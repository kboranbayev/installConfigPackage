#!/bin/bash

for arg in "$@"
do
	case ${arg} in
		config)     echo "CONFIGURING=>"
                    shift 
                    sudo sh config.sh "$@"
                    break                                                    ;;
        *)		    echo "INSTALLING==>`sudo dnf install -y -q ${arg}`"
                    echo "VERIFYING===> `rpm -qa | grep -i ${arg}`"		     ;;
	esac
done
