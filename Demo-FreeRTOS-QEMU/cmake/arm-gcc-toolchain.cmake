set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR arm)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# This is the toolchain directory containing bin/, not a Zephyr SDK root.
set(ARM_SDK_INSTALL_DIR "$ENV{ARM_SDK_INSTALL_DIR}" CACHE PATH
    "Arm GNU Toolchain installation directory containing bin/")
set(ARM_TOOLCHAIN_PREFIX "arm-none-eabi" CACHE STRING "GNU cross-tool prefix")
if(NOT ARM_SDK_INSTALL_DIR)
  message(FATAL_ERROR
    "Set ARM_SDK_INSTALL_DIR to the Arm GNU Toolchain directory containing bin/. "
    "Use the environment variable or -DARM_SDK_INSTALL_DIR=/path/to/toolchain.")
endif()
file(TO_CMAKE_PATH "${ARM_SDK_INSTALL_DIR}" ARM_SDK_INSTALL_DIR)

# CMake adds the host executable suffix. WIN32 describes the target, not host.
foreach(tool gcc ar ranlib objcopy size)
  find_program(ARM_${tool} NAMES "${ARM_TOOLCHAIN_PREFIX}-${tool}"
    PATHS "${ARM_SDK_INSTALL_DIR}/bin" NO_DEFAULT_PATH NO_CACHE REQUIRED)
endforeach()
set(CMAKE_C_COMPILER "${ARM_gcc}")
set(CMAKE_ASM_COMPILER "${ARM_gcc}")
set(CMAKE_AR "${ARM_ar}")
set(CMAKE_RANLIB "${ARM_ranlib}")
set(CMAKE_OBJCOPY "${ARM_objcopy}")
set(CMAKE_SIZE "${ARM_size}")
list(APPEND CMAKE_TRY_COMPILE_PLATFORM_VARIABLES
  ARM_SDK_INSTALL_DIR ARM_TOOLCHAIN_PREFIX)
