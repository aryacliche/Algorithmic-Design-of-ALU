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

architecture RTL_based of square_root is
	component datapath_squareroot is -- need to be replaced
		generic (
			INPUT_WIDTH: integer
		);
		port (
			clk, t0, t1: in std_logic;
			p0: out std_logic; 
			a,b: in std_logic_vector (INPUT_WIDTH - 1 downto 0);
			p:   out std_logic_vector(2 * INPUT_WIDTH - 1 downto 0)
		);
	end component datapath_squareroot;
	
	type states is (DONE_STATE, MULTIPLY_STATE, LOOP_STATE, RST_STATE);
	signal curr_state: states;
	signal t0, t1 : std_logic; -- transfers
	signal p0, p1 : std_logic; -- predicate

begin
	datapath_main : datapath_squareroot generic map (INPUT_WIDTH) port map(clk, t0, t1, p0, a, b, p);

	process(clk, reset, p0, start, curr_state)
		variable next_state : states;
		variable done_var : std_logic;
	begin
		case curr_state is
			when RST_STATE =>
				done_var := '0';
				t1 <= '0';
				if(start = '1') then
					t0 <= '1';
					next_state := MULTIPLY_STATE;
				else
					t0 <= '0';
					next_state := RST_STATE;
				end if;

			when MULTIPLY_STATE =>
				t0 <= '0';
				t1 <= '0';	
				done_var := '0';
				if (p0 = '1') then
					next_state := LOOP_STATE;
				else
					next_state := MULTIPLY_STATE;
				end if;

			when LOOP_STATE =>
				t0 <= '0';
				t1 <= '1';	
				if (p1 = '1') then
					done_var := '1';
					next_state := DONE_STATE;
				else
					done_var := '0';
					next_state := MULTIPLY_STATE;
				end if;

			when DONE_STATE =>
				t1 <= '0';
				if (start = '1') then
					t0 <= '1';
					done_var := '0';
					next_state := MULTIPLY_STATE;
				else
					t0 <= '0';
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
end RTL_based;