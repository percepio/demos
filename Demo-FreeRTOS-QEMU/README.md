# Percepio FreeRTOS-demo för QEMU MPS2

Detta är ett fristående bare-metal-projekt för `mps2-an385`/Cortex-M3. Det
bygger den gemensamma demo-runnern i `../UsageExamples` direkt tillsammans med
TraceRecorder, DFM och CrashCatcher i `../PercepioLibs`. Zephyr, west, Kconfig
och devicetree används inte.

Projektet är verifierat på Windows med QEMU 10.0.2 och Zephyr SDK 1.0.1:s GCC
14.3.0. Alla projektspecifika filer ligger i denna katalog; inga filer i de två
gemensamma katalogerna ändras.

## Bygg och kör

Första konfigureringen hämtar den pinnade FreeRTOS-kärnan från GitHub och kräver
därför nätåtkomst. Efter det finns den i den ignorerade byggkatalogen.

```powershell
cmake --preset debug
cmake --build --preset debug
cmake --build --preset debug --target run
```

`run` startar QEMU i terminalen. Avsluta med Ctrl+C. DFM:s seriella cloud-port
skriver maskinläsbara alert-, trace- och core-dumpblock, så utskriften är stor
när alertdemona körs. ELF-filen blir
`build/debug/Demo-FreeRTOS-QEMU.elf` och länk-kartan blir
`build/debug/Demo-FreeRTOS-QEMU.map`.

Standardvägarna kan ändras utan att redigera projektet:

```powershell
$env:ARM_ZEPHYR_EABI_TOOLCHAIN_ROOT = 'D:\sdk\gnu\arm-zephyr-eabi'
cmake --preset debug -DUSAGE_EXAMPLES_DIR=D:\src\UsageExamples `
  -DPERCEPIO_LIBS_DIR=D:\src\PercepioLibs
