with Ada.Interrupts.Names; use Ada.Interrupts.Names;

package Fan_3wires.Interrupts is

   protected Handler is
      pragma Interrupt_Priority;

   private

      procedure IRQ_Handler;
      pragma Attach_Handler (IRQ_Handler, TIM2_Interrupt);

   end Handler;

end Fan_3wires.Interrupts;
