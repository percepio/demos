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
MKDIR=mkdir -p
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
MP_LINKER_FILE_OPTION=,--script="../src/config/pic32ck_sg01_cult/PIC32CK2051SG01144.ld"
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
${OBJECTDIR}/_ext/1518072025/plib_clock.o: ../src/config/pic32ck_sg01_cult/peripheral/clock/plib_clock.c  .generated_files/flags/pic32ck_sg01_cult/7811a0d948b4197d3dbc3f499ea9da36f5bca289 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1518072025" 
	@${RM} ${OBJECTDIR}/_ext/1518072025/plib_clock.o.d 
	@${RM} ${OBJECTDIR}/_ext/1518072025/plib_clock.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1518072025/plib_clock.o.d" -o ${OBJECTDIR}/_ext/1518072025/plib_clock.o ../src/config/pic32ck_sg01_cult/peripheral/clock/plib_clock.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/782314513/plib_cmcc.o: ../src/config/pic32ck_sg01_cult/peripheral/cmcc/plib_cmcc.c  .generated_files/flags/pic32ck_sg01_cult/a4d47bbcb88bbf046cddf05e6c645ad5ca91c47 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/782314513" 
	@${RM} ${OBJECTDIR}/_ext/782314513/plib_cmcc.o.d 
	@${RM} ${OBJECTDIR}/_ext/782314513/plib_cmcc.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/782314513/plib_cmcc.o.d" -o ${OBJECTDIR}/_ext/782314513/plib_cmcc.o ../src/config/pic32ck_sg01_cult/peripheral/cmcc/plib_cmcc.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1515922539/plib_evsys.o: ../src/config/pic32ck_sg01_cult/peripheral/evsys/plib_evsys.c  .generated_files/flags/pic32ck_sg01_cult/df4c3385ffc8a68f2e05a84d8f1795df9092e9fa .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1515922539" 
	@${RM} ${OBJECTDIR}/_ext/1515922539/plib_evsys.o.d 
	@${RM} ${OBJECTDIR}/_ext/1515922539/plib_evsys.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1515922539/plib_evsys.o.d" -o ${OBJECTDIR}/_ext/1515922539/plib_evsys.o ../src/config/pic32ck_sg01_cult/peripheral/evsys/plib_evsys.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/782651049/plib_nvic.o: ../src/config/pic32ck_sg01_cult/peripheral/nvic/plib_nvic.c  .generated_files/flags/pic32ck_sg01_cult/2299bcb27d8df77adb7d0df02a53133d7bb7e441 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/782651049" 
	@${RM} ${OBJECTDIR}/_ext/782651049/plib_nvic.o.d 
	@${RM} ${OBJECTDIR}/_ext/782651049/plib_nvic.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/782651049/plib_nvic.o.d" -o ${OBJECTDIR}/_ext/782651049/plib_nvic.o ../src/config/pic32ck_sg01_cult/peripheral/nvic/plib_nvic.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1760077436/plib_pm.o: ../src/config/pic32ck_sg01_cult/peripheral/pm/plib_pm.c  .generated_files/flags/pic32ck_sg01_cult/84bae49b8dd0f799ec305d6db0e40db662e20abd .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1760077436" 
	@${RM} ${OBJECTDIR}/_ext/1760077436/plib_pm.o.d 
	@${RM} ${OBJECTDIR}/_ext/1760077436/plib_pm.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1760077436/plib_pm.o.d" -o ${OBJECTDIR}/_ext/1760077436/plib_pm.o ../src/config/pic32ck_sg01_cult/peripheral/pm/plib_pm.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/782704200/plib_port.o: ../src/config/pic32ck_sg01_cult/peripheral/port/plib_port.c  .generated_files/flags/pic32ck_sg01_cult/f16add885a4b3443982bc5f52ab94e6b8a772171 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/782704200" 
	@${RM} ${OBJECTDIR}/_ext/782704200/plib_port.o.d 
	@${RM} ${OBJECTDIR}/_ext/782704200/plib_port.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/782704200/plib_port.o.d" -o ${OBJECTDIR}/_ext/782704200/plib_port.o ../src/config/pic32ck_sg01_cult/peripheral/port/plib_port.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1361970333/xc32_monitor.o: ../src/config/pic32ck_sg01_cult/stdio/xc32_monitor.c  .generated_files/flags/pic32ck_sg01_cult/f35c7b73f35e5ec2428867931358d4b711d34e47 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1361970333" 
	@${RM} ${OBJECTDIR}/_ext/1361970333/xc32_monitor.o.d 
	@${RM} ${OBJECTDIR}/_ext/1361970333/xc32_monitor.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1361970333/xc32_monitor.o.d" -o ${OBJECTDIR}/_ext/1361970333/xc32_monitor.o ../src/config/pic32ck_sg01_cult/stdio/xc32_monitor.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/interrupts.o: ../src/config/pic32ck_sg01_cult/interrupts.c  .generated_files/flags/pic32ck_sg01_cult/5faf7c11dade042e24dcee6cb3193903060e0b36 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/interrupts.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/interrupts.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/interrupts.o.d" -o ${OBJECTDIR}/_ext/461543203/interrupts.o ../src/config/pic32ck_sg01_cult/interrupts.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/libc_syscalls.o: ../src/config/pic32ck_sg01_cult/libc_syscalls.c  .generated_files/flags/pic32ck_sg01_cult/3ecdae489c484479596f1e33f3ce0b580508dfaf .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/libc_syscalls.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/libc_syscalls.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/libc_syscalls.o.d" -o ${OBJECTDIR}/_ext/461543203/libc_syscalls.o ../src/config/pic32ck_sg01_cult/libc_syscalls.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/initialization.o: ../src/config/pic32ck_sg01_cult/initialization.c  .generated_files/flags/pic32ck_sg01_cult/c9d8990346a349afd6f26d410a397e76e1ddeb01 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/initialization.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/initialization.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/initialization.o.d" -o ${OBJECTDIR}/_ext/461543203/initialization.o ../src/config/pic32ck_sg01_cult/initialization.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/exceptions.o: ../src/config/pic32ck_sg01_cult/exceptions.c  .generated_files/flags/pic32ck_sg01_cult/33044c8bdd8d6646e9446167c221da1090d6a637 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/exceptions.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/exceptions.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/exceptions.o.d" -o ${OBJECTDIR}/_ext/461543203/exceptions.o ../src/config/pic32ck_sg01_cult/exceptions.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/startup_xc32.o: ../src/config/pic32ck_sg01_cult/startup_xc32.c  .generated_files/flags/pic32ck_sg01_cult/485b679eae13c275a62e71e0ee1424eba5eb2344 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/startup_xc32.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/startup_xc32.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/startup_xc32.o.d" -o ${OBJECTDIR}/_ext/461543203/startup_xc32.o ../src/config/pic32ck_sg01_cult/startup_xc32.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1211494914/secure_context_port.o: ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_context_port.c  .generated_files/flags/pic32ck_sg01_cult/18e6bfa693e6a0230362fa39c9716f471c6b697c .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1211494914" 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_context_port.o.d 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_context_port.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1211494914/secure_context_port.o.d" -o ${OBJECTDIR}/_ext/1211494914/secure_context_port.o ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_context_port.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1211494914/secure_context.o: ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_context.c  .generated_files/flags/pic32ck_sg01_cult/60a3d4367192bdd78beb815739dd36d003f548d0 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1211494914" 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_context.o.d 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_context.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1211494914/secure_context.o.d" -o ${OBJECTDIR}/_ext/1211494914/secure_context.o ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_context.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1211494914/secure_init.o: ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_init.c  .generated_files/flags/pic32ck_sg01_cult/64c04f2b2c16e831bd9b729e0efafdea230a2ffd .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1211494914" 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_init.o.d 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_init.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1211494914/secure_init.o.d" -o ${OBJECTDIR}/_ext/1211494914/secure_init.o ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_init.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1211494914/secure_heap.o: ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_heap.c  .generated_files/flags/pic32ck_sg01_cult/960af98962c9ddaa6aedf8de82f31f814da83548 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1211494914" 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_heap.o.d 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_heap.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1211494914/secure_heap.o.d" -o ${OBJECTDIR}/_ext/1211494914/secure_heap.o ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_heap.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1903470166/nonsecure_entry.o: ../src/trustZone/nonsecure_entry.c  .generated_files/flags/pic32ck_sg01_cult/b35d196a4145977f71a9404e5bda05e423d5d487 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1903470166" 
	@${RM} ${OBJECTDIR}/_ext/1903470166/nonsecure_entry.o.d 
	@${RM} ${OBJECTDIR}/_ext/1903470166/nonsecure_entry.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1903470166/nonsecure_entry.o.d" -o ${OBJECTDIR}/_ext/1903470166/nonsecure_entry.o ../src/trustZone/nonsecure_entry.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1360937237/main.o: ../src/main.c  .generated_files/flags/pic32ck_sg01_cult/11b1daf9e19cb4aa984656d13db0854f8e93552f .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1360937237" 
	@${RM} ${OBJECTDIR}/_ext/1360937237/main.o.d 
	@${RM} ${OBJECTDIR}/_ext/1360937237/main.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1360937237/main.o.d" -o ${OBJECTDIR}/_ext/1360937237/main.o ../src/main.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
