//-------------------------------------------------------------------------------------------------
// EACA EG2000 Colour Genie implementation for ZX-Uno by Kyp
// https://github.com/Kyp069/eg2000
//-------------------------------------------------------------------------------------------------
// Z80 chip module implementation by Sorgelig
// https://github.com/sorgelig/ZX_Spectrum-128K_MIST
//-------------------------------------------------------------------------------------------------
// UM6845R chip module implementation by Sorgelig
// https://github.com/sorgelig/Amstrad_MiST
//-------------------------------------------------------------------------------------------------
// AY chip module implementation by Jotego
// https://github.com/jotego/jt49
//-------------------------------------------------------------------------------------------------
module eg2000
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock27,

	output wire       led,

	output wire[ 1:0] sync,
	output wire[17:0] rgb,

	input  wire       ear,
	output wire[ 1:0] audio,

	output wire       ramCk,
	output wire       ramCe,
	output wire       ramCs,
	output wire       ramWe,
	output wire       ramRas,
	output wire       ramCas,
	output wire[ 1:0] ramDqm,
	inout  wire[15:0] ramDQ,
	output wire[ 1:0] ramBA,
	output wire[12:0] ramA,

	input  wire       cfgD0,
	input  wire       spiCk,
	input  wire       spiS2,
	input  wire       spiS3,
	input  wire       spiDi,
	output wire       spiDo
);
//-------------------------------------------------------------------------------------------------

clock Clock
(
	.inclk0 (clock27),
	.c0     (clock  ) // 35.468 MHz
);

reg[4:0] ce;
always @(negedge clock) ce <= ce+1'd1;

wire ce8M8p = ~ce[0] &  ce[1];
wire ce8M8n = ~ce[0] & ~ce[1];

wire ce2M2p = ~ce[0] & ~ce[1] & ~ce[2] &  ce[3];
wire ce2M2n = ~ce[0] & ~ce[1] & ~ce[2] & ~ce[3];

wire ce1M1 = ~ce[0] & ~ce[1] & ~ce[2] & ~ce[3] &  ce[4];

//-------------------------------------------------------------------------------------------------

reg[5:0] rs;
wire power = rs[5];
always @(posedge clock) if(ce2M2p) if(!power) rs <= rs+1'd1;

//-------------------------------------------------------------------------------------------------

wire reset = power & ready & ~F11 & osdRs;
wire nmi = ~F5;

wire[ 7:0] d;
wire[ 7:0] q;
wire[15:0] a;

cpu Cpu
(
	.clock  (clock  ),
	.cep    (ce2M2p ),
	.cen    (ce2M2n ),
	.reset  (reset  ),
	.iorq   (iorq   ),
	.mreq   (mreq   ),
	.rfsh   (rfsh   ),
	.wr     (wr     ),
	.rd     (rd     ),
	.nmi    (nmi    ),
	.d      (d      ),
	.q      (q      ),
	.a      (a      )
);

//-------------------------------------------------------------------------------------------------

reg mode, c, b;
always @(posedge clock) if(ce2M2p) if(!ioFF && !wr) { mode, c, b } <= q[5:3];

//-------------------------------------------------------------------------------------------------

