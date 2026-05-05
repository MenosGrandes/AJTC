#!/bin/bash
# AJTC React grading script using Podman containers
# Usage: ./ajtc_react.sh students_archive.zip 
# INSTRUCTION:
# Go into sharepoint, get Submitted files from group, download as a zip
# Go into assignment download tests, unpack tests and put them into project folder
# in project folder run:
# npm i
# copy zip with student work to the same folder as the ajtc.sh
# run ./ajtc.sh OneDriveSomeDate.zip
# it will print out something like this:
# Unpacking student submissions...
# Done unpacking
# Running tests for: /home/mg/AJTC/OneDrive_2026-05-01_2/Submitted files/StudentName/OOJS - First Graded Test/Wersja 1/functions (2) 2/functions (1)/functions.js

# In the  folder named 'outputs_' that will be created there will be each output from student work.
# The summary in in the final.mg_log printed in a table.

# WARNING!
# STUDENTS NAME CONTAINS NON UTF8 CHARACTERS IN MOST CASES THERE WILL BE EIGHTER ? OR _ YOU HAVE TO FIGURE IT OUT

# REQUIREMENTS:
# DTRX FDFIND (FD) RIPGREP
# IN Ubuntu based use
# sudo apt install ripgrep fd-find dtrx


ARCHIVE_NAME=$1
if [ -z "$ARCHIVE_NAME" ]; then
    echo "Usage: $0 <students_archive.zip>"
    exit 1
fi

# Check required commands
for cmd in dtrx fdfind rg npm realpath; do
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
 
 # Clean up archives, node_modules, __MACOSX, spictures
 find . -type d -empty -delete
 fdfind -HI '\.(zip|tar|tar\.gz|tgz|tar\.bz2|tbz2|tar\.xz|txz|7z|rar|iso|gz|bz2|xz|lzma|zst|cab|ar|deb|rpm)$' -X rm -rf
 fdfind -t d -HI node_modules -X rm -rf
 fdfind -t d -HI __MACOSX -X rm -rf
 fdfind -HI '\.(png|jpg|bmp)$' -X rm -rf

 popd


rm -rf ./project/functions.js
PWD=$(pwd)
OUTPUT_DIR="${PWD}/outputs_${FOLDER_NAME}"
rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"

# Find all student functions.js files (folders named 'functions.js')
mapfile -t STUDENT_COMPONENTS < <(fdfind  -g 'functions.js' --hidden --no-ignore)

for STUDENT_PATH in "${STUDENT_COMPONENTS[@]}"; do

    # Absolute path for students work
    STUDENT_ABS_PATH="$(realpath "$STUDENT_PATH")"

    # Generate safe student name for logs
    NAME="$(echo "$STUDENT_PATH" | tr '/' '_' | tr ' ' '_' | sed -E 's/.*Submitted_files_(.*)_src_components_.*/\1/')"
    LOG_FILE="${OUTPUT_DIR}/${NAME}.mg_log"
    echo "Running tests for: ${STUDENT_ABS_PATH}"
    rm -rf ./project/functions.js
    cp -f "${STUDENT_ABS_PATH}" ./project
    pushd .
    cd ./project
    npm run test &> "${LOG_FILE}" 
    popd 
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

echo "DONE"

