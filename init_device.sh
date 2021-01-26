#!/usr/bin/env bash

yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 111; }
try() { "$@" || die "cannot $*"; }

# TODO: not just check if it exists, but also check if it's the same

MAIN_DIR="./src"
INSTALL_FILE="install.py"
AMPY_IGNORE=(".gitignore" "README.md" "init_device.sh" "$INSTALL_FILE")

# directory
check_dir_cmd="ampy ls"
make_dir_cmd="ampy mkdir"

# file
check_file_cmd="ampy get"
put_file_cmd="ampy put"

ampy_ignore_contains() {
    # starting point: https://stackoverflow.com/questions/8063228/check-if-a-variable-exists-in-a-list-in-bash
    if [[ "${AMPY_IGNORE[@]}" =~ (^|[[:space:]])"$1"($|[[:space:]]) ]]; then
        echo 1;
    else
        echo 0;
    fi
}

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
        local file_exists=$(ampy_ignore_contains $full_path)
        if [[ $file_exists == 0 ]]; then
            echo "in here"
            local out=$($put_file_cmd $full_path)
            if [[ out -ne "" ]]; then
                echo "error putting $full_path on device"
            else
            # NOTE: if file is empty, will overwrite
            echo "$full_path put on device"
            fi
        else
            echo "file $full_path already exists"
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


 

# ampy_ignore_contains  ".gitignore"
# ampy_ignore_contains "init_device.sh"
#ampy_ignore_contains "install.py"



TEST_file="jack.py"
# #handle_dir $MAIN_DIR
maybe_put_file $TEST_file 

#echo $AMPY_IGNORE

