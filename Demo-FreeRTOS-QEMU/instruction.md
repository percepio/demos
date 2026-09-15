# Plan för FreeRTOS-demot i QEMU

## Mål

Skapa ett fristående CMake/Ninja-projekt som kör Percepios demo-runner från
`C:\src\DemosRepo\UsageExamples` tillsammans med bibliotekskoden i
`C:\src\DemosRepo\PercepioLibs` ovanpå FreeRTOS, helt utan Zephyr-kod eller
Zephyrs byggsystem.

Projektet ska köras och kunna debugas i samma lokalt installerade QEMU 10.0.2
som används av Zephyr-demot. Den valda maskinmodellen är `mps2-an385`, som
liksom Zephyrs `lm3s6965evb` använder Cortex-M3. Kortmodell, minneskarta och
periferienheter skiljer sig, men QEMU-binären och den gemensamma Cortex-M3/NVIC-
och exceptionsemuleringen är desamma.

Första leveransen ska prioritera hela demo-runnern. Portning av Zephyrs DFM-
testsvit är en separat, senare fas och får inte blockera demot.

## Beslutad teknisk bas

- QEMU:
  `C:\Users\johan\zephyr-sdk-1.0.1\hosttools\qemu\qemu-system-arm.exe`
- QEMU-version: 10.0.2.
- Maskin: `mps2-an385`.
- CPU: `cortex-m3`.
- Kompilator och debugger kan tas från samma Zephyr SDK:
  `arm-zephyr-eabi-gcc` 14.3.0 och `arm-zephyr-eabi-gdb-py`.
  Verktygsnamnet innebär inte att Zephyr behöver användas eller länkas.
- Byggsystem: vanlig CMake och Ninja, utan `west`, Kconfig, devicetree eller
  `find_package(Zephyr)`.
- FreeRTOS: aktuell officiell FreeRTOS-Kernel med en exakt pinnad release eller
  commit. Använd den officiella GCC-porten `ARM_CM3`. Undvik en flytande
  `main`-referens och undvik att basera det nya projektet på repoets äldre
  FreeRTOS 10.3.1-kopia.
- CMSIS: filerna som hör till MPS2-demot kan återanvändas, alternativt hämtas
  från en exakt pinnad officiell CMSIS-version.

På Windows behöver QEMU-processens `PATH` även innehålla
`C:\Program Files\Git\mingw64\bin`, eftersom den lokala QEMU-binären använder
DLL-filer därifrån.

## Utgångspunkt: det officiella MPS2-demot

Använd FreeRTOS-demot `CORTEX_MPS2_QEMU_IAR_GCC` som donor och referens:

<https://github.com/FreeRTOS/FreeRTOS/tree/main/FreeRTOS/Demo/CORTEX_MPS2_QEMU_IAR_GCC>

Detta är en aktuell officiell demo som fortfarande finns i FreeRTOS huvudrepo
och byggs/körs i projektets CI. TraceRecorder-integrationen i demot är tidigare
gjord av Percepio och är därför en känd, relevant utgångspunkt.

Återanvänd eller anpassa följande delar:

- `build/gcc/startup_gcc.c`, inklusive vektortabell och tidig initiering.
- `build/gcc/mps2_m3.ld` som grund för minneslayouten.
- de nödvändiga filerna i demots `CMSIS`-katalog.
- UART-initiering och `printf`-retarget för MPS2.
- FreeRTOS-inställningarna och interruptkopplingen för Cortex-M3.
- TraceRecorders QEMU-anpassning, särskilt SysTick i stället för DWT.
- principen i `.vscode/launch.json` och `.vscode/tasks.json` för att starta
  QEMU och ansluta GDB på port 1234.

Ta inte med följande i det nya projektet:

- `main_blinky.c`, `main_full.c` eller FreeRTOS standarddemotester.
- Eclipse/IAR-projektfiler eller det gamla Makefile-bygget.
- den TraceRecorder-version som råkar ligga i FreeRTOS-demot. Använd i stället
  den aktuella koden under `PercepioLibs`.
- genererade binärer eller build-kataloger.

Behåll copyright- och licenstexter för filer som kopieras eller bearbetas.

## Föreslagen projektstruktur

