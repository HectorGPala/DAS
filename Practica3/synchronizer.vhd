--Practica3 de Dise�o Automatico de Sistemas

--Cerrojo Electronico.

--Sincronizador de se�al de entrada con clk.

--Desarrollada por H�ctor Guti�rrez Palancarejo.

library ieee;
use ieee.std_logic_1164.all;

entity synchronizer is
    port( 
			x : in  std_logic;
			rst : in std_logic;
			clk : in std_logic;
			xsync : out  std_logic
		);
end synchronizer;

architecture rtl of synchronizer is
	signal xp : std_logic;
begin
	clock : process(clk,rst)
	begin
		if(rst = '0') then
			xp <= '1';
			xsync <= '1';
		elsif(rising_edge(clk)) then
			xp <= x;
			xsync <= xp;			
		end if;		
	end process;
end rtl;

