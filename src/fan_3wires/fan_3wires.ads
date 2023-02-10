with Beta_Types;

with STM32.GPIO;   use STM32.GPIO;
with STM32.Timers; use STM32.Timers;
with STM32.Device; use STM32.Device;

package Fan_3wires is

   package BT renames Beta_Types;

   procedure Initialize;
   procedure Initialize_Encoder;

   function Get_Fan_Encoder_Freq return BT.UInt32;
   procedure Save_Timer_Count;

private
   Encoder_Tach  : constant GPIO_Point                    :=  PA5; -- PB3;
   Encoder_Timer : Timer renames Timer_2;
   Encoder_AF    : constant STM32.GPIO_Alternate_Function := GPIO_AF_TIM2_1;

end Fan_3wires;
