/* Copyright (C) 2022  Adam Green (https://github.com/adamgreen)

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

/* Modified by Percepio AB */

#include <CrashCatcher.h>
#include "CrashCatcherPriv.h"
#include <string.h>


/* Test harness will define this value on 64-bit machine to provide upper 32-bits of pointer addresses. */
CRASH_CATCHER_TEST_WRITEABLE uint64_t g_crashCatcherTestBaseAddress;

/* The unit tests can point the core to a fake location for the SCB->CPUID register. */
CRASH_CATCHER_TEST_WRITEABLE uint32_t* g_pCrashCatcherCpuId = (uint32_t*)0xE000ED00;

/* The unit tests can point the core to a fake location for the fault status registers. */
CRASH_CATCHER_TEST_WRITEABLE FaultStatusRegisters* g_pCrashCatcherFaultStatusRegisters = (FaultStatusRegisters*)0xE000ED28;

/* The unit tests can point the core to a fake location for the Coprocessor Access Control Register. */
CRASH_CATCHER_TEST_WRITEABLE uint32_t* g_pCrashCatcherCoprocessorAccessControlRegister = (uint32_t*)0xE000ED88;


/* Fault handler will switch MSP to use this area as the stack while CrashCatcher code is running.
   NOTE: If you change the size of this buffer, it also needs to be changed in the HardFault_Handler (in
         FaultHandler_arm*.S) when initializing the stack pointer. */
uint32_t g_crashCatcherStack[CRASH_CATCHER_STACK_WORD_COUNT] __attribute__((aligned(8)));

/* Percepio: A fault exception from inside CrashCatcher can not be processed by CrashCatcher, since the fault
is then likely to repeat. This variable is used to detect faults occuring while CrashCatcher is active.
In that case, just the device is just reset without attempting to output anything.*/
static volatile uint32_t crashCatcherActive = 0;


typedef struct
{
    const CrashCatcherExceptionRegisters* pExceptionRegisters;
    CrashCatcherStackedRegisters*         pSP;
    uint32_t                              flags;
    CrashCatcherInfo                      info;
} Object;


static void resetOnReentry(void);
static Object initStackPointers(const CrashCatcherExceptionRegisters* pExceptionRegisters);
static uint32_t getAddressOfExceptionStack(const CrashCatcherExceptionRegisters* pExceptionRegisters);
static void* uint32AddressToPointer(uint32_t address);
static void advanceStackPointerToValueBeforeException(Object* pObject);
static int areFloatingPointRegistersAutoStacked(const Object* pObject);
static void initFloatingPointFlag(Object* pObject);
static int areFloatingPointCoprocessorsEnabled(void);
static void initIsBKPT(Object* pObject);
static int isBKPT(uint16_t instruction);
static uint8_t getBKPTValue(uint16_t instruction);
static int isBadPC();
static void setStackSentinel(void);
static void dumpSignature(void);
static void dumpFlags(const Object* pObject);
static void dumpR0toR3(const Object* pObject);
static void dumpR4toR11(const Object* pObject);
static void dumpR12(const Object* pObject);
static void dumpSP(const Object* pObject);
static void dumpLR_PC_PSR(const Object* pObject);
static void dumpMSPandPSPandExceptionPSR(const Object* pObject);
static void dumpFloatingPointRegisters(const Object* pObject);
static void dumpMemoryRegions(const CrashCatcherMemoryRegion* pRegion);
static void checkStackSentinelForStackOverflow(void);
static int isARMv6MDevice(void);
static void dumpFaultStatusRegisters(void);
static void advanceProgramCounterPastHardcodedBreakpoint(const Object* pObject);


