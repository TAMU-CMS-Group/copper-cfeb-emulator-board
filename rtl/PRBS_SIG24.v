`timescale 1ns / 1ps

module PRBS_SIG24(
    input wire  clk     , // Clock input
    input wire  rst     , // Active-high reset
    output wire [23:0] prbs_out // PRBS output bit
);
parameter SEED  = 24'h12345;
reg [23:0] lfsr ;
wire    feedback;

assign feedback = lfsr[23] ^ lfsr[22] ^ lfsr[21] ^ lfsr[16];
assign prbs_out = lfsr;

always@( posedge clk or posedge rst ) begin
    if (rst)
        lfsr    <= SEED;
    else
        lfsr    <= {lfsr[22:0], feedback
        };
end
endmodule

