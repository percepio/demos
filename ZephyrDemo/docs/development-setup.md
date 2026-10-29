# Development workflow and validation

This adapts the FreeRTOS demo workflow from commits `38a87d2` (2026-10-27) and
`a6602bf` (2026-10-28), following its development setup guide. The shared UX is
install / open workspace / review settings / F5 / view results, with incremental
F5 builds and explicit pristine builds under Ctrl+Shift+B.

## File responsibilities

| File | Responsibility |
| --- | --- |
| `.vscode/settings.json` | Reviewed local tool paths, Zephyr environment and configuration profile |
| `.vscode/tasks.json` | Direct process calls to the configured Python's `west`; no shell quoting or fixed parallelism |
| `.vscode/launch.json` | Board-specific ELF, pre-launch build, native QEMU/OpenOCD ownership and source mapping |
| `.vscode/c_cpp_properties.json` | Compile database for the selected navigation board/source/profile |
| `ZephyrDemo.code-workspace` | Named application root plus shared library/example roots |
| `CMakeLists.txt`, `modules/percepio` | Existing Zephyr module and local/upstream integration |
| `cmake/qemu-cortex-m3.cmake` | Logged terminal targets only for `qemu_cortex_m3` |
| `scripts/normalize_qemu_log.py` | Normalize repeated CRs in the completed QEMU text log, without changing other bytes |
| `boards/support/b_u585i_iot02a.cfg` | ST OpenOCD board configuration respecting the debugger-assigned GDB port |

The obsolete second workspace file and PowerShell start/stop wrapper are removed.
F5 has no PID files, port polling or global process kills. Its post-debug task
only normalizes the text log, without managing any processes.
The extension owns its server and assigns the GDB port. Terminal-only
`debugserver_logged` binds `127.0.0.1:1234`; F5 uses Cortex-Debug's native listener.

## Common settings and Zephyr-specific behavior

`demo.qemuPath`, `demo.openOcdPath` and `demo.openOcdScripts` have the same names
and meanings in both demos. The FreeRTOS settings, task/debug consumers and customer
guides were renamed together; its compiler and build system remain independent.
Both settings files group shared tool paths together. Zephyr adds its own Python,
checkout, SDK and profile settings. QEMU, Python, checkout and SDK settings are
home-relative; Windows task/launch overrides prepend `${env:USERPROFILE}` and
Linux uses `${userHome}`. Neither platform embeds a username or relies on nested
variable expansion. OpenOCD paths remain absolute and must be reviewed per machine.

Cortex-Debug 1.12.1 registers its GNU tool settings with the default `window`
scope, so folder settings cannot override them in a multi-root workspace. The
Zephyr launch entries use `zephyr.armToolchainPrefix` and explicit GDB/objdump
paths derived from the project SDK settings, with Windows executable suffixes.
This also prevents global Cortex-Debug GDB/objdump overrides for another project
from selecting incompatible tools. No separate global tool configuration is
required for the supplied entries.

The build always uses `ZEPHYR_TOOLCHAIN_VARIANT=zephyr` and the selected SDK.
Generic tasks accept a complete Zephyr board target, including revisions and
qualifiers, without enumerating boards in a preset or copying FreeRTOS startup,
linker, Newlib or compiler configuration. `west boards` provides discovery.
Firmware feature/architecture support remains an application concern.

Every build directory is `build/<complete-board-target>/<source>-<profile>`.
F5's executable, pristine build and run tasks share that convention. Source choice
is part of the directory, while users name a new profile for changed fragments,
overlays, SDKs or checkouts. There is no separate saved board selection to get
out of sync with F5. The generic task prompts independently, just as the FreeRTOS
clean-build task selection is independent of its debugger dropdown.

Tasks pass additional Kconfig/overlay inputs but leave the default `CONF_FILE`
and `DTC_OVERLAY_FILE` selection to Zephyr. In the current checkout, explicitly
passing `CONF_FILE=prj.conf` bypasses automatic `boards/*.conf` merging, losing
`CONFIG_QEMU_ICOUNT_SLEEP=y`. This was caught during migration validation and
the default tasks intentionally do not pass that override.

