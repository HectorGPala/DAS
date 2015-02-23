--Practica3 de Diseño Automatico de Sistemas

--Cerrojo Electronico.

--Eliminador de Rebotes.

--Desarrollada por Héctor Gutiérrez Palancarejo.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity debouncer is
    port( 
			x : in  std_logic;
			rst : in std_logic;
			clk : in std_logic;
			xdeb : out  std_logic
		);
end debouncer;

architecture rtl of debouncer is
	type states_debouncer is (espera_presion,espera_fin_rebotep,espera_depresion,espera_fin_reboted);
	signal current_state,next_state : states_debouncer;
	signal start_timer,timer_end : std_logic;
	constant timeout: std_logic_vector(14 downto 0) := "111010100110000";
	signal count : std_logic_vector(14 downto 0);
	
begin
	timer: process(clk,rst)	
	begin
	   if(rst='0') then
			count <= (others=>'0');
		elsif(rising_edge(clk)) then
			if(start_timer='1') then
				count <= (others=>'0');
			elsif(count /= timeout) then
				count <= std_logic_vector(unsigned(count) + 1);
			end if;
		end if;
	end process;
	
	timer_end <= '1' when (count = timeout) else '0';
		
	state : process(clk,rst)
	begin
		if(rst = '0')then
			current_state <= espera_presion;
		elsif(rising_edge(clk)) then
			current_state <= next_state;
		end if;
	end process;
	
	state_gen : process(current_state, x, timer_end)
	begin
		next_state <= current_state;
		case current_state is
			when espera_presion =>
				if (x = '0') then
					next_state <= espera_fin_rebotep;
				else
					next_state <= current_state;
				end if;
			when espera_fin_rebotep =>
				if(timer_end = '1') then
					next_state <= espera_depresion;
				else
					next_state <= current_state;
				end if;
			when espera_depresion =>
				if(x = '1') then
					next_state <= espera_fin_reboted;
				else
					next_state <= current_state;
				end if;
			when espera_fin_reboted =>
				if(timer_end = '1') then
					next_state <= espera_presion;
				else
					next_state <= current_state;
				end if;
		end case;
	end process;
	
	signals_gen : process(current_state, x, timer_end)
	begin
		xdeb <= '1';
		start_timer <= '0';
		case current_state is
			when espera_presion =>
				if(x = '0') then
					start_timer <= '1';
				end if;
			when espera_fin_rebotep =>
				xdeb <= '0';
			when espera_depresion =>
				if(x = '1') then
					start_timer <= '1';
				end if;
				xdeb <= '0';
			when espera_fin_reboted =>
				xdeb <= '1';
				start_timer <= '0';
		end case;
	end process;
end rtl;