void CrashCatcher_Entry(const CrashCatcherExceptionRegisters* pExceptionRegisters)
{
    Object object;

    /* Check before reading the exception frame or calling any dump callbacks. */
    if (crashCatcherActive != 0)
    {
        resetOnReentry();
    }

    crashCatcherActive = 1;

    object = initStackPointers(pExceptionRegisters);
    advanceStackPointerToValueBeforeException(&object);
    initFloatingPointFlag(&object);
    initIsBKPT(&object);

    do
    {
        setStackSentinel();
        CrashCatcher_DumpStart(&object.info);
        dumpSignature();
        dumpFlags(&object);
        dumpR0toR3(&object);
        dumpR4toR11(&object);
        dumpR12(&object);
        dumpSP(&object);
        dumpLR_PC_PSR(&object);
        dumpMSPandPSPandExceptionPSR(&object);
        if (object.flags & CRASH_CATCHER_FLAGS_FLOATING_POINT)
            dumpFloatingPointRegisters(&object);
        dumpMemoryRegions(CrashCatcher_GetMemoryRegions());
        if (!isARMv6MDevice())
            dumpFaultStatusRegisters();
        checkStackSentinelForStackOverflow();
    }
    while (CrashCatcher_DumpEnd() == CRASH_CATCHER_TRY_AGAIN);

    advanceProgramCounterPastHardcodedBreakpoint(&object);
    crashCatcherActive = 0;
}

/* resetOnReentry() is called on nested faults during CrashCatcher fault handling.
In this cas, just reset the device without attempting to output, since the fault
is likely to repeat otherwise.

From the Device Integration Guide:
"If no alert output is generated, or the device resets unexpectedly without
producing a complete DFM alert, this may indicate a processor fault occurring
inside DFM or CrashCatcher.
Such nested faults can occur due to integration issues. To avoid repeatedly
triggering the same fault, CrashCatcher detects if it is entered again before
the previous session has completed. In this case, it immediately resets the
device without generating further DFM output."

See Percepio-Detect-Device-Integration-Guide.pdf for guidance, found in the
device-integration folder of the Percepio Detect package.
*/

static void resetOnReentry(void)
{
    volatile uint32_t* const pAIRCR = (volatile uint32_t*)0xE000ED0C;

    /* Same sequence as CMSIS NVIC_SystemReset(), without output or callbacks.
     * Preserve PRIGROUP, supply VECTKEY, and set SYSRESETREQ. */
    __asm volatile ("dsb 0xf" : : : "memory");
    *pAIRCR = 0x05FA0004U | (*pAIRCR & 0x00000700U);
    __asm volatile ("dsb 0xf" : : : "memory");
    for (;;)
        __asm volatile ("nop");
}

static Object initStackPointers(const CrashCatcherExceptionRegisters* pExceptionRegisters)
{
    Object object;
    object.pExceptionRegisters = pExceptionRegisters;
    object.info.sp = getAddressOfExceptionStack(pExceptionRegisters);
    object.pSP = uint32AddressToPointer(object.info.sp);
    object.flags = 0;
    return object;
}

static uint32_t getAddressOfExceptionStack(const CrashCatcherExceptionRegisters* pExceptionRegisters)
{
    if (pExceptionRegisters->exceptionLR & LR_PSP)
        return pExceptionRegisters->psp;
    else
        return pExceptionRegisters->msp;
}

static void* uint32AddressToPointer(uint32_t address)
{
    if (sizeof(uint32_t*) == 8)
        return (void*)(unsigned long)((uint64_t)address | g_crashCatcherTestBaseAddress);
    else
        return (void*)(unsigned long)address;
}

static void advanceStackPointerToValueBeforeException(Object* pObject)
{
    /* Cortex-M processor always push 8 integer registers on the stack. */
    pObject->info.sp += 8 * sizeof(uint32_t);
    /* ARMv7-M processors can also push 16 single-precision floating point registers, FPSCR and a padding word. */
    if (areFloatingPointRegistersAutoStacked(pObject))
        pObject->info.sp += (16 + 1 + 1) * sizeof(uint32_t);
    /* Cortex-M processor may also have had to force 8-byte alignment before auto stacking registers. */
    pObject->info.sp |= (pObject->pSP->psr & PSR_STACK_ALIGN) ? 4 : 0;
    
    CC_DBG_LOG("advanceStackPointerToValueBeforeException\n");
    CC_DBG_LOG("  SP:     %08X\n", pObject->info.sp);
    
}

// Floating point support can be switched on and off.
// If switched off, no floating point registers are included.
#define USE_FP_SUPPORT 1

static int areFloatingPointRegistersAutoStacked(const Object* pObject)
{

#if (USE_FP_SUPPORT == 1)   
    int ret = (0 == (pObject->pExceptionRegisters->exceptionLR & LR_FLOAT));  
#else
    int ret = 0;
#endif
    
    CC_DBG_LOG("areFloatingPointRegistersAutoStacked: %d\n", ret);
    
    return ret;
}

