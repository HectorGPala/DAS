--Practica4 de Diseño Automatico de Sistemas

--Cronometro.

--Fichero Principal.

--Desarrollada por Héctor Gutiérrez Palancarejo.

library ieee;
use ieee.std_logic_1164.all;

entity cronometer is
    port(
			clk : in  std_logic;
			rst : in  std_logic;
			sel : in std_logic;
			puesta_zero : in  std_logic;
			start_stop : in  std_logic;
			left_segs : out  std_logic_vector (6 downto 0);
			right_segs : out  std_logic_vector (6 downto 0);
			decimal_segs : out  std_logic_vector (6 downto 0);
			point : out  std_logic_vector (2 downto 0)
		);
end cronometer;

architecture rtl of cronometer is
	component contador is
    	port(
				clk : in std_logic;
           		rst : in std_logic;
           		puesta_zero : in std_logic;
           		start_stop : in std_logic;
           		cmp : in std_logic_vector (3 downto 0);
           		display : out std_logic_vector (3 downto 0);
           		fin : out std_logic
			);
	end component;

	component clk10hz is
  		port(
				clk : in std_logic;
         		rst : in std_logic;
         		clk_out : out std_logic
			);
	end component;

	component switch2display7seg is
  		port(
				a : in  std_logic_vector(3 downto 0);
       			b : out std_logic_vector(6 downto 0)
			);
	end component;

	component synchronizer is
    	port(
				x : in  std_logic;
				rst : in std_logic;
				clk : in std_logic;
				xsync : out  std_logic
			);
	end component;

	component debouncer is
    	port(
				x : in std_logic;
				rst : in std_logic;
				clk : in std_logic;
           		xdeb : out  std_logic
			);
	end component;

	component edgedetector is
    	port(
				rst : in std_logic;
           		x : in std_logic;
           		clk : in std_logic;
           		x_falling_edge : out std_logic;
           		x_rising_edge : out std_logic
			);
	end component;

	signal clk10,rst1 : std_logic;	
	signal start_sync, start_deb, start_edge,start_state : std_logic;
	signal zero_sync, zero_deb, zero_edge, zero_state : std_logic;
	signal fin_decimas, fin_usecs, fin_dsecs, fin_umin, fin_dmin : std_logic;
	signal decimas_7segs : std_logic_vector (3 downto 0);
	signal unidades_sec_7segs, decenas_sec_7segs : std_logic_vector (3 downto 0);
	signal unidades_min_7segs, decenas_min_7segs : std_logic_vector (3 downto 0);
	signal left_display, right_display : std_logic_vector (3 downto 0); 
	signal left_display7, right_display7, third_display7 : std_logic_vector (6 downto 0);
	--trimmed signals:
	signal trim1,trim2 : std_logic; 

begin
	start_stop_signal : process(clk,rst,start_edge)
	begin
		if(rst = '0') then
			start_state <= '0';
		elsif(rising_edge(clk)) then
			if(start_edge = '1')then
				start_state <= not(start_state);
			end if;
		end if;
	end process;

	zero_signal : process(clk,rst,rst1,zero_edge)
	begin
		if(rst = '0' or rst1 = '1') then
			zero_state <= '0';
		elsif(rising_edge(clk)) then		
			if(zero_edge = '1')then
				zero_state <= '1';
			end if;
		end if;
	end process;

	counter_to_zero : process(clk10,rst,zero_state)
	begin	
		if(rst = '0') then
			rst1 <= '0';	
		elsif(rising_edge(clk10))then
			if(zero_state = '1') then
				rst1 <= '1';
			else
				rst1 <= '0';
			end if;
		end if;
	end process;
		
	point(2) <= fin_decimas;
	point(1) <= fin_usecs;
	point(0) <= fin_dsecs;
	

	u_sync_start : synchronizer port map (x=>start_stop,rst=>rst,
		clk=>clk,xsync=>start_sync);

	u_deb_start : debouncer port map (x=>start_sync,rst=>rst,
		clk=>clk,xdeb=>start_deb);

	u_edge_start : edgedetector port map (rst=>rst,x=>start_deb,
		clk=>clk,x_falling_edge=>start_edge,x_rising_edge=>trim1);

	u_sync_zero : synchronizer port map (x=>puesta_zero,rst=>rst,
		clk=>clk,xsync=>zero_sync);

	u_deb_zero : debouncer port map (x=>zero_sync,rst=>rst,
		clk=>clk,xdeb=>zero_deb);

	u_edge_zero : edgedetector port map (rst=>rst,x=>zero_deb,
		clk=>clk,x_falling_edge=>zero_edge,x_rising_edge=>trim2);

	u_clk10hz : clk10hz port map (clk=>clk, rst=>rst, clk_out=>clk10);

	u_decimas : contador port map (clk=>clk10,rst=>rst,puesta_zero=>zero_state,
		start_stop=>start_state,cmp=>"1001",display=>decimas_7segs,fin=>fin_decimas);

	u_unidades_secs : contador port map (clk=>clk10,rst=>rst,puesta_zero=>zero_state,
		start_stop=>fin_decimas,cmp=>"1001",display=>unidades_sec_7segs,fin=>fin_usecs);

	u_decenas_secs : contador port map (clk=>clk10,rst=>rst,puesta_zero=>zero_state,
		start_stop=>fin_usecs,cmp=>"0101",display=>decenas_sec_7segs,fin=>fin_dsecs);

	u_unidades_min : contador port map (clk=>clk10,rst=>rst,puesta_zero=>zero_state,
		start_stop=>fin_dsecs,cmp=>"1001",display=>unidades_min_7segs,fin=>fin_umin);

	u_decenas_min : contador port map (clk=>clk10,rst=>rst,puesta_zero=>zero_state,
		start_stop=>fin_umin,cmp=>"0101",display=>decenas_min_7segs,fin=>fin_dmin);

	u_left7segs: switch2display7seg port map (a=>left_display,b=>left_display7);
	u_right7segs: switch2display7seg port map (a=>right_display,b=>right_display7);
	u_third7segs: switch2display7seg port map (a=>decimas_7segs,b=>third_display7);

	left_display <= decenas_sec_7segs when sel = '1' else decenas_min_7segs;
	right_display <= unidades_sec_7segs when sel = '1' else unidades_min_7segs;
	left_segs <= left_display7;
	right_segs <= right_display7;
	decimal_segs <= third_display7;
end rtl;
