--Practica2 de Diseño Automatico de Sistemas

--Manejo display 7-SEGMENTOS.

--Desarrollada por Héctor Gutiérrez Palancarejo

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity switch2display7seg is
	port(
			a : in  std_logic_vector(3 downto 0);
			b : out std_logic_vector(6 downto 0)
		);
end switch2display7seg;

architecture rtl of switch2display7seg is
  constant zero     : std_logic_vector(6 downto 0) := "0000001";  -- 0
  constant one      : std_logic_vector(6 downto 0) := "1001111";
  constant two      : std_logic_vector(6 downto 0) := "0010010";
  constant three    : std_logic_vector(6 downto 0) := "0000110";
  constant four     : std_logic_vector(6 downto 0) := "1001100";
  constant five     : std_logic_vector(6 downto 0) := "0100100";
  constant six      : std_logic_vector(6 downto 0) := "0100000";
  constant seven    : std_logic_vector(6 downto 0) := "0001111";
  constant eight    : std_logic_vector(6 downto 0) := "0000000";
  constant nine     : std_logic_vector(6 downto 0) := "0001100";
  constant ten      : std_logic_vector(6 downto 0) := "0001000";
  constant eleven   : std_logic_vector(6 downto 0) := "1100000";
  constant twelve   : std_logic_vector(6 downto 0) := "0110001";
  constant thirteen : std_logic_vector(6 downto 0) := "1000010";
  constant fourteen  : std_logic_vector(6 downto 0) := "0110000";
  constant fiveteen : std_logic_vector(6 downto 0) := "0111000";  -- 15

begin
	b <= not(zero) when a = "0000" else
		not(one) when a = "0001" else
		not(two) when a = "0010" else
		not(three) when a = "0011" else
		not(four) when a = "0100" else
		not(five) when a = "0101" else
		not(six) when a = "0110" else
		not(seven) when a = "0111" else
		not(eight) when a = "1000" else
		not(nine) when a = "1001" else
		not(ten) when a = "1010" else
		not(eleven) when a = "1011" else
		not(twelve) when a = "1100" else
		not(thirteen) when a = "1101" else
		not(fourteen) when a = "1110" else
		not(fiveteen);
end rtl;

