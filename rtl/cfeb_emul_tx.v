`timescale 1ns / 1ps

module cfeb_emul_tx(
    input       lhc_ck     ,
    input       ccb_bc0     ,
    input       spare8     ,
    input   [3:0] sw     ,
    output  [3:0] led     ,
    output      spare7     ,
    output reg [23:0] cfeb1out     ,
    output reg [23:0] cfeb2out     ,
    output reg [23:0] cfeb3out
);

reg [1:0] state = 2'b00;
wire [23:0] out_wone, out_wzer, out_prbs, out_a5a5;
reg [3:0] rsts = 4'b1111;
// assign led  = rsts;
assign spare7   = ccb_bc0;

reg [27:0] div_cnt = 28'd0;
reg     slow_en = 1'b0;
wire    ibufg_lhc, clk_40 ;
IBUFG IBUFG_inst (
    .O (ibufg_lhc),
    .I (lhc_ck)
);
BUFG BUFG_inst (
    .O (clk_40), // Clock buffer output
    .I (ibufg_lhc) // Clock buffer input
);

wire    clk0_dcm;
wire    clkfb   ;
BUFG bufg_fb_inst (
    .I (clk0_dcm),
    .O (clkfb)
);
wire    clk_80  ;
wire    clk_reset;
wire [7:0] dcm_status;
wire    dcm_locked;
DCM #(.SIM_MODE("SAFE"), // Simulation: "SAFE" vs. "FAST", see "Synthesis and Simulation Design Guide" for details
.CLKDV_DIVIDE(2.0), // Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5
// 7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
.CLKFX_DIVIDE(1), // Can be any integer from 1 to 32
.CLKFX_MULTIPLY(2), // Can be any integer from 2 to 32
.CLKIN_DIVIDE_BY_2("FALSE"), // TRUE/FALSE to enable CLKIN divide by two feature
.CLKIN_PERIOD(25), // Specify period of input clock
.CLKOUT_PHASE_SHIFT("FIXED"), // Specify phase shift of NONE, FIXED or VARIABLE
.CLK_FEEDBACK("1X"), // Specify clock feedback of NONE, 1X or 2X
.DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"), // SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or
// an integer from 0 to 15
.DFS_FREQUENCY_MODE("LOW"), // HIGH or LOW frequency mode for frequency synthesis
.DLL_FREQUENCY_MODE("LOW"), // HIGH or LOW frequency mode for DLL
.DUTY_CYCLE_CORRECTION("TRUE"), // Duty cycle correction, TRUE or FALSE
.FACTORY_JF(16'hC080), // FACTORY JF values
.PHASE_SHIFT( - 51), // Amount of fixed phase shift from -255 to 255
.STARTUP_WAIT("FALSE") // Delay configuration DONE until DCM LOCK, TRUE/FALSE
) DCM_inst (
    .CLK0 (clk0_dcm), // 0 degree DCM CLK output
    .CLK180 (), // 180 degree DCM CLK output
    .CLK270 (), // 270 degree DCM CLK output
    .CLK2X (), // 2X DCM CLK output
    .CLK2X180 (), // 2X, 180 degree DCM CLK out
    .CLK90 (), // 90 degree DCM CLK output
    .CLKDV (), // Divided DCM CLK out (CLKDV_DIVIDE)
    .CLKFX (clk_80), // DCM CLK synthesis out (M/D)
    .CLKFX180 (), // 180 degree CLK synthesis out
    .LOCKED (dcm_locked), // DCM LOCK status output
    .PSDONE (), // Dynamic phase adjust done output
    .STATUS (dcm_status), // 8-bit DCM status bits output
    .CLKFB (clkfb), // DCM clock feedback
    .CLKIN (ibufg_lhc), // Clock input (from IBUFG, BUFG or DCM)
    .PSCLK (), // Dynamic phase adjust clock input
    .PSEN (), // Dynamic phase adjust enable input
    .PSINCDEC (), // Dynamic phase adjust increment/decrement
    .RST (1'b0 ) // DCM asynchronous reset input
);

always@( posedge clk_40 ) begin
    if (div_cnt >= 28'd40_000_000 - 1) begin
        div_cnt <= 28'd0;
        slow_en <= 1'b1;
    end
    else begin
        div_cnt <= div_cnt + 28'd1;
        slow_en <= 1'b0;
    end
end

// instatiate modules
WalkingOnes_SIG24 wone24 (
    .clk (clk_80),
    .rst (rsts[0] ),
    .test_sig (out_wone)
);
WalkingZeros_SIG24 wzer24 (
    .clk (clk_80),
    .rst (rsts[1] ),
    .test_sig (out_wzer)
);
PRBS_SIG24 prbs24 (
    .clk (clk_80),
    .rst (rsts[2] ),
    .prbs_out (prbs_out)
);
A5A5_SIG24 a5a524 (
    .clk (clk_80),
    .rst (rsts[3] ),
    .test_sig (out_a5a5)
);

reg     resync_meta = 1'b0;
reg     resync_sync = 1'b0;
reg     resync_prev = 1'b0;
reg [7:0] lock_holdoff = 8'd0;
reg     ready_40 = 1'b0;

always@( posedge clk_40 ) begin
    resync_meta <= ccb_bc0;
    resync_sync <= resync_meta;
    resync_prev <= resync_sync;
    if (!dcm_locked) begin
        lock_holdoff    <= 8'd0;
        ready_40    <= 1'b0;
    end
    else if (lock_holdoff != 8'hFF) begin
        lock_holdoff    <= lock_holdoff + 1'b1;
    end
    else begin
        ready_40    <= 1'b1;
    end
end

wire    resync_start_40 = ready_40 & resync_sync & ~resync_prev;

reg     resync_start_80 = 1'b0;
reg     ready_80 = 1'b0;
always@( posedge clk_80 ) begin
    resync_start_80 <= resync_start_40;
    ready_80    <= ready_40;
end

assign led[0]   = dcm_locked;
assign led[1]   = dcm_status[1];
assign led[2]   = dcm_status[2];
assign led[3]   = ccb_bc0;

always@( posedge clk_80 ) begin
    if (!ready_80) begin
        state   <= 2'b00;
        rsts    <= 4'b1111;
        cfeb1out    <= 24'hFFFFFF;
        cfeb2out    <= 24'hFFFFFF;
        cfeb3out    <= 24'hFFFFFF;
    end
    else begin
        if (resync_start_80) begin
            state   <= state + 1'b1;
        end

        case (state)
            2'b00: begin
                cfeb1out    <= out_wone;
                cfeb2out    <= out_wone;
                cfeb3out    <= out_wone;
                rsts    <= 4'b1110;
            end
            2'b01: begin
                cfeb1out    <= out_wzer;
                cfeb2out    <= out_wzer;
                cfeb3out    <= out_wzer;
                rsts    <= 4'b1101;
            end
            2'b10: begin
                cfeb1out    <= out_prbs;
                cfeb2out    <= out_prbs;
                cfeb3out    <= out_prbs;
                rsts    <= 4'b1011;
            end
            2'b11: begin
                cfeb1out    <= out_a5a5;
                cfeb2out    <= out_a5a5;
                cfeb3out    <= out_a5a5;
                rsts    <= 4'b0111;
            end
        endcase
    end
end

endmodule
