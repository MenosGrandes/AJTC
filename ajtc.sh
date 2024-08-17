#!/bin/bash
# MenosGrandes #2024
# Very simple automatic checker for JEST JS files
# Automatic Jest Test Checker - AJTC
#
# You have to run this program with an arugment
#first argument is zip with all students work
# You have to specify two folders in which there is a file called
# functions.test.js
# this file is the test file in which all tests are written for particular test
# script will unpack the $1, and run test for each function.js file found in the $1
# logs will be stored in logs1 and logs2 folder.


#prerequisite
# unrar
# 7zip
# all arhivers that can be used with the dtrx
# https://github.com/dtrx-py/dtrx

# npm ( provided package.json)
#       jest installed

# ripgrep for grep 

if ! command -v unrar &> /dev/null
then
    echo "unrar could not be found. Installing!"
fi

if ! command -v dtrx &> /dev/null
then
    echo "dtrx could not be found. Installing!"
fi
#
npm i


#remove previous files
toRemove=$(echo "$1" | cut -d'.' -f1)
echo "Removing $toRemove"
rm -rf "$toRemove" 

##unpack all archives
echo "Unpacking!"
dtrx -r -n "$1"
echo "Unpacked!"

#find all functions.js files
students_work_dir=${1%.*}

echo "$students_work_dir"

#little cleanup
#remove all non functions.js files
find "$students_work_dir" ! -name 'functions.js' -type f -exec rm -f {} +
readarray -d '' students_work < <(find "${students_work_dir}" -name "functions.js" -print0)
rm -rf logs1 > /dev/null
rm -rf logs2 > /dev/null
mkdir -p logs1
mkdir -p logs2


rm -rf "1/functions.js"
rm -rf "2/functions.js"

for i in "${students_work[@]}"
do

    file=$(realpath -s "$i")
   logfile=$(echo "$i" | cut -d'/' -f3- |cut -d'/' -f-2| tr ' /-' '_' | tr '.' '_' | tr -d "[]" | tr -s '_')
   printf "Students work :\n\t %s \n" "$file"
   printf "ToBeLogged Into:\n\t %s \n" "$logfile"
   #get this file and put it as a link
   ln -s "$file" "1/functions.js"
   ln -s "$file" "2/functions.js"

   npm test 1 &> "logs1/$logfile.mg_log"
   npm test 2 &> "logs2/$logfile".mg_log

   rm -rf "1/functions.js"
   rm -rf "2/functions.js"
   printf "\n"

done

rg '^Tests:' -g "*.mg_log"






