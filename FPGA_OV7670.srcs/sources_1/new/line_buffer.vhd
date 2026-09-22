library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity line_buffer is
    Generic (
        DEPTH : integer := 320
    );
    Port (
        clk  : in  std_logic;
        rst  : in  std_logic;
        clr  : in  std_logic;
        ce   : in  std_logic;

        din  : in  std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0)
    );
end line_buffer;

architecture Behavioral of line_buffer is

    type ram_t is array (0 to DEPTH - 1) of std_logic_vector(7 downto 0);
    signal ram    : ram_t;
    signal wptr   : integer range 0 to DEPTH - 1;
    signal dout_r : std_logic_vector(7 downto 0);

begin

    dout <= dout_r;

    process(clk, rst)
    begin
        if rst = '1' then
            wptr   <= 0;
            dout_r <= (others => '0');
        elsif rising_edge(clk) then
            if clr = '1' then
                wptr   <= 0;
                dout_r <= (others => '0');
            elsif ce = '1' then
                dout_r    <= ram(wptr);
                ram(wptr) <= din;
                if wptr = DEPTH - 1 then
                    wptr <= 0;
                else
                    wptr <= wptr + 1;
                end if;
            end if;
        end if;
    end process;

end Behavioral;
