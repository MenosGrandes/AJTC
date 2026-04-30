#!/bin/bash
# AJTC React grading script using Podman containers
# Usage: ./ajtc_react.sh students_archive.zip "string of test"
# Requirements: podman, dtrx, fdfind, ripgrep, npm

set -e

ARCHIVE_NAME=$1
if [ -z "$ARCHIVE_NAME" ]; then
    echo "Usage: $0 <students_archive.zip> string of test"
    exit 1
fi

TEXT_NAME=$2
if [ -z "$ARCHIVE_NAME" ]; then
    echo "Usage: $0 <students_archive.zip> string of test"
    exit 1
fi
# Check required commands
for cmd in dtrx fdfind rg npm podman realpath; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: $cmd is not installed." >&2
        exit 1
    fi
done

pushd () { command pushd "$@" > /dev/null; }
popd () { command popd "$@" > /dev/null; }



 pushd .
 
 # Prepare folder for student submissions
 FOLDER_NAME="${ARCHIVE_NAME%.*}"
 rm -rf "${FOLDER_NAME}"
 echo "Unpacking student submissions..."
 dtrx -r -n "$ARCHIVE_NAME"
 echo "Done unpacking"
 
 cd "${FOLDER_NAME}"
 
 # Clean up archives, node_modules, __MACOSX
 find . -type d -empty -delete
 fdfind -Hitf '\.(zip|tar|tar\.gz|tgz|tar\.bz2|tbz2|tar\.xz|txz|7z|rar|iso|gz|bz2|xz|lzma|zst|cab|ar|deb|rpm)$' -X rm -rf
 fdfind -t d -Hi node_modules -X rm -rf
 fdfind -t d -Hi __MACOSX -X rm -rf
 
 popd


PWD=$(pwd)
OUTPUT_DIR="${PWD}/outputs_${FOLDER_NAME}"
rm -rf "${OUTPUT_DIR}"

mkdir -p "${OUTPUT_DIR}"

# Find all student component folders (folders named 'components')
mapfile -t STUDENT_COMPONENTS < <(fdfind -t d -Hi '^components$')

# Run tests in parallel containers
MAX_JOBS=6
for STUDENT_PATH in "${STUDENT_COMPONENTS[@]}"; do
    while [ "$(jobs -r | wc -l)" -ge "$MAX_JOBS" ]; do sleep 0.2; done

    # Absolute path for Podman bind mount
    STUDENT_ABS_PATH="$(realpath "$STUDENT_PATH")"

    # Generate safe student name for logs
    NAME="$(echo "$STUDENT_PATH" | tr '/' '_' | tr ' ' '_' | sed -E 's/.*Submitted_files_(.*)_src_components_.*/\1/')"

    if [[ "$NAME" == *"$TEXT_NAME"* ]]; then
        LOG_FILE="${OUTPUT_DIR}/${NAME}.mg_log"
        echo "Running tests for: ${NAME}"
        # Run in Podman container with explicit bind mount
        podman run --rm \
            --mount type=bind,source="$STUDENT_ABS_PATH",target=/app/src/components,readonly \
            grading-image > "$LOG_FILE" 2>&1 &
    fi

    done

wait
echo "All students processed."

# Collect summaries
cd "${OUTPUT_DIR}"
rg -P '^\s*Summary' -g '*.{mg_log}' \
    | awk -F '/' '{printf "%-50s %s %s\n", $NF, $3, $4}' \
    | sed 's/.mg_log:Summary//' \
    | sort -t '|' -k2,2nr \
    | column -t > final.mg_log

#cat final.mg_log
echo "DONE"

