#
# Generated Makefile - do not edit!
#
# Edit the Makefile in the project folder instead (../Makefile). Each target
# has a -pre and a -post target defined where you can add customized code.
#
# This makefile implements configuration specific macros and targets.


# Include project Makefile
ifeq "${IGNORE_LOCAL}" "TRUE"
# do not include local makefile. User is passing all local related variables already
else
include Makefile
# Include makefile containing local settings
ifeq "$(wildcard nbproject/Makefile-local-pic32ck_sg01_cult.mk)" "nbproject/Makefile-local-pic32ck_sg01_cult.mk"
include nbproject/Makefile-local-pic32ck_sg01_cult.mk
endif
endif

# Environment
MKDIR=gnumkdir -p
RM=rm -f 
MV=mv 
CP=cp 

# Macros
CND_CONF=pic32ck_sg01_cult
ifeq ($(TYPE_IMAGE), DEBUG_RUN)
IMAGE_TYPE=debug
OUTPUT_SUFFIX=elf
DEBUGGABLE_SUFFIX=elf
FINAL_IMAGE=${DISTDIR}/get_start_freertos_pic32ck_sg01_cult.X.${IMAGE_TYPE}.${OUTPUT_SUFFIX}
else
IMAGE_TYPE=production
OUTPUT_SUFFIX=hex
DEBUGGABLE_SUFFIX=elf
FINAL_IMAGE=${DISTDIR}/get_start_freertos_pic32ck_sg01_cult.X.${IMAGE_TYPE}.${OUTPUT_SUFFIX}
endif

ifeq ($(COMPARE_BUILD), true)
COMPARISON_BUILD=-mafrlcsj
else
COMPARISON_BUILD=
endif

# Object Directory
OBJECTDIR=build/${CND_CONF}/${IMAGE_TYPE}

# Distribution Directory
DISTDIR=dist/${CND_CONF}/${IMAGE_TYPE}

# Source Files Quoted if spaced
SOURCEFILES_QUOTED_IF_SPACED=../src/config/pic32ck_sg01_cult/driver/i2c/src/drv_i2c.c ../src/config/pic32ck_sg01_cult/driver/usart/src/drv_usart.c ../src/config/pic32ck_sg01_cult/osal/osal_freertos.c ../src/config/pic32ck_sg01_cult/peripheral/dma/plib_dma0.c ../src/config/pic32ck_sg01_cult/peripheral/nvic/plib_nvic.c ../src/config/pic32ck_sg01_cult/peripheral/port/plib_port.c ../src/config/pic32ck_sg01_cult/peripheral/sercom/i2c_master/plib_sercom4_i2c_master.c ../src/config/pic32ck_sg01_cult/peripheral/sercom/usart/plib_sercom5_usart.c ../src/config/pic32ck_sg01_cult/peripheral/tcc/plib_tcc0.c ../src/config/pic32ck_sg01_cult/stdio/xc32_monitor.c ../src/config/pic32ck_sg01_cult/system/cache/sys_cache.c ../src/config/pic32ck_sg01_cult/system/dma/sys_dma.c ../src/config/pic32ck_sg01_cult/system/int/src/sys_int.c ../src/config/pic32ck_sg01_cult/system/time/src/sys_time.c ../src/config/pic32ck_sg01_cult/initialization.c ../src/config/pic32ck_sg01_cult/libc_syscalls.c ../src/config/pic32ck_sg01_cult/startup_xc32.c ../src/config/pic32ck_sg01_cult/freertos_hooks.c ../src/config/pic32ck_sg01_cult/exceptions.c ../src/config/pic32ck_sg01_cult/interrupts.c ../src/config/pic32ck_sg01_cult/tasks.c ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure/port.c ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure/portasm.c ../src/third_party/rtos/FreeRTOS/Source/portable/MemMang/heap_1.c ../src/third_party/rtos/FreeRTOS/Source/list.c ../src/third_party/rtos/FreeRTOS/Source/FreeRTOS_tasks.c ../src/third_party/rtos/FreeRTOS/Source/queue.c ../src/third_party/rtos/FreeRTOS/Source/timers.c ../src/third_party/rtos/FreeRTOS/Source/stream_buffer.c ../src/third_party/rtos/FreeRTOS/Source/croutine.c ../src/third_party/rtos/FreeRTOS/Source/event_groups.c ../src/main.c ../src/app_user_input_thread.c ../src/app_sensor_thread.c ../src/app_eeprom_thread.c

# Object Files Quoted if spaced
OBJECTFILES_QUOTED_IF_SPACED=${OBJECTDIR}/_ext/1370381428/drv_i2c.o ${OBJECTDIR}/_ext/77410273/drv_usart.o ${OBJECTDIR}/_ext/1341659013/osal_freertos.o ${OBJECTDIR}/_ext/1272162897/plib_dma0.o ${OBJECTDIR}/_ext/782651049/plib_nvic.o ${OBJECTDIR}/_ext/782704200/plib_port.o ${OBJECTDIR}/_ext/2068415726/plib_sercom4_i2c_master.o ${OBJECTDIR}/_ext/1526276258/plib_sercom5_usart.o ${OBJECTDIR}/_ext/1272177965/plib_tcc0.o ${OBJECTDIR}/_ext/1361970333/xc32_monitor.o ${OBJECTDIR}/_ext/1034146574/sys_cache.o ${OBJECTDIR}/_ext/1364204420/sys_dma.o ${OBJECTDIR}/_ext/1201302448/sys_int.o ${OBJECTDIR}/_ext/1184702314/sys_time.o ${OBJECTDIR}/_ext/461543203/initialization.o ${OBJECTDIR}/_ext/461543203/libc_syscalls.o ${OBJECTDIR}/_ext/461543203/startup_xc32.o ${OBJECTDIR}/_ext/461543203/freertos_hooks.o ${OBJECTDIR}/_ext/461543203/exceptions.o ${OBJECTDIR}/_ext/461543203/interrupts.o ${OBJECTDIR}/_ext/461543203/tasks.o ${OBJECTDIR}/_ext/1779283508/port.o ${OBJECTDIR}/_ext/1779283508/portasm.o ${OBJECTDIR}/_ext/1665200909/heap_1.o ${OBJECTDIR}/_ext/404212886/list.o ${OBJECTDIR}/_ext/404212886/FreeRTOS_tasks.o ${OBJECTDIR}/_ext/404212886/queue.o ${OBJECTDIR}/_ext/404212886/timers.o ${OBJECTDIR}/_ext/404212886/stream_buffer.o ${OBJECTDIR}/_ext/404212886/croutine.o ${OBJECTDIR}/_ext/404212886/event_groups.o ${OBJECTDIR}/_ext/1360937237/main.o ${OBJECTDIR}/_ext/1360937237/app_user_input_thread.o ${OBJECTDIR}/_ext/1360937237/app_sensor_thread.o ${OBJECTDIR}/_ext/1360937237/app_eeprom_thread.o
POSSIBLE_DEPFILES=${OBJECTDIR}/_ext/1370381428/drv_i2c.o.d ${OBJECTDIR}/_ext/77410273/drv_usart.o.d ${OBJECTDIR}/_ext/1341659013/osal_freertos.o.d ${OBJECTDIR}/_ext/1272162897/plib_dma0.o.d ${OBJECTDIR}/_ext/782651049/plib_nvic.o.d ${OBJECTDIR}/_ext/782704200/plib_port.o.d ${OBJECTDIR}/_ext/2068415726/plib_sercom4_i2c_master.o.d ${OBJECTDIR}/_ext/1526276258/plib_sercom5_usart.o.d ${OBJECTDIR}/_ext/1272177965/plib_tcc0.o.d ${OBJECTDIR}/_ext/1361970333/xc32_monitor.o.d ${OBJECTDIR}/_ext/1034146574/sys_cache.o.d ${OBJECTDIR}/_ext/1364204420/sys_dma.o.d ${OBJECTDIR}/_ext/1201302448/sys_int.o.d ${OBJECTDIR}/_ext/1184702314/sys_time.o.d ${OBJECTDIR}/_ext/461543203/initialization.o.d ${OBJECTDIR}/_ext/461543203/libc_syscalls.o.d ${OBJECTDIR}/_ext/461543203/startup_xc32.o.d ${OBJECTDIR}/_ext/461543203/freertos_hooks.o.d ${OBJECTDIR}/_ext/461543203/exceptions.o.d ${OBJECTDIR}/_ext/461543203/interrupts.o.d ${OBJECTDIR}/_ext/461543203/tasks.o.d ${OBJECTDIR}/_ext/1779283508/port.o.d ${OBJECTDIR}/_ext/1779283508/portasm.o.d ${OBJECTDIR}/_ext/1665200909/heap_1.o.d ${OBJECTDIR}/_ext/404212886/list.o.d ${OBJECTDIR}/_ext/404212886/FreeRTOS_tasks.o.d ${OBJECTDIR}/_ext/404212886/queue.o.d ${OBJECTDIR}/_ext/404212886/timers.o.d ${OBJECTDIR}/_ext/404212886/stream_buffer.o.d ${OBJECTDIR}/_ext/404212886/croutine.o.d ${OBJECTDIR}/_ext/404212886/event_groups.o.d ${OBJECTDIR}/_ext/1360937237/main.o.d ${OBJECTDIR}/_ext/1360937237/app_user_input_thread.o.d ${OBJECTDIR}/_ext/1360937237/app_sensor_thread.o.d ${OBJECTDIR}/_ext/1360937237/app_eeprom_thread.o.d

