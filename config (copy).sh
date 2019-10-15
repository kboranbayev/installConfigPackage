#!/bin/bash

configureFile() {
    echo "Openning editor ..."
    sudo nano ${conf_file}
    `sudo systemctl restart ${arg}.service`
    echo "STATUS===>${arg}.service"
    echo "`systemctl status ${arg}.service`"
}


for arg in "$@"
do
    echo "configuring ${arg}";
    echo "Configuration file for ${arg}:";
    read conf_file;
    if [ -f $conf_file ]
    then
        echo "Would you like to copy $conf_file before you mess it up?[y/N]"
        read select
        case $select in
            y|Y)        echo "User select to copy the file"
                        if [ -f $conf_file"-copy" ]
                        then
                            sudo cp $conf_file $conf_file"-copy-2"
                        else
                            sudo cp $conf_file $conf_file"-copy"
                        fi
                                                                    ;;
            n|N)      echo "User select to NOT copy the file"       ;;
        esac
    else
        echo "File 404"
    fi
    configureFile
done

