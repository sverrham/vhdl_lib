
library ieee;
use ieee.std_logic_1164.all;

library ethernet_mac;
use ethernet_mac.ethernet_types.all;

library olo_lib;

library stream_lib;
use stream_lib.stream_pkg.all;
use stream_lib.status_pkg.all;

entity ethernet_test_top is
    Port (  clk_200_pi : in  std_logic;
            clk_200_ni : in  std_logic;
			-- Uart
			uart_tx : out  std_logic;
			uart_rx : in   std_logic;
			-- Phy interface
            phy_reset_o    : out   std_ulogic;
		    mdc_o          : out   std_ulogic;
		    mdio_io        : inout std_ulogic;
            -- mii interface
            mii_tx_clk_i   : in    std_logic;
            mii_tx_er_o    : out   std_logic;
            mii_tx_en_o    : out   std_logic;
            mii_txd_o      : out   std_ulogic_vector(7 downto 0);
            mii_rx_clk_i   : in    std_logic;
            mii_rx_er_i    : in    std_logic;
		    mii_rx_dv_i    : in    std_logic;
            mii_rxd_i      : in    std_ulogic_vector(7 downto 0);
            gmii_gtx_clk_o : out   std_logic;

            led_o          : out   std_logic_vector(3 downto 0));
            -- user_led_o     : out   std_logic);
end ethernet_test_top;

architecture rtl of ethernet_test_top is
    signal clock_125 : std_logic;
    signal dcm_locked : std_logic;
    signal reset : std_logic;
    signal link_up : std_logic;

    signal speed_detected : t_ethernet_speed;
    signal rx_empty : std_logic;

    signal rx_rd_en : std_logic;
    signal rx_data : t_ethernet_data; 

    signal tx_data : t_ethernet_data;
    signal tx_wr_en : std_logic;
    signal tx_full : std_logic;

    signal data_stream_rdy : std_logic;
    signal data_stream_vld : std_logic;
    signal data_stream : t_stream;

    signal pps : std_logic;
    signal status : t_status;
    signal status_vld : std_logic;
    signal status_rdy : std_logic;

	signal uart_rx_vld  : std_logic;
	signal uart_tx_vld  : std_logic;
	signal uart_tx_rdy  : std_logic;
	signal uart_rx_data : std_logic_vector(7 downto 0);
	signal uart_tx_data : std_logic_vector(7 downto 0);

	signal CONTROL : std_logic_vector(35 downto 0);
