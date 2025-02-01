#!/bin/bash
#First argument is a zip folder with a students work
#second argument is a fodler with tests
#You have to install dtrx in python venv

if ! [ -x "$(command -v dtrx)" ]; then
  echo 'Error: dtrx is not installed.' >&2
  exit 1
fi
if ! [ -x "$(command -v fdfind)" ]; then
  echo 'Error: fdfind is not installed.' >&2
  exit 1
fi
if ! [ -x "$(command -v rg)" ]; then
  echo 'Error: ripgrep is not installed.' >&2
  exit 1
fi
if ! [ -x "$(command -v npm)" ]; then
  echo 'Error: npm is not installed.' >&2
  exit 1
fi

pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}

ARCHIVE_NAME=$1
TESTS_PATH=$(realpath $2)
TESTS_PATH="$(echo $TESTS_PATH| tr -d '\r')"
echo "TESTS_PATH"
echo $TESTS_PATH
pushd .
cd $TESTS_PATH
cd ..
rm -rf src/*
npm i
popd

FOLDER_NAME="${ARCHIVE_NAME%.*}"
rm -rf $FOLDER_NAME
dtrx -r -n $ARCHIVE_NAME
#remove the extension, as this will be name of folder from dtrx

cd $FOLDER_NAME

#remove all archives
fdfind -Hitf '\.(zip|tar|tar\.gz|tgz|tar\.bz2|tbz2|tar\.xz|txz|7z|rar|iso|gz|bz2|xz|lzma|zst|cab|ar|deb|rpm)$' -X rm -rf
fdfind  -t d -Hi node_modules -X rm -rf
#find a base folder.

# Use fd to find files and save trimmed paths into an array
mapfile -t trimmed_paths < <(fdfind  -t f -Hi '^Counter.jsx$' -x bash -c '
    trimmed="${1%/*}"
    echo "$trimmed"
' bash {})

for trimmed in "${trimmed_paths[@]}"; do
    pushd .
    GO_INTO="$(echo $trimmed| tr -d '\r')"
    echo "GO INTO"
    echo $GO_INTO
    cd "$GO_INTO"
    TEMP_PWD="$(echo $PWD| tr -d '\r')"


    echo "Copy from ${TEMP_PWD}"
    echo "Copy to  ${TESTS_PATH}"
    rm -rf ${TESTS_PATH}/components
    cp -r "${TEMP_PWD}" "${TESTS_PATH}" 
    cd "${TESTS_PATH}"

    echo "NAME"
    NAME="$(echo ${GO_INTO} | awk -F '/' '{printf("%s" , $3)}' | tr -s ' ' '_')"
    echo $NAME
    anothervariable="$NAME".mg_log

    npm test run &> $anothervariable
    echo "NEXT"
    popd 

done
cd $TESTS_PATH
rg -P '^\s*Tests' -g '*.{mg_log}' | awk -F '/' '{printf("%-35s %-35s\n" , $2, $NF)}' | sed 's/wynik.mg_log://' &> final.mg_log
cat final.mg_log | sort
echo "DONE"

