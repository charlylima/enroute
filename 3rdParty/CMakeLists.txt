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
_add_subdirectory(maplibre-native-qt)

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
# zlib (compression library, required by MapLibre Native Qt)
#

add_subdirectory(zlib)


#
# bzip2 (compression library, required by MapLibre Native Qt)
#

add_subdirectory(bzip2)


#
# libzip (zip library for enroute)
#

# Configure libzip to use our 3rdParty zlib instead of system zlib.
# Set policy CMP0074, without CMake would ignore ZLIB_ROOT variable.
cmake_policy(SET CMP0074 NEW)
set(ZLIB_ROOT "${CMAKE_CURRENT_BINARY_DIR}/zlib" CACHE PATH "Path to zlib installation" FORCE)

# Disable libzip installation and exports since we only need the library target
set(LIBZIP_DO_INSTALL OFF CACHE BOOL "Disable libzip installation" FORCE)

add_subdirectory(libzip)


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

# For simplicity, we do not build the subset library, but include the source files
# into the enroute target. This avoids problems on iOS and saves us the overhead of
# finding and loading the library at runtime.

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
