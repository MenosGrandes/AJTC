#!/bin/bash

set -euo pipefail
cleanup() {
    echo -e "\n--- Cleanup initiated. Exiting. ---"
}
trap cleanup EXIT

check_required_commands() {
    # Check required commands
    for cmd in dtrx fdfind rg npm realpath; do
        if ! command -v $cmd &>/dev/null; then
            echo "Error: $cmd is not installed." >&2
            exit 1
        fi
    done
}

pushd() { command pushd "$@" >/dev/null; }
popd() { command popd >/dev/null; }

unpack_student_work() {
    local FOLDER_NAME
    FOLDER_NAME="${1%.*}"
    rm -rf "${FOLDER_NAME}"
    local CMD_TO_RUN
    CMD_TO_RUN="dtrx -r -n \"$ARCHIVE_NAME\""
    (progress_bar "${CMD_TO_RUN}" "Unpacking student submissions") >&2
    echo "${FOLDER_NAME}"
}

# Clean up archives, node_modules, __MACOSX, spictures
clean_students_work() {
    pushd .
    cd "$1" || exit
    find . -type d -empty -delete
    fdfind -t f -HI '\.(zip|tar|tar\.gz|tgz|tar\.bz2|tbz2|tar\.xz|txz|7z|rar|iso|gz|bz2|xz|lzma|zst|cab|ar|deb|rpm)$' -X rm -f
    fdfind -t d -HI node_modules -X rm -rf
    fdfind -t d -HI __MACOSX -X rm -rf
    fdfind -t f -HI '\.(png|jpg|bmp)$' -X rm -rf
    fdfind -t f -HI 'functions.test.js' -X rm -rf
    fdfind -t f -HI 'package.*' -X rm -rf
    popd || exit
}
get_all_students_work() {
    fdfind -g 'functions.js' --hidden --no-ignore | while IFS= read -r file; do
        echo "$file"
    done
}

collect_summary() {
    local OUTPUT_DIR="${1}"

    pushd .
    cd "${OUTPUT_DIR}"
    rg -P '^\s*Summary' -g '*.{mg_log}' |
        awk -F '/' '{printf "%-50s %s %s\n", $NF, $3, $4}' |
        sed 's/.mg_log:Summary//' |
        sort -t '|' -k2,2nr |
        column -t >final.mg_log || {
        echo "collect_summary failed!" >&2
        exit 1
    }
    popd || exit
}
run_test() {
    local STUDENT_ABS_PATH
    local LOG_FILE
    local NAME
    local OUTPUT_DIR

    STUDENT_ABS_PATH="$(realpath "$1")"
    NAME="$(echo "${1}" | tr '/' '_' | tr ' ' '_' | sed -E 's/.*Submitted_files_(.*)_src_components_.*/\1/')"
    OUTPUT_DIR="${2}"
    LOG_FILE="${OUTPUT_DIR}/${NAME}.mg_log"
    rm -rf ./project/functions.js
    cp -f "${STUDENT_ABS_PATH}" ./project
    pushd .
    cd ./project
    npm run test &>"${LOG_FILE}" || true
    popd
}

prerepare_project() {
    local FOLDER_NAME
    FOLDER_NAME="${1}"
    rm -rf ./project/functions.js
    PWD=$(pwd)
    local OUTPUT_DIR
    OUTPUT_DIR="${PWD}/outputs_${FOLDER_NAME}"
    rm -rf "${OUTPUT_DIR}"
    mkdir -p "${OUTPUT_DIR}"
    echo "${OUTPUT_DIR}"
}

progress_bar() {
    local cmd
    cmd="${1}"
    i=1
    sp='←↖↑↗→↘↓↙'
    eval "$cmd" &
    tput civis
    echo -ne "[START]"
    while ps | grep $! &>/dev/null; do
        echo -ne "\\r${sp:i++%8:1} ${2}" >&2
        sleep 0.1
    done
    tput cnorm
    echo -e "\t[DONE]"
}

install_npm() {
    pushd .
    cd "${1}"
    npm i &>'/dev/null' || {
        echo "Npm Installation failed in ${1}" >&2
        exit 1
    }
    popd
}