C/C++ reads the west-generated compile database, rather than allowing CMake Tools
to configure a competing build. `zephyr.intelliSenseBoard` selects navigation;
it does not change the F5 target. Named workspace variables keep task directories,
ELF paths and source mapping tied to ZephyrDemo with a shared-library file active.

## QEMU console and board options

The native F5 entry is specifically **LM3S6965EVB / Cortex-M3**, matching Zephyr's
`qemu_cortex_m3`, rather than FreeRTOS's MPS2 board. It preserves icount shift 6,
virtual-clock timing, sleep pacing, UART and the existing guarded software reboot
workaround in `src/qemu_reboot_workaround.c`.

The small logged terminal target duplicates these board options and reads timing
values from Kconfig. Keep `.vscode/launch.json`, `boards/qemu_cortex_m3.conf` and
`cmake/qemu-cortex-m3.cmake` aligned when changing this debug profile. Do not use
that launch entry for a different board or a profile with different QEMU timing.
Other boards retain Zephyr's native emulator/runner selection.

QEMU's native chardev `logfile` / `logappend=off` captures output for both run and
debug. A QEMU 10 hub or output-redirection wrapper is not required. Byte checks
found that Windows stdio logging adds CR before LF, and the guest's existing
output sometimes already contains repeated CRs. Switching to a hub/file backend
preserved the guest bytes but did not remove the guest's repeated CRs. We therefore
retain a small Python text-log normalizer after QEMU exits, through a VS Code
post-debug task or the next command in the terminal CMake target. It collapses
CR runs before LF and leaves every other byte untouched. Stop QEMU before giving
the completed log to Detect. No firmware/library newline behavior is changed.
Only one session may write `qemu_last_session.log` at a time. CLI run
retains the monitor multiplexer and Ctrl+A, X exit; F5 uses debugger Stop.
The Detect ELF must be from the matching board/source/profile/build.

## Validation record (2026-10-28)

Checks below describe this migration, separately from previous demo validation.
Windows uses the existing Zephyr checkout `64d5ab82b35c` (4.4.99), west 1.5.0,
SDK 1.0.1 / GCC 14.3.0, CMake 4.4.2, Ninja and QEMU 10.2.0 installed outside build
output. The README's earlier reference checkout is not the checkout tested here.

| Check | Result |
| --- | --- |
| Windows pristine QEMU and STM32U585 builds through resolved task arguments | Pass; both use the Zephyr SDK Arm compiler, local modules and board overlays. Zephyr emits its expected test-RNG warning. |
| Windows qualified board `mps2/an385`, generic task | Build passes; separate qualified output directory. Zephyr warns that its MPU stack guard disables `STACK_SENTINEL`. No run/debug validation claimed. |
| Windows `qemu_riscv32`, generic task | Board discovery/configuration succeeds and selects SDK `riscv64-zephyr-elf-gcc`. Demo compilation fails in `UsageExamples/10_dfm_crash_alert.c`: unguarded Cortex-M `SCB` usage. No RISC-V demo compatibility claimed. |
| Windows Cortex-Debug 1.12.1 via Debug Adapter Protocol, two successive sessions | Pass: stops at `main`, source resolves to this checkout, steps, resets to `main`, continues and disconnects. No newly spawned QEMU/GDB processes remain after either session. |
| Windows CMake `run_logged`, full demo cycle and Ctrl+A, X | Pass: all examples through the custom text payload, three boot banners and two fatal-error reports; normal exit and completed 205,576-byte log with no CRCRLF. |
| Windows immediate post-disconnect normalization | Pass with a separate log: the helper runs immediately after Cortex-Debug Disconnect and removes repeated CRs; server release is also checked. |
| Text-log normalizer unit checks | Pass: repeated CRs collapse, other payload bytes and lone CR/LF survive, a second pass is unchanged, and a failed launch with no log is handled. |
| Linux Ubuntu 24.04, pristine QEMU and STM32U585 builds | Pass with the same Zephyr checkout and SDK 1.0.1 / GCC 14.3.0; CMake 3.28.3, Ninja 1.11.1, Python 3.12.3 and west 1.5.0. |
| Linux QEMU 8.2.2 (`1:8.2.2+ds-0ubuntu1.18`), CMake `run_logged` | Pass: full demo cycle, three boot banners, two fatal-error reports, normal Ctrl+A, X exit and a completed 205,575-byte log without CRCRLF. |
| Linux SDK GDB 16.2, two successive terminal debug sessions | Pass: connects to `debugserver_logged`, breaks at `main`, steps, resets to `main` and exits QEMU with `monitor quit`; the second session reuses the same loopback port. This is terminal/GDB coverage, not Linux VS Code UI or adapter coverage. |

