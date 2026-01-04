module DOUBLE_BUFFER #(
    parameter DATAWIDTH = 32,
    parameter DEPTH = 4,
    parameter NB_OF_DATA = 4
)(
    input rstn,
    input en,
    input clk,

    output ready_out,
    input [NB_OF_DATA * DATAWIDTH - 1 : 0] data_in,
    input valid_in,

    input ready_in,
    output [NB_OF_DATA * DATAWIDTH - 1 : 0] data_out,
    output reg valid_out
);

    localparam BUFFER_OP_READ = 1'b0;
    localparam BUFFER_OP_WRITE = 1'b1;

    wire [DATAWIDTH - 1 : 0] din [NB_OF_DATA - 1 : 0];
    reg [DATAWIDTH - 1 : 0] dout [NB_OF_DATA - 1 : 0];

    genvar gi;
    generate
        for (gi = 0; gi < NB_OF_DATA; gi = gi + 1)
        begin
            assign din[gi] = data_in[(gi + 1) * DATAWIDTH - 1 : gi * DATAWIDTH];
            assign data_out[(gi + 1) * DATAWIDTH - 1 : gi * DATAWIDTH] = dout[gi];
        end
    endgenerate

    reg [DATAWIDTH - 1 : 0] buffer_0 [DEPTH - 1 : 0][NB_OF_DATA - 1 : 0];
    reg [DATAWIDTH - 1 : 0] buffer_1 [DEPTH - 1 : 0][NB_OF_DATA - 1 : 0];
    
    reg [$clog2(DEPTH) - 1 : 0] read_ptr_0;
    reg [$clog2(DEPTH) - 1 : 0] read_ptr_1;

    reg [$clog2(DEPTH) - 1 : 0] write_ptr_0;
    reg [$clog2(DEPTH) - 1 : 0] write_ptr_1;

    reg last_op_0;
    reg last_op_1;

    wire is_empty_0;
    wire is_empty_1;

    wire is_full_0;
    wire is_full_1;

    // sel == 0 ---> write in buffer_0 and read from buffer_1
    // sel == 1 ---> write in buffer_1 and read from buffer_0
    reg sel;

    integer i, j;


    // write block
    always @(posedge clk)
    begin
        if (!rstn)
        begin
            for (i = 0; i < DEPTH; i = i + 1)
             for (j = 0; j < NB_OF_DATA; j = j + 1)
             begin
                buffer_0[i][j] <= 0;
                buffer_1[i][j] <= 0;
             end
            
            write_ptr_0 <= 0;
            write_ptr_1 <= 0;
        end
        else if (rstn && en)
        begin
            if (!sel)
            begin
                if (valid_in && ready_out && !is_full_0)
                begin
                    for (i = 0; i < NB_OF_DATA; i = i + 1)
                        buffer_0[write_ptr_0][i] <= din[i];

                    write_ptr_0 <= write_ptr_0 + 1;
                end
            end
            else
            begin
                if (valid_in && ready_out && !is_full_1)
                begin
                    for (i = 0; i < NB_OF_DATA; i = i + 1)
                        buffer_1[write_ptr_1][i] <= din[i];

                    write_ptr_1 <= write_ptr_1 + 1;
                end
            end
        end
    end

    assign is_full_0 = (rstn && en && (write_ptr_0 == read_ptr_0) && last_op_0 == BUFFER_OP_WRITE) ? 1 : 0;
    assign is_full_1 = (rstn && en && (write_ptr_1 == read_ptr_1) && last_op_1 == BUFFER_OP_WRITE) ? 1 : 0;

    // read block
    always @(posedge clk)
    begin
        if (!rstn)
        begin
            for (i = 0; i < NB_OF_DATA; i = i + 1)
                dout[i] <= 0;

            read_ptr_0 <= 0;
            read_ptr_1 <= 0;
            
            valid_out <= 0;
        end
        else if (rstn && en)
        begin
            if (sel)
            begin
                if (ready_in && !is_empty_0)
                begin
                    for (i = 0; i < NB_OF_DATA; i = i + 1)
                        dout[i] <= buffer_0[read_ptr_0][i];
                    
                    valid_out <= 1;
                    read_ptr_0 <= read_ptr_0 + 1;
                end
                else
                    valid_out <= 0;
            end
            else
            begin
                if (ready_in && !is_empty_1)
                begin
                    for (i = 0; i < NB_OF_DATA; i = i + 1)
                        dout[i] <= buffer_1[read_ptr_1][i];
                    
                    valid_out <= 1;
                    read_ptr_1 <= read_ptr_1 + 1;
                end
                else
                    valid_out <= 0;
            end
        end
    end

    assign is_empty_0 = (rstn && en && (read_ptr_0 == write_ptr_0) && last_op_0 == BUFFER_OP_READ) ? 1 : 0;
    assign is_empty_1 = (rstn && en && (read_ptr_1 == write_ptr_1) && last_op_1 == BUFFER_OP_READ) ? 1 : 0;

    // lats op
    always @(posedge clk) 
    begin
        if (!rstn)
        begin
            last_op_0 <= BUFFER_OP_READ;
            last_op_1 <= BUFFER_OP_READ;
        end
        else if (rstn && en)
        begin
            if (!sel && valid_in && ready_out && !is_full_0)
                last_op_0 <= BUFFER_OP_WRITE;
            if (sel && ready_in && !is_empty_0)
                last_op_0 <= BUFFER_OP_READ;

            if (sel && valid_in && ready_out && !is_full_1)
                last_op_1 <= BUFFER_OP_WRITE;
            if (!sel && ready_in && !is_empty_1)
                last_op_1 <= BUFFER_OP_READ;
        end
    end

    // buffer selection
    always @(*)
    begin
        if (!rstn)
        begin            
            sel = 0;
        end
        else if (rstn && en)
        begin
            if (is_full_0)
                sel = 1;

            if (is_full_1)
                sel = 0;
            
            if (sel && is_empty_0 && !is_empty_1 && ready_in)
                sel = 0;
            
            if (!sel && is_empty_1 && !is_empty_0 && ready_in)
                sel = 1;
            
        end
    end

    assign ready_out = !is_full_0 | !is_full_1;

endmodule
