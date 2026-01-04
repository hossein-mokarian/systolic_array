`timescale 1ns/1ps


module systolic_tb;

    parameter DATAWIDTH = 32; // Data width
    parameter N = 4; // Systolic Row Count
    parameter M = 4; // Systolic Column Count

    reg rstn;
    reg en;
    reg clk;

    reg start;

    wire buffer_data_ready;
    reg [N * DATAWIDTH - 1 : 0] mem_data;
    reg mem_data_valid;

    // reg mem_data_ready;
    // wire buffer_data_valid;
    
    wire buffer_weight_ready;
    reg [M * DATAWIDTH - 1 : 0] mem_weight;
    reg mem_weight_valid;
    
    // reg mem_weight_ready;
    // wire buffer_weight_valid;

    wire [N * DATAWIDTH - 1 : 0] packed_result;

    wire [DATAWIDTH - 1 : 0] unpacked_result[N - 1 : 0][M - 1 : 0];

    genvar i, j;
    generate
        for (i = 0; i < N; i = i + 1)
            for (j = 0; j < M; j = j + 1)
                assign unpacked_result[i][j] = packed_result[(i * M * DATAWIDTH + (j + 1) * DATAWIDTH) : (i * M * DATAWIDTH + j * DATAWIDTH)];
    endgenerate


    SYSTOLIC_TOP #(
        .DATAWIDTH(DATAWIDTH),
        .N(N),
        .M(M)
    ) dut (
        .rstn(rstn),
        .en(en),
        .clk(clk),

        .start_in(start),

        // mem to nuffer data interface
        .data_ready_out(buffer_data_ready),
        .mem_data_in(mem_data),
        .data_valid_in(mem_data_valid),

        // .data_ready_in(mem_data_ready),
        // .data_valid_out(buffer_data_valid),

        // mem to nuffer weight interface
        .weight_ready_out(buffer_weight_ready),
        .mem_weight_in(mem_weight),       
        .weight_valid_in(mem_weight_valid),
        
        // .weight_ready_in(mem_weight_ready),
        // .weight_valid_out(buffer_weight_valid),

        // final output (for example: Matrix multiplication)
        .result_out(packed_result)
    );

    initial
    begin
        rstn = 0;
        en = 0;
        clk = 0;
        start = 0;

        #10 rstn = 1;
        #5 en = 1;
        mem_data_valid = 1;

        #1000 $finish;
    end

    always #5 clk = ~clk;

    initial 
    begin
        $dumpfile("systolic_tb_results.vcd");
        $dumpvars(0, systolic_tb);
    end
    
endmodule
