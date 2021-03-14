// =============================================================================
// FILE: pwm_ctrl.sv
// DATE: 27-Dec-2018
// AUTHOR: Sammy Carbajal
// =============================================================================
// PURPOSE: 
//   Host Interface
// =============================================================================
// PARAMETERS: 
//   NAME               DEFAULT  DESCRIPTION       
//   NUM_CH 		8 	 Number of microphones
//   CNT_WIDTH 		16 	 Counter width
// =============================================================================

module pwm_ctrl #(
  parameter 	NUM_CH = 8,
  parameter 	CNT_WIDTH = 16
)(
  // Avalon MM interface
  input clock, 
  input resetn, 
  input read, 
  input write, 
  input [5:0] address,
  input chipselect,
  input [3:0] byteenable,
  input [31:0] writedata,
  output [31:0] readdata,

  // PWM output
  output logic [NUM_CH-1:0] 	pwm_out_ff
);

// Local parameters
localparam CTRL_1_REG_ADDR   = 10'h0;
localparam CTRL_2_REG_ADDR   = 10'h1;
localparam CH_CTRL_REG_ADDR  = 10'h2;

// ====================
//   Internal signals
// ====================

// Miscellaneous
logic [NUM_CH-1:0]      ch_en_ff;
logic [CNT_WIDTH-1:0]   cnt_max_ff;
logic [CNT_WIDTH-1:0]   ch_duty_ff [NUM_CH-1:0];

// Counter
logic [CNT_WIDTH-1:0]   cnt_ff;

integer i, k, l;
genvar j;

// Sky-blue
logic [3:0] local_byteenable;

logic ctrl_1_reg_sel;
logic ctrl_2_reg_sel;
logic [NUM_CH-1:0] ch_duty_n_reg_sel;

logic [31:0] ctrl_1_read_data;
logic [31:0] ctrl_2_read_data;
logic [31:0] ch_duty_n_read_data;

logic [31:0] byteenable_ext;
logic [63:0] byteenable_ext_2;

// ====================
//  Register Selection
// ====================

assign ctrl_1_reg_sel   = address == CTRL_1_REG_ADDR;
assign ctrl_2_reg_sel   = address == CTRL_2_REG_ADDR;

always_comb
for (i = 0; i < NUM_CH ; i=i+1)
  begin
  ch_duty_n_reg_sel[i]  = address == (CH_CTRL_REG_ADDR + i);
  end

assign local_byteenable = (chipselect & write) ? byteenable : 4'd0;


assign readdata = (ctrl_1_read_data   & {32{ctrl_1_reg_sel}}) |
		  (ctrl_2_read_data   & {32{ctrl_2_reg_sel}}) |
		  ch_duty_n_read_data ;

// Byte enable extended
assign byteenable_ext = {{8{local_byteenable[3]}},
			 {8{local_byteenable[2]}},
			 {8{local_byteenable[1]}},
			 {8{local_byteenable[0]}}};

// =================
//  CTRL_1 register
// =================

// Counter maximum
always_ff@(posedge clock, negedge resetn)
  if (!resetn)
    cnt_max_ff <= {CNT_WIDTH{1'b1}};
  else if (ctrl_1_reg_sel)
    cnt_max_ff <=  ~byteenable_ext & cnt_max_ff |
                    byteenable_ext & writedata;		  

// Read data
assign ctrl_1_read_data = cnt_max_ff;

// =================
//  CTRL_2 register
// =================

// Channel enable
always_ff@(posedge clock, negedge resetn)
  if (!resetn)
    ch_en_ff <= {NUM_CH{1'b0}};
  else if (ctrl_2_reg_sel)
    ch_en_ff <= ~byteenable_ext & ch_en_ff | 
          	 byteenable_ext & writedata;

// Read data
assign ctrl_2_read_data = ch_en_ff;

// =======================
//   CH_CTRL[n] register
// =======================

// Channel duty 
generate
  for (j=0; j<NUM_CH; j=j+1) 
  begin: ch_duty
    always_ff@(posedge clock, negedge resetn)
    begin
      if (!resetn)
        ch_duty_ff[j] <= {CNT_WIDTH{1'b0}};
      else if (ch_duty_n_reg_sel[j])
        ch_duty_ff[j] <= ~byteenable_ext & ch_duty_ff[j] | 
          	          byteenable_ext & writedata;
    end
  end
endgenerate

// Read data
always_comb
begin
  ch_duty_n_read_data = 32'd0;
  for (k=0; k<NUM_CH; k=k+1)
     ch_duty_n_read_data = ch_duty_n_read_data | 
			   ({{{32-CNT_WIDTH}{1'b0}},ch_duty_ff[k]} &
			   {32{ch_duty_n_reg_sel[k]}});
end

// ===================
//    PWM Control
// ===================

// Counter
always_ff@(posedge clock, negedge resetn)
  if (!resetn)
    cnt_ff <= 'd0;
  else if (!(|ch_en_ff) || cnt_ff == cnt_max_ff)
    cnt_ff <= 'd0;
  else 
    cnt_ff <= cnt_ff + 1;

// PWM output
always_ff@(posedge clock, negedge resetn)
  if (!resetn)
    pwm_out_ff <= {NUM_CH{1'b0}};
  else for (l=0; l<NUM_CH; l=l+1) 
    pwm_out_ff[l] <= (cnt_ff < ch_duty_ff[l]) && ch_en_ff[l];

endmodule
