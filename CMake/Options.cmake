# ================================
# Options
# ================================

include_guard(GLOBAL)

# Helper to set Debug/Release defaults
function(set_option_default var description default_debug default_release)
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        set(default_value ${default_debug})
    else()
        set(default_value ${default_release})
    endif()
    option(${var} "${description}" ${default_value})
endfunction()

# ------- Feature toggles -------
set_option_default(HST_LOGS        "Enable internal logging system"           OFF ON)
option          (HST_UNICODE      "Build with Unicode support"               ON)
set_option_default(HST_PROFILER    "Enable profiling support"                 OFF ON)
set_option_default(HST_VALIDATION  "Enable Vulkan validation layers"          OFF ON)
set_option_default(HST_EDITOR_MENU "Enable Editor Menu (ImGui)"               OFF ON)

# ================================
# Runtime Path Options
# ================================

# Root runtime directory (default: build or maye bin I dont know yet/runtime)
set(HST_RUNTIME_PATH "${CMAKE_BINARY_DIR}/runtime" CACHE PATH "Root runtime path for all runtime resources")

# Sub-paths inside runtime
set(HST_SAVE_PATH       "${HST_RUNTIME_PATH}/saved"   CACHE PATH "Save data path (save files, checkpoints, etc.)")
set(HST_LOAD_PATH       "${HST_RUNTIME_PATH}/saved"   CACHE PATH "Load data path (imported user data, mods, etc.)")
set(HST_LOG_SAVE_PATH   "${HST_RUNTIME_PATH}/logs"    CACHE PATH "Log save path")
set(HST_ASSETS_PATH     "${HST_RUNTIME_PATH}/assets"  CACHE PATH "Runtime assets path (copied from source assets)")

# Source assets (authoring)
set(HST_SOURCE_ASSETS_PATH "${CMAKE_SOURCE_DIR}/assets" CACHE PATH "Source assets (authoring location, not used at runtime)")

# Diagnostics
message(STATUS "Runtime paths:")
message(STATUS "  Runtime Root:   ${HST_RUNTIME_PATH}")
message(STATUS "  Save Path:      ${HST_SAVE_PATH}")
message(STATUS "  Load Path:      ${HST_LOAD_PATH}")
message(STATUS "  Log Save Path:  ${HST_LOG_SAVE_PATH}")
message(STATUS "  Assets Path:    ${HST_ASSETS_PATH}")
message(STATUS "  Source Assets:  ${HST_SOURCE_ASSETS_PATH}")

# ================================
# Assets timestamp (updates when any source asset changes)
# ================================

# Extensions to watch
set(HST_ASSET_EXTS
        png;jpg;jpeg;tga;hdr;ktx;ktx2;bmp
        obj;fbx;gltf;glb
        wav;ogg;mp3
        json;txt;bin
        spv;vert;frag;comp;rcp
)

# Build the file list to watch (reconfigures when assets are added/removed)
set(_asset_globs)
foreach(ext IN LISTS HST_ASSET_EXTS)
    list(APPEND _asset_globs
            "${HST_SOURCE_ASSETS_PATH}/*.${ext}"
            "${HST_SOURCE_ASSETS_PATH}/**/*.${ext}")
endforeach()

file(GLOB_RECURSE HST_ASSET_FILES
        CONFIGURE_DEPENDS
        LIST_DIRECTORIES FALSE
        ${_asset_globs})

# Cache/work dir for helper scripts
set(HST_CACHE_DIR "${CMAKE_BINARY_DIR}/cache" CACHE PATH "Internal cache/work files")
file(MAKE_DIRECTORY "${HST_CACHE_DIR}")

# Helper script to write the stamp
file(WRITE "${HST_CACHE_DIR}/hst_write_stamp.cmake" [=[
  if(NOT DEFINED STAMP_PATH)
    message(FATAL_ERROR "hst_write_stamp.cmake: STAMP_PATH is required")
  endif()
  if(NOT DEFINED SOURCE_DIR)
    set(SOURCE_DIR "?")
  endif()
  string(TIMESTAMP _now "%Y-%m-%d %H:%M:%S" UTC)
  file(WRITE "${STAMP_PATH}"
"Assets stamp
Source: ${SOURCE_DIR}
UTC: ${_now}
")
]=])

# Stamp file lives in runtime assets
set(HST_ASSETS_STAMP "${HST_ASSETS_PATH}/assets.stamp" CACHE FILEPATH "Stamp file written when assets change")

add_custom_command(
        OUTPUT  "${HST_ASSETS_STAMP}"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${HST_ASSETS_PATH}"
        COMMAND ${CMAKE_COMMAND}
        -DSTAMP_PATH="${HST_ASSETS_STAMP}"
        -DSOURCE_DIR="${HST_SOURCE_ASSETS_PATH}"
        -P "${HST_CACHE_DIR}/hst_write_stamp.cmake"
        DEPENDS ${HST_ASSET_FILES}
        COMMENT "Updating assets timestamp: ${HST_ASSETS_STAMP}"
        VERBATIM
)

add_custom_target(AssetsTimestamp ALL DEPENDS "${HST_ASSETS_STAMP}")
message(STATUS "Assets timestamp target ready: ${HST_ASSETS_STAMP}")
