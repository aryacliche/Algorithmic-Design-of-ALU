library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
library work;
use work.all;

entity square_root is
	generic (
		INPUT_WIDTH: integer := 8
	);
	port (
		clk, reset: in std_logic;
		start: in std_logic; 
		x: in std_logic_vector (INPUT_WIDTH - 1 downto 0);
		y: out std_logic_vector(INPUT_WIDTH / 2 - 1 downto 0);
		done: out std_logic);
end entity square_root;

architecture Simple of square_root is
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
			INPUT_WIDTH : integer
		);
		port (
			start: in std_logic; 
			done: out std_logic;
			A,B: in std_logic_vector (INPUT_WIDTH - 1 downto 0);
			C:   out std_logic_vector(INPUT_WIDTH downto 0);
			clk: in std_logic;
			reset: in std_logic);
	end component Sub2;

	component Add2 is	-- computes A - B
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
	end component Add2;
	
	type states is (DONE_STATE, MULTIPLY_STATE, LOOP_STATE, RST_STATE, PRELOOP_STATE, POSTLOOP1_STATE, POSTLOOP2_STATE);
	signal curr_state: states;

	signal x_minus_tsquare : std_logic_vector(INPUT_WIDTH downto 0);
	signal x_minus_tplus1square, sub_diff : std_logic_vector(INPUT_WIDTH + 1 downto 0);
	-- x_minus_tsquare stores the value of x - t^2 : Should compulsorily be non-negative
	-- x_minus_tplus1square stores the value of x - (t + 1)^2 : Should compulsorily be negative
	signal ty : std_logic_vector(INPUT_WIDTH - 1 downto 0); -- this stores the value of y^2
	
	signal done_m, done_s1, done_a1 : std_logic;
	signal start_m, start_s1, start_a1 : std_logic;

	signal add_a, add_b : std_logic_vector(INPUT_WIDTH / 2 - 1 downto 0);
	signal add_c : std_logic_vector(INPUT_WIDTH / 2 downto 0);
	signal sub_a, sub_b: std_logic_vector(INPUT_WIDTH downto 0);
	signal mul_a, mul_b : std_logic_vector(INPUT_WIDTH / 2 - 1 downto 0);
	signal t, lower, upper : std_logic_vector(INPUT_WIDTH / 2 - 1 downto 0);
	

