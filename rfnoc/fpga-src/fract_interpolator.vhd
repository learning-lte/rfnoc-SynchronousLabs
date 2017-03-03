--
--
--	SYNCHRONOUS LAB IP
--	www.synchronouslabs.com
--	
--Module Name:  fract_interpolator
--
--Description:
--This module serves as the top level module of a fractional interpolator.  
--It is implemented as a 16 Tap, 4096 phase systolic FIR filter capable of outptuing 
--data at sample rates between fs*4099/4095 and fs*4096.  The filter offers a SFDR of ~78dBc.
--
--
--             --------------     ---------------------     ---------------
--             |            |     |                   |     |             |
--             |            |     |                   |     |             |
--   Input---->|   Fifo     |---->|    Resampler      |---->|     Fifo    |---->Output
--             |            |     |                   |     |             |    
--             |            |     |                   |     |             |  
--             |            |     |                   |     |             |
--             --------------     ---------------------     ---------------
--
--
--Version: 
--1.00 - (2/19/17) Initial Release 
--
--If you are in need of custom filter with different perfrmance or resource allocations, let us know. We offer 
--custom IP and design services specific to FPGA based software defined radio implementations.  You can reach us at
--www.synchronouslabs.com 
--



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity fract_interpolator is
generic(
    DIN_WIDTH                 : integer := 16
);
Port ( 
    i_clk         : in   std_logic;
    i_rst         : in   std_logic;
    i_clear       : in   std_logic;  
    i_din_i       : in   std_logic_vector(DIN_WIDTH-1 downto 0); 
    i_din_q       : in   std_logic_vector(DIN_WIDTH-1 downto 0); 
    i_din_vld     : in   std_logic; 
    i_rdy         : in   std_logic; 
    
    i_set_stb     : in   std_logic;
    i_set_addr    : in   std_logic_vector(7 downto 0);
    i_set_data    : in   std_logic_vector(31 downto 0);       
    
    o_rdy         : out  std_logic;
    o_tdata       : out  std_logic_vector(31 downto 0); 
    o_tvalid      : out  std_logic
    
);
end fract_interpolator;

architecture Behavioral of fract_interpolator is

component ila_0
  port (
	clk     : in STD_LOGIC;
	probe0  : in STD_LOGIC_VECTOR(127 downto 0)
  );
end component;

--~ COMPONENT dds
  --~ PORT (
    --~ aclk : IN STD_LOGIC;
    --~ aclken : IN STD_LOGIC;
    --~ m_axis_data_tvalid : OUT STD_LOGIC;
    --~ m_axis_data_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  --~ );
--~ END COMPONENT;


constant DELTA_REG            : integer := 192;
signal s_delta                : std_logic_vector(31 downto 0);
signal s_delta_ext            : std_logic_vector(47 downto 0);
signal s_delta_chgd           : std_logic;
signal s_dout                 : std_logic_vector(31 downto 0); 
signal s_dout_vld             : std_logic;
signal s_filter_out           : std_logic_vector(31 downto 0); 
signal s_filter_vld           : std_logic;
signal s_sync                 : std_logic;
signal s_active               : std_logic; 
signal s_active_z1            : std_logic; 
signal s_en                   : std_logic;
signal s_rdy                  : std_logic;
signal s_complex_din          : std_logic_vector(31 downto 0);
signal s_mfifo_valid          : std_logic;
signal s_fifo_dout            : std_logic_vector(31 downto 0);
signal s_data_cnt_0           : std_logic_vector(9 downto 0);
signal s_data_cnt_1           : std_logic_vector(9 downto 0);
signal s_fifo_out_full        : std_logic;
signal s_fifo_full            : std_logic;
signal s_fifo_full_z1         : std_logic;
signal s_wr_en_1              : std_logic;
signal s_rd_en_1              : std_logic;
signal s_full_1               : std_logic;
signal s_empty_1              : std_logic;

signal s_wr_en_0              : std_logic;
signal s_rd_en_0              : std_logic;
signal s_full_0               : std_logic;
signal s_empty_0              : std_logic;

signal s_i_rdy                : std_logic;
signal s_phase                : std_logic_vector(11 downto 0) := (others=>'0');

signal s_din                  : std_logic_vector(15 downto 0);
signal s_din_vld              : std_logic; 
   
signal s_ila_probe            : std_logic_vector(127 downto 0);
signal s_dds_dout             : std_logic_vector(31 downto 0);
signal s_dds_vld              : std_logic;
signal s_clear                : std_logic;


