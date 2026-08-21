#
# Save current RPATH settings to restore later
#

set(_SAVED_CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_RPATH}")
set(_SAVED_CMAKE_INSTALL_RPATH_USE_LINK_PATH "${CMAKE_INSTALL_RPATH_USE_LINK_PATH}")
set(_SAVED_CMAKE_MACOSX_RPATH "${CMAKE_MACOSX_RPATH}")
set(_SAVED_PKG_CONFIG_RPATH "${PKG_CONFIG_RPATH}")

#
# Function to add a subdirectory with RPATH isolation
#

function(add_subdirectory_with_rpath_isolation dir)
    # Save current values
    set(SAVED_INSTALL_RPATH "${CMAKE_INSTALL_RPATH}")
    set(SAVED_INSTALL_RPATH_USE_LINK_PATH "${CMAKE_INSTALL_RPATH_USE_LINK_PATH}")
    set(SAVED_MACOSX_RPATH "${CMAKE_MACOSX_RPATH}")
    set(SAVED_PKG_CONFIG_RPATH "${PKG_CONFIG_RPATH}")

    # Add the subdirectory (which may modify RPATH settings)
    add_subdirectory(${dir} ${ARGN})

    # Restore original values in parent scope
    set(CMAKE_INSTALL_RPATH "${SAVED_INSTALL_RPATH}" PARENT_SCOPE)
    set(CMAKE_INSTALL_RPATH_USE_LINK_PATH "${SAVED_INSTALL_RPATH_USE_LINK_PATH}" PARENT_SCOPE)
    set(CMAKE_MACOSX_RPATH "${SAVED_MACOSX_RPATH}" PARENT_SCOPE)
    set(PKG_CONFIG_RPATH "${SAVED_PKG_CONFIG_RPATH}" PARENT_SCOPE)
endfunction()

#
# zlib (compression library, required by MapLibre Native Qt)
#
add_subdirectory(zlib)

