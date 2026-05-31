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

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/core/bash/utils.sh"

ARCHIVE_NAME=$1
if [ -z "$ARCHIVE_NAME" ]; then
    echo "Usage: $0 <students_archive.zip>"
    exit 1
fi

check_required_commands

install_npm "${DIR}"/project

STUDENTS_WORK_DIR=$(unpack_student_work "${ARCHIVE_NAME}")

clean_students_work_wrapper() {
    local CMD_TO_RUN
    CMD_TO_RUN="clean_students_work \"$STUDENTS_WORK_DIR\""
    (progress_bar "${CMD_TO_RUN}" "Clean_students_work") >&2
}

clean_students_work_wrapper
TEST_OUTPUT_DIR=$(prerepare_project "${STUDENTS_WORK_DIR}")

mapfile -t STUDENT_COMPONENTS < <(get_all_students_work)

run_all_students_work() {
    for STUDENT_PATH in "${STUDENT_COMPONENTS[@]}"; do
        run_test "${STUDENT_PATH}" "${TEST_OUTPUT_DIR}"
    done
}

progress_bar run_all_students_work "Running tests!"

collect_summary "${TEST_OUTPUT_DIR}"
REAL_PATH_STUDENTS_DIR=$(realpath "${STUDENTS_WORK_DIR}")
install_npm .
make --no-print-directory run -C "${DIR}"/plagiarism-detector DIR="${REAL_PATH_STUDENTS_DIR}" STRIP_PREFIX="Submitted files"