```text
Demo-FreeRTOS-QEMU/
  CMakeLists.txt
  CMakePresets.json                 # valfritt men rekommenderat
  README.md
  .vscode/
    settings.json
    tasks.json
    launch.json
    Invoke-QemuGdbServer.ps1        # om robust processhantering behövs
  cmake/
    arm-zephyr-eabi-toolchain.cmake
  src/
    main.c
    startup_gcc.c
    platform_mps2.c
    stdio_uart.c
  include/
    main.h
    FreeRTOSConfig.h
  config/
    trcConfig.h
    trcKernelPortConfig.h
    dfmConfig.h
    dfmCrashCatcherConfig.h
  linker/
    mps2_m3.ld
  third_party/
    FreeRTOS-Kernel/                # submodul/vendor, eller pinnad FetchContent
    CMSIS_6/                        # om demots CMSIS-filer inte läggs lokalt
```

Filer kan slås ihop om projektet blir tydligare av det, men startup,
vektortabell, länkarskript och projektlokala konfigurationsfiler behövs även i
ett minimalt bare-metal-projekt.

## CMake-upplägg

CMake ska:

1. Bygga med `-mcpu=cortex-m3 -mthumb -mfloat-abi=soft`.
2. Använda MPS2-länkarskriptet och producera en ELF-fil med debugsymboler.
3. Länka FreeRTOS-kärnan och GCC-porten `ARM_CM3`.
4. Bygga relevanta delar av `PercepioLibs`:
   - TraceRecorder och dess FreeRTOS-kernelport,
   - DFM och dess FreeRTOS-kernelport,
   - CrashCatcher för ARMv7-M,
   - vald streamport och övriga stödfiler som demo-runnern behöver.
5. Bygga `UsageExamples/demo_app.c` och dess tillhörande demofiler.
6. Länka matematiksbiblioteket eftersom dataloggningsdemot använder `sin()`.
7. Använda projektets egna config-kataloger före standardkonfigurationerna i
   `PercepioLibs`.
8. Erbjuda mål som minst motsvarar `build`, `run` och `debugserver`.

Det är lämpligt att dela koden i separata CMake-targets, exempelvis
`freertos_kernel`, `percepio_trace`, `percepio_dfm`, `crashcatcher` och
`usage_examples`, innan slutlig länkning. Då blir inkluderingsvägar och
kompilationsdefinitioner begripliga och kontrollerbara.

## `main.c` och demo-runnern

`main.c` ska vara liten:

1. Utför endast den plattformsinitiering som behövs före applikationsstart.
2. Initiera UART/standardutmatning.
3. Anropa `demo_app()` från `UsageExamples`.

`UsageExamples/osal.h` har redan en FreeRTOS-gren med statiska tasks, mutexar
och köer samt start av schedulern. `UsageExamples/demo_app.c` initierar redan
TraceRecorder och DFM, skapar den statiska `DemoDriver`-tasken och startar
FreeRTOS. Samma kod används redan i repoets STM32- och PIC32-FreeRTOS-projekt.

Zephyr-demots befintliga `src/main.c` och `src/main.h` ska inte kopieras rakt
av, eftersom de innehåller Zephyr-specifika anrop som `printk`. Skapa ett litet
projektlokalt `main.h` som kopplar utskrift till MPS2-UART och vid behov till
TraceRecorders console channel.

## FreeRTOS-konfiguration

Utgå från MPS2-demots `FreeRTOSConfig.h`, men anpassa den till demo-runnerns
krav och den pinnade FreeRTOS-versionen. Följande behöver minst vara aktiverat:

```text
configSUPPORT_STATIC_ALLOCATION = 1
configUSE_TRACE_FACILITY = 1
configUSE_MUTEXES = 1
configNUM_THREAD_LOCAL_STORAGE_POINTERS >= 1
INCLUDE_vTaskDelete = 1
INCLUDE_vTaskDelay = 1
INCLUDE_vTaskDelayUntil = 1
```

`configMAX_PRIORITIES` måste vara högre än de prioriteter som `osal.h` använder;
MPS2-demots värde 9 räcker. FreeRTOS handlers för SVC, PendSV och SysTick ska
ligga på rätt positioner i vektortabellen. Om endast statisk allokering används
behövs callbacks som tillhandahåller minne åt idle-tasken och, om timers är
aktiverade, timer-tasken.

Inkludera den aktuella `trcRecorder.h` sist i `FreeRTOSConfig.h` så att
FreeRTOS-operationerna instrumenteras. Ställ in `trcKernelPortConfig.h` för den
aktuella FreeRTOS-kärnan; i befintliga `PercepioLibs` står den på 10.3.1 medan
den nya kärnan ska använda valet för FreeRTOS 11.1.0 eller senare.

