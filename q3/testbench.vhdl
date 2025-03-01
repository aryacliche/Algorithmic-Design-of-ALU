library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity testbench is
end entity;

architecture struct of testbench is
	component divider_8bit is
        port (
            clk, reset: in std_logic;
            start: in std_logic; 
            a,b: in std_logic_vector (7 downto 0);
            q:   out std_logic_vector(7 downto 0);
            done: out std_logic);
    end component divider_8bit;

	signal start: std_logic; 
	signal done:  std_logic;
	signal a,b:   std_logic_vector (7 downto 0);
	signal q:     std_logic_vector(7 downto 0);
	signal clk:   std_logic := '0';
	signal reset: std_logic := '1';

	signal error_flag: std_logic := '0';
			
begin
	
	-- clk gen.
	clk <= not clk after 5 ns;

	process
variable I_max : integer := 255;
		variable J_max : integer := 255;
	begin
		wait until clk = '1';
		reset <= '0';

		for I in 0 to I_max loop
			for J in 0 to J_max loop
				a <= std_logic_vector(to_unsigned(I, 8));
				b <= std_logic_vector(to_unsigned(J, 8));
				start <= '1';
				-- wait until clk = '1';	
				wait until clk = '0';
				wait until clk = '1';
				start <= '0';

				while true loop
					wait until clk = '1';
					if (done = '1') then
						exit;
					end if;
				end loop;
				
				if (J = 0) then
					if (to_integer(unsigned(q)) /= 0) then
						error_flag <= '1';
						assert false report "Error with B = 0" severity error;
					end if;
				elsif (to_integer(unsigned(q)) /= integer(floor(real(I)/real(J)))) then	
					error_flag <= '1';
					assert false report "Error at " & integer'image(I) severity error;
				end if;
			end loop;
		end loop;

		-- for the last iteration
		while true loop
			wait until clk = '1';
			if (done = '1') then
				exit;
			end if;
		end loop;

		wait;
	end process;

	dut: divider_8bit port map (start => start, done => done,
				a => a, b => b, q => q,
					clk => clk, reset => reset);

end struct;
