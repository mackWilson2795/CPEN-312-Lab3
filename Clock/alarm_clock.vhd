LIBRARY ieee;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.STD_LOGIC_ARITH.all;
USE IEEE.STD_LOGIC_UNSIGNED.all;

ENTITY BCDCOUNT IS
	port(
	KEY0, KEY1, KEY2, CLK_50, AM_PM_TOGGLE, ALARM_TOGGLE :IN STD_LOGIC;
	SET_MSD :IN STD_LOGIC_VECTOR (2 downto 0);
	SET_LSD :IN STD_LOGIC_VECTOR (3 downto 0);
	ALARM, ALARM_AM_PM :OUT STD_LOGIC;
	AM_PM, AM_PM_OUT_FLAG :OUT STD_LOGIC;
	AM_PM_READ, KEY4, CLK_ON, SET :IN STD_LOGIC;
	MSD, LSD :OUT STD_LOGIC_VECTOR (0 to 6);
	M_MSD, M_LSD :OUT STD_LOGIC_VECTOR (0 to 6);
	H_MSD, H_LSD :OUT STD_LOGIC_VECTOR (0 to 6)
	);
END BCDCOUNT;

ARCHITECTURE a of BCDCOUNT is
		SIGNAL ClkFlag: STD_LOGIC;
		SIGNAL AM_PM_VAL, AM_PM_FLAG, Alarm_AM_PM_Flag: STD_LOGIC := '0';
		SIGNAL Internal_Count: STD_LOGIC_VECTOR(28 downto 0);
		SIGNAL HighDigit, LowDigit: STD_LOGIC_VECTOR(3 downto 0);
		SIGNAL M_LowDigit: STD_LOGIC_VECTOR(3 downto 0):= "1001";
		SIGNAL M_HighDigit: STD_LOGIC_VECTOR(3 downto 0) := "0101";
		SIGNAL H_LowDigit: STD_LOGIC_VECTOR(3 downto 0) := "0001";
		SIGNAL H_HighDigit: STD_LOGIC_VECTOR(3 downto 0) := "0001";
		SIGNAL MSD_7SEG, LSD_7SEG: STD_LOGIC_VECTOR(0 to 6);
		SIGNAL M_MSD_7SEG, M_LSD_7SEG: STD_LOGIC_VECTOR(0 to 6);
		SIGNAL H_MSD_7SEG, H_LSD_7SEG: STD_LOGIC_VECTOR(0 to 6);
		SIGNAL AlarmHourMSD: STD_LOGIC_VECTOR(3 downto 0) := "0001";
		SIGNAL AlarmHourLSD: STD_LOGIC_VECTOR(3 downto 0) := "0010";
		SIGNAL AlarmMinMSD, AlarmMinLSD: STD_LOGIC_VECTOR(3 downto 0) := "0000";
		
	BEGIN
		LSD<=LSD_7SEG;
		MSD<=MSD_7SEG;
		AM_PM_OUT_FLAG<=AM_PM_FLAG;
		AM_PM<=AM_PM_VAL;
		ALARM_AM_PM<=ALARM_AM_PM_FLAG;
		M_LSD<=M_LSD_7SEG;
		M_MSD<=M_MSD_7SEG;
		H_LSD<=H_LSD_7SEG;
		H_MSD<=H_MSD_7SEG;
	
	-- Clock Divider/Counter --
	PROCESS(CLK_50)
	BEGIN
		if(CLK_50'event and CLK_50='1') then
			-- 25000000 gives real time --
			if Internal_Count<25000000 then
				Internal_Count<=Internal_Count+1;
			else
				Internal_Count<=(others => '0');
				ClkFlag<=not ClkFlag;
			end if;
		end if;
	END PROCESS;
	
	-- Toggle Alarm AM/PM --
	PROCESS(AM_PM_TOGGLE)
	BEGIN
		if(AM_PM_TOGGLE'event and AM_PM_TOGGLE='0' and SET='1') then
			Alarm_AM_PM_FLAG<=not Alarm_AM_PM_FLAG;
		end if;
	END PROCESS;

	-- Toggle Clock AM/PM --
	PROCESS(AM_PM_TOGGLE)
	BEGIN
		if(AM_PM_TOGGLE'event and AM_PM_TOGGLE='0' and SET='0') then
			AM_PM_FLAG<=not AM_PM_FLAG;
		end if;			
	END PROCESS;
	
	-- Main Clock Control --
	PROCESS(ClkFlag, KEY0, KEY1, KEY2)
	BEGIN
		if (KEY4='0') then
			HighDigit<="0101";
			LowDigit<="1001";
			M_LowDigit<="1001";
			M_HighDigit<="0101";
			H_LowDigit<="0001";
			H_HighDigit<="0001";
			AlarmMinLSD<="0000";
			AlarmMinMSD<="0000";
			AlarmHourLSD<="0010";
			AlarmHourMSD<="0001";
		elsif (CLK_ON='0') then
			if(KEY0='0') then -- set seconds
				if(SET='0') then
					LowDigit<=SET_LSD;
					HighDigit<='0' & SET_MSD;
				end if;
			elsif(KEY1='0') then -- set minutes
				if(SET='0') then
					M_LowDigit<=SET_LSD;
					M_HighDigit<='0' & SET_MSD;
				else
					AlarmMinLSD<=SET_LSD;
					AlarmMinMSD<='0' & SET_MSD;
				end if;
			elsif(KEY2='0') then -- set hours
				if(SET='0') then
					H_LowDigit<=SET_LSD;
					H_HighDigit<='0' & SET_MSD;
				else
					AlarmHourLSD<=SET_LSD;
					AlarmHourMSD<='0' & SET_MSD;
				end if;
			end if;
		elsif(ClkFlag'event and ClkFlag='1') then
			if (LowDigit=9) then
				LowDigit<="0000";
				if (HighDigit=5) then
					HighDigit<="0000";
						
					-- Minute Clock --					
					if (M_LowDigit=9) then
						M_LowDigit<="0000";
						if (M_HighDigit=5) then
							M_HighDigit<="0000";
							
							-- Hour Clock --
							if (H_HighDigit=1) then
								if (H_LowDigit=2) then
									H_HighDigit<="0000";
									H_LowDigit<="0001";
								else
									if (H_LowDigit=1) then 
											-- 11:59:59 => AM<->PM --
											AM_PM_VAL<= not AM_PM_VAL;
									end if;
									H_LowDigit<=H_LowDigit+'1';
								end if;
							elsif (H_LowDigit=9) then
									H_HighDigit<=H_HighDigit+'1';
									H_LowDigit<="0000";
							else
								H_LowDigit<=H_LowDigit+'1';
							end if;
							-- End Hour Clock --
						
						else M_HighDigit<=M_HighDigit+'1';
						end if;
					else
						M_LowDigit<=M_LowDigit+'1';
					end if;
					-- End Minute Clock --
						
				else HighDigit<=HighDigit+'1';
				end if;
			else
				LowDigit<=LowDigit+'1';
			end if;
		end if;	
	END PROCESS;
	
	-- Handle Alarm --
	PROCESS(M_LowDigit, AlarmMinLSD, AlarmMinMSD, AlarmHourLSD, AlarmHourMSD)
	BEGIN
		if (ALARM_TOGGLE='1' and AlarmHourMSD = H_HighDigit and AlarmHourLSD = H_LowDigit
									and AlarmMinMSD = M_HighDigit and AlarmMinLSD = M_LowDigit
									and AM_PM_READ = Alarm_AM_PM_FLAG) then
			ALARM<='1';
		else
			ALARM<='0';
		end if;
	END PROCESS;

	
	-- Display clock values to 7 segs --
	PROCESS(LowDigit, HighDigit, M_LowDigit, M_HighDigit, H_LowDigit, H_HighDigit)
	BEGIN
		-- Seconds --
		case LowDigit is
			when "0000" => LSD_7SEG <= "0000001";
			when "0001" => LSD_7SEG <= "1001111";
			when "0010" => LSD_7SEG <= "0010010";
			when "0011" => LSD_7SEG <= "0000110";
			when "0100" => LSD_7SEG <= "1001100";
			when "0101" => LSD_7SEG <= "0100100";
			when "0110" => LSD_7SEG <= "0100000";
			when "0111" => LSD_7SEG <= "0001111";
			when "1000" => LSD_7SEG <= "0000000";
			when "1001" => LSD_7SEG <= "0000100";
			when others => LSD_7SEG <= "1111111";
		end case;
		case HighDigit is
			when "0000" => MSD_7SEG <= "0000001";
			when "0001" => MSD_7SEG <= "1001111";
			when "0010" => MSD_7SEG <= "0010010";
			when "0011" => MSD_7SEG <= "0000110";
			when "0100" => MSD_7SEG <= "1001100";
			when "0101" => MSD_7SEG <= "0100100";
			when "0110" => MSD_7SEG <= "0100000";
			when "0111" => MSD_7SEG <= "0001111";
			when "1000" => MSD_7SEG <= "0000000";
			when "1001" => MSD_7SEG <= "0000100";
			when others => MSD_7SEG <= "1111111";
		end case;
		
		-- Minutes --
		case M_LowDigit is
			when "0000" => M_LSD_7SEG <= "0000001";
			when "0001" => M_LSD_7SEG <= "1001111";
			when "0010" => M_LSD_7SEG <= "0010010";
			when "0011" => M_LSD_7SEG <= "0000110";
			when "0100" => M_LSD_7SEG <= "1001100";
			when "0101" => M_LSD_7SEG <= "0100100";
			when "0110" => M_LSD_7SEG <= "0100000";
			when "0111" => M_LSD_7SEG <= "0001111";
			when "1000" => M_LSD_7SEG <= "0000000";
			when "1001" => M_LSD_7SEG <= "0000100";
			when others => M_LSD_7SEG <= "1111111";
		end case;
		case M_HighDigit is
			when "0000" => M_MSD_7SEG <= "0000001";
			when "0001" => M_MSD_7SEG <= "1001111";
			when "0010" => M_MSD_7SEG <= "0010010";
			when "0011" => M_MSD_7SEG <= "0000110";
			when "0100" => M_MSD_7SEG <= "1001100";
			when "0101" => M_MSD_7SEG <= "0100100";
			when "0110" => M_MSD_7SEG <= "0100000";
			when "0111" => M_MSD_7SEG <= "0001111";
			when "1000" => M_MSD_7SEG <= "0000000";
			when "1001" => M_MSD_7SEG <= "0000100";
			when others => M_MSD_7SEG <= "1111111";
		end case;
		
		-- Hours --
		case H_LowDigit is
			when "0000" => H_LSD_7SEG <= "0000001";
			when "0001" => H_LSD_7SEG <= "1001111";
			when "0010" => H_LSD_7SEG <= "0010010";
			when "0011" => H_LSD_7SEG <= "0000110";
			when "0100" => H_LSD_7SEG <= "1001100";
			when "0101" => H_LSD_7SEG <= "0100100";
			when "0110" => H_LSD_7SEG <= "0100000";
			when "0111" => H_LSD_7SEG <= "0001111";
			when "1000" => H_LSD_7SEG <= "0000000";
			when "1001" => H_LSD_7SEG <= "0000100";
			when others => H_LSD_7SEG <= "1111111";
		end case;
		-- Hour High Digit only needs 0, 1, 2 --
		case H_HighDigit is
			when "0000" => H_MSD_7SEG <= "0000001";
			when "0001" => H_MSD_7SEG <= "1001111";
			when "0010" => H_MSD_7SEG <= "0010010";
			when others => H_MSD_7SEG <= "1111111";
		end case;
	END PROCESS;	
end a;