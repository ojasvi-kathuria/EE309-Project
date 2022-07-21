--Title- Project 1, Multi cycle implementation IITB RISC
--component- sign extender
--date- 16/04/2022


library ieee;
use ieee.std_logic_1164.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity sign_extender is
    generic(
        input_width : integer:=6;
        output_width : integer:=16
        );
    port (
        input: in std_logic_vector(input_width-1 downto 0);
        output: out std_logic_vector(output_width-1 downto 0)
    ) ;
end sign_extender;

architecture a1 of sign_extender is
    

begin
	output(input_width-1 downto 0) <= input(input_width-1 downto 0);
   
	extend:
	for i in input_width to output_width-1 generate
		output(i) <= input(input_width-1);
	end generate;
	
	
end a1 ; 
