`timescale 1ns / 1ps

module WalkingOnes_SIG24(
    input     wire                   clk                        ,
    input     wire                   rst                        ,
    output    wire       [23:0]      test_sig
);
reg                 [23:0]              test_sig_reg                        ;
assign test_sig   = test_sig_reg;

always @ ( posedge clk ) begin
    if ((test_sig_reg == 24'h800000) | rst) begin
        test_sig_reg <= 24'h000001; // wraparound / reset
    end
    else begin
        test_sig_reg <= test_sig_reg << 1; // shift the 1
    end
end
endmodule
