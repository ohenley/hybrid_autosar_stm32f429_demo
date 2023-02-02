with STM32.Board;   use STM32.Board;
with STM32.Device;  use STM32.Device;
with STM32.Timers;  use STM32.Timers;
with STM32.GPIO;    use STM32.GPIO;

package body Fan_3wires.Interrupts is

   -------------
   -- Handler --
   -------------

   protected body Handler is

      -----------------
      -- IRQ_Handler --
      -----------------

      procedure IRQ_Handler is
      begin
         if Status (Timer_2, Timer_Update_Indicated) then
            if Interrupt_Enabled (Timer_2, Timer_Update_Interrupt) then
               Clear_Pending_Interrupt (Timer_2, Timer_Update_Interrupt);
                  fan_3wires.Get_Timer_Count;
            end if;
         end if;
      end IRQ_Handler;

   end Handler;

end Fan_3wires.Interrupts;
