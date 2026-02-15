#/bin/bash

ctnr_image_name=$1
ctnr_file=$2


podman build -t $ctnr_image_name -f $ctnr_file
