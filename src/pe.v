module PE #(
    parameter DATAWIDTH = 32
)(
    input rstn,
    input en,
    input clk,

    input run_in,
    output reg run_out,
    input shift_in,

    input [DATAWIDTH - 1 : 0] psum_in,
    input [DATAWIDTH - 1 : 0] data_in,
    input [DATAWIDTH - 1 : 0] weight_in,
    input [DATAWIDTH - 1 : 0] prev_result_in,

    output reg [DATAWIDTH - 1 : 0] psum_out,
    output reg [DATAWIDTH - 1 : 0] weight_out,
    output reg [DATAWIDTH - 1 : 0] data_out,
    output [DATAWIDTH - 1 : 0] next_result_out
);

    reg [DATAWIDTH - 1 : 0] result;
    
    always @(posedge clk) 
    begin
        if (!rstn)
        begin
            run_out <= 0;
            psum_out <= 0;
            weight_out <= 0;
            data_out <= 0;
            result <= 0;
            // next_result_out <= 0;
        end
        else if (rstn && en)
        begin
            run_out <= run_in;
            
            if (run_in && !shift_in)
            begin
                data_out <= data_in;
                weight_out <= weight_in;
                result <= result + data_in * weight_in;
                // result <= psum_in + data_in * weight_in;
                psum_out <= result; // todo
            end
            else if (!run_in && shift_in)
            begin
                // next_result_out <= result;
                result <= prev_result_in;
            end
        end
    end

    assign next_result_out = (rstn && en) ? result : {DATAWIDTH{1'b0}};

endmodule
