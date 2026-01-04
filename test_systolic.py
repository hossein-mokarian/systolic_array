import cocotb
from cocotb.triggers import Timer, FallingEdge, RisingEdge
from cocotb.clock import Clock
from cocotb.types import LogicArray, Range

import numpy as np


async def generate_clock(dut):
    """Generate clock pulses."""

    for _ in range(10):
        dut.clk.value = 0
        await Timer(1, unit="ns")
        dut.clk.value = 1
        await Timer(1, unit="ns")

async def setSignal(clk, signal, name, delay, value):
    await Timer(delay, unit="ns")
    # signal.value = value
    await RisingEdge(clk)
    signal.value = value
    # await RisingEdge(clk)
    # assert signal.value == value, "%s is incorrect: %s != %s" % (name, str(signal.value), str(value))
    cocotb.log.info("%s is %s", name, signal.value)


@cocotb.test()
async def basic_test(dut):
    """Try accessing the design."""

    rstn = dut.rstn
    en = dut.en
    clk = dut.clk
    start = dut.start_in

    rstn.value = 0
    en.value = 0
    start.value = 0
    dut.data_valid_in.value = 0
    dut.weight_valid_in.value = 0

    # cocotb.start_soon(generate_clock(dut)) # run the clock "in the background"
    cocotb.start_soon(Clock(clk, 1, unit="ns").start())

    # await Timer(5, unit="ns")  # wait a bit
    # await FallingEdge(dut.clk)  # wait for falling edge/"negedge"

    # cocotb.log.info("en is %s", en.value)
    # assert en.value == 0

    cocotb.log.info("Starting the test ...")

    await setSignal(clk, rstn, "rstn", 2, 1)
    await setSignal(clk, en, "en", 1, 1)

    # await Timer(5, unit="ns")

    DEPTH = 4
    DATAWIDTH = 32
    N = 4
    M = 4
    PADDED_ROW = 5
    PADDED_COL = 3
    data_mat = np.array([[1,  0,  0],
                        [ 2, 11,  0],
                        [ 3, 12, 21],
                        [ 0, 13, 22],
                        [ 0,  0, 23]])
    weight_mat = np.array([[1,  0,  0],
                          [11,  2,  0],
                          [21, 12,  3],
                          [ 0, 22, 13],
                          [ 0,  0, 23]])
    data_mat_orig = np.array([[1,  2,  3], 
                            [ 11, 12, 13],
                            [ 21, 22, 23]])
    weight_mat_orig = np.array([[1,  2,   3],
                                [11, 12,  13],
                                [21, 22,  23]])
    result_mat = np.matmul(data_mat_orig, weight_mat_orig)
    print("result_mat is: \n", result_mat)

    for col in range(PADDED_ROW):
        print("waiting for dut.data_ready_out ...")
        if dut.data_ready_out.value == 1 and dut.weight_ready_out.value == 1:
            col_data = data_mat[col, :]
            col_weight = weight_mat[col, :]
            cocotb.log.info(f"Row {col} data: {col_data}")
            cocotb.log.info(f"ROW {col} weight: {col_weight}")
            
            data_packed = 0
            weight_packed = 0
            for row in range(PADDED_COL):
                data_val = int(col_data[row]) & 0xFFFFFFFF
                weight_val = int(col_weight[row]) & 0xFFFFFFFF
                # print(f"data_val: {data_val}")
                # print(f"weight_val: {weight_val}")
                data_shifted = data_val << (row * 32)
                weight_shifted = weight_val << (row * 32)
                # print(f"data_shifted: {data_shifted}")
                # print(f"weight_shifted: {weight_shifted}")
                data_packed |= data_shifted
                weight_packed |= weight_shifted
                # print(f"data_packed: {data_packed}")
                # print(f"weight_packed: {weight_packed}")
            
            print(f"data_packed: {data_packed}")
            print(f"weight_packed: {weight_packed}")

            await RisingEdge(clk)
            dut.mem_data_in.value = data_packed
            dut.data_valid_in.value = 1
            dut.mem_weight_in.value = weight_packed
            dut.weight_valid_in.value = 1
            if col != 0 and col % DEPTH == 0:
                print("Staring the systolic ...")
                start.value = 1
            else:
                start.value = 0

    
    await RisingEdge(clk)
    dut.data_valid_in.value = 0
    dut.weight_valid_in.value = 0
    start.value = 0

    # if M <= DEPTH:
    #     await FallingEdge(clk)
    #     start.value = 1
    #     await FallingEdge(clk)
    #     start.value = 0

    print("Waiting for result_valid ...")
    while dut.result_valid_out.value != 1:
        await FallingEdge(clk)

    print("Reading the final result ...")
    final_result = np.zeros((N, M))
    for col in range(M):
        print(f"result_valid_out: {dut.result_valid_out.value}")
        if dut.result_valid_out.value == 1:
            await RisingEdge(clk)
            for row in range(N):
                # value = dut.result_out.value.binstr
                # print(f"value: {value}" )
                column_value_bits  = dut.result_out.value[(row + 1) * DATAWIDTH - 1 : row * DATAWIDTH]
                # print(f"column_value_bits: {column_value_bits}" )
                column_value = column_value_bits.to_unsigned()
                # print(f"column_value: {column_value}" )
                mask = (1 << 32) - 1  # 32-bit mask: 0xFFFFFFFF
                # element = (column_value >> (row * 32)) & mask
                element =  column_value & mask
                # print(f"element: {element}" )
                final_result[row][col] = element
                print(f"col: {col} row: {row} final: {final_result[row][col]}" )
        # if col < M - 1:
        print("Waitning for next edge ...")
        while dut.result_valid_out.value != 1:
            await FallingEdge(clk)

    print("final_result is: \n", final_result)

    await Timer(1000, unit='ns')