# Object Files
OBJECTFILES=${OBJECTDIR}/_ext/1370381428/drv_i2c.o ${OBJECTDIR}/_ext/77410273/drv_usart.o ${OBJECTDIR}/_ext/1341659013/osal_freertos.o ${OBJECTDIR}/_ext/1272162897/plib_dma0.o ${OBJECTDIR}/_ext/782651049/plib_nvic.o ${OBJECTDIR}/_ext/782704200/plib_port.o ${OBJECTDIR}/_ext/2068415726/plib_sercom4_i2c_master.o ${OBJECTDIR}/_ext/1526276258/plib_sercom5_usart.o ${OBJECTDIR}/_ext/1272177965/plib_tcc0.o ${OBJECTDIR}/_ext/1361970333/xc32_monitor.o ${OBJECTDIR}/_ext/1034146574/sys_cache.o ${OBJECTDIR}/_ext/1364204420/sys_dma.o ${OBJECTDIR}/_ext/1201302448/sys_int.o ${OBJECTDIR}/_ext/1184702314/sys_time.o ${OBJECTDIR}/_ext/461543203/initialization.o ${OBJECTDIR}/_ext/461543203/libc_syscalls.o ${OBJECTDIR}/_ext/461543203/startup_xc32.o ${OBJECTDIR}/_ext/461543203/freertos_hooks.o ${OBJECTDIR}/_ext/461543203/exceptions.o ${OBJECTDIR}/_ext/461543203/interrupts.o ${OBJECTDIR}/_ext/461543203/tasks.o ${OBJECTDIR}/_ext/1779283508/port.o ${OBJECTDIR}/_ext/1779283508/portasm.o ${OBJECTDIR}/_ext/1665200909/heap_1.o ${OBJECTDIR}/_ext/404212886/list.o ${OBJECTDIR}/_ext/404212886/FreeRTOS_tasks.o ${OBJECTDIR}/_ext/404212886/queue.o ${OBJECTDIR}/_ext/404212886/timers.o ${OBJECTDIR}/_ext/404212886/stream_buffer.o ${OBJECTDIR}/_ext/404212886/croutine.o ${OBJECTDIR}/_ext/404212886/event_groups.o ${OBJECTDIR}/_ext/1360937237/main.o ${OBJECTDIR}/_ext/1360937237/app_user_input_thread.o ${OBJECTDIR}/_ext/1360937237/app_sensor_thread.o ${OBJECTDIR}/_ext/1360937237/app_eeprom_thread.o

# Source Files
SOURCEFILES=../src/config/pic32ck_sg01_cult/driver/i2c/src/drv_i2c.c ../src/config/pic32ck_sg01_cult/driver/usart/src/drv_usart.c ../src/config/pic32ck_sg01_cult/osal/osal_freertos.c ../src/config/pic32ck_sg01_cult/peripheral/dma/plib_dma0.c ../src/config/pic32ck_sg01_cult/peripheral/nvic/plib_nvic.c ../src/config/pic32ck_sg01_cult/peripheral/port/plib_port.c ../src/config/pic32ck_sg01_cult/peripheral/sercom/i2c_master/plib_sercom4_i2c_master.c ../src/config/pic32ck_sg01_cult/peripheral/sercom/usart/plib_sercom5_usart.c ../src/config/pic32ck_sg01_cult/peripheral/tcc/plib_tcc0.c ../src/config/pic32ck_sg01_cult/stdio/xc32_monitor.c ../src/config/pic32ck_sg01_cult/system/cache/sys_cache.c ../src/config/pic32ck_sg01_cult/system/dma/sys_dma.c ../src/config/pic32ck_sg01_cult/system/int/src/sys_int.c ../src/config/pic32ck_sg01_cult/system/time/src/sys_time.c ../src/config/pic32ck_sg01_cult/initialization.c ../src/config/pic32ck_sg01_cult/libc_syscalls.c ../src/config/pic32ck_sg01_cult/startup_xc32.c ../src/config/pic32ck_sg01_cult/freertos_hooks.c ../src/config/pic32ck_sg01_cult/exceptions.c ../src/config/pic32ck_sg01_cult/interrupts.c ../src/config/pic32ck_sg01_cult/tasks.c ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure/port.c ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure/portasm.c ../src/third_party/rtos/FreeRTOS/Source/portable/MemMang/heap_1.c ../src/third_party/rtos/FreeRTOS/Source/list.c ../src/third_party/rtos/FreeRTOS/Source/FreeRTOS_tasks.c ../src/third_party/rtos/FreeRTOS/Source/queue.c ../src/third_party/rtos/FreeRTOS/Source/timers.c ../src/third_party/rtos/FreeRTOS/Source/stream_buffer.c ../src/third_party/rtos/FreeRTOS/Source/croutine.c ../src/third_party/rtos/FreeRTOS/Source/event_groups.c ../src/main.c ../src/app_user_input_thread.c ../src/app_sensor_thread.c ../src/app_eeprom_thread.c



CFLAGS=
ASFLAGS=
LDLIBSOPTIONS=

############# Tool locations ##########################################
# If you copy a project from one host to another, the path where the  #
# compiler is installed may be different.                             #
# If you open this project with MPLAB X in the new host, this         #
# makefile will be regenerated and the paths will be corrected.       #
#######################################################################
# fixDeps replaces a bunch of sed/cat/printf statements that slow down the build
FIXDEPS=fixDeps

.build-conf:  ${BUILD_SUBPROJECTS}
ifneq ($(INFORMATION_MESSAGE), )
	@echo $(INFORMATION_MESSAGE)
endif
	${MAKE}  -f nbproject/Makefile-pic32ck_sg01_cult.mk ${DISTDIR}/get_start_freertos_pic32ck_sg01_cult.X.${IMAGE_TYPE}.${OUTPUT_SUFFIX}

