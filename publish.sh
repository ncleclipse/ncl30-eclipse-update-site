#!/bin/bash
#This script is intended to update the ncl-eclipse-update-site
PROGRAM_NAME='publish.sh'
PROGRAM_VERSION='$Id: build.sh 0.1 2010/03/02 robertogerson'
AUTHORS='Roberto Azevedo'
BUGS_TO='robertogerson@telemidia.puc-rio.br'


#get the atual path
cwd=`pwd`

#Variables handling with the repository of the plugin
PLUGIN_REPO_USER='ncleclipse'
PLUGIN_REPO_PASSWOED=''
PLUGIN_REPO_HOST='laws.deinf.ufma.br'
PLUGIN_REPO_PATH='/home/ncleclipse/www/update/'
PLUGIN_REPO_PATH_TEST='/home/ncleclipse/www/update/test'
PLUGINS="ncleclipse ncleclipse.club"
FEATURES="ncleclipse.feature"

COPY_FILES_CMD="scp"

#arguments defaults
testflag='true' #default is making tests
allflag='false'
helpflag='false'
xmlfilesflag='true'
pluginsfilesflag='true'
featuresfilesflag='true'
showfilestopush='false'
nofixxmlfilesflag='false'
plugin_version='' #publish just the last by default


#will be used by the filter_file
FILES_TO_COPY=''

#Parse the arguments and set the variables to be handled by the script
parse_args() {
	echo "Running with parameters: '$*'"
	until [ -z "$1" ]
	do
		case "$1" in
			(-h|--help) helpflag='true';;
			(--no-test) testflag='false';;
			(-a|--all) allflag='true';;
			(--plugins) PLUGINS="$2"; shift;;

			(--no-features-files) featuresfilesflag='false';;
			(--no-xml-files) xmlfilesflag='false';;
			(--no-plugins-files) pluginsfilesflag='false';;

			(--no-fix-xml-files) nofixxmlfilesflag='true';;
			(--show-files-to-push) showfilestopushflag='true';;
			(--) shift break;;	
		esac
		shift
	done
}

print_help() {
	echo "\
Usage: $PROGRAM_NAME [OPTIONS...]
Publish ncl eclipse plugin to UPDATE SITE repository

Options:
	-a,--all		publish all the files (all versions) from plugin/
				and feature/ directories

	-h,--help		print this help

	--no-features-files	don't push FEATURES files (located at features/)
	--no-plugins-files	don't push PLUGINS files (located at plugin/)
	--no-xml-files		don't push XML configurations files

	--show-files-to-push	with this option the script will not send the
				files to repository, just show a list with the
				files should be pushed to server. It's recommended
				allways run first with this option, before sending
				the files.

	--no-test		publish to the oficial site repository, not to
				the test repository
	

	--no-fix-xml-files	this scripts automatically resolves problems in some
				xml files generated automatically by Eclipse. If this 
				option is setted it doesn't fix this xml files.


	-v,--verbose		verbose mode (not working yet)
	
Report bugs to: <$BUGS_TO>."
}


solve_eclipse_bugs(){
	#unjar the configuration files
	echo "Solving BUG from eclipse... changing some attributes from content.xml"
	jar -xf content.jar
#	rm content.jar
	cat content.xml  | sed 's/feature\.feature/feature/' > .content.tmp.xml
	rm content.xml
	rm -rf META-INF
	mv .content.tmp.xml content.xml
	rm content.jar
	touch content.jar
	jar -cf content.jar content.xml
	rm content.xml
	echo "(OK)"
}

filter_files() {
	local path="$1"
	local array="$2"
	FILES_TO_COPY=''
	#test if should copy all plugin files
	if test "$allflag" = 'true'; then
		echo 'All the files will be published. Option -a|--all was setted.'
		FILES_TO_COPY="$path/*"
	else
		#copy just the last version of each plugin
		cd "$path"
		for i in $array
		do
			local var=`ls *"$i"_* | sort -V -r`
			#get first element in the string
			var=`echo "$var" | grep -m 1 "$i"`
			FILES_TO_COPY="$FILES_TO_COPY $path/$var"
		done
		cd ..
	fi
}

do_actions() {
	if test "$helpflag" = 'true'; then
		print_help
		return 1
	fi

	if test "$testflag" = 'true'; then
		PLUGIN_REPO_PATH=$PLUGIN_REPO_PATH_TEST
	fi

	#1: copy all XML files to Repository
	if test "$xmlfilesflag" = 'true'; then
		#if the user explicitily ask to not fix the xml files
		if test "$nofixxmlfilesflag" = 'false'; then
			solve_eclipse_bugs
		fi
		FILES_TO_COPY='*.xml *.jar'
		if test "$showfilestopushflag" = 'true'; then
			echo "\
This files will be sended to ROOT:
$FILES_TO_COPY"

		else
			echo "Copying XML and jar files to server..."
			$COPY_FILES_CMD $FILES_TO_COPY $PLUGIN_REPO_USER@$PLUGIN_REPO_HOST:$PLUGIN_REPO_PATH
		fi
	fi


	#2: copy PLUGINS files to Repository
	if test "$pluginsfilesflag" = 'true'; then
		filter_files "plugins" "$PLUGINS"
		#the return will be in FILES_TO_COPY
		if test "$showfilestopushflag" = 'true'; then
			echo "\

This files will be sended to ROOT/plugins:
$FILES_TO_COPY"

		else
			echo "Copying PLUGINS files to server..."
			$COPY_FILES_CMD $FILES_TO_COPY $PLUGIN_REPO_USER@$PLUGIN_REPO_HOST:$PLUGIN_REPO_PATH"/plugins"
		fi
	fi


	#3: copy FEATURES files to repository
	if test "$featuresfilesflag" = 'true'; then
		filter_files "features" "$FEATURES"

		if test "$showfilestopushflag" = 'true'; then
			echo "\

This files will be sended to ROOT/features:
$FILES_TO_COPY"

		else
			echo "Copying FEATURES files to server..."
			$COPY_FILES_CMD $FILES_TO_COPY $PLUGIN_REPO_USER@$PLUGIN_REPO_HOST:$PLUGIN_REPO_PATH"/features"
		fi
	fi
	
}

parse_args "$@"
do_actions

cd $cwd
