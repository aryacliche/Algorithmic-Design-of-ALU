library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.all;

entity multiplier_faster is
	generic (
		INPUT_WIDTH: integer := 8
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

	component Add2_with_carry is
		generic (
			INPUT_WIDTH : integer
		);
		port (
			start: in std_logic; 
			done: out std_logic;
			A,B: in std_logic_vector (INPUT_WIDTH - 1 downto 0);
			Cin : in std_logic;
			C:   out std_logic_vector(INPUT_WIDTH downto 0);
			clk: in std_logic;
			reset: in std_logic);
	end component Add2_with_carry;
	
    type states is (DONE_STATE, WAIT_STATE, RST_STATE, Add1_DONE_STATE, Add2_DONE_STATE, Add3_DONE_STATE);
    signal curr_state : states;

	signal done_temp : std_logic_vector(INPUT_WIDTH / 2 - 1 downto 0);
    signal start_temp : std_logic_vector(INPUT_WIDTH / 2 - 1 downto 0);
    signal aHbH, aHbL, aLbH, aLbL : std_logic_vector(INPUT_WIDTH - 1 downto 0);
	signal beta : std_logic_vector(INPUT_WIDTH downto 0);
	signal gamma : std_logic_vector(INPUT_WIDTH - 1 downto 0);
	signal done_slave : std_logic;
    
begin
	slave_multiplier_0 : multiplier generic map(INPUT_WIDTH / 2) port map(clk, reset, start_temp(0), a(INPUT_WIDTH - 1 downto INPUT_WIDTH / 2), b(INPUT_WIDTH - 1 downto INPUT_WIDTH / 2), aHbH, done_temp(0)); -- a_H, b_H
    slave_multiplier_1 : multiplier generic map(INPUT_WIDTH / 2) port map(clk, reset, start_temp(1), a(INPUT_WIDTH - 1 downto INPUT_WIDTH / 2), b(INPUT_WIDTH / 2 - 1 downto 0), aHbL, done_temp(1)); -- a_H, b_L
    slave_multiplier_2 : multiplier generic map(INPUT_WIDTH / 2) port map(clk, reset, start_temp(2), a(INPUT_WIDTH / 2 - 1	 downto 0), b(INPUT_WIDTH - 1 downto INPUT_WIDTH / 2), aLbH, done_temp(2)); -- a_L, b_H
    slave_multiplier_3 : multiplier generic map(INPUT_WIDTH / 2) port map(clk, reset, start_temp(3), a(INPUT_WIDTH / 2 - 1	 downto 0), b(INPUT_WIDTH / 2 - 1 downto 0), aLbL, done_temp(INPUT_WIDTH / 2 - 1)); -- a_L, b_L

	final_adder : Add2_with_carry generic map(INPUT_WIDTH) port map (adder_start, adder_done, adder_A, adder_B, adder_Cin, adder_C, clk, reset);
    
    p <= adder_C(INPUT_WIDTH - 1 downto 0) & gamma; -- this only makes sense once you realise that p will only have the correct value when in DONE state
	done_slaves <= AND done_temp;

    process(clk, reset, start, curr_state, done)
		variable next_state : states;
		variable done_var : std_logic;
	begin
		case curr_state is
				when RST_STATE =>
					done_var := '0';  
					adder_start <= '0';
					if(start = '1') then
						start_temp <= (others => '1');  -- Start all of the forks
						next_state := WAIT_STATE;
					else
						start_temp <= (others => '0');
						next_state := RST_STATE;
					end if;

				when WAIT_STATE =>
					done_var := '0';
					start_temp <= (others => '0');  -- While we are waiting for the result to come in, don't let anyone start the next line.
					if (done = '1') then  -- All of the forked proceesses were able to finish their products
						next_state := Add1_DONE_STATE;
						adder_A <= aLbH;
						adder_B <= aHbL;
						adder_Cin <= '0';
						adder_start <= '1';
					else		
						adder_start <= '0';	
						next_state := WAIT_STATE;
					end if;

				when Add1_DONE_STATE =>
					done_var := '0';
					start_temp <= (others => '0');  -- While we are waiting for the result to come in, don't let anyone start the next line.
					if (adder_done = '1') then  -- we are done with the first Addition
						next_state := Add2_DONE_STATE;
						beta <= adder_C;
						adder_A <= adder_C(INPUT_WIDTH / 2 - 1 downto 0) & (INPUT_WIDTH / 2 - 1 downto 0 => '0');
						adder_B <= aLbL;
						adder_Cin <= '0';
						adder_start <= '1';
					else		
						adder_start <= '0';	
						next_state := Add1_DONE_STATE;
					end if;

				when Add2_DONE_STATE =>
					done_var := '0';
					start_temp <= (others => '0');  -- While we are waiting for the result to come in, don't let anyone start the next line.
					if (adder_done = '1') then  -- we are done with the second Addition
						next_state := Add3_DONE_STATE;
						gamma <= adder_C(INPUT_WIDTH - 1 downto 0);
						adder_A <= aHbH;
						adder_B <= (INPUT_WIDTH / 2 - 2 downto 0 => '0') & beta(INPUT_WIDTH downto INPUT_WIDTH / 2);
						adder_Cin <= adder_C(INPUT_WIDTH);
						adder_start <= '1';
					else		
						adder_start <= '0';	
						next_state := Add2_DONE_STATE;
					end if;

				when Add3_DONE_STATE =>
					start_temp <= (others => '0');  -- While we are waiting for the result to come in, don't let anyone start the next line.
					adder_start <= '0';
					if (adder_done = '1') then  -- we are done with the third Addition
						next_state := DONE_STATE;
						done_var := '1';
					else		
						done_var := '0';
						next_state := Add3_DONE_STATE;
					end if;

				when DONE_STATE =>
					adder_start <= '0';
					if (adder_done = '0') -- we need to wait before we proclaim being right
						done_var := '0';
					else if (start = '1') then
						start_temp <= (others => '1');
						done_var := '1';
						next_state := WAIT_STATE;
					else
						start_temp <= (others => '0');
						done_var := '1';
						next_state := DONE_STATE;
					end if;
		end case;
		
		if rising_edge(clk) then
			if (reset = '1') then
				curr_state <= RST_STATE;
				done <= '0';
			else
				curr_state <= next_state;
				done <= done_var;
			end if;
		end if;
	end process;
end fork_RTL_based;