attribute keep : string;  
attribute keep of s_fifo_dout    : signal is "true";  
attribute keep of s_delta_ext    : signal is "true"; 
attribute keep of s_dout         : signal is "true";  
attribute keep of s_data_cnt_0   : signal is "true"; 
attribute keep of s_data_cnt_1   : signal is "true"; 
attribute keep of s_en           : signal is "true"; 
attribute keep of s_dout_vld     : signal is "true";  
attribute keep of s_active       : signal is "true"; 
attribute keep of s_rdy          : signal is "true"; 
attribute keep of s_mfifo_valid  : signal is "true"; 
attribute keep of s_sync         : signal is "true";
attribute keep of s_wr_en_0      : signal is "true";
attribute keep of s_rd_en_0      : signal is "true";
attribute keep of s_wr_en_1      : signal is "true";
attribute keep of s_rd_en_1      : signal is "true";
attribute keep of s_i_rdy        : signal is "true";
attribute keep of s_din          : signal is "true";
attribute keep of s_din_vld      : signal is "true";
attribute keep of s_full_0       : signal is "true";
attribute keep of s_empty_0      : signal is "true";
attribute keep of s_full_1       : signal is "true";
attribute keep of s_empty_1      : signal is "true";
attribute keep of s_clear        : signal is "true";
attribute keep of s_delta        : signal is "true";
attribute keep of s_filter_vld   : signal is "true";
attribute keep of s_filter_out   : signal is "true";

begin

o_tdata        <= s_fifo_dout;
o_tvalid       <= not(s_empty_1);
o_rdy          <= not(s_full_0);           
s_complex_din  <= i_din_i & i_din_q;
s_en           <= not(s_full_1) and not(s_empty_0);
s_wr_en_0      <= i_din_vld and not(s_full_0);
s_rd_en_0      <= s_sync;
s_wr_en_1      <= s_filter_vld;
s_rd_en_1      <= i_rdy and not(s_empty_1);
s_delta_ext    <= s_delta & X"0000";
s_i_rdy        <= i_rdy;
s_din          <= i_din_i;
s_din_vld      <= i_din_vld;
s_clear        <= i_clear;




--Register control data write
process(i_clk)
begin
    if rising_edge(i_clk) then
        if (i_rst='1') then
            s_delta <= X"00000000";
        else
            if ( (i_set_addr= std_logic_vector(to_unsigned(DELTA_REG,8 ))) and (i_set_stb='1') ) then
                s_delta <= i_set_data;
                s_delta_chgd <= '1';
            else
                s_delta <= s_delta;
                s_delta_chgd <= '0';
            end if;
        end if;
    end if;
end process;



--Input data fifo  
din_fifo_inst: entity work.din_fifo
  PORT MAP (
    clk        => i_clk,
    srst       => i_rst,
    din        => s_complex_din,
    wr_en      => s_wr_en_0,
    rd_en      => s_rd_en_0,
    dout       => s_dout,
    full       => open,
    empty      => open,
    data_count => s_data_cnt_0,
    prog_full  => s_full_0,
    prog_empty => s_empty_0
  );
                

--Fractional Resampler         
fract_interp_filter_uut: entity work.fract_interp_filter 
Port Map( 
    i_clk         => i_clk,
    i_rst         => i_rst, 
    i_din_i       => s_dout(31 downto 16), 
    i_din_q       => s_dout(15 downto 0),  
    i_delta       => s_delta_ext,
    i_phase       => s_phase,
    i_ce          => s_en,
    o_dout        => s_filter_out,
    o_dout_vld    => s_filter_vld,
    o_sync        => s_sync  
);

--Output data fifo  
dout_fifo_inst: entity work.din_fifo
  PORT MAP (
    clk        => i_clk,
    srst       => i_rst,
    din        => s_filter_out,
    wr_en      => s_wr_en_1,
    rd_en      => s_rd_en_1,
    dout       => s_fifo_dout,
    full       => open,
    empty      => open,
    data_count => s_data_cnt_1,
    prog_full  => s_full_1,
    prog_empty => s_empty_1
  );


--~ ila_0_inst: ila_0
--~ port map( 
	--~ clk     => i_clk,
	--~ probe0  => s_ila_probe
 --~ );
 

s_ila_probe(47 downto 0)    <= s_delta_ext;
s_ila_probe(63 downto 48)   <= s_complex_din(15 downto 0);
s_ila_probe(64)             <= s_en;
s_ila_probe(80 downto 65)   <= s_filter_out(15 downto 0);
s_ila_probe(81)             <= s_filter_vld;
s_ila_probe(82)             <= s_sync;
s_ila_probe(92 downto 83)   <= s_data_cnt_0;
s_ila_probe(95 downto 93)   <= (others=>'0');
s_ila_probe(96)             <= s_i_rdy;
s_ila_probe(97)             <= s_din_vld;
s_ila_probe(98)             <= s_empty_0;
s_ila_probe(99)             <= s_full_0;
s_ila_probe(100)            <= s_wr_en_0;
s_ila_probe(101)            <= s_rd_en_0;
s_ila_probe(102)            <= s_empty_1;
s_ila_probe(103)            <= s_full_1;
s_ila_probe(104)            <= s_wr_en_1;
s_ila_probe(105)            <= s_rd_en_1;
s_ila_probe(121 downto 106) <= s_din(15 downto 0);
s_ila_probe(127 downto 122) <= (others=>'0');

end Behavioral;
