--Practica6 de Diseño Automatico de Sistemas

--Pong El primer Videojuego.

--Fichero Principal.

--Desarrollada por Héctor Gutiérrez Palancarejo.

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity pong is
	port(
			rst: in std_logic;
			clk: in std_logic;
			ps2_clk : in std_logic;
			ps2_data : in std_logic;
			hsync: out std_logic;
			vsync: out std_logic;
			disp1 : out std_logic_vector (6 downto 0);--puntos jugador1
			disp2 : out std_logic_vector (6 downto 0);--puntos jugador2
			sound : out std_logic;
			rgb: out std_logic_vector(8 downto 0)
		);
end pong;

architecture rtl of pong is

--señales vga:
	signal pixelcntout : std_logic_vector (10 downto 0);
	signal linecntout : std_logic_vector (9 downto 0);
	signal blanking, valor : std_logic;
  
	signal hsync_int,vsync_int,valor_int : std_logic;

	signal line : std_logic_vector (7 downto 0);
	signal pixel : std_logic_vector (7 downto 0);
	
	signal color : std_logic_vector(8 downto 0);
  
--registros:
	signal raqueta1,raqueta2 : std_logic_vector (6 downto 0);--posicion raquetas
	signal pelotax : std_logic_vector (7 downto 0);--posicion pelota eje_x
	signal pelotay : std_logic_vector (6 downto 0);--posicion pelota eje_y
	
--señales de control:
	signal addr1,addr2,addx,addy : std_logic;--suma/resta en los registros de raqueta1,raqueta2 y pelota
	signal mvr1,mvr2 : std_logic;--movimiento de raquetas y pelota
	signal choque,choque_pared,choque_raqueta : std_logic;--señales de deteccion de choque
	signal fin1,fin2,fin : std_logic;--señales fin de juego
	signal flag : std_logic_vector (4 downto 0);--indica que tecla esta pulsada
	

--señales PS2:
	signal ps2_reg : std_logic_vector (7 downto 0);
	signal new_data_s,ack :std_logic;
	type states_ps2 is(wait_press,state_f0,wait_depress);
	signal current_state_ps2,next_state_ps2 : states_ps2;
	signal state_ps2 : std_logic;

--deteccion de eventos:
	signal flag_rise : std_logic;	
	signal fin1_rise,fin2_rise : std_logic;
	signal start : std_logic;	
	
--estados de la pelota
	type states_ball is (izq_arriba,izq_abajo,der_abajo,der_arriba);
	signal current_state,next_state : states_ball;
	
--marcadores:
	signal puntos1,puntos2 : std_logic_vector (3 downto 0);
  
--timer:
	signal timer : std_logic_vector (19 downto 0);
	signal fin_timer,fin_juego : std_logic;
	
--sonido choque:  
	signal choque_nota : std_logic_vector (17 downto 0);
	signal sound_s : std_logic;
	
--instancias:  
	component edgedetector is
		Port(
				rst : in STD_LOGIC;
				x : in STD_LOGIC;
				clk : in STD_LOGIC;
				x_falling_edge : out STD_LOGIC;
				x_rising_edge : out STD_LOGIC
			);
	end component;
	
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

	component gen_onda is
		port(
				clk : in std_logic;
				rst : in std_logic;
				note_in : in std_logic_vector(17 downto 0);
				clear : in std_logic;
				onda_out : out std_logic
			);
	end component;    
begin
	choque_nota <= "010111010101001101";--do en 50MHz
	u_gen_onda : gen_onda port map(clk=>clk,rst=>rst,note_in=>choque_nota,clear=>'0',onda_out=>sound_s);

	u_ps2 : ps2_interface port map(clk=>clk,rst=>rst,ps2_clk=>ps2_clk,ps2_data=>ps2_data,new_data_ack=>ack,data=>ps2_reg,new_data=>new_data_s);
  
	u_display1 : switch2display7seg port map (a=>puntos1,b=>disp1);
	u_display2 : switch2display7seg port map (a=>puntos2,b=>disp2);
	
	u_edge_start : edgedetector port map(rst=>rst,x=>flag(0),clk=>clk,x_falling_edge=>open,x_rising_edge=>flag_rise);
	u_edge_fin1 : edgedetector port map(rst=>rst,x=>fin1,clk=>clk,x_falling_edge=>open,x_rising_edge=>fin1_rise);
	u_edge_fin2 : edgedetector port map(rst=>rst,x=>fin2,clk=>clk,x_falling_edge=>open,x_rising_edge=>fin2_rise);

