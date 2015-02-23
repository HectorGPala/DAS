--Practica3 de Diseño Automatico de Sistemas

--Cerrojo Electronico.

--Fichero principal.

--Desarrollada por Héctor Gutiérrez Palancarejo.

library ieee;
use ieee.std_logic_1164.all;

entity lock is
    port ( intro : in  std_logic;
           clk : in  std_logic;
           rst : in  std_logic;
           switches : in  std_logic_vector (7 downto 0);
           lock_signal : out  std_logic;
           segs : out  std_logic_vector (6 downto 0));
end lock;

architecture rtl of lock is
	component synchronizer 
		port( 
				x : in  std_logic;
				rst : in std_logic;
				clk : in std_logic;
				xsync : out  std_logic
			);
	end component;
	
	component debouncer
		port(
				x : in  std_logic;
				rst : in std_logic;
				clk : in std_logic;
				xdeb : out  std_logic
			);
	end component;
	
	component edgedetector 
		port(
				rst : in  std_logic;
				x : in  std_logic;
				clk : in  std_logic;
				x_falling_edge : out  std_logic;
				x_rising_edge : out  std_logic
			);
	end component;
	
	component fsm is
		port( 
				x : in std_logic;
				clk : in  std_logic;
				rst : in  std_logic;
				eq : in  std_logic;
				lock : out  std_logic;
				ld : out std_logic;
				st : out  std_logic_vector (3 downto 0)
			);
	end component;
	
	component switch2display7seg
		port(
				a : in  std_logic_vector(3 downto 0);
				b : out std_logic_vector(6 downto 0)
			);
	end component;

	signal reg : std_logic_vector(7 downto 0);
	signal display : std_logic_vector(3 downto 0);
	signal eq,load,xsync,xdeb,x_falling,x_rising,lock_inv : std_logic;
begin
	i_sync : synchronizer port map(x=>intro, rst=>rst, clk=>clk, xsync=>xsync);
	
	i_deb : debouncer port map(x=>xsync,rst=>rst,clk=>clk,xdeb=>xdeb);
	
	i_edge : edgedetector port map(x=>xdeb,rst=>rst,clk=>clk,
				x_falling_edge =>x_falling, x_rising_edge=>x_rising);
	
	i_fsm : fsm port map(x=>x_falling,rst=>rst,clk=>clk,eq=>eq,
				lock=>lock_inv,ld=>load,st=>display);
	
	i_7segs : switch2display7seg port map(a=>display,b=>segs);

	eq <= '1' when switches = reg else '0';
	lock_signal <= lock_inv;
	
	reg_load : process(clk,rst)
	begin
		if(rst = '0') then
			reg <= (others => '0');
		elsif(rising_edge(clk)) then
			if(load = '1') then
				reg <= switches;
			end if;
		end if;
	end process;
end rtl;