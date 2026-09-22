library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity xclk_gen is
    Port (
        clk_100 : in  std_logic;
        rst     : in  std_logic;
        xclk_25 : out std_logic
    );
end xclk_gen;

architecture Behavioral of xclk_gen is

    signal counter : unsigned(1 downto 0);
    signal clk_div : std_logic;

begin

    xclk_25 <= clk_div;

    process(clk_100, rst)
    begin
        if rst = '1' then
            counter <= (others => '0');
            clk_div <= '0';
        elsif rising_edge(clk_100) then
            if counter = 1 then
                counter <= (others => '0');
                clk_div <= not clk_div;
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;

end Behavioral;
