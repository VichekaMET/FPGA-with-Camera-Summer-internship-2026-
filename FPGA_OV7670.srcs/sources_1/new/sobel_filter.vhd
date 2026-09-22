library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sobel_filter is
    Generic (
        WIDTH  : integer := 320;
        HEIGHT : integer := 240
    );
    Port (
        clk       : in  std_logic;
        rst       : in  std_logic;
        clr       : in  std_logic;
        ce        : in  std_logic;

        din       : in  std_logic_vector(7 downto 0);

        edge_out  : out std_logic_vector(7 downto 0);
        addr      : out std_logic_vector(16 downto 0);
        valid_out : out std_logic
    );
end sobel_filter;

architecture Behavioral of sobel_filter is

    component line_buffer
        Generic (
            DEPTH : integer
        );
        Port (
            clk  : in  std_logic;
            rst  : in  std_logic;
            clr  : in  std_logic;
            ce   : in  std_logic;
            din  : in  std_logic_vector(7 downto 0);
            dout : out std_logic_vector(7 downto 0)
        );
    end component;

    constant PRIME : integer := WIDTH + 5;

    signal q1, q2   : std_logic_vector(7 downto 0);
    signal din_r1   : std_logic_vector(7 downto 0);
    signal q1_r1    : std_logic_vector(7 downto 0);

    signal b0, b1, b2 : std_logic_vector(7 downto 0);
    signal m0, m1, m2 : std_logic_vector(7 downto 0);
    signal t0, t1, t2 : std_logic_vector(7 downto 0);

    signal tl, tm, tr : signed(12 downto 0);
    signal ml, mr     : signed(12 downto 0);
    signal bl, bm, br : signed(12 downto 0);

    signal col_l, col_r, row_t, row_b : signed(12 downto 0);
    signal gx, gy : signed(13 downto 0);
    signal nx, ny : signed(13 downto 0);
    signal abs_x  : unsigned(13 downto 0);
    signal abs_y  : unsigned(13 downto 0);
    signal mag    : unsigned(14 downto 0);
    signal edge_c : std_logic_vector(7 downto 0);

    signal primed   : std_logic;
    signal in_cnt   : integer range 0 to 2 * WIDTH + 8;
    signal cx       : integer range 0 to WIDTH - 1;
    signal cy       : integer range 0 to HEIGHT - 1;
    signal row_base : unsigned(16 downto 0);
    signal in_win   : std_logic;

    signal edge_r   : std_logic_vector(7 downto 0);
    signal addr_r   : unsigned(16 downto 0);
    signal valid_r  : std_logic;

begin

    LINE_BUF_A : line_buffer
        generic map (
            DEPTH => WIDTH
        )
        port map (
            clk  => clk,
            rst  => rst,
            clr  => clr,
            ce   => ce,
            din  => din,
            dout => q1
        );

    LINE_BUF_B : line_buffer
        generic map (
            DEPTH => WIDTH
        )
        port map (
            clk  => clk,
            rst  => rst,
            clr  => clr,
            ce   => ce,
            din  => q1,
            dout => q2
        );

    tl <= signed("00000" & t2);
    tm <= signed("00000" & t1);
    tr <= signed("00000" & t0);
    ml <= signed("00000" & m2);
    mr <= signed("00000" & m0);
    bl <= signed("00000" & b2);
    bm <= signed("00000" & b1);
    br <= signed("00000" & b0);

    col_l <= tl + ml + ml + bl;
    col_r <= tr + mr + mr + br;
    row_t <= tl + tm + tm + tr;
    row_b <= bl + bm + bm + br;

    gx <= (col_r(12) & col_r) - (col_l(12) & col_l);
    gy <= (row_b(12) & row_b) - (row_t(12) & row_t);

    nx <= (not gx) + 1;
    ny <= (not gy) + 1;

    abs_x <= unsigned(gx(13 downto 0)) when gx(13) = '0' else unsigned(nx(13 downto 0));
    abs_y <= unsigned(gy(13 downto 0)) when gy(13) = '0' else unsigned(ny(13 downto 0));

    mag <= ('0' & abs_x) + ('0' & abs_y);

    edge_c <= x"FF" when mag(14 downto 8) /= "0000000" else std_logic_vector(mag(7 downto 0));

    in_win <= '1' when (primed = '1'
                        and cx >= 1 and cx <= WIDTH - 2
                        and cy >= 1 and cy <= HEIGHT - 2)
                   else '0';

    edge_out  <= edge_r;
    addr      <= std_logic_vector(addr_r);
    valid_out <= valid_r;

    process(clk, rst)
    begin
        if rst = '1' then
            din_r1   <= (others => '0');
            q1_r1    <= (others => '0');
            b0 <= (others => '0'); b1 <= (others => '0'); b2 <= (others => '0');
            m0 <= (others => '0'); m1 <= (others => '0'); m2 <= (others => '0');
            t0 <= (others => '0'); t1 <= (others => '0'); t2 <= (others => '0');
            in_cnt   <= 0;
            primed   <= '0';
            cx       <= 0;
            cy       <= 0;
            row_base <= (others => '0');
            edge_r   <= (others => '0');
            addr_r   <= (others => '0');
            valid_r  <= '0';
        elsif rising_edge(clk) then
            if clr = '1' then
                in_cnt   <= 0;
                primed   <= '0';
                cx       <= 0;
                cy       <= 0;
                row_base <= (others => '0');
                valid_r  <= '0';
            elsif ce = '1' then
                din_r1 <= din;
                q1_r1  <= q1;

                b0 <= din_r1; b1 <= b0; b2 <= b1;
                m0 <= q1_r1;  m1 <= m0; m2 <= m1;
                t0 <= q2;     t1 <= t0; t2 <= t1;

                if primed = '0' then
                    if in_cnt = PRIME then
                        primed <= '1';
                    else
                        in_cnt <= in_cnt + 1;
                    end if;
                else
                    if cx = WIDTH - 1 then
                        cx <= 0;
                        if cy = HEIGHT - 1 then
                            cy       <= 0;
                            row_base <= (others => '0');
                        else
                            cy       <= cy + 1;
                            row_base <= row_base + to_unsigned(WIDTH, 17);
                        end if;
                    else
                        cx <= cx + 1;
                    end if;
                end if;

                edge_r  <= edge_c;
                addr_r  <= row_base + to_unsigned(cx, 17);
                valid_r <= in_win;
            else
                valid_r <= '0';
            end if;
        end if;
    end process;

end Behavioral;
