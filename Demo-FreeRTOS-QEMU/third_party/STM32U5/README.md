# STM32U5 platform source subset

This directory contains the startup, CMSIS and STM32U5 HAL files needed by the
B-U585I-IOT02A target. They were copied from
`percepio/Tracealyzer-STM32CubeIDE-SWO`, commit
`b435d3941cc918bbeb613d74ad42910fac5cd9b2`.

Only the HAL implementation units selected by the top-level `CMakeLists.txt`
are compiled. The board does not download code at configure or build time.
The donor repository license is retained as `LICENSE`; individual ST files
retain their original license headers.
