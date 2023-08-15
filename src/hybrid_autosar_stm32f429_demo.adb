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

with Engine;
with STM32.PWM;

with Bitmapped_Drawing;
with Cortex_M.Cache;
with HAL.Bitmap;

with Simple_Adc;
with RTE;

with Textures.Autosar;
with Textures.Adalogo;

with Ada.Containers.Vectors;

procedure Hybrid_Autosar_Stm32f429_Demo is

   package TM renames Thermocouple_Max31856;
   package F3W renames Fan_3wires;

   TC_Cycle_Freq : constant Cyclic_Temp.MS_T := 1_000;
   Fan_Running : Boolean := False;

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

   Period : constant Time_Span := Milliseconds (1000);
   Next_Release : Time;
   
   procedure To_LCD (PWM1 : String; PWM2 : String; ADC : String; Temp : String; Fan_Running : Boolean) is
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
               Start      => (0, 40),
               Msg        => Temp,
               Font       => BMP_Fonts.Font16x24,
               Foreground => HAL.Bitmap.White,
               Background => HAL.Bitmap.Transparent);

      Bitmapped_Drawing.Draw_String
              (Buffer     => Buf,
               Start      => (0, 64),
               Msg        => "Fan: ",
               Font       => BMP_Fonts.Font16x24,
               Foreground => HAL.Bitmap.White,
               Background => HAL.Bitmap.Transparent);

      Bitmapped_Drawing.Draw_String
              (Buffer     => Buf,
               Start      => (80, 64),
               Msg        => (if Fan_Running then "ON" else "OFF"),
               Font       => BMP_Fonts.Font16x24,
               Foreground => (if Fan_Running then HAL.Bitmap.Green else HAL.Bitmap.Red),
               Background => HAL.Bitmap.Transparent);

      Bitmapped_Drawing.Draw_String
              (Buffer     => Buf,
               Start      => (0, 110),
               Msg        => " -> " & ADC,
               Font       => BMP_Fonts.Font12x12,
               Foreground => HAL.Bitmap.White,
               Background => HAL.Bitmap.Transparent);

      Bitmapped_Drawing.Draw_String
              (Buffer     => Buf,
               Start      => (0, 130),
               Msg        => " -> " & PWM1,
               Font       => BMP_Fonts.Font12x12,
               Foreground => HAL.Bitmap.White,
               Background => HAL.Bitmap.Transparent);

      Bitmapped_Drawing.Draw_String
              (Buffer     => Buf,
               Start      => (0, 150),
               Msg        => " -> " & PWM2,
               Font       => BMP_Fonts.Font12x12,
               Foreground => HAL.Bitmap.White,
               Background => HAL.Bitmap.Transparent);
      
      Bitmapped_Drawing.Draw_Texture
        (Buffer     => Buf,
         Start      => (0, 206),
         Tex        => Textures.Adalogo.Bmp,
         Foreground => HAL.Bitmap.White,
         Background => HAL.Bitmap.Transparent);
      
      STM32.Board.Display.Update_Layer (1);

   end To_LCD;

   procedure Run_Demo is
      use TM;
      TC_Temp : TM.Thermocouple_Temp_T;
      
      Fan_Duty : STM32.PWM.Percentage := 100;

      procedure Run_Fan is
      begin
         TC_Temp := Cyclic_Temp.Get_Thermocouple_Temp;
         if TC_Temp > 28.0 then
            Fan_3wires.Set_Duty(100);
            Fan_Running := True;
         elsif TC_Temp < 27.0 then
            Fan_3wires.Set_Duty(0);
            Fan_Running := False;
         end if;
      end;
      
      procedure Run_Motor is
         function Read_ADC_Value (G : Simple_Adc.Group_T; 
                                  V : access Simple_Adc.Data_T) return Simple_Adc.Status_T
            with
               Import        => True,
               Convention    => C,
               External_Name => "Adc_ReadGroup";

         Value : aliased Simple_Adc.Data_T := 0;
         Result : Simple_Adc.Status_T := Read_ADC_Value (1, Value'Unchecked_Access);
         Duty : STM32.PWM.Percentage := STM32.PWM.Percentage (-0.008333333*Float (Value) + 100.0);

         type Fixed is delta 0.1 range -1.0e6 .. 1.0e6;

         PWM1_Image : String := Duty'Image;
         Sliced_PWM1  : constant String := PWM1_Image(2 .. PWM1_Image'Last);

         PWM2 : Integer := (if Fan_Running then 100 else 0);
         PWM2_Image : String := PWM2'Image;
         Sliced_PWM2  : constant String := PWM2_Image(2 .. PWM2_Image'Last);
      begin
         if Duty <= 20 then
            Duty := 0;
         end if;
         Engine.Set_Duty (Duty);
         To_LCD ("Pwm_SetDutyCycle(" & Sliced_PWM1 &")",
                 "Pwm_SetDutyCycle(" & Sliced_PWM2 &")",
                 "Adc_ReadGroup(0," & Value'Image & ")",
                 "Motor Temp:" & Fixed(TC_Temp)'Image & "C",
                 Fan_Running);
      end Run_Motor;
   begin
      Run_Fan;
      Run_Motor;
   end Run_Demo;

   --package MyVector is new Ada.Containers.Vectors(Index_Type   => Natural,
   --                                              Element_Type => Integer);
   --MV : MyVector.Vector;
   I : Integer := 0;
begin
   --  LCD_Std_Out.Set_Orientation (Landscape);
   --  Fan_3wires.Initialize_PWM_Fan;
   --  RTE.Init_ADC;
   --  RTE.Init_PWM;
   --  Simple_Adc.Start_Group_Conversion (1);
   --  Cyclic_Temp.Create_Cycle (TC'Unchecked_Access, TC_Cycle_Freq);

   loop
      I := I + 1;
      --MV.Append (I);
      delay 0.5;
      To_LCD ("Pwm_SetDutyCycle(" & "Sliced_PWM1" &")",
                 "Pwm_SetDutyCycle(" & "Sliced_PWM2" &")",
                 "Adc_ReadGroup(0," & I'Image & ")",
                 "Motor Temp:" & I'Image & "C",
                 True);
      --Run_Demo;
   end loop;

end Hybrid_Autosar_Stm32f429_Demo;
