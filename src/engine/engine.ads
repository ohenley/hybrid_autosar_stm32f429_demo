with Beta_Types;

with STM32.GPIO;   use STM32.GPIO;
with STM32.Timers; use STM32.Timers;
with STM32.Device; use STM32.Device;

with STM32.PWM; use STM32.PWM;

package Engine is
   package BT renames Beta_Types;

   procedure Initialize_PWM_Engine;
   procedure Set_Duty (Duty : STM32.PWM.Percentage);

private

   PWM_Engine : GPIO_Point renames PA6;
   PWM_Output_Timer : Timer renames Timer_3;
   PWM_Output_Engine  : PWM_Modulator;
   PWM_Output_AF : constant STM32.GPIO_Alternate_Function := GPIO_AF_TIM3_2;
   PWM_Frequency : constant := 50;  -- arbitrary

end Engine;
