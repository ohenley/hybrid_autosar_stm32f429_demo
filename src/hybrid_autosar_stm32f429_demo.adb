with Beta_Types; use Beta_Types;

with STM32;
with STM32.Device; use STM32.Device;

with STM32.GPIO; use STM32.GPIO;
with STM32.SPI; use STM32.SPI;

with LCD_Std_Out; use LCD_Std_Out;

with Thermocouple_Max31856;
with Cyclic_Temp;

with Fan_3wires;
with Fan_3wires.Interrupts;  pragma Unreferenced (Fan_3wires.Interrupts);

procedure Hybrid_Autosar_Stm32f429_Demo is

   package TM renames Thermocouple_Max31856;
   package F3W renames Fan_3wires;

   TC_Temp : TM.Thermocouple_Temp_T;
   Count : UInt32 := 0;
   Freq : constant Cyclic_Temp.MS_T := 1000;

   Port            : SPI_Port renames SPI_4;
   SPI_AF          : STM32.GPIO_Alternate_Function renames GPIO_AF_SPI4_5;
   SPI_SCK_Pin     : GPIO_Point renames PE2;
   SPI_MISO_Pin    : GPIO_Point renames PE5;
   SPI_MOSI_Pin    : GPIO_Point renames PE6;
   Chip_Select_Pin : GPIO_Point renames PE3;

   TC : aliased TM.Thermocouple_T := TM.Build_Thermocouple
                                     (Port,
                                      SPI_AF,
                                      SPI_SCK_Pin,
                                      SPI_MISO_Pin,
                                      SPI_MOSI_Pin,
                                      Chip_Select_Pin);

begin
   Cyclic_Temp.Create_Cycle (TC'Unchecked_Access, Freq);
   loop
      TC_Temp := Cyclic_Temp.Get_Thermocouple_Temp;
      Count := F3W.Get_Count;
      Clear_Screen;
      Put_Line (TC_Temp'Image);
      Put_Line (Count'Image);
   end loop;
end Hybrid_Autosar_Stm32f429_Demo;
