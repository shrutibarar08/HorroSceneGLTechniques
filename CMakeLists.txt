cmake_minimum_required(VERSION 3.25)

project(HorrorScenes LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(CMake/Options.cmake)
include(CMake/Dependencies.cmake)

add_subdirectory(engine)
add_subdirectory(application)
