library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity testbench is
	generic(
		INPUT_WIDTH : integer := 4
	);
end entity;

architecture struct of testbench is
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

	signal start: std_logic; 
	signal done:  std_logic;
	signal a,b:   std_logic_vector (INPUT_WIDTH - 1 downto 0);
	signal p:     std_logic_vector(2 * INPUT_WIDTH - 1 downto 0);
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

	for I in 0 to (2**INPUT_WIDTH - 1) loop
			a <= std_logic_vector(to_unsigned(I, INPUT_WIDTH));
			for J in 0 to (2**INPUT_WIDTH - 1) loop
				b <= std_logic_vector(to_unsigned(J, INPUT_WIDTH));
				wait until clk = '1';
				start <= '1';
				wait until clk = '0';
				wait until clk = '1';
				start <= '0';

				while true loop
					wait until clk = '1';
					if (done = '1') then
						exit;
					end if;
				end loop;

				if (to_integer (unsigned(p)) /= (I * J)) then
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

	dut: multiplier 	
		generic map (INPUT_WIDTH => INPUT_WIDTH)
		port map (start => start, done => done,
				a => a, b => b, p => p,
					clk => clk, reset => reset);

end struct;
