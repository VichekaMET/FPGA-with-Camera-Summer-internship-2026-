library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_controller is
end tb_controller;

architecture Behavioral of tb_controller is

    component ov7670_controller
        Generic (
            CLK_FREQ_HZ : integer
        );
        Port (
            clk         : in    std_logic;
            rst         : in    std_logic;
            config_done : out   std_logic;
            sioc        : out   std_logic;
            siod        : inout std_logic;
            reset_n     : out   std_logic;
            pwdn        : out   std_logic
        );
    end component;

    signal clk         : std_logic := '0';
    signal rst         : std_logic := '1';
    signal config_done : std_logic;
    signal sioc        : std_logic;
    signal siod        : std_logic;
    signal reset_n     : std_logic;
    signal pwdn        : std_logic;

begin

    siod <= 'H';

    DUT : ov7670_controller
        generic map (
            CLK_FREQ_HZ => 1_000_000
        )
        port map (
            clk         => clk,
            rst         => rst,
            config_done => config_done,
            sioc        => sioc,
            siod        => siod,
            reset_n     => reset_n,
            pwdn        => pwdn
        );

    clk <= not clk after 500 ns;

    process
    begin
        rst <= '1';
        wait for 5 us;
        rst <= '0';
        wait until config_done = '1';
        report "CONFIG DONE" severity note;
        wait for 100 us;
        std.env.stop;
    end process;

end Behavioral;