--Practica4 de Diseño Automatico de Sistemas

--Cronometro.

--Generador señal 10Hz.

--Desarrollada por Héctor Gutiérrez Palancarejo.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clk10hz is
	port(
			clk : in  std_logic;
			rst : in  std_logic;
			clk_out : out std_logic
		);
end clk10hz;

architecture rtl of clk10hz is
	signal count : unsigned(23 downto 0);
	signal temp : std_logic;
begin
  gen_10hz : process(clk, rst)
  begin
	if(rst = '0')then
		count <= (others => '0');
		temp  <= '0';
    elsif(rising_edge(clk)) then
		if (count = "10011000100101100111111") then
			temp  <= not(temp);
			count <= (others => '0');
		else
			count <= count + 1;
		end if;
    end if;
  end process;
  clk_out <= temp;
end rtl;

