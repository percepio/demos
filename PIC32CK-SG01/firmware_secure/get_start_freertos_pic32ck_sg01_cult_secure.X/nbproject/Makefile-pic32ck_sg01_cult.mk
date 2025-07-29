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
FINAL_IMAGE=${DISTDIR}/get_start_freertos_pic32ck_sg01_cult_secure.X.${IMAGE_TYPE}.${OUTPUT_SUFFIX}
else
IMAGE_TYPE=production
OUTPUT_SUFFIX=hex
DEBUGGABLE_SUFFIX=elf
FINAL_IMAGE=${DISTDIR}/get_start_freertos_pic32ck_sg01_cult_secure.X.${IMAGE_TYPE}.${OUTPUT_SUFFIX}
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
SOURCEFILES_QUOTED_IF_SPACED=../src/config/pic32ck_sg01_cult/peripheral/clock/plib_clock.c ../src/config/pic32ck_sg01_cult/peripheral/cmcc/plib_cmcc.c ../src/config/pic32ck_sg01_cult/peripheral/evsys/plib_evsys.c ../src/config/pic32ck_sg01_cult/peripheral/nvic/plib_nvic.c ../src/config/pic32ck_sg01_cult/peripheral/pm/plib_pm.c ../src/config/pic32ck_sg01_cult/peripheral/port/plib_port.c ../src/config/pic32ck_sg01_cult/stdio/xc32_monitor.c ../src/config/pic32ck_sg01_cult/interrupts.c ../src/config/pic32ck_sg01_cult/libc_syscalls.c ../src/config/pic32ck_sg01_cult/initialization.c ../src/config/pic32ck_sg01_cult/exceptions.c ../src/config/pic32ck_sg01_cult/startup_xc32.c ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_context_port.c ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_context.c ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_init.c ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_heap.c ../src/trustZone/nonsecure_entry.c ../src/main.c

# Object Files Quoted if spaced
OBJECTFILES_QUOTED_IF_SPACED=${OBJECTDIR}/_ext/1518072025/plib_clock.o ${OBJECTDIR}/_ext/782314513/plib_cmcc.o ${OBJECTDIR}/_ext/1515922539/plib_evsys.o ${OBJECTDIR}/_ext/782651049/plib_nvic.o ${OBJECTDIR}/_ext/1760077436/plib_pm.o ${OBJECTDIR}/_ext/782704200/plib_port.o ${OBJECTDIR}/_ext/1361970333/xc32_monitor.o ${OBJECTDIR}/_ext/461543203/interrupts.o ${OBJECTDIR}/_ext/461543203/libc_syscalls.o ${OBJECTDIR}/_ext/461543203/initialization.o ${OBJECTDIR}/_ext/461543203/exceptions.o ${OBJECTDIR}/_ext/461543203/startup_xc32.o ${OBJECTDIR}/_ext/1211494914/secure_context_port.o ${OBJECTDIR}/_ext/1211494914/secure_context.o ${OBJECTDIR}/_ext/1211494914/secure_init.o ${OBJECTDIR}/_ext/1211494914/secure_heap.o ${OBJECTDIR}/_ext/1903470166/nonsecure_entry.o ${OBJECTDIR}/_ext/1360937237/main.o
POSSIBLE_DEPFILES=${OBJECTDIR}/_ext/1518072025/plib_clock.o.d ${OBJECTDIR}/_ext/782314513/plib_cmcc.o.d ${OBJECTDIR}/_ext/1515922539/plib_evsys.o.d ${OBJECTDIR}/_ext/782651049/plib_nvic.o.d ${OBJECTDIR}/_ext/1760077436/plib_pm.o.d ${OBJECTDIR}/_ext/782704200/plib_port.o.d ${OBJECTDIR}/_ext/1361970333/xc32_monitor.o.d ${OBJECTDIR}/_ext/461543203/interrupts.o.d ${OBJECTDIR}/_ext/461543203/libc_syscalls.o.d ${OBJECTDIR}/_ext/461543203/initialization.o.d ${OBJECTDIR}/_ext/461543203/exceptions.o.d ${OBJECTDIR}/_ext/461543203/startup_xc32.o.d ${OBJECTDIR}/_ext/1211494914/secure_context_port.o.d ${OBJECTDIR}/_ext/1211494914/secure_context.o.d ${OBJECTDIR}/_ext/1211494914/secure_init.o.d ${OBJECTDIR}/_ext/1211494914/secure_heap.o.d ${OBJECTDIR}/_ext/1903470166/nonsecure_entry.o.d ${OBJECTDIR}/_ext/1360937237/main.o.d

