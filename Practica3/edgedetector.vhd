--Practica3 de Diseño Automatico de Sistemas

--Cerrojo Electronico.

--Detector de Flancos.

--Desarrollada por Héctor Gutiérrez Palancarejo.

library ieee;
use ieee.std_logic_1164.all;

entity edgedetector is
    port(
			rst : in  std_logic;
			x : in  std_logic;
			clk : in  std_logic;
			x_falling_edge : out std_logic;
			x_rising_edge : out std_logic
		);
end edgedetector;

architecture rtl of edgedetector is
	signal q1,q2 : std_logic;
begin
	edge : process(clk,rst)
	begin
		if(rst = '0') then
			q1 <= '1';
			q2 <= '1';
		elsif(rising_edge(clk)) then
			q2 <= q1;
			q1 <= x;
		end if;
	end process;
	x_falling_edge <= q2 and not(q1);
	x_rising_edge <= q1 and not(q2);
end rtl;

