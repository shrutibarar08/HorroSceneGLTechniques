# engine/CMakeLists.txt

cmake_minimum_required(VERSION 3.25)

# --------- Engine Library ---------
add_library(engine STATIC)

# --------- Auto-collect sources/headers (with IDE-friendly grouping) ----------
# Re-scan when files are added/removed
file(GLOB_RECURSE ENGINE_SRC
        CONFIGURE_DEPENDS
        "${CMAKE_CURRENT_SOURCE_DIR}/src/*.c"
        "${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp"
        "${CMAKE_CURRENT_SOURCE_DIR}/src/*.cc"
)
file(GLOB_RECURSE ENGINE_HEADERS
        CONFIGURE_DEPENDS
        "${CMAKE_CURRENT_SOURCE_DIR}/include/*.h"
        "${CMAKE_CURRENT_SOURCE_DIR}/include/*.hpp"
)

target_sources(engine PRIVATE ${ENGINE_SRC} ${ENGINE_HEADERS})

source_group(TREE "${CMAKE_CURRENT_SOURCE_DIR}/src"     PREFIX "Source Files" FILES ${ENGINE_SRC})
source_group(TREE "${CMAKE_CURRENT_SOURCE_DIR}/include" PREFIX "Header Files" FILES ${ENGINE_HEADERS})

# Public headers for consumers (application)
target_include_directories(engine
        PUBLIC
        "${CMAKE_CURRENT_SOURCE_DIR}/include"
)

# --------- Compile features / defs from Options.cmake -------------------------
target_compile_features(engine PUBLIC cxx_std_20)

target_link_libraries(engine PUBLIC HST::Unicode)

if(HST_LOGS)
    target_compile_definitions(engine PUBLIC HST_LOGS)
endif()
if(HST_VALIDATION)
    target_compile_definitions(engine PUBLIC USE_VULKAN_VALIDATION)
endif()
if(HST_EDITOR_MENU)
    target_compile_definitions(engine PUBLIC HST_USE_IMGUI)
endif()

# --------- Dependencies from Dependencies.cmake -------------------------------
target_link_libraries(engine
        PUBLIC
        Vulkan::Vulkan
        glm::glm
        nlohmann_json::nlohmann_json
        stb::stb
        assimp::assimp
        miniaudio::miniaudio
        PRIVATE
        $<$<BOOL:${HST_EDITOR_MENU}>:imgui>
        $<$<BOOL:${HST_PROFILER}>:tracy::client>
        $<$<BOOL:${WIN32}>:Win32::System>
)

hst_apply_warnings(engine)
hst_apply_sanitizers(engine)
hst_enable_unity(engine)
hst_enable_lto_if_requested(engine)
hst_route_outputs(engine)

# Configs
configure_file(
        "include/config.hpp.in"
        "${CMAKE_CURRENT_BINARY_DIR}/generated/Engine/config.hpp"
        @ONLY
)

target_include_directories(engine
        PUBLIC
        "${CMAKE_CURRENT_SOURCE_DIR}/include"
        "${CMAKE_CURRENT_BINARY_DIR}/generated"
)
