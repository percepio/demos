/*--------------------------------------------------------------------------
 * MPLAB XC32 Compiler -  PIC32CK2051SG01144 linker script
 * 
 * Copyright (c) 2024, Microchip Technology Inc. and its subsidiaries ("Microchip")
 * All rights reserved.
 * 
 * This software is developed by Microchip Technology Inc. and its
 * subsidiaries ("Microchip").
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are 
 * met:
 * 
 * 1.      Redistributions of source code must retain the above copyright
 *         notice, this list of conditions and the following disclaimer.
 * 2.      Redistributions in binary form must reproduce the above 
 *         copyright notice, this list of conditions and the following 
 *         disclaimer in the documentation and/or other materials provided 
 *         with the distribution.
 * 3.      Microchip's name may not be used to endorse or promote products
 *         derived from this software without specific prior written 
 *         permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY MICROCHIP "AS IS" AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR PURPOSE ARE DISCLAIMED. IN NO EVENT 
 * SHALL MICROCHIP BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING BUT NOT LIMITED TO
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWSOEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 */

OUTPUT_FORMAT("elf32-littlearm", "elf32-littlearm", "elf32-littlearm")
OUTPUT_ARCH(arm)
SEARCH_DIR(.)

/*
 *  Define the __XC32_RESET_HANDLER_NAME macro on the command line when you
 *  want to use a different name for the Reset Handler function.
 */
#ifndef __XC32_RESET_HANDLER_NAME
#define __XC32_RESET_HANDLER_NAME Reset_Handler
#endif /* __XC32_RESET_HANDLER_NAME */

/*  Set the entry point in the ELF file. Once the entry point is in the ELF
 *  file, you can then use the --write-sla option to xc32-bin2hex to place
 *  the address into the hex file using the SLA field (RECTYPE 5). This hex
 *  record may be useful for a bootloader that needs to determine the entry
 *  point to the application.
 */
ENTRY(__XC32_RESET_HANDLER_NAME)

/*************************************************************************
 * Memory-Region Macro Definitions
 * The XC32 linker preprocesses linker scripts. You may define these
 * macros in the MPLAB X project properties or on the command line when
 * calling the linker via the xc32-gcc shell.
 *************************************************************************/

#ifndef ROM_ORIGIN
#  define ROM_ORIGIN 0xc000000
#endif
#ifndef ROM_LENGTH
#  define ROM_LENGTH 0x200000
#elif (ROM_LENGTH > 0x200000)
#  error ROM_LENGTH is greater than the max size of 0x200000
#endif
#ifndef BOOT_ROM_ORIGIN
#  define BOOT_ROM_ORIGIN 0x8000000
#endif
#ifndef BOOT_ROM_LENGTH
#  define BOOT_ROM_LENGTH 0x20000
#elif (BOOT_ROM_LENGTH > 0x20000)
#  error BOOT_ROM_LENGTH is greater than the max size of 0x20000
#endif
#ifndef RAM_ORIGIN
#  define RAM_ORIGIN 0x20000000
#endif
#ifndef RAM_LENGTH
#  define RAM_LENGTH 0x80000
#elif (RAM_LENGTH > 0x80000)
#  error RAM_LENGTH is greater than the max size of 0x80000
#endif
#ifndef TCM_ORIGIN
#  define TCM_ORIGIN 0x0
#endif
#ifndef __XC32_TCM_LENGTH
#  define __XC32_TCM_LENGTH 0x0
#elif (defined(__XC32_TCM_LENGTH)  && __XC32_TCM_LENGTH != 0x0 && __XC32_TCM_LENGTH != 0x800 && __XC32_TCM_LENGTH != 0xc00 && __XC32_TCM_LENGTH != 0x1000)
#  warning Non-standard ITCM length, using default 0x1000
#  undef __XC32_TCM_LENGTH
#  define __XC32_TCM_LENGTH 0x1000
#endif



