--Practica6 de Diseño Automatico de Sistemas

--Pong El primer Videojuego.

--Sonido de choque.

--Desarrollada por Héctor Gutiérrez Palancarejo.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gen_onda is
	port(
			clk : in std_logic;
			rst : in std_logic;
			note_in : in std_logic_vector(17 downto 0);
			clear : in std_logic;
			onda_out : out std_logic
		);
end gen_onda;

architecture rtl of gen_onda is
	signal count : unsigned(17 downto 0);
	signal temp  : std_logic;
begin
	gen_signal : process(clk, rst)
	begin
		if(rst = '0')then
			count <= (others => '0');
			temp  <= '0';
		elsif(rising_edge(clk)) then
			if(clear = '1') then
				count <= (others=>'0');
			elsif(count = unsigned(note_in)) then
				temp  <= not(temp);
				count <= (others => '0');
			else
				count <= count + 1;
			end if;
		end if;
	end process;
	onda_out <= temp;
end rtl;