# Object Files
OBJECTFILES=${OBJECTDIR}/_ext/1518072025/plib_clock.o ${OBJECTDIR}/_ext/782314513/plib_cmcc.o ${OBJECTDIR}/_ext/1515922539/plib_evsys.o ${OBJECTDIR}/_ext/782651049/plib_nvic.o ${OBJECTDIR}/_ext/1760077436/plib_pm.o ${OBJECTDIR}/_ext/782704200/plib_port.o ${OBJECTDIR}/_ext/1361970333/xc32_monitor.o ${OBJECTDIR}/_ext/461543203/interrupts.o ${OBJECTDIR}/_ext/461543203/libc_syscalls.o ${OBJECTDIR}/_ext/461543203/initialization.o ${OBJECTDIR}/_ext/461543203/exceptions.o ${OBJECTDIR}/_ext/461543203/startup_xc32.o ${OBJECTDIR}/_ext/1211494914/secure_context_port.o ${OBJECTDIR}/_ext/1211494914/secure_context.o ${OBJECTDIR}/_ext/1211494914/secure_init.o ${OBJECTDIR}/_ext/1211494914/secure_heap.o ${OBJECTDIR}/_ext/1903470166/nonsecure_entry.o ${OBJECTDIR}/_ext/1360937237/main.o