wire ioFA = !(!iorq && a[7:0] == 8'hFA); // crtc addr
wire ioFB = !(!iorq && a[7:0] == 8'hFB); // crtc data

wire crtcCs = !(!ioFA || !ioFB);
wire crtcRs = a[0];
wire crtcRw = wr;

wire[ 7:0] crtcQ;

wire[13:0] crtcMa;
wire[ 4:0] crtcRa;

UM6845R Crtc
(
	.TYPE   (1'b0   ),
	.CLOCK  (clock  ),
	.CLKEN  (ce1M1  ),
	.nRESET (reset  ),
	.ENABLE (1'b1   ),
	.nCS    (crtcCs ),
	.R_nW   (crtcRw ),
	.RS     (crtcRs ),
	.DI     (q      ),
	.DO     (crtcQ  ),
	.VSYNC  (VSync  ),
	.HSYNC  (HSync  ),
	.DE     (crtcDe ),
	.FIELD  (       ),
	.CURSOR (cursor ),
	.MA     (crtcMa ),
	.RA     (crtcRa )
);

//-------------------------------------------------------------------------------------------------
// bdir bc1
//   1   1    wr addr
//   1   0    wr data
//   0   1    rd data

wire ioF8 = !(!iorq && a[7:0] == 8'hF8); // psg addr
wire ioF9 = !(!iorq && a[7:0] == 8'hF9); // psg data

wire bdir = (!wr && !ioF8) || (!wr && !ioF9);
wire bc1 = (!wr && !ioF8) || (!rd && !ioF9);

wire[7:0] psgA;
wire[7:0] psgB;
wire[7:0] psgC;
wire[7:0] psgQ;

jt49_bus Psg
(
	.clk    (clock  ),
	.clk_en (ce2M2p ),
	.rst_n  (reset  ),
	.bdir   (bdir   ),
	.bc1    (bc1    ),
	.din    (q      ),
	.dout   (psgQ   ),
	.A      (psgA   ),
	.B      (psgB   ),
	.C      (psgC   ),
	.sel    (1'b0   )
);

//-------------------------------------------------------------------------------------------------

wire[13:0] vma = crtcMa;
wire[ 2:0] vra = crtcRa[2:0];
wire[ 7:0] color;

wire[ 7:0] memQ;

memory Memory
(
	.clock  (clock  ),
	.reset  (power  ),
	.ready  (ready  ),
	.ps2Code(ps2Code),
	.ps2Strb(ps2Strb),
	.ps2Prsd(ps2Prsd),
	.f11    (F11    ),
	.f5     (F5     ),
	.hSync  (hSync  ),
	.vcep   (ce8M8p ),
	.vcen   (ce8M8n ),
	.b      (b      ),
	.c      (c      ),
	.vma    (vma    ),
	.vra    (vra    ),
	.pixel  (pixel  ),
	.color  (color  ),
	.ce     (ce2M2p ),
	.mreq   (mreq   ),
	.rfsh   (rfsh   ),
	.rd     (rd     ),
	.wr     (wr     ),
	.d      (q      ),
	.q      (memQ   ),
	.a      (a      ),
	.ramCk  (ramCk  ),
	.ramCe  (ramCe  ),
	.ramCs  (ramCs  ),
	.ramRas (ramRas ),
	.ramCas (ramCas ),
	.ramWe  (ramWe  ),
	.ramDqm (ramDqm ),
	.ramDQ  (ramDQ  ),
	.ramBA  (ramBA  ),
	.ramA   (ramA   )
);

//-------------------------------------------------------------------------------------------------

reg[1:0] cur;
always @(posedge clock) if(ce1M1) cur <= { cur[0], cursor };

reg[17:0] palette[15:0];
initial begin
	palette[15] = 18'b111000_111000_111000; // C7_4E_FF; // grey
	palette[14] = 18'b100000_001000_111000; // 98_20_FF; // magenta
	palette[13] = 18'b001000_110000_100000; // 1F_C4_8C; // turquise
	palette[12] = 18'b100000_100000_100000; // 8C_8C_8C; // grey
	palette[11] = 18'b100000_011000_111000; // 8A_67_FF; // blue
	palette[10] = 18'b110000_010000_111000; // FF_FF_FF; // violet
	palette[ 9] = 18'b101000_110000_111000; // BC_DF_FF; // dark blue
	palette[ 8] = 18'b001000_010000_111000; // 2F_53_FF; // blue
	palette[ 7] = 18'b110000_111000_001000; // EA_FF_27; // yellow/green
	palette[ 6] = 18'b111000_011000_001000; // EB_6F_2B; // orange
	palette[ 5] = 18'b101000_111000_010000; // AB_FF_4A; // green
	palette[ 4] = 18'b111000_111000_001000; // FF_F2_3D; // yellow
	palette[ 3] = 18'b111000_111000_111000; // FF_FF_FF; // white
	palette[ 2] = 18'b110000_001000_010000; // CB_26_5E; // red
	palette[ 1] = 18'b011000_111000_111000; // 7C_FF_EA; // cyan
	palette[ 0] = 18'b010000_010000_010000; // 5E_5E_5E; // grey
end

//assign sync = ~(hSync^vSync);
//assign rgb = (pixel || cur[1]) && crtcDe ? palette[color[3:0]] : 9'd0;

wire[17:0] rgbQ = (pixel || cur[1]) && crtcDe ? palette[color[3:0]] : 9'd0;

//-------------------------------------------------------------------------------------------------

audio Audio
(
	.clock  (clock  ),
	.reset  (reset  ),
	.a      (psgA   ),
	.b      (psgB   ),
	.c      (psgC   ),
	.audio  (audio  )
);

//-------------------------------------------------------------------------------------------------

wire ioFF = !(!iorq && a[7:0] == 8'hFF);

assign d
	= !mreq ? memQ
	: !ioF9 ? psgQ
	: !ioFB ? crtcQ
	: !ioFF ? { 7'd0, ~ear }
	: 8'hFF;

//-------------------------------------------------------------------------------------------------

assign led = ~ear;

//-------------------------------------------------------------------------------------------------

localparam CONF_STR = {
	"EG2000;;",
	"T0,Reset;",
	"O23,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"V,v1.1"
};

wire[31:0] status;
wire       scandoubler_disable;

wire[ 7:0] ps2Code =ps2_key[7:0];
wire       ps2Prsd = ps2_key[9];

wire [10:0] ps2_key;

wire ps2Strb = old_keystb ^ ps2_key[10];
reg old_keystb = 0;

always @(posedge clock) old_keystb <= ps2_key[10];

//user_io #(.STRLEN(($size(CONF_STR)>>3))) userIo
//( 
//	.conf_str    (CONF_STR),
//	.clk_sys     (clock   ),
//	.SPI_CLK     (spiCk   ),
//	.SPI_SS_IO   (cfgD0   ),
//	.SPI_MISO    (spiDo   ),
//	.SPI_MOSI    (spiDi   ),
//	.status      (status  ),
//	.key_code    (ps2Code ),
//	.key_strobe  (ps2Strb ),
//	.key_pressed (ps2Prsd ),
//	.key_extended(        ),
//	.scandoubler_disable(scandoubler_disable)
//);
//
//mist_video mistVideo
//(
//	.clk_sys   ( clock     ),
//	.SPI_SCK   ( spiCk     ),
//	.SPI_DI    ( spiDi     ),
//	.SPI_SS3   ( spiS3     ),
//	.scanlines (status[3:2]),
//	.ce_divider(1'b0       ),
//	.scandoubler_disable(scandoubler_disable),
//	.no_csync  (1'b0       ),
//	.ypbpr     (1'b0       ),
//	.rotate    (2'b00      ),
//	.blend     (1'b0       ),
//	.R         (rgbQ[17:12]),
//	.G         (rgbQ[11: 6]),
//	.B         (rgbQ[ 5: 0]),
//	.HSync     (~hSync     ),
//	.VSync     (~vSync     ),
//	.VGA_R     (rgb[17:12] ),
//	.VGA_G     (rgb[11: 6] ),
//	.VGA_B     (rgb[ 5: 0] ),
//	.VGA_VS    (sync[1]    ),
//	.VGA_HS    (sync[0]    )
//);

mist_io #(.STRLEN(($size(CONF_STR)>>3))) mist_io
(  
	.ioctl_ce    (1),
	.conf_str    (CONF_STR),
	.clk_sys     (clock   ),
	.SPI_SCK     (spiCk   ),
	.CONF_DATA0  (cfgD0   ),
	.SPI_SS2     (spiS2   ),
	.SPI_DO    	 (spiDo   ),
	.SPI_DI      (spiDi   ),
	.status      (status  ),
   .ps2_key     (ps2_key ),
	.scandoubler_disable(scandoubler_disable),
	.ypbpr       (ypbpr   ),

	// unused
	.ps2_kbd_clk(),
	.ps2_kbd_data(),
	.ps2_mouse_clk(),
	.ps2_mouse_data(),
	.joystick_analog_0(),
	.joystick_analog_1()
);

wire [1:0] scale = status[3:2];
wire ce_pix = ce8M8p;


video_mixer #(.LINE_LENGTH(512), .HALF_DEPTH(1)) video_mixer
(
	.*,
	.ce_pix(ce_pix),
	.ce_pix_actual(ce_pix),
	.hq2x(scale == 1),
	.scanlines(scandoubler_disable ? 2'b00 : {scale==3, scale==2}),
	.clk_sys   ( clock     ),
	.SPI_SCK   ( spiCk     ),
	.SPI_DI    ( spiDi     ),
	.SPI_SS3   ( spiS3     ),
   .mono      (0),
	.ypbpr     (ypbpr      ),
	.line_start(0),
	.ypbpr_full(0),
	.HSync     (~HSync),
	.VSync     (~VSync),
//	.R         (rgbQ[17:12]),
//	.G         (rgbQ[11: 6]),
//	.B         (rgbQ[ 5: 0]),
	.R         (rgbQ[17:15]),
	.G         (rgbQ[11: 9]),
	.B         (rgbQ[ 5: 3]),

	.VGA_R     (rgb[17:12] ),
	.VGA_G     (rgb[11: 6] ),
	.VGA_B     (rgb[ 5: 0] ),
	.VGA_VS    (sync[1]    ),
	.VGA_HS    (sync[0]    )
);

wire osdRs = ~status[0];

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
