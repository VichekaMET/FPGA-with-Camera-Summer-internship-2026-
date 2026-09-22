library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_controller is
    Port (
        clk_25     : in  std_logic;
        rst        : in  std_logic;

        mode       : in  std_logic_vector(1 downto 0);
        threshold  : in  std_logic_vector(7 downto 0);

        rgb_data   : in  std_logic_vector(11 downto 0);
        edge_data  : in  std_logic_vector(7 downto 0);
        raddr      : out std_logic_vector(16 downto 0);

        boxa_x0    : in  std_logic_vector(8 downto 0);
        boxa_x1    : in  std_logic_vector(8 downto 0);
        boxa_y0    : in  std_logic_vector(7 downto 0);
        boxa_y1    : in  std_logic_vector(7 downto 0);
        boxa_valid : in  std_logic;

        boxb_x0    : in  std_logic_vector(8 downto 0);
        boxb_x1    : in  std_logic_vector(8 downto 0);
        boxb_y0    : in  std_logic_vector(7 downto 0);
        boxb_y1    : in  std_logic_vector(7 downto 0);
        boxb_valid : in  std_logic;

        vga_hs     : out std_logic;
        vga_vs     : out std_logic;
        vga_red    : out std_logic_vector(3 downto 0);
        vga_grn    : out std_logic_vector(3 downto 0);
        vga_blu    : out std_logic_vector(3 downto 0)
    );
end vga_controller;

architecture Behavioral of vga_controller is

    signal h_cnt    : unsigned(9 downto 0);
    signal v_cnt    : unsigned(9 downto 0);
    signal active   : std_logic;
    signal active_r : std_logic;
    signal hs_r     : std_logic;
    signal vs_r     : std_logic;

    signal r4       : unsigned(3 downto 0);
    signal g4       : unsigned(3 downto 0);
    signal b4       : unsigned(3 downto 0);
    signal sum6     : unsigned(5 downto 0);
    signal gray4    : std_logic_vector(3 downto 0);
    signal pix_out  : std_logic_vector(11 downto 0);

    signal hx       : unsigned(8 downto 0);
    signal vy       : unsigned(7 downto 0);

    signal ax0, ax1 : unsigned(8 downto 0);
    signal ay0, ay1 : unsigned(7 downto 0);
    signal avld_s1  : std_logic;
    signal avld_s2  : std_logic;
    signal on_a_v   : std_logic;
    signal on_a_h   : std_logic;
    signal on_boxa  : std_logic;

    signal bx0, bx1 : unsigned(8 downto 0);
    signal by0, by1 : unsigned(7 downto 0);
    signal bvld_s1  : std_logic;
    signal bvld_s2  : std_logic;
    signal on_b_v   : std_logic;
    signal on_b_h   : std_logic;
    signal on_boxb  : std_logic;

begin

    active <= '1' when (h_cnt < 640 and v_cnt < 480) else '0';

    raddr <= std_logic_vector(v_cnt(8 downto 1) * to_unsigned(320, 9) + h_cnt(9 downto 1));

    r4 <= unsigned(rgb_data(11 downto 8));
    g4 <= unsigned(rgb_data(7 downto 4));
    b4 <= unsigned(rgb_data(3 downto 0));

    sum6  <= ("00" & r4) + ('0' & g4 & '0') + ("00" & b4);
    gray4 <= std_logic_vector(sum6(5 downto 2));

    pix_out <= rgb_data                                              when mode = "00" else
               gray4 & gray4 & gray4                                 when mode = "01" else
               edge_data(7 downto 4) & edge_data(7 downto 4) & edge_data(7 downto 4) when mode = "10" else
               x"FFF" when unsigned(edge_data) > unsigned(threshold) else
               x"000";

    hx <= h_cnt(9 downto 1);
    vy <= v_cnt(8 downto 1);

    ax0 <= unsigned(boxa_x0);
    ax1 <= unsigned(boxa_x1);
    ay0 <= unsigned(boxa_y0);
    ay1 <= unsigned(boxa_y1);

    bx0 <= unsigned(boxb_x0);
    bx1 <= unsigned(boxb_x1);
    by0 <= unsigned(boxb_y0);
    by1 <= unsigned(boxb_y1);

    on_a_v <= '1' when ((hx = ax0 or hx = ax0 + 1 or hx = ax1 or hx = ax1 - 1)
                        and vy >= ay0 and vy <= ay1)
                  else '0';

    on_a_h <= '1' when ((vy = ay0 or vy = ay0 + 1 or vy = ay1 or vy = ay1 - 1)
                        and hx >= ax0 and hx <= ax1)
                  else '0';

    on_boxa <= avld_s2 and (on_a_v or on_a_h);

    on_b_v <= '1' when ((hx = bx0 or hx = bx0 + 1 or hx = bx1 or hx = bx1 - 1)
                        and vy >= by0 and vy <= by1)
                  else '0';

    on_b_h <= '1' when ((vy = by0 or vy = by0 + 1 or vy = by1 or vy = by1 - 1)
                        and hx >= bx0 and hx <= bx1)
                  else '0';

    on_boxb <= bvld_s2 and (on_b_v or on_b_h);

    vga_hs  <= hs_r;
    vga_vs  <= vs_r;
    vga_red <= x"0" when (active_r = '1' and (on_boxb = '1' or on_boxa = '1')) else
               pix_out(11 downto 8) when active_r = '1' else (others => '0');
    vga_grn <= x"0" when (active_r = '1' and on_boxb = '1') else
               x"F" when (active_r = '1' and on_boxa = '1') else
               pix_out(7 downto 4)  when active_r = '1' else (others => '0');
    vga_blu <= x"F" when (active_r = '1' and on_boxb = '1') else
               x"0" when (active_r = '1' and on_boxa = '1') else
               pix_out(3 downto 0)  when active_r = '1' else (others => '0');

    process(clk_25, rst)
    begin
        if rst = '1' then
            h_cnt    <= (others => '0');
            v_cnt    <= (others => '0');
            active_r <= '0';
            hs_r     <= '1';
            vs_r     <= '1';
            avld_s1  <= '0';
            avld_s2  <= '0';
            bvld_s1  <= '0';
            bvld_s2  <= '0';
        elsif rising_edge(clk_25) then
            avld_s1 <= boxa_valid;
            avld_s2 <= avld_s1;
            bvld_s1 <= boxb_valid;
            bvld_s2 <= bvld_s1;

            if h_cnt = 799 then
                h_cnt <= (others => '0');
                if v_cnt = 524 then
                    v_cnt <= (others => '0');
                else
                    v_cnt <= v_cnt + 1;
                end if;
            else
                h_cnt <= h_cnt + 1;
            end if;

            active_r <= active;

            if h_cnt >= 656 and h_cnt <= 751 then
                hs_r <= '0';
            else
                hs_r <= '1';
            end if;

            if v_cnt >= 490 and v_cnt <= 491 then
                vs_r <= '0';
            else
                vs_r <= '1';
            end if;
        end if;
    end process;

end Behavioral;