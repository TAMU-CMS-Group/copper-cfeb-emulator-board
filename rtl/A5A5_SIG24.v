`timescale 1ns / 1ps

module A5A5_SIG24(
    input wire clk,
    input wire rst,
    output wire [23:0] test_sig
    );
    reg sig_type = 1'b0; //flag to alternate between a5a5 and 5a5a
    reg [23:0] test_sig_reg;
    assign test_sig = test_sig_reg;
    
    // for each CC, generate a5 or 5a
    always@(posedge clk) begin
        if(rst) begin
            sig_type <= 1'b0;
            test_sig_reg <= 24'h000000;
        end else begin
            // generate output signal
            if(sig_type) begin
                test_sig_reg <= 24'h5a5a5a;
            end else begin
                test_sig_reg <= 24'ha5a5a5;
            end
            sig_type <= ~sig_type; //change output signal type
        end
    end
endmodule
