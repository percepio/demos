# DFM test sources are always linked. main.c selects run_tests() or demo_app().

if(NOT DEFINED DFM_TEST_VARIANT)
  set(DFM_TEST_VARIANT m3_o0)
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
elseif(DFM_TEST_VARIANT STREQUAL "m3_og")
  set(dfm_test_variant_id 2)
elseif(DFM_TEST_VARIANT STREQUAL "m3_os")
  set(dfm_test_variant_id 3)
elseif(DFM_TEST_VARIANT STREQUAL "m3_no_coredump")
  set(dfm_test_variant_id 4)
elseif(DFM_TEST_VARIANT STREQUAL "m3_small_coredump")
  set(dfm_test_variant_id 5)
elseif(DFM_TEST_VARIANT STREQUAL "m3_stack128")
  set(dfm_test_variant_id 6)
endif()

target_compile_definitions(app PRIVATE
  DFM_TEST_VARIANT_ID=${dfm_test_variant_id}
  DFM_TEST_VARIANT_NAME="${DFM_TEST_VARIANT}"
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