--process VGA:
	pixelcnt : process(rst,clk)
	begin
		if(rst='0') then
			pixelcntout <= (others=>'0');
		elsif(rising_edge(clk)) then
			if(pixelcntout = 1588) then
				pixelcntout <= (others=>'0');
			else
				pixelcntout <= pixelcntout+1;
			end if;
		end if;
	end process pixelcnt;

	linecnt : process(rst,clk)
	begin
		if (rst='0') then
			linecntout <= (others=>'0');
		elsif (rising_edge(clk)) then
			if (pixelcntout=1588) then
				if (linecntout=527) then
					linecntout <= (others=>'0');
				else
					linecntout <= linecntout+1;
				end if;
			end if;
		end if;
	end process linecnt;
  
	signals_out : process(clk,rst)
	begin
		if(rst = '0') then
			hsync <= '0';
			vsync <= '0';
			valor <= '0';
		elsif(rising_edge(clk)) then
			hsync <= hsync_int;
			vsync <= vsync_int;
			valor <= valor_int;
		end if;  
	end process;
	
	hsync_int <= '0' when (pixelcntout > 1304) and (pixelcntout <= 1493) else '1';
	vsync_int <= '0' when (linecntout > 493) and (linecntout <= 495) else '1';   
  
	blanking <= '1' when (pixelcntout > 1223) or (linecntout > 479) else '0';

	valor_int <= not blanking;

	rgb <= color when valor = '1' else "000000000";
  
	line <= linecntout(9 downto 2);
	pixel <= pixelcntout(10 downto 3);  
  
	color <= "111000000" when ((line >= raqueta1) and (line <= raqueta1 +16)) and pixel = 8 else
			"000000111" when ((line >= raqueta2) and (line<=raqueta2 +16 )) and pixel = 145 else
			"111111111" when (line = 8) or (line = 112) or (pixel = 76 and line(3) = '1') else
			"111111000" when (pelotax = pixel) and pelotay = line else
			"010100010";
  
--Movimiento raquetas:
	p_raqueta1 : process(clk,rst,addr1,mvr1,fin_timer)
  	begin
		if(rst = '0') then
			raqueta1 <= "0110000";--52
		elsif(rising_edge(clk)) then
			if(mvr1 = '1' and fin_timer = '1') then
				if(addr1 = '1' and raqueta1 < 96) then
					raqueta1 <= raqueta1 + 1;
				elsif(addr1 = '0' and raqueta1 > 8) then
					raqueta1 <= raqueta1 - 1;
				end if;
			end if;
		end if;
	end process;
	
	mvr1 <= '1' when flag(4) = '1' or flag(3) = '1' else '0';
	addr1 <= '1' when flag(3) = '1' else '0';

	p_raqueta2 : process(clk,rst,addr2,mvr2,fin_timer)
  	begin
		if(rst = '0') then
			raqueta2 <= "0110100";--52
		elsif(rising_edge(clk)) then
			if(mvr2 = '1' and fin_timer = '1') then
				if(addr2 = '1' and raqueta2 < 96) then
					raqueta2 <= raqueta2 + 1;
				elsif(addr2 = '0' and raqueta2 > 8) then
					raqueta2 <= raqueta2 - 1;
				end if;
			end if;
		end if;
	end process;
	
	mvr2 <= '1' when flag(2) = '1' or flag(1) = '1' else '0';
	addr2 <= '1' when flag(1) = '1' else '0';
	
--Movimiento pelota:  
	p_pelotax : process(clk,rst,addx,start,fin_timer)
  	begin
		if(rst = '0') then
			pelotax <= "01001100";--76
		elsif(rising_edge(clk)) then
			if(start = '1' and fin_timer = '1') then
				if(addx = '1') then
					pelotax <= pelotax + 1;
				else
					pelotax <= pelotax - 1;
				end if;
			elsif(flag_rise = '1') then
				pelotax <= "01001100";--76
			end if;
		end if;
	end process;

	p_pelotay : process(clk,rst,addy,start,fin_timer)
  	begin
		if(rst = '0') then
			pelotay <= "0111100";--60
		elsif(rising_edge(clk)) then
			if(start = '1' and fin_timer = '1') then
				if(addy = '1') then
					pelotay <= pelotay + 1;
				else
					pelotay <= pelotay - 1;
				end if;
			elsif(flag_rise = '1') then
				pelotay <= "0111100";--60
			end if;
		end if;
	end process;
	