MP_PROCESSOR_OPTION=32CK2051SG01144
MP_LINKER_FILE_OPTION=,--script="..\src\config\pic32ck_sg01_cult\PIC32CK2051SG01144.ld"
# ------------------------------------------------------------------------------------
# Rules for buildStep: assemble
ifeq ($(TYPE_IMAGE), DEBUG_RUN)
else
endif

# ------------------------------------------------------------------------------------
# Rules for buildStep: assembleWithPreprocess
ifeq ($(TYPE_IMAGE), DEBUG_RUN)
else
endif

# ------------------------------------------------------------------------------------
# Rules for buildStep: compile
ifeq ($(TYPE_IMAGE), DEBUG_RUN)
${OBJECTDIR}/_ext/1370381428/drv_i2c.o: ../src/config/pic32ck_sg01_cult/driver/i2c/src/drv_i2c.c  .generated_files/flags/pic32ck_sg01_cult/d8dfb12954b698985cdd2978d8b0f54fcf4e8cb6 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1370381428" 
	@${RM} ${OBJECTDIR}/_ext/1370381428/drv_i2c.o.d 
	@${RM} ${OBJECTDIR}/_ext/1370381428/drv_i2c.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1370381428/drv_i2c.o.d" -o ${OBJECTDIR}/_ext/1370381428/drv_i2c.o ../src/config/pic32ck_sg01_cult/driver/i2c/src/drv_i2c.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/77410273/drv_usart.o: ../src/config/pic32ck_sg01_cult/driver/usart/src/drv_usart.c  .generated_files/flags/pic32ck_sg01_cult/ee3653a140facb4eaa70865259a35f365680d049 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/77410273" 
	@${RM} ${OBJECTDIR}/_ext/77410273/drv_usart.o.d 
	@${RM} ${OBJECTDIR}/_ext/77410273/drv_usart.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/77410273/drv_usart.o.d" -o ${OBJECTDIR}/_ext/77410273/drv_usart.o ../src/config/pic32ck_sg01_cult/driver/usart/src/drv_usart.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1341659013/osal_freertos.o: ../src/config/pic32ck_sg01_cult/osal/osal_freertos.c  .generated_files/flags/pic32ck_sg01_cult/1712ec6e8163d661b10f97c79cc0281d026ea993 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1341659013" 
	@${RM} ${OBJECTDIR}/_ext/1341659013/osal_freertos.o.d 
	@${RM} ${OBJECTDIR}/_ext/1341659013/osal_freertos.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1341659013/osal_freertos.o.d" -o ${OBJECTDIR}/_ext/1341659013/osal_freertos.o ../src/config/pic32ck_sg01_cult/osal/osal_freertos.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1272162897/plib_dma0.o: ../src/config/pic32ck_sg01_cult/peripheral/dma/plib_dma0.c  .generated_files/flags/pic32ck_sg01_cult/ff9e0ecc6f7c60c9fba3f98a1efcaf08e943bb32 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1272162897" 
	@${RM} ${OBJECTDIR}/_ext/1272162897/plib_dma0.o.d 
	@${RM} ${OBJECTDIR}/_ext/1272162897/plib_dma0.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1272162897/plib_dma0.o.d" -o ${OBJECTDIR}/_ext/1272162897/plib_dma0.o ../src/config/pic32ck_sg01_cult/peripheral/dma/plib_dma0.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/782651049/plib_nvic.o: ../src/config/pic32ck_sg01_cult/peripheral/nvic/plib_nvic.c  .generated_files/flags/pic32ck_sg01_cult/17d20319ac7fc499a4027a0347e864bfdf9cec21 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/782651049" 
	@${RM} ${OBJECTDIR}/_ext/782651049/plib_nvic.o.d 
	@${RM} ${OBJECTDIR}/_ext/782651049/plib_nvic.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/782651049/plib_nvic.o.d" -o ${OBJECTDIR}/_ext/782651049/plib_nvic.o ../src/config/pic32ck_sg01_cult/peripheral/nvic/plib_nvic.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/782704200/plib_port.o: ../src/config/pic32ck_sg01_cult/peripheral/port/plib_port.c  .generated_files/flags/pic32ck_sg01_cult/a65b73c6797a9ca48d78ccaad3a01ad3ce8fa8df .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/782704200" 
	@${RM} ${OBJECTDIR}/_ext/782704200/plib_port.o.d 
	@${RM} ${OBJECTDIR}/_ext/782704200/plib_port.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/782704200/plib_port.o.d" -o ${OBJECTDIR}/_ext/782704200/plib_port.o ../src/config/pic32ck_sg01_cult/peripheral/port/plib_port.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/2068415726/plib_sercom4_i2c_master.o: ../src/config/pic32ck_sg01_cult/peripheral/sercom/i2c_master/plib_sercom4_i2c_master.c  .generated_files/flags/pic32ck_sg01_cult/33c861cc9498c78d54ff654591f8f53f839ce923 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/2068415726" 
	@${RM} ${OBJECTDIR}/_ext/2068415726/plib_sercom4_i2c_master.o.d 
	@${RM} ${OBJECTDIR}/_ext/2068415726/plib_sercom4_i2c_master.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/2068415726/plib_sercom4_i2c_master.o.d" -o ${OBJECTDIR}/_ext/2068415726/plib_sercom4_i2c_master.o ../src/config/pic32ck_sg01_cult/peripheral/sercom/i2c_master/plib_sercom4_i2c_master.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1526276258/plib_sercom5_usart.o: ../src/config/pic32ck_sg01_cult/peripheral/sercom/usart/plib_sercom5_usart.c  .generated_files/flags/pic32ck_sg01_cult/3d8d567c46b7dbf8c5f532fd6128f39d9d553c70 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1526276258" 
	@${RM} ${OBJECTDIR}/_ext/1526276258/plib_sercom5_usart.o.d 
	@${RM} ${OBJECTDIR}/_ext/1526276258/plib_sercom5_usart.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1526276258/plib_sercom5_usart.o.d" -o ${OBJECTDIR}/_ext/1526276258/plib_sercom5_usart.o ../src/config/pic32ck_sg01_cult/peripheral/sercom/usart/plib_sercom5_usart.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1272177965/plib_tcc0.o: ../src/config/pic32ck_sg01_cult/peripheral/tcc/plib_tcc0.c  .generated_files/flags/pic32ck_sg01_cult/52d95542a16537f29e50cc7d8e93e130f3bf88b .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1272177965" 
	@${RM} ${OBJECTDIR}/_ext/1272177965/plib_tcc0.o.d 
	@${RM} ${OBJECTDIR}/_ext/1272177965/plib_tcc0.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1272177965/plib_tcc0.o.d" -o ${OBJECTDIR}/_ext/1272177965/plib_tcc0.o ../src/config/pic32ck_sg01_cult/peripheral/tcc/plib_tcc0.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1361970333/xc32_monitor.o: ../src/config/pic32ck_sg01_cult/stdio/xc32_monitor.c  .generated_files/flags/pic32ck_sg01_cult/a9baef701f71c3f3c9a60b4b79eb947795dbdf1b .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1361970333" 
	@${RM} ${OBJECTDIR}/_ext/1361970333/xc32_monitor.o.d 
	@${RM} ${OBJECTDIR}/_ext/1361970333/xc32_monitor.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1361970333/xc32_monitor.o.d" -o ${OBJECTDIR}/_ext/1361970333/xc32_monitor.o ../src/config/pic32ck_sg01_cult/stdio/xc32_monitor.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1034146574/sys_cache.o: ../src/config/pic32ck_sg01_cult/system/cache/sys_cache.c  .generated_files/flags/pic32ck_sg01_cult/a4b3744bc00d98652d9f97f670c645d2df5dd0a .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1034146574" 
	@${RM} ${OBJECTDIR}/_ext/1034146574/sys_cache.o.d 
	@${RM} ${OBJECTDIR}/_ext/1034146574/sys_cache.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1034146574/sys_cache.o.d" -o ${OBJECTDIR}/_ext/1034146574/sys_cache.o ../src/config/pic32ck_sg01_cult/system/cache/sys_cache.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1364204420/sys_dma.o: ../src/config/pic32ck_sg01_cult/system/dma/sys_dma.c  .generated_files/flags/pic32ck_sg01_cult/ba49e2ec81a0acaa99676cf4aad5b0a18a760401 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1364204420" 
	@${RM} ${OBJECTDIR}/_ext/1364204420/sys_dma.o.d 
	@${RM} ${OBJECTDIR}/_ext/1364204420/sys_dma.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1364204420/sys_dma.o.d" -o ${OBJECTDIR}/_ext/1364204420/sys_dma.o ../src/config/pic32ck_sg01_cult/system/dma/sys_dma.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1201302448/sys_int.o: ../src/config/pic32ck_sg01_cult/system/int/src/sys_int.c  .generated_files/flags/pic32ck_sg01_cult/461ff4cb0c30d58a37c09dcedcd498fc283e9882 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1201302448" 
	@${RM} ${OBJECTDIR}/_ext/1201302448/sys_int.o.d 
	@${RM} ${OBJECTDIR}/_ext/1201302448/sys_int.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1201302448/sys_int.o.d" -o ${OBJECTDIR}/_ext/1201302448/sys_int.o ../src/config/pic32ck_sg01_cult/system/int/src/sys_int.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1184702314/sys_time.o: ../src/config/pic32ck_sg01_cult/system/time/src/sys_time.c  .generated_files/flags/pic32ck_sg01_cult/ca820796ede1ad5a20b3007d9fcfbc4a4c4794ee .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1184702314" 
	@${RM} ${OBJECTDIR}/_ext/1184702314/sys_time.o.d 
	@${RM} ${OBJECTDIR}/_ext/1184702314/sys_time.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1184702314/sys_time.o.d" -o ${OBJECTDIR}/_ext/1184702314/sys_time.o ../src/config/pic32ck_sg01_cult/system/time/src/sys_time.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/initialization.o: ../src/config/pic32ck_sg01_cult/initialization.c  .generated_files/flags/pic32ck_sg01_cult/6207976e769c272a88e06e4fe76789c610c44fb1 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/initialization.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/initialization.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/initialization.o.d" -o ${OBJECTDIR}/_ext/461543203/initialization.o ../src/config/pic32ck_sg01_cult/initialization.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/libc_syscalls.o: ../src/config/pic32ck_sg01_cult/libc_syscalls.c  .generated_files/flags/pic32ck_sg01_cult/84ee2be7dbf545ac250828f25866ab575e981a5f .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/libc_syscalls.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/libc_syscalls.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/libc_syscalls.o.d" -o ${OBJECTDIR}/_ext/461543203/libc_syscalls.o ../src/config/pic32ck_sg01_cult/libc_syscalls.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/startup_xc32.o: ../src/config/pic32ck_sg01_cult/startup_xc32.c  .generated_files/flags/pic32ck_sg01_cult/78797349eec289f8ad251cbcaa89874b1476def2 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/startup_xc32.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/startup_xc32.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/startup_xc32.o.d" -o ${OBJECTDIR}/_ext/461543203/startup_xc32.o ../src/config/pic32ck_sg01_cult/startup_xc32.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/freertos_hooks.o: ../src/config/pic32ck_sg01_cult/freertos_hooks.c  .generated_files/flags/pic32ck_sg01_cult/54b640d403745b4dc3e3908d580d18cb91452c8a .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/freertos_hooks.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/freertos_hooks.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/freertos_hooks.o.d" -o ${OBJECTDIR}/_ext/461543203/freertos_hooks.o ../src/config/pic32ck_sg01_cult/freertos_hooks.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/exceptions.o: ../src/config/pic32ck_sg01_cult/exceptions.c  .generated_files/flags/pic32ck_sg01_cult/1a62b32af177dbd5c5563f2dcbd751ec4721d7c9 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/exceptions.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/exceptions.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/exceptions.o.d" -o ${OBJECTDIR}/_ext/461543203/exceptions.o ../src/config/pic32ck_sg01_cult/exceptions.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/interrupts.o: ../src/config/pic32ck_sg01_cult/interrupts.c  .generated_files/flags/pic32ck_sg01_cult/d88fe12e1d93c1aaf2dbc7bb380f18f31291cba8 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/interrupts.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/interrupts.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/interrupts.o.d" -o ${OBJECTDIR}/_ext/461543203/interrupts.o ../src/config/pic32ck_sg01_cult/interrupts.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/tasks.o: ../src/config/pic32ck_sg01_cult/tasks.c  .generated_files/flags/pic32ck_sg01_cult/be870a09332c5a19b1d780f993c9c1ce55b06b84 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/tasks.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/tasks.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/tasks.o.d" -o ${OBJECTDIR}/_ext/461543203/tasks.o ../src/config/pic32ck_sg01_cult/tasks.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1779283508/port.o: ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure/port.c  .generated_files/flags/pic32ck_sg01_cult/16c5611644a31ac4d11c805d0071e97a1d1ed8d6 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1779283508" 
	@${RM} ${OBJECTDIR}/_ext/1779283508/port.o.d 
	@${RM} ${OBJECTDIR}/_ext/1779283508/port.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1779283508/port.o.d" -o ${OBJECTDIR}/_ext/1779283508/port.o ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure/port.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1779283508/portasm.o: ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure/portasm.c  .generated_files/flags/pic32ck_sg01_cult/72c850ad1b9dc18277147a0209dd149a5379b4c7 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1779283508" 
	@${RM} ${OBJECTDIR}/_ext/1779283508/portasm.o.d 
	@${RM} ${OBJECTDIR}/_ext/1779283508/portasm.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1779283508/portasm.o.d" -o ${OBJECTDIR}/_ext/1779283508/portasm.o ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure/portasm.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1665200909/heap_1.o: ../src/third_party/rtos/FreeRTOS/Source/portable/MemMang/heap_1.c  .generated_files/flags/pic32ck_sg01_cult/2b25bb0aaae9f969930c94f5d70024de79ef84d2 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1665200909" 
	@${RM} ${OBJECTDIR}/_ext/1665200909/heap_1.o.d 
	@${RM} ${OBJECTDIR}/_ext/1665200909/heap_1.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1665200909/heap_1.o.d" -o ${OBJECTDIR}/_ext/1665200909/heap_1.o ../src/third_party/rtos/FreeRTOS/Source/portable/MemMang/heap_1.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/404212886/list.o: ../src/third_party/rtos/FreeRTOS/Source/list.c  .generated_files/flags/pic32ck_sg01_cult/563aea4d0758e3e2c5781638706d72fb17cc158 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/404212886" 
	@${RM} ${OBJECTDIR}/_ext/404212886/list.o.d 
	@${RM} ${OBJECTDIR}/_ext/404212886/list.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/404212886/list.o.d" -o ${OBJECTDIR}/_ext/404212886/list.o ../src/third_party/rtos/FreeRTOS/Source/list.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/404212886/FreeRTOS_tasks.o: ../src/third_party/rtos/FreeRTOS/Source/FreeRTOS_tasks.c  .generated_files/flags/pic32ck_sg01_cult/ac629ea75a5f34adf24336a42d57adda4d6c8a3a .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/404212886" 
	@${RM} ${OBJECTDIR}/_ext/404212886/FreeRTOS_tasks.o.d 
	@${RM} ${OBJECTDIR}/_ext/404212886/FreeRTOS_tasks.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/404212886/FreeRTOS_tasks.o.d" -o ${OBJECTDIR}/_ext/404212886/FreeRTOS_tasks.o ../src/third_party/rtos/FreeRTOS/Source/FreeRTOS_tasks.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/404212886/queue.o: ../src/third_party/rtos/FreeRTOS/Source/queue.c  .generated_files/flags/pic32ck_sg01_cult/37ca0bcfadc7563fdc9d0ff7b8dbbe6f84082fbb .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/404212886" 
	@${RM} ${OBJECTDIR}/_ext/404212886/queue.o.d 
	@${RM} ${OBJECTDIR}/_ext/404212886/queue.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/404212886/queue.o.d" -o ${OBJECTDIR}/_ext/404212886/queue.o ../src/third_party/rtos/FreeRTOS/Source/queue.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/404212886/timers.o: ../src/third_party/rtos/FreeRTOS/Source/timers.c  .generated_files/flags/pic32ck_sg01_cult/97365b86ff76dcd8f565c547ca3a3f50ddf1defa .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/404212886" 
	@${RM} ${OBJECTDIR}/_ext/404212886/timers.o.d 
	@${RM} ${OBJECTDIR}/_ext/404212886/timers.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/404212886/timers.o.d" -o ${OBJECTDIR}/_ext/404212886/timers.o ../src/third_party/rtos/FreeRTOS/Source/timers.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/404212886/stream_buffer.o: ../src/third_party/rtos/FreeRTOS/Source/stream_buffer.c  .generated_files/flags/pic32ck_sg01_cult/baadb5cf01da56ce3e50c69c70244b92990cf891 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/404212886" 
	@${RM} ${OBJECTDIR}/_ext/404212886/stream_buffer.o.d 
	@${RM} ${OBJECTDIR}/_ext/404212886/stream_buffer.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/404212886/stream_buffer.o.d" -o ${OBJECTDIR}/_ext/404212886/stream_buffer.o ../src/third_party/rtos/FreeRTOS/Source/stream_buffer.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/404212886/croutine.o: ../src/third_party/rtos/FreeRTOS/Source/croutine.c  .generated_files/flags/pic32ck_sg01_cult/a2be031e2d08bfaad6ae4fb7cea3537b0dbfaa59 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/404212886" 
	@${RM} ${OBJECTDIR}/_ext/404212886/croutine.o.d 
	@${RM} ${OBJECTDIR}/_ext/404212886/croutine.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/404212886/croutine.o.d" -o ${OBJECTDIR}/_ext/404212886/croutine.o ../src/third_party/rtos/FreeRTOS/Source/croutine.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/404212886/event_groups.o: ../src/third_party/rtos/FreeRTOS/Source/event_groups.c  .generated_files/flags/pic32ck_sg01_cult/19ae86521f1d8094f455581eab9a254cce9c2347 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/404212886" 
	@${RM} ${OBJECTDIR}/_ext/404212886/event_groups.o.d 
	@${RM} ${OBJECTDIR}/_ext/404212886/event_groups.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/404212886/event_groups.o.d" -o ${OBJECTDIR}/_ext/404212886/event_groups.o ../src/third_party/rtos/FreeRTOS/Source/event_groups.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1360937237/main.o: ../src/main.c  .generated_files/flags/pic32ck_sg01_cult/401b9ed572fd6fc66bcd44c05c20726f10f93670 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1360937237" 
	@${RM} ${OBJECTDIR}/_ext/1360937237/main.o.d 
	@${RM} ${OBJECTDIR}/_ext/1360937237/main.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1360937237/main.o.d" -o ${OBJECTDIR}/_ext/1360937237/main.o ../src/main.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1360937237/app_user_input_thread.o: ../src/app_user_input_thread.c  .generated_files/flags/pic32ck_sg01_cult/e776ce86b4a506f652218020f060c7115743ac7 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1360937237" 
	@${RM} ${OBJECTDIR}/_ext/1360937237/app_user_input_thread.o.d 
	@${RM} ${OBJECTDIR}/_ext/1360937237/app_user_input_thread.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1360937237/app_user_input_thread.o.d" -o ${OBJECTDIR}/_ext/1360937237/app_user_input_thread.o ../src/app_user_input_thread.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1360937237/app_sensor_thread.o: ../src/app_sensor_thread.c  .generated_files/flags/pic32ck_sg01_cult/9edf96aa3e903dd028c99fdec080a918fb4593c2 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1360937237" 
	@${RM} ${OBJECTDIR}/_ext/1360937237/app_sensor_thread.o.d 
	@${RM} ${OBJECTDIR}/_ext/1360937237/app_sensor_thread.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1360937237/app_sensor_thread.o.d" -o ${OBJECTDIR}/_ext/1360937237/app_sensor_thread.o ../src/app_sensor_thread.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1360937237/app_eeprom_thread.o: ../src/app_eeprom_thread.c  .generated_files/flags/pic32ck_sg01_cult/a0cd08dc5cc3de64ddd87fa69318596ca500bdfd .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1360937237" 
	@${RM} ${OBJECTDIR}/_ext/1360937237/app_eeprom_thread.o.d 
	@${RM} ${OBJECTDIR}/_ext/1360937237/app_eeprom_thread.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1360937237/app_eeprom_thread.o.d" -o ${OBJECTDIR}/_ext/1360937237/app_eeprom_thread.o ../src/app_eeprom_thread.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
