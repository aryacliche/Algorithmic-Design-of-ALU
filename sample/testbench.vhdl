library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity testbench is
	generic (
		INPUT_WIDTH: integer := 8
	);
end entity;


architecture struct of testbench is
	component Add2 is 
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

	signal start: std_logic; 
	signal done:  std_logic;
	signal A,B:   std_logic_vector (INPUT_WIDTH - 1 downto 0);
	signal C:     std_logic_vector(INPUT_WIDTH downto 0);
	signal clk:   std_logic := '0';
	signal reset: std_logic := '1';

	signal error_flag: std_logic := '0';
			
begin
	
	-- clk gen.
	clk <= not clk after 5 ns;

	process
	begin
		wait until clk = '1';
		reset <= '0';

		for I in 0 to 2**INPUT_WIDTH - 1 loop
			A <= std_logic_vector(to_unsigned(I, INPUT_WIDTH));
			for J in 0 to 2**INPUT_WIDTH - 1 loop
				B <= std_logic_vector(to_unsigned(J, INPUT_WIDTH));
				wait until clk = '1';
				start <= '1';

				while true loop
					wait until clk = '1';
					if (done = '1') then
						exit;
					end if;
				end loop;

				if (to_integer (unsigned(C)) /= (I + J)) then
					error_flag <= '1';
					assert false report "Error" severity error;
				end if;
			end loop;
		end loop;
	
		if(error_flag = '0') then
			assert false report "Success." severity note;
		else 
			assert false report "Failure." severity note;
		end if;	

		wait;
	end process;

	dut: Add2 
			generic map (INPUT_WIDTH => 8)
			port map (start => start, done => done,
				A => A, B => B, C => C,
					clk => clk, reset => reset);

end struct;


