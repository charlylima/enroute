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


#
# zlib (compression library, required by MapLibre Native Qt)
#

add_subdirectory(zlib)


#
# bzip2 (compression library, required by MapLibre Native Qt)
#

add_subdirectory(bzip2)


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
