library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity datapath_divider is
	generic (
		INPUT_WIDTH: integer := 8 ;
		COUNTER_WIDTH: integer := 4
	);
	port (
		clk, t0, t1, t2: in std_logic;
		p0: out std_logic; 
		a,b: in std_logic_vector (INPUT_WIDTH - 1 downto 0);
		q:   out std_logic_vector(INPUT_WIDTH - 1 downto 0)
		);
end entity datapath_divider;

architecture standard of datapath_divider is
	
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

	component Sub2 is  -- Adding the necessary components
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

	signal ta : std_logic_vector(2 * INPUT_WIDTH - 1 downto 0);
	signal diff : std_logic_vector(INPUT_WIDTH  downto 0);
	signal t : std_logic_vector(INPUT_WIDTH  downto 0);
	signal counter : std_logic_vector(COUNTER_WIDTH - 1 downto 0);
	signal counter_adder_out : std_logic_vector(COUNTER_WIDTH downto 0);
	signal b_is_zero, done_a1, done_s1 : std_logic;
	
	begin
		b_is_zero <= (AND (std_logic_vector(unsigned(b)) xnor (INPUT_WIDTH - 1 downto 0 => '0'))); -- This signal tells datapath_divider that the sampled value of B is zero; thus don't			 report real value of division
		q <= t(INPUT_WIDTH - 1 downto 0); -- The output is connected to the t register

		p0 <= (AND (std_logic_vector(counter) xnor std_logic_vector(to_unsigned(INPUT_WIDTH	, COUNTER_WIDTH)))); -- (Has to be combinational logic therefore is outside of the process)	

		main_subtractor : Sub2 
			generic map (INPUT_WIDTH => INPUT_WIDTH)
			port map(t1, done_s1, ta(2 * INPUT_WIDTH - 2 downto INPUT_WIDTH - 1), b, diff, clk, '0');
		
		counter_adder : Add2 
			generic map(INPUT_WIDTH => COUNTER_WIDTH)
			port map(t1, done_a1, counter, std_logic_vector(to_unsigned(1, COUNTER_WIDTH)), counter_adder_out, clk, '0');

		process(clk, t0, t1, t2)
		begin
			if rising_edge(clk) then
				if(t0 = '1') then -- We are in the reset state
					ta <= (INPUT_WIDTH - 1 downto 0=> '0') & a;
					t <= (others => '0');
					counter <= (others => '0');
				
				-- Funnily enough we don't need to do anything for t1 case. It is purely just priming.
				
				elsif (t2 = '1') then -- We are in the LOOP_STATE
					with b_is_zero select
						t <= 	t(INPUT_WIDTH - 1 downto 0) & not diff(INPUT_WIDTH ) when '0',	-- basically if diff was positive, we can subtract so we add a 1 at the end. 
								(others => '0') when others;			-- with b = 0, you don't want to change t at all.
					if (diff(INPUT_WIDTH ) = '0') then -- divisor < dividend (since carry is RESET)
						ta(2 * INPUT_WIDTH - 1 downto INPUT_WIDTH ) <= diff(INPUT_WIDTH - 1 downto 0);
						ta(INPUT_WIDTH - 1 downto 0) <= ta(INPUT_WIDTH - 2 downto 0) & '0';
					else	-- divisor > dividend
						ta(2 * INPUT_WIDTH - 1 downto 0) <= ta(14 downto 0) & '0';
					end if;
					
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