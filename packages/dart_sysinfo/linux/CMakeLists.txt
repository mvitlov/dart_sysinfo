cmake_minimum_required(VERSION 3.10)

set(PROJECT_NAME "dart_sysinfo")
project(${PROJECT_NAME} LANGUAGES CXX)

include("../cargokit/cmake/cargokit.cmake")
apply_cargokit(${PROJECT_NAME} ../../native dart_sysinfo_native "")

set(dart_sysinfo_bundled_libraries
  "${${PROJECT_NAME}_cargokit_lib}"
  PARENT_SCOPE
)