begin
	main_multiplier : multiplier_faster 
		generic map(INPUT_WIDTH / 2) 
		port map(clk, reset, start_m, mul_a, mul_b, ty, done_m);

	-- Both x_minus_tsquare and x_minus_tplus1square share this subtractor
	-- x_minus_tsquare checks if we have a value of t smaller than or equal to sqrt(x)
	-- If x_minus_tplus1square is non-negative (while x_minus_tsquare is valid), then x < (t + 1)^2
	subtractor : Sub2 
		generic map(INPUT_WIDTH + 1) 
		port map(start_s1, done_s1, sub_a, sub_b, sub_diff, clk, reset);
	
	-- Adder is used to update the value of t and upper, lower
	adder : Add2 
		generic map(INPUT_WIDTH / 2) 
		port map(start_a1, done_a1, add_a, add_b, add_c, clk, reset);

	y <= t(INPUT_WIDTH / 2 - 1 downto 0); -- The output is connected to the t register (but we skip the MSB for some reason)
	
	process(clk, reset, start, curr_state)
		variable next_state : states;
		variable done_var : std_logic;
	begin
		case curr_state is
			when RST_STATE =>
				done_var := '0';
				start_s1 <= '0';
				start_a1 <= '0';
				done_var := '0';
				if(start = '1') then
					start_m <= '1';
					upper <= std_logic_vector(to_unsigned(2 ** (INPUT_WIDTH / 2) - 1, INPUT_WIDTH / 2));
					lower <= std_logic_vector(to_unsigned(0, INPUT_WIDTH / 2));
					-- start off t from a middle value
					t <= std_logic_vector(to_unsigned(2 ** (INPUT_WIDTH / 2 - 1) - 1, INPUT_WIDTH / 2));
					mul_a <= std_logic_vector(to_unsigned(2 ** (INPUT_WIDTH / 2 - 1) - 1, INPUT_WIDTH / 2));
					mul_b <= std_logic_vector(to_unsigned(2 ** (INPUT_WIDTH / 2 - 1) - 1, INPUT_WIDTH / 2));
					next_state := MULTIPLY_STATE;
				else
					next_state := RST_STATE;
				end if;

			when MULTIPLY_STATE =>
				done_var := '0';
				start_a1 <= '0';
				start_m <= '0';
				if (done_m = '1') then
					sub_a <= '0' & x;
					sub_b <= '0' & ty;
					start_s1 <= '1';
					next_state := PRELOOP_STATE;
				else
					start_s1 <= '0';
					next_state := MULTIPLY_STATE;
				end if;

			when PRELOOP_STATE =>
				x_minus_tsquare <= sub_diff(INPUT_WIDTH downto 0);
				start_m <= '0';
				done_var := '0';
				if (sub_diff(INPUT_WIDTH + 1) = '0') then -- i.e. we have a non-negative value
					sub_a <= sub_diff(INPUT_WIDTH downto 0);
					sub_b <= (INPUT_WIDTH / 2 - 1 downto 0 => '0') & t & '1'; -- Same as 2 * t + 1
					start_s1 <= '1';
					start_a1 <= '0';
					next_state := LOOP_STATE;
				else
					start_s1 <= '0';
					start_a1 <= '1';
					add_a <= t;
					add_b <= std_logic_vector(to_signed(-1, INPUT_WIDTH / 2));
					next_state := POSTLOOP1_STATE;
				end if;

			when LOOP_STATE =>
				x_minus_tplus1square <= sub_diff;
				start_m <= '0';
				start_s1 <= '0';
				if (sub_diff(INPUT_WIDTH + 1) = '1') then -- we found the correct value!
					start_a1 <= '0';
					done_var := '1';
					next_state := DONE_STATE;
				else
					start_a1 <= '1';
					add_a <= t;
					if (x_minus_tsquare(INPUT_WIDTH) = '1') then		
						add_b <= std_logic_vector(to_signed(-1, INPUT_WIDTH / 2));
					else
						add_b <= std_logic_vector(to_unsigned(1, INPUT_WIDTH / 2));
					end if;
					done_var := '0';
					next_state := POSTLOOP1_STATE;
				end if;

			when POSTLOOP1_STATE =>
				start_a1 <= '1';
				start_s1 <= '0';
				start_m <= '0';
				if (x_minus_tsquare(INPUT_WIDTH) = '1') then
					upper <= add_c(INPUT_WIDTH / 2 - 1 downto 0);
					add_a <= lower;
					add_b <= add_c(INPUT_WIDTH / 2 - 1 downto 0);
				else
					lower <= add_c(INPUT_WIDTH / 2 - 1 downto 0);
					add_a <= upper;
					add_b <= add_c(INPUT_WIDTH / 2 - 1 downto 0);
				end if;
				done_var := '0';
				next_state := POSTLOOP2_STATE;

			when POSTLOOP2_STATE =>
				start_a1 <= '1';
				start_s1 <= '0';
				start_m <= '1';
				mul_a <= '0' & add_c(INPUT_WIDTH / 2 - 1 downto 1);
				mul_b <= '0' & add_c(INPUT_WIDTH / 2 - 1 downto 1);
				t <= '0' & add_c(INPUT_WIDTH / 2 - 1 downto 1);
				done_var := '0';	
				next_state := MULTIPLY_STATE;

			when DONE_STATE =>
				if (start = '1') then
					start_m <= '1';
					upper <= std_logic_vector(to_unsigned(2 ** (INPUT_WIDTH / 2) - 1, INPUT_WIDTH / 2));
					lower <= std_logic_vector(to_unsigned(0, INPUT_WIDTH / 2));
					mul_a <= std_logic_vector(to_unsigned(2 ** (INPUT_WIDTH / 2 - 1) - 1, INPUT_WIDTH / 2));
					mul_b <= std_logic_vector(to_unsigned(2 ** (INPUT_WIDTH / 2 - 1) - 1, INPUT_WIDTH / 2));
					t <= std_logic_vector(to_unsigned(2 ** (INPUT_WIDTH / 2 - 1) - 1, INPUT_WIDTH / 2));
					done_var := '0';
					next_state := MULTIPLY_STATE;
				else
					done_var := '1';
					next_state := DONE_STATE;
				end if;
		end case;

		if rising_edge(clk) then
			done <= done_var;
			if (reset = '1') then
				curr_state <= RST_STATE;
			else
				curr_state <= next_state;
			end if;
		end if;
	end process;
end Simple;