# Source Files
SOURCEFILES=../src/config/pic32ck_sg01_cult/peripheral/clock/plib_clock.c ../src/config/pic32ck_sg01_cult/peripheral/cmcc/plib_cmcc.c ../src/config/pic32ck_sg01_cult/peripheral/evsys/plib_evsys.c ../src/config/pic32ck_sg01_cult/peripheral/nvic/plib_nvic.c ../src/config/pic32ck_sg01_cult/peripheral/pm/plib_pm.c ../src/config/pic32ck_sg01_cult/peripheral/port/plib_port.c ../src/config/pic32ck_sg01_cult/stdio/xc32_monitor.c ../src/config/pic32ck_sg01_cult/interrupts.c ../src/config/pic32ck_sg01_cult/libc_syscalls.c ../src/config/pic32ck_sg01_cult/initialization.c ../src/config/pic32ck_sg01_cult/exceptions.c ../src/config/pic32ck_sg01_cult/startup_xc32.c ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_context_port.c ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_context.c ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_init.c ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_heap.c ../src/trustZone/nonsecure_entry.c ../src/main.c



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
	${MAKE}  -f nbproject/Makefile-pic32ck_sg01_cult.mk ${DISTDIR}/get_start_freertos_pic32ck_sg01_cult_secure.X.${IMAGE_TYPE}.${OUTPUT_SUFFIX}

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
${OBJECTDIR}/_ext/1518072025/plib_clock.o: ../src/config/pic32ck_sg01_cult/peripheral/clock/plib_clock.c  .generated_files/flags/pic32ck_sg01_cult/dcf9bb6d1b22c04e253501388aeb43cec68ca82b .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1518072025" 
	@${RM} ${OBJECTDIR}/_ext/1518072025/plib_clock.o.d 
	@${RM} ${OBJECTDIR}/_ext/1518072025/plib_clock.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1518072025/plib_clock.o.d" -o ${OBJECTDIR}/_ext/1518072025/plib_clock.o ../src/config/pic32ck_sg01_cult/peripheral/clock/plib_clock.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/782314513/plib_cmcc.o: ../src/config/pic32ck_sg01_cult/peripheral/cmcc/plib_cmcc.c  .generated_files/flags/pic32ck_sg01_cult/b7ce260e8b11abd91c6c3980f43d5f0388ebd971 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/782314513" 
	@${RM} ${OBJECTDIR}/_ext/782314513/plib_cmcc.o.d 
	@${RM} ${OBJECTDIR}/_ext/782314513/plib_cmcc.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/782314513/plib_cmcc.o.d" -o ${OBJECTDIR}/_ext/782314513/plib_cmcc.o ../src/config/pic32ck_sg01_cult/peripheral/cmcc/plib_cmcc.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1515922539/plib_evsys.o: ../src/config/pic32ck_sg01_cult/peripheral/evsys/plib_evsys.c  .generated_files/flags/pic32ck_sg01_cult/c65c233dc4f1ee4b5f4c48f27dd1d6050b8293fa .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1515922539" 
	@${RM} ${OBJECTDIR}/_ext/1515922539/plib_evsys.o.d 
	@${RM} ${OBJECTDIR}/_ext/1515922539/plib_evsys.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1515922539/plib_evsys.o.d" -o ${OBJECTDIR}/_ext/1515922539/plib_evsys.o ../src/config/pic32ck_sg01_cult/peripheral/evsys/plib_evsys.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/782651049/plib_nvic.o: ../src/config/pic32ck_sg01_cult/peripheral/nvic/plib_nvic.c  .generated_files/flags/pic32ck_sg01_cult/42e12973870d7b51f69abffff42be8da905d61 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/782651049" 
	@${RM} ${OBJECTDIR}/_ext/782651049/plib_nvic.o.d 
	@${RM} ${OBJECTDIR}/_ext/782651049/plib_nvic.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/782651049/plib_nvic.o.d" -o ${OBJECTDIR}/_ext/782651049/plib_nvic.o ../src/config/pic32ck_sg01_cult/peripheral/nvic/plib_nvic.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1760077436/plib_pm.o: ../src/config/pic32ck_sg01_cult/peripheral/pm/plib_pm.c  .generated_files/flags/pic32ck_sg01_cult/eab94ef25922069be2c92ad99f4664695ca90d03 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1760077436" 
	@${RM} ${OBJECTDIR}/_ext/1760077436/plib_pm.o.d 
	@${RM} ${OBJECTDIR}/_ext/1760077436/plib_pm.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1760077436/plib_pm.o.d" -o ${OBJECTDIR}/_ext/1760077436/plib_pm.o ../src/config/pic32ck_sg01_cult/peripheral/pm/plib_pm.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/782704200/plib_port.o: ../src/config/pic32ck_sg01_cult/peripheral/port/plib_port.c  .generated_files/flags/pic32ck_sg01_cult/72fea8d20b3f5178dd9367f9fd4fdb5c49445fac .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/782704200" 
	@${RM} ${OBJECTDIR}/_ext/782704200/plib_port.o.d 
	@${RM} ${OBJECTDIR}/_ext/782704200/plib_port.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/782704200/plib_port.o.d" -o ${OBJECTDIR}/_ext/782704200/plib_port.o ../src/config/pic32ck_sg01_cult/peripheral/port/plib_port.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1361970333/xc32_monitor.o: ../src/config/pic32ck_sg01_cult/stdio/xc32_monitor.c  .generated_files/flags/pic32ck_sg01_cult/8cad037db3729fb5e71fa2256c69ecd809052718 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1361970333" 
	@${RM} ${OBJECTDIR}/_ext/1361970333/xc32_monitor.o.d 
	@${RM} ${OBJECTDIR}/_ext/1361970333/xc32_monitor.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1361970333/xc32_monitor.o.d" -o ${OBJECTDIR}/_ext/1361970333/xc32_monitor.o ../src/config/pic32ck_sg01_cult/stdio/xc32_monitor.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/interrupts.o: ../src/config/pic32ck_sg01_cult/interrupts.c  .generated_files/flags/pic32ck_sg01_cult/b2cbdc73ffdedb665636aae0518179c252b595fb .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/interrupts.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/interrupts.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/interrupts.o.d" -o ${OBJECTDIR}/_ext/461543203/interrupts.o ../src/config/pic32ck_sg01_cult/interrupts.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/libc_syscalls.o: ../src/config/pic32ck_sg01_cult/libc_syscalls.c  .generated_files/flags/pic32ck_sg01_cult/5892485ea5530d17994eb6a496c8f306b66a1bdc .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/libc_syscalls.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/libc_syscalls.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/libc_syscalls.o.d" -o ${OBJECTDIR}/_ext/461543203/libc_syscalls.o ../src/config/pic32ck_sg01_cult/libc_syscalls.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/initialization.o: ../src/config/pic32ck_sg01_cult/initialization.c  .generated_files/flags/pic32ck_sg01_cult/3b10c4703f31344fd32e2a60fe9b2cd7f4112ef3 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/initialization.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/initialization.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/initialization.o.d" -o ${OBJECTDIR}/_ext/461543203/initialization.o ../src/config/pic32ck_sg01_cult/initialization.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/exceptions.o: ../src/config/pic32ck_sg01_cult/exceptions.c  .generated_files/flags/pic32ck_sg01_cult/7c21d52d98f38227204da635930c6caad2c8726a .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/exceptions.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/exceptions.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/exceptions.o.d" -o ${OBJECTDIR}/_ext/461543203/exceptions.o ../src/config/pic32ck_sg01_cult/exceptions.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/startup_xc32.o: ../src/config/pic32ck_sg01_cult/startup_xc32.c  .generated_files/flags/pic32ck_sg01_cult/97b77e105dc0b47f5801d4cb1719e1d4690f7a58 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/startup_xc32.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/startup_xc32.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/startup_xc32.o.d" -o ${OBJECTDIR}/_ext/461543203/startup_xc32.o ../src/config/pic32ck_sg01_cult/startup_xc32.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1211494914/secure_context_port.o: ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_context_port.c  .generated_files/flags/pic32ck_sg01_cult/aabf12a29276041217342e20878cacb1cd49de65 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1211494914" 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_context_port.o.d 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_context_port.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1211494914/secure_context_port.o.d" -o ${OBJECTDIR}/_ext/1211494914/secure_context_port.o ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_context_port.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1211494914/secure_context.o: ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_context.c  .generated_files/flags/pic32ck_sg01_cult/473170618f96e8535de5e81f9c3af3a8bba9b99a .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1211494914" 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_context.o.d 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_context.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1211494914/secure_context.o.d" -o ${OBJECTDIR}/_ext/1211494914/secure_context.o ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_context.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1211494914/secure_init.o: ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_init.c  .generated_files/flags/pic32ck_sg01_cult/9e6ca311f9c448d5ad9129ec001896290c7a90a8 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1211494914" 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_init.o.d 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_init.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1211494914/secure_init.o.d" -o ${OBJECTDIR}/_ext/1211494914/secure_init.o ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_init.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1211494914/secure_heap.o: ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_heap.c  .generated_files/flags/pic32ck_sg01_cult/402270b1a4d0f27c42a88065b3e51bcaca2c968d .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1211494914" 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_heap.o.d 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_heap.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1211494914/secure_heap.o.d" -o ${OBJECTDIR}/_ext/1211494914/secure_heap.o ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_heap.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1903470166/nonsecure_entry.o: ../src/trustZone/nonsecure_entry.c  .generated_files/flags/pic32ck_sg01_cult/c95340a0138973944178b17e5b6531b0a3660335 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1903470166" 
	@${RM} ${OBJECTDIR}/_ext/1903470166/nonsecure_entry.o.d 
	@${RM} ${OBJECTDIR}/_ext/1903470166/nonsecure_entry.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1903470166/nonsecure_entry.o.d" -o ${OBJECTDIR}/_ext/1903470166/nonsecure_entry.o ../src/trustZone/nonsecure_entry.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1360937237/main.o: ../src/main.c  .generated_files/flags/pic32ck_sg01_cult/c503402e11c470d3793e15fa6da8d3fa647c7168 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1360937237" 
	@${RM} ${OBJECTDIR}/_ext/1360937237/main.o.d 
	@${RM} ${OBJECTDIR}/_ext/1360937237/main.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1360937237/main.o.d" -o ${OBJECTDIR}/_ext/1360937237/main.o ../src/main.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