--Control Teclado PS2:
	state_keyboard : process(clk,rst)
	begin
		if(rst = '0') then
			current_state_ps2 <= wait_press;
		elsif(rising_edge(clk)) then
			current_state_ps2 <= next_state_ps2;
		end if;
	end process;
  
	gen_state_ps2 : process(current_state_ps2,ps2_reg,new_data_s)
	begin
		next_state_ps2 <= current_state_ps2;
		case current_state_ps2 is
			when wait_press =>
				if(ps2_reg = x"f0") then
					next_state_ps2 <= state_f0;
				end if;
			when state_f0 =>
				if(new_data_s = '1') then
					next_state_ps2 <= wait_depress;
				end if;
			when wait_depress =>
				next_state_ps2 <= wait_press;
		end case;
	end process;
	
	gen_signals_ps2 : process(current_state_ps2)
	begin
		case current_state_ps2 is
			when wait_press =>
				state_ps2 <= '0';
			when state_f0 =>
				state_ps2 <= '1';
			when wait_depress =>
				state_ps2 <= '1';
		end  case;
	end process;

	p_flags : process(clk,rst,ps2_reg)
	begin
		if(rst = '0') then
			flag <= (others=> '0');
		elsif(rising_edge(clk)) then
			if(new_data_s = '1') then
			if (state_ps2 = '0') then
					if(ps2_reg = x"15") then
						flag(4) <= '1';
					elsif(ps2_reg = x"1C") then
						flag(3) <= '1';
					elsif(ps2_reg = x"4D") then
						flag(2) <= '1';
					elsif(ps2_reg = x"4B") then
						flag(1) <= '1';
					elsif(ps2_reg = x"29") then
						flag(0) <= '1';
					end if;
			else
					if(ps2_reg = x"15") then
						flag(4) <= '0';
					elsif(ps2_reg = x"1C") then
						flag(3) <= '0';
					elsif(ps2_reg = x"4D") then
						flag(2) <= '0';
					elsif(ps2_reg = x"4B") then
						flag(1) <= '0';
					elsif(ps2_reg = x"29") then
						flag(0) <= '0';
					end if;
			end if;
			ack <= '1';
			else
			ack <= '0';
			end if;
		end if;
	end process;
	
--FSM control movimiento pelota:
	state_ball : process(clk,rst)
	begin
		if(rst = '0') then
			current_state <= izq_arriba;
		elsif(rising_edge(clk)) then
			current_state <= next_state;
		end if;
	end process;  

	gen_state : process(choque_pared,choque_raqueta,current_state,fin_timer)
	begin
		next_state <= current_state;
		if(choque_raqueta = '1' and fin_timer = '1') then
			case current_state is
				when izq_arriba =>
					next_state <= der_arriba;
				when izq_abajo =>
					next_state <= der_abajo;
				when der_abajo =>
					next_state <= izq_abajo;
				when der_arriba =>
					next_state <= izq_arriba;
			end case;
		elsif(choque_pared = '1' and fin_timer = '1') then
			case current_state is
				when izq_arriba =>
					next_state <= izq_abajo;
				when izq_abajo =>
					next_state <= izq_arriba;
				when der_abajo =>
					next_state <= der_arriba;
				when der_arriba =>
					next_state <= der_abajo;
			end case;
		end if;
	end process;

	gen_signals : process(next_state)
	begin
		case next_state is
			when izq_arriba =>
				addx <= '0';
				addy <= '0';
			when izq_abajo =>
				addx <= '0';
				addy <= '1';
			when der_abajo =>
				addx <= '1';
				addy <= '1';
			when der_arriba =>
				addx <= '1';
				addy <= '0';
		end case;
	end process;
	
--Control arranque/parada/puntos de Juego:
	p_fin1 : process(clk,rst,pelotax)
	begin
		if(rst = '0') then
			fin1 <= '0';
		elsif(rising_edge(clk)) then
			if(pelotax < 8) then
				fin1 <= '1';
			else
				fin1 <= '0';			
			end if;
		end if;
	end process;

	p_fin2 : process(clk,rst,pelotax)
	begin
		if(rst = '0') then
			fin2 <= '0';
		elsif(rising_edge(clk)) then
			if(pelotax > 145) then
				fin2 <= '1';
			else
				fin2 <= '0';			
			end if;
		end if;
	end process;

	p_puntos : process(clk,rst,fin1_rise,fin2_rise)
	begin
		if(rst = '0') then
			puntos1 <= (others=>'0');
			puntos2 <= (others=>'0');
		elsif(rising_edge(clk)) then
			if(fin1_rise = '1') then
					puntos2 <= puntos2 + 1;
			elsif(fin2_rise = '1') then
					puntos1 <= puntos1 + 1;
			end if;
		end if;
	end process;

	p_start : process(clk,rst,flag_rise,fin)
	begin
		if(rst = '0') then
			start <= '0';
		elsif(rising_edge(clk)) then
			if(flag_rise = '1') then
				start <= '1';
			elsif(fin = '1') then
				start <= '0';
			end if;
		end if;
	end process;
	
	fin <= fin1_rise or fin2_rise or fin_juego;
	fin_juego <= '1' when puntos1 = "1010" or puntos2 = "1010" else '0';

--temporizacion 50px/s
	p_timer : process(clk,rst)
	begin
		if(rst = '0') then
			timer <= (others=>'0');
			fin_timer <= '0';
		elsif(rising_edge(clk)) then
			if(timer = "11110100001000111111") then
				fin_timer <= '1';
				timer <= (others=>'0');
			else
				timer <= timer + 1;
				fin_timer <= '0';
			end if;
		end if;
	end process;

--Condiciones de choque:  
	choque <= choque_pared or choque_raqueta;
	choque_pared <= '1' when pelotay = 8 or pelotay = 112 else '0';	
	choque_raqueta <= '1' when (pelotax = 8 and (pelotay >= raqueta1 and pelotay < raqueta1+16)) or (pelotax = 145 and (pelotay >= raqueta2 and pelotay < raqueta2+16)) else '0';

--Activacion sonido:
	sound <= choque and sound_s;
end rtl;