else
${OBJECTDIR}/_ext/1370381428/drv_i2c.o: ../src/config/pic32ck_sg01_cult/driver/i2c/src/drv_i2c.c  .generated_files/flags/pic32ck_sg01_cult/d17514fc6b4ce8c642d17e8c0947784ac7e23b0c .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1370381428" 
	@${RM} ${OBJECTDIR}/_ext/1370381428/drv_i2c.o.d 
	@${RM} ${OBJECTDIR}/_ext/1370381428/drv_i2c.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1370381428/drv_i2c.o.d" -o ${OBJECTDIR}/_ext/1370381428/drv_i2c.o ../src/config/pic32ck_sg01_cult/driver/i2c/src/drv_i2c.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/77410273/drv_usart.o: ../src/config/pic32ck_sg01_cult/driver/usart/src/drv_usart.c  .generated_files/flags/pic32ck_sg01_cult/62aefff74392013529f0fcf4228cf63859a5688f .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/77410273" 
	@${RM} ${OBJECTDIR}/_ext/77410273/drv_usart.o.d 
	@${RM} ${OBJECTDIR}/_ext/77410273/drv_usart.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/77410273/drv_usart.o.d" -o ${OBJECTDIR}/_ext/77410273/drv_usart.o ../src/config/pic32ck_sg01_cult/driver/usart/src/drv_usart.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1341659013/osal_freertos.o: ../src/config/pic32ck_sg01_cult/osal/osal_freertos.c  .generated_files/flags/pic32ck_sg01_cult/38e0fce2a448ad7ccde91f651ca5b6443a3b6afa .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1341659013" 
	@${RM} ${OBJECTDIR}/_ext/1341659013/osal_freertos.o.d 
	@${RM} ${OBJECTDIR}/_ext/1341659013/osal_freertos.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1341659013/osal_freertos.o.d" -o ${OBJECTDIR}/_ext/1341659013/osal_freertos.o ../src/config/pic32ck_sg01_cult/osal/osal_freertos.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1272162897/plib_dma0.o: ../src/config/pic32ck_sg01_cult/peripheral/dma/plib_dma0.c  .generated_files/flags/pic32ck_sg01_cult/9a1395aba8e130b0955c07f605b049be0619f65c .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1272162897" 
	@${RM} ${OBJECTDIR}/_ext/1272162897/plib_dma0.o.d 
	@${RM} ${OBJECTDIR}/_ext/1272162897/plib_dma0.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1272162897/plib_dma0.o.d" -o ${OBJECTDIR}/_ext/1272162897/plib_dma0.o ../src/config/pic32ck_sg01_cult/peripheral/dma/plib_dma0.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/782651049/plib_nvic.o: ../src/config/pic32ck_sg01_cult/peripheral/nvic/plib_nvic.c  .generated_files/flags/pic32ck_sg01_cult/447a94d031793e6ca5cbde0e59ff2d014db62cf5 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/782651049" 
	@${RM} ${OBJECTDIR}/_ext/782651049/plib_nvic.o.d 
	@${RM} ${OBJECTDIR}/_ext/782651049/plib_nvic.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/782651049/plib_nvic.o.d" -o ${OBJECTDIR}/_ext/782651049/plib_nvic.o ../src/config/pic32ck_sg01_cult/peripheral/nvic/plib_nvic.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/782704200/plib_port.o: ../src/config/pic32ck_sg01_cult/peripheral/port/plib_port.c  .generated_files/flags/pic32ck_sg01_cult/e1f511b977455e0523cae5a3913ba6719632ece .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/782704200" 
	@${RM} ${OBJECTDIR}/_ext/782704200/plib_port.o.d 
	@${RM} ${OBJECTDIR}/_ext/782704200/plib_port.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/782704200/plib_port.o.d" -o ${OBJECTDIR}/_ext/782704200/plib_port.o ../src/config/pic32ck_sg01_cult/peripheral/port/plib_port.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/2068415726/plib_sercom4_i2c_master.o: ../src/config/pic32ck_sg01_cult/peripheral/sercom/i2c_master/plib_sercom4_i2c_master.c  .generated_files/flags/pic32ck_sg01_cult/6fbffb652ef36db0b890adae59e6d2f3fb8a8371 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/2068415726" 
	@${RM} ${OBJECTDIR}/_ext/2068415726/plib_sercom4_i2c_master.o.d 
	@${RM} ${OBJECTDIR}/_ext/2068415726/plib_sercom4_i2c_master.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/2068415726/plib_sercom4_i2c_master.o.d" -o ${OBJECTDIR}/_ext/2068415726/plib_sercom4_i2c_master.o ../src/config/pic32ck_sg01_cult/peripheral/sercom/i2c_master/plib_sercom4_i2c_master.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1526276258/plib_sercom5_usart.o: ../src/config/pic32ck_sg01_cult/peripheral/sercom/usart/plib_sercom5_usart.c  .generated_files/flags/pic32ck_sg01_cult/af5a9b0247bea71e413431aec9541193a8ee849c .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1526276258" 
	@${RM} ${OBJECTDIR}/_ext/1526276258/plib_sercom5_usart.o.d 
	@${RM} ${OBJECTDIR}/_ext/1526276258/plib_sercom5_usart.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1526276258/plib_sercom5_usart.o.d" -o ${OBJECTDIR}/_ext/1526276258/plib_sercom5_usart.o ../src/config/pic32ck_sg01_cult/peripheral/sercom/usart/plib_sercom5_usart.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1272177965/plib_tcc0.o: ../src/config/pic32ck_sg01_cult/peripheral/tcc/plib_tcc0.c  .generated_files/flags/pic32ck_sg01_cult/57872e967100b49f316216261e6bc8218ac06420 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1272177965" 
	@${RM} ${OBJECTDIR}/_ext/1272177965/plib_tcc0.o.d 
	@${RM} ${OBJECTDIR}/_ext/1272177965/plib_tcc0.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1272177965/plib_tcc0.o.d" -o ${OBJECTDIR}/_ext/1272177965/plib_tcc0.o ../src/config/pic32ck_sg01_cult/peripheral/tcc/plib_tcc0.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1361970333/xc32_monitor.o: ../src/config/pic32ck_sg01_cult/stdio/xc32_monitor.c  .generated_files/flags/pic32ck_sg01_cult/c9bbfdf84e526717994829344d1d402dc62c0935 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1361970333" 
	@${RM} ${OBJECTDIR}/_ext/1361970333/xc32_monitor.o.d 
	@${RM} ${OBJECTDIR}/_ext/1361970333/xc32_monitor.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1361970333/xc32_monitor.o.d" -o ${OBJECTDIR}/_ext/1361970333/xc32_monitor.o ../src/config/pic32ck_sg01_cult/stdio/xc32_monitor.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1034146574/sys_cache.o: ../src/config/pic32ck_sg01_cult/system/cache/sys_cache.c  .generated_files/flags/pic32ck_sg01_cult/cd13db15683b8f09e48d0e83357c7bec7e40de55 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1034146574" 
	@${RM} ${OBJECTDIR}/_ext/1034146574/sys_cache.o.d 
	@${RM} ${OBJECTDIR}/_ext/1034146574/sys_cache.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1034146574/sys_cache.o.d" -o ${OBJECTDIR}/_ext/1034146574/sys_cache.o ../src/config/pic32ck_sg01_cult/system/cache/sys_cache.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1364204420/sys_dma.o: ../src/config/pic32ck_sg01_cult/system/dma/sys_dma.c  .generated_files/flags/pic32ck_sg01_cult/4bd436650b8e1873166e0ccbc44427dcadfe34c3 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1364204420" 
	@${RM} ${OBJECTDIR}/_ext/1364204420/sys_dma.o.d 
	@${RM} ${OBJECTDIR}/_ext/1364204420/sys_dma.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1364204420/sys_dma.o.d" -o ${OBJECTDIR}/_ext/1364204420/sys_dma.o ../src/config/pic32ck_sg01_cult/system/dma/sys_dma.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1201302448/sys_int.o: ../src/config/pic32ck_sg01_cult/system/int/src/sys_int.c  .generated_files/flags/pic32ck_sg01_cult/4dc061719df987dc7c189a68e040c1b25be7245d .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1201302448" 
	@${RM} ${OBJECTDIR}/_ext/1201302448/sys_int.o.d 
	@${RM} ${OBJECTDIR}/_ext/1201302448/sys_int.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1201302448/sys_int.o.d" -o ${OBJECTDIR}/_ext/1201302448/sys_int.o ../src/config/pic32ck_sg01_cult/system/int/src/sys_int.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1184702314/sys_time.o: ../src/config/pic32ck_sg01_cult/system/time/src/sys_time.c  .generated_files/flags/pic32ck_sg01_cult/c18817fd234529242df6c4133be41146ed245ec8 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1184702314" 
	@${RM} ${OBJECTDIR}/_ext/1184702314/sys_time.o.d 
	@${RM} ${OBJECTDIR}/_ext/1184702314/sys_time.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1184702314/sys_time.o.d" -o ${OBJECTDIR}/_ext/1184702314/sys_time.o ../src/config/pic32ck_sg01_cult/system/time/src/sys_time.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/initialization.o: ../src/config/pic32ck_sg01_cult/initialization.c  .generated_files/flags/pic32ck_sg01_cult/dab37a1a3826148e889a6af6a69abdfcd922a572 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/initialization.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/initialization.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/initialization.o.d" -o ${OBJECTDIR}/_ext/461543203/initialization.o ../src/config/pic32ck_sg01_cult/initialization.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/libc_syscalls.o: ../src/config/pic32ck_sg01_cult/libc_syscalls.c  .generated_files/flags/pic32ck_sg01_cult/3fd4519b14562111a4c698076a425a4694a7384b .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/libc_syscalls.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/libc_syscalls.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/libc_syscalls.o.d" -o ${OBJECTDIR}/_ext/461543203/libc_syscalls.o ../src/config/pic32ck_sg01_cult/libc_syscalls.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/startup_xc32.o: ../src/config/pic32ck_sg01_cult/startup_xc32.c  .generated_files/flags/pic32ck_sg01_cult/5c04748279b41222fce0d4781cd6802e7b88650c .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/startup_xc32.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/startup_xc32.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/startup_xc32.o.d" -o ${OBJECTDIR}/_ext/461543203/startup_xc32.o ../src/config/pic32ck_sg01_cult/startup_xc32.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/freertos_hooks.o: ../src/config/pic32ck_sg01_cult/freertos_hooks.c  .generated_files/flags/pic32ck_sg01_cult/87b02b987fc2f0b0bbb04831d992be88cd81a1 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/freertos_hooks.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/freertos_hooks.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/freertos_hooks.o.d" -o ${OBJECTDIR}/_ext/461543203/freertos_hooks.o ../src/config/pic32ck_sg01_cult/freertos_hooks.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/exceptions.o: ../src/config/pic32ck_sg01_cult/exceptions.c  .generated_files/flags/pic32ck_sg01_cult/ab52d48ea65106b8476bbab7f80fc610c5b35bdf .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/exceptions.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/exceptions.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/exceptions.o.d" -o ${OBJECTDIR}/_ext/461543203/exceptions.o ../src/config/pic32ck_sg01_cult/exceptions.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/interrupts.o: ../src/config/pic32ck_sg01_cult/interrupts.c  .generated_files/flags/pic32ck_sg01_cult/5a1232dd9213047c96dd0e5be2a66d3533a0cdc0 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/interrupts.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/interrupts.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/interrupts.o.d" -o ${OBJECTDIR}/_ext/461543203/interrupts.o ../src/config/pic32ck_sg01_cult/interrupts.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/tasks.o: ../src/config/pic32ck_sg01_cult/tasks.c  .generated_files/flags/pic32ck_sg01_cult/e0e621ed5c39e686a147c76aba876ddd94940f54 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/tasks.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/tasks.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/tasks.o.d" -o ${OBJECTDIR}/_ext/461543203/tasks.o ../src/config/pic32ck_sg01_cult/tasks.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1779283508/port.o: ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure/port.c  .generated_files/flags/pic32ck_sg01_cult/ed46633d473ade8b44f63cfa5d8913f858444fe2 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1779283508" 
	@${RM} ${OBJECTDIR}/_ext/1779283508/port.o.d 
	@${RM} ${OBJECTDIR}/_ext/1779283508/port.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1779283508/port.o.d" -o ${OBJECTDIR}/_ext/1779283508/port.o ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure/port.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1779283508/portasm.o: ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure/portasm.c  .generated_files/flags/pic32ck_sg01_cult/aee741232635df1f72bbeec211436422e9455c12 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1779283508" 
	@${RM} ${OBJECTDIR}/_ext/1779283508/portasm.o.d 
	@${RM} ${OBJECTDIR}/_ext/1779283508/portasm.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1779283508/portasm.o.d" -o ${OBJECTDIR}/_ext/1779283508/portasm.o ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure/portasm.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1665200909/heap_1.o: ../src/third_party/rtos/FreeRTOS/Source/portable/MemMang/heap_1.c  .generated_files/flags/pic32ck_sg01_cult/d800a6d17208833a13c52b50d4ba06f09556a45 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1665200909" 
	@${RM} ${OBJECTDIR}/_ext/1665200909/heap_1.o.d 
	@${RM} ${OBJECTDIR}/_ext/1665200909/heap_1.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1665200909/heap_1.o.d" -o ${OBJECTDIR}/_ext/1665200909/heap_1.o ../src/third_party/rtos/FreeRTOS/Source/portable/MemMang/heap_1.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/404212886/list.o: ../src/third_party/rtos/FreeRTOS/Source/list.c  .generated_files/flags/pic32ck_sg01_cult/1ac04414a3f21d22ca3249c0c30343a1134205f6 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/404212886" 
	@${RM} ${OBJECTDIR}/_ext/404212886/list.o.d 
	@${RM} ${OBJECTDIR}/_ext/404212886/list.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/404212886/list.o.d" -o ${OBJECTDIR}/_ext/404212886/list.o ../src/third_party/rtos/FreeRTOS/Source/list.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/404212886/FreeRTOS_tasks.o: ../src/third_party/rtos/FreeRTOS/Source/FreeRTOS_tasks.c  .generated_files/flags/pic32ck_sg01_cult/edf9207e078f77cb365f22db39fc67bd60091297 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/404212886" 
	@${RM} ${OBJECTDIR}/_ext/404212886/FreeRTOS_tasks.o.d 
	@${RM} ${OBJECTDIR}/_ext/404212886/FreeRTOS_tasks.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/404212886/FreeRTOS_tasks.o.d" -o ${OBJECTDIR}/_ext/404212886/FreeRTOS_tasks.o ../src/third_party/rtos/FreeRTOS/Source/FreeRTOS_tasks.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/404212886/queue.o: ../src/third_party/rtos/FreeRTOS/Source/queue.c  .generated_files/flags/pic32ck_sg01_cult/1fd1cf98663c3e6ade161f372f0a4b7abad44b1f .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/404212886" 
	@${RM} ${OBJECTDIR}/_ext/404212886/queue.o.d 
	@${RM} ${OBJECTDIR}/_ext/404212886/queue.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/404212886/queue.o.d" -o ${OBJECTDIR}/_ext/404212886/queue.o ../src/third_party/rtos/FreeRTOS/Source/queue.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/404212886/timers.o: ../src/third_party/rtos/FreeRTOS/Source/timers.c  .generated_files/flags/pic32ck_sg01_cult/63f15e5edfe2644496d25b0732a9125c0e8c4f71 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/404212886" 
	@${RM} ${OBJECTDIR}/_ext/404212886/timers.o.d 
	@${RM} ${OBJECTDIR}/_ext/404212886/timers.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/404212886/timers.o.d" -o ${OBJECTDIR}/_ext/404212886/timers.o ../src/third_party/rtos/FreeRTOS/Source/timers.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/404212886/stream_buffer.o: ../src/third_party/rtos/FreeRTOS/Source/stream_buffer.c  .generated_files/flags/pic32ck_sg01_cult/d7a9cfcb4bcefc1fc60a2632d6b2cbb41a06404b .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/404212886" 
	@${RM} ${OBJECTDIR}/_ext/404212886/stream_buffer.o.d 
	@${RM} ${OBJECTDIR}/_ext/404212886/stream_buffer.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/404212886/stream_buffer.o.d" -o ${OBJECTDIR}/_ext/404212886/stream_buffer.o ../src/third_party/rtos/FreeRTOS/Source/stream_buffer.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/404212886/croutine.o: ../src/third_party/rtos/FreeRTOS/Source/croutine.c  .generated_files/flags/pic32ck_sg01_cult/827425d14dfa7005d8ec00572b4f8cb316eb060f .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/404212886" 
	@${RM} ${OBJECTDIR}/_ext/404212886/croutine.o.d 
	@${RM} ${OBJECTDIR}/_ext/404212886/croutine.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/404212886/croutine.o.d" -o ${OBJECTDIR}/_ext/404212886/croutine.o ../src/third_party/rtos/FreeRTOS/Source/croutine.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/404212886/event_groups.o: ../src/third_party/rtos/FreeRTOS/Source/event_groups.c  .generated_files/flags/pic32ck_sg01_cult/37b5bf729565e026c7b3234a7fff14747d733400 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/404212886" 
	@${RM} ${OBJECTDIR}/_ext/404212886/event_groups.o.d 
	@${RM} ${OBJECTDIR}/_ext/404212886/event_groups.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/404212886/event_groups.o.d" -o ${OBJECTDIR}/_ext/404212886/event_groups.o ../src/third_party/rtos/FreeRTOS/Source/event_groups.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1360937237/main.o: ../src/main.c  .generated_files/flags/pic32ck_sg01_cult/1e103bdf569fda2e4fe9f85f28e9fb84fe050186 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1360937237" 
	@${RM} ${OBJECTDIR}/_ext/1360937237/main.o.d 
	@${RM} ${OBJECTDIR}/_ext/1360937237/main.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1360937237/main.o.d" -o ${OBJECTDIR}/_ext/1360937237/main.o ../src/main.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1360937237/app_user_input_thread.o: ../src/app_user_input_thread.c  .generated_files/flags/pic32ck_sg01_cult/d04ba6dba2bbb10e1274156cb014bccccc9f23cc .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1360937237" 
	@${RM} ${OBJECTDIR}/_ext/1360937237/app_user_input_thread.o.d 
	@${RM} ${OBJECTDIR}/_ext/1360937237/app_user_input_thread.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1360937237/app_user_input_thread.o.d" -o ${OBJECTDIR}/_ext/1360937237/app_user_input_thread.o ../src/app_user_input_thread.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1360937237/app_sensor_thread.o: ../src/app_sensor_thread.c  .generated_files/flags/pic32ck_sg01_cult/1ec0caca5d2fe2e21e76a28b9bdbe797c81e8b8a .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1360937237" 
	@${RM} ${OBJECTDIR}/_ext/1360937237/app_sensor_thread.o.d 
	@${RM} ${OBJECTDIR}/_ext/1360937237/app_sensor_thread.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1360937237/app_sensor_thread.o.d" -o ${OBJECTDIR}/_ext/1360937237/app_sensor_thread.o ../src/app_sensor_thread.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1360937237/app_eeprom_thread.o: ../src/app_eeprom_thread.c  .generated_files/flags/pic32ck_sg01_cult/709665fa8a0c820f495a1655356046cf85cdcf29 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1360937237" 
	@${RM} ${OBJECTDIR}/_ext/1360937237/app_eeprom_thread.o.d 
	@${RM} ${OBJECTDIR}/_ext/1360937237/app_eeprom_thread.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -I"../../firmware_secure/src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/non_secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1360937237/app_eeprom_thread.o.d" -o ${OBJECTDIR}/_ext/1360937237/app_eeprom_thread.o ../src/app_eeprom_thread.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
