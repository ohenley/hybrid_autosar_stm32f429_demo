with Beta_Types; use Beta_Types;

with Ada.Real_Time; use Ada.Real_Time;

with STM32;
with STM32.Device; use STM32.Device;

with STM32.GPIO; use STM32.GPIO;
with STM32.SPI;  use STM32.SPI;

with LCD_Std_Out; use LCD_Std_Out;
with BMP_Fonts; use BMP_Fonts;

with Thermocouple_Max31856;
with Cyclic_Temp;

with STM32.Board;

with Fan_3wires;
with Fan_3wires.Interrupts;
pragma Unreferenced (Fan_3wires.Interrupts);

procedure Hybrid_Autosar_Stm32f429_Demo is

   package TM renames Thermocouple_Max31856;
   package F3W renames Fan_3wires;

   TC_Temp : TM.Thermocouple_Temp_T;
   TC_Cycle_Freq : constant Cyclic_Temp.MS_T := 1_000;

   F3W_Freq : UInt32 := 0;

   Port            : SPI_Port renames SPI_4;
   SPI_AF          : STM32.GPIO_Alternate_Function renames GPIO_AF_SPI4_5;
   SPI_SCK_Pin     : GPIO_Point renames PE2;
   SPI_MISO_Pin    : GPIO_Point renames PE5;
   SPI_MOSI_Pin    : GPIO_Point renames PE6;
   Chip_Select_Pin : GPIO_Point renames PE3;

   TC : aliased TM.Thermocouple_T :=
     TM.Build_Thermocouple
       (Port, SPI_AF, SPI_SCK_Pin, SPI_MISO_Pin, SPI_MOSI_Pin,
        Chip_Select_Pin);

   Period : constant Time_Span := Milliseconds (1000);
   Next_Release : Time;

begin
   --STM32.GPIO.Initialize_LEDs;

   --Set_Font (Font8x8);
   --STM32.Board.Initialize_LEDs;
   --STM32.Board.Toggle (STM32.Board.Green_LED);
   --STM32.Board.All_LEDs_On;

   Fan_3wires.Initialize;
   Cyclic_Temp.Create_Cycle (TC'Unchecked_Access, TC_Cycle_Freq);

   -- Next_Release := Clock + Period;
   loop
      null;
      -- delay until Next_Release;
      -- Next_Release := Next_Release + Period;

      TC_Temp := Cyclic_Temp.Get_Thermocouple_Temp;
      F3W_Freq   := F3W.Get_Fan_Encoder_Freq;

      Clear_Screen;
      Put_Line ("Temp: " & TC_Temp'Image & " C");
      Put_Line ("Fan: " & F3W_Freq'Image & " Hz");
   end loop;
end Hybrid_Autosar_Stm32f429_Demo;
