#! /bin/sh -eu
 
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

function mail_report()
{
    subject = $1
    body_file = $2
    cat $body_file | mail -s $1 martin.evaldsson@smhi.se 
}

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
EXP_DIR=/nobackup/rossby15/rossby/joint_exp/tamip/
logfile=$LOG_DIR/$(date +%Y%m%d%H).log

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

{
    log "Start at date=$(date)"
    log "====================="

    # check if running (sm_maeva)
    set +e
    running_jobs=squeue | grep sm_maeva
    if [ $? -eq 0 ];then
        log "job is running"
        log $running_jobs
        exit 0;
    fi
    set -e

    # read running date file
    . $SCRIPT_DIR/running_job.txt

    # clean up TMIP folder (remove restarts + rename folder)
    set -x
    rm -f $EXP_DIR/TMIP/srf*
    set +x
    
    # check for errors and report
    cd $EXP_DIR
    cat ece.info NODE* > tamip_email_report.txt
    cd -
        
    # delete running date file
    # delete running date file entry from control-file
    # copy next entry of control file to running date file
    # update template run-scripts
    # launch next run
    log "End at date=$(date)"
    log "====================="
} >> $logfile 2>&1