static void initFloatingPointFlag(Object* pObject)
{
#if (USE_FP_SUPPORT == 1)     
    if (areFloatingPointCoprocessorsEnabled())
        pObject->flags |= CRASH_CATCHER_FLAGS_FLOATING_POINT;
#else
    pObject->flags = 0;
#endif    
}

static int areFloatingPointCoprocessorsEnabled(void)
{
    static const uint32_t coProcessor10and11EnabledBits = 5 << 20;
    uint32_t              coprocessorAccessControl = *g_pCrashCatcherCoprocessorAccessControlRegister;

    return (coprocessorAccessControl & (coProcessor10and11EnabledBits)) == coProcessor10and11EnabledBits;
}

static void initIsBKPT(Object* pObject)
{
    int wasBKPT = 0;
    uint8_t bkptNumber = 0;

    /* On ARMv7M, can use fault status registers to determine if bad PC was cause of fault before checking to see if
       it points to a BKPT instruction. */
    if (CRASH_CATCHER_ISBKPT_SUPPORT && (isARMv6MDevice() || !isBadPC()))
    {
        const uint16_t* pInstruction = uint32AddressToPointer(pObject->pSP->pc);
        uint16_t instruction = *pInstruction;
        wasBKPT = isBKPT(instruction);
        if (wasBKPT)
             bkptNumber = getBKPTValue(instruction);
    }
    pObject->info.isBKPT = wasBKPT;
    pObject->info.bkptNumber = bkptNumber;
}

static int isBKPT(uint16_t instruction)
{
    int ret = ((instruction & 0xFF00) == 0xBE00);    
    CC_DBG_LOG("isBKPT: %d\n", ret);
    return ret;
}

static uint8_t getBKPTValue(uint16_t instruction)
{
    return instruction & 0x00FF;
}

static int isBadPC()
{
    int ret;
    const uint32_t IACCVIOL = 1 << 0;
    const uint32_t IBUSERR = 1 << 8;
    const uint32_t badPCFaultBits = IACCVIOL | IBUSERR;

    ret = g_pCrashCatcherFaultStatusRegisters->CFSR & badPCFaultBits;
    
    CC_DBG_LOG("isBadPC: %d\n", ret);
    
    return ret;
}

static void setStackSentinel(void)
{
    g_crashCatcherStack[0] = CRASH_CATCHER_STACK_SENTINEL;
}

static void dumpSignature(void)
{
    static const uint8_t signature[4] = {CRASH_CATCHER_SIGNATURE_BYTE0,
                                         CRASH_CATCHER_SIGNATURE_BYTE1,
                                         CRASH_CATCHER_VERSION_MAJOR,
                                         CRASH_CATCHER_VERSION_MINOR};

    CC_DBG_LOG("dumpSignature\n");    
    CrashCatcher_DumpMemory(signature, CRASH_CATCHER_BYTE, sizeof(signature));
}

static void dumpFlags(const Object* pObject)
{
    CC_DBG_LOG("dumpFlags: %08X\n", pObject->flags);
    CrashCatcher_DumpMemory(&pObject->flags, CRASH_CATCHER_BYTE, sizeof(pObject->flags));
}

static void dumpR0toR3(const Object* pObject)
{
    CC_DBG_LOG("  R0: %08X\n", pObject->pSP->r0);
    CC_DBG_LOG("  R1: %08X\n", pObject->pSP->r1);
    CC_DBG_LOG("  R2: %08X\n", pObject->pSP->r2);
    CC_DBG_LOG("  R3: %08X\n", pObject->pSP->r3);
    
    CrashCatcher_DumpMemory(&pObject->pSP->r0, CRASH_CATCHER_BYTE, 4 * sizeof(uint32_t));
}

static void dumpR4toR11(const Object* pObject)
{
    CC_DBG_LOG("  R4: %08X\n", pObject->pExceptionRegisters->r4);
    CC_DBG_LOG("  R5: %08X\n", pObject->pExceptionRegisters->r5);
    CC_DBG_LOG("  R6: %08X\n", pObject->pExceptionRegisters->r6);
    CC_DBG_LOG("  R7: %08X\n", pObject->pExceptionRegisters->r7);
    CC_DBG_LOG("  R8: %08X\n", pObject->pExceptionRegisters->r8);
    CC_DBG_LOG("  R9: %08X\n", pObject->pExceptionRegisters->r9);
    CC_DBG_LOG("  R10: %08X\n", pObject->pExceptionRegisters->r10);
    CC_DBG_LOG("  R11: %08X\n", pObject->pExceptionRegisters->r11);
    CrashCatcher_DumpMemory(&pObject->pExceptionRegisters->r4, CRASH_CATCHER_BYTE, (11 - 4 + 1) * sizeof(uint32_t));
}

