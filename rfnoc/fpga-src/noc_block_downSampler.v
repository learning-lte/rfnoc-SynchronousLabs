/*

	SYNCHRONOUS LAB IP
	www.synchronouslabs.com

Module Name:  noc_block_downSampler

Description:
This module serves as a fraction downsampler implemented as an RF Noc Block.
It is implemented as a 16 Tap, 4096 phase transposed FIR filter capable of outptuing 
data at sample rates between fs*4095/4096 and fs*1/4096.  The filter 
offers a SFDR of ~78dBc.

Version: 
1.00 - (2/19/17) Initial Release 

If you are in need of custom filter with different perfrmance or resource allocations, let us know. We offer 
custom IP and design services specific to FPGA based software defined radio implementations.  You can reach us at
www.synchronouslabs.com 
*/

module noc_block_downSampler #(
	parameter NOC_ID = 64'hED6E9C5B02328DA5,
	parameter STR_SINK_FIFOSIZE = 11)
(
	input bus_clk, input bus_rst,
	input ce_clk, input ce_rst,
	input  [63:0] i_tdata, input  i_tlast, input  i_tvalid, output i_tready,
	output [63:0] o_tdata, output o_tlast, output o_tvalid, input  o_tready,
	output [63:0] debug
);
 
  
	wire [31:0] set_data;
	wire [7:0]  set_addr;
	wire        set_stb;
	reg  [63:0] rb_data;
	wire [7:0]  rb_addr;

	wire [63:0] cmdout_tdata, ackin_tdata;
	wire        cmdout_tlast, cmdout_tvalid, cmdout_tready, ackin_tlast, ackin_tvalid, ackin_tready;

	wire [63:0] str_sink_tdata, str_src_tdata;
	wire        str_sink_tlast, str_sink_tvalid, str_sink_tready, str_src_tlast, str_src_tvalid, str_src_tready;

	wire [15:0] src_sid;
	wire [15:0] next_dst_sid, resp_out_dst_sid;
	wire [15:0] resp_in_dst_sid;

	wire        clear_tx_seqnum;
  	wire [31:0]  m_axis_data_tdata;
	wire         m_axis_data_tlast;
	wire         m_axis_data_tvalid;
	wire         m_axis_data_tready;
	wire [127:0] m_axis_data_tuser;

	wire [31:0]  s_axis_data_tdata;
	wire         s_axis_data_tlast;
	wire         s_axis_data_tvalid;
	wire         s_axis_data_tready;
	wire [127:0] s_axis_data_tuser;

	noc_shell #(
		.NOC_ID(NOC_ID),
		.STR_SINK_FIFOSIZE(STR_SINK_FIFOSIZE))
	noc_shell (
		.bus_clk(bus_clk), .bus_rst(bus_rst),
		.i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
		.o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready),
		// Computer Engine Clock Domain
		.clk(ce_clk), .reset(ce_rst),
		// Control Sink
		.set_data(set_data), .set_addr(set_addr), .set_stb(set_stb),
		.rb_stb(1'b1), .rb_data(rb_data), .rb_addr(rb_addr),
		// Control Source
		.cmdout_tdata(cmdout_tdata), .cmdout_tlast(cmdout_tlast), .cmdout_tvalid(cmdout_tvalid), .cmdout_tready(cmdout_tready),
		.ackin_tdata(ackin_tdata), .ackin_tlast(ackin_tlast), .ackin_tvalid(ackin_tvalid), .ackin_tready(ackin_tready),
		// Stream Sink
		.str_sink_tdata(str_sink_tdata), .str_sink_tlast(str_sink_tlast), .str_sink_tvalid(str_sink_tvalid), .str_sink_tready(str_sink_tready),
		// Stream Source
		.str_src_tdata(str_src_tdata), .str_src_tlast(str_src_tlast), .str_src_tvalid(str_src_tvalid), .str_src_tready(str_src_tready),
		// Stream IDs set by host
		.src_sid(src_sid),                   // SID of this block
		.next_dst_sid(next_dst_sid),         // Next destination SID
		.resp_in_dst_sid(resp_in_dst_sid),   // Response destination SID for input stream responses / errors
		.resp_out_dst_sid(resp_out_dst_sid), // Response destination SID for output stream responses / errors
		// Misc
		.vita_time('d0), .clear_tx_seqnum(clear_tx_seqnum),
		.debug(debug));
 
 
	axi_wrapper_mod #(
		.MTU(13))
	axi_wrapper_mod (
		.clk(ce_clk), .reset(ce_rst),
		.clear_tx_seqnum(clear_tx_seqnum),
		.next_dst(next_dst_sid),
		.set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
		.i_tdata(str_sink_tdata), .i_tlast(str_sink_tlast), .i_tvalid(str_sink_tvalid), .i_tready(str_sink_tready),
		.o_tdata(str_src_tdata), .o_tlast(str_src_tlast), .o_tvalid(str_src_tvalid), .o_tready(str_src_tready),
		.m_axis_data_tdata(m_axis_data_tdata),
		.m_axis_data_tlast(m_axis_data_tlast),
		.m_axis_data_tvalid(m_axis_data_tvalid),
		.m_axis_data_tready(m_axis_data_tready),
		.m_axis_data_tuser(),
		.s_axis_data_tdata(s_axis_data_tdata),
		.s_axis_data_tlast(1'b0),
		.s_axis_data_tvalid(s_axis_data_tvalid),
		.s_axis_data_tready(s_axis_data_tready),
		.s_axis_data_tuser(),
		.m_axis_config_tdata(),
		.m_axis_config_tlast(),
		.m_axis_config_tvalid(),
		.m_axis_config_tready(),
		.m_axis_pkt_len_tdata(),
		.m_axis_pkt_len_tvalid(),
		.m_axis_pkt_len_tready());
    

    
	fract_decimator fract_decimator_inst
	(
		.i_clk(ce_clk),         
		.i_rst(ce_rst),        
		.i_din_i(m_axis_data_tdata[31:16]),        
		.i_din_q(m_axis_data_tdata[15:0]),  
		.i_din_vld(m_axis_data_tvalid), 
		.i_rdy(s_axis_data_tready),     
		.i_set_stb(set_stb),     
		.i_set_addr(set_addr),    
		.i_set_data(set_data),  
		.o_rdy(m_axis_data_tready),
		.o_tdata(s_axis_data_tdata),
		.o_tvalid(s_axis_data_tvalid)              
		);  
    
  

endmodule