## TraceRecorder-timestamps

QEMU-modellen ska inte använda Cortex-M3:s DWT cycle counter som
TraceRecorder-klocka. FreeRTOS MPS2-demot har redan den relevanta lösningen:

```text
TRC_CFG_HARDWARE_PORT = TRC_HARDWARE_PORT_ARM_Cortex_M
TRC_CFG_ARM_CM_USE_SYSTICK
```

Det anropar även `xTraceTimestampSetPeriod()` baserat på CPU- och tickfrekvens.
Återanvänd detta upplägg först. Verifiera sedan stopwatch- och task-monitor-
demon under QEMU. En separat MPS2-timer behövs bara om SysTick-lösningen visar
sig otillräcklig för demo-runnerns busy-wait eller tidsmätning.

## DFM och CrashCatcher

Använd projektlokala DFM-konfigurationer. De nuvarande generella config-filerna
i `PercepioLibs` innehåller STM32-header, STM32-specifik firmwareinformation och
en RAM-gräns för STM32L4 och kan därför inte användas oförändrade.

För MPS2-demots länkarskript är den primära RAM-regionen:

```text
0x20000000 ... 0x203fffff
```

Det ger 4 MiB RAM och RAM-slutet `0x20400000`. DFM:s CrashCatcher-konfiguration
och eventuella minnesfilter ska följa den verkliga länkade minneslayouten.

Vektortabellen ska koppla HardFault, MemManage, BusFault och UsageFault till
DFM/CrashCatcher enligt den befintliga integrationens krav. Bygg med
`-fstack-protector-strong` så att stackkorruptionsdemot verkligen utlöser det
avsedda förloppet. Kontrollera även att optimerings- och debugflaggorna ger
användbara call stacks i core dumps.

## Reset och byte till nästa demo

Demo-runnern använder avsiktliga krascher och behöver kunna starta nästa demo
efter att DFM har fångat felet. Börja med vanlig `NVIC_SystemReset()` på
`mps2-an385`.

I modern QEMU gör ARMv7-M/NVIC-modellen ett QEMU-systemreset vid `SYSRESETREQ`
när kortmodellen inte har kopplat signalen till en separat reset controller.
MPS2 ser ut att använda detta standardbeteende och kan därför slippa Zephyrs
LM3S-specifika software reboot.

Det måste verifieras på den exakta lokala QEMU 10.0.2-binären:

- reset från normalt task context,
- reset från fault/handler context,
- att QEMU-processen fortsätter att köra,
- att en `.noinit`-sektion bevaras,
- att demoindexet överlever och nästa demo startas,
- att DFM-data är färdigskriven före reset.

Länkarskriptet ska därför få en riktig `.noinit`-sektion som inte nollställs av
`Reset_Handler`.

Om den vanliga resetvägen inte fungerar ska relevanta delar av Zephyrs lösning
portas från:

```text
C:\src\DemosRepo\ZephyrDemo\src\qemu_reboot_workaround.c
C:\Users\johan\zephyrproject\zephyr\soc\ti\lm3s6965\sys_arch_reboot.c
C:\Users\johan\zephyrproject\zephyr\soc\ti\lm3s6965\reboot.S
```

Den lösningen lämnar Handler mode via en syntetisk exception return innan den
går till resetvektorn. `qemu_reboot_workaround.c` gör dessutom den tidiga
minnesnollningen stacklös för att en syntetisk reboot inte ska skriva över sin
egen aktiva stack. Detta är en fallback för MPS2, inte utgångsläget.

## QEMU-kommandon

Normal körning bör motsvara:

```text
qemu-system-arm.exe
  -machine mps2-an385
  -cpu cortex-m3
  -kernel <build>/Demo-FreeRTOS-QEMU.elf
  -monitor none
  -nographic
  -serial stdio
  -icount shift=6,align=on,sleep=on
  -rtc clock=vm
  -net none
```

Debugserver använder dessutom:

```text
-S -gdb tcp::1234
```

Använd `align=on` så att QEMU synkroniserar simulatorns virtuella klocka mot
väggklockan. Med Zephyr-körningens tidigare `align=off` går FreeRTOS-tick och
`vTaskDelay()` betydligt snabbare än verklig tid på denna maskin.

## VS Code

`.vscode` ska ge ett enkelt flöde:

