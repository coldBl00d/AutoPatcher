#!/bin/bash

#TODO 
#support selecting servers to patch
#support rel13 <onGoing> 
#0) Better backup 
#1) class file based patching 
#2) Jar Based
#3) Restore from backup 
#4) basic backup jars 
#5) copy relevant class files from jars to orcl_class folder 
#6) patch class to jar
#parametrize patch folder ? 
#fetch mode to just fetch server jar for manual patching 
#restore mode to restore changes from ./backup_cb 
#restore purge 

mkdir ./backup_cb
>loc.txt
extraDelim="/"
startPath=""
patchFolder="./orcl"
rel12=1 #flag for determining which release to patch, default to rel12 

#intended as a crappy way to backup jars in r13, since find was not working reading from manifest 
#That was because manifest created in windows had some hidden characters 
create_temp(){
	mkdir ./tmp
	while read jarName; do
		touch ./tmp/$jarName 
	done<manifest.txt
}

#method to back up modifing jars by reading from a list of jar from manifest
backup_jars(){
	echo "Start backup_jars()::"
	#cat manifest.txt| grep -i "#" >jarNames.txt #filter every jar names from manifest in form of #<jar-name>
	echo "Searching from start location " "$startPath"
	while read jarName; do #for every jarName in jarNames.txt
		echo "Starting Back up of $jarName"
		echo "Searching for location of $jarName"
		find  $startPath -type f -iname "$jarName"
		find  $startPath -type f -iname $jarName > jar_loc.txt #location of current jar r_jarName 
		echo "Estimated locations:"
		cat jar_loc.txt
		while read jloc; do
			echo "Backing up from: $jloc" 
		    cp $jloc ./backup_cb  
		    echo "Backed up"
		    break
		done<jar_loc.txt 
		>jar_loc.txt #clear jar_loc for next jar 
	done<manifest.txt
	rm jar_loc.txt #delete working file
	echo "End backup_jars()::"
}


#r switch starts rel12 mode 
#default r13 mode. 

while getopts "r" opt; do
  case $opt in
    r)
      echo "-r was triggered" >&2
      rel12=0
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
		echo "Please dont touch the bloop.jar :D"
		mkdir ./orcl
		touch ./orcl/bloop.jar
	fi
else
	echo "***Patch tool for Release 13***"
	startPath="/u01/APPLTOP/fusionapps/applications/fa/deploy/oracle.apps.fa.model.ear"
	#add check here if it is actually a rel13 environment. 
	backup_jars
fi