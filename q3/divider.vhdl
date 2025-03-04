library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
library work;
use work.all;

entity divider is
	generic (
		INPUT_WIDTH: integer := 8
	);
	port (
		clk, reset: in std_logic;
		start: in std_logic; 
		a,b: in std_logic_vector (INPUT_WIDTH - 1 downto 0);
		q:   out std_logic_vector(INPUT_WIDTH - 1 downto 0);
		done: out std_logic);
end entity divider;

architecture RTL_based of divider is
	component datapath_divider is
		generic (
			INPUT_WIDTH: integer;
			COUNTER_WIDTH: integer
		);
		port (
			clk, t0, t1, t2: in std_logic;
			p0: out std_logic; 
			a,b: in std_logic_vector (INPUT_WIDTH - 1 downto 0);
			q:   out std_logic_vector(INPUT_WIDTH - 1 downto 0)
			);
	end component datapath_divider;
	
	type states is (DONE_STATE, LOOP_STATE, RST_STATE, PRIME_STATE);
	signal curr_state: states;
	signal t0, t1, t2: std_logic; 	-- transfers
	signal p0 : std_logic; 		-- predicate

begin
	datapath_main : datapath_divider 
		generic map (INPUT_WIDTH => INPUT_WIDTH, COUNTER_WIDTH => 1 + integer(ceil(log2(real(INPUT_WIDTH))))) 
		port map(clk, t0, t1, t2, p0, a, b, q);

	process(clk, reset, p0, start, curr_state)
		variable next_state : states;
		variable done_var : std_logic;
	begin
		case curr_state is
			when RST_STATE =>
				done_var := '0';
				t1 <= '0';
				t2 <= '0';
				if(start = '1') then
					t0 <= '1';
					next_state := PRIME_STATE;
				else
					t0 <= '0';
					next_state := RST_STATE;
				end if;

			when PRIME_STATE =>
				t0 <= '0';
				t1 <= '1';
				t2 <= '0';
				done_var := '0';
				next_state := LOOP_STATE;

			when LOOP_STATE =>
				t0 <= '0';	
				t1 <= '0';			
				if (p0 = '1') then -- If division is completed OR B is zero, we just rush to DONE_STATE
					t2 <= '0';
					done_var := '1';
					next_state := DONE_STATE;
				else
					t2 <= '1';
					done_var := '0';
					next_state := PRIME_STATE;
				end if;

			when DONE_STATE =>
				t1 <= '0';
				if (start = '1') then
					t0 <= '1';
					done_var := '0';
					next_state := PRIME_STATE;
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