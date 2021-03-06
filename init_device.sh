#!/usr/bin/env bash

# NOTE: this is a rough personal use script, run at your own risk

yell() { echo -e "$0: $*" >&2; }
die() { yell "$*"; exit 111; }
try() { "$@" || die "cannot $*"; }

# TODO: not just check if it exists, but also check if it's the same
# TODO: include ability to wipe directory


MAIN_DIR="src"
INSTALL_FILE="install.py"
RESTART_FILE="restart.py"
AMPY_IGNORE=(".gitignore" "README.md" "init_device.sh")
PYTHON_CMD="/home/jackburdick/anaconda3/envs/esp/bin/python -m ampy.cli"

# directory commands
check_dir_cmd="ls"
make_dir_cmd="mkdir --exists-okay"

# file commands
check_file_cmd="get"
put_file_cmd="put"
install_cmd="run"


ampy_check_device_present () {
    local ERROR=$($PYTHON_CMD $check_dir_cmd 2>&1 > /dev/null)
    if [[ $ERROR != "" ]]; then
        die "Device does not seem to be connected \n Error below: \n $ERROR"
    fi
}

ampy_ignore_contains() {
    # starting point: https://stackoverflow.com/questions/8063228/check-if-a-variable-exists-in-a-list-in-bash
    if [[ "${AMPY_IGNORE[@]}" =~ (^|[[:space:]])"$1"($|[[:space:]]) ]]; then
        echo 1;
    else
        echo 0;
    fi
}

make_path () {
    # presently this function is not needed, in that it only concatenates the
    # directory and file. However, I'm leaving in place as this logic may need
    # to change in the future
    local f=$1
    local d=$2
    local full_path=""
    full_path="$d$f"
    # if [[ $d == "" ]]; then
    #     full_path="$f"
    # else
    #     full_path="$d$f"
    # fi
    echo $full_path
}


maybe_make_device_dir() { 
    local cur_dir=$1
    # suppress error
    local ampy_ret=$($PYTHON_CMD $check_dir_cmd $cur_dir 2> /dev/null)
    if [[ $ampy_ret ]]; then
        echo "$ampy_ret exists"
    else
        out=$($PYTHON_CMD $make_dir_cmd $cur_dir 2> /dev/null)
        echo "$cur_dir created"
    fi
}

maybe_put_file() { 
    local cur_file=$1
    local cur_dir=$2
    local ampy_ret=$($PYTHON_CMD $check_file_cmd $cur_dir/$cur_file 2> /dev/null)
    if [[ $ampy_ret ]]; then
        echo "$cur_file exists on device"
    else
        # NOTE: the local file should exist (since it's created by an ls)
        local full_path=$(make_path $cur_file $cur_dir)
        local file_exists=$(ampy_ignore_contains $full_path)
        if [[ $file_exists == 0 ]]; then
            # echo "attempt to put file on dev: $full_path"
            local f_without_main_dir=${f//*$MAIN_DIR\//}
            local out=$($PYTHON_CMD $put_file_cmd $full_path $f_without_main_dir)
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

build_parent_dir() {
    local PATH=$1
    local dirs=(${PATH//\// })
    local mypath=""
    for x in "${dirs[@]::${#dirs[@]}-1}"; do
        mypath+="$x/"
    done
    echo $mypath
}

obtain_last_dir() {
    local PATH=$1
    local dirs=(${PATH//\// })
    echo $"${dirs[-1]}"
}

dirs_traveled=()
dirs_traveled_contains() {
    # starting point: https://stackoverflow.com/questions/8063228/check-if-a-variable-exists-in-a-list-in-bash
    if [[ "${dirs_traveled[@]}" =~ (^|[[:space:]])"$1"($|[[:space:]]) ]]; then
        echo 1;
    else
        echo 0;
    fi
}

handle_dir() {
    local cur_dir=$1
    local parent_dir=$2
    local full_path=$(make_path $cur_dir $parent_dir)
    local cur_dir_wc="$full_path/*"
    for f in $cur_dir_wc; do
        if [ -d "$f" ]; then
            # create directory if not exist
            local make_dir=${f//*$MAIN_DIR\//}
            maybe_make_device_dir $make_dir
            # recurse directory
            parent_dir=$(build_parent_dir $f)
            cur_dir=$(obtain_last_dir $f)
            dir_traveled=$(dirs_traveled_contains $f)
            if [[ $dir_traveled == 0 ]]; then
                # not traveled
                dirs_traveled+=($f)
                handle_dir $cur_dir $parent_dir 
            fi
        else
            echo "trying to put file $f"
            maybe_put_file $f
        fi
    done
}

maybe_install() {
    # NOTE: run after moving all files
    local py_install_file=$1
    local out=$($PYTHON_CMD $install_cmd $py_install_file)
    local MSG="${py_install_file} ran:\n$out"
    echo -e "$MSG"

}

maybe_restart() {
    local py_restart_file=$1
    # error will occur since device will restart
    local out=$($PYTHON_CMD $install_cmd $py_restart_file  2>&1 > /dev/null)
    local MSG="${py_restart_file} ran:\n$out"
    echo -e "$MSG"

}

# check if device is present and die if not
try ampy_check_device_present

# recursively iterative files and subdirectories in the specified directory and
# place on device (ignoring those specified)
try handle_dir $MAIN_DIR

# attempt to restart before install
try maybe_restart $RESTART_FILE

# attempt to install the listed packages in the install.py file
try maybe_install $INSTALL_FILE