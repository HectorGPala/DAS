--Practica4 de Diseño Automatico de Sistemas

--Cronometro.

--Contador.

--Desarrollada por Héctor Gutiérrez Palancarejo.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity contador is
    port ( clk : in  std_logic;
           rst : in  std_logic;
           puesta_zero : in  std_logic;
           start_stop : in  std_logic;
           cmp : in  std_logic_vector (3 downto 0);
           display : out  std_logic_vector (3 downto 0);
           fin : out  std_logic);
end contador;

architecture rtl of contador is
	signal temp : unsigned (3 downto 0);
begin
	count : process(clk,rst)
	begin
		if(rst = '0') then
			temp <= (others=>'0');
			fin <= '0';
		elsif(rising_edge(clk))then
			if(start_stop = '1') then
				if(temp = unsigned(cmp)) then
					temp <= (others=>'0');
					fin <= '1';
				else				
					temp <= temp + 1;
					fin <= '0';
				end if;
			else
				fin <= '0';
			end if;
			if(puesta_zero = '1') then
				temp <= (others=>'0');
				fin <= '0';
			end if;
		end if;		
	end process;
	display <= std_logic_vector(temp);
end rtl;

