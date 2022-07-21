library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

library work;
use work.basic.all;
use work.add.all;

entity datapath is
	port(
	op_code: out std_logic_vector(3 downto 0);
	condition: out std_logic_vector(1 downto 0);
	clk, reset: in std_logic;
	T: in std_logic_vector(36 downto 0);
	S: out std_logic_vector(5 downto 0);
	P0: out std_logic_vector(15 downto 0));
end entity;
	
architecture rtl of datapath is

	component sign_extender is
		generic(input_width: integer := 6;
			output_width: integer := 16);
		port(
			input: in std_logic_vector(input_width-1 downto 0);
			output: out std_logic_vector(output_width-1 downto 0));
	end component;

	component register_file is
		generic(
			operand_width: integer := 16;
			num_reg: integer := 8);
			
		port(
			data_in: in std_logic_vector(operand_width-1 downto 0);
			data_out1, data_out2, R7, R0: out std_logic_vector(operand_width-1 downto 0);
			sel_in, sel_out1, sel_out2: in std_logic_vector(2 downto 0);
			clk, wr_ena, reset: in std_logic);
			
	end component;

	component ls_multiple is
		generic(input_width: integer := 8);
		port(
			input: in std_logic_vector(input_width-1 downto 0);
			ena, clk, set_zero, reset: in std_logic;
			valid, invalid_next: out std_logic;
			address: out std_logic_vector(2 downto 0));
	end component;

	component alu is
    generic(
        operand_width : integer:=16
        );
    port (
        alu_A: in std_logic_vector(operand_width-1 downto 0);
        alu_B: in std_logic_vector(operand_width-1 downto 0);
         cin: in std_logic;
			sel : in std_logic_vector(1 downto 0);
        cy, z: out std_logic;
		  alu_out: out std_logic_vector(operand_width-1 downto 0)) ;
	end component;
			
	component ram
		PORT
		(
			aclr		: IN STD_LOGIC  := '0';
			address	: IN STD_LOGIC_VECTOR (14 DOWNTO 0);
			clock		: IN STD_LOGIC  := '1';
			data		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
			wren		: IN STD_LOGIC ;
			q			: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
		);
	end component;

	component shifter_1bit is
		generic(operand_width: integer := 16);
		port(
			input: in std_logic_vector(operand_width-1 downto 0);
         output: out std_logic_vector(operand_width-1 downto 0));
	end component;
	
	signal I, D1, D2, D3, SEs, SEl, LS, ALU_A, ALU_B, ALU_S, T1, T2,T3, shifter: std_logic_vector(15 downto 0) := (others => '0');
	signal A_IM, A_DM, DO_IM, DO_DM, DI_DM, T3_IN, E1, E2, PC, PC_IN, R7, R0: std_logic_vector(15 downto 0) := (others => '0');
	signal A1, A2, A3, A3_int: std_logic_vector(2 downto 0) := (others => '0');
	signal CY, OV, Z: std_logic_vector(0 downto 0) := (others => '0');
	signal carry_ena, zero_ena, b_ena, temp, wren, pc_ena, ena_boot: std_logic;
	signal alu_op: std_logic_vector(1 downto 0);
	signal PE: std_logic_vector(2 downto 0);