/*  Linker Macros controlling memory regions for TrustZone-M
 *
 *  Linking either the secure or non-secure application requires that the
 *  linker know the address and length of secure, non-secure, and non-secure
 *  callable memory regions. The following are the preprocessor definitions
 *  that are used to set and control memory zones for TrustZone when linking
 *  TrustZone applications. They are passed as -Wl,-DNAME[=value].
 *
 *  When building a secure application, the following preprocessor definitions
 *  affect this linker script.
 *
 *  + SECURE (required): Use the memory layout for a secure application.
 *  + ANS_SIZE=size (recommended): Defines the flash non-secure application 
 *    size, in bytes. Defaults to 50% of ROM if not provided.
 *  + ANSC_SIZE=size (recommended): Defines the flash application non-secure
 *    callable size, in bytes. Defaults to 0 if not provided.
 *
 *  When building a non-secure application, the following preprocessor
 *  definitions affect this linker script.
 *
 *  + NONSECURE (required): Use the memory layout for a non-secure application.
 *  + ANS_SIZE=size (recommended): Defines the flash non-secure application 
 *    size, in bytes. Defaults to 50% of ROM if not provided.
 *
 *  When building a secure bootloader, the following preprocessor
 *  definitions are used.
 *
 *  + SECURE_BOOTLOADER (required): Use the memory layout for a secure bootloader.
 *  + BNSC_SIZE=size (recommended): Defines the flash non-secure callable boot size
 *    in bytes. Defaults to 0 if not provided.
 *
 *  All application types can use the following macro.
 *
 *  + RNS_SIZE=size (recommended): Defines the size of non-secure RAM, in 
 *    bytes. Defaults to 50% of RAM if not provided.
 *
 *  In all cases, if a recommended value is not provided it will result in a warning
 *  message from the linker preprocessor.  It is advised to specify all the recommended
 *  macros for an application type to avoid any surprising results.
 *
 *  IMPORTANT: The memory region sizes must match those programmed in the device
 *  configuration bits in BOOTCFG and USERCFG.
 *  These can be set as configuration bits via #pragma config in the source code.
 *  If that is done, the values in the config bits must match up with the values in
 *  the linker scripts dictating the memory regions in order to facilitate proper
 *  operation. See the normal config pragma documentation for the names of the fields
 *  and values.
 *
 */

#if (defined(SECURE_BOOTLOADER) + defined(SECURE) + defined(NONSECURE)) > 1
#  error "Exactly one of SECURE, NONSECURE, or SECURE_BOOTLOADER must be defined."
#endif

#if (defined(SECURE_BOOTLOADER) + defined(SECURE) + defined(NONSECURE)) == 0
#  warning "Defaulting to a SECURE TrustZone-M project. Please define the linker macro SECURE, NONSECURE, or SECURE_BOOTLOADER (e.g. -Wl,-DSECURE)."
#  define SECURE
#endif

#if defined(SECURE) || defined(NONSECURE)
#  ifndef ANS_SIZE
#    warning "Non-Secure app length (ANS_SIZE) not specified (e.g. -Wl,-DANS_SIZE=size). Assuming half of ROM (0x100000 bytes)."
#    define ANS_SIZE 0x100000
#  endif
#endif

#if defined(SECURE_BOOTLOADER)
#  ifndef BNSC_SIZE
#    warning "Non-secure callable boot length (BNSC_SIZE) not specified (e.g. -Wl,-DBNSC_SIZE=size). Assuming 0 bytes."
#    define BNSC_SIZE 0x0
#  endif
#endif

#if defined(SECURE)
#  ifndef ANSC_SIZE
#    warning "Non-secure callable length (ANSC_SIZE) not specified (e.g. -Wl,-DANSC_SIZE=size). Assuming 0 bytes."
#    define ANSC_SIZE 0x0
#  endif
#endif

#ifndef RNS_SIZE
#  warning "Non-secure SRAM length (RNS_SIZE) not specified (e.g. -Wl,-DRNS_SIZE=size). Assuming half of SRAM (0x40000 bytes)."
#  define RNS_SIZE 0x40000
#endif

