# DFM test sources are always linked. main.c selects run_tests() or demo_app().

if(NOT DEFINED DFM_TEST_VARIANT)
  set(DFM_TEST_VARIANT m3_o0)
endif()

# The host harness changes this value between physical-board invocations so
# stale .noinit state from an earlier flash cannot complete a new run. It stays
# fixed across the target's intentional resets within one invocation.
if(NOT DEFINED DFM_TEST_RUN_COOKIE)
  set(DFM_TEST_RUN_COOKIE 0)
endif()

# Zero selects every case in the variant. A non-zero value builds a singleton
# registry so target-side reboot handling remains identical to a full suite.
if(NOT DEFINED DFM_TEST_CASE_ID)
  set(DFM_TEST_CASE_ID 0)
endif()

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

if(DFM_TEST_VARIANT STREQUAL "m3_o0")
  set(dfm_test_variant_id 1)
  set(dfm_test_variant_cases 1001 1003 1012)
elseif(DFM_TEST_VARIANT STREQUAL "m3_og")
  set(dfm_test_variant_id 2)
  set(dfm_test_variant_cases 1013)
elseif(DFM_TEST_VARIANT STREQUAL "m3_os")
  set(dfm_test_variant_id 3)
  set(dfm_test_variant_cases
    1002 1004 1005 1006 1007 1008 1009 1011
    1014 1016 1017 1018 1019 1021 1010
  )
elseif(DFM_TEST_VARIANT STREQUAL "m3_no_coredump")
  set(dfm_test_variant_id 4)
  set(dfm_test_variant_cases 1015)
elseif(DFM_TEST_VARIANT STREQUAL "m3_small_coredump")
  set(dfm_test_variant_id 5)
  set(dfm_test_variant_cases 1020)
elseif(DFM_TEST_VARIANT STREQUAL "m3_stack128")
  set(dfm_test_variant_id 6)
  set(dfm_test_variant_cases 1024)
endif()

if(NOT DFM_TEST_CASE_ID STREQUAL "0" AND
   NOT DFM_TEST_CASE_ID IN_LIST dfm_test_variant_cases)
  message(FATAL_ERROR
    "Test case ${DFM_TEST_CASE_ID} is not part of ${DFM_TEST_VARIANT}"
  )
endif()

target_compile_definitions(app PRIVATE
  DFM_TEST_VARIANT_ID=${dfm_test_variant_id}
  DFM_TEST_VARIANT_NAME="${DFM_TEST_VARIANT}"
  DFM_TEST_CASE_ID=${DFM_TEST_CASE_ID}
  DFM_TEST_RUN_COOKIE=${DFM_TEST_RUN_COOKIE}
)

target_sources(app PRIVATE
  src/test_runner.c
  src/test_state.c
  src/test_call_chains.c
  src/test_contexts.c
  src/test_boundaries.c
  src/test_msp.S
)

target_include_directories(app PRIVATE
  ${CMAKE_CURRENT_LIST_DIR}/include
  ${CMAKE_CURRENT_LIST_DIR}/src
)
