#!/usr/bin/env bash

yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 111; }
try() { "$@" || die "cannot $*"; }

# TODO: not just check if it exists, but also check if it's the same

MAIN_DIR="./src"
AMPY_IGNORE=(".gitignore" "README.md" "init_device.sh")

# directory
check_dir_cmd="ampy ls"
make_dir_cmd="ampy mkdir"

# file
check_file_cmd="ampy get"
put_file_cmd="ampy put"

make_path () { 
    local f=$1
    local d=$2
    local full_path=""
    if [[ $d == "" ]]; then
        full_path="./$f"
    elif [[ $d == "." ]]; then
        full_path="./$f"
    else
        full_path="./$d/$f"
    fi
    echo $full_path
}


maybe_make_device_dir() { 
    local cur_dir=$1
    # suppress error
    local ampy_ret=$($check_dir_cmd $cur_dir 2> /dev/null)
    if [[ $ampy_ret ]]; then
        echo "$ampy_ret exists"
    else
        out=$($make_dir_cmd $cur_dir)
        echo "$cur_dir created"
    fi
}


maybe_put_file() { 
    local cur_file=$1
    local cur_dir=$2
    local ampy_ret=$($check_file_cmd $cur_dir/$cur_file 2> /dev/null)
    if [[ $ampy_ret ]]; then
        echo "$cur_file exists"
    else
        # NOTE: the local file should exist (since it's created by an ls)
        local full_path=$(make_path $cur_file $cur_dir)
        local out=$($put_file_cmd $full_path)
        if [[ out -ne "" ]]; then
            echo "error putting $full_path on device"
        else
          # NOTE: if file is empty, will overwrite
          echo "$full_path put on device"
        fi
    fi
}


handle_dir() {
    local cur_dir_wc="$1/*"
    for f in $cur_dir_wc; do
        if [ -d "$f" ]; then
            # create directory if not exist
            maybe_make_device_dir $f
            # recurse directory
            # handle_dir $f
        else
            echo "is not dir: $f"
        fi
    done
}


TEST_file="jack.py"
#handle_dir $MAIN_DIR
maybe_put_file $TEST_file 


# # ampy put boot.py
# # ampy mkdir tinyweb
# # ampy put tinyweb/server.py ./tinyweb/server.py


# FILE_EXISTS=$($check_dir_cmd tinyweb)
# if [ -z ${FILE_EXISTS+x} ]; then
#   # not present
#   try echo "hi"
# else
#   # exists
#   try echo 'exists'
# fi



#echo $AMPY_IGNORE