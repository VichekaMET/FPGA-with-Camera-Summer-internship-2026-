library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity color_bbox is
    Generic (
        WIDTH   : integer := 320;
        HEIGHT  : integer := 240;
        R_MIN   : integer := 8;
        MARGIN  : integer := 3;
        MIN_PIX : integer := 100
    );
    Port (
        pclk      : in  std_logic;
        rst       : in  std_logic;
        vsync     : in  std_logic;

        pixel     : in  std_logic_vector(11 downto 0);
        we        : in  std_logic;

        box_x0    : out std_logic_vector(8 downto 0);
        box_x1    : out std_logic_vector(8 downto 0);
        box_y0    : out std_logic_vector(7 downto 0);
        box_y1    : out std_logic_vector(7 downto 0);
        box_valid : out std_logic
    );
end color_bbox;

architecture Behavioral of color_bbox is

    signal r4, g4, b4 : unsigned(3 downto 0);
    signal is_target  : std_logic;

    signal cx : integer range 0 to WIDTH - 1;
    signal cy : integer range 0 to HEIGHT - 1;

    signal min_x : integer range 0 to WIDTH - 1;
    signal max_x : integer range 0 to WIDTH - 1;
    signal min_y : integer range 0 to HEIGHT - 1;
    signal max_y : integer range 0 to HEIGHT - 1;
    signal count : integer range 0 to WIDTH * HEIGHT;

    signal vsync_r : std_logic;

    signal x0_r : std_logic_vector(8 downto 0);
    signal x1_r : std_logic_vector(8 downto 0);
    signal y0_r : std_logic_vector(7 downto 0);
    signal y1_r : std_logic_vector(7 downto 0);
    signal vld_r : std_logic;

begin

    r4 <= unsigned(pixel(11 downto 8));
    g4 <= unsigned(pixel(7 downto 4));
    b4 <= unsigned(pixel(3 downto 0));

    is_target <= '1' when (r4 >= R_MIN
                           and r4 >= g4 + MARGIN
                           and r4 >= b4 + MARGIN)
                     else '0';

    box_x0    <= x0_r;
    box_x1    <= x1_r;
    box_y0    <= y0_r;
    box_y1    <= y1_r;
    box_valid <= vld_r;

    process(pclk, rst)
    begin
        if rst = '1' then
            cx      <= 0;
            cy      <= 0;
            min_x   <= WIDTH - 1;
            max_x   <= 0;
            min_y   <= HEIGHT - 1;
            max_y   <= 0;
            count   <= 0;
            vsync_r <= '0';
            x0_r    <= (others => '0');
            x1_r    <= (others => '0');
            y0_r    <= (others => '0');
            y1_r    <= (others => '0');
            vld_r   <= '0';
        elsif rising_edge(pclk) then
            vsync_r <= vsync;

            if vsync = '1' and vsync_r = '0' then
                if count >= MIN_PIX then
                    x0_r  <= std_logic_vector(to_unsigned(min_x, 9));
                    x1_r  <= std_logic_vector(to_unsigned(max_x, 9));
                    y0_r  <= std_logic_vector(to_unsigned(min_y, 8));
                    y1_r  <= std_logic_vector(to_unsigned(max_y, 8));
                    vld_r <= '1';
                else
                    vld_r <= '0';
                end if;
                min_x <= WIDTH - 1;
                max_x <= 0;
                min_y <= HEIGHT - 1;
                max_y <= 0;
                count <= 0;
                cx    <= 0;
                cy    <= 0;
            elsif we = '1' then
                if is_target = '1' then
                    count <= count + 1;
                    if cx < min_x then
                        min_x <= cx;
                    end if;
                    if cx > max_x then
                        max_x <= cx;
                    end if;
                    if cy < min_y then
                        min_y <= cy;
                    end if;
                    if cy > max_y then
                        max_y <= cy;
                    end if;
                end if;

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
    end process;

end Behavioral;