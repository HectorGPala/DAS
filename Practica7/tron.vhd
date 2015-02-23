--Practica7 de Diseño Automatico de Sistemas

--Juego TRON.

--Fichero Principal.

--Desarrollada por Héctor Gutiérrez Palancarejo.

library unisim;
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use unisim.vcomponents.all;--memorias ram

entity tron is
	port(
			rst: in std_logic;
			clk: in std_logic;
			ps2_clk : in std_logic;
			ps2_data : in std_logic;
			hsync: out std_logic;
			vsync: out std_logic;
			rgb: out std_logic_vector(8 downto 0)
		);
end tron;

architecture rtl of tron is
--señales vga:
	signal pixelcntout : std_logic_vector (10 downto 0);
	signal linecntout : std_logic_vector (9 downto 0);
	signal blanking, valor : std_logic;
  
	signal hsync_int,vsync_int,valor_int : std_logic;

	signal color : std_logic_vector(8 downto 0);
	signal line : std_logic_vector (6 downto 0);
	signal pixel : std_logic_vector (7 downto 0);
  
--registros:
	signal moto1y,moto2y : std_logic_vector (6 downto 0);
	signal moto1x,moto2x : std_logic_vector (7 downto 0);
	
--señales de control:
	signal add1x,add1y,add2x,add2y : std_logic;
	signal mv_vert1,mv_vert2 : std_logic;
	signal flag : std_logic_vector (8 downto 0);--indica que tecla esta pulsada
	signal start : std_logic;--indica si las motos se mueven
	signal fin : std_logic;

--señales PS2:
	signal ps2_reg : std_logic_vector (7 downto 0);
	signal new_data_s,ack : std_logic;
	
--FSM deteccion de F0 en keyboard:
	type states_ps2 is(wait_press,state_f0,wait_depress);
	signal current_state_ps2,next_state_ps2 : states_ps2;
	signal state_ps2 : std_logic;--indica si estoy esperando F0

--timer:
	signal timer : std_logic_vector (19 downto 0);
	signal fin_timer : std_logic;
	
--direcciones RAM:
	signal dir_refresco,dir_moto1,dir_moto2 : std_logic_vector(14 downto 0);

--valores RAM:
	signal estela,select_estela1,select_estela2,select_valor_moto1,select_valor_moto2 : std_logic_vector (1 downto 0);
	signal write_refresco,valor_moto1,valor_moto2 : std_logic;
	signal write_moto : std_logic;
	
--deteccion de eventos:
	signal flag_rise : std_logic;
	signal refresh_ok : std_logic;
	
--señales refresh:
	signal timer_refresh : std_logic_vector(18 downto 0);
	
--detector de flancos: Se usa para comprobar cuando se ha pulsado espacio=29.
	component edgedetector is
		Port(
				rst : in  STD_LOGIC;
				x : in  STD_LOGIC;
				clk : in  STD_LOGIC;
				x_falling_edge : out  STD_LOGIC;
				x_rising_edge : out  STD_LOGIC
			);
	end component;
	
--control keyboard:	
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
    
begin
	u_ps2 : ps2_interface port map(clk=>clk,rst=>rst,ps2_clk=>ps2_clk,ps2_data=>ps2_data,new_data_ack=>ack,data=>ps2_reg,new_data=>new_data_s);
		
	u_edge_start : edgedetector port map(rst=>rst,x=>flag(0),clk=>clk,x_falling_edge=>open,x_rising_edge=>flag_rise);
	u_edge_refresh : edgedetector port map(rst=>rst,x=>write_refresco,clk=>clk,x_falling_edge=>refresh_ok,x_rising_edge=>open);
	
