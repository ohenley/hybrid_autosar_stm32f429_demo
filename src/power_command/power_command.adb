with Ada.Real_Time; use Ada.Real_Time;

with STM32.Board;  use STM32.Board;
with STM32.Device; use STM32.Device;

with HAL;        use HAL;
with STM32.ADC;  use STM32.ADC;
with STM32.DMA;  use STM32.DMA;
with STM32.GPIO; use STM32.GPIO;

package body Power_Command is

    Converter : Analog_To_Digital_Converter renames ADC_1;
    Input_Channel : constant Analog_Input_Channel := 13;
    Input         : constant GPIO_Point           := PC3;

    Controller : DMA_Controller renames DMA_2;
    Stream     : constant DMA_Stream_Selector := Stream_0;

    Counts : UInt16 with Volatile;
    --  The raw sample from the ADC conversion of the VBat input

    Voltage : UInt32;  -- in millivolts
    --  the converted voltage representing the VBat level, in millivolts

    procedure Initialize_DMA is
        Config : DMA_Stream_Configuration;
    begin
        Enable_Clock (Controller);

        Reset (Controller, Stream);

        Config.Channel                      := Channel_0;
        Config.Direction                    := Peripheral_To_Memory;
        Config.Memory_Data_Format           := HalfWords;
        Config.Peripheral_Data_Format       := HalfWords;
        Config.Increment_Peripheral_Address := False;
        Config.Increment_Memory_Address     := False;
        Config.Operation_Mode               := Circular_Mode;
        Config.Priority                     := Priority_Very_High;
        Config.FIFO_Enabled                 := False;
        Config.Memory_Burst_Size            := Memory_Burst_Single;
        Config.Peripheral_Burst_Size        := Peripheral_Burst_Single;

        Configure (Controller, Stream, Config);

        Clear_All_Status (Controller, Stream);
    end Initialize_DMA;


    procedure Initialize_ADC is
        All_Regular_Conversions : constant Regular_Channel_Conversions :=
           (1 => (Channel => Input_Channel, Sample_Time => Sample_480_Cycles));

        procedure Configure_Analog_Input is
        begin
            Enable_Clock (Input);
            Configure_IO (Input, (Mode => Mode_Analog, Resistors => Floating));
        end Configure_Analog_Input;
    begin
        Configure_Analog_Input;

        Enable_Clock (Converter);

        Reset_All_ADC_Units;

        Configure_Common_Properties
           (Mode     => Independent, Prescalar => PCLK2_Div_2,
            DMA_Mode => Disabled, Sampling_Delay => Sampling_Delay_5_Cycles);

        Configure_Unit
           (Converter, Resolution => ADC_Resolution_12_Bits,
            Alignment             => Right_Aligned);

        Configure_Regular_Conversions
           (Converter, Continuous => True, Trigger => Software_Triggered,
            Enable_EOC => False, Conversions => All_Regular_Conversions);

        Enable_DMA (Converter);

        Enable_DMA_After_Last_Transfer (Converter);
    end Initialize_ADC;

    function Get_Milli_Voltage return UInt32 is
    begin
        return ((UInt32 (Counts) * 4) * ADC_Supply_Voltage) / 16#FFF#;
    end;

begin
    Initialize_DMA;
    Initialize_ADC;
    Enable (Converter);
    Start_Transfer
       (Controller, Stream, Source => Data_Register_Address (Converter),
        Destination => Counts'Address, Data_Count => 1);  -- ie, 1 halfword
    Start_Conversion (Converter);
end Power_Command;
