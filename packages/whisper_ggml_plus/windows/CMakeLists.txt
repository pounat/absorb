cmake_minimum_required(VERSION 3.14)

set(PROJECT_NAME "whisper_ggml_plus")
project(${PROJECT_NAME} LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

set(PROJECT_VERSION "1.8.3")
set(SOVERSION 1)
set(PLATFORM_SHARED_ROOT "${CMAKE_CURRENT_LIST_DIR}/../macos/Classes")
set(WHISPER_ROOT_DIR "${PLATFORM_SHARED_ROOT}/whisper")
set(WHISPER_SRC_DIR "${WHISPER_ROOT_DIR}/src")
set(GGML_ROOT_DIR "${WHISPER_ROOT_DIR}/ggml")
set(JSON_ROOT_DIR "${PLATFORM_SHARED_ROOT}/json")

set(BUILD_SHARED_LIBS OFF CACHE BOOL "Build vendored libs static" FORCE)
set(GGML_METAL OFF CACHE BOOL "Disable Metal backend on Windows" FORCE)
set(GGML_ACCELERATE OFF CACHE BOOL "Disable Accelerate on Windows" FORCE)
set(GGML_BLAS OFF CACHE BOOL "Disable BLAS auto-linking on Windows" FORCE)
set(GGML_OPENMP OFF CACHE BOOL "Disable OpenMP for initial Windows support" FORCE)
set(GGML_BACKEND_DL OFF CACHE BOOL "Disable dynamic ggml backends" FORCE)
set(WHISPER_COREML OFF CACHE BOOL "Disable CoreML on Windows" FORCE)
set(WHISPER_OPENVINO OFF CACHE BOOL "Disable OpenVINO on Windows" FORCE)
set(WHISPER_ALL_WARNINGS OFF CACHE BOOL "Use default warnings" FORCE)
set(GGML_ALL_WARNINGS OFF CACHE BOOL "Use default warnings" FORCE)

add_compile_definitions(
  WHISPER_VERSION=\"1.8.3\"
  GGML_USE_CPU
)

add_subdirectory("${GGML_ROOT_DIR}" "${CMAKE_CURRENT_BINARY_DIR}/ggml")
add_subdirectory("${WHISPER_SRC_DIR}" "${CMAKE_CURRENT_BINARY_DIR}/whisper")

add_library(${PROJECT_NAME} SHARED
  "${CMAKE_CURRENT_LIST_DIR}/whisper_ggml_plus.cpp"
)

target_include_directories(${PROJECT_NAME} PRIVATE
  "${CMAKE_CURRENT_LIST_DIR}"
  "${PLATFORM_SHARED_ROOT}"
  "${WHISPER_ROOT_DIR}"
  "${WHISPER_ROOT_DIR}/include"
  "${WHISPER_SRC_DIR}"
  "${GGML_ROOT_DIR}"
  "${GGML_ROOT_DIR}/include"
  "${GGML_ROOT_DIR}/src"
  "${JSON_ROOT_DIR}"
)

target_compile_definitions(${PROJECT_NAME} PRIVATE
  _CRT_SECURE_NO_WARNINGS
)

target_link_libraries(${PROJECT_NAME} PRIVATE whisper)

set_target_properties(${PROJECT_NAME} PROPERTIES
  OUTPUT_NAME "whisper_ggml_plus"
)

if(NOT CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
  set(whisper_ggml_plus_bundled_libraries
    $<TARGET_FILE:${PROJECT_NAME}>
    PARENT_SCOPE
  )
endif()
