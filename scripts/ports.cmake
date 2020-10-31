cmake_minimum_required(VERSION 3.5)

macro(debug_message)
    if(DEFINED PORT_DEBUG AND PORT_DEBUG)
        message(STATUS "[DEBUG] ${ARGN}")
    endif()
endmacro()

option(_VCPKG_PROHIBIT_BACKCOMPAT_FEATURES "Controls whether use of a backcompat only support feature fails the build.")
if (_VCPKG_PROHIBIT_BACKCOMPAT_FEATURES)
    set(_VCPKG_BACKCOMPAT_MESSAGE_LEVEL "FATAL_ERROR")
else()
    set(_VCPKG_BACKCOMPAT_MESSAGE_LEVEL "WARNING")
endif()

if((NOT DEFINED VCPKG_ROOT_DIR)
    OR (NOT DEFINED DOWNLOADS)
    OR (NOT DEFINED _VCPKG_INSTALLED_DIR)
    OR (NOT DEFINED PACKAGES_DIR)
    OR (NOT DEFINED BUILDTREES_DIR))
    message(FATAL_ERROR [[
        Your vcpkg executable is outdated and is not compatible with the current CMake scripts.
        Please re-build vcpkg by running bootstrap-vcpkg.
    ]])
endif()

file(TO_CMAKE_PATH ${BUILDTREES_DIR} BUILDTREES_DIR)
file(TO_CMAKE_PATH ${PACKAGES_DIR} PACKAGES_DIR)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/cmake)
set(CURRENT_INSTALLED_DIR ${_VCPKG_INSTALLED_DIR}/${TARGET_TRIPLET} CACHE PATH "Location to install final packages")
set(SCRIPTS ${CMAKE_CURRENT_LIST_DIR} CACHE PATH "Location to stored scripts")

if(PORT)
    set(CURRENT_BUILDTREES_DIR ${BUILDTREES_DIR}/${PORT})
    set(CURRENT_PACKAGES_DIR ${PACKAGES_DIR}/${PORT}_${TARGET_TRIPLET})
endif()

if(CMD MATCHES "^BUILD$")
    set(CMAKE_TRIPLET_FILE ${TARGET_TRIPLET_FILE})
    if(NOT EXISTS ${CMAKE_TRIPLET_FILE})
        message(FATAL_ERROR "Unsupported target triplet. Triplet file does not exist: ${CMAKE_TRIPLET_FILE}")
    endif()

    if(NOT DEFINED CURRENT_PORT_DIR)
        message(FATAL_ERROR "CURRENT_PORT_DIR was not defined")
    endif()
    set(TO_CMAKE_PATH "${CURRENT_PORT_DIR}" CURRENT_PORT_DIR)
    if(NOT EXISTS ${CURRENT_PORT_DIR})
        message(FATAL_ERROR "Cannot find port: ${PORT}\n  Directory does not exist: ${CURRENT_PORT_DIR}")
    endif()
    if(NOT EXISTS ${CURRENT_PORT_DIR}/portfile.cmake)
        message(FATAL_ERROR "Port is missing portfile: ${CURRENT_PORT_DIR}/portfile.cmake")
    endif()
    if(NOT EXISTS ${CURRENT_PORT_DIR}/CONTROL AND NOT EXISTS ${CURRENT_PORT_DIR}/vcpkg.json)
        message(FATAL_ERROR "Port is missing control or manifest file: ${CURRENT_PORT_DIR}/{CONTROL,vcpkg.json}")
    endif()

    unset(PACKAGES_DIR)
    unset(BUILDTREES_DIR)

    if(EXISTS ${CURRENT_PACKAGES_DIR})
        file(GLOB FILES_IN_CURRENT_PACKAGES_DIR "${CURRENT_PACKAGES_DIR}/*")
        if(FILES_IN_CURRENT_PACKAGES_DIR)
            file(REMOVE_RECURSE ${FILES_IN_CURRENT_PACKAGES_DIR})
            file(GLOB FILES_IN_CURRENT_PACKAGES_DIR "${CURRENT_PACKAGES_DIR}/*")
            if(FILES_IN_CURRENT_PACKAGES_DIR)
                message(FATAL_ERROR "Unable to empty directory: ${CURRENT_PACKAGES_DIR}\n  Files are likely in use.")
            endif()
        endif()
    endif()
    file(MAKE_DIRECTORY ${CURRENT_BUILDTREES_DIR} ${CURRENT_PACKAGES_DIR})

    include(${CMAKE_TRIPLET_FILE})

    if (DEFINED VCPKG_PORT_CONFIGS)
        foreach(VCPKG_PORT_CONFIG ${VCPKG_PORT_CONFIGS})
            include(${VCPKG_PORT_CONFIG})
        endforeach()
    endif()

    set(TRIPLET_SYSTEM_ARCH ${VCPKG_TARGET_ARCHITECTURE})
    include(${SCRIPTS}/cmake/vcpkg_common_definitions.cmake)
    include(execute_process)
    include(vcpkg_acquire_msys)
    include(vcpkg_add_to_path)
    include(vcpkg_apply_patches)
    include(vcpkg_build_cmake)
    include(vcpkg_build_gn)
    include(vcpkg_build_make)
    include(vcpkg_build_msbuild)
    include(vcpkg_build_ninja)
    include(vcpkg_build_nmake)
    include(vcpkg_build_qmake)
    include(vcpkg_buildpath_length_warning)
    include(vcpkg_check_features)
    include(vcpkg_check_linkage)
    include(vcpkg_clean_executables_in_bin)
    include(vcpkg_clean_msbuild)
    include(vcpkg_configure_cmake)
    include(vcpkg_configure_gn)
    include(vcpkg_configure_make)
    include(vcpkg_configure_meson)
    include(vcpkg_configure_qmake)
    include(vcpkg_copy_pdbs)
    include(vcpkg_copy_tool_dependencies)
    include(vcpkg_copy_tools)
    include(vcpkg_download_distfile)
    include(vcpkg_execute_build_process)
    include(vcpkg_execute_required_process)
    include(vcpkg_execute_required_process_repeat)
    include(vcpkg_extract_source_archive)
    include(vcpkg_extract_source_archive_ex)
    include(vcpkg_fail_port_install)
    include(vcpkg_find_acquire_program)
    include(vcpkg_fixup_cmake_targets)
    include(vcpkg_fixup_pkgconfig)
    include(vcpkg_from_bitbucket)
    include(vcpkg_from_git)
    include(vcpkg_from_github)
    include(vcpkg_from_gitlab)
    include(vcpkg_from_sourceforge)
    include(vcpkg_get_program_files_platform_bitness)
    include(vcpkg_get_windows_sdk)
    include(vcpkg_install_cmake)
    include(vcpkg_install_gn)
    include(vcpkg_install_make)
    include(vcpkg_install_meson)
    include(vcpkg_install_msbuild)
    include(vcpkg_install_nmake)
    include(vcpkg_install_qmake)
    include(vcpkg_pkgconfig)
    include(vcpkg_prettify_command)
    include(vcpkg_replace_string)
    include(vcpkg_test_cmake)
    include(${CURRENT_PORT_DIR}/portfile.cmake)
    if(DEFINED PORT)
        include(${SCRIPTS}/build_info.cmake)
    endif()
