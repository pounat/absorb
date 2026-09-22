cmake_minimum_required(VERSION 3.22.1)

project(whisper_flutter_library LANGUAGES C CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(WHISPER_VENDOR_DIR "${CMAKE_CURRENT_LIST_DIR}/src")
set(GGML_VENDOR_DIR "${WHISPER_VENDOR_DIR}/ggml")
set(WHISPER_ENGINE_DIR "${WHISPER_VENDOR_DIR}/src")

set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
set(GGML_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(GGML_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(GGML_CPU ON CACHE BOOL "" FORCE)
set(GGML_NATIVE OFF CACHE BOOL "" FORCE)
set(GGML_OPENMP OFF CACHE BOOL "" FORCE)
set(GGML_BLAS OFF CACHE BOOL "" FORCE)
set(GGML_ACCELERATE OFF CACHE BOOL "" FORCE)
set(WHISPER_ALL_WARNINGS OFF CACHE BOOL "" FORCE)
set(WHISPER_COREML OFF CACHE BOOL "" FORCE)
set(WHISPER_OPENVINO OFF CACHE BOOL "" FORCE)

# Without an arch baseline ggml compiles plain armv8-a and loses the dotprod
# and fp16 kernels that quantized whisper spends nearly all its time in.
# armv8.2-a+dotprod+fp16 needs Cortex-A75/A55 (2018) or newer; cores older
# than that SIGILL on it, so ../../../android_compat builds this same file a
# second time with WHISPER_COMPAT on, producing a plain armv8-a
# libwhisper_compat.so that the Dart side picks at runtime instead.
option(WHISPER_COMPAT "Baseline armv8-a build for CPUs without dotprod/fp16" OFF)
if (ANDROID_ABI STREQUAL "arm64-v8a" AND NOT WHISPER_COMPAT)
    set(GGML_CPU_ARM_ARCH "armv8.2-a+dotprod+fp16" CACHE STRING "" FORCE)
endif()

add_subdirectory("${GGML_VENDOR_DIR}" "${CMAKE_CURRENT_BINARY_DIR}/ggml")
add_subdirectory("${WHISPER_ENGINE_DIR}" "${CMAKE_CURRENT_BINARY_DIR}/whisper")

add_library(whisper_flutter SHARED main.cpp)

target_include_directories(whisper_flutter PRIVATE
    "${CMAKE_CURRENT_LIST_DIR}"
    "${WHISPER_VENDOR_DIR}"
    "${WHISPER_VENDOR_DIR}/include"
)

target_compile_definitions(whisper_flutter PUBLIC DART_SHARED_LIB)

find_library(LOG_LIB log)
find_library(ATOMIC_LIB atomic)

target_link_libraries(whisper_flutter PRIVATE whisper ${LOG_LIB})

if (ATOMIC_LIB)
    target_link_libraries(whisper_flutter PRIVATE ${ATOMIC_LIB})
endif()

if (ANDROID)
    target_link_options(whisper_flutter PRIVATE
        $<$<OR:$<STREQUAL:${ANDROID_ABI},arm64-v8a>,$<STREQUAL:${ANDROID_ABI},x86_64>>:LINKER:-z,max-page-size=16384>
        $<$<OR:$<STREQUAL:${ANDROID_ABI},arm64-v8a>,$<STREQUAL:${ANDROID_ABI},x86_64>>:LINKER:-z,common-page-size=16384>
    )
endif()

if (WHISPER_COMPAT)
    set(WHISPER_OUTPUT_NAME "whisper_compat")
else()
    set(WHISPER_OUTPUT_NAME "whisper")
endif()

set_target_properties(whisper_flutter PROPERTIES
    PUBLIC_HEADER src/whisper.h
    OUTPUT_NAME "${WHISPER_OUTPUT_NAME}"
)