endif

# ------------------------------------------------------------------------------------
# Rules for buildStep: compileCPP
ifeq ($(TYPE_IMAGE), DEBUG_RUN)
else
endif

# ------------------------------------------------------------------------------------
# Rules for buildStep: link
ifeq ($(TYPE_IMAGE), DEBUG_RUN)
${DISTDIR}/get_start_freertos_pic32ck_sg01_cult.X.${IMAGE_TYPE}.${OUTPUT_SUFFIX}: ${OBJECTFILES}  nbproject/Makefile-${CND_CONF}.mk    ../src/config/pic32ck_sg01_cult/PIC32CK2051SG01144.ld
	@${MKDIR} ${DISTDIR} 
	${MP_CC} $(MP_EXTRA_LD_PRE) -g   -mprocessor=$(MP_PROCESSOR_OPTION)  -mno-device-startup-code -o ${DISTDIR}/get_start_freertos_pic32ck_sg01_cult.X.${IMAGE_TYPE}.${OUTPUT_SUFFIX} ${OBJECTFILES_QUOTED_IF_SPACED}          -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -Wl,--defsym=__MPLAB_BUILD=1$(MP_EXTRA_LD_POST)$(MP_LINKER_FILE_OPTION),--defsym=__ICD2RAM=1,--defsym=__MPLAB_DEBUG=1,--defsym=__DEBUG=1,-D=__DEBUG_D,--defsym=_min_heap_size=512,--gc-sections,-L"./",-Map="${DISTDIR}/${PROJECTNAME}.${IMAGE_TYPE}.map",-DANS_SIZE=0x100000,-DNONSECURE,-DRNS_SIZE=0x40000,-DVECTOR_REGION=CODE_REGION,--memorysummary,${DISTDIR}/memoryfile.xml,-l:get_start_freertos_pic32ck_sg01_cult_secure_sg_veneer.lib -mdfp="${DFP_DIR}/PIC32CK-SG01"
	
