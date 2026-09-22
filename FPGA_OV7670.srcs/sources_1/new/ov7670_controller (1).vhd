library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ov7670_controller is
    Generic (
        CLK_FREQ_HZ : integer := 100_000_000
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
end ov7670_controller;

architecture Behavioral of ov7670_controller is

    component sccb_master
        Generic (
            CLK_FREQ_HZ  : integer;
            SCCB_FREQ_HZ : integer
        );
        Port (
            clk      : in    std_logic;
            rst      : in    std_logic;
            start    : in    std_logic;
            reg_addr : in    std_logic_vector(7 downto 0);
            reg_data : in    std_logic_vector(7 downto 0);
            busy     : out   std_logic;
            done     : out   std_logic;
            sioc     : out   std_logic;
            siod     : inout std_logic
        );
    end component;

    component ov7670_config_rom
        Port (
            clk  : in  std_logic;
            rst  : in  std_logic;
            addr : in  std_logic_vector(7 downto 0);
            dout : out std_logic_vector(15 downto 0)
        );
    end component;

    constant DELAY_1MS : integer := CLK_FREQ_HZ / 1000;

    type state_t is (S_PWRUP, S_READ, S_WAITROM, S_WRITE, S_WAITDONE, S_DELAY, S_DONE);
    signal state : state_t;

    signal rom_addr  : unsigned(7 downto 0);
    signal rom_dout  : std_logic_vector(15 downto 0);

    signal start     : std_logic;
    signal busy      : std_logic;
    signal done      : std_logic;

    signal delay_cnt : integer range 0 to 2 * DELAY_1MS;
    signal cfg_done  : std_logic;

begin

    config_done <= cfg_done;
    reset_n     <= '1';
    pwdn        <= '0';

    CONFIG_ROM : ov7670_config_rom
        port map (
            clk  => clk,
            rst  => rst,
            addr => std_logic_vector(rom_addr),
            dout => rom_dout
        );

    SCCB : sccb_master
        generic map (
            CLK_FREQ_HZ  => CLK_FREQ_HZ,
            SCCB_FREQ_HZ => 100_000
        )
        port map (
            clk      => clk,
            rst      => rst,
            start    => start,

            reg_addr => rom_dout(15 downto 8),
            reg_data => rom_dout(7 downto 0),

            busy     => busy,
            done     => done,

            sioc     => sioc,
            siod     => siod
        );

    process(clk, rst)
    begin
        if rst = '1' then
            state     <= S_PWRUP;
            rom_addr  <= (others => '0');
            start     <= '0';
            delay_cnt <= 0;
            cfg_done  <= '0';
        elsif rising_edge(clk) then
            start <= '0';

            case state is

                when S_PWRUP =>
                    if delay_cnt = DELAY_1MS then
                        delay_cnt <= 0;
                        state     <= S_READ;
                    else
                        delay_cnt <= delay_cnt + 1;
                    end if;

                when S_READ =>
                    state <= S_WAITROM;

                when S_WAITROM =>
                    if rom_dout = x"FFFF" then
                        state <= S_DONE;
                    else
                        start <= '1';
                        state <= S_WRITE;
                    end if;

                when S_WRITE =>
                    if busy = '1' then
                        state <= S_WAITDONE;
                    end if;

                when S_WAITDONE =>
                    if done = '1' then
                        if rom_dout = x"1280" then
                            state <= S_DELAY;
                        else
                            rom_addr <= rom_addr + 1;
                            state    <= S_READ;
                        end if;
                    end if;

                when S_DELAY =>
                    if delay_cnt = DELAY_1MS then
                        delay_cnt <= 0;
                        rom_addr  <= rom_addr + 1;
                        state     <= S_READ;
                    else
                        delay_cnt <= delay_cnt + 1;
                    end if;

                when S_DONE =>
                    cfg_done <= '1';

            end case;
        end if;
    end process;

end Behavioral;
