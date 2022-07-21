--Title : Project 1, Multi Cycle Implementation of IITB RISC
--Component: ALU
--Date ; 16/04/2022
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
	library work;
use work.add.all;

entity alu is
    generic(
        operand_width : integer:=16
        );
    port (
        alu_A: in std_logic_vector(operand_width-1 downto 0);
        alu_B: in std_logic_vector(operand_width-1 downto 0);
        sel: in std_logic_vector(1 downto 0);
		  cin: in std_logic;
        cy, z: out std_logic;
		  alu_out: out std_logic_vector(operand_width-1 downto 0)) ;

end entity;

architecture a1 of alu is
    signal adder_output : std_logic_vector(operand_width-1 downto 0);
	 signal temp_output : std_logic_vector(operand_width-1 downto 0);
	 signal C : std_logic_vector(operand_width downto 1);
	 
begin	 
	 
	 ADD0: adder
		generic map(operand_width,4)
		port map (A => alu_A, B => alu_B, cin => cin, S => adder_output, Cout => C);
	
	cy <= C(operand_width);
	
alu_proc	:process(alu_A,alu_B,sel,adder_output)
	begin
		if (sel ="00") then
			temp_output <= adder_output;
		elsif (sel="01") then
			temp_output <= alu_A nand alu_B;
		elsif (sel="10") then
		   temp_output <= alu_A xor alu_B;
		end if;
	end process;
	
	z <= '1' when (to_integer(unsigned(temp_output)) = 0) else '0';
	alu_out <= temp_output;

		
end architecture;

