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
    subject=$1
    body_file=$2
    cat $body_file | mail -s $1 martin.evaldsson@smhi.se 
}

function exit_on_error()
{
    mail_report "$1" $2
    touch $SCRIPT_DIR/lockfile
    exit 1
}

trap 'exit_on_error "T-AMIP_error" /dev/null' ERR

program=$0

if [[ $0 == */* ]] ; then 
  export HOME_DIR=`cd ${0%/*}/.. && echo $PWD` 
else 
  export HOME_DIR=`cd .. && echo $PWD`
fi
LOG_DIR=$HOME_DIR/log/
SCRIPT_DIR=$HOME_DIR/script/
EXP_DIR=/nobackup/rossby15/rossby/joint_exp/tamip/
logfile=$LOG_DIR/$(date +%Y%m%d%H%M).log
run_dir=/nobackup/rossby15/sm_maeva/sources-tamip/runtime/

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

if [ $# -lt 2 ]; then
  echo "Wrong number of arguments" 2>&1
  usage_and_exit
fi

FIRST_RUN=1
while (( "$#" )); do 
  case $1 in 
     firstChoice)
        ;;
     --help|--hel|--he|--h|-help|-hel|-he|-h)
        usage_and_exit
        ;;
     --first-run)
        FIRST_RUN=0
        ;;
      --)
        set --
        ;;
      -cf) 
        control_file=$2
        shift 2
        ;;
      *)
        printf '\n%s\n\n' "Unknown flag $1" 2>&1
        usage_and_exit 1
        ;;
  esac  
done

{
    log "====================="
    log ""
    log ""
    log "====================="
    log "Start at date=$(date)"
    log "====================="

    # Check lockfile
    if [ -e $SCRIPT_DIR/lockfile ]; then
        exit 1
    fi

    # Check if running (sm_maeva)
    running_jobs=$(squeue | awk '/sm_maeva/{print $0}')
    if [ ${#running_jobs} -ne 0 ];then
        log "job is running"
        log $running_jobs
        exit 0;
    fi

    if [ $FIRST_RUN -eq 1 ]; then
        log "Read running date file"
        set -- $(cat $SCRIPT_DIR/running_job.txt)
        jobid=$1
        running_date=$2

        log "Clean up TMIP folder (remove restarts + rename folder)"
        set -x
        rm -f $EXP_DIR/TM{jobid}/srf*
        set +x
        mv $EXP_DIR/TM${jobid} $EXP_DIR/TMIP_${running_date}
        
        log "Report run report"
        cd $EXP_DIR/TMIP_${running_date}
        cat ece.info NODE* > $SCRIPT_DIR/tamip_email_report.txt
        cd -
        mail_report "T-AMIP_report_${running_date}" $SCRIPT_DIR/tamip_email_report.txt
            
        log "Delete running date file"
        rm -f $SCRIPT_DIR/running_job.txt

        log "Delete running date file entry from control-file"
        sed -i "/$running_date/d" $control_file
    fi

    log "Copy next entry of control file to running date file"
    head -1 $control_file >  $SCRIPT_DIR/running_job.txt

    log "Update run-scripts"
    set -- $(cat $SCRIPT_DIR/running_job.txt)
    jobid=$1
    running_date=$2
    sed "s/EXPN/TM${jobid}/" ${run_dir}/run-atm-tamip-template.sh > ${run_dir}/run-atm-tamip.sh 
    sed -i "s/YYYY-MM-DD/$running_date/" ${run_dir}/run-atm-tamip.sh 

    log "Launch next run"
    cd $run_dir
    curr_job=$((58-jobid))
    sbatch -J ECE3-TAMIP_${curr_job}_of_57 -N 4 -t 01:00:00  -o 'out/run-atm-tamip.sh.out' -e 'out/run-atm-tamip.sh.err' ./run-atm-tamip.sh

    log "End at date=$(date)"
    log "====================="
} >> $logfile 2>&1
