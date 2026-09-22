library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ov7670_capture is
    Port (
        pclk  : in  std_logic;
        rst   : in  std_logic;
        vsync : in  std_logic;
        href  : in  std_logic;

        d     : in  std_logic_vector(7 downto 0);

        pixel : out std_logic_vector(11 downto 0);
        gray  : out std_logic_vector(7 downto 0);
        addr  : out std_logic_vector(16 downto 0);
        we    : out std_logic
    );
end ov7670_capture;

architecture Behavioral of ov7670_capture is

    signal addr_cnt : unsigned(16 downto 0);
    signal x_cnt    : unsigned(9 downto 0);
    signal y_cnt    : unsigned(9 downto 0);
    signal href_r   : std_logic;
    signal byte_tgl : std_logic;
    signal hi_byte  : std_logic_vector(7 downto 0);
    signal pixel_r  : std_logic_vector(11 downto 0);
    signal gray_r   : std_logic_vector(7 downto 0);
    signal we_r     : std_logic;

    signal r8       : unsigned(7 downto 0);
    signal g8       : unsigned(7 downto 0);
    signal b8       : unsigned(7 downto 0);
    signal acc      : unsigned(15 downto 0);

begin

    addr  <= std_logic_vector(addr_cnt);
    pixel <= pixel_r;
    gray  <= gray_r;
    we    <= we_r;

    r8  <= unsigned(hi_byte(7 downto 3) & hi_byte(7 downto 5));
    g8  <= unsigned(hi_byte(2 downto 0) & d(7 downto 5) & hi_byte(2 downto 1));
    b8  <= unsigned(d(4 downto 0) & d(4 downto 2));
    acc <= r8 * to_unsigned(77, 8) + g8 * to_unsigned(150, 8) + b8 * to_unsigned(29, 8);

    process(pclk, rst)
    begin
        if rst = '1' then
            addr_cnt <= (others => '0');
            x_cnt    <= (others => '0');
            y_cnt    <= (others => '0');
            href_r   <= '0';
            byte_tgl <= '0';
            hi_byte  <= (others => '0');
            pixel_r  <= (others => '0');
            gray_r   <= (others => '0');
            we_r     <= '0';
        elsif rising_edge(pclk) then
            href_r <= href;

            if vsync = '1' then
                addr_cnt <= (others => '0');
                x_cnt    <= (others => '0');
                y_cnt    <= (others => '0');
                byte_tgl <= '0';
                we_r     <= '0';
            else
                if we_r = '1' then
                    addr_cnt <= addr_cnt + 1;
                end if;

                if href = '1' then
                    if byte_tgl = '0' then
                        hi_byte  <= d;
                        byte_tgl <= '1';
                        we_r     <= '0';
                    else
                        byte_tgl <= '0';
                        x_cnt    <= x_cnt + 1;
                        if x_cnt(0) = '0' and y_cnt(0) = '0' then
                            pixel_r <= hi_byte(7 downto 4) & hi_byte(2 downto 0) & d(7) & d(4 downto 1);
                            gray_r  <= std_logic_vector(acc(15 downto 8));
                            we_r    <= '1';
                        else
                            we_r <= '0';
                        end if;
                    end if;
                else
                    byte_tgl <= '0';
                    we_r     <= '0';
                    x_cnt    <= (others => '0');
                    if href_r = '1' then
                        y_cnt <= y_cnt + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

end Behavioral;
