//-------------------------------------------------------------------------------------------------
module memory
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock,
	input  wire       reset,
	output wire       ready,

	input  wire[ 7:0] ps2Code,
	input  wire       ps2Strb,
	input  wire       ps2Prsd,
	output wire       f11,
	output wire       f5,

	input  wire       hSync,
	input  wire       vcep,
	input  wire       vcen,
	input  wire       b,
	input  wire       c,
	input  wire[13:0] vma,
	input  wire[ 2:0] vra,
	output wire       pixel,
	output wire[ 3:0] color,

	input  wire       ce,
	input  wire       mreq,
	input  wire       rfsh,
	input  wire       rd,
	input  wire       wr,
	input  wire[ 7:0] d,
	output wire[ 7:0] q,
	input  wire[15:0] a,

	output wire       ramCk,
	output wire       ramCe,
	output wire       ramCs,
	output wire       ramWe,
	output wire       ramRas,
	output wire       ramCas,
	output wire[ 1:0] ramDqm,
	inout  wire[15:0] ramDQ,
	output wire[ 1:0] ramBA,
	output wire[12:0] ramA
);
//-------------------------------------------------------------------------------------------------

reg[2:0] hCount;
always @(posedge clock) if(hSync) hCount <= 3'd0; else if(vcep) hCount <= hCount+1'd1;

//-------------------------------------------------------------------------------------------------

wire[ 7:0] romQ;
wire[13:0] romA = a[13:0];

rom #(.KB(16), .FN("basic.hex")) Rom
(
	.clock  (clock  ),
	.ce     (ce     ),
	.q      (romQ   ),
	.a      (romA   )
);

//-------------------------------------------------------------------------------------------------

wire[ 7:0] videoQ;
wire[13:0] videoA = vma;

wire shmWe = !(!mreq && !wr && a[15:14] == 2'b01);
wire[ 7:0] shmQ;
wire[13:0] shmA = a[13:0];

dprf #(.KB(16)) Ram
(
	.clock  (clock  ),
	.ce1    (vcep   ),
	.q1     (videoQ ),
	.a1     (videoA ),
	.ce2    (ce     ),
	.we2    (shmWe  ),
	.d2     (d      ),
	.q2     (shmQ   ),
	.a2     (shmA   )
);

reg[7:0] video;
always @(posedge clock) if(vcen) if(hCount == 0) video <= videoQ;

//-------------------------------------------------------------------------------------------------

wire sdrRd = !(!mreq && !rd && a[15:14] == 2'b10);
wire sdrWr = !(!mreq && !wr && a[15:14] == 2'b10);

wire[15:0] sdrD = {2{d}};
wire[15:0] sdrQ;
wire[23:0] sdrA  = { 10'd0, a[13:0] };

sdram SDram
(
	.clock  (clock  ),
	.reset  (reset  ),
	.ready  (ready  ),
	.refresh(rfsh   ),
	.write  (sdrWr  ),
	.read   (sdrRd  ),
	.portD  (sdrD   ),
	.portQ  (sdrQ   ),
	.portA  (sdrA   ),
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

wire[7:0] colorQ;
wire[9:0] colorA = vma[9:0];

wire colWe = !(!mreq && !wr && a[15:10] == 6'b111100);
wire[7:0] colD = d;
wire[7:0] colQ;
wire[9:0] colA = a[9:0];

dprf #(.KB(1)) ColorRam
(
	.clock  (clock  ),
	.ce1    (vcep   ),
	.q1     (colorQ ),
	.a1     (colorA ),
	.ce2    (ce     ),
	.we2    (colWe  ),
	.d2     (colD   ),
	.q2     (colQ   ),
	.a2     (colA   )
);

reg[7:0] csr;
always @(posedge clock) if(vcen) if(hCount == 0) csr <= { csr[3:0], colorQ[3:0] };

//-------------------------------------------------------------------------------------------------

wire[7:0] charQ;
wire[9:0] charA = { video[6:0], vra };

wire chrWe = !(!mreq && !wr && a[15:10] == 6'b111101);
wire[7:0] chrQ;
wire[9:0] chrA = a[9:0];

dprf #(.KB(1)) CharRam
(
	.clock  (clock  ),
	.ce1    (vcep   ),
	.q1     (charQ  ),
	.a1     (charA  ),
	.ce2    (ce     ),
	.we2    (chrWe  ),
	.d2     (d      ),
	.q2     (chrQ   ),
	.a2     (chrA   )
);

//-------------------------------------------------------------------------------------------------

wire[ 7:0] fontQ;
wire[10:0] fontA = { video, vra };

rom #(.KB(2), .FN("font.hex")) FontRom
(
	.clock  (clock  ),
	.ce     (vcep   ),
	.q      (fontQ  ),
	.a      (fontA  )
);

//-------------------------------------------------------------------------------------------------

reg[7:0] psr;
wire ds = video[7] && ((!c && !video[6]) || (!b && video[6]));
always @(posedge clock) if(vcen) if(hCount == 0) psr <= ds ? charQ : fontQ; else psr <= { psr[6:0], 1'b0 };

//-------------------------------------------------------------------------------------------------

wire[7:0] keyQ;
wire[7:0] keyA = a[7:0];

keyboard Keyboard
(
	.clock  (clock  ),
	.code   (ps2Code),
	.strobe (ps2Strb),
	.pressed(ps2Prsd),
	.f11    (f11    ),
	.f5     (f5     ),
	.q      (keyQ   ),
	.a      (keyA   )
);

//-------------------------------------------------------------------------------------------------

assign pixel = psr[7];
assign color = csr[7:4];

assign q
	= a[15:14] == 2'b00 ? romQ
	: a[15:14] == 2'b01 ? shmQ
	: a[15:14] == 2'b10 ? sdrQ[7:0]
	: a[15:10] == 6'b111100 ? colQ
	: a[15:10] == 6'b111101 ? chrQ
	: a[15:10] == 6'b111110 ? keyQ
	: 8'hFF;

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
