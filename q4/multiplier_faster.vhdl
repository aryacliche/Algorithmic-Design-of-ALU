library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.all;

entity multiplier_faster is
	generic (
		INPUT_WIDTH: integer := 4
	);
	port (
		clk, reset: in std_logic;
		start: in std_logic; 
		a,b: in std_logic_vector (INPUT_WIDTH - 1 downto 0);
		p:   out std_logic_vector(2 * INPUT_WIDTH - 1 downto 0);
		done: out std_logic);
end entity multiplier_faster;

architecture fork_RTL_based of multiplier_faster is
	component multiplier is
		generic (
			INPUT_WIDTH: integer
		);
		port (
			clk, reset: in std_logic;
			start: in std_logic; 
			a,b: in std_logic_vector (INPUT_WIDTH - 1 downto 0);
			p:   out std_logic_vector(2 * INPUT_WIDTH - 1 downto 0);
			done: out std_logic);
	end component multiplier;
	
    type states is (DONE_STATE, WAIT_STATE, RST_STATE);
    signal curr_state : states;

	-- Temporary signals
	signal left_shift_1 : std_logic_vector(2 * INPUT_WIDTH - 1 downto 0);
	signal left_shift_2, left_shift_3 : std_logic_vector(3 * INPUT_WIDTH / 2 - 1 downto 0);
    signal temp_sum1, temp_sum2 : std_logic_vector(2 * INPUT_WIDTH downto 0);
    signal temp_sum3 : std_logic_vector(2 * INPUT_WIDTH + 1 downto 0);
	signal done_temp : std_logic_vector(INPUT_WIDTH / 2 - 1 downto 0);
    signal start_temp : std_logic_vector(INPUT_WIDTH / 2 - 1 downto 0);
    signal aHbH, aHbL, aLbH, aLbL : std_logic_vector(INPUT_WIDTH - 1 downto 0);
    
begin
	slave_multiplier_0 : multiplier generic map(INPUT_WIDTH / 2) port map(clk, reset, start_temp(0), a(INPUT_WIDTH - 1 downto INPUT_WIDTH / 2), b(INPUT_WIDTH - 1 downto INPUT_WIDTH / 2), aHbH, done_temp(0)); -- a_H, b_H
    slave_multiplier_1 : multiplier generic map(INPUT_WIDTH / 2) port map(clk, reset, start_temp(1), a(INPUT_WIDTH - 1 downto INPUT_WIDTH / 2), b(INPUT_WIDTH / 2 - 1 downto 0), aHbL, done_temp(1)); -- a_H, b_L
    slave_multiplier_2 : multiplier generic map(INPUT_WIDTH / 2) port map(clk, reset, start_temp(2), a(INPUT_WIDTH / 2 - 1	 downto 0), b(INPUT_WIDTH - 1 downto INPUT_WIDTH / 2), aLbH, done_temp(2)); -- a_L, b_H
    slave_multiplier_3 : multiplier generic map(INPUT_WIDTH / 2) port map(clk, reset, start_temp(INPUT_WIDTH / 2 - 1), a(INPUT_WIDTH / 2 - 1	 downto 0), b(INPUT_WIDTH / 2 - 1 downto 0), aLbL, done_temp(INPUT_WIDTH / 2 - 1)); -- a_L, b_L

	left_shift_1 <= aHbH & std_logic_vector(to_unsigned(0, INPUT_WIDTH));
	left_shift_2 <= aHbL & std_logic_vector(to_unsigned(0, INPUT_WIDTH / 2));
	left_shift_3 <= aLbH & std_logic_vector(to_unsigned(0, INPUT_WIDTH / 2));
    temp_sum1 <= std_logic_vector(unsigned('0' & left_shift_1) + unsigned((INPUT_WIDTH  + 1=>'0') & aLbL));
    temp_sum2 <= std_logic_vector(unsigned((INPUT_WIDTH / 2 + 1 => '0') & left_shift_2) + unsigned((INPUT_WIDTH / 2 + 1=>'0') & left_shift_3));
    temp_sum3 <= std_logic_vector(unsigned('0' & temp_sum1) + unsigned('0' & temp_sum2));
    
	p <= temp_sum3	(2 * INPUT_WIDTH - 1 downto 0);
    done <= AND done_temp;

    process(clk, reset, start, curr_state, done)
		variable next_state : states;
	begin
		case curr_state is
				when RST_STATE =>
					if(start = '1') then
						start_temp <= (others => '1');  -- Start all of the forks
						next_state := WAIT_STATE;
					else
						start_temp <= (others => '0');
						next_state := RST_STATE;
					end if;

				when WAIT_STATE =>
					start_temp <= (others => '0');  -- While we are waiting for the result to come in, don't let anyone start the next line.
					if (done = '1') then  -- All of the forked proceesses were able to finish their products
						next_state := DONE_STATE;
					else			
						next_state := WAIT_STATE;
					end if;

				when DONE_STATE =>
					if (start = '1') then
						start_temp <= (others => '1');
						next_state := WAIT_STATE;
					else
						start_temp <= (others => '0');
						next_state := DONE_STATE;
					end if;
		end case;
		
		if rising_edge(clk) then
			if (reset = '1') then
				curr_state <= RST_STATE;
			else
				curr_state <= next_state;
			end if;
		end if;
	end process;
end fork_RTL_based;