begin

    led_o(0) <= dcm_locked;
    led_o(1) <= reset;

    led_o(2) <= link_up;
    -- led_o(2) <= speed_detected(0);
    led_o(3) <= speed_detected(1);
    -- led_o(3) <='0'; 

    phy_reset_o <= not reset;

	reset_generator_inst : entity ethernet_mac.reset_generator
		generic map(
			RESET_TICKS => 1000
		)
		port map(
			clock_i  => clock_125,
            speed_i  => SPEED_1000MBPS, -- reset on speed change 
			reset_i  => not dcm_locked,
			reset_o  => reset
		);

	clock_generator_inst : entity work.clock_generator
		port map(
		    clk_in1_p => clk_200_pi,
		    clk_in1_n => clk_200_ni,
			clk_out1  => clock_125,
			reset     => '0',
			locked    => dcm_locked
		);

    pps_process : process (clock_125) is
        variable count : integer range 0 to 125_000_000 := 125_000_000;
    begin
        if rising_edge(clock_125) then
            pps <= '0';
            if count = 0 then
                count := 125_000_000 - 1;
                pps <= '1';
            else
                count := count - 1;
            end if;
        end if;
    end process;

    ethernet_with_fifos_inst : entity ethernet_mac.ethernet_with_fifos
		generic map(
			miim_phy_address      => "00111",
			miim_reset_wait_ticks => 1250000 -- 10 ms at 125 MHz clock, minimum: 5 ms
		)
		port map(
			clock_125_i    => clock_125,
			reset_i        => reset,
            mac_address_i  => x"04AA19BCDE10",
			rx_reset_o     => open, -- Identical to tx_reset_o
			mii_tx_clk_i   => mii_tx_clk_i,
			mii_tx_er_o    => mii_tx_er_o,
			mii_tx_en_o    => mii_tx_en_o,
			mii_txd_o      => mii_txd_o,
			mii_rx_clk_i   => mii_rx_clk_i,
			mii_rx_er_i    => mii_rx_er_i,
			mii_rx_dv_i    => mii_rx_dv_i,
			mii_rxd_i      => mii_rxd_i,
			gmii_gtx_clk_o => gmii_gtx_clk_o,
			rgmii_tx_ctl_o => open,
			rgmii_rx_ctl_i => '0',
			miim_clock_i   => clock_125,
			mdc_o          => mdc_o,
			mdio_io        => mdio_io,
			link_up_o      => link_up,
			speed_o        => speed_detected,
			rx_clock_i     => clock_125,
			rx_empty_o     => rx_empty,
			rx_rd_en_i     => rx_rd_en,
			rx_data_o      => rx_data, 
			tx_clock_i     => clock_125,
			tx_data_i      => tx_data,
			tx_wr_en_i     => tx_wr_en,
			tx_full_o      => tx_full
        );

    mac_to_stream_i : entity stream_lib.mac_to_stream
    port map (
        clk_i => clock_125,
        rst_i => reset,
        empty_i => rx_empty,
        rd_en_o => rx_rd_en,
        data_i => std_logic_vector(rx_data),
        data_o => data_stream,
        data_vld_o => data_stream_vld,
        data_rdy_i => data_stream_rdy
    );

    vld_rdy_profiler_mac_output : entity stream_lib.vld_rdy_profiler
    port map (
        clk => clock_125,
        vld => data_stream_vld,
        rdy => data_stream_rdy,
        pps => pps,
        status => status,
        status_rdy => status_rdy,
        status_vld => status_vld
    ); 
    
    data_stream_rdy <= '1';

    -- olo_base_wconv_xn2n_i : entity olo_lib.olo_base_wconv_xn2n
    -- generic map (
    --     InWidth_g => 32,
    --     OutWidth_g => 8
    -- )
    -- port map (
    --     Clk => clock_125,
    --     Rst => reset,
    --     In_Valid => data_stream_vld,
    --     In_Ready => data_stream_rdy,
    --     In_Data => data_stream.data,
    --     Out_Valid => uart_tx_vld,
    --     Out_Ready => uart_tx_rdy,
    --     Out_Data => uart_tx_data 
    -- );
   
    status_to_uart_inst : entity stream_lib.status_to_uart
    port map (
        clk => clock_125,
        rst => reset,
        pps => pps,
        status => status,
        status_vld => status_vld,
        status_rdy => status_rdy,
        uart_data => uart_tx_data,
        uart_data_vld => uart_tx_vld,
        uart_data_rdy => uart_tx_rdy
    );

    uart_olo_inst : entity olo_lib.olo_intf_uart
        generic map (
            ClkFreq_g => 125.0e6,
            BaudRate_g => 115.2e3,
            DataBits_g => 8,
            StopBits_g => "1",
            Parity_g => "none"
        )
        port map (
            Clk => clock_125,
            Rst => reset,
            Tx_Valid => uart_tx_vld,
            Tx_Ready => uart_tx_rdy,
            Tx_Data => uart_tx_data,
            Rx_Valid => uart_rx_vld,
            Rx_Data => uart_rx_data,
            Rx_ParityError => open,
            Uart_Tx => uart_tx,
            Uart_Rx => uart_rx
        );


    -- For testing uart
    -- uart_tx_vld <= uart_rx_vld;
    -- uart_tx_data <= uart_rx_data;



end rtl;