elseif(CMD MATCHES "^CREATE$")
    file(TO_NATIVE_PATH ${VCPKG_ROOT_DIR} NATIVE_VCPKG_ROOT_DIR)
    file(TO_NATIVE_PATH ${DOWNLOADS} NATIVE_DOWNLOADS)
    set(PORT_PATH "${VCPKG_ROOT_DIR}/ports/${PORT}")
    file(TO_NATIVE_PATH ${PORT_PATH} NATIVE_PORT_PATH)
    set(PORTFILE_PATH "${PORT_PATH}/portfile.cmake")
    file(TO_NATIVE_PATH ${PORTFILE_PATH} NATIVE_PORTFILE_PATH)
    set(MANIFEST_PATH "${PORT_PATH}/vcpkg.json")
    file(TO_NATIVE_PATH ${MANIFEST_PATH} NATIVE_MANIFEST_PATH)

    if(EXISTS "${PORTFILE_PATH}")
        message(FATAL_ERROR "Portfile already exists: '${NATIVE_PORTFILE_PATH}'")
    endif()
    if(NOT FILENAME)
        get_filename_component(FILENAME "${URL}" NAME)
    endif()
    string(REGEX REPLACE "(\\.(zip|gz|tar|tgz|bz2))+\$" "" ROOT_NAME ${FILENAME})

    set(DOWNLOAD_PATH "${DOWNLOADS}/${FILENAME}")
    file(TO_NATIVE_PATH ${DOWNLOAD_PATH} NATIVE_DOWNLOAD_PATH)

    if(EXISTS "${DOWNLOAD_PATH}")
        message(STATUS "Using pre-downloaded: ${NATIVE_DOWNLOAD_PATH}")
        message(STATUS "If this is not desired, delete the file and ${NATIVE_PORT_PATH}")
    else()
        include(vcpkg_download_distfile)
        set(_VCPKG_INTERNAL_NO_HASH_CHECK ON)
        vcpkg_download_distfile(ARCHIVE
            URLS ${URL}
            FILENAME ${FILENAME}
        )
        set(_VCPKG_INTERNAL_NO_HASH_CHECK OFF)
    endif()
    file(SHA512 ${DOWNLOAD_PATH} SHA512)

    file(MAKE_DIRECTORY ${PORT_PATH})
    configure_file(${SCRIPTS}/templates/portfile.in.cmake ${PORTFILE_PATH} @ONLY)
    configure_file(${SCRIPTS}/templates/vcpkg.json.in ${MANIFEST_PATH} @ONLY)

    message(STATUS "Generated portfile: ${NATIVE_PORTFILE_PATH}")
    message(STATUS "Generated manifest: ${NATIVE_MANIFEST_PATH}")
    message(STATUS "To launch an editor for these new files, run")
    message(STATUS "    .\\vcpkg edit ${PORT}")
endif()
