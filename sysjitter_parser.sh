#!/bin/bash
# Runs sysjitter and plots the upper percentiles of the resulting distribution by-core in sysjitter_results.png
#Expects:
# 1. --runtime arg for sysjitter
# 2. threshold_nsec for sysjitter

shopt -s extglob

FILE_PATTERN=tmp.out
./sysjitter --raw $FILE_PATTERN --runtime $1 $2

#Merge all the raw files by-core
echo "Timestamp,Delta_us,Cycles,Interrupted_ns,Core" > tmp.csv
regex="$FILE_PATTERN.([0-9]+)"
for i in $FILE_PATTERN.+([0-9]|); do
    # Process $i
    core=0
   if [[ $i =~ $regex ]] ; then
       core="${BASH_REMATCH[1]}"
     else
       echo "Unknown file $i"
       exit 2
   fi

    tail -n+12 $i |
      tr -s ' ' |
      sed '
        s/^ //g;
        s/ /,/g;
        s/$/,'$core'/g;
      ' |
      cat -  >> tmp.csv
done

#Figure out where we are
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

Rscript $DIR/plotHdrStyle.R tmp.csv Interrupted_ns sysjitter_results.png Sysjitter Core

rm tmp.csv
