library ieee;
use ieee.std_logic_1164.all;

entity ps2_interface is
	port(clk : in std_logic;
		rst : in std_logic;
		ps2_clk : in std_logic;
		ps2_data : in std_logic;
		new_data_ack : in std_logic;
		data : out std_logic_vector(7 downto 0);
		new_data : out std_logic
	);
end ps2_interface;

architecture rtl of ps2_interface is
	
	component synchronizer is
    		port ( x : in  std_logic;
			  rst : in std_logic;
			  clk : in std_logic;
           		 xsync : out  std_logic);
	end component;

	component edgedetector is
    		port ( rst : in  std_logic;
           		x : in  std_logic;
           		clk : in  std_logic;
           		x_falling_edge : out  std_logic;
           		x_rising_edge : out  std_logic);
	end component;
	
	type states_ps2 is (esperando_datos,esperando_ack);
	signal current_state,next_state : states_ps2;
	
	signal shifter_out : std_logic_vector(10 downto 0);
	signal shifter,clear_shifter,valid_data : std_logic;
	signal clk_sync : std_logic;
	signal ld_reg : std_logic;
	signal reg_out : std_logic_vector(7 downto 0);
	signal parity : std_logic;
	
	--trimmed signals:
	signal trim1 : std_logic;

begin
		state : process(clk,rst)
		begin
			if(rst = '0') then
				current_state <= esperando_datos;
			elsif(rising_edge(clk)) then
				current_state <= next_state;
			end if;
		end process;
		
		gen_state : process(current_state,clear_shifter,new_data_ack,valid_data)
		begin
			next_state <= current_state;
			case current_state is
				when esperando_datos =>
					if(valid_data = '1') then
						next_state <= esperando_ack;
					end if;
				when esperando_ack =>
					if(new_data_ack = '1') then
						next_state <= esperando_datos;
					end if;
			end case;
		end process;
		
		gen_signals : process(current_state,clear_shifter,new_data_ack)
		begin
			case current_state is
				when esperando_datos =>
					new_data <= '0';
					ld_reg <= '0';
					if(clear_shifter = '1') then
						ld_reg <= '1';
					end if;
				when esperando_ack =>
					new_data <= '1';
					ld_reg <= '0';
			end case;
		end process;
		
		reg_shifter : process(clk,rst)
		begin
			if(rst = '0') then
				shifter_out <= (others=>'1');
			elsif(rising_edge(clk)) then
				if(clear_shifter = '1') then
					shifter_out <= (others=>'1');
				end if;
				if(shifter = '1') then
					for i in 0 to 9 loop
						shifter_out(i) <= shifter_out(i+1); 
					end loop;
					shifter_out(10) <= ps2_data;
				end if;
			end if;
		end process;
		
		reg_data : process(clk,rst)
		begin
			if(rst = '0') then
				reg_out <= (others=>'0');
			elsif(rising_edge(clk)) then
				if(ld_reg = '1') then
					reg_out <= shifter_out(8 downto 1);
				end if;
			end if;
		end process;
		
		data <= reg_out;
		
		parity <= (shifter_out(1) xor shifter_out(2) xor shifter_out(3) xor shifter_out(4)) xor (shifter_out(5) xor 
		shifter_out(6) xor shifter_out(7) xor shifter_out(8)) xor shifter_out(9);
		
		clear_shifter <= not(shifter_out(0));

		valid_data <= clear_shifter and parity;
		
		u_sync_clk : synchronizer port map (x=>ps2_clk,rst=>rst,
					clk=>clk,xsync=>clk_sync);

		u_edge_clk : edgedetector port map (rst=>rst,x=>clk_sync,
					clk=>clk,x_falling_edge=>shifter,x_rising_edge=>trim1);

end rtl;