else
${OBJECTDIR}/_ext/1518072025/plib_clock.o: ../src/config/pic32ck_sg01_cult/peripheral/clock/plib_clock.c  .generated_files/flags/pic32ck_sg01_cult/22f9c64e8d9347ff8f1dfb01b82093672c19324a .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1518072025" 
	@${RM} ${OBJECTDIR}/_ext/1518072025/plib_clock.o.d 
	@${RM} ${OBJECTDIR}/_ext/1518072025/plib_clock.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1518072025/plib_clock.o.d" -o ${OBJECTDIR}/_ext/1518072025/plib_clock.o ../src/config/pic32ck_sg01_cult/peripheral/clock/plib_clock.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/782314513/plib_cmcc.o: ../src/config/pic32ck_sg01_cult/peripheral/cmcc/plib_cmcc.c  .generated_files/flags/pic32ck_sg01_cult/50693f810d14ecbd3e8d1ce25db71b7556d9223a .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/782314513" 
	@${RM} ${OBJECTDIR}/_ext/782314513/plib_cmcc.o.d 
	@${RM} ${OBJECTDIR}/_ext/782314513/plib_cmcc.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/782314513/plib_cmcc.o.d" -o ${OBJECTDIR}/_ext/782314513/plib_cmcc.o ../src/config/pic32ck_sg01_cult/peripheral/cmcc/plib_cmcc.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1515922539/plib_evsys.o: ../src/config/pic32ck_sg01_cult/peripheral/evsys/plib_evsys.c  .generated_files/flags/pic32ck_sg01_cult/4549f858476030ddd9803cf28d11414d27b98ea9 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1515922539" 
	@${RM} ${OBJECTDIR}/_ext/1515922539/plib_evsys.o.d 
	@${RM} ${OBJECTDIR}/_ext/1515922539/plib_evsys.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1515922539/plib_evsys.o.d" -o ${OBJECTDIR}/_ext/1515922539/plib_evsys.o ../src/config/pic32ck_sg01_cult/peripheral/evsys/plib_evsys.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/782651049/plib_nvic.o: ../src/config/pic32ck_sg01_cult/peripheral/nvic/plib_nvic.c  .generated_files/flags/pic32ck_sg01_cult/f52998aac65408a3535f84792c240ef2a0380464 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/782651049" 
	@${RM} ${OBJECTDIR}/_ext/782651049/plib_nvic.o.d 
	@${RM} ${OBJECTDIR}/_ext/782651049/plib_nvic.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/782651049/plib_nvic.o.d" -o ${OBJECTDIR}/_ext/782651049/plib_nvic.o ../src/config/pic32ck_sg01_cult/peripheral/nvic/plib_nvic.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1760077436/plib_pm.o: ../src/config/pic32ck_sg01_cult/peripheral/pm/plib_pm.c  .generated_files/flags/pic32ck_sg01_cult/9b1a8e4ca61a7d6e88d7b92e13e4ed9a62376cca .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1760077436" 
	@${RM} ${OBJECTDIR}/_ext/1760077436/plib_pm.o.d 
	@${RM} ${OBJECTDIR}/_ext/1760077436/plib_pm.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1760077436/plib_pm.o.d" -o ${OBJECTDIR}/_ext/1760077436/plib_pm.o ../src/config/pic32ck_sg01_cult/peripheral/pm/plib_pm.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/782704200/plib_port.o: ../src/config/pic32ck_sg01_cult/peripheral/port/plib_port.c  .generated_files/flags/pic32ck_sg01_cult/2dfe8337a6fbc86d9f4a3bf716ebba3981ec9879 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/782704200" 
	@${RM} ${OBJECTDIR}/_ext/782704200/plib_port.o.d 
	@${RM} ${OBJECTDIR}/_ext/782704200/plib_port.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/782704200/plib_port.o.d" -o ${OBJECTDIR}/_ext/782704200/plib_port.o ../src/config/pic32ck_sg01_cult/peripheral/port/plib_port.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1361970333/xc32_monitor.o: ../src/config/pic32ck_sg01_cult/stdio/xc32_monitor.c  .generated_files/flags/pic32ck_sg01_cult/22c7a49ec6a1726263a138882c339626ed76b12 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1361970333" 
	@${RM} ${OBJECTDIR}/_ext/1361970333/xc32_monitor.o.d 
	@${RM} ${OBJECTDIR}/_ext/1361970333/xc32_monitor.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1361970333/xc32_monitor.o.d" -o ${OBJECTDIR}/_ext/1361970333/xc32_monitor.o ../src/config/pic32ck_sg01_cult/stdio/xc32_monitor.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/interrupts.o: ../src/config/pic32ck_sg01_cult/interrupts.c  .generated_files/flags/pic32ck_sg01_cult/c0a75aadb207d6a484de0c0fe10189b6a9c66b4c .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/interrupts.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/interrupts.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/interrupts.o.d" -o ${OBJECTDIR}/_ext/461543203/interrupts.o ../src/config/pic32ck_sg01_cult/interrupts.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/libc_syscalls.o: ../src/config/pic32ck_sg01_cult/libc_syscalls.c  .generated_files/flags/pic32ck_sg01_cult/7e33eb2e3b96a6fac2fbd20a09edeaac79e659e1 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/libc_syscalls.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/libc_syscalls.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/libc_syscalls.o.d" -o ${OBJECTDIR}/_ext/461543203/libc_syscalls.o ../src/config/pic32ck_sg01_cult/libc_syscalls.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/initialization.o: ../src/config/pic32ck_sg01_cult/initialization.c  .generated_files/flags/pic32ck_sg01_cult/e4000c27faab8db618d2249327fb4f27a0fd40a3 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/initialization.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/initialization.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/initialization.o.d" -o ${OBJECTDIR}/_ext/461543203/initialization.o ../src/config/pic32ck_sg01_cult/initialization.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/exceptions.o: ../src/config/pic32ck_sg01_cult/exceptions.c  .generated_files/flags/pic32ck_sg01_cult/5e0deea1ad5c675f956bac881d0de11362ceeed9 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/exceptions.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/exceptions.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/exceptions.o.d" -o ${OBJECTDIR}/_ext/461543203/exceptions.o ../src/config/pic32ck_sg01_cult/exceptions.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/461543203/startup_xc32.o: ../src/config/pic32ck_sg01_cult/startup_xc32.c  .generated_files/flags/pic32ck_sg01_cult/8578979c927ae22abe1d34f6bcd7fce6c0b57a92 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/461543203" 
	@${RM} ${OBJECTDIR}/_ext/461543203/startup_xc32.o.d 
	@${RM} ${OBJECTDIR}/_ext/461543203/startup_xc32.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/461543203/startup_xc32.o.d" -o ${OBJECTDIR}/_ext/461543203/startup_xc32.o ../src/config/pic32ck_sg01_cult/startup_xc32.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1211494914/secure_context_port.o: ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_context_port.c  .generated_files/flags/pic32ck_sg01_cult/557681eabc388544d2eaa218bcfa7e75ae7d589b .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1211494914" 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_context_port.o.d 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_context_port.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1211494914/secure_context_port.o.d" -o ${OBJECTDIR}/_ext/1211494914/secure_context_port.o ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_context_port.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1211494914/secure_context.o: ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_context.c  .generated_files/flags/pic32ck_sg01_cult/fae12f12ab0545ce2051564f592aab1ec2edb8e0 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1211494914" 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_context.o.d 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_context.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1211494914/secure_context.o.d" -o ${OBJECTDIR}/_ext/1211494914/secure_context.o ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_context.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1211494914/secure_init.o: ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_init.c  .generated_files/flags/pic32ck_sg01_cult/79de723d78f8d6555c818169b050fbbd8fbc811 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1211494914" 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_init.o.d 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_init.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1211494914/secure_init.o.d" -o ${OBJECTDIR}/_ext/1211494914/secure_init.o ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_init.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1211494914/secure_heap.o: ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_heap.c  .generated_files/flags/pic32ck_sg01_cult/7787d37cc197270707f00db79e550ea02730d6c3 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1211494914" 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_heap.o.d 
	@${RM} ${OBJECTDIR}/_ext/1211494914/secure_heap.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1211494914/secure_heap.o.d" -o ${OBJECTDIR}/_ext/1211494914/secure_heap.o ../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure/secure_heap.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1903470166/nonsecure_entry.o: ../src/trustZone/nonsecure_entry.c  .generated_files/flags/pic32ck_sg01_cult/6af1969f089c176b4c27a0413bf487f3ce5bbcf5 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/_ext/1903470166" 
	@${RM} ${OBJECTDIR}/_ext/1903470166/nonsecure_entry.o.d 
	@${RM} ${OBJECTDIR}/_ext/1903470166/nonsecure_entry.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -ffunction-sections -fdata-sections -O1 -I"../src" -I"../src/config/pic32ck_sg01_cult" -I"../src/packs/CMSIS/" -I"../src/packs/CMSIS/CMSIS/Core/Include" -I"../src/packs/PIC32CK2051SG01144_DFP" -I"../src/third_party/rtos/FreeRTOS/Source/include" -I"../src/third_party/rtos/FreeRTOS/Source/portable/GCC/ARM_CM33/secure" -Werror -Wall -MP -MMD -MF "${OBJECTDIR}/_ext/1903470166/nonsecure_entry.o.d" -o ${OBJECTDIR}/_ext/1903470166/nonsecure_entry.o ../src/trustZone/nonsecure_entry.c    -DXPRJ_pic32ck_sg01_cult=$(CND_CONF)    $(COMPARISON_BUILD)  -mcmse -mdfp="${DFP_DIR}/PIC32CK-SG01" ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/_ext/1360937237/main.o: ../src/main.c  .generated_files/flags/pic32ck_sg01_cult/1412b321ec5b9e9c409f503cfdb0f7f88dca5df0 .generated_files/flags/pic32ck_sg01_cult/da39a3ee5e6b4b0d3255bfef95601890afd80709
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
	${MP_CC_DIR}/xc32-bin2hex ${DISTDIR}/get_start_freertos_pic32ck_sg01_cult_secure.X.${IMAGE_TYPE}.${DEBUGGABLE_SUFFIX} 
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