begin

	
	--Instruction Register
	instruction_register: my_reg
		generic map(16)
		port map(clk => clk, clr => reset, Din => DO_IM, Dout => I, ena => T(23));
	
	--Register File
	rf: register_file
		port map(clk => clk, reset => reset, wr_ena => T(32), data_in => D3, R7 => R7, R0 => R0,
			data_out1 => D1, data_out2 => D2, sel_in => A3, sel_out1 => A1, sel_out2 => A2);
	
	--Priority Encoder Block
	pe_block: ls_multiple
		port map( input => I(7 downto 0), ena => T(33), clk => clk, set_zero => T(34),
			reset => reset, invalid_next => S(0), address => PE);
			
	--Sign Extend 6 to 16(SE10)
	sign_extend_1: sign_extender
		generic map(6,16)
		port map(input => I(5 downto 0), output => SEl);
		
	--Sign Extend 9 to 16(SE7)
	sign_extend_2: sign_extender
		generic map(9,16)
		port map(input => I(8 downto 0), output => SEs);
		
	--Arithmetic Logic Unit
	alu_instance: alu
		port map(alu_A => ALU_A, alu_B => ALU_B, alu_out => ALU_S, cin => '0',
			sel => alu_op, cy => CY(0), z => Z(0));

	--1 bit shifter
	shifter_onebit: shifter_1bit
		generic map(16)
		port map(input => T2, output => shifter);
			
	--Memory
	mem: ram
		port map(q => DO_DM, data => DI_DM, address => A_DM(14 downto 0), wren => wren,
			aclr => reset, clock => clk);
		
	--Temporary Register 3
	T3_Reg: my_reg
		generic map(16)
		port map(Din => T3_IN, Dout => T3, ena => T(26), clk => clk, clr => reset);
		
	--Temporary Register 2
	T2_reg: my_reg
		generic map(16)
		port map(Din => D2, Dout => T2, ena => T(29), clr => reset, clk => clk);
		
	--Temporary Register 1
	T1_reg: my_reg
		generic map(16)
		port map(Din => D1, Dout => T1, ena => T(24), clr => reset, clk => clk);
		
	--Condtion Code Register: Carry
	Carry_CCR: my_reg
		generic map(1)
		port map(Din => CY, Dout => S(1 downto 1), ena => carry_ena, clr => reset, clk => clk);
		
	--Condition Code Register: Zero	
	Zero_CCR: my_reg
		generic map(1)
		port map(Din => Z, Dout => S(2 downto 2), ena => zero_ena, clr => reset, clk => clk);
				
	--Register PC
	PC_reg: my_reg
		generic map(16)
		port map(Din => PC_IN, Dout => PC, ena => pc_ena, clr => reset, clk => clk);
		
		
		
	--PC Enable
	pc_ena <= temp or T(30);
	--Carry Enable
	carry_ena <= '1' when ((I(15 downto 13) = "000") and (T(35) = '1')) else '0';
	--Zero Enable
	zero_ena <= '1' when (((I(15 downto 14) = "00") and ((I(13) and I(12)) = '0') and (T(35) = '1')) or I(15 downto 12) = "0111") else '0';
	
	--ALU Operation 
	alu_op <= "01" when (I(15 downto 12) = "0010") else
					"10" when (I(15 downto 12) = "1000") else
					"00";
	
	--Temporary Signal
	temp <= (A3(2) and A3(1) and A3(0) and T(2));
	
	--Left Shifter Input
	
	LS <= I(8 downto 0) & "0000000" when (I(15) = '0') else
		"0000000" & I(8 downto 0);
	
	--Equality Check
	S(4) <= '1' when (D1 = D2) else '0';
	
	--Address In 1 of Register File
	A1 <= I(11 downto 9);
		
	--Address In 2 of Register File
	A2 <= PE when (T(3) = '0') else
		I(8 downto 6);
	
	--Address In 3 of Register File
	A3_int <= PE when (T(6 downto 4) = "000") else
		I(11 downto 9) when (T(6 downto 4) = "001") else
		I(8 downto 6) when (T(6 downto 4) = "010") else
		I(5 downto 3) when (T(6 downto 4) = "011") else
		"111";
	
	--Data In of Register File
	D3 <= PC when (T(8 downto 7) = "00") else
		T3 when (T(8 downto 7) = "10") else
		LS when (T(8 downto 7) = "01");

	--Workaround to accomodate ADI write to REGB	
	A3 <= I(8 downto 6) when ((I(15 downto 12) = "0001") and (T(6 downto 4) = "011")) else A3_int;

	--Input 2 of ALU
	ALU_B <= SEl when (T(15 downto 13)) = "000" else
	        SEs when (T(15 downto 13)) = "001" else
		std_logic_vector(to_unsigned(1,16)) when (T(15 downto 13) = "100") else
		T2 when (T(15 downto 13) = "010") else
		shifter
		;
	
	--Input 1 of ALU
	ALU_A <= SEl when (T(12 downto 11)) = "00" else
		T1 when (T(12 downto 11) = "10") else
		R7;
    
	--Input of Temporary Register 1
	T3_IN <= ALU_S when (T(28 downto 27) = "01") else
				D2 when (T(28 downto 27) = "10") else
				DO_DM;
				
		
	PC_IN <= T2 when ((T(31)='1')) else
		ALU_S;
		
	
	
		
	--Send Operation Code to the control path
	op_code <= I(15 downto 12) when (T(24) = '0') else
		DO_IM(15 downto 12);
	--Send the Conditional Execution Data to control path
	condition <= I(1 downto 0);
	DO_IM <= DO_DM;
	P0 <= R0;
 
-- Transfer Signal Mapping--
	--
	-- T(0)		: A1 enable
	--
	-- T(1)		: a2 Enable
	-- T(2)		: d3 Enable
	-- T(3)		:: A2 Input Select
	--			1 	- I(8-6)
	--			0	- PE
	-- T(6:4)		: A3 Input Select
	--		000 - pe_out
	--		001 - I(11-9)
	--		010 - I(8-6)
	--		011 - I(5-3)
	--		100- "111"
	-- T(8:7)		: D3 Input Select
	--		00 - PC
	--		10 - T3
	--		01 - LS
	-- T(9)		: ALU_A Enable
	-- t(10): ALU_B Enable
	-- T(12:11)		: ALU_A Input Select
	--				00	- SE(6-16)
	--				10	- T1
	--				01	- R7
	-- T(15:13)		: ALU_B Input Select
	--				000 - SE(6-16)
	--				010 - T2
	--				011 - SHIFTER
	--				100 - 1
	--				001 - SE(9-16)
	-- T(17:16)	: ALU select
					--00-add
					--01-nand
					--10-xor
	-- T(18)	: memA enable
	-- T(19) : memD(in) enable
	-- T(21:20)	: mem a input select
						--00-T3
						--01-T1
						--10-R7
	-- T(22)	: mem d(in) input selct
					--0-T3
					--1-T2
	--
	-- T(23)	: IR ENABLE 
	
	-- T(24)	: T1 ENABLE
	--T(25) : T1 input selct
				--0-ALU OUT
				--1- RFD1
	--
	-- T(26)	: T3 ENABLE
	--
	-- T(28:27)	: T3 Input Select
			--01 - ALU Output
			--10 - D2
			--00-MEM D
			
	--T(29) : T2 ENABLE
	--T(30) : PC ENABLE
	--T(31) : PC INPUT SELECT
			--0-ALU OUT
			--1-T2
	--T(32): RF WRITE ENABLE A3
	-- T(33)		: LS_Multiple Write Enable
	-- T(34)		: LS_Multiple Set-Zero
	-- T(35)		: FLAG SET

	--T(36)	: Op_Code Forwarding
	--		1 - Forwarded
	--		0 - From IR
	
	-- Predicate Signal Mapping--
	--
	-- S(0)	: InValid_Next Signal from ls_multiple
	-- S(1)	: Carry
	-- S(2)	: Zero
	-- S(3)	: Bit B
	-- S(4)	: Equality
	-- S(5)	: Overflow
	
	--Instruction Memory
	--ins_mem: rom
	--	port map(q => DO_IM, address => A_IM, clock => clk, aclr => reset);
	
end architecture;