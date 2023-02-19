package body Engine is

   use BT;

   procedure Initialize_PWM_Engine is
   begin
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
      PWM_Output_Engine.Set_Duty_Cycle (Duty);
   end;

--begin
   --Initialize_PWM_Engine;
end Engine;
