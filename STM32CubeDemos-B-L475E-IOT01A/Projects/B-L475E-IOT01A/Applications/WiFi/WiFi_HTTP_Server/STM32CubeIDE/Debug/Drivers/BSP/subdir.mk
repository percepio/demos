################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (12.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
C:/src/github-repos/detect_basic_demo/STM32CubeDemos-B-L475E-IOT01A/Drivers/BSP/Components/hts221/hts221.c 

OBJS += \
./Drivers/BSP/hts221.o 

C_DEPS += \
./Drivers/BSP/hts221.d 


# Each subdirectory must supply rules for building sources it contributes
Drivers/BSP/hts221.o: C:/src/github-repos/detect_basic_demo/STM32CubeDemos-B-L475E-IOT01A/Drivers/BSP/Components/hts221/hts221.c Drivers/BSP/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m4 -std=gnu11 -g3 -DUSE_HAL_DRIVER -DUSE_STM32L475E_IOT01 -DSTM32L475xx -c -I../../Inc -I../../../Common/Inc -I../../../../../../../Drivers/CMSIS/Include -I../../../../../../../Drivers/CMSIS/Device/ST/STM32L4xx/Include -I../../../../../../../Drivers/STM32L4xx_HAL_Driver/Inc -I../../../../../../../Drivers/BSP/B-L475E-IOT01 -O0 -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb -o "$@"

clean: clean-Drivers-2f-BSP

clean-Drivers-2f-BSP:
	-$(RM) ./Drivers/BSP/hts221.cyclo ./Drivers/BSP/hts221.d ./Drivers/BSP/hts221.o ./Drivers/BSP/hts221.su

.PHONY: clean-Drivers-2f-BSP