--MEMORIA RAM	
	--moto 1 modulo1
	slice0 : RAMB16_S1_S1
		generic map(WRITE_MODE_B => "READ_FIRST") 
		port map (WEA=>write_moto,ENA=>not(dir_moto1(14)),SSRA=>not(rst),CLKA=>clk,ADDRA=>dir_moto1(13 downto 0),DIA=>"1",DOA=>select_valor_moto1(0 downto 0),
				WEB=>write_refresco,ENB=>'1',SSRB=>not(rst),CLKB=>clk,ADDRB=>dir_refresco(13 downto 0),DIB=>"0",DOB=>select_estela1(0 downto 0));
	--moto1 modulo2
	slice1 : RAMB16_S1_S1
		generic map(WRITE_MODE_B => "READ_FIRST") 
		port map (WEA=>write_moto,ENA=>dir_moto1(14),SSRA=>not(rst),CLKA=>clk,ADDRA=>dir_moto1(13 downto 0),DIA=>"1",DOA=>select_valor_moto1(1 downto 1),
				WEB=>write_refresco,ENB=>'1',SSRB=>not(rst),CLKB=>clk,ADDRB=>dir_refresco(13 downto 0),DIB=>"0",DOB=>select_estela1(1 downto 1));
	--moto2 modulo1
	slice2 : RAMB16_S1_S1
		generic map(WRITE_MODE_B => "READ_FIRST") 
		port map (WEA=>write_moto,ENA=>not(dir_moto2(14)),SSRA=>not(rst),CLKA=>clk,ADDRA=>dir_moto2(13 downto 0),DIA=>"1",DOA=>select_valor_moto2(0 downto 0),
				WEB=>write_refresco,ENB=>'1',SSRB=>not(rst),CLKB=>clk,ADDRB=>dir_refresco(13 downto 0),DIB=>"0",DOB=>select_estela2(0 downto 0));
	--moto2 modulo2
	slice3 : RAMB16_S1_S1
		generic map(WRITE_MODE_B => "READ_FIRST") 
		port map (WEA=>write_moto,ENA=>dir_moto2(14),SSRA=>not(rst),CLKA=>clk,ADDRA=>dir_moto2(13 downto 0),DIA=>"1",DOA=>select_valor_moto2(1 downto 1),
				WEB=>write_refresco,ENB=>'1',SSRB=>not(rst),CLKB=>clk,ADDRB=>dir_refresco(13 downto 0),DIB=>"0",DOB=>select_estela2(1 downto 1));
				
--señales control RAM:
	write_moto <= fin_timer and start;
	
	dir_refresco <= line & pixel;
	dir_moto1 <= moto1y & moto1x;
	dir_moto2 <= moto2y & moto2x;
	
	estela(1) <= select_estela1(0) when dir_refresco(14) = '0' else select_estela1(1);
	valor_moto1 <= select_valor_moto1(0) when dir_moto1(14) = '0' else select_valor_moto1(1);
	
	estela(0) <= select_estela2(0) when dir_refresco(14) = '0' else select_estela2(1);
	valor_moto2 <= select_valor_moto2(0) when dir_moto2(14) = '0' else select_valor_moto2(1);
  
--VGA:
	pixelcnt : process(rst,clk)
	begin
		if (rst='0') then
			pixelcntout <= (others=>'0');
		elsif(rising_edge(clk)) then
			if (pixelcntout = 1588) then
				pixelcntout <= (others=>'0');
			else
				pixelcntout <= pixelcntout+1;
			end if;
		end if;
	end process pixelcnt;

	linecnt : process(rst,clk)
	begin
		if(rst='0') then
			linecntout <= (others=>'0');
		elsif(rising_edge(clk)) then
			if(pixelcntout=1588) then
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
	line <= linecntout(8 downto 2);--7bits
	pixel <= pixelcntout(10 downto 3);--8bits
	color <= "111000000" when ((line = moto1y or line = moto1y-1 or line = moto1y+1) and (pixel = moto1x or pixel = moto1x-1 or pixel = moto1x+1)) or estela(1) = '1' else
			"000000111" when ((line = moto2y or line = moto2y-1 or line = moto2y+1) and (pixel = moto2x or pixel = moto2x-1 or pixel = moto2x+1)) or estela(0) = '1' else
			"000000000";
  
