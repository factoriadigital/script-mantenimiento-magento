#!/bin/bash

# Show log messages
VERBOSE=true

# Vars
ROOT_DIR="/home/" # Absolute path to this script
LOG_FILES_EXPIRATION=30 # In days
SESSION_FILES_EXPIRATION=7 # In days
CACHE_IMAGES_EXPIRATION=180 # In days
LOG_VISITOR_EXPIRATION_DAYS=7 # In days
ERROR_LOG_MONTH_DAY=25 #Month day when error_log file will be removed
MAXIMUM_LOG_FILE_SIZE=50 # In MB

# Function declarations
function usage() 
{
    echo
    echo "Usage: $0"
    echo

    exit 1
}

function backup_logs()
{
    show_log "Starting the logs backup process..."

    if [ -d "$1/var/log/" ]; then        
        name=$(date '+%d-%m-%Y')
        fullname="logs_$name.tar.gz"
        cd $1/var/log
        tar --exclude='*.tar.gz' -zcf $fullname $(find . -size -"$MAXIMUM_LOG_FILE_SIZE"M)
        show_log "$fullname successfully created on $1/var/log"        
    else
        show_log "Skipping backup logs process: $1/var/log/ folder does not exist"
    fi

    show_log "Logs backup process finished."
}

function clean_folders()
{
    show_log "Starting the clean folders process..."

    if [ -d "$1/var/log/" ]; then
        find $1/var/log/* ! -name '*.tar.gz' -type f -exec rm {} \;
        show_log "Log files cleaned."
        find $1/var/log/* -mtime +$LOG_FILES_EXPIRATION -exec rm {} \;
        show_log "Cleaned logs and .tar.gz files with modification date greater than $LOG_FILES_EXPIRATION days."
    else
        show_log "$1/var/log/ folder does not exist"
    fi

    if [ -d "$1/var/report/" ]; then
        find $1/var/report/* -mtime +$LOG_FILES_EXPIRATION -exec rm {} \;
        show_log "Cleaned report files with modification date greater than $LOG_FILES_EXPIRATION days."
    else
        show_log "$1/var/report/ folder does not exist"
    fi

    if [ -d "$1/var/session/" ]; then
        find $1/var/session -name 'sess_*' -type f -mtime +$SESSION_FILES_EXPIRATION -exec rm {} \;
        show_log "Cleaned session files with modification date greater than $SESSION_FILES_EXPIRATION days."
    else
        show_log "$1/var/session/ folder does not exist"
    fi
    
    show_log "Clean folders process finished."
}

function clean_cache_images()
{
    show_log "Starting the clean cache images process..."

    if [ -d "$1/media/catalog/product/cache/" ]; then
        find $1/media/catalog/product/cache/* -type f -mtime +$CACHE_IMAGES_EXPIRATION -exec rm -f {} \;
        show_log "Cleaned cache images with modification date greater than $CACHE_IMAGES_EXPIRATION days."
    else
        show_log "Skipping clean cache images process: $1/media/catalog/product/cache/ folder does not exist"
    fi
    
    show_log "Clean cache images process finished."
}

function clean_visitor_logs()
{
    show_log "Cleaning visitor logs..."
    php $1/shell/log.php clean --days $LOG_VISITOR_EXPIRATION_DAYS
    show_log "Cleaned visitor logs successfully."
}

function clean_error_log_file()
{
    show_log "Cleaning error_log file..."

    monthDay=`date +%d`
    if [[ $monthDay -ge $ERROR_LOG_MONTH_DAY && -f "$1/error_log" ]]; then
        rm -f $1/error_log
        show_log "Cleaned"
    else
        show_log "Skipping clean error log file process: Not $ERROR_LOG_MONTH_DAY month day"
    fi

    show_log "Clean error_log file process finished."
}

function clean()
{
    show_log "-----------------------------------------------------------------------"
    show_log "Magento installation found on: $1"    
    backup_logs $1
    clean_folders $1
    clean_visitor_logs $1
    clean_cache_images $1 # Maybe the customer does not want to do this process
    clean_error_log_file $1
    show_log "-----------------------------------------------------------------------"
}

function show_log()
{
    if [ "$VERBOSE" = true ]; then
        echo $1
    fi    
}

# For multiple Magento installations
for dir in *;
do
    # If Magento is found
    if [ -f "$ROOT_DIR$dir/public_html/app/Mage.php" ]; then
        clean "$ROOT_DIR$dir/public_html"
        chown -R $dir:$dir $ROOT_DIR$dir/public_html/var/log
    else
        for subdir in $ROOT_DIR$dir/public_html/*;
        do
            if [ -f "$subdir/app/Mage.php" ]; then
                clean "$subdir"
                chown -R $dir:$dir $subdir/var/log
            fi
        done
    fi
done

# For a single Magento installation

# If Magento is found
#if [ -f "$ROOT_DIRapp/Mage.php" ]; then    
#    clean "$ROOT_DIR"
#    chown -R $dir:$dir $ROOT_DIRvar/log
#else
#   for subdir in $ROOT_DIRpublic_html/*;
#   do
#       if [ -f "$subdir/app/Mage.php" ]; then
#           clean "$subdir"
#           chown -R $dir:$dir $subdir/var/log
#       fi
#   done
#fi
