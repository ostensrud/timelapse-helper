#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use File::Copy;

use feature 'say';

die "Usage: $0 --config path/to/config\n" unless (@ARGV);

my $config;
my $fps = 24;

my $input_folder="./input/";
my $output_folder="output/";
my $config_folder="configs/";
my $work_folder="work/";
our %params;

GetOptions('config=s' => \$config,
           'fps=i' => \$fps) 
or die ("Error in command line arguments.");

sub read_config
{
  my $filename = $config_folder . $config;

  open (my $cfgfh, '<:encoding(UTF-8)',$filename) or die "Could not open $filename";
  while(<$cfgfh>) {
    my ($key, $value) = split('=', $_);
    chomp($value);
    $params{$key} = $value;
  }
}

sub copy_and_rename
{
  my $counter = 0;

  my $dir=$input_folder . $params{"FOLDERS"};

  opendir(my $dh, $dir) or die "Could not read directory $dir";
  #my @files = sort {$a cmp $b }readdir($dh);
  my @files = glob "$dir/*.JPG";
  

  foreach(@files) {
    next unless $_ =~ /\.JPG$/;
    my $new_file = $work_folder . "file_" . sprintf("%04d", $counter++) . ".jpg";
    copy($_, $new_file) or die "Could not copy $!";
  }

}

sub cleanup
{
  unlink glob $work_folder . "/*";
}

sub resize
{
  # resize all images;
}

sub make_movie
{
  # make the movie
}

eval {
  say "Reading config...";
  read_config();

  say "Copying and renaming files...";
  copy_and_rename();

  say "Cleaning up...";
  cleanup();

}; 

if ($@) {
  say $@;
}