--Movimiento motos:
	p_moto1x : process(clk,rst,add1x,mv_vert1,fin_timer)
  	begin
		if(rst = '0') then
			moto1x <= (others=>'0');
		elsif(rising_edge(clk)) then
			if(start = '1' and mv_vert1 = '0' and fin_timer = '1') then
				if(add1x = '1' and moto1x = 153) then
					moto1x <= (others=>'0');--reaparecer por la izquierda
				elsif(add1x = '1') then
					moto1x <= moto1x + 1;
				elsif(add1x = '0' and moto1x = 0) then
					moto1x <= "10011001";--reaparecer por la derecha
				elsif(add1x = '0') then
					moto1x <= moto1x - 1;
				end if;
			elsif(flag_rise = '1') then
				moto1x <= (others=>'0');
			end if;
		end if;
	end process;
	
	p_moto1y : process(clk,rst,add1y,mv_vert1,fin_timer)
  	begin
		if(rst = '0') then
			moto1y <= "0001000";--8
		elsif(rising_edge(clk)) then
			if(start = '1' and mv_vert1 = '1' and fin_timer = '1') then
				if(add1y = '1' and moto1y = 120) then
					moto1y <= (others=>'0');--reaparecer arriba
				elsif(add1y = '1') then
					moto1y <= moto1y + 1;
				elsif(add1y = '0' and moto1y = 0) then
					moto1y <= "1111000";--reaparecer abajo
				elsif(add1y = '0') then
					moto1y <= moto1y - 1;
				end if;
			elsif(flag_rise = '1') then
				moto1y <= "0001000";
			end if;
		end if;
	end process;
	
	p_moto2x : process(clk,rst,add2x,mv_vert2,fin_timer)
  	begin
		if(rst = '0') then
			moto2x <= "10011001";--153
		elsif(rising_edge(clk)) then
			if(start = '1' and mv_vert2 = '0' and fin_timer = '1') then
				if(add2x = '1' and moto2x = 153) then
					moto2x <= (others=>'0');--reaparecer izquierda
				elsif(add2x = '1') then
					moto2x <= moto2x + 1;
				elsif(add2x = '0' and moto2x = 0) then
					moto2x <= "10011001";--reaparecer derecha
				elsif(add2x = '0') then
					moto2x <= moto2x - 1;
				end if;
			elsif(flag_rise = '1') then
				moto2x <= "10011001";
			end if;
		end if;
	end process;
 
	p_moto2y : process(clk,rst,add2y,mv_vert2,fin_timer)
  	begin
		if(rst = '0') then
			moto2y <= "1110000";--112
		elsif(rising_edge(clk)) then
			if(start = '1' and mv_vert2 = '1' and fin_timer = '1') then
				if(add2y = '1' and moto2y = 120) then
					moto2y <= (others=>'0');--reaparecer arriba
				elsif(add2y = '1') then
					moto2y <= moto2y + 1;
				elsif(add2y = '0' and moto2y = 0) then
					moto2y <= "1111000";--reaparecer abajo
				elsif(add2y = '0') then
					moto2y <= moto2y - 1;
				end if;
			elsif(flag_rise = '1') then
				moto2y <= "1110000";
			end if;
		end if;
	end process;
	
	gen_signals_motos : process(clk,rst,flag)
	begin
		if(rst = '0') then
			mv_vert1 <= '0';
			add1y <= '0';
			add1x <= '1';
			mv_vert2 <= '0';
			add2x <= '0';
			add2y <= '0';
		elsif(rising_edge(clk)) then
			if(flag(8) = '1') then
				mv_vert1 <= '1';
				add1y <= '0';
				add1x <= '0';
			elsif(flag(7) = '1') then
				mv_vert1 <= '1';
				add1y <= '1';
				add1x <= '0';
			end if;
			if(flag(4) = '1') then
				mv_vert1 <= '0';
				add1y <= '0';
				add1x <= '0';			
			elsif(flag(3) = '1') then
				mv_vert1 <= '0';
				add1y <= '0';
				add1x <= '1';
			end if;
			if(flag(6) = '1') then
				mv_vert2 <= '1';
				add2y <= '0';
				add2x <= '0';
			elsif(flag(5) = '1') then
				mv_vert2 <= '1';
				add2y <= '1';
				add2x <= '0';
			end if;
			if(flag(2) = '1') then
				mv_vert2 <= '0';
				add2y <= '0';
				add2x <= '0';
			elsif(flag(1) = '1') then
				mv_vert2 <= '0';
				add2y <= '0';
				add2x <= '1';
			end if;
			if(flag(0) = '1') then
				mv_vert1 <= '0';
				add1y <= '0';
				add1x <= '1';
				mv_vert2 <= '0';
				add2y <= '0';
				add2x <= '0';
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
					if(ps2_reg = x"15") then--Q
						flag(8) <= '1';
					elsif(ps2_reg = x"1C") then--A
						flag(7) <= '1';
					elsif(ps2_reg = x"4D") then--P
						flag(6) <= '1';
					elsif(ps2_reg = x"4B") then--L
						flag(5) <= '1';
					elsif(ps2_reg = x"1A") then--Z
						flag(4) <= '1';
					elsif(ps2_reg = x"22") then--X
						flag(3) <= '1';
					elsif(ps2_reg = x"31") then--N
						flag(2) <= '1';
					elsif(ps2_reg = x"3A") then--M
						flag(1) <= '1';
					elsif(ps2_reg = x"29") then--espacio
						flag(0) <= '1';
					end if;
				else
					if(ps2_reg = x"15") then--Q
						flag(8) <= '0';
					elsif(ps2_reg = x"1C") then--A
						flag(7) <= '0';
					elsif(ps2_reg = x"4D") then--P
						flag(6) <= '0';
					elsif(ps2_reg = x"4B") then--L
						flag(5) <= '0';
					elsif(ps2_reg = x"1A") then--Z
						flag(4) <= '0';
					elsif(ps2_reg = x"22") then--X
						flag(3) <= '0';
					elsif(ps2_reg = x"31") then--N
						flag(2) <= '0';
					elsif(ps2_reg = x"3A") then--M
						flag(1) <= '0';
					elsif(ps2_reg = x"29") then--espacio
						flag(0) <= '0';
					end if;
				end if;
				ack <= '1';
			else
				ack <= '0';
			end if;
		end if;
	end process;
	
