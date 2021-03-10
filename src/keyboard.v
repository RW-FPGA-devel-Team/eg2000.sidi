//-------------------------------------------------------------------------------------------------
module keyboard
//-------------------------------------------------------------------------------------------------
(
	input  wire      clock,
	input  wire[7:0] code,
	input  wire      strobe,
	input  wire      pressed,
	output wire      f11,
	output wire      f5,
	output wire[7:0] q,
	input  wire[7:0] a
);
//-------------------------------------------------------------------------------------------------

reg F11;
reg F5;

reg left;
reg backspace;

reg[7:0] key[7:0];

always @(posedge clock) if(strobe)
case(code)

	8'h54: key[0][0] <= pressed; // @
	8'h1C: key[0][1] <= pressed; // A
	8'h32: key[0][2] <= pressed; // B
	8'h21: key[0][3] <= pressed; // C
	8'h23: key[0][4] <= pressed; // D
	8'h24: key[0][5] <= pressed; // E
	8'h2B: key[0][6] <= pressed; // F
	8'h34: key[0][7] <= pressed; // G

	8'h33: key[1][0] <= pressed; // H
	8'h43: key[1][1] <= pressed; // I
	8'h3B: key[1][2] <= pressed; // J
	8'h42: key[1][3] <= pressed; // K
	8'h4B: key[1][4] <= pressed; // L
	8'h3A: key[1][5] <= pressed; // M
	8'h31: key[1][6] <= pressed; // N
	8'h44: key[1][7] <= pressed; // O

	8'h4D: key[2][0] <= pressed; // P
	8'h15: key[2][1] <= pressed; // Q
	8'h2D: key[2][2] <= pressed; // R
	8'h1B: key[2][3] <= pressed; // S
	8'h2C: key[2][4] <= pressed; // T
	8'h3C: key[2][5] <= pressed; // U
	8'h2A: key[2][6] <= pressed; // V
	8'h1D: key[2][7] <= pressed; // W

	8'h22: key[3][0] <= pressed; // X
	8'h35: key[3][1] <= pressed; // Y
	8'h1A: key[3][2] <= pressed; // Z
	// ------------------------; // 
	8'h05: key[3][4] <= pressed; // F1
	8'h06: key[3][5] <= pressed; // F2
	8'h04: key[3][6] <= pressed; // F3
	8'h0C: key[3][7] <= pressed; // F4

	8'h45: key[4][0] <= pressed; // 0
	8'h16: key[4][1] <= pressed; // 1
	8'h1E: key[4][2] <= pressed; // 2
	8'h26: key[4][3] <= pressed; // 3
	8'h25: key[4][4] <= pressed; // 4
	8'h2E: key[4][5] <= pressed; // 5
	8'h36: key[4][6] <= pressed; // 6
	8'h3D: key[4][7] <= pressed; // 7

	8'h3E: key[5][0] <= pressed; // 8
	8'h46: key[5][1] <= pressed; // 9
	8'h4E: key[5][2] <= pressed; // :
	8'h4C: key[5][3] <= pressed; // ;
	8'h41: key[5][4] <= pressed; // ,
	8'h52: key[5][5] <= pressed; // -
	8'h49: key[5][6] <= pressed; // .
	8'h4A: key[5][7] <= pressed; // /

	8'h5A: key[6][0] <= pressed; // NL
	8'h55: key[6][1] <= pressed; // CLR
	8'h76: key[6][2] <= pressed; // BRK
	8'h75: key[6][3] <= pressed; // Up
	8'h72: key[6][4] <= pressed; // Down
//	8'h6B: key[6][5] <= pressed; // Left
	8'h74: key[6][6] <= pressed; // Right
	8'h29: key[6][7] <= pressed; // SPACE

	8'h12: key[7][0] <= pressed; // Shift
//	8'h59: key[7][1] <= pressed; // ModSel
	// ------------------------; // 
//	8'h59: key[7][3] <= pressed; // rpt
	8'h14: key[7][4] <= pressed; // ctrl
	// ------------------------; // 
	// ------------------------; // 
//	8'h59: key[7][7] <= pressed; // lp

	8'h78: F11 <= pressed;
	8'h03: F5  <= pressed;

	8'h6B: left <= pressed; // Left
	8'h66: backspace <= pressed; // Backspace
endcase

//-------------------------------------------------------------------------------------------------

assign f11 = F11;
assign f5  = F5;

wire key65 = left|backspace;

assign q =
{
	(a[0]&key[0][7])|(a[1]&key[1][7])|(a[2]&key[2][7])|(a[3]&key[3][7])|(a[4]&key[4][7])|(a[5]&key[5][7])|(a[6]&key[6][7])|(a[7]&key[7][7]),
	(a[0]&key[0][6])|(a[1]&key[1][6])|(a[2]&key[2][6])|(a[3]&key[3][6])|(a[4]&key[4][6])|(a[5]&key[5][6])|(a[6]&key[6][6])|(a[7]&key[7][6]),
	(a[0]&key[0][5])|(a[1]&key[1][5])|(a[2]&key[2][5])|(a[3]&key[3][5])|(a[4]&key[4][5])|(a[5]&key[5][5])|(a[6]&key65    )|(a[7]&key[7][5]),
	(a[0]&key[0][4])|(a[1]&key[1][4])|(a[2]&key[2][4])|(a[3]&key[3][4])|(a[4]&key[4][4])|(a[5]&key[5][4])|(a[6]&key[6][4])|(a[7]&key[7][4]),
	(a[0]&key[0][3])|(a[1]&key[1][3])|(a[2]&key[2][3])|(a[3]&key[3][3])|(a[4]&key[4][3])|(a[5]&key[5][3])|(a[6]&key[6][3])|(a[7]&key[7][3]),
	(a[0]&key[0][2])|(a[1]&key[1][2])|(a[2]&key[2][2])|(a[3]&key[3][2])|(a[4]&key[4][2])|(a[5]&key[5][2])|(a[6]&key[6][2])|(a[7]&key[7][2]),
	(a[0]&key[0][1])|(a[1]&key[1][1])|(a[2]&key[2][1])|(a[3]&key[3][1])|(a[4]&key[4][1])|(a[5]&key[5][1])|(a[6]&key[6][1])|(a[7]&key[7][1]),
	(a[0]&key[0][0])|(a[1]&key[1][0])|(a[2]&key[2][0])|(a[3]&key[3][0])|(a[4]&key[4][0])|(a[5]&key[5][0])|(a[6]&key[6][0])|(a[7]&key[7][0])
};

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
