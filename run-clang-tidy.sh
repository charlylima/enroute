#!/bin/bash
# clang-tidy runner script for enroute project
# Usage: ./run-clang-tidy.sh [file1.cpp] [file2.cpp] ...

# Set up basic configuration
CLANG_TIDY_CMD="clang-tidy-18"
BUILD_DIR="build-linux"
PROJECT_ROOT="/home/enc2tt/chris/enroute"

# Ensure we're in the project root
cd "$PROJECT_ROOT"

# Check if compile_commands.json exists
if [ ! -f "$BUILD_DIR/compile_commands.json" ]; then
    echo "Generating compile_commands.json..."
    cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -B "$BUILD_DIR" -S .
fi

# Set up reasonable clang-tidy checks (avoiding overly pedantic ones)
CHECKS="*,-abseil-*,-altera-*,-android-*,-fuchsia-*,-google-*,-llvm-*,-llvmlibc-*,-zircon-*"
CHECKS="$CHECKS,-readability-magic-numbers,-cppcoreguidelines-avoid-magic-numbers"
CHECKS="$CHECKS,-modernize-use-trailing-return-type,-readability-named-parameter"
CHECKS="$CHECKS,-misc-non-private-member-variables-in-classes,-readability-function-cognitive-complexity"
CHECKS="$CHECKS,-bugprone-easily-swappable-parameters,-readability-identifier-length"
CHECKS="$CHECKS,-modernize-use-nodiscard,-cppcoreguidelines-avoid-do-while"
CHECKS="$CHECKS,-readability-avoid-const-params-in-decls,-performance-avoid-endl"
CHECKS="$CHECKS,-misc-include-cleaner,-readability-redundant-access-specifiers"

if [ $# -eq 0 ]; then
    echo "Usage: $0 <file1.cpp> [file2.cpp] ..."
    echo "Example: $0 src/navigation/FlightRoute.cpp"
    exit 1
fi

echo "Running clang-tidy on: $@"
echo "Using checks: $CHECKS"
echo ""

"$CLANG_TIDY_CMD" -p "$BUILD_DIR" --checks="$CHECKS" "$@"
