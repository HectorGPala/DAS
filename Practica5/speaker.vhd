--Practica5 de Diseño Automatico de Sistemas

--Piano Electronico.

--Altavoz.

--Desarrollada por Héctor Gutiérrez Palancarejo.

library ieee;
use ieee.std_logic_1164.all;

entity speaker is
    port(
			clk : in std_logic;
			rst : in std_logic;
			note_in : in std_logic_vector (7 downto 0);
			new_data : in std_logic;
			sound : out std_logic;
			ack : out std_logic;
			sound_active : out std_logic_vector (7 downto 0)
		);			  
end speaker;

architecture rtl of speaker is
	
	component gen_onda is
  		port(
				clk : in std_logic;
         		rst : in  std_logic;
				note_in : in std_logic_vector(17 downto 0);
				clear : in std_logic;
         		onda_out : out std_logic
			);
	end component;

	type states_piano is (wait_press,state_f0,wait_depress);
	signal current_state,next_state : states_piano;
	signal n : std_logic_vector(18 downto 0);
	signal silence : std_logic;
	signal note_out :std_logic;
	signal clear_s,load_note,clear_note : std_logic;
	signal reg_note : std_logic_vector (7 downto 0);
begin
	--rom memory
	n <= "0101110101010011010" when reg_note = x"1c" else--a
	"0101100000010010110" when reg_note = x"1d" else--w
	"0101001000110011110" when reg_note = x"1b" else--s
	"0100111001111001111" when reg_note = x"24" else--e
	"0100101000010010010" when reg_note = x"23" else--d
	"0100010111101001111" when reg_note = x"2b" else--f
	"0100000111111011110" when reg_note = x"2c" else--t
	"0011111001000111110" when reg_note = x"34" else--g
	"0011101011001001010" when reg_note = x"35" else--y
	"0011011101111100011" when reg_note = x"33" else--h
	"0011010001011110001" when reg_note = x"3c" else--u
	"0011000101101110010" when reg_note = x"3b" else--j
	"0010111010100111010" when reg_note = x"42" else--k
	"1000000000000000000";
	
	p_state : process(clk,rst)
	begin
		if (rst = '0') then
			current_state <= wait_press;
		elsif(rising_edge(clk)) then
			current_state <= next_state;
		end if;
	end process;
	
	gen_state : process(current_state,reg_note,new_data)
	begin
		next_state <= current_state;
		case current_state is
			when wait_press =>
				if(reg_note = x"f0") then
					next_state <= state_f0;
				end if;
			when state_f0 =>
				if(new_data = '1') then
					next_state <= wait_depress;
				end if;
			when wait_depress =>
				next_state <= wait_press;
		end case;
	end process;
	
	gen_signals : process(current_state)
	begin
		case current_state is
			when wait_press =>
				load_note <= '1';
				clear_note <= '0';
			when state_f0 =>
				load_note <= '0';
				clear_note <= '1';
			when wait_depress =>
				load_note <= '0';
				clear_note <= '0';
		end  case;
	end process;
	
	reg_note_p : process(clk,rst,clear_note)
	begin
		if(rst = '0') then
			reg_note <= x"00";
			ack <= '0';
		elsif(rising_edge(clk)) then
			if(new_data = '1') then
				if(clear_note = '1') then
					reg_note <= x"00";
				elsif(load_note = '1') then
					reg_note <= note_in;
				end if;
				ack <= '1';
			else
				ack <= '0';
			end if;
		end if;
	end process;
	
	silence <= n(18);
	
	sound_active <= reg_note;
	
	clear_s <= '1' when reg_note /= note_in else '0';
	
	sound <= note_out and not(silence);

	u_gen_onda : gen_onda port map(clk =>clk,rst=>rst,note_in=>n(17 downto 0),clear=>clear_s,onda_out=>note_out);
end rtl;

