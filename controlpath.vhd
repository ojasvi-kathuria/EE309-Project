library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity control_path is
	port(
		reset, clk: in std_logic; 
		op_code: in std_logic_vector(3 downto 0);
		condition: in std_logic_vector(1 downto 0);
		T: out std_logic_vector(36 downto 0);
		C, OV, Z, invalid_next, eq: in std_logic);
end entity;

architecture fsm of control_path is
	type fsm_state is (S0,S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14, S15, S16, S17, S18, S19, S20, S21, S22, S23);
	signal Q, nQ: fsm_state := S0;
begin

	clocked:
	process(clk, nQ)
	begin
		if (clk'event and clk = '1') then
			Q <= nQ;
		end if;
	end process;
	
	outputs:
	process(op_code, Q)
	begin
		T <= (others => '0');
		case Q is
		   when S0 => 
				T <= (others => '0');
			when S1 =>
				T(15 downto 13) <= "100";	--ALU_B = 1
				T(12 downto 11) <= "01"; 	--ALU_A = R7
				T(31) <= '0';					--Send ALU Output to PC
				T(30) <= '1';					--Enable PC Register
				T(23) <= '1';					--Instruction Register Enable
				T(36) <= '1';					--Fetch OpCode from Memory Output
				
			when S2 =>
				T(0) <= '1';					--A1= 11-9
				T(29) <= '1';					--enable t2
				T(25) <= '1';					--Put D1 in T1
				T(24) <= '1';					--Enable T1
				T(3) <= '1';					--A2 = I(8-6)
				
			when S3 =>
			T(9) <= '1'; --ALUA ENABLED
				T(12 downto 11) <= "10";	--ALU_A = T1
				T(10) <= '1'; --ALUB ENABLED
				T(15 downto 13) <= "010";	--ALU_B = T2
				T(26) <= '1';					--Enable T3
				T(28 downto 27) <= "01";	--t3=alu_out
				T(36) <= '1';					--Set Flags according to the Instruction
				
			when S4 =>
				T(32) <= '1';
				T(6 downto 4) <= "011";	--a3=I(3-5)
				T(8 downto 7) <= "10";	--D3 = T3
				T(2) <= '1';	
				
			when S5 =>
				T(8 downto 7) <= "00";	--D3 = PC
				T(6 downto 4) <= "100";	--A3 = "111"
				T(2) <= '1';	
				T(32) <= '1';
				
			when S6 =>
				T(9) <='1';
				T(10) <='1';
				T(26) <='1';
				T(12 downto 11) <= "10";	--ALU_A = T1
				T(15 downto 13) <= "011";	--ALU_B = shifter
				T(2) <= '1';					--Enable Register Write
				T(28 downto 27) <= "01";	--T3= ALU OUT
				
			when S7 =>
				T(9) <='1';
				T(10) <='1';
				T(12 downto 11) <= "10";	--ALU_A = T1
				T(15 downto 13) <= "000";	--ALU_B = SE(6-16)
				T(26) <= '1';					--Enable T3
				T(28 downto 27) <= "01";	--T3= ALU OUT
				
			when S8 =>
				T(2) <= '1';	
				T(8 downto 7) <= "10";	--D3 = T3
				T(6 downto 4) <= "010";	--A3 = I(8-6)
				T(32) <= '1';					
			
			when S9 =>
				T(8 downto 7) <= "01";	--D3 = LS
				T(6 downto 4) <= "001";	--A3 = I(9-11)
				T(2) <= '1';					
				T(32) <= '1';
				
			when S10 =>
				T(10) <= '1';
				T(9) <= '1';
				T(26) <= '1';
				T(15 downto 13) <= "010";	--ALU_B = T2
				T(12 downto 11) <= "00";	--ALU_A = sE10
				T(28 downto 27) <= "01";	--T3 = ALU_out
				
			when S11 =>
				T(18) <= '1';					--mem a enable
				T(21 downto 20) <= "00";	--memA = T3
				T(26) <= '1';
				T(28 downto 27) <= "00";	--T3 = memD
				
				
				
			when S12 =>
				T(8 downto 7) <= "10";	--d3 = T3
				T(6 downto 4) <= "001";	--A3= I(11-9)
				T(2) <= '1';	
				T(32) <= '1';	
				
			when S13 =>
				T(18) <= '1';
				T(21 downto 20) <= "00";	--memA = T3
				T(19) <= '1';
				T(22) <= '1'; --memD=t2
				
			when S14 =>
				T(34) <= '1'; --LSMULTIPLE SET ZERO 
				T(18) <= '1';
				T(21 downto 20) <= "01";	--memA = T1
				T(26) <= '1';
				T(28 downto 27) <= "00";	--T3 = memD
				
			when S15 =>
				T(8 downto 7) <= "10";	--D3 = t3
				T(6 downto 4) <= "000";	--A3 = pe_out
				T(2) <= '1';
				T(32) <= '1';--
				
			when S16 =>
				T(9) <= '1';
				T(10) <= '1';
				T(24) <= '1';
				T(12 downto 11) <= "10";	--ALU A = T1
				T(15 downto 13) <= "100";	--ALU B = 1
				T(25) <= '0';					--T1 = ALU_out
				
			when S17 =>
				 T(34) <= '1'; --LSMULTIPLE SET ZERO
			    T(1) <= '1';
				 T(3) <= '0'; --a2=pe
				 T(28 downto 27) <= "10"; --t3=d2
				 T(26) <= '1'; --
				
			when S18 =>
			    T(18) <= '1';
				 T(21 downto 20) <= "01"; --memA= t1
				 T(19) <= '1'; 
				 T(22) <= '0'; --memD= t3
				 
			when S19 =>
				 T(25) <= '1';
				 T(9) <= '1';
				 T(10) <= '1';
				 T(30) <= '1';
			    T(12 downto 11) <= "01"; --aluA=r7
				 T(15 downto 37) <= "000"; --alub= se10
				 T(31) <= '0';-- pc=aluout
				 T(2) <= '1'; --enable register file
				 
			
			when S20 =>
			    T(8 downto 7) <= "00"; --d3=pc
				 T(6 downto 4) <= "001"; --a3= i(9-11)
				 T(2) <= '1'; 
				 T(32) <= '1';
			
		  when S21 =>
		       T(9) <= '1'; 
				 T(10) <= '1'; 
			    T(12 downto 11) <= "01"; --aluA=r7
				 T(15 downto 13) <= "001"; --alu b= se7
				T(30) <= '1';-- pc=enable
				 T(31) <= '0';-- pc=aluout
				 
		  when S22 =>
				 T(9) <= '1';
				 T(10) <= '1';
			    T(12 downto 11) <= "10"; --alua=t1
				 T(15 downto 13) <= "001"; --alu b= se(9-16)
				 T(30) <= '1';-- pc=enable
				 T(31) <= '0';-- pc=aluout
				 
			when S23 =>
				  T(30) <= '1';-- pc enable
				 T(31) <= '1';-- pc=t
				 
				
		end case;
	end process;
	
	
	next_state:
	process(op_code, condition, C, OV, Z, invalid_next, eq, reset, Q)
	begin
		nQ <= Q;
		case Q is
			when S0 => nQ <= S1;	
			when S1 =>
				case op_code is
					when "0000" => nQ <= S9;	
					when "1001" =>	nQ <= S20;
					when others =>	nQ <= S2;
				end case;
			when S2 =>
				case op_code is
					when "0001" =>
						case condition is
							when "00" => nQ <= S3;
							when "10" =>
								if (C = '1') then	nQ <= S3;
								else	nQ <= S5;
							end if;
						when "01" =>
								if (Z = '1') then	nQ <= S3;
								else nQ <= S5;
								end if;
							when "11" =>
								nQ <= S6;
						end case;
					when "0000" => nQ <= S7;
					when "0111"|"0101" =>	nQ <= S10;
					when "1100" =>	nQ <= S14;
					when "1101" => nQ <= S17;
					when "1010" => nQ <= S20;
					when "1000" => nQ <= S3;
					when others => nQ <= S2;	
				end case;
				
			when S3 =>	
				case op_code is
					when "1000" =>
						if (eq = '1') then nQ <= S19;
						else	nQ <= S5;
						end if;
					when others => 	nQ <= S4;
					
				end case;
				
					
			when S4 => 	
				nQ <= S5;
				
			when S5 =>	nQ <= S1;
			when S6 =>	nQ <= S4;
			when S7 => nQ <= S8;
			
			when S8 => nQ <= S5;
			when S9 =>	nQ <= S5;
			when S10 => 
				case op_code is
					when "0111" => nQ <= S11;
					when "0101" => nQ <= S13;
					when others => nQ <= S10;
				end case;
			
			when S11 => nQ <= S12;
			when S12 =>	nQ <= S5;
			when S13 => nQ <= S5;
			when S14 =>	nQ <= S15;
			when S15 => nQ <= S16;
			when S16 => nQ <= S5;
			when S17 => nQ <= S18;
			when S18 => nQ <= S16;
			when S19 => nQ <= S5;
			when S20 => 
				case op_code is
					when "1010" => nQ <= S23;
					when "1001" => nQ <= S21;
					when others => nQ <= S20;
				end case;
			when S21 => nQ <= S5;
			when S22 => nQ <= S5;
			when S23 => nQ <= S5;
		end case;
	end process;
		
end architecture;