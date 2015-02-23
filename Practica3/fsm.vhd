--Practica3 de Diseño Automatico de Sistemas

--Cerrojo Electronico.

--Maquina de estados.

--Desarrollada por Héctor Gutiérrez Palancarejo.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fsm is
    port( 
			x : in std_logic;
			clk : in  std_logic;
			rst : in  std_logic;
			eq : in  std_logic;
			lock : out  std_logic;
			ld : out std_logic;
			st : out  std_logic_vector (3 downto 0)
		);
end fsm;

architecture rtl of fsm is
	type states_fsm is (inicial,s0,s1,s2,s3);
	signal current_state,next_state : states_fsm;
begin
	state : process(clk,rst)
	begin
		if(rst = '0')then
			current_state <= inicial;
		elsif(rising_edge(clk)) then
			current_state <= next_state;
		end if;
	end process;
	
	state_gen : process(current_state,x,eq)
	begin
		next_state <= current_state;
		case current_state is
			when inicial =>
				if(x = '1') then
					next_state <= s3;
				end if;
			when s3 =>
				if(x = '1' and eq = '1') then
					next_state <= inicial;
				elsif(x = '1' and eq = '0') then
					next_state <= s2;
				end if;
			when s2 =>
				if(x = '1' and eq = '1') then
					next_state <= inicial;
				elsif(x = '1' and eq = '0') then
					next_state <= s1;
				end if;
			when s1 =>
				if(x = '1' and eq = '1') then
					next_state <= inicial;
				elsif(x = '1' and eq = '0') then
					next_state <= s0;
				end if;
			when s0 =>
				next_state <= current_state;					
		end case;		
	end process;
	
	signals_gen : process(current_state, x)
	begin
		case current_state is
			when inicial =>
				if(x = '1') then
					ld <= '1';
				else
					ld <= '0';
				end if;
				lock <= '0';
				st <= "0011";
			when s3 =>
				ld <= '0';
				st <= "0011";
				lock <= '1';
			when s2 =>
				ld <= '0';
				st <= "0010";
				lock <= '1';
			when s1 =>
				ld <= '0';
				st <= "0001";
				lock <= '1';
			when s0 =>
				ld <= '0';
				st <= "0000";
				lock <= '1';
		end case;
	end process;
end rtl;

