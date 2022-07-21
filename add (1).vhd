--  Title : Project 1, Multi Cycle Implementation of IITB RISC
--  Component: adder
--  Date ; 16/04/2022


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package add is
	component full_adder is
		port(
			a, b, cin: in std_logic;
			s, p, g: out std_logic);
	end component;
	
	component carry_generate is
		generic(grp_width: integer := 4);
		port(
			P, G: in std_logic_vector(grp_width-1 downto 0);
			cin: in std_logic;
			Cout: out std_logic_vector(grp_width-1 downto 0));
	end component;
	
	component adder is
		generic(
			operand_width: integer := 16;
			grp_width: integer := 4);	--This better be a factor of operand_width
		port(
			A, B: in std_logic_vector(operand_width-1 downto 0);
			S: out std_logic_vector(operand_width-1 downto 0);
			cin: in std_logic;
			Cout: out std_logic_vector(operand_width-1 downto 0));
	end component;

end package;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity full_adder is
	port(
		a, b, cin: in std_logic;
		s, p, g: out std_logic);
end entity;

architecture basic of full_adder is
begin
	
	g <= a and b;
	p <= a or b;
	s <= a xor b xor cin;
	
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity carry_generate is
	generic(grp_width: integer := 4);-- a factor of operand_width
	port(
		P, G: in std_logic_vector(grp_width-1 downto 0);
		cin: in std_logic;
		Cout: out std_logic_vector(grp_width-1 downto 0));
end entity;

architecture basic of carry_generate is
	signal C: std_logic_vector(grp_width downto 0);
begin
	
	C(0) <= cin;
	logic:
	for i in 1 to grp_width generate
		C(i) <= G(i-1) or (P(i-1) and C(i-1)); 
	end generate;

	Cout <= C(grp_width downto 1);
end architecture;


library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;

library work;
use work.add.all;

entity adder is
	generic(
		operand_width: integer := 16;
		grp_width: integer := 4);	
	port(
		A, B: in std_logic_vector(operand_width-1 downto 0);
		S: out std_logic_vector(operand_width-1 downto 0);
		cin: in std_logic;
		Cout: out std_logic_vector(operand_width-1 downto 0));
end entity;

architecture look_ahead of adder is
	signal C: std_logic_vector(operand_width downto 0);
	signal P, G: std_logic_vector(operand_width-1 downto 0);
begin

	C(0) <= cin;
	
	adder_element:
	for i in 0 to operand_width-1 generate
		ADDX: full_adder
			port map(a => A(i), b => B(i), cin => C(i),
				s => S(i), p => P(i), g => G(i));
	end generate;
	
	carry_element:
	for i in 0 to (operand_width/grp_width)-1 generate
		CARRYX: carry_generate
			generic map(grp_width)
			port map(P => P((i+1)*grp_width-1 downto i*grp_width),
				G => G((i+1)*grp_width-1 downto i*grp_width),
				cin => C(i*grp_width), Cout => C((i+1)*grp_width downto i*grp_width+1));
	end generate;
	
	Cout <= C(operand_width downto 1);
	
end architecture;
