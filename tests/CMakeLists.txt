add_subdirectory(ogn)

# Add a custom target named "tests" that depends on the unittestOgn executable
add_custom_target(tests
    DEPENDS unittestOgn
    COMMAND ${CMAKE_CTEST_COMMAND} --output-on-failure
)
