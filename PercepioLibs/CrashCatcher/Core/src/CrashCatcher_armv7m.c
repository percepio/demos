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
#include <intrinsics.h>

extern void dfmStackOverflowCheckSuspend(void);
extern void dfmStackOverflowCheckResume(void);

__thumb void UsageFault_Handler(void) __attribute__((alias("HardFault_Handler")));

__thumb void DFM_Fault_Handler(void) __attribute__((alias("HardFault_Handler")));

/* Implementation of ARMv7-M assembly language code to trap exceptions and call CrashCatcher_Entry(). 
   Ported for IAR and updated for ARMv8-M (Cortex-M33) by Percepio. */

/* Called on Hard Fault exception.  Stacks important registers and calls CrashCatcher_Entry(). */
__thumb __stackless void HardFault_Handler(void)
{
      /* Suspends stack supervision (MSPLIM) on Cortex-M33 and above, necessary
       since CrachCatcher moves SP to the internal CrashCatcher stack.
       This is compatible also with Cortex-M devices lacking PSPLIM and MSPLIM,
       since relying on CMSIS-Core register access functions that are defined
       for all core types and does nothing if registers are not available. */
        
    __asm volatile("push.w  {r12, lr}"); // Preserve lr, include r12 to keep 8 byte SP alignment
    dfmStackOverflowCheckSuspend();
    __asm volatile("pop.w  {r12, lr}");
  
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
  __asm volatile("mrs      r3, xpsr" ::: "r3");
  __asm volatile("mrs      r2, psp" ::: "r2");
  __asm volatile("mrs      r1, msp" ::: "r1");
  __asm volatile("ldr.w    sp, =%c0" :: "i"((uint32_t) g_crashCatcherStack + 4 * CRASH_CATCHER_STACK_WORD_COUNT));
  __asm volatile("push.w   {r1-r11,lr}");

  // Call CrashCatcher_Entry with first argument pointing to registers that were just stacked.
  const CrashCatcherExceptionRegisters* pExceptionRegisters = (CrashCatcherExceptionRegisters*) __get_SP();
  CrashCatcher_Entry(pExceptionRegisters);

  // Only make it back here when CrashCatcher_DumpEnd() returns CRASH_CATCHER_EXIT to indicate that it would like
  // execution to be restored back to the faulting code (typically a hard coded breakpoint).
  // Restore non-volatile registers and SP to values they had upon entry to fault handler before resuming execution
  // at point of fault.
  __asm volatile("pop.w    {r1-r11,lr}");
  __asm volatile("mov      sp, r1");
  
  __asm volatile("push.w  {r12, lr}"); // Preserve lr, include r12 to keep 8 byte SP alignment
  dfmStackOverflowCheckResume();
  __asm volatile("pop.w  {r12, lr}");
  
}


/* Called from CrashCatcher core to copy all floating point registers to supplied buffer. The supplied buffer must
   be large enough to contain 33 32-bit values (S0-S31 & FPSCR).
*/
__thumb __stackless void
CrashCatcher_CopyAllFloatingPointRegisters(uint32_t* pBuffer)
{
#if CRASH_CATCHER_WITH_FPU
  // Grab a copy of FPSCR before issuing any other FP instructions.
  __asm volatile("vmrs        r1, fpscr");
  
  // Move s0 - s31 to pBuffer.
  __asm volatile("vstmia.32   r0!, {s0 - s31}");
  
  // Move fpscr to pBuffer.
  __asm volatile("str         r1, [r0]");
#endif
  // Return to caller.
}


    /* Called from CrashCatcher core to copy upper 16 floating point registers to supplied buffer. The supplied buffer
       must be large enough to contain 16 32-bit values (S16-S31).
    */
__thumb __stackless void
CrashCatcher_CopyUpperFloatingPointRegisters(uint32_t* pBuffer)
{
#if CRASH_CATCHER_WITH_FPU
  // Move s16 - s31 to pBuffer.
  __asm volatile("vstmia.32   r0!, {s16 - s31}");
#endif
  // Return to caller.
}
