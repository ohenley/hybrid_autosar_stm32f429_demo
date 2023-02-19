package body Fan_3wires is

   use BT;

   Memory_Count : Float := 0.0;
   Count : Float := 0.0;
   Coef : constant Float := 90_000_000.0 * 0.5; -- ABH2 @ 90MHz, 2 pulses per rotation

   function Get_Fan_Encoder_Freq return BT.UInt32 is
      Moving_Average_Count : constant Float := (Count) * 0.1 + Memory_Count * 0.9;
   begin
      Memory_Count := Moving_Average_Count;
      return BT.UInt32 (Coef / Moving_Average_Count);
   end Get_Fan_Encoder_Freq;

   procedure Save_Timer_Count is
      Actual_Count : constant BT.UInt32 := Current_Capture_Value (Encoder_Timer, Channel_1);
   begin
      Count := (if Actual_Count = 0 then 1.0 else Float (Actual_Count));
      Set_Counter (Encoder_Timer, BT.UInt32'(0));
   end Save_Timer_Count;
   
   --  function Get_Fan_Encoder_Freq return BT.UInt32 is
   --     --Freq : constant UInt32 := Coef / Count;
   --  begin
   --     --return Freq;
   --     return Count;
   --  end Get_Fan_Encoder_Freq;
   --  
   --  procedure Save_Timer_Count is
   --     Reset_Value : BT.UInt32 := 0;
   --  begin
   --     Count := Current_Counter (Encoder_Timer);
   --     Set_Counter (Encoder_Timer, Reset_Value);
   --  end Save_Timer_Count;
   
   procedure Initialize_PWM_Fan is
   begin
      STM32.PWM.Configure_PWM_Timer (PWM_Output_Timer'Access, PWM_Frequency);
      PWM_Output_Fan.Attach_PWM_Channel
        (Generator => PWM_Output_Timer'Access,
         Channel   => Channel_1,
         Point     => PWM_Fan,
         PWM_AF    => PWM_Output_AF);
      PWM_Output_Fan.Set_Duty_Cycle (0);
      PWM_Output_Fan.Enable_Output;
   end Initialize_PWM_Fan;

   procedure Initialize is
   begin
      Enable_Clock (Encoder_Tach);
      Enable_Clock (Encoder_Timer);

      Configure_IO
        (Encoder_Tach,
         (Mode           => Mode_AF,
          AF             => Encoder_AF,
          Resistors      => Pull_Up,
          AF_Output_Type => Push_Pull,
          AF_Speed       => Speed_100MHz));

      Configure
        (Encoder_Timer,
         Prescaler => 0,
         Period => BT.UInt32 (BT.UInt32'Last),
         Clock_Divisor => Div1,
         Counter_Mode => Up);

      Configure_Channel_Input
        (Encoder_Timer,
         Channel   => Channel_1,
         Polarity  => Rising,
         Selection => Direct_TI,
         Prescaler => Div1,
         Filter => 0);

      Enable_Channel (Encoder_Timer, Channel_1);
      Set_Counter (Encoder_Timer, BT.UInt32'(0));

      Enable_Interrupt (Encoder_Timer, Timer_CC1_Interrupt);

      Enable (Encoder_Timer);
   end Initialize;
   
   procedure Set_Duty (Duty : STM32.PWM.Percentage) is
   begin
      PWM_Output_Fan.Set_Duty_Cycle (Duty);
   end;

begin
   -- Initialize_PWM_Fan;
   Initialize;
end Fan_3wires;
