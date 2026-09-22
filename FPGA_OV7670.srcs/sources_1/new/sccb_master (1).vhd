library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sccb_master is
    Generic (
        CLK_FREQ_HZ  : integer := 100_000_000;
        SCCB_FREQ_HZ : integer := 100_000
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
end sccb_master;

architecture Behavioral of sccb_master is

    constant DIV    : integer := CLK_FREQ_HZ / (4 * SCCB_FREQ_HZ);
    constant DEV_ID : std_logic_vector(7 downto 0) := x"42";

    type state_t is (S_IDLE, S_START, S_DATA, S_STOP, S_DONE);
    signal state : state_t;

    signal div_cnt  : integer range 0 to DIV;
    signal tick     : std_logic;
    signal quarter  : unsigned(1 downto 0);

    signal byte_cnt : integer range 0 to 2;
    signal bit_cnt  : integer range 0 to 8;
    signal data_reg : std_logic_vector(23 downto 0);

    signal sioc_r   : std_logic;
    signal siod_r   : std_logic;
    signal siod_oe  : std_logic;
    signal busy_r   : std_logic;
    signal done_r   : std_logic;

begin

    sioc <= sioc_r;
    siod <= '0' when (siod_oe = '1' and siod_r = '0') else 'Z';
    busy <= busy_r;
    done <= done_r;

    process(clk, rst)
    begin
        if rst = '1' then
            state    <= S_IDLE;
            div_cnt  <= 0;
            tick     <= '0';
            quarter  <= (others => '0');
            byte_cnt <= 0;
            bit_cnt  <= 0;
            sioc_r   <= '1';
            siod_r   <= '1';
            siod_oe  <= '1';
            busy_r   <= '0';
            done_r   <= '0';
        elsif rising_edge(clk) then
            tick <= '0';
            if div_cnt = DIV - 1 then
                div_cnt <= 0;
                tick    <= '1';
            else
                div_cnt <= div_cnt + 1;
            end if;

            done_r <= '0';

            case state is

                when S_IDLE =>
                    sioc_r  <= '1';
                    siod_r  <= '1';
                    siod_oe <= '1';
                    busy_r  <= '0';
                    quarter <= (others => '0');
                    if start = '1' then
                        data_reg <= DEV_ID & reg_addr & reg_data;
                        byte_cnt <= 0;
                        bit_cnt  <= 0;
                        busy_r   <= '1';
                        state    <= S_START;
                    end if;

                when S_START =>
                    if tick = '1' then
                        quarter <= quarter + 1;
                        case quarter is
                            when "00" =>
                                sioc_r  <= '1';
                                siod_r  <= '1';
                                siod_oe <= '1';
                            when "01" =>
                                siod_r <= '0';
                            when "10" =>
                                sioc_r <= '0';
                            when others =>
                                state <= S_DATA;
                        end case;
                    end if;

                when S_DATA =>
                    if tick = '1' then
                        quarter <= quarter + 1;
                        case quarter is
                            when "00" =>
                                sioc_r <= '0';
                                if bit_cnt = 8 then
                                    siod_oe <= '0';
                                    siod_r  <= '1';
                                else
                                    siod_oe <= '1';
                                    siod_r  <= data_reg(23 - (byte_cnt * 8) - bit_cnt);
                                end if;
                            when "01" =>
                                sioc_r <= '1';
                            when "10" =>
                                sioc_r <= '1';
                            when others =>
                                sioc_r <= '0';
                                if bit_cnt = 8 then
                                    bit_cnt <= 0;
                                    if byte_cnt = 2 then
                                        state <= S_STOP;
                                    else
                                        byte_cnt <= byte_cnt + 1;
                                    end if;
                                else
                                    bit_cnt <= bit_cnt + 1;
                                end if;
                        end case;
                    end if;

                when S_STOP =>
                    if tick = '1' then
                        quarter <= quarter + 1;
                        case quarter is
                            when "00" =>
                                sioc_r  <= '0';
                                siod_oe <= '1';
                                siod_r  <= '0';
                            when "01" =>
                                sioc_r <= '1';
                            when "10" =>
                                siod_r <= '1';
                            when others =>
                                done_r <= '1';
                                state  <= S_DONE;
                        end case;
                    end if;

                when S_DONE =>
                    busy_r <= '0';
                    state  <= S_IDLE;

            end case;
        end if;
    end process;

end Behavioral;
