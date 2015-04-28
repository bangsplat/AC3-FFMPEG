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
# version 1.1
# created 2013-11-09
# modified 2015-04-28
# 
# use six mono WAVE files as sources
# using standard channel naming convention
# 	"_L" or "_LEFT" for left
# 	"_R" or "_RIGHT" for right
# 	"_C" or "_CENTER" for center
# 	"_LFE" or "_SUB" for LFE
# 	"_LS" or "_LSUR" for left surround
# 	"_RS" or "_RSUR" for right surround
# 
# here's the command we want to use:
# 
# ffmpeg -i left.wav -i right.wav -i center.wav -i lfe.wav -i left_surround.wav
# -i right_surround -ab 640k -dialnorm "-24" -center_mixlev 0.707 -surround_mixlev 0.707
# -filter_complex "[0:a][1:a][2:a][3:a][4:a][5:a] amerge=inputs=6" output_surround.ac3 
#
# search through the starting folder looking for ".wav" files and build a list
# look through list looking for each channel
# assuming we find them all, build the command and execute
# 
# this will require having ffmpeg installd and on the path
# have an option to output the command to STDOUT
#
# version 1.1 - add ability to adjust dialnorm value 
# 	also changing default dialnorm value to -24 dB (was -27 dB)

my ( $directory_param, $output_param, $execute_param, $recurse_param, $help_param, $dialnorm_param, $version_param, $debug_param );
my ( @wave_files, $num_wave_files );
my ( $left_channel, $right_channel, $center_channel, $lfe_channel, $left_surround_channel, $right_surround_channel );
my ( $ffmpeg_command );

# get command line options
GetOptions( 'directory|d=s'	=>	\$directory_param,
			'output|o=s'	=>	\$output_param,
			'execute|x!'	=>	\$execute_param,
			'recurse|r!'	=>	\$recurse_param,
			'dialnorm|d=s'	=>	\$dialnorm_param,
			'debug'			=>	\$debug_param,
			'help|?'		=>	\$help_param,
			'version'		=>	\$version_param );

if ( $debug_param ) {
	print "DEBUG: passed parameters:\n";
	print "directory_param: $directory_param\n";
	print "output_param: $output_param\n";
	print "execute_param: $execute_param\n";
	print "recurse_param: $recurse_param\n";
	print "dialnorm_param: $dialnorm_param\n";
	print "debug_param: $debug_param\n";
	print "help_param: $help_param\n";
	print "version_param: $version_param\n\n";
}

if ( $version_param ) {
	print "ac3ffmpeg.pl version 1.1\n";
	exit;
}

if ( $help_param ) {
	print "ac3ffmpeg.pl\n";
	print "version 1.1\n\n";
	print "--directory | -d <path>\n";
	print "\toptional - defaults to current working directory\n";
	print "--output | -o\n";
	print "\toutput file\n";
	print "\toptional - default is the left channel basename plus \".ac3\"\n";
	print "--[no]execute | -[no]x\n";
	print "\tdefault is true - execute the ffmpeg command\n";
	print "\trequires ffmpeg to be installed and on the search path\n";
	print "\tif false, outputs command to STDOUT\n";
	print "--[no]recurse | -[no]r\n";
	print "\tlook in subfolders for WAVE files\n";
	print "\tdefault is false - only look in current working directory\n";
	print "--dialnorm | -d <value>\n";
	print "\tuse non-default dialnorm value\n";
	print "\tdefault value is -24 dB\n";
	print "--version\n";
	print "\tdisplay version number\n";
	print "--help | -?\n";
	print "\tdisplay this text\n";
	exit;
}

# set parameter defaults
if ( $directory_param eq undef ) { ; }
if ( $execute_param eq undef ) { $execute_param = 1; }
if ( $recurse_param eq undef ) { $recurse_param = 0; }
# dialnorm is a bit more complicated
if ( $dialnorm_param eq undef ) { $dialnorm_param = 24; }
$dialnorm_param = abs( $dialnorm_param );	# remove the negative sign if it was used
$dialnorm_param = int( $dialnorm_param );	# strip any fractional part
# make sure it is inside the appropriate range:
if ( ( abs( $dialnorm_param ) lt 1 ) || ( abs( $dialnorm_param ) gt 31 ) ) { $dialnorm_param = 24; }

if ( $debug_param ) {
	print "DEBUG: adjusted parameters:\n";
	print "directory_param: $directory_param\n";
	print "output_param: $output_param\n";
	print "execute_param: $execute_param\n";
	print "recurse_param: $recurse_param\n";
	print "dialnorm_param: $dialnorm_param\n";
	print "debug_param: $debug_param\n";
	print "help_param: $help_param\n";
	print "version_param: $version_param\n\n";
}

# find all the WAVE files
find( \&find_wave_files, "." );

