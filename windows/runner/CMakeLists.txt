cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

# Define the application target.
add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)

# Standard Flutter build settings.
apply_standard_settings(${BINARY_NAME})

# Flutter version macros
target_compile_definitions(${BINARY_NAME} PRIVATE
  FLUTTER_VERSION="${FLUTTER_VERSION}"
  FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}
  FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}
  FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}
  FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}
  NOMINMAX
)

# Link required libraries
target_link_libraries(${BINARY_NAME} PRIVATE
  flutter
  flutter_wrapper_app
  flutter_wrapper_plugin
  dwmapi.lib
  legacy_stdio_definitions.lib
  ws2_32.lib
  advapi32.lib
)

# Include dir for generated header
target_include_directories(${BINARY_NAME} PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}"
  "${CMAKE_CURRENT_SOURCE_DIR}/.."
  "${FLUTTER_MANAGED_DIR}"
)

# Flutter build dependency
add_dependencies(${BINARY_NAME} flutter_assemble)
