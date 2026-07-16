#!/bin/bash
# Code quality checks for enroute project
# Checks all modified source files (unstaged, staged, and last commit)

set -e

CLANG_TIDY="/opt/Qt/Tools/QtCreator/libexec/qtcreator/clang/bin/clang-tidy"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build-linux"

# Check if build directory exists
if [ ! -d "$BUILD_DIR" ]; then
    echo "Error: Build directory $BUILD_DIR does not exist. Run build-linux.sh first."
    exit 1
fi

# Check if compile_commands.json exists
if [ ! -f "$BUILD_DIR/compile_commands.json" ]; then
    echo "Error: compile_commands.json not found. Ensure CMake generates it."
    exit 1
fi

echo "=== Running clang-tidy on modified enroute source files ==="
echo "Using: $("$CLANG_TIDY" --version | head -1)"
echo "Build directory: $BUILD_DIR"
echo

# Track if any warnings were found
WARNINGS_FOUND=0

# Collect all modified C++ files (unstaged, staged, and last commits)
MODIFIED_FILES=$(
    {
        # Unstaged changes (working directory)
        git diff --name-only 2>/dev/null || true
        # Staged changes
        git diff --cached --name-only 2>/dev/null || true
        # Last 2 commits
        git diff --name-only HEAD~2 HEAD 2>/dev/null || true
    } | grep -E '\.(cpp|h)$' | sort -u || true
)

if [ -z "$MODIFIED_FILES" ]; then
    echo "No modified C++ files found."
    echo "✓ Code quality checks passed (no files to check)!"
    exit 0
fi

echo "Modified files to check:"
echo "$MODIFIED_FILES"
echo

# Check each modified file
while IFS= read -r rel_file; do
    if [ -n "$rel_file" ]; then
        abs_file="$SCRIPT_DIR/$rel_file"
        if [ -f "$abs_file" ]; then
            echo "Checking: $rel_file"
            OUTPUT=$("$CLANG_TIDY" "$abs_file" -p "$BUILD_DIR" --header-filter="^((?!autogen|\.moc).)*$" 2>&1 || true)
            # Check if there are actual warnings (not just suppressed ones)
            if echo "$OUTPUT" | grep -q "^.*:[0-9]*:[0-9]*: warning:"; then
                echo "$OUTPUT"
                WARNINGS_FOUND=1
            fi
            echo
        else
            echo "Skipping: $rel_file (file not found)"
            echo
        fi
    fi
done <<< "$MODIFIED_FILES"

echo "=== Code checks completed ==="

# Exit with appropriate code
if [ $WARNINGS_FOUND -eq 0 ]; then
    echo "✓ No warnings found - code quality checks passed!"
    exit 0
else
    echo "✗ Code quality checks failed - please fix the warnings above"
    exit 1
fi
