with Interfaces.C;

package body Engine is

   package IC renames Interfaces.C;

   use BT;

   subtype Pwm_Channel_T is IC.unsigned range 1 .. 1;
   subtype Pwm_Period_T is IC.unsigned range 50 .. 40_000;
   subtype Duty_Cycle_T is IC.unsigned range 0 .. 100;

   --  procedure Pwm_Set_Period_And_Duty (Channel_Number : Pwm_Channel_T; 
   --                                     Period : Pwm_Period_T; 
   --                                     Duty_Cycle: Duty_Cycle_T)
   --     with
   --        Import        => True,
   --        Convention    => C,
   --        External_Name => "Pwm_SetPeriodAndDuty";

   --  procedure Pwm_Set_Duty_Cycle (Channel_Number : Pwm_Channel_T;
   --                                Duty_Cycle : Duty_Cycle_T)
   --     with
   --              Import        => True,
   --              Convention    => C,
   --              External_Name => "Pwm_SetPeriodAndDuty";

   procedure Initialize_PWM_Engine is
   begin
      --Pwm_Set_Period_And_Duty (1, 50, 0);
      Configure_PWM_Timer (PWM_Output_Timer'Access, PWM_Frequency);

      PWM_Output_Engine.Attach_PWM_Channel
        (Generator => PWM_Output_Timer'Access,
         Channel   => Channel_1,
         Point     => PWM_Engine,
         PWM_AF    => PWM_Output_AF);
      
      PWM_Output_Engine.Set_Duty_Cycle (0);
      PWM_Output_Engine.Enable_Output;
   end Initialize_PWM_Engine;

   procedure Set_Duty (Duty : STM32.PWM.Percentage) is
   begin
      --Pwm_Set_Duty_Cycle (1, Duty_Cycle_T (Duty));
      PWM_Output_Engine.Set_Duty_Cycle (Duty);
   end;

--begin
   --Initialize_PWM_Engine;
end Engine;
