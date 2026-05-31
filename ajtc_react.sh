#!/bin/bash
#First argument is a zip folder with a students work
#second argument is a fodler with tests
#You have to install dtrx in python venv
#this file should be inside a root of proper configured react project
#zip itself should only contain a folder named "Submitted files"

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

pushd() {
  command pushd "$@" >/dev/null
}

popd() {
  command popd "$@" >/dev/null
}

ARCHIVE_NAME=$1
pushd .
npm i

FOLDER_NAME="${ARCHIVE_NAME%.*}"
rm -rf "${FOLDER_NAME}"
echo "Unpacking"
dtrx -r -n $ARCHIVE_NAME
#remove the extension, as this will be name of folder from dtrx
echo "Done unpacking"

cd "${FOLDER_NAME}"

#remove all archives
find . -type d -empty -delete
fdfind -Hitf '\.(zip|tar|tar\.gz|tgz|tar\.bz2|tbz2|tar\.xz|txz|7z|rar|iso|gz|bz2|xz|lzma|zst|cab|ar|deb|rpm)$' -X rm -rf
fdfind -t d -Hi node_modules -X rm -rf
popd

pwd=$PWD
components_pwd="${pwd}/src/"
output_dir="${pwd}/outputs/"
rm -rf "${output_dir}"
mkdir -p "${output_dir}"
echo "remove ${components_pwd}"
rm -rf "${components_pwd}"
mkdir -p "${components_pwd}"

#Find all folders that contains Counter.jsx, its a base root for src/components
#copy all files from this folder to local one and run tests
mapfile -t trimmed_paths < <(fdfind -t f -Hi '^Counter.jsx$' -x bash -c '
    trimmed="${1%/*}"
    echo "$trimmed"
' bash {})

for trimmed in "${trimmed_paths[@]}"; do
  echo "copy from ${trimmed}"
  rm -rf "${components_pwd}"
  mkdir -p "${components_pwd}"

  cp -r "${trimmed}" ./src/
  GO_INTO="$(echo $trimmed | tr -d '\r')"
  #get a name of student
  NAME="$(echo ${GO_INTO} | awk -F '/' '{printf("%s" , $4_$5_$6)}' | tr -s ' ' '_')"
  echo "RUN FOR : ${NAME}"
  #save output of npm run to log_file
  log_file="${output_dir}/${NAME}.mg_log"
  npm run test ./tests &>"${log_file}"
done
#go into output and look for all mg_log. Grep over them to get nice table with tests
cd "${output_dir}"
rg -P '^\s*Tests' -g '*.{mg_log}' | awk -F '/' '{printf("%s %-35s\n" , $2, $NF)}' | sed 's/.mg_log:Tests://' | column -t &>final.mg_log
cat final.mg_log | sort
echo "DONE"
