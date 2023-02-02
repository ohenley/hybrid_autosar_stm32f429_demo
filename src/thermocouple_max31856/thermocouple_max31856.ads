with Beta_Types;

with HAL.SPI; use HAL.SPI;
with HAL.GPIO;

with STM32.Device; use STM32.Device;
with STM32.GPIO;   use STM32.GPIO;
with STM32.SPI;

with STM32; use STM32;

package Thermocouple_Max31856 is

   package BT renames Beta_Types;

   type Thermocouple_T is limited private;

   type Thermocouple_Access_T is access all Thermocouple_T;

   type Conversion_Mode_T is (Normaly_Off, Continuous_100ms) with
      Size => 1;

   type One_Shot_Mode_T is (No, Yes) with
      Size => 1;

   type Open_Circuit_Fault_Detection_T is
     (Disabled, Enabled_Smaller_5k, Enabled_Greater_5k_Smaller_2ms,
      Enabled_Greater_5k_Greater_2ms) with
      Size => 2;

   type Cold_Junction_Sensor_T is (Enabled, Disabled) with
      Size => 1;

   type Fault_Mode_T is (Comparator, Interrupt) with
      Size => 1;

   type Fault_Status_Clear_T is
     (Default, Interrupt_Return_All_Fault_Status) with
      Size => 1;

   type Noise_Rejection_Filter_T is (Hertz_60, Hertz_50) with
      Size => 1;

   type Voltage_Conversion_Averaging_Mode_T is
     (Sample_1, Sample_2, Sample_4, Sample_8, Sample_16) with
      Size => 3;

   type Thermocouple_Type_T is (B, E, J, K, N, R, S, T) with
      Size => 4;

   type Thermocouple_Temp_T is delta 0.007_812_5 range -210.0 .. 1_800.0;

   type Cold_Junction_Temp_T is delta 1.0 range -128.0 .. 127.0;

   function Build_Thermocouple
     (Port : in out STM32.SPI.SPI_Port; SPI_AF : GPIO_Alternate_Function;
      SPI_SCK_Pin  :        GPIO_Point; SPI_MISO_Pin : GPIO_Point;
      SPI_MOSI_Pin :        GPIO_Point; Chip_Select_Pin : in out GPIO_Point)
      return Thermocouple_T;

   procedure Set_Thermocouple_Type
     (This : in out Thermocouple_T; T_type : Thermocouple_Type_T);
   function Get_Thermocouple_Type
     (This : in out Thermocouple_T) return Thermocouple_Type_T;

   procedure Set_One_Shot_Mode (This : in out Thermocouple_T);

   function Get_One_Shot_Mode
     (This : in out Thermocouple_T) return One_Shot_Mode_T;

   function Retrieve_Thermocouple_Temp
     (This : in out Thermocouple_T) return Thermocouple_Temp_T;

private

   type Thermocouple_T is record
      Port         : not null HAL.SPI.Any_SPI_Port;
      SPI_AF       : GPIO_Alternate_Function;
      SPI_SCK_Pin  : GPIO_Point;
      SPI_MISO_Pin : GPIO_Point;
      SPI_MOSI_Pin : GPIO_Point;
      Chip_Select  : GPIO_Point;
   end record;

   for Conversion_Mode_T use (Normaly_Off => 0, Continuous_100ms => 1);

   for One_Shot_Mode_T use (No => 0, Yes => 1);

   for Open_Circuit_Fault_Detection_T use
     (Disabled                       => 2#00#, Enabled_Smaller_5k => 2#01#,
      Enabled_Greater_5k_Smaller_2ms => 2#10#,
      Enabled_Greater_5k_Greater_2ms => 2#11#);

   for Cold_Junction_Sensor_T use
     (Enabled => 0, Disabled => 1); -- MAX31856.pdf, p.19

   for Fault_Mode_T use (Comparator => 0, Interrupt => 1);

   for Fault_Status_Clear_T use
     (Default => 0, Interrupt_Return_All_Fault_Status => 1);

   for Noise_Rejection_Filter_T use (Hertz_60 => 0, Hertz_50 => 1);

   for Voltage_Conversion_Averaging_Mode_T use
     (Sample_1 => 2#000#, Sample_2 => 2#001#, Sample_4 => 2#010#,
      Sample_8 => 2#011#, Sample_16 => 2#111#);

   for Thermocouple_Type_T use
     (B => 2#0000#, E => 2#0001#, J => 2#0010#, K => 2#0011#, N => 2#0100#,
      R => 2#0101#, S => 2#0110#, T => 2#0111#);

   for Thermocouple_Temp_T'Small use 0.007_812_5;

   for Cold_Junction_Temp_T'Small use 1.0;

   type CR0_T is record
      CMODE    : Conversion_Mode_T              := Normaly_Off;
      ONE_SHOT : One_Shot_Mode_T                := No;
      OCFAULT  : Open_Circuit_Fault_Detection_T := Disabled;
      CJ       : Cold_Junction_Sensor_T         := Enabled;
      FAULT    : Fault_Mode_T                   := Comparator;
      FAULTCLR : Fault_Status_Clear_T           := Default;
      HZ_6050  : Noise_Rejection_Filter_T       := Hertz_60;
   end record with
      Size => BT.UInt8'Size;
   for CR0_T use record
      CMODE    at 0 range 7 .. 7;
      ONE_SHOT at 0 range 6 .. 6;
      OCFAULT  at 0 range 4 .. 5;
      CJ       at 0 range 3 .. 3;
      FAULT    at 0 range 2 .. 2;
      FAULTCLR at 0 range 1 .. 1;
      HZ_6050  at 0 range 0 .. 0;
   end record;

   type CR1_T is record
      DUMMY   : BT.Bit                              := 0;
      AVGSEL  : Voltage_Conversion_Averaging_Mode_T := Sample_1;
      TC_TYPE : Thermocouple_Type_T                 := K;
   end record with
      Size => BT.UInt8'Size;

   for CR1_T use record
      DUMMY   at 0 range 7 .. 7;
      AVGSEL  at 0 range 4 .. 6;
      TC_TYPE at 0 range 0 .. 3;
   end record;

end Thermocouple_Max31856;
