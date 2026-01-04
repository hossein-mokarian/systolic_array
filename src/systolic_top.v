`include "./src/systolic.v"
`include "./src/double_buffer.v"


module SYSTOLIC_TOP #(
    parameter DATAWIDTH = 32,
    parameter N = 4,
    parameter M = 4
)(
    input rstn,
    input en,
    input clk,

    input start_in,
    
    output data_ready_out,
    input [N * DATAWIDTH - 1 : 0] mem_data_in,
    input data_valid_in,

    // input data_ready_in,
    // output data_valid_out,

    output weight_ready_out,
    input [M * DATAWIDTH - 1 : 0] mem_weight_in,
    input weight_valid_in,
    
    // input weight_ready_in,
    // output weight_valid_out,

    output [N * DATAWIDTH - 1 : 0] result_out,
    output result_valid_out
);

    wire [N * DATAWIDTH - 1 : 0] data;
    wire [M * DATAWIDTH - 1 : 0] weight;

    SYSTOLIC #(
        .DATAWIDTH(DATAWIDTH),
        .N(N),
        .M(M)
    ) systolic (
        .rstn(rstn),
        .en(en),
        .clk(clk),

        .start_in(start_in),

        .data_ready_out(data_ready),
        .data_in(data),
        .data_valid_in(data_valid),

        .weight_ready_out(weight_ready),
        .weight_in(weight),
        .weight_valid_in(weight_valid),

        .data_out(result_out),
        .data_valid_out(result_valid_out)
    );

    DOUBLE_BUFFER #(
        .DATAWIDTH(DATAWIDTH),
        .NB_OF_DATA(N)
    ) row_buffer (
        .rstn(rstn),
        .en(en),
        .clk(clk),
        
        .ready_out(data_ready_out),
        .data_in(mem_data_in),
        .valid_in(data_valid_in),

        .ready_in(data_ready),
        .data_out(data),
        .valid_out(data_valid)
    );

    DOUBLE_BUFFER #(
        .DATAWIDTH(DATAWIDTH),
        .NB_OF_DATA(M)
    ) col_buffer (
        .rstn(rstn),
        .en(en),
        .clk(clk),

        .ready_out(weight_ready_out),
        .data_in(mem_weight_in),
        .valid_in(weight_valid_in),

        .ready_in(weight_ready),
        .data_out(weight),
        .valid_out(weight_valid)
    );

endmodule