```

QEMU-sökvägen kan skickas till `cmake/Invoke-Qemu.ps1` med parametern `-Qemu`.
Den lokala QEMU-binären behöver `C:\Program Files\Git\mingw64\bin` på `PATH`;
startskripten lägger till den katalogen om den finns.

## Debugga

Öppna denna katalog som workspace i VS Code, installera Cortex-Debug och välj
**FreeRTOS in QEMU (GDB)**. Flödet konfigurerar och bygger projektet, startar en
dold QEMU med `-S -gdb tcp::1234`, väntar på GDB-porten och ansluter
`arm-zephyr-eabi-gdb-py.exe`. Debugkonfigurationen speglar ZephyrDemo; endast
projektnamn och ELF-sökväg skiljer.

VS Code-taskarna ger två byggflöden:

- **CMake: clean build (debug)** är standard-build-tasken och körs med
  `Ctrl+Alt+B`.
- **CMake: build (debug)** är den normala inkrementella byggen och kan väljas
  med **Tasks: Run Task**.
- `F5` bygger inkrementellt, stoppar alltid en tidigare QEMU-instans för just
  projektet och startar sedan en ny instans innan GDB ansluts.

Både normal och clean build stoppar QEMU innan länkning. Debugservern kör
dessutom en separat `Demo-FreeRTOS-QEMU.qemu.elf`, så QEMU håller aldrig
byggmålets `Demo-FreeRTOS-QEMU.elf` låst på Windows.

Startskriptet sparar PID för just denna QEMU-instans i
`.vscode/qemu-gdb.pid`. Stoppskriptet verifierar både PID och executable-sökväg
innan processen avslutas; det använder inte global `taskkill`. Seriell output
hamnar i `qemu-gdb.log` via en QEMU `file`-chardev och QEMU-diagnostik i
`qemu-gdb.error.log`. Debug-QEMU använder avsiktligt inte `-serial stdio`:
annars ärver den VS Code-taskterminalens stdin och GDB-stubben kan sluta svara
när taskterminalen återanvänds.
En separat bakgrundstask följer samma loggfil och visar därför `printf`-utskriften
live i terminalen **QEMU: watch serial output**. Själva QEMU-starttasken är
fortfarande ändlig. Därmed kör VS Code alltid stop/start-flödet på nytt vid nästa
F5 i stället för att återanvända en gammal aktiv starttask.

Både vanlig körning och F5-debug använder
`-icount shift=6,align=on,sleep=on -rtc clock=vm`. Den viktiga skillnaden mot
Zephyr-demots tidigare `align=off` är att `align=on` synkroniserar den virtuella
klockan mot väggklockan. Därmed följer FreeRTOS-tick och `vTaskDelay()` verklig
tid i stället för att köras kraftigt för snabbt.

Manuell debugserver kan också köras i förgrunden:

```powershell
cmake --build --preset debug --target debugserver
```

## Versioner och ursprung

| Del | Version/revision | Hur den används |
| --- | --- | --- |
| FreeRTOS-Kernel | `V11.3.1` | Exakt tagg via CMake `FetchContent`; GCC-port `ARM_CM3`, heap 4 |
| TraceRecorder | `4.11.0` | Byggs direkt från `../PercepioLibs/TraceRecorder` |
| DFM | `2.1.0` | Byggs direkt från `../PercepioLibs/DFM` |
| CrashCatcher | repoets aktuella kopia | Byggs direkt från `../PercepioLibs/CrashCatcher` |
| UsageExamples och PercepioLibs | parent-revision `4f11ad191349c89a115c561c2b1e4e1928a00f98` vid verifieringen | Gemensam källkod, inte kopierad eller modifierad |
| MPS2-startup, länkarskript och CMSIS | FreeRTOS huvudrepo `f4fcc3b228643144727e9257ba12db1cb632b6e6` | Lokala donor-filer, licenstexter behållna |
| Verktyg | QEMU 10.0.2, GCC/GDB 14.3.0, CMake 4.4.2, Ninja 1.13.2 | Lokalt verifierad kombination |

Eftersom uppgiften uttryckligen kräver att `UsageExamples` och `PercepioLibs`
byggs direkt är deras parent-revision en reproducerbarhetsförutsättning, inte
ett beroende som CMake hämtar. Om parent-repot står på en annan revision bygger
projektet den kod som då ligger i syskonkatalogerna.

## Tekniska val och antaganden

- RAM följer MPS2-donatorn: `0x20000000`–`0x203fffff` (4 MiB). `.noinit` är en
  riktig `NOLOAD`-sektion och nollställs inte av `Reset_Handler`.
- Demoindex sparas med magic-värde i `.noinit`. QEMU 10.0.2 bevarar RAM vid
  `NVIC_SystemReset()`, även vid reset från fault handler, så ingen
  LM3S-specifik omstartslösning behövdes.
- Donatordemots SysTick-lösning provades först. DFM 2.1.0:s stopwatch kräver
  dock vid kompilering `TRC_FREE_RUNNING_32BIT_INCR`, medan SysTick-porten är en
  nedräknare. Därför används MPS2 TIMER0 som fri 32-bitars uppräknare (dess
  nedräknande värde inverteras). Timern kör utan interrupt; FreeRTOS behåller
  SysTick exklusivt som RTOS-tick.
- Den applikationsdefinierade timerporten använder Cortex-M `PRIMASK` för
  TraceRecorders korta kritiska sektioner. Det krävs eftersom trace-hookar körs
  från PendSV och FreeRTOS `taskENTER_CRITICAL()` medvetet assertar i exception
  context på ARM_CM3.
- RingBuffer-streamporten har 10 KiB buffert och overwrite-läge. DFM använder
  serial cloud-port och dummy storage-port; faktisk Detect Receiver/databas är
  utanför denna leverans.
- DFM/CrashCatcher får den verkliga MPS2-RAM-gränsen. Cortex-M3 saknar
  `MSPLIM`/`PSPLIM`, så dessa ARMv8-M-register representeras med noll/no-op i den
  lokala konfigurationen.
- Debugbygget använder `-O0 -g3 -fno-omit-frame-pointer` för användbara call
  stacks och `-fstack-protector-strong` för stackkorruptionsdemot.
- FreeRTOS heap 4 och både statisk och dynamisk allokering är aktiverade. Idle-
  taskens statiska minne tillhandahålls av plattformskoden; software timers är
  avstängda eftersom demona inte behöver dem.
- MPS2:s LAN9118 finns i maskinmodellen men används inte. QEMU kan därför skriva
  den ofarliga varningen `nic lan9118.0 has no peer` trots `-net none`.

## Verifiering 2026-09-15

- Standard-build-taskens clean build byggde om samtliga 68 steg utan varningar;
  efterföljande normal build rapporterade `ninja: no work to do`.
- Två debugstarter i följd ersatte den första QEMU-processen. Samma test
  passerade när PID-filen togs bort mellan starterna, vilket verifierar
  återställning via portägaren.
- SDK-GDB anslöt på port 1234, återställde målet och nådde `main`.
- Med `align=on` kom nästa demo efter cirka 6,0 sekunders väggklocketid, vilket
  omfattar `vTaskDelay(5000)` och den efterföljande `vTaskDelay(1000)`. Med
  tidigare `align=off` kom samma övergång efter mindre än en sekund.

## Tidigare fullständig demoverifiering 2026-09-14

Konfigurering och full build kördes med kommandona ovan. Resultatet var utan
kompilatorvarningar och hade följande storlek:

```text
text 72848, data 240, bss 169608, totalt 242696 byte
```

QEMU kördes med den beslutade 10.0.2-binären, `mps2-an385`, `cortex-m3` och
`-icount shift=6,align=off,sleep=on`. En filtrerad seriell logg visade följande
sammanhängande första varv:

```text
demo 0 -> demo 1 -> demo 2 -> demo 3
UsageFault 0x02000000 -> systemreset -> demo 4 -> demo 5
stackskydd -> systemreset -> demo 6 -> demo 7 -> demo 0
```

Kontrollerade observationer:

- Alla index 0–7 förekom i rätt ordning och runnern började därefter om på 0.
- Boot-meddelandet kom på nytt efter både fault- och stackskyddsreset, medan
  demoindex fortsatte på 4 respektive 6. Detta verifierar `.noinit` och reset.
- Demo 3 gav `DFM Alert: Fault exception, CFSR: 0x02000000` samt serialiserad
  `cc_coredump.dmp` och `dfm_trace.psfs`.
- Demo 4 gav `DFM Alert: arg1 < 0`; den är avsiktligt konfigurerad utan reset.
- Demo 5 gav `DFM Alert: Stack corruption detected` och fortsatte efter reset.
- Demo 6 skrev en monoton stopwatch-tabell med `ComputeTime` och genererade
  latency-alert.
- Demo 7 körde nominalfallet samt över- och underlastfallen. Loggen nådde
  `TaskMonitor example 3` och rapporterade nya alerts efter varje avvikelse.
- Ingen `FATAL:`-rad eller FreeRTOS-assert förekom i slutlig verifieringslogg.
- VS Code-start/stop-flödet provades separat: GDB anslöt på port 1234, såg
  `Reset_Handler` med symboler och stoppskriptet avslutade endast sparad PID.

Den kompletta DFM-testsviten, Detect Receiver och databasinläsning ingår inte,
i enlighet med uppgiftens avgränsning.
