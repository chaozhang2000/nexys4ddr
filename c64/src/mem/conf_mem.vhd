library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

-- This stores the configuration and status information
-- Configuration information is provided in the config_o signal, and includes
-- * 0x00-0x07 X-position (2 bytes pr MOB)
-- * 0x08-0x0B Y-position (1 byte pr MOB)
-- * 0x0C-0x0F Color      (1 byte pr MOB)
-- * 0x10-0x13 Enable     (1 byte pr MOB)
-- * 0x18 Foreground text colour
-- * 0x19 Background text colour
-- * 0x1A Horizontal pixel shift
-- * 0x1B Y-line interrupt
-- * 0x1C IRQ status
-- * 0x1D IRQ mask
-- * 0x1E Keyboard

entity conf_mem is

   generic (
      G_CONF_SIZE : integer           -- Number of bits in CONF address
   );
   port (
      a_clk_i     : in  std_logic;
      a_rst_i     : in  std_logic;
      a_addr_i    : in  std_logic_vector(15 downto 0);
      a_wr_en_i   : in  std_logic;
      a_wr_data_i : in  std_logic_vector(7 downto 0);
      a_rd_en_i   : in  std_logic;
      a_rd_data_o : out std_logic_vector(7 downto 0);
      a_irq_o     : out std_logic;
      a_kb_rden_o : out std_logic;
      a_kb_val_i  : in  std_logic_vector(7 downto 0);
      --
      b_clk_i     : in  std_logic;
      b_rst_i     : in  std_logic;
      b_yline_i   : in  std_logic_vector(7 downto 0);
      b_config_o  : out std_logic_vector(2**(G_CONF_SIZE+3)-1 downto 0);
      b_irq_i     : in  std_logic
  );
end conf_mem;

architecture Structural of conf_mem is

   constant C_YLINE    : integer := 27;
   constant C_IRQ_STAT : integer := 28;
   constant C_IRQ_MASK : integer := 29;
   constant C_KBD      : integer := 30;

   signal a_config    : std_logic_vector(2**(G_CONF_SIZE+3)-1 downto 0) := (others => '0');
   signal a_irq_latch : std_logic := '0';
   signal a_yline_d   : std_logic_vector(7 downto 0);
   signal a_irq_d     : std_logic;
   signal a_rd_data   : std_logic_vector(7 downto 0);
   signal a_kb_rden   : std_logic;

   signal b_config    : std_logic_vector(2**(G_CONF_SIZE+3)-1 downto 0) := (others => '0');

begin

   --------------
   -- Port A
   --------------

   -- Synchronize from b_clk to a_clk
   proc_sync : process (a_clk_i)
   begin
      if rising_edge(a_clk_i) then
         a_yline_d <= b_yline_i;
         a_irq_d   <= b_irq_i;
      end if;
   end process proc_sync;

   proc_write : process (a_clk_i)
      variable addr_v : integer range 0 to 2**G_CONF_SIZE-1;
   begin
      if rising_edge(a_clk_i) then
         addr_v := conv_integer(a_addr_i(G_CONF_SIZE-1 downto 0));
         if a_wr_en_i = '1' then
            a_config(addr_v*8+7 downto addr_v*8) <= a_wr_data_i;
         end if;
      end if;
   end process proc_write;

   proc_read : process (a_clk_i)
      variable addr_v : integer range 0 to 2**G_CONF_SIZE-1;
   begin
      if rising_edge(a_clk_i) then
         addr_v := conv_integer(a_addr_i(G_CONF_SIZE-1 downto 0));

         a_rd_data <= (others => '0');
         a_kb_rden <= '0';

         if a_rd_en_i = '1' then
            case addr_v is
               when C_YLINE =>
                  a_rd_data <= a_yline_d;
               when C_KBD =>
                  a_rd_data <= a_kb_val_i;
                  a_kb_rden <= '1';
               when C_IRQ_STAT =>
                  a_rd_data(0) <= a_irq_latch;
                  a_irq_latch <= '0';
               when others =>
                  a_rd_data <= a_config(addr_v*8+7 downto addr_v*8);
            end case;
         end if;

         if a_irq_d = '1' and a_config(C_IRQ_MASK*8) = '1' then  -- IRQ Mask
            a_irq_latch <= '1';
         end if;

         if a_rst_i = '1' then
            a_irq_latch <= '0';
         end if;
      end if;
   end process proc_read;

   -- Drive output signals.
   a_irq_o     <= a_irq_latch;
   a_rd_data_o <= a_rd_data;
   a_kb_rden_o <= a_kb_rden;


   --------------
   -- Port B
   --------------

   conf_b_proc : process (b_clk_i)
   begin
      if rising_edge(b_clk_i) then
         b_config <= a_config;
      end if;
   end process conf_b_proc;

   -- Drive output signals.
   b_config_o <= b_config;

end Structural;
