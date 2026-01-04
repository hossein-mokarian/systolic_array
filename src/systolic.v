`include "./src/pe.v"


module SYSTOLIC #(
    parameter DATAWIDTH = 32,
    parameter N = 4,
    parameter M = 4
)(
    input rstn,
    input en,
    input clk,

    input start_in,

    output data_ready_out,
    input [N * DATAWIDTH - 1 : 0] data_in,
    input data_valid_in,

    output weight_ready_out,
    input [M * DATAWIDTH - 1 : 0] weight_in,
    input weight_valid_in,

    output [N * DATAWIDTH - 1 : 0] data_out,
    output data_valid_out
);

    localparam CLKS_COUNT = N + M + M;

    wire run;
    wire shift;
    // reg [$clog2(N - 1 + M + M) - 1 : 0] counter;
    reg [$clog2(CLKS_COUNT) - 1 : 0] counter;  // NEEDS TO COUNT THROUGH FULL COMPUTATION
    // reg [$clog2(M) - 1 : 0] counter;
    reg [M - 1 : 0] run_sr;
    integer k;

    wire [DATAWIDTH - 1 : 0] data   [N - 1 : 0];
    wire [DATAWIDTH - 1 : 0] weight [M - 1 : 0];

    wire runs   [N - 1 : 0][M - 1 : 0];
    wire [DATAWIDTH - 1 : 0] psum   [N - 1 : 0][M - 1 : 0];
    wire [DATAWIDTH - 1 : 0] wout   [N - 1 : 0][M - 1 : 0];
    wire [DATAWIDTH - 1 : 0] dout   [N - 1 : 0][M - 1 : 0];

    wire [DATAWIDTH - 1 : 0] result [N - 1 : 0][M - 1 : 0];

    genvar i, j;

    generate
        for (i = 0; i < N; i = i + 1)
            assign data[i] = data_in[(i + 1) * DATAWIDTH - 1 : i * DATAWIDTH];
        
        for (i = 0; i < M; i = i + 1)
            assign weight[i] = weight_in[(i + 1) * DATAWIDTH - 1 : i * DATAWIDTH];

        for (i = 0; i < N; i = i + 1)
            assign data_out[(i + 1) * DATAWIDTH - 1 : i * DATAWIDTH] = result[i][M - 1];

    endgenerate

    generate
        for (i = 0; i < N; i = i + 1)
        begin
            for (j = 0; j < M; j = j + 1)
            begin
                if (i == 0 && j == 0)
                    PE #(
                        .DATAWIDTH(DATAWIDTH)
                    ) pe0 (
                        .rstn(rstn),
                        .en(en),
                        .clk(clk),

                        .run_in(run),
                        .run_out(runs[i][j]),
                        .shift_in(shift),

                        .psum_in(0),
                        .data_in(data[j]),
                        .weight_in(weight[j]),
                        .prev_result_in(0),

                        .psum_out(psum[i][j]),
                        .weight_out(wout[i][j]),
                        .data_out(dout[i][j]),
                        .next_result_out(result[i][j])
                    );
                else if (i == 0 && j == M - 1)
                    PE #(
                        .DATAWIDTH(DATAWIDTH)
                    ) pe0 (
                        .rstn(rstn),
                        .en(en),
                        .clk(clk),

                        .run_in(runs[i][j - 1]),
                        .run_out(runs[i][j]),
                        .shift_in(shift),

                        .psum_in(0),
                        .data_in(dout[i][j - 1]),
                        .weight_in(weight[j]),
                        .prev_result_in(result[i][j - 1]),

                        .psum_out(psum[i][j]),
                        .weight_out(wout[i][j]),
                        .data_out(dout[i][j]),
                        .next_result_out(result[i][j])
                    );
                else if (i == 0)
                    PE #(
                        .DATAWIDTH(DATAWIDTH)
                    ) pe0 (
                        .rstn(rstn),
                        .en(en),
                        .clk(clk),

                        .run_in(runs[i][j - 1]),
                        .run_out(runs[i][j]),
                        .shift_in(shift),

                        .psum_in(0),
                        .data_in(dout[i][j - 1]),
                        .weight_in(weight[j]),
                        .prev_result_in(result[i][j - 1]),

                        .psum_out(psum[i][j]),
                        .weight_out(wout[i][j]),
                        .data_out(dout[i][j]),
                        .next_result_out(result[i][j])
                    );
                else if (j == 0)
                    PE #(
                        .DATAWIDTH(DATAWIDTH)
                    ) pe0 (
                        .rstn(rstn),
                        .en(en),
                        .clk(clk),

                        .run_in(run_sr[i - 1]),
                        .run_out(runs[i][j]),
                        .shift_in(shift),
                        
                        .psum_in(psum[i - 1][j]),
                        .data_in(data[i]),
                        .weight_in(wout[i - 1][j]),
                        .prev_result_in(0),

                        .psum_out(psum[i][j]),
                        .weight_out(wout[i][j]),
                        .data_out(dout[i][j]),
                        .next_result_out(result[i][j])
                    );
                else if (j == M - 1)
                    PE #(
                        .DATAWIDTH(DATAWIDTH)
                    ) pe0 (
                        .rstn(rstn),
                        .en(en),
                        .clk(clk),

                        .run_in(runs[i][j - 1]),
                        .run_out(runs[i][j]),
                        .shift_in(shift),

                        .psum_in(psum[i - 1][j]),
                        .data_in(dout[i][j - 1]),
                        .weight_in(wout[i - 1][j]),
                        .prev_result_in(result[i][j - 1]),

                        .psum_out(psum[i][j]),
                        .weight_out(wout[i][j]),
                        .data_out(dout[i][j]),
                        .next_result_out(result[i][j])
                    );
                else
                    PE #(
                        .DATAWIDTH(DATAWIDTH)
                    ) pe0 (
                        .rstn(rstn),
                        .en(en),
                        .clk(clk),

                        .run_in(runs[i][j - 1]),
                        .run_out(runs[i][j]),
                        .shift_in(shift),

                        .psum_in(psum[i - 1][j]),
                        .data_in(dout[i][j - 1]),
                        .weight_in(wout[i - 1][j]),
                        .prev_result_in(result[i][j - 1]),

                        .psum_out(psum[i][j]),
                        .weight_out(wout[i][j]),
                        .data_out(dout[i][j]),
                        .next_result_out(result[i][j])
                    );
            end
        end
    endgenerate

    always @(posedge clk)
    begin
        if (!rstn)
        begin
            counter <= 0;
            for (k = 0; k < M; k = k + 1)
                run_sr[k] <= 0;
        end
        else if (rstn && en)
        begin
            if (start_in)
                counter <= 1;
            else if (counter == CLKS_COUNT - 1)
                counter <= 0;
            else if (counter != 0)
                counter <= counter + 1;
            
            run_sr[0] <= run;
            for (k = 0; k < M - 1; k = k + 1)
                run_sr[k + 1] <= run_sr[k];
        end
    end

    assign run = (rstn && en && (start_in || (counter != 0 && counter <= N - 1))) ? 1 : 0;
    assign shift = (rstn && en && counter == 0) ? 1 : 0;

    assign data_ready_out = run || (counter != 0 && counter <= M + N - 1);
    assign weight_ready_out = data_ready_out;

    assign data_valid_out = shift;

endmodule
