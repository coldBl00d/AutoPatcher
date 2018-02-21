#!/bin/bash

#TODO
#support flags <OnGoing> 
#support selecting servers to patch
#support rel13 
#parametrize patch folder ? 
#fetch mode to just fetch server jar for manual patching 
#restore mode to restore changes from ./backup_cb 
#restore purge 

mkdir ./backup_cb
>loc.txt
extraDelim="/"
startPath="/scratch/aime/work/APPTOP/fusionapps/applications/crm/deploy"
patchFolder="./orcl"

rel13=false

while getopts "r" opt; do
  case $opt in
    r)
      echo "-r was triggered, Parameter: $OPTARG" >&2
      rel13=true
      echo "Patching R13 Environment"
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

if [ -d $patchFolder ]; then 
	touch ./orcl/bloop.jar
	echo "If youre only seeing bloop.jar then you did not copy your jars!!"
	for file in ./orcl/*.jar; do
	        echo "$(basename "$file")"
	        find  $startPath -type f -iname "$(basename "$file")" > loc.txt 
	        #TODO this is crap but works, rewrite backup 
	        while read location; do 
	        	cp $location ./backup_cb 
	        	echo "backed up server copy of " "$(basename "$file")"
	        	break
	        done<loc.txt
	        while read location; do 
	             #echo "Patching " "$(basename "$file")" " at location"
	             folder_loc=$(echo $location | rev | cut -d"/" -f2-  | rev)
	             folder_loc=$folder_loc$extraDelim
	             #echo "cp " "$file " "$folder_loc " 
	             cp $file $folder_loc
	        done<loc.txt 
	        echo "Patched " "$(basename "$file")"
	        >loc.txt 
	done
else
	#when orcl directory is not found, create a one and init a file in it to prevent infinite looping
	#not sure why the loop happens 
	echo "orcl directory not found, place all your jars there. I just created the folder for you :)"
	echo "Please dont touch the bloop :D"
	mkdir ./orcl
	touch ./orcl/bloop.jar
fi