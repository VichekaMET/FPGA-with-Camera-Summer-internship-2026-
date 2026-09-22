library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity motion_bbox is
    Generic (
        WIDTH    : integer := 320;
        HEIGHT   : integer := 240;
        DIFF_MIN : integer := 40;
        MIN_PIX  : integer := 200
    );
    Port (
        pclk      : in  std_logic;
        rst       : in  std_logic;
        vsync     : in  std_logic;

        gray      : in  std_logic_vector(7 downto 0);
        addr      : in  std_logic_vector(16 downto 0);
        we        : in  std_logic;

        box_x0    : out std_logic_vector(8 downto 0);
        box_x1    : out std_logic_vector(8 downto 0);
        box_y0    : out std_logic_vector(7 downto 0);
        box_y1    : out std_logic_vector(7 downto 0);
        box_valid : out std_logic
    );
end motion_bbox;

architecture Behavioral of motion_bbox is

    type ram_t is array (0 to WIDTH * HEIGHT - 1) of std_logic_vector(7 downto 0);
    signal prev_frame : ram_t;

    signal prev_px   : std_logic_vector(7 downto 0);
    signal gray_r    : std_logic_vector(7 downto 0);
    signal cmp_en    : std_logic;
    signal cx_r      : integer range 0 to WIDTH - 1;
    signal cy_r      : integer range 0 to HEIGHT - 1;

    signal diff_ab   : unsigned(7 downto 0);
    signal is_moving : std_logic;

    signal cx : integer range 0 to WIDTH - 1;
    signal cy : integer range 0 to HEIGHT - 1;

    signal min_x : integer range 0 to WIDTH - 1;
    signal max_x : integer range 0 to WIDTH - 1;
    signal min_y : integer range 0 to HEIGHT - 1;
    signal max_y : integer range 0 to HEIGHT - 1;
    signal count : integer range 0 to WIDTH * HEIGHT;

    signal frame_cnt : unsigned(1 downto 0);
    signal armed     : std_logic;
    signal vsync_r   : std_logic;

    signal x0_r  : std_logic_vector(8 downto 0);
    signal x1_r  : std_logic_vector(8 downto 0);
    signal y0_r  : std_logic_vector(7 downto 0);
    signal y1_r  : std_logic_vector(7 downto 0);
    signal vld_r : std_logic;

begin

    diff_ab <= unsigned(gray_r) - unsigned(prev_px)
               when unsigned(gray_r) >= unsigned(prev_px)
               else unsigned(prev_px) - unsigned(gray_r);

    is_moving <= '1'
                 when (cmp_en = '1' and armed = '1' and diff_ab >= DIFF_MIN)
                 else '0';

    box_x0    <= x0_r;
    box_x1    <= x1_r;
    box_y0    <= y0_r;
    box_y1    <= y1_r;
    box_valid <= vld_r;

    process(pclk)
    begin
        if rising_edge(pclk) then
            if we = '1' then
                prev_px <= prev_frame(to_integer(unsigned(addr)));
                prev_frame(to_integer(unsigned(addr))) <= gray;
            end if;
        end if;
    end process;

    process(pclk, rst)
    begin
        if rst = '1' then
            gray_r    <= (others => '0');
            cmp_en    <= '0';
            cx        <= 0;
            cy        <= 0;
            cx_r      <= 0;
            cy_r      <= 0;
            min_x     <= WIDTH - 1;
            max_x     <= 0;
            min_y     <= HEIGHT - 1;
            max_y     <= 0;
            count     <= 0;
            frame_cnt <= (others => '0');
            armed     <= '0';
            vsync_r   <= '0';
            x0_r      <= (others => '0');
            x1_r      <= (others => '0');
            y0_r      <= (others => '0');
            y1_r      <= (others => '0');
            vld_r     <= '0';

        elsif rising_edge(pclk) then

            vsync_r <= vsync;
            cmp_en  <= we;
            gray_r  <= gray;
            cx_r    <= cx;
            cy_r    <= cy;

            if vsync = '1' and vsync_r = '0' then

                if armed = '1' and count >= MIN_PIX then
                    x0_r  <= std_logic_vector(to_unsigned(min_x, 9));
                    x1_r  <= std_logic_vector(to_unsigned(max_x, 9));
                    y0_r  <= std_logic_vector(to_unsigned(min_y, 8));
                    y1_r  <= std_logic_vector(to_unsigned(max_y, 8));
                    vld_r <= '1';
                end if;

                min_x <= WIDTH - 1;
                max_x <= 0;
                min_y <= HEIGHT - 1;
                max_y <= 0;
                count <= 0;

                cx <= 0;
                cy <= 0;

                if frame_cnt = 2 then
                    armed <= '1';
                else
                    frame_cnt <= frame_cnt + 1;
                end if;

            else

                if is_moving = '1' then

                    count <= count + 1;

                    if cx_r < min_x then
                        min_x <= cx_r;
                    end if;

                    if cx_r > max_x then
                        max_x <= cx_r;
                    end if;

                    if cy_r < min_y then
                        min_y <= cy_r;
                    end if;

                    if cy_r > max_y then
                        max_y <= cy_r;
                    end if;

                end if;

                if we = '1' then
                    if cx = WIDTH - 1 then
                        cx <= 0;
                        if cy = HEIGHT - 1 then
                            cy <= 0;
                        else
                            cy <= cy + 1;
                        end if;
                    else
                        cx <= cx + 1;
                    end if;
                end if;

            end if;

        end if;
    end process;

end Behavioral;
