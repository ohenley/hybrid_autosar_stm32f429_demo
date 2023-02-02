with STM32.Board;
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
         if Status (Timer_2, Timer_CC1_Indicated) then
            if Interrupt_Enabled (Timer_2, Timer_CC1_Interrupt) then
               Clear_Pending_Interrupt (Timer_2, Timer_CC1_Interrupt);
               fan_3wires.Get_Timer_Count;
               STM32.Board.All_LEDs_On;
            end if;
         end if;
      end IRQ_Handler;

   end Handler;

end Fan_3wires.Interrupts;
