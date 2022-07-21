--Title- Project 1, Multi cycle implementation IITB RISC
--component- priority encoder
--date- 16/04/2022

library ieee;
use ieee.numeric_std.all;
use ieee.math_real.all;
use ieee.std_logic_1164.all;

entity p_encoder is
	generic(input_width: integer := 8); 
	port(
		input: in std_logic_vector(input_width-1 downto 0);
		output: out std_logic_vector(2 downto 0);
	--integer(ceil(log2(real(input_width))))=4   
		valid: out std_logic);
end entity;

architecture behave_ov of p_encoder is
	signal output_temp: std_logic_vector(2 downto 0);
begin

	main: process(input)
	begin
		output_temp <= (others => '0');
		for i in input_width-1 downto 0 loop
			if input(i) = '1' then
				output_temp <= std_logic_vector(to_unsigned(i,3));
			end if;
		end loop;
	end process;
	
	output <= output_temp;
	valid <= '0' when (to_integer(unsigned(output_temp)) = 0 and input(0) = '0') else '1';
	
end architecture;