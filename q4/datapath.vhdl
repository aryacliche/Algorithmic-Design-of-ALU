library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- use Work; -- I forgot how to import the entity from another file

entity datapath_squareroot is
	generic (
		INPUT_WIDTH: integer := 8
	);
	port (
		clk, t0, t1: in std_logic;
		x : in std_logic_vector (INPUT_WIDTH - 1 downto 0);
		p0, p1: out std_logic; 
		y: out std_logic_vector ((INPUT_WIDTH / 2) - 1 downto 0)
		);
end entity datapath_squareroot;

architecture standard of datapath_squareroot is
	component multiplier_faster is
		generic (
			INPUT_WIDTH: integer
		);
		port (
			clk, reset: in std_logic;
			start: in std_logic; 
			a,b: in std_logic_vector (INPUT_WIDTH - 1 downto 0);
			p:   out std_logic_vector(2 * INPUT_WIDTH - 1 downto 0);
			done: out std_logic);
	end component multiplier_faster;
	
	signal p_ : std_logic_vector(INPUT_WIDTH downto 0);
	signal q_ : std_logic_vector(INPUT_WIDTH + 1 downto 0);
	signal new_bound : std_logic_vector(INPUT_WIDTH / 2 downto 0);
	
	signal t : std_logic_vector(INPUT_WIDTH / 2 downto 0); -- this stores out candidate value of y
	signal upper, lower : std_logic_vector(INPUT_WIDTH / 2 downto 0); -- these are going to be used for binary searching for the value of t

	signal ty : std_logic_vector(INPUT_WIDTH - 1 downto 0); -- this stores the value of y^2 
	signal done_m : std_logic;
	signal start_m : std_logic;
	
	begin
		main_multiplier : multiplier_faster 
			generic map(INPUT_WIDTH / 2) 
			port map(clk, reset, start_m, t(INPUT_WIDTH / 2 - 1 downto 0), t(INPUT_WIDTH / 2 - 1 downto 0), ty, done_m);
		
		y <= t(INPUT_WIDTH / 2 - 1 downto 0); -- The output is connected to the t register (but we skip the MSB for some reason)
		
		-- Intermediate signals that matter a lot
		p_ <= std_logic_vector(unsigned('0' & x) - unsigned('0' & ty)); -- This checks if we have a value of t smaller than or equal to sqrt(x)
		q_ <= std_logic_vector(unsigned((INPUT_WIDTH / 2 => '0') & t & '1') - unsigned('0' & p_)); -- If this is non-negative, then x < (t + 1)^2
		-- the first term is basically 2 * t  + 1. Smart na?
		
		-- p_'s signed bit decides the direction in which our binary search goes.
		with p_(INPUT_WIDTH) select
			new_bound 	<= std_logic_vector(unsigned(t) - 1) when '1',
						<= std_logic_vector(unsigned(t) + 1) when others; -- this is used to decrease the value of t
		
		with p_(INPUT_WIDTH) select
			new_t 	<= std_logic_vector((unsigned(new_bound) + unsigned(lower)) / 2) when '1',
					<= std_logic_vector((unsigned(new_bound) + unsigned(upper)) / 2) when others;
		
		-- looking at the predicates
		p0 <= done_m; -- this signifies that the multiplier is done
		p1 <= not (p_(INPUT_WIDTH) OR q_(INPUT_WIDTH + 1)); -- this signifies that we are done with the binary search (sign bits are being studied)

		process(clk, t0, t1)
		begin
			if rising_edge(clk) then
				if(t0 = '1') then -- We are transitioning to the MULTIPLY_STATE (therefore initialise everything)
					start_m <= '1';
					upper <= to_unsigned(2 ** (INPUT_WIDTH / 2) - 1, INPUT_WIDTH / 2);
					lower <= to_unsigned(0, INPUT_WIDTH / 2);
					t <= to_unsigned(2 ** (INPUT_WIDTH / 2 - 1) - 1, INPUT_WIDTH / 2 + 1); -- to start off with a middle value
				
				elsif (t1 = '1') then -- We are in the LOOP state and are soon going to transition to the MULTIPLY state therefore make all necessary changes to the inputs to the multiplier.
					if(p_(INPUT_WIDTH) = '1') then -- value of t exceeds sqrt (x) 
						upper <= std_logic_vector(unsigned(t(INPUT_WIDTH / 2  - 1 downto 0)) - 1); -- we need to decrease the value of t
						t <= std_logic_vector(unsigned('0' & t(INPUT_WIDTH / 2  - 1 downto 0)) - 1); -- we need to decrease the value of t
					else
						t(2 * INPUT_WIDTH downto 0) <= '0' & t(2 * INPUT_WIDTH downto 1);
					end if;
					
				else -- We are in the done state
					t <= t;
					
				end if;
			end if;
		end process;
end architecture standard;