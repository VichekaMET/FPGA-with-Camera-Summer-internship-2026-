library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ov7670_config_rom is
    Port (
        clk  : in  std_logic;
        rst  : in  std_logic;
        addr : in  std_logic_vector(7 downto 0);
        dout : out std_logic_vector(15 downto 0)
    );
end ov7670_config_rom;

architecture Behavioral of ov7670_config_rom is
begin

    process(clk, rst)
    begin
        if rst = '1' then
            dout <= x"FFFF";
        elsif rising_edge(clk) then
            case addr is
                when x"00" => dout <= x"1280";
                when x"01" => dout <= x"1204";
                when x"02" => dout <= x"1100";
                when x"03" => dout <= x"0C00";
                when x"04" => dout <= x"3E00";
                when x"05" => dout <= x"703A";
                when x"06" => dout <= x"7135";
                when x"07" => dout <= x"7211";
                when x"08" => dout <= x"73F0";
                when x"09" => dout <= x"A202";
                when x"0A" => dout <= x"1500";
                when x"0B" => dout <= x"40D0";
                when x"0C" => dout <= x"3A04";
                when x"0D" => dout <= x"1438";
                when x"0E" => dout <= x"4FB3";
                when x"0F" => dout <= x"50B3";
                when x"10" => dout <= x"5100";
                when x"11" => dout <= x"523D";
                when x"12" => dout <= x"53A7";
                when x"13" => dout <= x"54E4";
                when x"14" => dout <= x"589E";
                when x"15" => dout <= x"3DC0";
                when x"16" => dout <= x"1713";
                when x"17" => dout <= x"1801";
                when x"18" => dout <= x"32B6";
                when x"19" => dout <= x"1902";
                when x"1A" => dout <= x"1A7A";
                when x"1B" => dout <= x"030A";
                when x"1C" => dout <= x"0F41";
                when x"1D" => dout <= x"1E00";
                when x"1E" => dout <= x"3C78";
                when x"1F" => dout <= x"6900";
                when x"20" => dout <= x"7400";
                when x"21" => dout <= x"B084";
                when x"22" => dout <= x"B10C";
                when x"23" => dout <= x"B20E";
                when x"24" => dout <= x"B382";
                when others => dout <= x"FFFF";
            end case;
        end if;
    end process;

end Behavioral;
