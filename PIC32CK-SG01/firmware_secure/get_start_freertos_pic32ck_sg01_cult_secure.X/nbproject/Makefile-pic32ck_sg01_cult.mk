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
${OBJECTDIR}/_ext/1518072025/plib_clock.o: ../src/config/pic32ck_sg01_cult/peripheral/clock/plib_clock.c  .generated_files/flags/pic32ck_sg01_cult/d140336e528da76069ba0f205072e505832424a8 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1518072025" 
	@${RM} ${OBJECTDIR}/_ext/1518072025/plib_clock.o.d 
	@${RM} ${OBJECTDIR}/_ext/1518072025/plib_clock.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG -D__MPLAB_DEBUGGER_PKOB4=1  -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1518072025/plib_clock.o.d" -o ${OBJECTDIR}/_ext/1518072025/plib_clock.o ../src/config/pic32ck_sg01_cult/peripheral/clock/plib_clock.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/782314513/plib_cmcc.o: ../src/config/pic32ck_sg01_cult/peripheral/cmcc/plib_cmcc.c  .generated_files/flags/pic32ck_sg01_cult/57065699248f342329b00b565e566b133acfbde6 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/782314513" 
	@${RM} ${OBJECTDIR}/_ext/782314513/plib_cmcc.o.d 
	@${RM} ${OBJECTDIR}/_ext/782314513/plib_cmcc.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG -D__MPLAB_DEBUGGER_PKOB4=1  -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/782314513/plib_cmcc.o.d" -o ${OBJECTDIR}/_ext/782314513/plib_cmcc.o ../src/config/pic32ck_sg01_cult/peripheral/cmcc/plib_cmcc.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1515922539/plib_evsys.o: ../src/config/pic32ck_sg01_cult/peripheral/evsys/plib_evsys.c  .generated_files/flags/pic32ck_sg01_cult/3764b75ee4fb7f9bbed22f50f5738474321c9ba .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1515922539" 
	@${RM} ${OBJECTDIR}/_ext/1515922539/plib_evsys.o.d 
	@${RM} ${OBJECTDIR}/_ext/1515922539/plib_evsys.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG -D__MPLAB_DEBUGGER_PKOB4=1  -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1515922539/plib_evsys.o.d" -o ${OBJECTDIR}/_ext/1515922539/plib_evsys.o ../src/config/pic32ck_sg01_cult/peripheral/evsys/plib_evsys.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/782651049/plib_nvic.o: ../src/config/pic32ck_sg01_cult/peripheral/nvic/plib_nvic.c  .generated_files/flags/pic32ck_sg01_cult/64f49bf504b73f0d37be89b7aeef6773e6e0fda7 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/782651049" 
	@${RM} ${OBJECTDIR}/_ext/782651049/plib_nvic.o.d 
	@${RM} ${OBJECTDIR}/_ext/782651049/plib_nvic.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG -D__MPLAB_DEBUGGER_PKOB4=1  -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/782651049/plib_nvic.o.d" -o ${OBJECTDIR}/_ext/782651049/plib_nvic.o ../src/config/pic32ck_sg01_cult/peripheral/nvic/plib_nvic.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1760077436/plib_pm.o: ../src/config/pic32ck_sg01_cult/peripheral/pm/plib_pm.c  .generated_files/flags/pic32ck_sg01_cult/36189591a2e8dee33751dd9e36ff57e3757731d1 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1760077436" 
	@${RM} ${OBJECTDIR}/_ext/1760077436/plib_pm.o.d 
	@${RM} ${OBJECTDIR}/_ext/1760077436/plib_pm.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG -D__MPLAB_DEBUGGER_PKOB4=1  -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1760077436/plib_pm.o.d" -o ${OBJECTDIR}/_ext/1760077436/plib_pm.o ../src/config/pic32ck_sg01_cult/peripheral/pm/plib_pm.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/782704200/plib_port.o: ../src/config/pic32ck_sg01_cult/peripheral/port/plib_port.c  .generated_files/flags/pic32ck_sg01_cult/303248929d45e8b986de816ac88c59d0efd0e3db .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/782704200" 
	@${RM} ${OBJECTDIR}/_ext/782704200/plib_port.o.d 
	@${RM} ${OBJECTDIR}/_ext/782704200/plib_port.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG -D__MPLAB_DEBUGGER_PKOB4=1  -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/782704200/plib_port.o.d" -o ${OBJECTDIR}/_ext/782704200/plib_port.o ../src/config/pic32ck_sg01_cult/peripheral/port/plib_port.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1361970333/xc32_monitor.o: ../src/config/pic32ck_sg01_cult/stdio/xc32_monitor.c  .generated_files/flags/pic32ck_sg01_cult/640258623384cb709be1c82519683723ad6ec543 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1361970333" 
	@${RM} ${OBJECTDIR}/_ext/1361970333/xc32_monitor.o.d 
	@${RM} ${OBJECTDIR}/_ext/1361970333/xc32_monitor.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG -D__MPLAB_DEBUGGER_PKOB4=1  -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1361970333/xc32_monitor.o.d" -o ${OBJECTDIR}/_ext/1361970333/xc32_monitor.o ../src/config/pic32ck_sg01_cult/stdio/xc32_monitor.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/interrupts.o: ../src/config/pic32ck_sg01_cult/interrupts.c  .generated_files/flags/pic32ck_sg01_cult/ae15e686603466ac4f337d518b938aed919046e2 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/interrupts.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/interrupts.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG -D__MPLAB_DEBUGGER_PKOB4=1  -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/interrupts.o.d" -o ${OBJECTDIR}/_ext/461543203/interrupts.o ../src/config/pic32ck_sg01_cult/interrupts.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/libc_syscalls.o: ../src/config/pic32ck_sg01_cult/libc_syscalls.c  .generated_files/flags/pic32ck_sg01_cult/af424a2cf28dab0efe8d2293ba9a3d0b5630e878 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/libc_syscalls.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/libc_syscalls.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG -D__MPLAB_DEBUGGER_PKOB4=1  -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/libc_syscalls.o.d" -o ${OBJECTDIR}/_ext/461543203/libc_syscalls.o ../src/config/pic32ck_sg01_cult/libc_syscalls.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/initialization.o: ../src/config/pic32ck_sg01_cult/initialization.c  .generated_files/flags/pic32ck_sg01_cult/2356267cfb854d381b7890ed0898517d10891608 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/initialization.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/initialization.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG -D__MPLAB_DEBUGGER_PKOB4=1  -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/initialization.o.d" -o ${OBJECTDIR}/_ext/461543203/initialization.o ../src/config/pic32ck_sg01_cult/initialization.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/exceptions.o: ../src/config/pic32ck_sg01_cult/exceptions.c  .generated_files/flags/pic32ck_sg01_cult/59755d2d4ab9ba42e86f2248472b614e45981b84 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/exceptions.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/exceptions.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG -D__MPLAB_DEBUGGER_PKOB4=1  -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/exceptions.o.d" -o ${OBJECTDIR}/_ext/461543203/exceptions.o ../src/config/pic32ck_sg01_cult/exceptions.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/startup_xc32.o: ../src/config/pic32ck_sg01_cult/startup_xc32.c  .generated_files/flags/pic32ck_sg01_cult/9272b50090c35eb7153fa282b703da81e663b480 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/startup_xc32.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/startup_xc32.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG -D__MPLAB_DEBUGGER_PKOB4=1  -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/startup_xc32.o.d" -o ${OBJECTDIR}/_ext/461543203/startup_xc32.o ../src/config/pic32ck_sg01_cult/startup_xc32.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1211494914/secure_context_port.o: ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_context_port.c  .generated_files/flags/pic32ck_sg01_cult/57d4dd24ef9a724f0c74da6444a00e94612174f2 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1211494914" 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_context_port.o.d 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_context_port.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG -D__MPLAB_DEBUGGER_PKOB4=1  -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1211494914/secure_context_port.o.d" -o ${OBJECTDIR}/_ext/1211494914/secure_context_port.o ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_context_port.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1211494914/secure_context.o: ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_context.c  .generated_files/flags/pic32ck_sg01_cult/c35faf673737e248855997e0e19d64aa65ab7c88 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1211494914" 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_context.o.d 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_context.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG -D__MPLAB_DEBUGGER_PKOB4=1  -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1211494914/secure_context.o.d" -o ${OBJECTDIR}/_ext/1211494914/secure_context.o ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_context.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1211494914/secure_init.o: ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_init.c  .generated_files/flags/pic32ck_sg01_cult/9a1afc3b8ae16a7b8de2b672c78ee5d6f646de48 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1211494914" 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_init.o.d 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_init.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG -D__MPLAB_DEBUGGER_PKOB4=1  -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1211494914/secure_init.o.d" -o ${OBJECTDIR}/_ext/1211494914/secure_init.o ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_init.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1211494914/secure_heap.o: ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_heap.c  .generated_files/flags/pic32ck_sg01_cult/fdc80761c0aa5aaeb0afedff72f2fee52ac19f4b .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1211494914" 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_heap.o.d 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_heap.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG -D__MPLAB_DEBUGGER_PKOB4=1  -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1211494914/secure_heap.o.d" -o ${OBJECTDIR}/_ext/1211494914/secure_heap.o ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_heap.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1903470166/nonsecure_entry.o: ../src/trustZone/nonsecure_entry.c  .generated_files/flags/pic32ck_sg01_cult/ab66413c38aac3052103e273483aa9f96f7c4e05 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1903470166" 
	@${RM} ${OBJECTDIR}/_ext/1903470166/nonsecure_entry.o.d 
	@${RM} ${OBJECTDIR}/_ext/1903470166/nonsecure_entry.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG -D__MPLAB_DEBUGGER_PKOB4=1  -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1903470166/nonsecure_entry.o.d" -o ${OBJECTDIR}/_ext/1903470166/nonsecure_entry.o ../src/trustZone/nonsecure_entry.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1360937237/main.o: ../src/main.c  .generated_files/flags/pic32ck_sg01_cult/febae79f80f47373b2420e0ef25386689c281f07 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1360937237" 
	@${RM} ${OBJECTDIR}/_ext/1360937237/main.o.d 
	@${RM} ${OBJECTDIR}/_ext/1360937237/main.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG -D__MPLAB_DEBUGGER_PKOB4=1  -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1360937237/main.o.d" -o ${OBJECTDIR}/_ext/1360937237/main.o ../src/main.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