else
${OBJECTDIR}/_ext/1518072025/plib_clock.o: ../src/config/pic32ck_sg01_cult/peripheral/clock/plib_clock.c  .generated_files/flags/pic32ck_sg01_cult/2e1d8f120494c86942bbef3cc0cdca72434b5848 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1518072025" 
	@${RM} ${OBJECTDIR}/_ext/1518072025/plib_clock.o.d 
	@${RM} ${OBJECTDIR}/_ext/1518072025/plib_clock.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1518072025/plib_clock.o.d" -o ${OBJECTDIR}/_ext/1518072025/plib_clock.o ../src/config/pic32ck_sg01_cult/peripheral/clock/plib_clock.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/782314513/plib_cmcc.o: ../src/config/pic32ck_sg01_cult/peripheral/cmcc/plib_cmcc.c  .generated_files/flags/pic32ck_sg01_cult/afc4bb48cb7bdd2b91f118d824a445d605156c32 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/782314513" 
	@${RM} ${OBJECTDIR}/_ext/782314513/plib_cmcc.o.d 
	@${RM} ${OBJECTDIR}/_ext/782314513/plib_cmcc.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/782314513/plib_cmcc.o.d" -o ${OBJECTDIR}/_ext/782314513/plib_cmcc.o ../src/config/pic32ck_sg01_cult/peripheral/cmcc/plib_cmcc.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1515922539/plib_evsys.o: ../src/config/pic32ck_sg01_cult/peripheral/evsys/plib_evsys.c  .generated_files/flags/pic32ck_sg01_cult/bc82dc7c894479534d29b86c34a14e0989ddc418 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1515922539" 
	@${RM} ${OBJECTDIR}/_ext/1515922539/plib_evsys.o.d 
	@${RM} ${OBJECTDIR}/_ext/1515922539/plib_evsys.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1515922539/plib_evsys.o.d" -o ${OBJECTDIR}/_ext/1515922539/plib_evsys.o ../src/config/pic32ck_sg01_cult/peripheral/evsys/plib_evsys.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/782651049/plib_nvic.o: ../src/config/pic32ck_sg01_cult/peripheral/nvic/plib_nvic.c  .generated_files/flags/pic32ck_sg01_cult/623e1b161ead9c6e7066f2f822fba8d0f5c31422 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/782651049" 
	@${RM} ${OBJECTDIR}/_ext/782651049/plib_nvic.o.d 
	@${RM} ${OBJECTDIR}/_ext/782651049/plib_nvic.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/782651049/plib_nvic.o.d" -o ${OBJECTDIR}/_ext/782651049/plib_nvic.o ../src/config/pic32ck_sg01_cult/peripheral/nvic/plib_nvic.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1760077436/plib_pm.o: ../src/config/pic32ck_sg01_cult/peripheral/pm/plib_pm.c  .generated_files/flags/pic32ck_sg01_cult/c2c3a8daef38d8ba285a48c0299b9079a5aeef7b .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1760077436" 
	@${RM} ${OBJECTDIR}/_ext/1760077436/plib_pm.o.d 
	@${RM} ${OBJECTDIR}/_ext/1760077436/plib_pm.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1760077436/plib_pm.o.d" -o ${OBJECTDIR}/_ext/1760077436/plib_pm.o ../src/config/pic32ck_sg01_cult/peripheral/pm/plib_pm.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/782704200/plib_port.o: ../src/config/pic32ck_sg01_cult/peripheral/port/plib_port.c  .generated_files/flags/pic32ck_sg01_cult/a4c920cc99ef805ca1125f7d1ef074277c00bfc0 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/782704200" 
	@${RM} ${OBJECTDIR}/_ext/782704200/plib_port.o.d 
	@${RM} ${OBJECTDIR}/_ext/782704200/plib_port.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/782704200/plib_port.o.d" -o ${OBJECTDIR}/_ext/782704200/plib_port.o ../src/config/pic32ck_sg01_cult/peripheral/port/plib_port.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1361970333/xc32_monitor.o: ../src/config/pic32ck_sg01_cult/stdio/xc32_monitor.c  .generated_files/flags/pic32ck_sg01_cult/46da78c175342a90f6cadd7eebfe2acedca687bd .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1361970333" 
	@${RM} ${OBJECTDIR}/_ext/1361970333/xc32_monitor.o.d 
	@${RM} ${OBJECTDIR}/_ext/1361970333/xc32_monitor.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1361970333/xc32_monitor.o.d" -o ${OBJECTDIR}/_ext/1361970333/xc32_monitor.o ../src/config/pic32ck_sg01_cult/stdio/xc32_monitor.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/interrupts.o: ../src/config/pic32ck_sg01_cult/interrupts.c  .generated_files/flags/pic32ck_sg01_cult/b280616367cc4fb7e85d415b224ad431f56eb45a .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/interrupts.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/interrupts.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/interrupts.o.d" -o ${OBJECTDIR}/_ext/461543203/interrupts.o ../src/config/pic32ck_sg01_cult/interrupts.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/libc_syscalls.o: ../src/config/pic32ck_sg01_cult/libc_syscalls.c  .generated_files/flags/pic32ck_sg01_cult/50f6bca37e0d1373b7d28e70a4ec46313a5aa556 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/libc_syscalls.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/libc_syscalls.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/libc_syscalls.o.d" -o ${OBJECTDIR}/_ext/461543203/libc_syscalls.o ../src/config/pic32ck_sg01_cult/libc_syscalls.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/initialization.o: ../src/config/pic32ck_sg01_cult/initialization.c  .generated_files/flags/pic32ck_sg01_cult/eb4a990b683255815c03d6a6cf66e0aaa2d67456 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/initialization.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/initialization.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/initialization.o.d" -o ${OBJECTDIR}/_ext/461543203/initialization.o ../src/config/pic32ck_sg01_cult/initialization.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/exceptions.o: ../src/config/pic32ck_sg01_cult/exceptions.c  .generated_files/flags/pic32ck_sg01_cult/e0df4e2e5aa3677c17d09c43689bf6a06ad40020 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/exceptions.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/exceptions.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/exceptions.o.d" -o ${OBJECTDIR}/_ext/461543203/exceptions.o ../src/config/pic32ck_sg01_cult/exceptions.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/startup_xc32.o: ../src/config/pic32ck_sg01_cult/startup_xc32.c  .generated_files/flags/pic32ck_sg01_cult/62aee09ca0a069e0a5c4a161241b701c2d65611c .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/startup_xc32.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/startup_xc32.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/startup_xc32.o.d" -o ${OBJECTDIR}/_ext/461543203/startup_xc32.o ../src/config/pic32ck_sg01_cult/startup_xc32.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1211494914/secure_context_port.o: ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_context_port.c  .generated_files/flags/pic32ck_sg01_cult/90656ef257885ccc23cace3b9eb613f80b550513 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1211494914" 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_context_port.o.d 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_context_port.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1211494914/secure_context_port.o.d" -o ${OBJECTDIR}/_ext/1211494914/secure_context_port.o ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_context_port.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1211494914/secure_context.o: ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_context.c  .generated_files/flags/pic32ck_sg01_cult/1dc66412d8a6e9871c96d7b98a30863d7a0db0eb .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1211494914" 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_context.o.d 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_context.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1211494914/secure_context.o.d" -o ${OBJECTDIR}/_ext/1211494914/secure_context.o ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_context.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1211494914/secure_init.o: ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_init.c  .generated_files/flags/pic32ck_sg01_cult/47ce36d690e6fc9c92d79aa505aae36fb1e05a02 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1211494914" 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_init.o.d 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_init.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1211494914/secure_init.o.d" -o ${OBJECTDIR}/_ext/1211494914/secure_init.o ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_init.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1211494914/secure_heap.o: ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_heap.c  .generated_files/flags/pic32ck_sg01_cult/3bdf31d75b716522a60db8bff4e5a08e50dab6e2 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1211494914" 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_heap.o.d 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_heap.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1211494914/secure_heap.o.d" -o ${OBJECTDIR}/_ext/1211494914/secure_heap.o ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_heap.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1903470166/nonsecure_entry.o: ../src/trustZone/nonsecure_entry.c  .generated_files/flags/pic32ck_sg01_cult/6a403fb26fd2e281fa27019abf74e20c994b82a7 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1903470166" 
	@${RM} ${OBJECTDIR}/_ext/1903470166/nonsecure_entry.o.d 
	@${RM} ${OBJECTDIR}/_ext/1903470166/nonsecure_entry.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1903470166/nonsecure_entry.o.d" -o ${OBJECTDIR}/_ext/1903470166/nonsecure_entry.o ../src/trustZone/nonsecure_entry.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1360937237/main.o: ../src/main.c  .generated_files/flags/pic32ck_sg01_cult/7abad117d84f11f2a679ea384c1500c4a8b34187 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1360937237" 
	@${RM} ${OBJECTDIR}/_ext/1360937237/main.o.d 
	@${RM} ${OBJECTDIR}/_ext/1360937237/main.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1360937237/main.o.d" -o ${OBJECTDIR}/_ext/1360937237/main.o ../src/main.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