1. Konfigurera CMake.
2. Bygg ELF-filen med Ninja.
3. Starta den lokala QEMU-binären med `-S -gdb tcp::1234`.
4. Vänta tills port 1234 är tillgänglig.
5. Anslut SDK:ns `arm-zephyr-eabi-gdb-py` via Cortex-Debug eller `cppdbg`.
6. Stoppa rätt QEMU-process när debugsessionen avslutas.

Använd inte globala `taskkill`-kommandon som kan avsluta andra QEMU-sessioner.
Om en PowerShell-launcher används bör den hålla reda på PID och loggfiler för
just denna körning.

## Demoernas förväntade portningsnivå

- Kernel tracing, data logging och state logging bör fungera när FreeRTOS,
  UART och TraceRecorder är igång.
- Crash alert, trap och stack corruption kräver korrekt vektortabell,
  CrashCatcher, stack protector och resetförlopp.
- Stopwatch kräver verifierad monoton tidsmätning.
- Task monitor kräver trace hooks, thread-local storage och FreeRTOS task-
  information.

Implementera och verifiera fallen stegvis, men behåll demo-runnerns befintliga
ordning och beteende så långt som möjligt.

## Senare fas: DFM-testsviten

Den befintliga testsviten är starkt knuten till Zephyr genom bland annat
`k_thread`, `k_sem`, `k_work`, `irq_offload`, `SYS_INIT`, `sys_reboot`, Zephyrs
stack-API och Python-runnerns anrop till `west`.

En framtida port bör delas upp så här:

1. Porta rena C-tester för call chains, crashes och minnesgränser.
2. Ersätt Zephyr tasks och semaforer med FreeRTOS-motsvarigheter.
3. Implementera en liten worker task/queue för `k_work`-liknande fall.
4. Implementera interrupt-offload med SVC eller ett pended IRQ.
5. Kör pre-kernel-fall explicit i bestämda startupfaser.
6. Anpassa tester vars förväntningar beror på Zephyrs scheduler- eller
   stacksemantik.
7. Ersätt `west`-runnern med CMake/Ninja och direkt QEMU-start samt tydliga
   variantdefinitioner.

Portning av testsviten ska inte göras förrän hela demo-runnern fungerar stabilt.

## Föreslagen genomförandeordning

1. Skapa CMake/toolchain och bygg ett minimalt MPS2-program.
2. Verifiera UART-utskrift i den lokala QEMU-binären.
3. Lägg till den pinnade FreeRTOS-kärnan och verifiera två enkla tasks.
4. Lägg till aktuell TraceRecorder från `PercepioLibs` och kontrollera trace.
5. Länka in `UsageExamples` och starta `demo_app()`.
6. Få demo 0–2 stabila.
7. Lägg till DFM och CrashCatcher.
8. Verifiera fault capture, `.noinit` och reset till nästa demo.
9. Verifiera demo-runnerns samtliga fall 0–7.
10. Färdigställ VS Code-flödet och dokumentera reproducerbar byggning.
11. Påbörja därefter eventuell portning av testsviten.

## Acceptanskriterier för demo-projektet

- Projektet konfigureras och byggs med CMake/Ninja utan Zephyr eller west.
- Alla externa beroenden är exakt versionspinnade.
- Samma lokala QEMU 10.0.2-binär används med `mps2-an385` och `cortex-m3`.
- UART-loggen visar att FreeRTOS-schedulern och demo-runnern kör.
- Aktuell kod används direkt från `UsageExamples` och `PercepioLibs`.
- TraceRecorder producerar korrekta FreeRTOS-händelser och användarhändelser.
- DFM/CrashCatcher fångar avsiktliga faults med användbara call stacks.
- Demoindex överlever reset och runnern fortsätter till nästa demo.
- Samtliga demofall 0–7 kör enligt avsedd sekvens.
- VS Code kan bygga, starta QEMU, ansluta GDB och avsluta endast sin egen
  QEMU-process.

## Ej del av första leveransen

- Zephyr-kod, west, devicetree eller Kconfig.
- Detect-databasladdning, Receiver eller Detect REST-verifiering.
- Full portning av Zephyrs DFM-testsvit.
- Stöd för verklig MPS2-hårdvara eller LM3S6965EVB.
- FreeRTOS nätverks-, filsystems- eller standarddemotester.

OBS: Ändra inga filer i PercepioLibs eller andra kataloger. Alla ändringar ska vara nya filer i denna katalog.