else
${OBJECTDIR}/_ext/1518072025/plib_clock.o: ../src/config/pic32ck_sg01_cult/peripheral/clock/plib_clock.c  .generated_files/flags/pic32ck_sg01_cult/b5270e4d9456848b6ebaa91056828f2da422ed8 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1518072025" 
	@${RM} ${OBJECTDIR}/_ext/1518072025/plib_clock.o.d 
	@${RM} ${OBJECTDIR}/_ext/1518072025/plib_clock.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1518072025/plib_clock.o.d" -o ${OBJECTDIR}/_ext/1518072025/plib_clock.o ../src/config/pic32ck_sg01_cult/peripheral/clock/plib_clock.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/782314513/plib_cmcc.o: ../src/config/pic32ck_sg01_cult/peripheral/cmcc/plib_cmcc.c  .generated_files/flags/pic32ck_sg01_cult/70260524751329219a6175a5dd4519216339a016 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/782314513" 
	@${RM} ${OBJECTDIR}/_ext/782314513/plib_cmcc.o.d 
	@${RM} ${OBJECTDIR}/_ext/782314513/plib_cmcc.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/782314513/plib_cmcc.o.d" -o ${OBJECTDIR}/_ext/782314513/plib_cmcc.o ../src/config/pic32ck_sg01_cult/peripheral/cmcc/plib_cmcc.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1515922539/plib_evsys.o: ../src/config/pic32ck_sg01_cult/peripheral/evsys/plib_evsys.c  .generated_files/flags/pic32ck_sg01_cult/cad01816a6322885e91e3029231254a8d1daf5da .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1515922539" 
	@${RM} ${OBJECTDIR}/_ext/1515922539/plib_evsys.o.d 
	@${RM} ${OBJECTDIR}/_ext/1515922539/plib_evsys.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1515922539/plib_evsys.o.d" -o ${OBJECTDIR}/_ext/1515922539/plib_evsys.o ../src/config/pic32ck_sg01_cult/peripheral/evsys/plib_evsys.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/782651049/plib_nvic.o: ../src/config/pic32ck_sg01_cult/peripheral/nvic/plib_nvic.c  .generated_files/flags/pic32ck_sg01_cult/21844c1286b0f65d1f2cb332beee1638ede2f9ec .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/782651049" 
	@${RM} ${OBJECTDIR}/_ext/782651049/plib_nvic.o.d 
	@${RM} ${OBJECTDIR}/_ext/782651049/plib_nvic.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/782651049/plib_nvic.o.d" -o ${OBJECTDIR}/_ext/782651049/plib_nvic.o ../src/config/pic32ck_sg01_cult/peripheral/nvic/plib_nvic.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1760077436/plib_pm.o: ../src/config/pic32ck_sg01_cult/peripheral/pm/plib_pm.c  .generated_files/flags/pic32ck_sg01_cult/ed89eff237c264c9f5ac559b652fd3f435e3b67a .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1760077436" 
	@${RM} ${OBJECTDIR}/_ext/1760077436/plib_pm.o.d 
	@${RM} ${OBJECTDIR}/_ext/1760077436/plib_pm.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1760077436/plib_pm.o.d" -o ${OBJECTDIR}/_ext/1760077436/plib_pm.o ../src/config/pic32ck_sg01_cult/peripheral/pm/plib_pm.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/782704200/plib_port.o: ../src/config/pic32ck_sg01_cult/peripheral/port/plib_port.c  .generated_files/flags/pic32ck_sg01_cult/842ed1db548fca53296ab59bfb3239f309335a99 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/782704200" 
	@${RM} ${OBJECTDIR}/_ext/782704200/plib_port.o.d 
	@${RM} ${OBJECTDIR}/_ext/782704200/plib_port.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/782704200/plib_port.o.d" -o ${OBJECTDIR}/_ext/782704200/plib_port.o ../src/config/pic32ck_sg01_cult/peripheral/port/plib_port.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1361970333/xc32_monitor.o: ../src/config/pic32ck_sg01_cult/stdio/xc32_monitor.c  .generated_files/flags/pic32ck_sg01_cult/ee34c864d0e93ce61976490a51cd917a76af813f .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1361970333" 
	@${RM} ${OBJECTDIR}/_ext/1361970333/xc32_monitor.o.d 
	@${RM} ${OBJECTDIR}/_ext/1361970333/xc32_monitor.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1361970333/xc32_monitor.o.d" -o ${OBJECTDIR}/_ext/1361970333/xc32_monitor.o ../src/config/pic32ck_sg01_cult/stdio/xc32_monitor.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/interrupts.o: ../src/config/pic32ck_sg01_cult/interrupts.c  .generated_files/flags/pic32ck_sg01_cult/c2c519f29fef79b6db4baeac0c0c1096df13d800 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/interrupts.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/interrupts.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/interrupts.o.d" -o ${OBJECTDIR}/_ext/461543203/interrupts.o ../src/config/pic32ck_sg01_cult/interrupts.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/libc_syscalls.o: ../src/config/pic32ck_sg01_cult/libc_syscalls.c  .generated_files/flags/pic32ck_sg01_cult/454e49d407c68497f096727c2079606fec4a2211 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/libc_syscalls.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/libc_syscalls.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/libc_syscalls.o.d" -o ${OBJECTDIR}/_ext/461543203/libc_syscalls.o ../src/config/pic32ck_sg01_cult/libc_syscalls.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/initialization.o: ../src/config/pic32ck_sg01_cult/initialization.c  .generated_files/flags/pic32ck_sg01_cult/587d915bac989d3f4e233475a5b4e39d406790ea .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/initialization.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/initialization.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/initialization.o.d" -o ${OBJECTDIR}/_ext/461543203/initialization.o ../src/config/pic32ck_sg01_cult/initialization.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/exceptions.o: ../src/config/pic32ck_sg01_cult/exceptions.c  .generated_files/flags/pic32ck_sg01_cult/8d444d17cf0fd06eb9bf38be85d4a1705c549211 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/exceptions.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/exceptions.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/exceptions.o.d" -o ${OBJECTDIR}/_ext/461543203/exceptions.o ../src/config/pic32ck_sg01_cult/exceptions.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/startup_xc32.o: ../src/config/pic32ck_sg01_cult/startup_xc32.c  .generated_files/flags/pic32ck_sg01_cult/e2ca54be54582afc6cee50095bca65e34bb76e4d .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/startup_xc32.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/startup_xc32.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/startup_xc32.o.d" -o ${OBJECTDIR}/_ext/461543203/startup_xc32.o ../src/config/pic32ck_sg01_cult/startup_xc32.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1211494914/secure_context_port.o: ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_context_port.c  .generated_files/flags/pic32ck_sg01_cult/85d0e1175498e67f848c286095051049d5b7a14d .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1211494914" 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_context_port.o.d 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_context_port.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1211494914/secure_context_port.o.d" -o ${OBJECTDIR}/_ext/1211494914/secure_context_port.o ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_context_port.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1211494914/secure_context.o: ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_context.c  .generated_files/flags/pic32ck_sg01_cult/67a4da54bb0eed8b90fab1fced8e97df9589f20b .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1211494914" 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_context.o.d 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_context.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1211494914/secure_context.o.d" -o ${OBJECTDIR}/_ext/1211494914/secure_context.o ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_context.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1211494914/secure_init.o: ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_init.c  .generated_files/flags/pic32ck_sg01_cult/f1b0688b6476b01a358679337265a59e75bfcdea .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1211494914" 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_init.o.d 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_init.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1211494914/secure_init.o.d" -o ${OBJECTDIR}/_ext/1211494914/secure_init.o ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_init.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1211494914/secure_heap.o: ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_heap.c  .generated_files/flags/pic32ck_sg01_cult/7596b5eb2f2faa9c7f21559220b7e3b83643cffc .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1211494914" 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_heap.o.d 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_heap.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1211494914/secure_heap.o.d" -o ${OBJECTDIR}/_ext/1211494914/secure_heap.o ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_heap.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1903470166/nonsecure_entry.o: ../src/trustZone/nonsecure_entry.c  .generated_files/flags/pic32ck_sg01_cult/725b4026cf9b3bd64d3b2bc06490f7a6bc8b9a3e .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1903470166" 
	@${RM} ${OBJECTDIR}/_ext/1903470166/nonsecure_entry.o.d 
	@${RM} ${OBJECTDIR}/_ext/1903470166/nonsecure_entry.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1903470166/nonsecure_entry.o.d" -o ${OBJECTDIR}/_ext/1903470166/nonsecure_entry.o ../src/trustZone/nonsecure_entry.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1360937237/main.o: ../src/main.c  .generated_files/flags/pic32ck_sg01_cult/d5201d529feabcc842c45ad7e0dd76af3ea48124 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
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
	${MP_CC} $(MP_EXTRA_LD_PRE) -g  -D__MPLAB_DEBUGGER_PKOB4=1 -mprocessor=$(MP_PROCESSOR_OPTION)  -o ${DISTDIR}/get_start_freertos_pic32ck_sg01_cult_secure.X.${IMAGE_TYPE}.${OUTPUT_SUFFIX} ${OBJECTFILES_QUOTED_IF_SPACED}          -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -Wl,--defsym=__MPLAB_BUILD=1$(MP_EXTRA_LD_POST)$(MP_LINKER_FILE_OPTION),--defsym=__ICD2RAM=1,--defsym=__MPLAB_DEBUG=1,--defsym=__DEBUG=1,-D=__DEBUG_D,--defsym=__MPLAB_DEBUGGER_PKOB4=1,--defsym=_min_heap_size=512,--gc-sections,-Map="${DISTDIR}/${PROJECTNAME}.${IMAGE_TYPE}.map",-DANSC_SIZE=0x1000,-DANS_SIZE=0x100000,-DBNSC_SIZE=0x0,-DRNS_SIZE=0x40000,-DSECURE,-DVECTOR_REGION=boot_rom,--memorysummary,${DISTDIR}/memoryfile.xml,,--cmse-implib,--out-implib=../../firmware/get_start_freertos_pic32ck_sg01_cult.X/get_start_freertos_pic32ck_sg01_cult_secure_sg_veneer.lib -mdfp="${DFP_DIR}/PIC32CK-SG01"
	
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
