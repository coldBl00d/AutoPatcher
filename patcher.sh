#!/bin/bash

mkdir ./backup_cb
>loc.txt
extraDelim="/"
startPath=""
patchFolder="./orcl"
rel12=1 #flag for determining which release to patch, default to rel12 
mode_jar=0 #triggers jar mode for R13, R12 only support jar mode 

backup_jars(){
	echo "Start backup_jars()::"
	echo "Searching from start location " "$startPath"
	while read jarName; do 
		echo "Starting Back up of $jarName"
		echo "Searching for location of $jarName"
		find  $startPath -type f -iname "$jarName"
		find  $startPath -type f -iname $jarName > jar_loc.txt 
		echo "Estimated locations:"
		cat jar_loc.txt
		while read jloc; do
			echo "Backing up from: $jloc" 
		    folder_path=./backup_cb$(echo $jloc | rev | cut -d"/" -f2-  | rev)
		    if [ ! -d $folder_path ]; then
		    	 mkdir -p $folder_path
			fi
		    cp $jloc $folder_path
		    echo "Backed up"
		done<jar_loc.txt 
		>jar_loc.txt 
	done<manifest.txt
	rm jar_loc.txt
	echo "End backup_jars()::"
}

while getopts "rj" opt; do
  case $opt in
    r)
      echo "-r was triggered" >&2
      rel12=0
	  ;;
	j) 
	  echo "Jar mode triggered"
	  mode_jar=1
	  ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

if [ $rel12 -eq 1 ]; then 
	echo "***Patch tool for Release 12***"
	startPath="/scratch/aime/work/APPTOP/fusionapps/applications/crm/deploy"
	if [ -d $patchFolder ]; then 
		touch ./orcl/bloop.jar
		echo "If youre only seeing bloop.jar then you did not copy your jars!!"
		for file in ./orcl/*.jar; do
		        echo "$(basename "$file")"
		        find  $startPath -type f -iname "$(basename "$file")" > loc.txt 
		        while read location; do 
		        	cp $location ./backup_cb 
		        	echo "backed up server copy of " "$(basename "$file")"
		        	break
		        done<loc.txt
		        while read location; do 
		             folder_loc=$(echo $location | rev | cut -d"/" -f2-  | rev)
		             folder_loc=$folder_loc$extraDelim 
		             cp $file $folder_loc
		        done<loc.txt 
		        echo "Patched " "$(basename "$file")"
		        >loc.txt 
		done
	else
		echo "orcl directory not found, place all your jars there. I just created the folder for you :)"
		echo "Please dont touch the bloop.jar :D"
		mkdir ./orcl
		touch ./orcl/bloop.jar
	fi
else
	echo "***Patch tool for Release 13***"
	startPath="/u01/APPLTOP/fusionapps/applications/fa/deploy/oracle.apps.fa.model.ear"
	backup_jars
fi