endif

# ------------------------------------------------------------------------------------
# Rules for buildStep: compileCPP
ifeq ($(TYPE_IMAGE), DEBUG_RUN)
else
endif

# ------------------------------------------------------------------------------------
# Rules for buildStep: link
ifeq ($(TYPE_IMAGE), DEBUG_RUN)
${DISTDIR}/get_start_freertos_pic32ck_sg01_cult_secure.X.${IMAGE_TYPE}.${OUTPUT_SUFFIX}: ${OBJECTFILES}  nbproject/Makefile-${CND_CONF}.mk    ../src/config/pic32ck_sg01_cult/PIC32CK2051SG01144.ld
	@${MKDIR} ${DISTDIR} 
	${MP_CC} $(MP_EXTRA_LD_PRE) -g   -mprocessor=$(MP_PROCESSOR_OPTION)  -o ${DISTDIR}/get_start_freertos_pic32ck_sg01_cult_secure.X.${IMAGE_TYPE}.${OUTPUT_SUFFIX} ${OBJECTFILES_QUOTED_IF_SPACED}          -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -Wl,--defsym=__MPLAB_BUILD=1$(MP_EXTRA_LD_POST)$(MP_LINKER_FILE_OPTION),--defsym=__ICD2RAM=1,--defsym=__MPLAB_DEBUG=1,--defsym=__DEBUG=1,-D=__DEBUG_D,--defsym=_min_heap_size=512,--gc-sections,-Map="${DISTDIR}/${PROJECTNAME}.${IMAGE_TYPE}.map",-DANSC_SIZE=0x1000,-DANS_SIZE=0x100000,-DBNSC_SIZE=0x0,-DRNS_SIZE=0x40000,-DSECURE,-DVECTOR_REGION=boot_rom,--memorysummary,${DISTDIR}/memoryfile.xml,,--cmse-implib,--out-implib=../../firmware/get_start_freertos_pic32ck_sg01_cult.X/get_start_freertos_pic32ck_sg01_cult_secure_sg_veneer.lib -mdfp="${DFP_DIR}/PIC32CK-SG01"
	
