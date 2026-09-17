# FreeRTOS DFM test variants. Keep this mapping aligned with the Zephyr suite.

set(DFM_TEST_VARIANT "m3_o0" CACHE STRING "DFM test firmware variant")
set(DFM_TEST_RUN_COOKIE "0" CACHE STRING
    "Persistent-state cookie shared across intentional resets")
set(DFM_TEST_CASE_ID "0" CACHE STRING
    "Single test ID, or zero for every case in the variant")

set(dfm_test_valid_variants
  m3_o0
  m3_og
  m3_os
  m3_no_coredump
  m3_small_coredump
  m3_stack128
)

if(NOT DFM_TEST_VARIANT IN_LIST dfm_test_valid_variants)
  message(FATAL_ERROR "Unknown DFM_TEST_VARIANT: ${DFM_TEST_VARIANT}")
endif()

set(DFM_TEST_ENABLE_COREDUMPS 1)
set(DFM_TEST_MAX_COREDUMP_SIZE "")
set(DFM_TEST_STACKDUMP_SIZE 300)

if(DFM_TEST_VARIANT STREQUAL "m3_o0")
  set(DFM_TEST_VARIANT_ID 1)
  set(DFM_TEST_VARIANT_REVISION "Build-M3-O0")
  set(DFM_TEST_OPTIMIZATION "-O0")
  set(dfm_test_variant_cases 1001 1003 1012)
elseif(DFM_TEST_VARIANT STREQUAL "m3_og")
  set(DFM_TEST_VARIANT_ID 2)
  set(DFM_TEST_VARIANT_REVISION "Build-M3-Og")
  set(DFM_TEST_OPTIMIZATION "-Og")
  set(dfm_test_variant_cases 1013)
elseif(DFM_TEST_VARIANT STREQUAL "m3_os")
  set(DFM_TEST_VARIANT_ID 3)
  set(DFM_TEST_VARIANT_REVISION "Build-M3-Os")
  set(DFM_TEST_OPTIMIZATION "-Os")
  set(dfm_test_variant_cases
    1002 1004 1005 1006 1007 1008 1025 1009 1011
    1014 1016 1017 1018 1019 1021 1010
  )
elseif(DFM_TEST_VARIANT STREQUAL "m3_no_coredump")
  set(DFM_TEST_VARIANT_ID 4)
  set(DFM_TEST_VARIANT_REVISION "Build-M3-NoCD")
  set(DFM_TEST_OPTIMIZATION "-Os")
  set(DFM_TEST_ENABLE_COREDUMPS 0)
  set(dfm_test_variant_cases 1015)
elseif(DFM_TEST_VARIANT STREQUAL "m3_small_coredump")
  set(DFM_TEST_VARIANT_ID 5)
  set(DFM_TEST_VARIANT_REVISION "Build-M3-SmallCD")
  set(DFM_TEST_OPTIMIZATION "-Os")
  set(DFM_TEST_MAX_COREDUMP_SIZE 128)
  set(dfm_test_variant_cases 1020)
elseif(DFM_TEST_VARIANT STREQUAL "m3_stack128")
  set(DFM_TEST_VARIANT_ID 6)
  set(DFM_TEST_VARIANT_REVISION "Build-M3-Stack128")
  set(DFM_TEST_OPTIMIZATION "-O0")
  set(DFM_TEST_STACKDUMP_SIZE 128)
  set(dfm_test_variant_cases 1024)
endif()

if(NOT DFM_TEST_CASE_ID STREQUAL "0" AND
   NOT DFM_TEST_CASE_ID IN_LIST dfm_test_variant_cases)
  message(FATAL_ERROR
    "Test case ${DFM_TEST_CASE_ID} is not part of ${DFM_TEST_VARIANT}"
  )
endif()

set(DFM_TEST_SOURCES
  "${CMAKE_CURRENT_LIST_DIR}/src/test_runner.c"
  "${CMAKE_CURRENT_LIST_DIR}/src/test_state.c"
  "${CMAKE_CURRENT_LIST_DIR}/src/test_call_chains.c"
  "${CMAKE_CURRENT_LIST_DIR}/src/test_contexts.c"
  "${CMAKE_CURRENT_LIST_DIR}/src/test_boundaries.c"
  "${CMAKE_CURRENT_LIST_DIR}/src/test_msp.S"
)
