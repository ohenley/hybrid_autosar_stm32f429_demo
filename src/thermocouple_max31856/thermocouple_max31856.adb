with STM32;

with Ada.Real_Time; use Ada.Real_Time;
with STM32.Board;   use STM32.Board;

package body Thermocouple_Max31856 is

   type Register_Address is new BT.UInt8;

   CR0 : constant Register_Address := 16#00#;          -- Configuration 0 Register
   CR0_Default : constant                  := 16#00#;

   CR1 : constant Register_Address := 16#01#;          -- Configuration 1 Register
   CR1_Default : constant                  := 16#03#;

   MASK         : constant Register_Address := 16#02#; -- Fault Mask Register
   MASK_Default : constant                  := 16#FF#;

   CJHF : constant Register_Address :=
     16#03#; -- Cold-Junction High Fault Threshold
   CJHF_Default : constant := 16#7F#;

   CJLF : constant Register_Address :=
     16#04#; -- Cold-Junction Low Fault Threshold
   CJLF_Default : constant := 16#C0#;

   LTHFTH : constant Register_Address :=
     16#05#; -- Linearized Temperature High Fault Threshold MSB
   LTHFTH_Default : constant := 16#7F#;

   LTHFTL : constant Register_Address :=
     16#06#; -- Linearized Temperature High Fault Threshold LSB
   LTHFTL_Default : constant := 16#FF#;

   LTLFTH : constant Register_Address :=
     16#07#; -- Linearized Temperature Low Fault Threshold MSB
   LTLFTH_Default : constant := 16#80#;

   LTLFTL : constant Register_Address :=
     16#08#; -- Linearized Temperature Low Fault Threshold LSB
   LTLFTL_Default : constant := 16#00#;

   CJTO : constant Register_Address :=
     16#09#; -- Cold-Junction Temperature Offset Register
   CJTO_Default : constant := 16#00#;

   CJTH : constant Register_Address :=
     16#0A#; -- Cold-Junction Temperature Register MSB
   CJTH_Default : constant := 16#00#;

   CJTL : constant Register_Address :=
     16#0B#; -- Cold-Junction Temperature Register LSB
   CJTL_Default : constant := 16#00#;

   LTCBH : constant Register_Address :=
     16#0C#; -- Linearized TC Temperature, Byte 2
   LTCBH_Default : constant := 16#00#;

   LTCBM : constant Register_Address :=
     16#0D#; -- Linearized TC Temperature, Byte 1
   LTCBM_Default : constant := 16#00#;

   LTCBL : constant Register_Address :=
     16#0E#; -- Linearized TC Temperature, Byte 0
   LTCBL_Default : constant := 16#00#;

   SR         : constant Register_Address := 16#0F#; -- Fault Status Register
   SR_Default : constant                  := 16#00#;

   procedure IO_Write
     (This : in out Thermocouple_T; Value : BT.UInt8; Addr : Register_Address)
   is
      Status : SPI_Status;
      Data   : constant SPI_Data_8b (1 .. 2) :=
        (BT.UInt8 (Addr or 16#80#), Value);
   begin
      This.Chip_Select.Clear;
      This.Port.Transmit (Data, Status);
      This.Chip_Select.Set;

      if Status /= Ok then
         raise Program_Error;
      end if;
   end IO_Write;

   function IO_Read
     (This : in out Thermocouple_T; Nbr_Bytes_To_Read : Positive;
      Addr :        Register_Address) return SPI_Data_8b
   is
      Status  : SPI_Status;
      Request : constant SPI_Data_8b (1 .. 1)        := (1 => BT.UInt8 (Addr));
      Data    : SPI_Data_8b (1 .. Nbr_Bytes_To_Read) := (others => 0);
   begin
      This.Chip_Select.Clear;
      This.Port.Transmit (Request, Status);
      if Status /= Ok then
         raise Program_Error;
      end if;
      This.Port.Receive (Data, Status);
      if Status /= Ok then
         raise Program_Error;
      end if;
      This.Chip_Select.Set;
      return Data;
   end IO_Read;

   function Build_Thermocouple
     (Port : in out STM32.SPI.SPI_Port; SPI_AF : GPIO_Alternate_Function;
      SPI_SCK_Pin  :        GPIO_Point; SPI_MISO_Pin : GPIO_Point;
      SPI_MOSI_Pin :        GPIO_Point; Chip_Select_Pin : in out GPIO_Point)
      return Thermocouple_T
   is
      procedure Init_SPI is
         use STM32.SPI;
         Config : SPI_Configuration;
      begin
         Enable_Clock (Port);

         Config.Mode                := Master;
         Config.Baud_Rate_Prescaler := BRP_32;
         Config.Clock_Polarity      := Low;
         Config.Clock_Phase         := P2Edge;
         Config.First_Bit           := MSB;
         Config.CRC_Poly            := 7;
         Config.Slave_Management    := Software_Managed;  --  essential!!
         Config.Direction           := D2Lines_FullDuplex;
         Config.Data_Size           := HAL.SPI.Data_Size_8b;

         Disable (Port);
         Configure (Port, Config);
         Enable (Port);
      end Init_SPI;

      procedure Init_GPIO is
         Config     : GPIO_Port_Configuration;
         SPI_Points : constant GPIO_Points :=
           SPI_MOSI_Pin & SPI_MISO_Pin & SPI_SCK_Pin;
      begin
         Enable_Clock (SPI_Points);

         Configure_IO
           (SPI_Points,
            (Mode_AF, AF => SPI_AF, Resistors => Floating,
             AF_Speed    => Speed_50MHz, AF_Output_Type => Push_Pull));

         Enable_Clock (Chip_Select_Pin);

         Chip_Select_Pin.Configure_IO
           ((Mode_Out, Resistors => Pull_Up, Output_Type => Push_Pull,
             Speed               => Speed_25MHz));

         Chip_Select_Pin.Set;

      end Init_GPIO;

   begin
      Init_GPIO;
      Init_SPI;
      return
        (Port'Unchecked_Access, SPI_AF, SPI_SCK_Pin, SPI_MISO_Pin,
         SPI_MOSI_Pin, Chip_Select_Pin);
   end Build_Thermocouple;

   procedure Set_Thermocouple_Type
     (This : in out Thermocouple_T; T_type : Thermocouple_Type_T)
   is
      Register     : CR1_T;
      Raw_Register : SPI_Data_8b (1 .. 1) with
         Address => Register'Address;
   begin
      Raw_Register     := IO_Read (This, 1, CR1);
      Register.TC_TYPE := T_type;
      IO_Write (This, Raw_Register (1), CR1);
   end Set_Thermocouple_Type;

   function Get_Thermocouple_Type
     (This : in out Thermocouple_T) return Thermocouple_Type_T
   is
      Register     : CR1_T;
      Raw_Register : SPI_Data_8b (1 .. 1) with
         Address => Register'Address;
   begin
      Raw_Register := IO_Read (This, 1, CR1);
      return Register.TC_TYPE;
   end Get_Thermocouple_Type;

   procedure Set_One_Shot_Mode (This : in out Thermocouple_T) is
      CR0_Register : CR0_T;
      Raw_Register : BT.UInt8 with
         Address => CR0_Register'Address;
   begin
      CR0_Register.CMODE    := Normaly_Off;
      CR0_Register.ONE_SHOT := Yes;
      IO_Write (This, Raw_Register, CR0);
   end Set_One_Shot_Mode;

   function Get_One_Shot_Mode
     (This : in out Thermocouple_T) return One_Shot_Mode_T
   is
      CR0_Register : CR0_T;
      Raw_Register : SPI_Data_8b (1 .. 1) with
         Address => CR0_Register'Address;
   begin
      Raw_Register := IO_Read (This, 1, CR0);
      return CR0_Register.ONE_SHOT;
   end Get_One_Shot_Mode;

   function Retrieve_Thermocouple_Temp
     (This : in out Thermocouple_T) return Thermocouple_Temp_T
   is
      Temp_Array : constant SPI_Data_8b := IO_Read (This, 3, LTCBH);
      Array_Temp : SPI_Data_8b (1 .. 3) :=
        (Temp_Array (3), Temp_Array (2), Temp_Array (1));

      --  Array_Temp : SPI_Data_8b (1 .. 3) :=
      --    (Temp_Array (1), Temp_Array (2), Temp_Array (3));

      type Temp_T is record
         DUMMY : BT.UInt5;
         TEMP  : BT.UInt18;
         SIGN  : BT.Bit;
      end record with
         Size => BT.UInt24'Size;

      for Temp_T use record
         DUMMY at 0 range  0 ..  4;
         TEMP  at 0 range  5 .. 22;
         SIGN  at 0 range 23 .. 23;
      end record;

      Raw_Temp : Temp_T with
         Address => Array_Temp'Address;
      Temp              : BT.UInt18 := Raw_Temp.TEMP;
      Thermocouple_Temp : Thermocouple_Temp_T with
         Address => Temp'Address;
   begin
      return Thermocouple_Temp;
   end Retrieve_Thermocouple_Temp;

end Thermocouple_Max31856;
