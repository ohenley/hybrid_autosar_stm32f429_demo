with Ada.Real_Time;

with Interfaces.C; use Interfaces.C;

with STM32.Board;

with Engine;

package body Cyclic_Temp is

   --  procedure init_led;
   --  pragma Import (C, init_led, "init_led");
   
   --  procedure toggle_led_off;
   --  pragma Import (C, toggle_led_off, "toggle_led_off");
   
   --  procedure toggle_led_on;
   --  pragma Import (C, toggle_led_on, "toggle_led_on");

   TC_Max31856 : TM.Thermocouple_Access_T := null;

   protected Temp is
      procedure Set_Update_Frequency (F : MS_T);
      function Get_Update_Frequency return MS_T;
      procedure Set_Temp (T : TM.Thermocouple_Temp_T);
      function Get_Temp return TM.Thermocouple_Temp_T;
   private
      Freq : MS_T                   := 1_000;
      Temp : TM.Thermocouple_Temp_T := 0.0;
   end Temp;

   protected body Temp is
      procedure Set_Update_Frequency (F : MS_T) is
      begin
         Freq := F;
      end Set_Update_Frequency;
      function Get_Update_Frequency return MS_T is
      begin
         return Freq;
      end Get_Update_Frequency;
      procedure Set_Temp (T : TM.Thermocouple_Temp_T) is
      begin
         Temp := T;
      end Set_Temp;
      function Get_Temp return TM.Thermocouple_Temp_T is
      begin
         return Temp;
      end Get_Temp;
   end Temp;

   task Retrive_Temp;

   task body Retrive_Temp is
      use Ada.Real_Time;
      use TM;
      Period : constant Time_Span := Milliseconds (Temp.Get_Update_Frequency);
      Next_Release : Time;
   begin

      Engine.Initialize_PWM_Engine;
      
      --init_led;
      --toggle_led_on;

      while TC_Max31856 = null loop
         delay 0.1;
      end loop;

      TM.Set_Thermocouple_Type (TC_Max31856.all, TM.K);
      Next_Release := Clock + Period;
      loop
         delay until Next_Release;
         Next_Release := Next_Release + Period;

         if TM.Get_One_Shot_Mode (TC_Max31856.all) = No then
            Temp.Set_Temp (TM.Retrieve_Thermocouple_Temp (TC_Max31856.all));
            TM.Set_One_Shot_Mode (TC_Max31856.all);
         end if;
      end loop;
   end Retrive_Temp;

   procedure Set_Update_Frequency (Freq : MS_T) is
   begin
      Temp.Set_Update_Frequency (F => Freq);
   end Set_Update_Frequency;

   function Get_Thermocouple_Temp return TM.Thermocouple_Temp_T is
   begin
      return Temp.Get_Temp;
   end Get_Thermocouple_Temp;

   procedure Create_Cycle (TC : TM.Thermocouple_Access_T; Freq : MS_T) is
   begin
      TC_Max31856 := TC;
      Set_Update_Frequency (Freq);
   end Create_Cycle;
end Cyclic_Temp;
