# ================================
# application/CMakeLists.txt
# ================================

file(GLOB_RECURSE APP_SOURCES CONFIGURE_DEPENDS
        src/*.cpp
)

file(GLOB_RECURSE APP_HEADERS CONFIGURE_DEPENDS
        include/*.h
        include/*.hpp
)

add_executable(application
        ${APP_SOURCES}
        ${APP_HEADERS}
)

target_include_directories(application
        PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_link_libraries(application
        PRIVATE
        engine
)

target_compile_features(application PRIVATE cxx_std_20)

set_target_properties(application PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin
)

message(STATUS "Application sources: ${APP_SOURCES}")
message(STATUS "Application headers: ${APP_HEADERS}")
