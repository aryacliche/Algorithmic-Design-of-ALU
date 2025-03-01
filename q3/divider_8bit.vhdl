library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.all;

entity divider_8bit is
	port (
		clk, reset: in std_logic;
		start: in std_logic; 
		a,b: in std_logic_vector (7 downto 0);
		q:   out std_logic_vector(7 downto 0);
		done: out std_logic);
end entity divider_8bit;

architecture RTL_based of divider_8bit is
	component datapath is
		port (
			clk, t0, t1: in std_logic;
			p0: out std_logic; 
			a,b: in std_logic_vector (7 downto 0);
			q:   out std_logic_vector(7 downto 0)
			);
	end component datapath;
	
	type states is (DONE_STATE, LOOP_STATE, RST_STATE);
	signal curr_state: states;
	signal t0, t1: std_logic; 	-- transfers
	signal p0 : std_logic; 		-- predicate

begin
	datapath_main : datapath port map(clk, t0, t1, p0, a, b, q);

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
					next_state := LOOP_STATE;
				else
					t0 <= '0';
					next_state := RST_STATE;
				end if;

			when LOOP_STATE =>
				t1 <= '1';	
				t0 <= '0';				
				if (p0 = '1') then -- If division is completed OR B is zero, we just rush to DONE_STATE
					done_var := '1';
					next_state := DONE_STATE;
				else
					done_var := '0';
					next_state := LOOP_STATE;
				end if;

			when DONE_STATE =>
				t1 <= '0';
				if (start = '1') then
					t0 <= '1';
					done_var := '0';
					next_state := LOOP_STATE;
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