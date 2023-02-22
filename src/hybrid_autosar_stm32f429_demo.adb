with Beta_Types; use Beta_Types;

with Ada.Real_Time; use Ada.Real_Time;

with STM32;
with STM32.Device; use STM32.Device;

with STM32.GPIO; use STM32.GPIO;
with STM32.SPI;  use STM32.SPI;

with LCD_Std_Out;
with HAL.Framebuffer; use HAL.Framebuffer;
with BMP_Fonts; use BMP_Fonts;

with Thermocouple_Max31856;
with Cyclic_Temp;

with STM32.Board;

with Fan_3wires;
with Fan_3wires.Interrupts;
pragma Unreferenced (Fan_3wires.Interrupts);

-- with Power_Command;
with Engine;
with STM32.PWM;

with Bitmapped_Drawing;
with Cortex_M.Cache;
with HAL.Bitmap;

with Ada.Characters.Latin_1; use Ada.Characters.Latin_1;

with Simple_Adc;
with RTE;

with Textures.Autosar;

procedure Hybrid_Autosar_Stm32f429_Demo is

   package TM renames Thermocouple_Max31856;
   package F3W renames Fan_3wires;

   --TC_Temp : TM.Thermocouple_Temp_T;
   TC_Cycle_Freq : constant Cyclic_Temp.MS_T := 1_000;

   Port            : SPI_Port renames SPI_4;
   SPI_AF          : STM32.GPIO_Alternate_Function renames GPIO_AF_SPI4_5;
   SPI_SCK_Pin     : GPIO_Point renames PE2;
   SPI_MISO_Pin    : GPIO_Point renames PE5;
   SPI_MOSI_Pin    : GPIO_Point renames PE6;
   Chip_Select_Pin : GPIO_Point renames PE3;

   TC : aliased TM.Thermocouple_T := TM.Build_Thermocouple
       (Port, SPI_AF, SPI_SCK_Pin, SPI_MISO_Pin, SPI_MOSI_Pin,
        Chip_Select_Pin);

   Period : constant Time_Span := Milliseconds (1000);
   Next_Release : Time;
   
   procedure Log_To_LCD (Voltage : String; Duty : String; Temp : String) is
      Buf : HAL.Bitmap.Bitmap_Buffer'Class := STM32.Board.Display.Hidden_Buffer (1).all;
   begin
      LCD_Std_Out.Set_Orientation (Landscape);
      Cortex_M.Cache.Invalidate_DCache (Buf'Address, Buf.Buffer_Size);
      Buf.Fill;
      Bitmapped_Drawing.Draw_Texture
        (Buffer     => Buf,
         Start      => (0, 0),
         Tex        => Textures.Autosar.Bmp,
         Foreground => HAL.Bitmap.White,
         Background => HAL.Bitmap.Transparent);
      Bitmapped_Drawing.Draw_String
              (Buffer     => Buf,
               Start      => (0, 36),
               Msg        => Temp,
               Font       => BMP_Fonts.Font16x24,
               Foreground => HAL.Bitmap.White,
               Background => HAL.Bitmap.Transparent);
      Bitmapped_Drawing.Draw_String
              (Buffer     => Buf,
               Start      => (0, 60),
               Msg        => Voltage,
               Font       => BMP_Fonts.Font16x24,
               Foreground => HAL.Bitmap.White,
               Background => HAL.Bitmap.Transparent);
      Bitmapped_Drawing.Draw_String
              (Buffer     => Buf,
               Start      => (0, 84),
               Msg        => Duty,
               Font       => BMP_Fonts.Font16x24,
               Foreground => HAL.Bitmap.White,
               Background => HAL.Bitmap.Transparent);
      STM32.Board.Display.Update_Layer (1);
   end Log_To_LCD;

   procedure Run_Demo is
      use TM;
      TC_Temp : TM.Thermocouple_Temp_T;

      procedure Run_Fan is
      begin
         TC_Temp := Cyclic_Temp.Get_Thermocouple_Temp;
         if TC_Temp > 29.0 then
            Fan_3wires.Set_Duty(100);
         elsif TC_Temp < 28.0 then
            Fan_3wires.Set_Duty(0);
         end if;
      end;

      --  procedure Run_Engine is
      --     Voltage : UInt32 := Power_Command.Get_Milli_Voltage;
      --     Duty : STM32.PWM.Percentage := STM32.PWM.Percentage (-0.006666667*Float (Voltage) + 100.0);
      --  begin
      --     if Duty <= 20 then
      --        Duty := 0;
      --     end if;
      --     Engine.Set_Duty (Duty);
      --     Log_To_LCD ("Voltage:" & Voltage'Image,
      --                 "Duty:" & Duty'Image,
      --                 "Temp:" & TC_Temp'Image);
      --  end;
      
      procedure Run_Engine is
         function Read_ADC_Value (G : Simple_Adc.Group_T; 
                                  V : access Simple_Adc.Data_T) return Simple_Adc.Status_T
            with
               Import        => True,
               Convention    => C,
               External_Name => "Adc_ReadGroup";

         Value : aliased Simple_Adc.Data_T := 0;
         Result : Simple_Adc.Status_T := Read_ADC_Value (1, Value'Unchecked_Access);
         Duty : STM32.PWM.Percentage := STM32.PWM.Percentage (-0.006666667*Float (Value) + 100.0);
      begin
         if Duty <= 20 then
            Duty := 0;
         end if;
         Engine.Set_Duty (Duty);
         Log_To_LCD ("Voltage:" & Value'Image,
                     "Duty:" & Duty'Image,
                     "Temp:" & TC_Temp'Image);
      end;
      
      type Fixed is delta 0.1 range -1.0e6 .. 1.0e6;
   begin
      Run_Fan;
      Run_Engine;
   end Run_Demo;
begin

   LCD_Std_Out.Set_Orientation (Landscape);

   Fan_3wires.Initialize_PWM_Fan;
   RTE.Init_ADC;
   Simple_Adc.Start_Group_Conversion (1);

   Cyclic_Temp.Create_Cycle (TC'Unchecked_Access, TC_Cycle_Freq);

   loop
      Run_Demo;
   end loop;

end Hybrid_Autosar_Stm32f429_Demo;













--Fan_3wires.Initialize;
--TC_Temp := Cyclic_Temp.Get_Thermocouple_Temp;
--Voltage := Power_Command.Get_Milli_Voltage;
-- F3W_Freq   := F3W.Get_Fan_Encoder_Freq;
--Draw ("Engine Temp:" & Fixed(TC_Temp)'Image & " C" & CR & LF & "Voltage:" & Voltage'Image);
