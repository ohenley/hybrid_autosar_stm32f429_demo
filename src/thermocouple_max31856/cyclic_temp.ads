with Thermocouple_Max31856;

package Cyclic_Temp is

   package TM renames Thermocouple_Max31856;

   subtype MS_T is Integer range 0 .. 1_000;

   procedure Create_Cycle (TC : TM.Thermocouple_Access_T; Freq : MS_T);

   procedure Set_Update_Frequency (Freq : MS_T);
   function Get_Thermocouple_Temp return TM.Thermocouple_Temp_T;
end Cyclic_Temp;
