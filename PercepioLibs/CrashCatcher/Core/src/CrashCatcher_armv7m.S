/* Copyright (C) 2019  Adam Green (https://github.com/adamgreen)

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

#include "CrashCatcherPriv.h"

/* Implementation of ARMv7-M assembly language code to trap exceptions and call CrashCatcher_Entry(). */
    .text
    .syntax unified
    .arch armv7-m

    /* Called on fault exceptions. Stacks important registers and calls CrashCatcher_Entry(). */
    .global HardFault_Handler
    .type HardFault_Handler, %function

    .global DFM_Fault_Handler
    .type DFM_Fault_Handler, %function

HardFault_Handler:
DFM_Fault_Handler:

    /* Suspends stack supervision (MSPLIM) on Cortex-M33 and above, necessary
       since CrachCatcher moves SP to the internal CrashCatcher stack.
       This is compatible also with Cortex-M devices lacking PSPLIM and MSPLIM,
       since relying on CMSIS-Core register access functions that are defined
       for all core types and does nothing if registers are not available. */
    
    /* Restore MSPLIM if present (see dfmStackOverflowCheckSuspend call above) */
    push.w  {r12, lr} // Preserve lr, include r12 to keep 8 byte SP alignment
    bl dfmStackOverflowCheckSuspend
    pop.w  {r12, lr}
    
    /* Push the following onto the stack (see CrashCatcherExceptionRegisters structure). The g_crashCatcherStack buffer
       is reserved for use as the stack while CrashCatcher is running.
        msp
        psp
        exceptionPSR
        r4
        r5
        r6
        r7
        r8
        r9
        r10
        r11
        exceptionLR */
    mrs     r3, xpsr
    mrs     r2, psp
    mrs     r1, msp
    ldr     sp, =(g_crashCatcherStack + 4 * CRASH_CATCHER_STACK_WORD_COUNT)
    push.w  {r1-r11,lr}

    // Call CrashCatcher_Entry with first argument pointing to registers that were just stacked.
    mov     r0, sp
    bl      CrashCatcher_Entry

    // Only make it back here when CrashCatcher_DumpEnd() returns CRASH_CATCHER_EXIT to indicate that it would like
    // execution to be restored back to the faulting code (typically a hard coded breakpoint).
    // Restore non-volatile registers and SP to values they had upon entry to fault handler before resuming execution
    // at point of fault.
    pop.w   {r1-r11, lr}
    mov     sp, r1
    
    /* Restore MSPLIM if present (see dfmStackOverflowCheckSuspend call above) */
    push.w  {r12, lr} // Preserve lr, include r12 to keep 8 byte SP alignment
    bl dfmStackOverflowCheckResume
    pop.w   {r12, lr}
    bx      lr

    
    // Let assembler know that we have hit the end of the HardFault_Handler function.
    .pool
    .size   DFM_Fault_Handler, .-DFM_Fault_Handler



    /* Called from CrashCatcher core to copy all floating point registers to supplied buffer. The supplied buffer must
       be large enough to contain 33 32-bit values (S0-S31 & FPSCR).

        void CrashCatcher_CopyAllFloatingPointRegisters(uint32_t* pBuffer);
    */
    .global CrashCatcher_CopyAllFloatingPointRegisters
    .type CrashCatcher_CopyAllFloatingPointRegisters, %function
    .thumb_func
CrashCatcher_CopyAllFloatingPointRegisters:
#if CRASH_CATCHER_WITH_FPU
    // Grab a copy of FPSCR before issuing any other FP instructions.
    vmrs        r1, fpscr

    // Move s0 - s31 to pBuffer.
    vstmia.32   r0!, {s0 - s31}

    // Move fpscr to pBuffer.
    str         r1, [r0]
#endif
    // Return to caller.
    bx          lr

    .pool
    .size   CrashCatcher_CopyAllFloatingPointRegisters, .-CrashCatcher_CopyAllFloatingPointRegisters



    /* Called from CrashCatcher core to copy upper 16 floating point registers to supplied buffer. The supplied buffer
       must be large enough to contain 16 32-bit values (S16-S31).

        void CrashCatcher_CopyUpperFloatingPointRegisters(uint32_t* pBuffer);
    */
    .global CrashCatcher_CopyUpperFloatingPointRegisters
    .type CrashCatcher_CopyUpperFloatingPointRegisters, %function
    .thumb_func
CrashCatcher_CopyUpperFloatingPointRegisters:
#if CRASH_CATCHER_WITH_FPU
    // Move s16 - s31 to pBuffer.
    vstmia.32   r0!, {s16 - s31}
#endif
    // Return to caller.
    bx      lr

    .pool
    .size   CrashCatcher_CopyUpperFloatingPointRegisters, .-CrashCatcher_CopyUpperFloatingPointRegisters


    .end
