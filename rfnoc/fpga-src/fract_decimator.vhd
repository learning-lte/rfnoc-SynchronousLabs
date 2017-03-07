--~ 
--~ 
	--~ SYNCHRONOUS LAB IP
	--~ www.synchronouslabs.com
--~ 
--~ 
--~ This module serves as a fraction downsampler.  It is implemented as a 16 Tap, 4096 phase transposed
--~ FIR filter capable of outptuing data at sample rates between fs*4095/4096 and fs*1/4096.  The filter 
--~ offers a SFDR of ~78dBc.
--~ 
--~ If you are in need of custom filter with different perfrmance or resource allocations, let us know. We offer 
--~ design services specific to FPGA based software defined radio implementations.  You can reach us at
--~ www.synchronouslabs.com 


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fract_decimator is
generic(
    DIN_WIDTH                 : integer := 16
);
Port ( 
    i_clk         : in   std_logic;
    i_rst         : in   std_logic;
    i_din_i       : in   std_logic_vector(DIN_WIDTH-1 downto 0); 
    i_din_q       : in   std_logic_vector(DIN_WIDTH-1 downto 0); 
    i_din_vld     : in   std_logic; 
    i_rdy         : in   std_logic; 
    
    i_set_stb     : in   std_logic;
    i_set_addr    : in   std_logic_vector(7 downto 0);
    i_set_data    : in   std_logic_vector(31 downto 0);       
     
	o_rdy          : out  std_logic;
    o_tdata        : out  std_logic_vector(31 downto 0); 
    o_tvalid       : out  std_logic
    
);
end fract_decimator;

architecture Behavioral of fract_decimator is


component fract_dec_filter is
generic(
    ACCUM_WIDTH               : integer;
    ADDR_WIDTH                : integer;
    COEFF_WIDTH               : integer;
    NUM_TAPS                  : integer;
    DIN_WIDTH                 : integer;      
    ADDR_GEN_BITS             : integer
);
Port ( 
    i_clk         : in   std_logic;
    i_rst         : in   std_logic;  
    i_din_i       : in   std_logic_vector(DIN_WIDTH-1 downto 0); 
    i_din_q       : in   std_logic_vector(DIN_WIDTH-1 downto 0); 
    i_delta       : in   std_logic_vector(47 downto 0);
    i_phase       : in   std_logic_vector(11 downto 0);
    i_din_vld     : in   std_logic; 
    o_dout        : out  std_logic_vector(31 downto 0); 
    o_dout_vld    : out  std_logic
    );
end component fract_dec_filter;



constant DELTA_REG             : integer := 192;
signal s_delta                 : std_logic_vector(31 downto 0);
signal s_delta_ext             : std_logic_vector(47 downto 0);
signal s_delta_chgd            : std_logic;
signal s_dout                  : std_logic_vector(31 downto 0); 
signal s_dout_vld              : std_logic;
signal s_ila_probe             : std_logic_vector(127 downto 0);
signal s_in_last               : std_logic;
signal s_fifo_rst              : std_logic;
signal s_reset_on_change       : std_logic; -- Reset the resampler everytime there is a rate change
signal s_reset_on_live_change  : std_logic; -- Reset when rate changes while streaming
signal s_active                : std_logic; 
signal s_rate_changed_hold     : std_logic;
signal s_dec_rate              : std_logic_vector(47 downto 0);
signal s_resamp_rst            : std_logic;
signal s_tready                : std_logic;
signal s_rate_changed          : std_logic;
signal s_shift_reset           : std_logic_vector(3 downto 0);
signal s_clear                 : std_logic;
signal s_tvalid                : std_logic;

signal s_din_i                 : std_logic_vector(DIN_WIDTH-1 downto 0); 
signal s_din_q                 : std_logic_vector(DIN_WIDTH-1 downto 0); 
signal s_din_vld               : std_logic; 
signal s_rdy                   : std_logic;


attribute keep : string;   
attribute keep of s_delta_ext  : signal is "true";  
attribute keep of s_delta      : signal is "true"; 
attribute keep of s_dout_vld   : signal is "true";
attribute keep of s_dout       : signal is "true";
attribute keep of s_rdy        : signal is "true";
attribute keep of s_din_i      : signal is "true";
attribute keep of s_din_vld    : signal is "true";


begin

o_tdata     <= s_dout;
o_tvalid    <= s_dout_vld when i_rdy='1' else '0';
o_rdy       <= '1';
s_delta_ext <= s_delta & X"0000";       

s_din_i     <= i_din_i;
s_din_q     <= i_din_q;
s_din_vld   <= i_din_vld; 
s_rdy       <= i_rdy;

process(i_clk)
begin
    if rising_edge(i_clk) then
        if (i_rst='1') then
            s_delta            <= X"40000000";
            s_rate_changed     <= '0';
        else
            if ( (i_set_addr= std_logic_vector(to_unsigned(DELTA_REG,8 ))) and (i_set_stb='1') ) then
                s_delta        <= i_set_data;
                s_rate_changed <= '1';
            else
                s_delta        <= s_delta;
                s_rate_changed <= '0';
            end if;
        end if;
    end if;
end process;
                
        
fract_decimator_uut: fract_dec_filter 
generic map(
    ACCUM_WIDTH               => 48,
    ADDR_WIDTH                => 12,
    COEFF_WIDTH               => 18,
    NUM_TAPS                  => 16,
    DIN_WIDTH                 => 16,      
    ADDR_GEN_BITS             => 48
)
Port Map( 
    i_clk         => i_clk,
    i_rst         => i_rst, 
    i_din_i       => i_din_i, 
    i_din_q       => i_din_q, 
    i_delta       => s_delta_ext,
    i_phase       => X"000",
    i_din_vld     => i_din_vld,
    o_dout        => s_dout,
    o_dout_vld    => s_dout_vld 
);


end Behavioral;
