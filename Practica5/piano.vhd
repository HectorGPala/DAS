--Practica5 de Diseño Automatico de Sistemas

--Piano Electronico.

--Fichero Principal.

--Desarrollada por Héctor Gutiérrez Palancarejo.

library ieee;
use ieee.std_logic_1164.all;

entity piano is
	port(
			clk : in std_logic;
			rst : in std_logic;
			ps2_clk : in std_logic;
			ps2_data : in std_logic;
			sound : out std_logic;
			debug : out std_logic_vector(13 downto 0)
		);
end piano;

architecture rtl of piano is
	
	component ps2_interface is
		port(
				clk : in std_logic;
				rst : in std_logic;
				ps2_clk : in std_logic;
				ps2_data : in std_logic;
				new_data_ack : in std_logic;
				data : out std_logic_vector(7 downto 0);
				new_data : out std_logic
			);
	end component;
	
	component switch2display7seg is
		port(
				a : in std_logic_vector(3 downto 0);
				b : out std_logic_vector(6 downto 0)
			);
	end component;

	component speaker is
		port(
				clk : in std_logic;
				rst : in std_logic;
				note_in : in  std_logic_vector (7 downto 0);
				new_data : in std_logic;
				sound : out  std_logic;
				ack : out std_logic;
				sound_active : out std_logic_vector (7 downto 0)
			);
	end component;	
	signal data_signal,data_speaker : std_logic_vector(7 downto 0);
	signal new_data_s,ack : std_logic;
begin
	u_disp1 : switch2display7seg port map(a=>data_speaker(7 downto 4),b=>debug(13 downto 7));
	u_disp2 : switch2display7seg port map(a=>data_speaker(3 downto 0),b=>debug(6 downto 0));
	
	u_ps2 : ps2_interface port map(clk=>clk,rst=>rst,ps2_clk=>ps2_clk,ps2_data=>ps2_data,new_data_ack=>ack,
		data=>data_signal,new_data=>new_data_s);

	u_speaker : speaker port map(clk=>clk,rst=>rst,note_in=>data_signal,new_data=>new_data_s,sound=>sound,ack=>ack,
	sound_active=>data_speaker);
end rtl;