# Configure zlib paths for all components that need it (MapLibre, libzip)
# Point to zlib source for headers and build directory for library
set(CMAKE_POLICY_DEFAULT_CMP0074 NEW)
set(ZLIB_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/zlib" CACHE PATH "Path to zlib sources" FORCE)
set(ZLIB_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/zlib" CACHE PATH "Path to zlib headers" FORCE)
set(ZLIB_INCLUDE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}/zlib" CACHE PATH "Path to zlib headers (plural)" FORCE)
# Use the actual build directory where zlib library is built
set(ZLIB_LIBRARY "${CMAKE_CURRENT_BINARY_DIR}/zlib/libz.a" CACHE FILEPATH "Path to zlib library" FORCE)
set(ZLIB_LIBRARIES "${CMAKE_CURRENT_BINARY_DIR}/zlib/libz.a" CACHE FILEPATH "Path to zlib libraries (plural)" FORCE)
set(ZLIB_FOUND TRUE CACHE BOOL "ZLIB found flag" FORCE)

# Additional library path configuration for linker
link_directories("${CMAKE_CURRENT_BINARY_DIR}/zlib")

# Set environment variables for zlib as additional fallback
set(ENV{ZLIB_ROOT} "${CMAKE_CURRENT_SOURCE_DIR}/zlib")
set(ENV{ZLIB_INCLUDE_DIR} "${CMAKE_CURRENT_SOURCE_DIR}/zlib")

# Set library path for linker to find zlib
set(CMAKE_LIBRARY_PATH "${CMAKE_CURRENT_BINARY_DIR}/zlib;${CMAKE_LIBRARY_PATH}" CACHE PATH "Library search paths" FORCE)


#
# bzip2 (compression library, required by MapLibre Native Qt)
#
# Disable bzip2 applications to avoid conflicts with main project installation
set(ENABLE_LIB_ONLY ON CACHE BOOL "Only build bzip2 library, not applications" FORCE)
add_subdirectory(bzip2)

#
# libzip (zip library for enroute)
#
# Disable libzip installation and exports since we only need the library target
set(LIBZIP_DO_INSTALL OFF CACHE BOOL "Disable libzip installation" FORCE)
add_subdirectory_with_rpath_isolation(libzip)


#
# MapLibre Native Qt (for mapping functionality)
#

# Set options for maplibre-native-qt build
set(MLN_QT_WITH_LOCATION ON CACHE BOOL "Build QMapLibreLocation" FORCE)
set(MLN_QT_WITH_WIDGETS ON CACHE BOOL "Build QMapLibreWidgets" FORCE)
set(MLN_QT_STATIC OFF CACHE BOOL "Build QMapLibre statically" FORCE)
set(MLN_QT_WITH_COVERAGE OFF CACHE BOOL "Build QMapLibre with code coverage" FORCE)
set(MLN_QT_WITH_CLANG_TIDY OFF CACHE BOOL "Build QMapLibre with clang-tidy" FORCE)
set(MLN_QT_WITH_LTO OFF CACHE BOOL "Build QMapLibre with Link-Time Optimization" FORCE)
set(MLN_QT_WITH_INTERNAL_ICU ON CACHE BOOL "Use internal ICU" FORCE)
set(BUILD_TESTING OFF CACHE BOOL "Disable testing for dependencies" FORCE)
set(MLN_QT_WITH_TESTS OFF CACHE BOOL "Build tests" FORCE)
set(MLN_QT_WITH_BENCHMARK OFF CACHE BOOL "Build benchmarks" FORCE)

# Disable installation for iOS builds to avoid object library installation issues
if(IOS)
    set(MLN_QT_WITH_INSTALL OFF CACHE BOOL "Disable MapLibre installation for iOS" FORCE)
endif()

set(MBGL_WITH_QT_DECODERS ON CACHE BOOL "Use builtin decoders" FORCE)

# Override add_subdirectory to skip test directories.
# The MapLibre Native Qt submodule unconditionally includes test directories.
# The test targets have missing header dependencies that cause compilation failures.
macro(add_subdirectory dir)
    if(NOT "${dir}" STREQUAL "test")
        _add_subdirectory(${dir} ${ARGN})
    else()
        message(STATUS "Skipping test subdirectory: ${dir}")
    endif()
endmacro()

# Workaround for MapLibre accessing vendor/ folder in top project folder in install step.
# Install step to ensure vendor symlink exists BEFORE MapLibre install steps
# This must be defined before adding maplibre-native-qt to ensure correct install order
install(CODE "
    if(NOT EXISTS \"${CMAKE_SOURCE_DIR}/vendor\")
        execute_process(
            COMMAND ${CMAKE_COMMAND} -E create_symlink
            3rdParty/maplibre-native-qt/vendor
            ${CMAKE_SOURCE_DIR}/vendor
            RESULT_VARIABLE SYMLINK_RESULT
        )
        if(SYMLINK_RESULT EQUAL 0)
            message(STATUS \"Install: Created vendor symlink for MapLibre Native Qt\")
        else()
            message(FATAL_ERROR \"Install: Failed to create vendor symlink\")
        endif()
    else()
        message(STATUS \"Install: Vendor symlink already exists\")
    endif()
")

# Add maplibre-native-qt with proper configuration
# Additional ZLIB configuration specifically for MapLibre
set(CMAKE_PREFIX_PATH "${CMAKE_CURRENT_SOURCE_DIR}/zlib;${CMAKE_PREFIX_PATH}")
include_directories(BEFORE "${CMAKE_CURRENT_SOURCE_DIR}/zlib")

# Ensure that all subdirectories (including MapLibre) can find zlib
set(CMAKE_FIND_ROOT_PATH "${CMAKE_CURRENT_SOURCE_DIR}/zlib;${CMAKE_FIND_ROOT_PATH}")

_add_subdirectory(maplibre-native-qt)

# Create missing alias for the GeoServices plugin that the macro expects
# The plugin target exists but the QMapLibre::PluginGeoServices alias is only created during install
if(TARGET qtgeoservices_maplibre)
    add_library(QMapLibre::PluginGeoServices ALIAS qtgeoservices_maplibre)
endif()

# Create missing alias for the QML plugin that the macro might also expect
if(TARGET declarative_locationplugin_maplibre)
    add_library(QMapLibre::PluginQml ALIAS declarative_locationplugin_maplibre)
endif()

# Include MapLibre macros to make qmaplibre_location_setup_plugins available
include(${CMAKE_CURRENT_SOURCE_DIR}/maplibre-native-qt/src/location/macros.cmake)

# Add additional include path for style headers to fix header inclusion issues
target_include_directories(MLNQtCore PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/maplibre-native-qt/src/core/style
)
target_include_directories(MLNQtLocation PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/maplibre-native-qt/src/core/style
)

# Fix header paths for location plugins that also need style headers
if(TARGET declarative_locationplugin_maplibre)
    target_include_directories(declarative_locationplugin_maplibre PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/maplibre-native-qt/src/core/style
    )
endif()
if(TARGET qtgeoservices_maplibre)
    target_include_directories(qtgeoservices_maplibre PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/maplibre-native-qt/src/core/style
    )
endif()

# Function to copy MapLibre plugins to executable directory,
# so we do not need to set QML2_IMPORT_PATH and QT_PLUGIN_PATH for development builds.
function(copy_maplibre_plugins_to_target target_name)
    add_custom_command(TARGET ${target_name} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        ${CMAKE_BINARY_DIR}/3rdParty/maplibre-native-qt/src/location/plugins
        $<TARGET_FILE_DIR:${target_name}>
        COMMENT "Copying MapLibre QML plugins to executable directory"
    )
endfunction()


#
# Google Material Icons
#

set(material-design-icons_SOURCE_DIR
    ${CMAKE_CURRENT_SOURCE_DIR}/material-design-icons
    CACHE INTERNAL "" FORCE)


#
# MapBox fonts
#

set(mapBoxFont_SOURCE_DIR
    ${CMAKE_CURRENT_SOURCE_DIR}/openseamap-gl
    CACHE INTERNAL "" FORCE)


#
# KDSingleApplication
#

# For simplicity, we do not build the KDSingleApplication library, but include the source files
# into the enroute target. This saves us the overhead of
# finding and loading the library at runtime.


#
# Sunset/sunrise computation
#

# For simplicity, we do not build the sunset library, but include the source files
# into the enroute target. This avoids problems on iOS and saves us the overhead of
# finding and loading the library at runtime.

#
# spriteGenerator
#

# Build the spriteGenerator tool only when the flightMapSprites target is invoked.
# It is a host-only developer tool and must not be included in mobile builds.
if(NOT ANDROID AND NOT IOS)
    add_subdirectory(spriteGenerator EXCLUDE_FROM_ALL)
endif()

#
# enrouteOGN library
#

# Build the enrouteOGN library as a static library
add_subdirectory(enrouteOGN)

#
# Restore original RPATH settings that were overwritten by 3rdParty dependencies
#

if(DEFINED _SAVED_CMAKE_INSTALL_RPATH)
    set(CMAKE_INSTALL_RPATH "${_SAVED_CMAKE_INSTALL_RPATH}")
endif()
if(DEFINED _SAVED_CMAKE_INSTALL_RPATH_USE_LINK_PATH)
    set(CMAKE_INSTALL_RPATH_USE_LINK_PATH "${_SAVED_CMAKE_INSTALL_RPATH_USE_LINK_PATH}")
endif()
if(DEFINED _SAVED_CMAKE_MACOSX_RPATH)
    set(CMAKE_MACOSX_RPATH "${_SAVED_CMAKE_MACOSX_RPATH}")
endif()
if(DEFINED _SAVED_PKG_CONFIG_RPATH)
    set(PKG_CONFIG_RPATH "${_SAVED_PKG_CONFIG_RPATH}")
endif()

# Alternative: Explicitly set the desired RPATH behavior for the main project
# Uncomment and customize these lines based on your project's needs:
# set(CMAKE_INSTALL_RPATH_USE_LINK_PATH FALSE)
# if(APPLE)
#     set(CMAKE_MACOSX_RPATH ON)
# endif()

# Clean up vendor symlink after all 3rdParty install operations are complete
# This runs after all MapLibre and other dependency installs to clean up the temporary symlink
install(CODE "
    if(EXISTS \"${CMAKE_SOURCE_DIR}/vendor\")
        execute_process(
            COMMAND ${CMAKE_COMMAND} -E remove
            ${CMAKE_SOURCE_DIR}/vendor
            RESULT_VARIABLE REMOVE_RESULT
        )
        if(REMOVE_RESULT EQUAL 0)
            message(STATUS \"Install: Cleaned up vendor symlink\")
        else()
            message(WARNING \"Install: Failed to remove vendor symlink\")
        endif()
    endif()
")
