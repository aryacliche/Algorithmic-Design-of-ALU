library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity datapath is
	port (
		clk, t0, t1: in std_logic;
		p0: out std_logic; 
		a,b: in std_logic_vector (7 downto 0);
		q:   out std_logic_vector(7 downto 0)
		);
end entity datapath;

architecture standard of datapath is
	
	-- component Add2 is  -- Adding the necessary components
	--    port (
	-- 		start: in std_logic; 
	-- 		done: out std_logic;
	-- 		A,B: in std_logic_vector (7 downto 0);
	-- 		C:   out std_logic_vector(7 downto 0);
	-- 		clk: in std_logic;
	-- 		reset: in std_logic);
	-- end component;

	signal ta : std_logic_vector(15 downto 0);
	signal diff : std_logic_vector(8 downto 0);
	signal t : std_logic_vector(8 downto 0);
	signal counter : unsigned(3 downto 0);
	signal b_is_zero : std_logic;
	
	begin
		-- Structural stuff
		-- main_adder : Add2 port map(start, done, s1, s2, s3, clk, reset); 		-- Why is this adder so weird.
		b_is_zero <= (AND (std_logic_vector(unsigned(b)) xnor "00000000")); -- This signal tells datapath that the sampled value of B is zero; thus don't			 report real value of division
		q <= t(7 downto 0); -- The output is connected to the t register

		p0 <= (AND (std_logic_vector(counter) xnor "0111")); -- The predicate is the counter xor 7	(Has to be combinational logic therefore is outside of the process)
		diff <= std_logic_vector(unsigned('0' & ta(14 downto 7)) - unsigned('0' & b));

		process(clk, t0, t1)
		begin
			if rising_edge(clk) then
				if(t0 = '1') then -- We are in the reset state
					ta <= "00000000" & a;
					t <= (others => '0');
					counter <= (others => '0');
				
				elsif (t1 = '1') then -- We are in the LOOP_STATE part OR we just transitioned to DONE_STATE
					with b_is_zero select
						t <= 	t(7 downto 0) & not diff(8) when '0',
								(others => '0') when others;			-- with b = 0, you don't want to change t at all.
					if (diff(8) = '0') then -- divisor < dividend (since carry is RESET)
						ta(15 downto 8) <= diff(7 downto 0);
						ta(7 downto 0) <= ta(6 downto 0) & '0';
					else	-- divisor > dividend
						ta(15 downto 0) <= ta(14 downto 0) & '0';
					end if;
					
					if (counter = 7) then
						counter <= counter;
					else
						counter <= counter + 1;
					end if;
				else -- We are in the done state
					ta <= ta;
					t <= t;
					counter <= counter;
				end if;
			end if;
		end process;
end architecture standard;