library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_capture_sobel is
end tb_capture_sobel;

architecture Behavioral of tb_capture_sobel is

    component ov7670_capture
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
    end component;

    component sobel_filter
        Generic (
            WIDTH  : integer;
            HEIGHT : integer
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
    end component;

    constant H_PIX  : integer := 640;
    constant V_LIN  : integer := 480;

    signal pclk  : std_logic := '0';
    signal rst   : std_logic := '1';
    signal vsync : std_logic := '0';
    signal href  : std_logic := '0';
    signal d     : std_logic_vector(7 downto 0) := (others => '0');

    signal pixel : std_logic_vector(11 downto 0);
    signal gray  : std_logic_vector(7 downto 0);
    signal addr  : std_logic_vector(16 downto 0);
    signal we    : std_logic;

    signal edge_out  : std_logic_vector(7 downto 0);
    signal sob_addr  : std_logic_vector(16 downto 0);
    signal valid_out : std_logic;

begin

    DUT_CAP : ov7670_capture
        port map (
            pclk  => pclk,
            rst   => rst,
            vsync => vsync,
            href  => href,
            d     => d,
            pixel => pixel,
            gray  => gray,
            addr  => addr,
            we    => we
        );

    DUT_SOBEL : sobel_filter
        generic map (
            WIDTH  => 320,
            HEIGHT => 240
        )
        port map (
            clk       => pclk,
            rst       => rst,
            clr       => vsync,
            ce        => we,
            din       => gray,
            edge_out  => edge_out,
            addr      => sob_addr,
            valid_out => valid_out
        );

    pclk <= not pclk after 20 ns;

    process
        variable x : integer;
        variable y : integer;
        variable px : std_logic_vector(15 downto 0);
    begin
        rst <= '1';
        wait for 200 ns;
        wait until falling_edge(pclk);
        rst <= '0';

        vsync <= '1';
        for i in 0 to 19 loop
            wait until falling_edge(pclk);
        end loop;
        vsync <= '0';
        for i in 0 to 39 loop
            wait until falling_edge(pclk);
        end loop;

        for yl in 0 to V_LIN - 1 loop
            y := yl;
            href <= '1';
            for xp in 0 to H_PIX - 1 loop
                x := xp;
                if x >= 280 and x < 360 then
                    px := x"FFFF";
                else
                    px := x"0000";
                end if;
                d <= px(15 downto 8);
                wait until falling_edge(pclk);
                d <= px(7 downto 0);
                wait until falling_edge(pclk);
            end loop;
            href <= '0';
            for i in 0 to 19 loop
                wait until falling_edge(pclk);
            end loop;
        end loop;

        vsync <= '1';
        for i in 0 to 19 loop
            wait until falling_edge(pclk);
        end loop;
        vsync <= '0';

        wait for 2 us;
        report "FRAME DONE" severity note;
        std.env.stop;
    end process;

end Behavioral;