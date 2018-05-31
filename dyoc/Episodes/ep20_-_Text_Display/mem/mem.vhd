library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

-- This module controls the memory map of the computer
-- by instantiating the different memory components
-- needed (RAM, ROM, etc), and by handling the necessary
-- address decoding.

entity mem is
   generic (
      G_ROM_SIZE  : integer;          -- Number of bits in ROM address
      G_RAM_SIZE  : integer;          -- Number of bits in RAM address
      G_CHAR_SIZE : integer;          -- Number of bits in CHAR address
      G_COL_SIZE  : integer;          -- Number of bits in COL address
      --
      G_ROM_MASK  : std_logic_vector(15 downto 0);  -- Value of upper bits in ROM address
      G_RAM_MASK  : std_logic_vector(15 downto 0);  -- Value of upper bits in RAM address
      G_CHAR_MASK : std_logic_vector(15 downto 0);  -- Value of upper bits in CHAR address
      G_COL_MASK  : std_logic_vector(15 downto 0);  -- Value of upper bits in COL address
      --
      G_FONT_FILE : string;           -- Contains the contents of the FONT memory.
      G_ROM_FILE  : string            -- Contains the contents of the ROM memory.
   );
   port (
      clk_i         : in  std_logic;

      -- Port A - connected to CPU
      a_addr_i      : in  std_logic_vector(15 downto 0);
      a_data_o      : out std_logic_vector( 7 downto 0);
      a_data_i      : in  std_logic_vector( 7 downto 0);
      a_wren_i      : in  std_logic;

      -- Port B - connected to VGA
      b_char_addr_i : in  std_logic_vector(12 downto 0);
      b_char_data_o : out std_logic_vector( 7 downto 0);
      b_col_addr_i  : in  std_logic_vector(12 downto 0);
      b_col_data_o  : out std_logic_vector( 7 downto 0)
   );
end mem;

architecture Structural of mem is

   signal rom_data  : std_logic_vector(7 downto 0);
   signal rom_cs    : std_logic;
   --
   signal ram_wren  : std_logic;
   signal ram_data  : std_logic_vector(7 downto 0);
   signal ram_cs    : std_logic;
   --
   signal char_wren : std_logic;
   signal char_data : std_logic_vector(7 downto 0);
   signal char_cs   : std_logic;
   --
   signal col_wren  : std_logic;
   signal col_data  : std_logic_vector(7 downto 0);
   signal col_cs    : std_logic;

begin

   ----------------------
   -- Address decoding
   ----------------------

   rom_cs  <= '1' when a_addr_i(15 downto G_ROM_SIZE)  = G_ROM_MASK( 15 downto G_ROM_SIZE)  else '0';
   ram_cs  <= '1' when a_addr_i(15 downto G_RAM_SIZE)  = G_RAM_MASK( 15 downto G_RAM_SIZE)  else '0';
   char_cs <= '1' when a_addr_i(15 downto G_CHAR_SIZE) = G_CHAR_MASK(15 downto G_CHAR_SIZE) else '0';
   col_cs  <= '1' when a_addr_i(15 downto G_COL_SIZE)  = G_COL_MASK( 15 downto G_COL_SIZE)  else '0';

   ram_wren  <= a_wren_i and ram_cs;
   char_wren <= a_wren_i and char_cs;
   col_wren  <= a_wren_i and col_cs;


   ----------------------
   -- Instantiate the ROM
   ----------------------

   i_rom : entity work.rom
   generic map (
      G_INIT_FILE => G_ROM_FILE,
      G_ADDR_BITS => G_ROM_SIZE
   )
   port map (
      clk_i  => clk_i,
      addr_i => a_addr_i(G_ROM_SIZE-1 downto 0),
      data_o => rom_data
   );
   

   -----------------------------------
   -- Instantiate the character memory
   -----------------------------------

   i_char : entity work.dmem
   generic map (
      G_ADDR_BITS => G_CHAR_SIZE
   )
   port map (
      clk_i    => clk_i,
      a_addr_i => a_addr_i(G_CHAR_SIZE-1 downto 0),
      a_data_i => a_data_i,
      a_wren_i => char_wren,
      b_addr_i => b_char_addr_i,
      b_data_o => b_char_data_o
   );


   -----------------------------------
   -- Instantiate the colour memory
   -----------------------------------

   i_col : entity work.dmem
   generic map (
      G_ADDR_BITS => G_COL_SIZE
   )
   port map (
      clk_i    => clk_i,
      a_addr_i => a_addr_i(G_COL_SIZE-1 downto 0),
      a_data_i => a_data_i,
      a_wren_i => col_wren,
      b_addr_i => b_col_addr_i,
      b_data_o => b_col_data_o
   );


   ----------------------
   -- Instantiate the RAM
   ----------------------

   i_ram : entity work.ram
   generic map (
      G_ADDR_BITS => G_RAM_SIZE
   )
   port map (
      clk_i  => clk_i,
      addr_i => a_addr_i(G_RAM_SIZE-1 downto 0),
      data_o => ram_data,
      data_i => a_data_i,
      wren_i => ram_wren
   );
   

   a_data_o <= rom_data  when rom_cs  = '1' else
               ram_data  when ram_cs  = '1' else
               X"00";
  
end Structural;
