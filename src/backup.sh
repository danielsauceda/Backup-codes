#!/bin/bash


# EDIT FOR USER
GOOGLE_DIRNAME="Daniel Sauceda"
RCLONE_REMOTE_NAME="Arroyave_team_drive"




root_dir=`pwd`
current_date=$(date +'%m%d%Y')

bkup_dir=/tmp/backup_$current_date
mkdir $bkup_dir

rem_trailing_slash() {
    echo "$1" | sed 's/\/*$//g'
}

IFS="
"
resolve_path(){

    TARGET_FILE=$1

    cd `dirname $TARGET_FILE`
    TARGET_FILE=`basename $TARGET_FILE`

    # Iterate down a (possible) chain of symlinks
    while [ -L "$TARGET_FILE" ]
    do
        TARGET_FILE=`readlink $TARGET_FILE`
        cd `dirname $TARGET_FILE`
        TARGET_FILE=`basename $TARGET_FILE`
    done

    # Compute the canonicalized name by finding the physical path
    # for the directory we're in and appending the target file.
    PHYS_DIR=`pwd -P`
    RESULT=$PHYS_DIR/$TARGET_FILE
    echo $RESULT
    }

directory_exists(){
    FULL_PATH=resolve_path "$1"
    echo $FULL_PATH
    if [[ -d $FULL_PATH ]]
    then
        echo "Directory $1 exists."
    else
        echo "Error: Directory $1 does not exists."
        exit 1
    fi

    }

get_options() {
    echo "$@"
#    while getopts 'elha:' OPTION; do
    while [[ "$1" == -* ]]; do
        case "$1" in
            -d | --directory)
                shift
                directory_path="$1"
                # echo "you have supplied the -h option"
                ;;
            -e | --exclude)

                shift
                exclude_pattern="$1"
                # echo "The value provided is $avalue"
                ;;
            ?)
                echo 'here'
                #echo "script usage: $(basename \$0) [-l] [-h] [-a somevalue]" >&2
                exit 1
            ;;
        esac
        shift
    done

    # essentially returns values
    local directory_path=$(resolve_path $directory_path)
    # local directory_path=$directory_path
    local exclude_pattern=$exclude_pattern
    # echo $directory_path $exclude
}


rclone_sync_backup(){

    # This functions syncs a local directory to google Drive
    # This does NOT zip anything at all. So it will take longer to upload and maintain individual files.
    # This could cause SEVERE strains on the file limit. So use with caution.

    # Note: The exclude flag is slightly different in syntax
    # https://rclone.org/filtering/

    # Another feature of this backup method is that there when a file changed locally and synced
    # A backup of the original is created on the drive in /sync_backup/
    # This only retains a single backup.


    get_options "$@"
    #already resolved $directory_path

    DIR_BASENAME="$(basename -- $directory_path)"
    DIR_BASENAME=$(rem_trailing_slash $DIR_BASENAME)
    bkup_dir=$(rem_trailing_slash $bkup_dir)
    tar_basename=$DIR_BASENAME
    bkup_basename="$(basename -- $bkup_dir)"


    rclone -v sync $directory_path $RCLONE_REMOTE_NAME:$GOOGLE_DIRNAME/$DIR_BASENAME --exclude $exclude_pattern --backup-dir $RCLONE_REMOTE_NAME:$GOOGLE_DIRNAME/sync_backup/$DIR_BASENAME

}


tar_directory_backup() {

    # This function simply takes a directory, gzip tars it in a temporary location
    # then uploads it the google Team Drive in a dated backup folder such as"
    # Daniel Sauceda/backups/backup_10052022
    # in order month day year

    # This is by far the most complete method of backup as it allows for roll-back recoveries for a directory

    # arguments:
    # -d <directory path>
    # -e | --exclude  REGEX_PATTERN i.e. '*.log' 'data'

    # usage:
    # tar_directory_backup -d ~/research/presentations


    get_options "$@"
    #already resolved $directory_path

    DIR_BASENAME="$(basename -- $directory_path)"
    DIR_BASENAME=$(rem_trailing_slash $DIR_BASENAME)
    bkup_dir=$(rem_trailing_slash $bkup_dir)
    tar_basename=$DIR_BASENAME
    bkup_basename="$(basename -- $bkup_dir)"


    #$(rem_trailing_slash $i)

    if [ -z $directory_path ]
    then
        echo "Input Directory not specified!" 1>&2
        exit 64
    fi

    cd `dirname $directory_path`
    tar --exclude $exclude_pattern --ignore-failed-read -cvzf $bkup_dir/$tar_basename.tar.gz $DIR_BASENAME
    rclone copy -v $bkup_dir/$tar_basename.tar.gz $RCLONE_REMOTE_NAME:$GOOGLE_DIRNAME/backups/$bkup_basename/
    rm $bkup_dir/$tar_basename.tar.gz
    # Arroyave_team_drive:Daniel\ Sauceda/backups/$bkup_basename/$DIR_BASENAME/
    cd $root_dir
    # $DIR_BASENAME
    # echo $directory_path $exclude_pattern
}

tar_subdirectories_backup() {

    # specify a directory
    # tar and compress all the sub directories the directory
    # upload to back up to google as a dated archive


    get_options "$@"

    DIR_BASENAME="$(basename -- $directory_path)"
    DIR_BASENAME=$(rem_trailing_slash $DIR_BASENAME)
    bkup_dir=$(rem_trailing_slash $bkup_dir)

    bkup_basename="$(basename -- $bkup_dir)"

    cd $directory_path
    mkdir $bkup_dir/$DIR_BASENAME
    for i in `ls -d */`; do
        tar_basename=$(rem_trailing_slash $i)

        echo $bkup_dir/$DIR_BASENAME/$tar_basename.tar.gz
        tar --ignore-failed-read --exclude $exclude_pattern -cvzf $bkup_dir/$DIR_BASENAME/$tar_basename.tar.gz $i
        rclone copy -v $bkup_dir $RCLONE_REMOTE_NAME:$GOOGLE_DIRNAME/backups/$bkup_basename/

        rm $bkup_dir/$DIR_BASENAME/$tar_basename.tar.gz
    done

    for i in `ls -p |grep -v /$`; do

        FILE=$directory_path/$i
        rclone copy -v $FILE $RCLONE_REMOTE_NAME:$GOOGLE_DIRNAME/backups/$bkup_basename/$DIR_BASENAME/
    done

    cd $root_dir
}



tar_subdirectories_sync() {
    get_options "$@"

    DIR_BASENAME="$(basename -- $directory_path)"
    DIR_BASENAME=$(rem_trailing_slash $DIR_BASENAME)
    bkup_dir=$(rem_trailing_slash $bkup_dir)

    bkup_basename="$(basename -- $bkup_dir)"

    cd $directory_path
    mkdir $bkup_dir/$DIR_BASENAME


    }


### YOUR CODE HERE

# rclone_sync_backup -d ~/AA_BB --exclude '*analysis_AA_BB/**'
# tar_directory_backup -d ~/new_elastic_structures --exclude 'AA_BB_CC_DD'