#if defined(SECURE_BOOTLOADER)
#  define _SECURE
#  define TZ_ROM_ORIGIN (BOOT_ROM_ORIGIN)
#  define TZ_ROM_LENGTH (BOOT_ROM_LENGTH - BNSC_SIZE)
#  define TZ_ROM_NSC_ORIGIN ((BOOT_ROM_ORIGIN + BOOT_ROM_LENGTH) - BNSC_SIZE)
#  define TZ_ROM_NSC_LENGTH (BNSC_SIZE)
#  define TZ_RAM_ORIGIN (RAM_ORIGIN)
#  define TZ_RAM_LENGTH (RAM_LENGTH - RNS_SIZE)
#elif defined(SECURE)
#  define _SECURE
#  define TZ_ROM_ORIGIN (ROM_ORIGIN)
#  define TZ_ROM_LENGTH (ROM_LENGTH - ANS_SIZE)
#  define TZ_ROM_NSC_ORIGIN ((ROM_ORIGIN + ROM_LENGTH - ANS_SIZE) - ANSC_SIZE)
#  define TZ_ROM_NSC_LENGTH (ANSC_SIZE)
#  define TZ_RAM_ORIGIN (RAM_ORIGIN)
#  define TZ_RAM_LENGTH (RAM_LENGTH - RNS_SIZE)
#elif defined(NONSECURE)
#  define TZ_ROM_ORIGIN (ROM_ORIGIN + ROM_LENGTH - ANS_SIZE)
#  define TZ_ROM_LENGTH (ANS_SIZE)
#  define TZ_RAM_ORIGIN (RAM_ORIGIN + RAM_LENGTH - RNS_SIZE)
#  define TZ_RAM_LENGTH (RNS_SIZE)
#endif
/*************************************************************************
 * Memory-Region Definitions
 * The MEMORY command describes the location and size of blocks of memory
 * on the target device. The command below uses the macros defined above.
 *************************************************************************/
MEMORY
{
#if !defined(SECURE_BOOTLOADER)
  boot_rom (LRX) : ORIGIN = BOOT_ROM_ORIGIN, LENGTH = BOOT_ROM_LENGTH
#endif
  rom (LRX) : ORIGIN = TZ_ROM_ORIGIN, LENGTH = TZ_ROM_LENGTH
#if defined(_SECURE)
  rom_nsc (LRX) : ORIGIN = TZ_ROM_NSC_ORIGIN, LENGTH = TZ_ROM_NSC_LENGTH
#endif
  ram (WX!R) : ORIGIN = TZ_RAM_ORIGIN, LENGTH = TZ_RAM_LENGTH
#if defined(_SECURE)
 tcm (WX) : ORIGIN = TCM_ORIGIN, LENGTH = __XC32_TCM_LENGTH
#endif

}
/*************************************************************************
 * Output region definitions.
 * CODE_REGION defines the output region for .text/.rodata.
 * DATA_REGION defines the output region for .data/.bss
 * VECTOR_REGION defines the output region for .vectors.
 * 
 * CODE_REGION defaults to 'rom', if rom is present (non-zero length),
 * and 'ram' otherwise.
 * N.B. The BFA will still allocate code to any MEMORY named 'rom' regardless
 * of CODE_REGION's value. If you wish to use rom for something else please
 * rename the MEMORY entry.
 * DATA_REGION defaults to 'ram', which must be present.
 */
#ifndef CODE_REGION
# if ROM_LENGTH > 0
#   define CODE_REGION rom
# else
#   define CODE_REGION ram
# endif
#endif
#ifndef DATA_REGION
# define DATA_REGION ram
#endif 
#ifndef VECTOR_REGION
# define VECTOR_REGION boot_rom
#endif

__rom_end = ORIGIN(rom) + LENGTH(rom);
#if defined(_SECURE)
__rom_nsc_end = ORIGIN(rom_nsc) + LENGTH(rom_nsc);
#endif /* defined(SECURE) */
__ram_end = ORIGIN(ram) + LENGTH(ram);

/*************************************************************************
 * Section Definitions - Map input sections to output sections
 *************************************************************************/