--timer 50px/s:
	p_timer : process(clk,rst)
	begin
		if(rst = '0') then
			timer <= (others=>'0');
			fin_timer <= '0';
		elsif(rising_edge(clk)) then
			if(timer = "11110100001000111111") then--50px/s
				fin_timer <= '1';
				timer <= (others=>'0');
			else
				timer <= timer + 1;
				fin_timer <= '0';
			end if;
		end if;
	end process;
	
--registro que controla si el juego esta en marcha:
	p_start : process(clk,rst,refresh_ok,flag_rise,fin)
	begin
		if(rst = '0') then
			start <= '0';
		elsif(rising_edge(clk)) then
			if(refresh_ok = '1') then
				start <= '1';
			elsif(fin = '1') then
				start <= '0';
			end if;
		end if;
	end process;
	
--timer durante el cual se barre/limpia la pantalla:
	p_timer_refresh : process(clk,rst)
	begin
		if(rst = '0') then
			timer_refresh <= (others=>'0');
			write_refresco <= '1';
		elsif(rising_edge(clk)) then
			if(flag_rise = '1') then
				timer_refresh <= (others=>'0');
			else
				if(timer_refresh = "1111111111111111111") then
					write_refresco <= '0';
				else
					timer_refresh <= timer_refresh + 1;
					write_refresco <= '1';
				end if;
			end if;
		end if;
	end process;

--Fin de Juego:	
	fin <= '1' when estela = "11" or (valor_moto1 = '1' and fin_timer = '1') or (valor_moto2 = '1' and fin_timer = '1') else '0';
end rtl;