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
		p0, p1: out std_logic; 
		x : in std_logic_vector (INPUT_WIDTH - 1 downto 0);
		y: out std_logic_vector (INPUT_WIDTH / 2 - 1 downto 0)
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

	component Sub2 is	-- computes A - B
		generic (
			INPUT_WIDTH : integer := 8
		);
		port (
			start: in std_logic; 
			done: out std_logic;
			A,B: in std_logic_vector (INPUT_WIDTH - 1 downto 0);
			C:   out std_logic_vector(INPUT_WIDTH downto 0);
			clk: in std_logic;
			reset: in std_logic);
	end component Sub2;
	
	signal p_ : std_logic_vector(INPUT_WIDTH downto 0);
	signal q_ : std_logic_vector(INPUT_WIDTH + 1 downto 0);
	signal new_bound : std_logic_vector(INPUT_WIDTH / 2 downto 0);
	
	signal t : std_logic_vector(INPUT_WIDTH / 2 downto 0); -- this stores out candidate value of y
	signal upper, lower : std_logic_vector(INPUT_WIDTH / 2 downto 0); -- these are going to be used for binary searching for the value of t

	signal ty : std_logic_vector(INPUT_WIDTH - 1 downto 0); -- this stores the value of y^2 
	signal done_m, done_s1, start_a1 : std_logic;
	signal start_m, start_s1, start_a1 : std_logic;

	signal mul_a, mul_b : std_logic_vector(INPUT_WIDTH / 2 - 1 downto 0);
	signal sub_a, sub_b: std_logic_vector(INPUT_WIDTH + 1 downto 0);
	signal sub_diff: std_logic_vector(INPUT_WIDTH + 2 downto 0);
	
	begin
		main_multiplier : multiplier_faster 
			generic map(INPUT_WIDTH / 2) 
			port map(clk, reset, start_m, mul_a, mul_b, ty, done_m);

		-- Both p_ and q_ share this subtractor
		-- p_ checks if we have a value of t smaller than or equal to sqrt(x)
		-- If q_ is non-negative (while p_ is valid), then x < (t + 1)^2
		subtractor : Sub2 
			generic map(INPUT_WIDTH + 1) 
			port map(start_s1, done_s1, sub_a, sub_b, sub_diff, clk, reset);
		
		-- Adder is used to update the value of t and upper, lower
		adder : Add2 
			generic map(INPUT_WIDTH + 1) 
			port map(start_a1, done_a1, 
				(INPUT_WIDTH / 2 - 1 downto 0 => '0') & t & '1',  -- this is basically 2 * t + 1. No need for an adder!
				p_, q_, clk, reset);
		
		y <= t(INPUT_WIDTH / 2 - 1 downto 0); -- The output is connected to the t register (but we skip the MSB for some reason)
		
		-- looking at the predicates
		p0 <= done_m; -- this signifies that the multiplier is done
		p1 <= (not p_(INPUT_WIDTH - 1)) AND done_s1;
		p2 <= (not q_(INPUT_WIDTH)) AND done_s1;

		start_s1 <= done_m; -- Every time we are done with the multiplier, we start the subtractor

		process(clk, t0, t1)
		begin
			if rising_edge(clk) then
				if(t0 = '1') then -- We are transitioning to the MULTIPLY_STATE (therefore initialise everything)
					start_m <= '1';
					upper <= to_unsigned(2 ** (INPUT_WIDTH / 2) - 1, INPUT_WIDTH / 2);
					lower <= to_unsigned(0, INPUT_WIDTH / 2);
					mul_a <= to_unsigned(2 ** (INPUT_WIDTH / 2 - 1) - 1, INPUT_WIDTH / 2 + 1); -- to start off with a middle value
					mul_b <= to_unsigned(2 ** (INPUT_WIDTH / 2 - 1) - 1, INPUT_WIDTH / 2 + 1); -- to start off with a middle value
					t <= to_unsigned(2 ** (INPUT_WIDTH / 2 - 1) - 1, INPUT_WIDTH / 2 + 1); -- to start off with a middle value
				
				elsif (t1 = '1') then -- We are in the MULTIPLY_STATE
					sub_a <= x;
					sub_b <= std_logic_vector(unsigned(ty)); -- we are going to compare x with t^2
				
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