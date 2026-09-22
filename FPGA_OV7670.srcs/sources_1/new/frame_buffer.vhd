library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity frame_buffer is
    Generic (
        DATA_WIDTH : integer := 12;
        DEPTH      : integer := 76800
    );
    Port (
        wclk  : in  std_logic;
        we    : in  std_logic;
        waddr : in  std_logic_vector(16 downto 0);
        wdata : in  std_logic_vector(DATA_WIDTH - 1 downto 0);

        rclk  : in  std_logic;
        raddr : in  std_logic_vector(16 downto 0);
        rdata : out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
end frame_buffer;

architecture Behavioral of frame_buffer is

    type ram_t is array (0 to DEPTH - 1) of std_logic_vector(DATA_WIDTH - 1 downto 0);
    shared variable ram : ram_t;

begin

    process(wclk)
    begin
        if rising_edge(wclk) then
            if we = '1' then
                ram(to_integer(unsigned(waddr))) := wdata;
            end if;
        end if;
    end process;

    process(rclk)
    begin
        if rising_edge(rclk) then
            rdata <= ram(to_integer(unsigned(raddr)));
        end if;
    end process;

end Behavioral;
