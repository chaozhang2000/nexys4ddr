library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

-- This is the top level module. The ports on this entity are mapped directly
-- to pins on the FPGA.
--
-- In this version the design can execute all instructions.
-- It additionally features a 80x60 character display.
--
-- The speed of the execution is controlled by the slide switches.
-- Simultaneously, the CPU debug is shown as an overlay over the text screen.
-- If switch 7 is turned on, the CPU operates at full speed, and the
-- CPU debug overlay is switched off.

entity comp is
   generic (
      G_SIM_MODEL : boolean := false;  -- This is set to true in the simulation test bench.
      G_FONT_FILE : string := "font8x8.txt"
   );
   port (
      clk_i     : in  std_logic;                      -- 100 MHz

      -- CPU reset (push button). Active low.
      rstn_i    : in  std_logic;

      -- Input switches
      sw_i      : in  std_logic_vector(7 downto 0);

      -- Output LED's
      led_o     : out std_logic_vector(7 downto 0);

      -- Output to VGA monitor
      vga_hs_o  : out std_logic;
      vga_vs_o  : out std_logic;
      vga_col_o : out std_logic_vector(7 downto 0)    -- RRRGGGBB
   );
end comp;

architecture Structural of comp is

   -- Clock divider for VGA
   signal clk_cnt  : std_logic_vector(1 downto 0) := (others => '0');
   signal vga_clk  : std_logic;

   -- Reset
   signal rst : std_logic := '1';   -- Make sure reset is asserted after power-up.

   -- Generate pause signal
   -- 25 bits corresponds to 25Mhz / 2^25 = 1 Hz approx.
   signal sys_wait_cnt  : std_logic_vector(24 downto 0) := (others => '0');
   signal sys_wait      : std_logic;

   -- VGA debug overlay
   signal vga_overlay_en : std_logic;
   signal vga_overlay    : std_logic_vector(175 downto 0);

   -- Data Path signals
   signal cpu_addr  : std_logic_vector(15 downto 0);
   signal mem_data  : std_logic_vector( 7 downto 0);
   signal cpu_data  : std_logic_vector( 7 downto 0);
   signal cpu_rden  : std_logic;
   signal cpu_wren  : std_logic;
   signal cpu_wait  : std_logic;
   signal mem_wait  : std_logic;

   -- Interface between VGA and Memory
   signal char_addr : std_logic_vector(12 downto 0);
   signal char_data : std_logic_vector( 7 downto 0);
   signal col_addr  : std_logic_vector(12 downto 0);
   signal col_data  : std_logic_vector( 7 downto 0);

begin
   
   --------------------------------------------------
   -- Divide input clock by 4, from 100 MHz to 25 MHz
   -- This is close enough to 25.175 MHz needed by VGA.
   --------------------------------------------------

   p_clk_cnt : process (clk_i)
   begin
      if rising_edge(clk_i) then
         clk_cnt <= clk_cnt + 1;
      end if;
   end process p_clk_cnt;

   vga_clk <= clk_cnt(1);

   
   --------------------------------------------------
   -- Generate Reset
   --------------------------------------------------

   p_rst : process (vga_clk)
   begin
      if rising_edge(vga_clk) then
         rst <= not rstn_i;
      end if;
   end process p_rst;


   --------------------------------------------------
   -- Generate wait signal
   --------------------------------------------------

   p_sys_wait_cnt : process (vga_clk)
   begin
      if rising_edge(vga_clk) then
         sys_wait_cnt <= sys_wait_cnt + sw_i;
      end if;
   end process p_sys_wait_cnt;

   -- Check for wrap around of counter.
   sys_wait <= '0' when (sys_wait_cnt + sw_i) < sys_wait_cnt else not sw_i(7);

   -- Generate wait signal for the CPU.
   cpu_wait <= mem_wait or sys_wait;

   
   --------------------------------------------------
   -- Control VGA debug overlay
   --------------------------------------------------

   vga_overlay_en <= not sw_i(7);


   --------------------------------------------------
   -- Instantiate CPU
   --------------------------------------------------
   
   i_cpu : entity work.cpu
   port map (
      clk_i     => vga_clk,
      wait_i    => cpu_wait,
      addr_o    => cpu_addr,
      rden_o    => cpu_rden,
      data_i    => mem_data,
      wren_o    => cpu_wren,
      data_o    => cpu_data,
      invalid_o => led_o,
      debug_o   => vga_overlay,
      irq_i     => '0', -- Not used at the moment
      nmi_i     => '0', -- Not used at the moment
      rst_i     => rst
   );


   --------------------------------------------------
   -- Instantiate memory
   --------------------------------------------------
   
   i_mem : entity work.mem
   generic map (
      G_ROM_SIZE  => 14, -- 16 Kbytes
      G_RAM_SIZE  => 15, -- 32 Kbytes
      G_CHAR_SIZE => 13, -- 8 Kbytes
      G_COL_SIZE  => 13, -- 8 Kbytes
      --
      G_ROM_MASK  => X"C000",
      G_RAM_MASK  => X"0000",
      G_CHAR_MASK => X"8000",
      G_COL_MASK  => X"A000",
      --
      G_ROM_FILE  => "../rom.txt"
   )
   port map (
      clk_i    => vga_clk,
      --
      a_addr_i => cpu_addr,  -- Only select the relevant address bits
      a_data_o => mem_data,
      a_rden_i => cpu_rden,
      a_wren_i => cpu_wren,
      a_data_i => cpu_data,
      a_wait_o => mem_wait,
      --
      b_char_addr_i => char_addr,
      b_char_data_o => char_data,
      b_col_addr_i  => col_addr,
      b_col_data_o  => col_data
   );


   --------------------------------------------------
   -- Instantiate VGA module
   --------------------------------------------------

   i_vga : entity work.vga
   generic map (
      G_FONT_FILE => G_FONT_FILE
   )
   port map (
      clk_i     => vga_clk,
      overlay_i => vga_overlay_en,
      digits_i  => vga_overlay,
      vga_hs_o  => vga_hs_o,
      vga_vs_o  => vga_vs_o,
      vga_col_o => vga_col_o,

      char_addr_o => char_addr,
      char_data_i => char_data,
      col_addr_o  => col_addr,
      col_data_i  => col_data
   );

end architecture Structural;

