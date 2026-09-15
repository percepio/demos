set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR arm)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

if(DEFINED ENV{ARM_ZEPHYR_EABI_TOOLCHAIN_ROOT})
  file(TO_CMAKE_PATH "$ENV{ARM_ZEPHYR_EABI_TOOLCHAIN_ROOT}" TOOLCHAIN_ROOT)
elseif(DEFINED ENV{ZEPHYR_SDK_INSTALL_DIR})
  file(TO_CMAKE_PATH "$ENV{ZEPHYR_SDK_INSTALL_DIR}/gnu/arm-zephyr-eabi" TOOLCHAIN_ROOT)
else()
  set(TOOLCHAIN_ROOT "C:/Users/johan/zephyr-sdk-1.0.1/gnu/arm-zephyr-eabi")
endif()

set(TOOLCHAIN_BIN "${TOOLCHAIN_ROOT}/bin")
set(CMAKE_C_COMPILER "${TOOLCHAIN_BIN}/arm-zephyr-eabi-gcc.exe")
set(CMAKE_ASM_COMPILER "${TOOLCHAIN_BIN}/arm-zephyr-eabi-gcc.exe")
set(CMAKE_AR "${TOOLCHAIN_BIN}/arm-zephyr-eabi-ar.exe")
set(CMAKE_RANLIB "${TOOLCHAIN_BIN}/arm-zephyr-eabi-ranlib.exe")
set(CMAKE_OBJCOPY "${TOOLCHAIN_BIN}/arm-zephyr-eabi-objcopy.exe" CACHE FILEPATH "")
set(CMAKE_SIZE "${TOOLCHAIN_BIN}/arm-zephyr-eabi-size.exe" CACHE FILEPATH "")

if(NOT EXISTS "${CMAKE_C_COMPILER}")
  message(FATAL_ERROR
    "arm-zephyr-eabi-gcc was not found below ${TOOLCHAIN_ROOT}. "
    "Set ARM_ZEPHYR_EABI_TOOLCHAIN_ROOT to the SDK's gnu/arm-zephyr-eabi directory.")
endif()
