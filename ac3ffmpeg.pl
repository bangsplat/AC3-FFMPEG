#!/usr/bin/perl

use strict;	# Enforce some good programming rules
use Getopt::Long;
use File::Find;

#
# AC3-FFMPEG
# 
# use ffmpeg to encode AC-3 files
# 
# written by Theron Trowbridge
# http://therontrowbridge.com
# 
# version 0
# created 2013-11-09
# modified 2013-11-09
# 
# use six mono WAVE files as sources
# using standard channel naming convention
# 	"_L" for left
# 	"_R" for right
# 	"_C" for center
# 	"_LFE" for LFE
# 	"_LS" for left surround
# 	"_RS" for right surround
# 
# here's the command we want to use:
# 
# ffmpeg -i left.wav -i right.wav -i center.wav -i lfe.wav -i left_surround.wav
# -i right_surround -ab 640k -dialnorm “-27” -center_mixlev 0.707 -surround_mixlev 0.707
# -filter_complex “[0:a][1:a][2:a][3:a][4:a][5:a] amerge=inputs=6” output_surround.ac3 
#
# search through the starting folder looking for ".wav" files and build a list
# look through list looking for each channel
# assuming we find them all, build the command and execute
# 
# this will require having ffmpeg installd and on the path
# have an option to output the command to STDOUT
# 

my ( $directory_param, $execute_param, $help_param, $version_param, $debug_param );

# get command line options
GetOptions( 'directory|d=s'	=>	\$directory_param,
			'execute|x!'	=>	\$execute_param,
			'debug'			=>	\$debug_param,
			'help|?'		=>	\$help_param,
			'version'		=>	\$version_param );

if ( $debug_param ) {
	print "DEBUG: passed parameters:\n";
	print "directory_param: $directory_param\n";
	print "execute_param: $execute_param\n";
	print "debug_param: $debug_param\n";
	print "help_param: $help_param\n";
	print "version_param: $version_param\n\n";
}

if ( $version_param ) {
	print "ac3ffmpeg.pl version 0\n";
	exit;
}

if ( $help_param ) {
	print "ac3ffmpeg.pl\n";
	print "version 0\n\n";
	print "--directory | -d <path>\n";
	print "\toptional - defaults to current working directory\n";
	print "--[no]execute | -[no]x\n";
	print "\tdefault is true - execute the ffmpeg command\n";
	print "\trequires ffmpeg to be installed and on the search path\n";
	print "\tif false, outputs command to STDOUT\n";
	print "--version\n";
	print "\tdisplay version number\n";
	print "--help | -?\n";
	print "\tdisplay this text\n";
	exit;
}







