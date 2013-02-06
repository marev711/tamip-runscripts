#! /bin/sh -
 
#########################
# 
# Name: tamip-master.sh
#
# Purpose: Control (launch and clean-up) the T-AMIP runs
#
# Usage: ./tamip-master.sh <control-file>
#
# Revision history: 2013-02-06  --  Script created, Martin Evaldsson, Rossby Centre
#
# Contact persons:  martin.evaldsson@smhi.se
#
########################

program=$0

if [[ $0 == */* ]] ; then 
  export HOME_DIR=`cd ${0%/*}/.. && echo $PWD` 
else 
  export HOME_DIR=`cd .. && echo $PWD`
fi
LOG_DIR=$HOME_DIR/log
OUTPUT_DIR=$HOME_DIR/data
BIN_DIR=$HOME_DIR/bin
SCRIPT_DIR=$HOME_DIR/script

function usage {
 echo "Usage: ./tamip-master.sh -cf control-file
 Where <control-file> describes the runs to do. 'tamip-master.sh' is
 supposed to be run from crontab." 1>&2 
}

function log {
 echo "[ $(date -u '+%Y-%m-%d  %H:%M') ]: " $*
}

function usage_and_exit {
  exit_code=${1:-0}
  usage
  exit $exit_code
}

# Who is running and where
function log_whoami {
echo "==================================="
echo "This script, $(basename $0), is run by $(whoami) on server $(hostname) from folder $(pwd)"
echo "==================================="
}

if [ ! $# -eq 2 ]; then
  echo "Wrong number of arguments" 2>&1
  usage_and_exit
fi

while (( "$#" )); do 
  case $1 in 
     firstChoice)
        ;;
     --help|--hel|--he|--h|-help|-hel|-he|-h)
        usage_and_exit
        ;;
      --)
        set --
        ;;
      -cf) 
        control_file = $2
        shift 2
        ;;
      *)
        printf '\n%s\n\n' "Unknown flag $1" 2>&1
        usage_and_exit 1
        ;;
  esac  
done


