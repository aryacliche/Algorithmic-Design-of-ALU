library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity testbench is
	generic(
		INPUT_WIDTH : integer := 8
	);
end entity;

architecture struct of testbench is
	component square_root is
		generic (
			INPUT_WIDTH: integer := 8
		);
		port (
			clk, reset: in std_logic;
			start: in std_logic; 
			x: in std_logic_vector (INPUT_WIDTH - 1 downto 0);
			y: out std_logic_vector(INPUT_WIDTH / 2 - 1 downto 0);
			done: out std_logic);
	end component square_root;

	signal start: std_logic; 
	signal done:  std_logic;
	signal x:   std_logic_vector (INPUT_WIDTH - 1 downto 0);
	signal y:     std_logic_vector(INPUT_WIDTH / 2 - 1 downto 0);
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
			x <= std_logic_vector(to_unsigned(I, INPUT_WIDTH));
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

if (NOT ((to_integer(unsigned('0' & y)) ** 2 <= I) AND (to_integer(unsigned('0' & y) + 1) ** 2 > I))) then
				error_flag <= '1';
				assert false report "Error at " & integer'image(I) severity error;
			end if;
		end loop;
	
		if(error_flag = '0') then
			assert false report "Success." severity note;
		else 
			assert false report "Failure." severity note;
		end if;	

		wait;
	end process;

	dut: square_root	
		generic map (INPUT_WIDTH => INPUT_WIDTH)
		port map (start => start, done => done,
					x => x, y => y,
					clk => clk, reset => reset);

end struct;