The new hardware F5 entry requires an interactive ST-LINK check for programming,
reset, repeated sessions and probe release. Compilation alone does not establish
those behaviors. Full VS Code UI operation, including changing the active editor
to a library file, is separate from task/debug-adapter validation.

Linux validation uses a temporary Docker environment. Public tools and the SDK
were prepared without local source mounts; the actual builds/runs mount the
necessary sources read-only with Docker networking disabled. For runtime checks,
application files are copied into the container's filesystem to avoid per-character
UART logging over the Windows bind mount. SDK tools live in
the container's `/opt`, outside disposable build output. The default customer
workflow remains native Windows/Linux, without a container requirement.

## Prefix correction (2026-10-29)

Interactive use exposed a gap in the earlier adapter-only validation: the folder's
`cortex-debug.armToolchainPrefix` was ignored in the multi-root workspace, leaving
the default `arm-none-eabi` prefix. The earlier harness substituted that value
itself and did not exercise VS Code's setting scopes.

The project now uses `zephyr.armToolchainPrefix` and explicitly derives the GDB
and objdump executables in both launch entries from the SDK settings. A Windows
adapter check using these actual resolved launch fields passes: stop at `main`,
step, restart, continue and disconnect with no newly spawned server/debugger left
behind. A separate editor-host check could not start because VS Code reported
that its installer/update mutex was held; full editor verification of this fix
remains pending.

## Home-relative tool paths (2026-10-29)

Both projects now store `demo.qemuPath` relative to the user's home directory.
Zephyr's Python, checkout and SDK paths follow the same convention. Their task
and launch consumers prepend `${userHome}` directly; no setting value contains
a nested variable or a developer username. OpenOCD paths remain absolute, and
FreeRTOS's compiler installation still comes from `ARM_SDK_INSTALL_DIR`.

FreeRTOS now uses its folder-level `freertos.armToolchainPrefix` for both task
configuration and debugging, avoiding the same window-scope problem described
above. This does not change the default `arm-none-eabi` prefix.

Windows checks pass for both actual incremental QEMU build commands and resolved
debug launches: stop at `main`, step, restart, continue and disconnect. Tests use
Windows-native home paths, and quoted Zephyr kernel substitution preserves their
backslashes correctly. JSON/settings references and the Linux home-relative
system-QEMU examples were also checked. Native Linux runs were not repeated for
this path-only change; the earlier Linux validation record remains separate.

## Windows task path correction (2026-10-29)

The user's actual VS Code task runner produced `\c:\Users\...` for a command
built with `${userHome}`. The earlier subprocess/adapter checks did not exercise
that editor terminal-resolution path. Windows task and launch overrides now use
`${env:USERPROFILE}` directly for commands, QEMU arguments, SDK/workspace environment
variables and debugger tools/source mapping. Linux defaults retain `${userHome}`.
The relative values in `settings.json` are unchanged.

The effective Windows configurations are checked to contain no `${userHome}`
references before executing the build/debug validation. A fresh attempt to run
the real editor-host task test was blocked again by VS Code's held update mutex;
this limitation is distinct from the subprocess/adapter checks.

## References

- [Zephyr build, pristine and runner semantics](https://docs.zephyrproject.org/latest/develop/west/build-flash-debug.html)
- [Zephyr SDK selection](https://docs.zephyrproject.org/latest/develop/toolchains/zephyr_sdk.html)
- [Cortex-Debug QEMU controller](https://github.com/Marus/cortex-debug/blob/v1.12.1/src/qemu.ts)
- [QEMU character-device logging](https://www.qemu.org/docs/master/system/invocation.html#character-device-options)
- [VS Code configuration scopes](https://code.visualstudio.com/api/references/contribution-points#scope)