static void dumpR12(const Object* pObject)
{
    CC_DBG_LOG("  R12: %08X\n", pObject->pSP->r12);
    CrashCatcher_DumpMemory(&pObject->pSP->r12, CRASH_CATCHER_BYTE, sizeof(uint32_t));
}

static void dumpSP(const Object* pObject)
{
    CC_DBG_LOG("  SP: %08X\n", pObject->info.sp);
    CrashCatcher_DumpMemory(&pObject->info.sp, CRASH_CATCHER_BYTE, sizeof(uint32_t));
}

static void dumpLR_PC_PSR(const Object* pObject)
{
    CC_DBG_LOG("  LR: %08X\n", pObject->pSP->lr);
    CC_DBG_LOG("  PC: %08X\n", pObject->pSP->pc);
    CC_DBG_LOG("  PSR: %08X\n", pObject->pSP->psr);
    CrashCatcher_DumpMemory(&pObject->pSP->lr, CRASH_CATCHER_BYTE, 3 * sizeof(uint32_t));
}

static void dumpMSPandPSPandExceptionPSR(const Object* pObject)
{
    CC_DBG_LOG("  MSP: %08X\n", pObject->pExceptionRegisters->msp);
    CC_DBG_LOG("  PSP: %08X\n", pObject->pExceptionRegisters->psp);
    CC_DBG_LOG("  exPSR: %08X\n", pObject->pExceptionRegisters->exceptionPSR);
    
    CrashCatcher_DumpMemory(&pObject->pExceptionRegisters->msp, CRASH_CATCHER_BYTE, 3 * sizeof(uint32_t));
}

static void dumpFloatingPointRegisters(const Object* pObject)
{
    uint32_t allFloatingPointRegisters[32 + 1];
    
    CC_DBG_LOG("dumpFloatingPointRegisters:\n");
    
    if (areFloatingPointRegistersAutoStacked(pObject))
    {
        CC_DBG_LOG("  Auto-stacked float regs.\n");
        /* Copy the upper floats first as that will cause a lazy copy of the auto-stacked registers. */
        CrashCatcher_CopyUpperFloatingPointRegisters(&allFloatingPointRegisters[16]);
        memcpy(&allFloatingPointRegisters[0], &pObject->pSP->floats, sizeof(pObject->pSP->floats));
        allFloatingPointRegisters[32] = pObject->pSP->fpscr;
    }
    else
    {
        CC_DBG_LOG("  Copying all floats manually.\n");
        CrashCatcher_CopyAllFloatingPointRegisters(allFloatingPointRegisters);
    }
    CC_DBG_LOG("  Writing float regs to dump.\n");
    CrashCatcher_DumpMemory(allFloatingPointRegisters, CRASH_CATCHER_BYTE, sizeof(allFloatingPointRegisters));
}

static void dumpMemoryRegions(const CrashCatcherMemoryRegion* pRegion)
{
    while (pRegion && pRegion->startAddress != 0xFFFFFFFF)
    {
        CC_DBG_LOG("dumpMemoryRegions (addr):\n");
        /* Just dump the two addresses in pRegion.  The element size isn't required. */
        CrashCatcher_DumpMemory(pRegion, CRASH_CATCHER_BYTE, 2 * sizeof(uint32_t));
        
        int count = (pRegion->endAddress - pRegion->startAddress) / pRegion->elementSize;
        
        CC_DBG_LOG("dumpMemoryRegions (data):\n");
        CrashCatcher_DumpMemory(uint32AddressToPointer(pRegion->startAddress),
                                pRegion->elementSize,
                                count);
        pRegion++;
    }
}

static void checkStackSentinelForStackOverflow(void)
{
    if (g_crashCatcherStack[0] != CRASH_CATCHER_STACK_SENTINEL)
    {
        uint8_t value[4] = {0xAC, 0xCE, 0x55, 0xED};
        CC_DBG_LOG("Stack overflow detected. Writing marker:\n");
        CrashCatcher_DumpMemory(value, CRASH_CATCHER_BYTE, sizeof(value));
    }
    CC_DBG_LOG("No stack overflow detected.\n");
}

