//This module is derived from Ettus's axi_wrapper.  It essentially operates in
//that modules SIMPLE and RESIZE_OUTPUT modes.  It has added logic that manages 
//timestamp correction required due to the output sampling rate not
//being the same as the input rate.

module axi_wrapper_mod
	#(parameter MTU=9,
	  parameter USE_SEQ_NUM=0)
	(
	input clk, input reset,

    input clear_tx_seqnum,
    input [15:0] next_dst,             

    // To NoC Shell
    input set_stb, input [7:0] set_addr, input [31:0] set_data,
    input [63:0] i_tdata, input i_tlast, input i_tvalid, output i_tready,
    output [63:0] o_tdata, output o_tlast, output o_tvalid, input o_tready,

    // To AXI IP
    output [31:0] m_axis_data_tdata, output [127:0] m_axis_data_tuser, output m_axis_data_tlast, output m_axis_data_tvalid, input m_axis_data_tready,
    input [31:0] s_axis_data_tdata, input [127:0] s_axis_data_tuser, input s_axis_data_tlast, input s_axis_data_tvalid, output s_axis_data_tready, 
    input [15:0] m_axis_pkt_len_tdata, input m_axis_pkt_len_tvalid, output m_axis_pkt_len_tready, // Used when RESIZE_INPUT_PACKET=1

    // Variable number of AXI configuration busses
    output [31:0] m_axis_config_tdata,
    output m_axis_config_tlast,
    output m_axis_config_tvalid,
    input m_axis_config_tready
    );

	// /////////////////////////////////////////////////////////
	// Input side handling, chdr_deframer
	wire [127:0] s_axis_data_tuser_int, m_axis_data_tuser_int;
	wire         s_axis_data_tlast_int, m_axis_data_tlast_int;
	reg [15:0]   m_axis_pkt_len_reg = 16'd8;
	reg          sof_in = 1'b1;
	reg          first_pkt_out;
	reg [63:0]   vita_time_accum, vita_time_reg;
	wire         has_time = m_axis_data_tuser[125];
	reg          has_time_reg, has_time_changed;
	wire [127:0] header_fifo_i_tdata  = {m_axis_data_tuser[127:126], m_axis_data_tuser[125:96], m_axis_data_tuser[79:64],
                                                           next_dst,(first_pkt_out ? vita_time_in : vita_time_reg)};
	wire         header_fifo_i_tvalid = sof_in & m_axis_data_tvalid & m_axis_data_tready;

	chdr_deframer chdr_deframer
     (.clk(clk), .reset(reset), .clear(clear_tx_seqnum),
      .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
      .o_tdata(m_axis_data_tdata), .o_tuser(m_axis_data_tuser_int), .o_tlast(m_axis_data_tlast_int), .o_tvalid(m_axis_data_tvalid), .o_tready(m_axis_data_tready));

	assign m_axis_data_tuser = m_axis_data_tuser_int;

	//check if header's has_time field has changed
	always @(posedge clk)
	begin
		has_time_reg <= has_time;
		has_time_changed <= has_time_reg ^ has_time;
	end
   
   // Only store header once per packet
	always @(posedge clk)
	if(reset | clear_tx_seqnum)
		sof_in     <= 1'b1;
	else
		if(m_axis_data_tvalid & m_axis_data_tready)
			if(m_axis_data_tlast)
				sof_in <= 1'b1;
			else
				sof_in <= 1'b0;
  
    // FIFO 
    axi_fifo_short #(.WIDTH(128)) header_fifo
    (.clk(clk), .reset(reset), .clear(clear_tx_seqnum),
     .i_tdata(header_fifo_i_tdata),
     .i_tvalid(header_fifo_i_tvalid), .i_tready(),
     .o_tdata(s_axis_data_tuser_int), .o_tvalid(), .o_tready(s_axis_data_tlast_int & s_axis_data_tvalid & s_axis_data_tready),
     .occupied(), .space());
    
	reg [15:0] s_axis_pkt_cnt;
	reg [15:0] s_axis_pkt_len;
	always @(posedge clk) begin
		if (reset | clear_tx_seqnum) begin
			s_axis_pkt_cnt        <= 4;
			s_axis_pkt_len        <= 0;
		end else begin
		// Remove header
			s_axis_pkt_len <= s_axis_data_tuser_int[125] ? s_axis_data_tuser_int[111:96]-16 : s_axis_data_tuser_int[111:96]-8;
			if (s_axis_data_tvalid & s_axis_data_tready) begin
				if ((s_axis_pkt_cnt >= s_axis_pkt_len) | s_axis_data_tlast) begin
				//if (s_axis_pkt_cnt >= 16'd1024) begin
					s_axis_pkt_cnt        <= 4;
				end else begin
				s_axis_pkt_cnt        <= s_axis_pkt_cnt + 4;
				end
			end
		end
	end
       
	assign s_axis_data_tlast_int = (s_axis_pkt_cnt >= s_axis_pkt_len) | s_axis_data_tlast;  
	//assign s_axis_data_tlast_int = (s_axis_pkt_cnt >= 16'd1024);   
	assign m_axis_data_tlast     = m_axis_data_tlast_int;
	assign m_axis_pkt_len_tready = 1'b0;
    
    

	// /////////////////////////////////////////////////////////
	// Output side handling, chdr_framer
	chdr_framer #(.SIZE(MTU), .USE_SEQ_NUM(USE_SEQ_NUM)) chdr_framer
		(.clk(clk), .reset(reset), .clear(clear_tx_seqnum),
		.i_tdata(s_axis_data_tdata), .i_tuser(s_axis_data_tuser_int), .i_tlast(s_axis_data_tlast_int), .i_tvalid(s_axis_data_tvalid), .i_tready(s_axis_data_tready),
		.o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready));


	/********************************************************
	** Adjust VITA time
	********************************************************/
  
	always @(posedge clk) begin
		if (reset | clear_tx_seqnum ) begin
			first_pkt_out              <= 1'b1;
			vita_time_reg              <= 64'd1;
		end else begin
			if (o_tvalid & o_tready) begin
				if (o_tlast & first_pkt_out) begin
					first_pkt_out    <= 1'b0;
					vita_time_reg    <= vita_time_in;
				end else begin
					vita_time_reg    <= vita_time_reg + 1;
				end
			end
		end
	end

	wire has_time_in; 
	wire eob_in; 
	wire has_time_out; 
	wire eob_in_header;
	wire [15:0] payload_length_in; 
	wire [15:0] payload_length_out;
	wire [63:0] vita_time_in;
	wire [63:0] vita_time_out;
	cvita_hdr_decoder cvita_hdr_decoder_in_header (
		.header(m_axis_data_tuser_int), .pkt_type(), .eob(eob_in_header),
		.has_time(has_time_in), .seqnum(), .length(), .payload_length(payload_length_in),
		.src_sid(), .dst_sid(), .vita_time(vita_time_in));
   
   
endmodule // axi_wrapper_mod