else
${DISTDIR}/get_start_freertos_pic32ck_sg01_cult_secure.X.${IMAGE_TYPE}.${OUTPUT_SUFFIX}: ${OBJECTFILES}  nbproject/Makefile-${CND_CONF}.mk   ../src/config/pic32ck_sg01_cult/PIC32CK2051SG01144.ld
	@${MKDIR} ${DISTDIR} 
	${MP_CC} $(MP_EXTRA_LD_PRE)  -mprocessor=$(MP_PROCESSOR_OPTION)  -o ${DISTDIR}/get_start_freertos_pic32ck_sg01_cult_secure.X.${IMAGE_TYPE}.${DEBUGGABLE_SUFFIX} ${OBJECTFILES_QUOTED_IF_SPACED}          -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -Wl,--defsym=__MPLAB_BUILD=1$(MP_EXTRA_LD_POST)$(MP_LINKER_FILE_OPTION),--defsym=_min_heap_size=512,--gc-sections,-Map="${DISTDIR}/${PROJECTNAME}.${IMAGE_TYPE}.map",-DANSC_SIZE=0x1000,-DANS_SIZE=0x100000,-DBNSC_SIZE=0x0,-DRNS_SIZE=0x40000,-DSECURE,-DVECTOR_REGION=boot_rom,--memorysummary,${DISTDIR}/memoryfile.xml,,--cmse-implib,--out-implib=../../firmware/get_start_freertos_pic32ck_sg01_cult.X/get_start_freertos_pic32ck_sg01_cult_secure_sg_veneer.lib -mdfp="${DFP_DIR}/PIC32CK-SG01"
	${MP_CC_DIR}\\xc32-bin2hex ${DISTDIR}/get_start_freertos_pic32ck_sg01_cult_secure.X.${IMAGE_TYPE}.${DEBUGGABLE_SUFFIX} 
endif


# Subprojects
.build-subprojects:


# Subprojects
.clean-subprojects:

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