else
${DISTDIR}/get_start_freertos_pic32ck_sg01_cult.X.${IMAGE_TYPE}.${OUTPUT_SUFFIX}: ${OBJECTFILES}  nbproject/Makefile-${CND_CONF}.mk   ../src/config/pic32ck_sg01_cult/PIC32CK2051SG01144.ld ../../firmware_secure/get_start_freertos_pic32ck_sg01_cult_secure.X/dist/pic32ck_sg01_cult/production/get_start_freertos_pic32ck_sg01_cult_secure.X.production.hex
	@${MKDIR} ${DISTDIR} 
	${MP_CC} $(MP_EXTRA_LD_PRE)  -mprocessor=$(MP_PROCESSOR_OPTION)  -mno-device-startup-code -o ${DISTDIR}/get_start_freertos_pic32ck_sg01_cult.X.${IMAGE_TYPE}.${DEBUGGABLE_SUFFIX} ${OBJECTFILES_QUOTED_IF_SPACED}          -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -Wl,--defsym=__MPLAB_BUILD=1$(MP_EXTRA_LD_POST)$(MP_LINKER_FILE_OPTION),--defsym=_min_heap_size=512,--gc-sections,-L"./",-Map="${DISTDIR}/${PROJECTNAME}.${IMAGE_TYPE}.map",-DANS_SIZE=0x100000,-DNONSECURE,-DRNS_SIZE=0x40000,-DVECTOR_REGION=CODE_REGION,--memorysummary,${DISTDIR}/memoryfile.xml,-l:get_start_freertos_pic32ck_sg01_cult_secure_sg_veneer.lib -mdfp="${DFP_DIR}/PIC32CK-SG01"
	${MP_CC_DIR}\\xc32-bin2hex ${DISTDIR}/get_start_freertos_pic32ck_sg01_cult.X.${IMAGE_TYPE}.${DEBUGGABLE_SUFFIX} 
	@echo "Creating unified hex file"
	@"C:/Program Files/Microchip/MPLABX/v6.25/mplab_platform/platform/../mplab_ide/modules/../../bin/hexmate" --edf="C:/Program Files/Microchip/MPLABX/v6.25/mplab_platform/platform/../mplab_ide/modules/../../dat/en_msgs.txt" ${DISTDIR}/get_start_freertos_pic32ck_sg01_cult.X.${IMAGE_TYPE}.hex ../../firmware_secure/get_start_freertos_pic32ck_sg01_cult_secure.X/dist/pic32ck_sg01_cult/production/get_start_freertos_pic32ck_sg01_cult_secure.X.production.hex -odist/${CND_CONF}/production/get_start_freertos_pic32ck_sg01_cult.X.production.unified.hex

endif


# Subprojects
.build-subprojects:
ifeq ($(TYPE_IMAGE), DEBUG_RUN)
	cd ../../firmware_secure/get_start_freertos_pic32ck_sg01_cult_secure.X && ${MAKE}  -f Makefile CONF=pic32ck_sg01_cult TYPE_IMAGE=DEBUG_RUN
else
	cd ../../firmware_secure/get_start_freertos_pic32ck_sg01_cult_secure.X && ${MAKE}  -f Makefile CONF=pic32ck_sg01_cult
endif


# Subprojects
.clean-subprojects:
	cd ../../firmware_secure/get_start_freertos_pic32ck_sg01_cult_secure.X && rm -rf "build/pic32ck_sg01_cult" "dist/pic32ck_sg01_cult"

# Clean Targets
.clean-conf: ${CLEAN_SUBPROJECTS}
	${RM} -r ${OBJECTDIR}
	${RM} -r ${DISTDIR}

# Enable dependency checking
.dep.inc: .depcheck-impl

DEPFILES=$(wildcard ${POSSIBLE_DEPFILES})
ifneq (${DEPFILES},)
include ${DEPFILES}
endif
