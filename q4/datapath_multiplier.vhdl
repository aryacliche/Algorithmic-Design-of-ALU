library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use Work.all;

entity datapath_multiplier is
	generic (
		INPUT_WIDTH: integer := 8;
		COUNTER_WIDTH: integer := 4
	);
	port (
		clk, t0, t1, t2: in std_logic;
		p0: out std_logic; 
		a,b: in std_logic_vector (INPUT_WIDTH - 1 downto 0);
		p:   out std_logic_vector(2 * INPUT_WIDTH - 1 downto 0)
		);
end entity datapath_multiplier;

architecture standard of datapath_multiplier is
	
	component Add2 is  -- Adding the necessary components
		generic (
			INPUT_WIDTH : integer
		);
		port (
			start: in std_logic; 
			done: out std_logic;
			A,B: in std_logic_vector (INPUT_WIDTH - 1 downto 0);
			C:   out std_logic_vector(INPUT_WIDTH downto 0);
			clk: in std_logic;
			reset: in std_logic);
	end component;

	signal ta : std_logic_vector(INPUT_WIDTH - 1 downto 0);
	signal t : std_logic_vector(INPUT_WIDTH * 2 downto 0);
	signal counter : std_logic_vector(COUNTER_WIDTH - 1 downto 0);
	signal counter_adder_out : std_logic_vector(COUNTER_WIDTH downto 0);
	signal main_adder_out : std_logic_vector(INPUT_WIDTH downto 0);
	signal done_a1, done_a2 : std_logic; -- honestly I am not even going to look at these signals
	
	begin
		main_adder : Add2 
		generic map(INPUT_WIDTH => INPUT_WIDTH)
		port map(t1, done_a1, 
			t(2 * INPUT_WIDTH downto INPUT_WIDTH + 1), b, 
			main_adder_out, 
			clk, '0');

		counter_adder : Add2 
		generic map(INPUT_WIDTH => COUNTER_WIDTH)
		port map(t1, done_a2, 
			counter, std_logic_vector(to_unsigned(1, COUNTER_WIDTH)), 
			counter_adder_out, 
			clk, '0');
		
		p <= t(2 * INPUT_WIDTH - 1 downto 0); -- The output is connected to the t register (but we skip the MSB for some reason)
		p0 <= (AND (counter xnor std_logic_vector(to_unsigned(INPUT_WIDTH, COUNTER_WIDTH)))); -- The predicate is the counter xor 8	(Has to be combinational logic therefore is outside of the process)

		process(clk, t0, t1, t2)
		begin
			if rising_edge(clk) then
				if(t0 = '1') then -- We are in the reset state
					ta <= a;
					t <= (others => '0');
					counter <= (others => '0');
				
				elsif (t1 = '1') then -- We are in the PRIME_STATE
					if(ta(0) = '1') then
						t(INPUT_WIDTH - 1 downto 0) <= t(INPUT_WIDTH downto 1);
					else
						t(2 * INPUT_WIDTH downto 0) <= '0' & t(2 * INPUT_WIDTH downto 1);
					end if;
				
				elsif (t2 = '1') then -- We are in the LOOP_STATE
					if (ta(0) = '1') then
						t(2 * INPUT_WIDTH downto INPUT_WIDTH) <= main_adder_out;
					end if;
					ta <= '0' & ta(INPUT_WIDTH - 1 downto 1);
					
					if (unsigned(counter) = INPUT_WIDTH) then
						counter <= counter;
					else
						counter <= counter_adder_out(COUNTER_WIDTH - 1 downto 0);
					end if;		
				
				else -- We are in the done state
					ta <= ta;
					t <= t;
					counter <= counter;
				end if;
			end if;
		end process;
end architecture standard;