    library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.NUMERIC_STD.ALL;
    
    entity ov7670_vision_top is
        Port (
            clk_100      : in    std_logic;
            rst          : in    std_logic;
    
            mode         : in    std_logic_vector(1 downto 0);
            threshold    : in    std_logic_vector(7 downto 0);
    
            ov7670_sioc  : out   std_logic;
            ov7670_siod  : inout std_logic;
            ov7670_xclk  : out   std_logic;
            ov7670_reset : out   std_logic;
            ov7670_pwdn  : out   std_logic;
    
            ov7670_pclk  : in    std_logic;
            ov7670_vsync : in    std_logic;
            ov7670_href  : in    std_logic;
            ov7670_data  : in    std_logic_vector(7 downto 0);
    
            config_done  : out   std_logic;
    
            vga_hs       : out   std_logic;
            vga_vs       : out   std_logic;
            vga_red      : out   std_logic_vector(3 downto 0);
            vga_grn      : out   std_logic_vector(3 downto 0);
            vga_blu      : out   std_logic_vector(3 downto 0)
        );
    end ov7670_vision_top;
    
    architecture Behavioral of ov7670_vision_top is
    
        component xclk_gen
            Port (
                clk_100 : in  std_logic;
                rst     : in  std_logic;
                xclk_25 : out std_logic
            );
        end component;
    
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
    
        component frame_buffer
            Generic (
                DATA_WIDTH : integer;
                DEPTH      : integer
            );
            Port (
                wclk  : in  std_logic;
                we    : in  std_logic;
                waddr : in  std_logic_vector(16 downto 0);
                wdata : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
                rclk  : in  std_logic;
                raddr : in  std_logic_vector(16 downto 0);
                rdata : out std_logic_vector(DATA_WIDTH - 1 downto 0)
            );
        end component;
    
    component vga_controller
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
        end component;
        
        component color_bbox
            Generic (
                WIDTH   : integer;
                HEIGHT  : integer;
                R_MIN   : integer;
                MARGIN  : integer;
                MIN_PIX : integer
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
        end component;
        
        component motion_bbox
            Generic (
                WIDTH    : integer;
                HEIGHT   : integer;
                DIFF_MIN : integer;
                MIN_PIX  : integer
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
        end component;
    
        signal clk_25     : std_logic;
    
        signal cap_pixel  : std_logic_vector(11 downto 0);
        signal cap_gray   : std_logic_vector(7 downto 0);
        signal cap_addr   : std_logic_vector(16 downto 0);
        signal cap_we     : std_logic;
    
        signal sob_edge   : std_logic_vector(7 downto 0);
        signal sob_addr   : std_logic_vector(16 downto 0);
        signal sob_valid  : std_logic;
    
        signal vga_raddr  : std_logic_vector(16 downto 0);
        signal rgb_rdata  : std_logic_vector(11 downto 0);
        signal edge_rdata : std_logic_vector(7 downto 0);
        
        signal bb_x0    : std_logic_vector(8 downto 0);
        signal bb_x1    : std_logic_vector(8 downto 0);
        signal bb_y0    : std_logic_vector(7 downto 0);
        signal bb_y1    : std_logic_vector(7 downto 0);
        signal bb_valid : std_logic;
    
    
        signal mb_x0    : std_logic_vector(8 downto 0);
        signal mb_x1    : std_logic_vector(8 downto 0);
        signal mb_y0    : std_logic_vector(7 downto 0);
        signal mb_y1    : std_logic_vector(7 downto 0);
        signal mb_valid : std_logic;
    begin
    
        ov7670_xclk <= clk_25;
    
        XCLK_GEN_INST : xclk_gen
            port map (
                clk_100 => clk_100,
                rst     => rst,
                xclk_25 => clk_25
            );
    
        CONTROLLER : ov7670_controller
            generic map (
                CLK_FREQ_HZ => 100_000_000
            )
            port map (
                clk         => clk_100,
                rst         => rst,
    
                config_done => config_done,
    
                sioc        => ov7670_sioc,
                siod        => ov7670_siod,
    
                reset_n     => ov7670_reset,
                pwdn        => ov7670_pwdn
            );
    
        CAPTURE : ov7670_capture
            port map (
                pclk  => ov7670_pclk,
                rst   => rst,
                vsync => ov7670_vsync,
                href  => ov7670_href,
    
                d     => ov7670_data,
    
                pixel => cap_pixel,
                gray  => cap_gray,
                addr  => cap_addr,
                we    => cap_we
            );
    
        SOBEL : sobel_filter
            generic map (
                WIDTH  => 320,
                HEIGHT => 240
            )
            port map (
                clk       => ov7670_pclk,
                rst       => rst,
                clr       => ov7670_vsync,
                ce        => cap_we,
    
                din       => cap_gray,
    
                edge_out  => sob_edge,
                addr      => sob_addr,
                valid_out => sob_valid
            );
    
        RGB_BUF : frame_buffer
            generic map (
                DATA_WIDTH => 12,
                DEPTH      => 76800
            )
            port map (
                wclk  => ov7670_pclk,
                we    => cap_we,
                waddr => cap_addr,
                wdata => cap_pixel,
    
                rclk  => clk_25,
                raddr => vga_raddr,
                rdata => rgb_rdata
            );
    
        EDGE_BUF : frame_buffer
            generic map (
                DATA_WIDTH => 8,
                DEPTH      => 76800
            )
            port map (
                wclk  => ov7670_pclk,
                we    => sob_valid,
                waddr => sob_addr,
                wdata => sob_edge,
    
                rclk  => clk_25,
                raddr => vga_raddr,
                rdata => edge_rdata
            );
    --        DETECT : color_bbox
    --        generic map (
    --            WIDTH   => 320,
    --            HEIGHT  => 240,
    --            R_MIN   => 8,
    --            MARGIN  => 3,
    --            MIN_PIX => 100
    --        )
    --        port map (
    --            pclk      => ov7670_pclk,
    --            rst       => rst,
    --            vsync     => ov7670_vsync,
    --            pixel     => cap_pixel,
    --            we        => cap_we,
    --            box_x0    => bb_x0,
    --            box_x1    => bb_x1,
    --            box_y0    => bb_y0,
    --            box_y1    => bb_y1,
    --            box_valid => bb_valid
    --        );
            
            MOTION : motion_bbox
            generic map (
                WIDTH    => 320,
                HEIGHT   => 240,
                DIFF_MIN => 40,
                MIN_PIX  => 200
            )
            port map (
                pclk      => ov7670_pclk,
                rst       => rst,
                vsync     => ov7670_vsync,
                gray      => cap_gray,
                addr      => cap_addr,
                we        => cap_we,
                box_x0    => mb_x0,
                box_x1    => mb_x1,
                box_y0    => mb_y0,
                box_y1    => mb_y1,
                box_valid => mb_valid
            );
            
    VGA : vga_controller
            port map (
                clk_25     => clk_25,
                rst        => rst,
    
                mode       => mode,
                threshold  => threshold,
    
                rgb_data   => rgb_rdata,
                edge_data  => edge_rdata,
                raddr      => vga_raddr,
    
                boxa_x0    => bb_x0,
                boxa_x1    => bb_x1,
                boxa_y0    => bb_y0,
                boxa_y1    => bb_y1,
                boxa_valid => bb_valid,
    
                boxb_x0    => mb_x0,
                boxb_x1    => mb_x1,
                boxb_y0    => mb_y0,
                boxb_y1    => mb_y1,
                boxb_valid => mb_valid,
    
                vga_hs     => vga_hs,
                vga_vs     => vga_vs,
                vga_red    => vga_red,
                vga_grn    => vga_grn,
                vga_blu    => vga_blu
            );
            
    
    end Behavioral;
