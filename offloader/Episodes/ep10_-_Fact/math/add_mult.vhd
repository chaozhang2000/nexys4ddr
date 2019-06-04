library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity add_mult is
   generic (
      G_SIZE : integer
   );
   port ( 
      clk_i    : in  std_logic;
      rst_i    : in  std_logic;
      val_a_i  : in  std_logic_vector(G_SIZE-1 downto 0);
      val_x_i  : in  std_logic_vector(G_SIZE-1 downto 0);
      val_b_i  : in  std_logic_vector(2*G_SIZE-1 downto 0);
      start_i  : in  std_logic;
      res_o    : out std_logic_vector(2*G_SIZE-1 downto 0);
      valid_o  : out std_logic
   );
end add_mult;

architecture Behavioral of add_mult is

   constant C_ZERO : std_logic_vector(G_SIZE-1 downto 0) := (others => '0');

   signal mult_r   : std_logic_vector(G_SIZE-1 downto 0);
   signal add_r    : std_logic_vector(2*G_SIZE-1 downto 0);
   signal res_r    : std_logic_vector(2*G_SIZE-1 downto 0);
   signal valid_r  : std_logic;

   type fsm_state is (IDLE_ST, MULT_ST, DONE_ST);
   signal state_r  : fsm_state;

begin

   p_fsm : process (clk_i) is
   begin
      if rising_edge(clk_i) then
         valid_r <= '0';  -- Default value

         case state_r is
            when IDLE_ST =>
               null;

            when MULT_ST =>
               if mult_r(0) = '1' then
                  res_r <= res_r + add_r;
               end if;

               mult_r <= '0' & mult_r(G_SIZE-1 downto 1);
               add_r <= add_r(2*G_SIZE-2 downto 0) & '0';

               if mult_r = 0 then
                  state_r <= DONE_ST;
               end if;

            when DONE_ST =>
               valid_r <= '1';
               if start_i = '0' then
                  state_r <= IDLE_ST;
               end if;
         end case;

         if start_i = '1' then
            res_r   <= val_b_i;
            mult_r  <= val_a_i;
            add_r   <= C_ZERO & val_x_i;
            state_r <= MULT_ST;
         end if;

         if rst_i = '1' then
            state_r <= IDLE_ST;
         end if;
      end if;
   end process p_fsm;

   -- Connect output signals
   res_o   <= res_r when state_r = IDLE_ST else (others => '0');
   valid_o <= valid_r;

end Behavioral;
