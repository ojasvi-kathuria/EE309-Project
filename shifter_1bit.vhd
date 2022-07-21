--Title- Project 1, Multi cycle implementation IITB RISC
--component- left shifter
--date- 28/04/2022

library ieee;
use ieee.numeric_std.all;
use ieee.math_real.all;
use ieee.std_logic_1164.all;

entity shifter_1bit is
	generic(operand_width: integer := 16);
	port(
		input: in std_logic_vector(operand_width-1 downto 0);
		output: out std_logic_vector(operand_width-1 downto 0)
	 );
end entity;

architecture behave of shifter_1bit is
	
begin

	output(15 downto 0) <= input(14 downto 0) & '0';
	
end architecture;