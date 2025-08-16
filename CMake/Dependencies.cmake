# --------- Contents ---------
# Vulkan           (raw C Vulkan API)
# ImGui            (GUI system)
# glm              (Math library)
# miniaudio        (Audio library)
# stb              (Image loading: PNG, JPG etc... for Vulkan textures)
# nlohmann_json    (JSON serialization)
# assimp           (Model loader: OBJ, FBX, GLTF, etc..)
# Tracy            (real-time CPU/GPU profiler)
# --------------------------------

include_guard(GLOBAL)

# --------- Vulkan (system) ----------------------------------------------------
find_package(Vulkan REQUIRED)

# --------- Win32 convenience libs --------------------------------------------
if (WIN32)
    add_library(Win32::System INTERFACE)
    target_link_libraries(Win32::System INTERFACE user32 gdi32 shell32 shlwapi)
endif()

# --------- Unicode convenience (from Options.cmake: HST_UNICODE) --------------
add_library(HST::Unicode INTERFACE)
if (HST_UNICODE AND WIN32)
    target_compile_definitions(HST::Unicode INTERFACE UNICODE _UNICODE)
endif()

# --------- FetchContent setup -------------------------------------------------
include(FetchContent)

# --------- GLM (header-only) --------------------------------------------------
FetchContent_Declare(
        glm
        GIT_REPOSITORY https://github.com/g-truc/glm.git
        GIT_TAG        1.0.1
        GIT_SHALLOW    TRUE
)
FetchContent_MakeAvailable(glm)   # exports glm::glm

# --------- miniaudio (header-only) -------------------------------------------
FetchContent_Declare(
        miniaudio
        GIT_REPOSITORY https://github.com/mackron/miniaudio.git
        GIT_TAG        0.11.18
        GIT_SHALLOW    TRUE
)
FetchContent_GetProperties(miniaudio)
if (NOT miniaudio_POPULATED)
    FetchContent_Populate(miniaudio)
    add_library(miniaudio::miniaudio INTERFACE)
    target_include_directories(miniaudio::miniaudio INTERFACE "${miniaudio_SOURCE_DIR}")
endif()

# --------- Dear ImGui --------------------
if (HST_EDITOR_MENU)
    FetchContent_Declare(
            imgui
            GIT_REPOSITORY https://github.com/ocornut/imgui.git
            GIT_TAG        docking
            GIT_SHALLOW    TRUE
    )
    FetchContent_GetProperties(imgui)
    if (NOT imgui_POPULATED)
        FetchContent_Populate(imgui)

        set(IMGUI_DIR "${imgui_SOURCE_DIR}")
        set(IMGUI_SOURCES
                "${IMGUI_DIR}/imgui.cpp"
                "${IMGUI_DIR}/imgui_draw.cpp"
                "${IMGUI_DIR}/imgui_tables.cpp"
                "${IMGUI_DIR}/imgui_widgets.cpp"
                "${IMGUI_DIR}/backends/imgui_impl_win32.cpp"
                "${IMGUI_DIR}/backends/imgui_impl_vulkan.cpp"
        )
        set(IMGUI_HEADERS
                "${IMGUI_DIR}/imgui.h"
                "${IMGUI_DIR}/imconfig.h"
                "${IMGUI_DIR}/imgui_internal.h"
                "${IMGUI_DIR}/imstb_rectpack.h"
                "${IMGUI_DIR}/imstb_textedit.h"
                "${IMGUI_DIR}/imstb_truetype.h"
                "${IMGUI_DIR}/backends/imgui_impl_win32.h"
                "${IMGUI_DIR}/backends/imgui_impl_vulkan.h"
        )

        add_library(imgui STATIC ${IMGUI_SOURCES} ${IMGUI_HEADERS})
        target_include_directories(imgui PUBLIC "${IMGUI_DIR}" "${IMGUI_DIR}/backends")
        target_link_libraries(imgui PUBLIC Vulkan::Vulkan)
        if (WIN32)
            target_link_libraries(imgui PUBLIC Win32::System)
        endif()
        target_compile_definitions(imgui PUBLIC IMGUI_DISABLE_OBSOLETE_FUNCTIONS)
    endif()
endif()

# --------- nlohmann/json (header-only JSON) -----------------------------------
FetchContent_Declare(
        nlohmann_json
        GIT_REPOSITORY https://github.com/nlohmann/json.git
        GIT_TAG        v3.11.3
        GIT_SHALLOW    TRUE
)
FetchContent_MakeAvailable(nlohmann_json)  # exports nlohmann_json::nlohmann_json

# --------- Assimp (model loader: OBJ/FBX/GLTF/etc.) ---------------------------
set(ASSIMP_BUILD_TESTS        OFF CACHE BOOL "" FORCE)
set(ASSIMP_BUILD_ASSIMP_TOOLS OFF CACHE BOOL "" FORCE)
set(ASSIMP_BUILD_ZLIB         ON  CACHE BOOL "" FORCE)
set(ASSIMP_NO_EXPORT          OFF CACHE BOOL "" FORCE)
FetchContent_Declare(
        assimp
        GIT_REPOSITORY https://github.com/assimp/assimp.git
        GIT_TAG        v5.4.3
        GIT_SHALLOW    TRUE
)
FetchContent_MakeAvailable(assimp)         # exports assimp::assimp

# --------- stb (header-only image loaders) ------------------------------------
FetchContent_Declare(
        stb
        GIT_REPOSITORY https://github.com/nothings/stb.git
        GIT_TAG        master
        GIT_SHALLOW    TRUE
)
FetchContent_GetProperties(stb)
if (NOT stb_POPULATED)
    FetchContent_Populate(stb)
    add_library(stb::stb INTERFACE)
    target_include_directories(stb::stb INTERFACE "${stb_SOURCE_DIR}")
endif()

# --------- Tracy (profiler) — gated by HST_PROFILER ---------------------------
if (HST_PROFILER)
    FetchContent_Declare(
            tracy
            GIT_REPOSITORY https://github.com/wolfpld/tracy.git
            GIT_TAG        v0.11
            GIT_SHALLOW    TRUE
    )
    FetchContent_GetProperties(tracy)
    if (NOT tracy_POPULATED)
        FetchContent_Populate(tracy)
        add_library(tracy_client STATIC "${tracy_SOURCE_DIR}/public/TracyClient.cpp")
        target_include_directories(tracy_client PUBLIC "${tracy_SOURCE_DIR}/public")
        target_compile_definitions(tracy_client PUBLIC TRACY_ENABLE)
        if (WIN32)
            target_link_libraries(tracy_client PUBLIC ws2_32 dbghelp)
            target_compile_definitions(tracy_client PUBLIC NOMINMAX)
        endif()
        add_library(tracy::client ALIAS tracy_client)
    endif()
endif()