$num_wave_files = @wave_files;

if ( $debug_param ) { print "DEBUG: Number of WAVE files found: $num_wave_files\n"; }
if ( $debug_param ) { print "DEBUG: WAVE files: @wave_files\n"; }

# find left channel
for ( my $i = 0; $i < $num_wave_files; $i++ ) {
	if ( ( @wave_files[$i] =~ /_L\./i ) || ( @wave_files[$i] =~ /_LEFT\./i ) ) {
		$left_channel = @wave_files[$i];
	}
}
if ( $debug_param ) { print "DEBUG: Left WAVE file: $left_channel\n"; }

# find right channel
for ( my $i = 0; $i < $num_wave_files; $i++ ) {
	if ( ( @wave_files[$i] =~ /_R\./i ) || ( @wave_files[$i] =~ /_RIGHT\./i ) ) {
		$right_channel = @wave_files[$i];
	}
}
if ( $debug_param ) { print "DEBUG: Right WAVE file: $right_channel\n"; }

# find center channel
for ( my $i = 0; $i < $num_wave_files; $i++ ) {
	if ( ( @wave_files[$i] =~ /_C\./i ) || ( @wave_files[$i] =~ /_CENTER\./i ) ) {
		$center_channel = @wave_files[$i];
	}
}
if ( $debug_param ) { print "DEBUG: Center WAVE file: $center_channel\n"; }

# find LFE channel
for ( my $i = 0; $i < $num_wave_files; $i++ ) {
	if ( ( @wave_files[$i] =~ /_LFE\./i ) || ( @wave_files[$i] =~ /_SUB\./i ) ) {
		$lfe_channel = @wave_files[$i];
	}
}
if ( $debug_param ) { print "DEBUG: LFE WAVE file: $lfe_channel\n"; }

# find left surround channel
for ( my $i = 0; $i < $num_wave_files; $i++ ) {
	if ( ( @wave_files[$i] =~ /_LS\./i ) || ( ( @wave_files[$i] =~ /_LSUR\./i ) ) ) {
		$left_surround_channel = @wave_files[$i];
	}
}
if ( $debug_param ) { print "DEBUG: Left surround WAVE file: $left_surround_channel\n"; }

# find right surround channel
for ( my $i = 0; $i < $num_wave_files; $i++ ) {
	if ( ( @wave_files[$i] =~ /_RS\./i ) || ( @wave_files[$i] =~ /_RSUR\./i ) ) {
		$right_surround_channel = @wave_files[$i];
	}
}
if ( $debug_param ) { print "DEBUG: Right surround WAVE file: $right_surround_channel\n"; }

# make sure we have all the channels we need
if ( $left_channel eq undef ) { die "ERROR: can't find left channel WAVE file\n"; }
if ( $right_channel eq undef ) { die "ERROR: can't find right channel WAVE file\n"; }
if ( $center_channel eq undef ) { die "ERROR: can't find center channel WAVE file\n"; }
if ( $lfe_channel eq undef ) { die "ERROR: can't find LFE channel WAVE file\n"; }
if ( $left_surround_channel eq undef ) { die "ERROR: can't find left surround channel WAVE file\n"; }
if ( $right_surround_channel eq undef ) { die "ERROR: can't find right surround channel WAVE file\n"; }

# come up with our default output file name if one was not supplied
if ( $output_param eq undef ) {
	$output_param = $center_channel;
	$output_param =~ s/_[^_]*?\.wav$/_51\.ac3/i;
}

# build the ffmpeg command
$ffmpeg_command = "ffmpeg -i $left_channel -i $right_channel -i $center_channel " .
	"-i $lfe_channel -i $left_surround_channel -i $right_surround_channel " .
	"-ab 640k -dialnorm \"-$dialnorm_param\" -center_mixlev 0.707 -surround_mixlev 0.707 " .
	"-filter_complex \"[0:a][1:a][2:a][3:a][4:a][5:a] amerge=inputs=6\" $output_param";

if ( $debug_param ) { print( "DEBUG: ffmpeg command: $ffmpeg_command\n" ); }

if ( $execute_param ) { system( $ffmpeg_command ); }
else { print "$ffmpeg_command\n"; }


sub find_wave_files {
	if ( /\.wav$/i && ( $recurse_param || $File::Find::dir eq "." ) ) {
		push @wave_files, clean_path( $File::Find::name );
	}
}

sub clean_path {
	my $path = @_[0];
	$path =~ s/\\/\//g;		# turn around any backwards slashes
	$path =~ s/\/\.\//\//;	# remove extra "/./"
	$path =~ s/^\.\///;
	return( $path );

	###
	# 	this works on Mac/Linux and on Windows if all the WAVE files are local
	#	need to make sure we don't screw up file paths on Windows machines
	###

}
