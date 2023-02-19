with Beta_Types;

with STM32.GPIO;   use STM32.GPIO;
with STM32.Timers; use STM32.Timers;
with STM32.Device; use STM32.Device;

with STM32.PWM;

package Fan_3wires is

   package BT renames Beta_Types;

   procedure Initialize;
   procedure Initialize_PWM_Fan;
   procedure Set_Duty (Duty : STM32.PWM.Percentage);

   function Get_Fan_Encoder_Freq return BT.UInt32;
   procedure Save_Timer_Count;

private
   Encoder_Tach  : constant GPIO_Point                    :=  PA5;
   Encoder_Timer : Timer renames Timer_2;
   Encoder_AF    : constant STM32.GPIO_Alternate_Function := GPIO_AF_TIM2_1;

   PWM_Fan : GPIO_Point renames PA7;
   PWM_Output_Timer : Timer renames Timer_14;
   PWM_Output_Fan  : STM32.PWM.PWM_Modulator;
   PWM_Output_AF : constant STM32.GPIO_Alternate_Function := GPIO_AF_TIM14_9;
   PWM_Frequency : constant := 24000;  -- arbitrary
end Fan_3wires;
