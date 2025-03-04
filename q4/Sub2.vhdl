library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Sub2 is	-- computes A - B
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
end entity Sub2;

architecture Simple of Sub2 is
	type Add2State is (IDLE_STATE, DONE_STATE);
	signal fsm_state: Add2State;
begin
	process(clk, reset, fsm_state, start, A, B)
		variable next_fsm_state_var : Add2State;
		variable done_var : std_logic;
		variable next_C_var : std_logic_vector(INPUT_WIDTH downto 0);
	begin
		done_var := '0';
		next_fsm_state_var := fsm_state;
		
		case fsm_state is
			when IDLE_STATE =>
				if(start = '1') then
					next_fsm_state_var := DONE_STATE;
					next_C_var := std_logic_vector(unsigned('0' & A) - unsigned('0' & B));
				end if;
			when DONE_STATE =>
				done_var := '1';
				if(start = '1') then
					next_fsm_state_var := DONE_STATE;
					next_C_var := std_logic_vector(unsigned('0' & A) - unsigned('0' & B));
				else
					next_fsm_state_var := IDLE_STATE;
				end if;
		end case;

		done <= done_var;
		
		if(clk'event and (clk = '1')) then
			if (reset = '1') then
				fsm_state <= IDLE_STATE;
				C <= (others => '0');
			else
				fsm_state <= next_fsm_state_var;
				C <= next_C_var;
			end if;
		end if;
	end process;
end Simple;
