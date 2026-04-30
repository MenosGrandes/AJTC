podman version of AJTC:
First You have to build an image:
podman build -t grading-image .

It will copy a "project" folder into the image itself.
project must contain tests in "test" folder and cannot contain a src folder

than run:
./ajtc_react.sh <zip> 
or if there are multiple zips, copy them in same place as ajtc_reach.sh and

fdfind -t f -e zip -d 1 . | xargs -P 5 -I {} ./ajtc_react.sh "{}"