SECTIONS
{

    /*
     * The linker moves the .vectors section into itcm when itcm is
     * enabled via the -mitcm option, but only when this .vectors output
     * section exists in the linker script.
     */
    .vectors :
    {
        . = ALIGN(4);
        _sfixed = .;
        KEEP(*(.vectors .vectors.* .vectors_default .vectors_default.*))
        KEEP(*(.isr_vector))
        KEEP(*(.reset*))
        KEEP(*(.after_vectors))
    } > VECTOR_REGION
    /*
     * Code Sections - Note that standard input sections such as
     * *(.text), *(.text.*), *(.rodata), & *(.rodata.*)
     * are not mapped here. The best-fit allocator locates them,
     * so that input sections may flow around absolute sections
     * as needed.
     */
    .text :
    {
        . = ALIGN(4);
        *(.glue_7t) *(.glue_7)
       /* Force the inclusion of debug info for veneers. This is
        * sensitive to the name of the .o file containing the
        * cmse_nonsecure_entry functions. What are given are
        * common file names. */
       KEEP(*veneer.o(.text.*))
       KEEP(*nonsecure_entry.o(.text.*))
        *(.gnu.linkonce.r.*)
        *(.ARM.extab* .gnu.linkonce.armextab.*)

        /* Support C constructors, and C destructors in both user code
           and the C library. This also provides support for C++ code. */
        . = ALIGN(4);
        KEEP(*(.init))
        . = ALIGN(4);
        __preinit_array_start = .;
        KEEP (*(.preinit_array))
        __preinit_array_end = .;

        . = ALIGN(4);
        __init_array_start = .;
        KEEP (*(SORT(.init_array.*)))
        KEEP (*(.init_array))
        __init_array_end = .;

        . = ALIGN(0x4);
        KEEP (*crtbegin.o(.ctors))
        KEEP (*(EXCLUDE_FILE (*crtend.o) .ctors))
        KEEP (*(SORT(.ctors.*)))
        KEEP (*crtend.o(.ctors))

        . = ALIGN(4);
        KEEP(*(.fini))

        . = ALIGN(4);
        __fini_array_start = .;
        KEEP (*(.fini_array))
        KEEP (*(SORT(.fini_array.*)))
        __fini_array_end = .;

        KEEP (*crtbegin.o(.dtors))
        KEEP (*(EXCLUDE_FILE (*crtend.o) .dtors))
        KEEP (*(SORT(.dtors.*)))
        KEEP (*crtend.o(.dtors))

        . = ALIGN(4);
        _efixed = .;            /* End of text section */
    } > CODE_REGION

    /* .ARM.exidx is sorted, so has to go in its own output section.  */
    PROVIDE_HIDDEN (__exidx_start = .);
    .ARM.exidx :
    {
      *(.ARM.exidx* .gnu.linkonce.armexidx.*)
    } > CODE_REGION
    PROVIDE_HIDDEN (__exidx_end = .);

    . = ALIGN(4);
    _etext = .;

#if defined(_SECURE)
    /* Holds the veneers for calling into secure code. */
    . = ALIGN(4);
    .gnu.sgstubs : {
        _ssgstubs = .;
    } > rom_nsc
#endif /* defined(SECURE) */

    /*
     *  Align here to ensure that the .bss section occupies space up to
     *  _end.  Align after .bss to ensure correct alignment even if the
     *  .bss section disappears because there are no input sections.
     *
     *  Note that input sections named .bss* are no longer mapped here.
     *  The best-fit allocator locates them, so that they may flow
     *  around absolute sections as needed.
     */
  /*  .bss :
    {
        . = ALIGN(4);
        __bss_start__ = .;
        _sbss = . ;
        _szero = .;
        *(COMMON)
        . = ALIGN(4);
        __bss_end__ = .;
        _ebss = . ;
        _ezero = .;
    } > DATA_REGION*/

/* Modified linker section: force bss into LOAD to fix CrashDebug memory region error */
.bss :
{
    . = ALIGN(4);
    __bss_start__ = .;
    _sbss = .;
    _szero = .;
    *(COMMON)
    *(.bss*)
    *(.gnu.bss*)
    . = ALIGN(4);
    __bss_end__ = .;
    _ebss = .;
    _ezero = .;
} > DATA_REGION

    . = ALIGN(4);
    _end = . ;
    _ram_end_ = ORIGIN(ram) + LENGTH(ram) -1 ;
    
}

