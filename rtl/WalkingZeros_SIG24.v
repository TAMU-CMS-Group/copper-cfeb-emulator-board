`timescale 1ns / 1ps

module WalkingZeros_SIG24(
    input wire clk,
    input wire rst,
    output wire [23:0] test_sig
    );
    reg [23:0] test_sig_reg = 24'hFFFFFE;
    assign test_sig = test_sig_reg;
    
    always@(posedge clk) begin
        if((test_sig_reg == 24'h7FFFFF) | rst)
            test_sig_reg <= 24'hFFFFFE; // wraparound / reset
        else
            test_sig_reg <= {test_sig_reg[22:0], 1'b1}; // shift the 0
    end
endmodule
