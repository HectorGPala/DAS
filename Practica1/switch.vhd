--Practica1 de Diseño Automatico de Sistemas

--Manejo barra de leds con switches.

--Desarrollada por Héctor Gutiérrez Palancarejo

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity switch is
	port(	
			a : in std_logic_vector(9 downto 0);
			b : out std_logic_vector(9 downto 0)
		);
end switch;

architecture rtl of switch is
begin
	b <= not(a);
end rtl;

