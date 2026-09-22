# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

# Project-level configuration.
set(PROJECT_NAME "whisper_ggml_plus")
project(${PROJECT_NAME} LANGUAGES CXX)

# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(ggml_library_flutter_bundled_libraries
        # Defined in ../src/CMakeLists.txt.
        # This can be changed to accommodate different builds.
        "${CMAKE_CURRENT_SOURCE_DIR}/libggml-base.so"
        "${CMAKE_CURRENT_SOURCE_DIR}/libggml-cpu.so"
        "${CMAKE_CURRENT_SOURCE_DIR}/libggml.so"
        PARENT_SCOPE
)