static int isARMv6MDevice(void)
{
    static const uint32_t armv6mArchitecture = 0xC << 16;
    uint32_t              cpuId = *g_pCrashCatcherCpuId;
    uint32_t              architecture = cpuId & (0xF << 16);

    int ret = (architecture == armv6mArchitecture);
    
    CC_DBG_LOG("Architecture: %d, isARMv6: %d\n", architecture, ret);
    
    return ret;
}

static void dumpFaultStatusRegisters(void)
{
    uint32_t                 faultStatusRegistersAddress = (uint32_t)(unsigned long)g_pCrashCatcherFaultStatusRegisters;
    
    CC_DBG_LOG("dumpFaultStatusRegisters:\n");
    
    CrashCatcherMemoryRegion faultStatusRegion[] = { {faultStatusRegistersAddress,
                                                      faultStatusRegistersAddress + sizeof(FaultStatusRegisters),
                                                      CRASH_CATCHER_WORD},
                                                     {0xFFFFFFFF, 0xFFFFFFFF, CRASH_CATCHER_BYTE} };
    dumpMemoryRegions(faultStatusRegion);
}

static void advanceProgramCounterPastHardcodedBreakpoint(const Object* pObject)
{
    CC_DBG_LOG("advanceProgramCounterPastHardcodedBreakpoint:\n");
    if (pObject->info.isBKPT)
    {
        pObject->pSP->pc += 2;
        CC_DBG_LOG("pObject->pSP->pc updated to: 0x%08X\n", pObject->pSP->pc);
    }else{
        CC_DBG_LOG("No breakpoint, no action.\n");
    }
        
}

/* Armv8-M Baseline has stack limit registers only in Secure state. */
#if defined(__ARM_ARCH) && (__ARM_ARCH >= 8) && \
    defined(__ARM_ARCH_PROFILE) && (__ARM_ARCH_PROFILE == 'M') && \
    ((__ARM_ARCH_ISA_THUMB >= 2) || \
     (defined(__ARM_FEATURE_CMSE) && (__ARM_FEATURE_CMSE >= 3)))

/* Keep these separate from DFM_TRAP's saved limits: it may suspend checking before entering CrashCatcher. */
static volatile uint32_t storedPSPLIM = 0;
static volatile uint32_t storedMSPLIM = 0;

static int isProcessStackActive(void)
{
    uint32_t ipsr;
    uint32_t control;

    __asm volatile ("mrs %0, ipsr" : "=r" (ipsr));
    if (ipsr != 0U)
        return 0; /* Handler mode always uses MSP, regardless of CONTROL.SPSEL. */

    __asm volatile ("mrs %0, control" : "=r" (control));
    return (control & (1U << 1)) != 0U;
}

/* Suspend the current stack's limit before the fault handler switches to g_crashCatcherStack. */
void stackLimitCheckSuspend(void)
{
    uint32_t limit;
    uint32_t disabledLimit = 0;

    if (isProcessStackActive())
    {
        __asm volatile ("mrs %0, psplim" : "=r" (limit));
        storedPSPLIM = limit;
        __asm volatile ("msr psplim, %0" : : "r" (disabledLimit) : "memory");
    }
    else
    {
        __asm volatile ("mrs %0, msplim" : "=r" (limit));
        storedMSPLIM = limit;
        __asm volatile ("msr msplim, %0" : : "r" (disabledLimit) : "memory");
    }
    __asm volatile ("isb" : : : "memory");
}

/* Called after the fault handler restores the original stack pointer. */
void stackLimitCheckResume(void)
{
    uint32_t limit;

    if (isProcessStackActive())
    {
        limit = storedPSPLIM;
        __asm volatile ("msr psplim, %0" : : "r" (limit) : "memory");
    }
    else
    {
        limit = storedMSPLIM;
        __asm volatile ("msr msplim, %0" : : "r" (limit) : "memory");
    }
    __asm volatile ("isb" : : : "memory");
}

#else

/* No accessible stack limit registers, e.g. Armv7-M. */
void stackLimitCheckSuspend(void)
{
}

void stackLimitCheckResume(void)
{
}

#endif
