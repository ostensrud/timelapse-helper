#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use File::Copy;

use feature 'say';

die "Usage: $0 --config path/to/config\n" unless (@ARGV);

my $config;
my $resize = 0;
my $fps = 24;

my $input_folder="input";
my $output_folder="output";
my $config_folder="configs";
my $work_folder="work";
my $resize_folder=$work_folder."/resize";
our %params;

GetOptions('config=s' => \$config,
           'fps=i' => \$fps,
           'resize' => \$resize) 
or die ("Error in command line arguments.");

sub read_config
{
  my $filename = "$config_folder/$config";

  open (my $cfgfh, '<:encoding(UTF-8)',$filename) or die "Could not open $filename";
  while(<$cfgfh>) {
    my ($key, $value) = split('=', $_);
    chomp($value);
    $params{$key} = $value;
  }
}

sub verify_config
{ 
  my @missing_params;
  push @missing_params, "PROJECT_NAME" unless exists $params{"PROJECT_NAME"};
  push @missing_params, "FOLDERS" unless exists $params{"FOLDERS"};

  if (@missing_params > 0) {
    my $msg = "Invalid configuration. Missing parameters:\n" . join (",", @missing_params);
    die $msg;
  }
}

sub copy_and_rename
{
  my $counter = 0;

  my @dirs=map { "$input_folder/$_" } split(',', $params{"FOLDERS"});

  foreach my $dir(@dirs) {
    say "Copying $dir";
    opendir(my $dh, $dir) or die "Could not read directory $dir";
    my @files = glob "$dir/*.JPG";
  
    foreach(@files) {
      next unless $_ =~ /\.JPG$/;
      my $new_file = $work_folder . "/file_" . sprintf("%04d", $counter++) . ".jpg";
      copy($_, $new_file) or die "Could not copy $!";
    }
  }

}

sub cleanup
{
  unlink glob $resize_folder . "/*";
  unlink glob $work_folder . "/*";
}

sub resize
{
  #`mogrify -resize 1920x1080! $work_folder/*.jpg`
  `mogrify -resize 1920x1080! -path $resize_folder $work_folder/*.jpg`
}

sub make_movie
{
  # make the movie
  `avconv -y -q:v 3 -framerate 30 -i '$resize_folder/file_%4d.jpg' -vcodec libx264 $output_folder/$params{"PROJECT_NAME"}.mp4`
}

eval {
  say "Reading config...";
  read_config();

  say "Veryfing configuration...";
  verify_config();

  say "Copying and renaming files...";
  copy_and_rename();

  if ($resize) {
    say "Resizing(this might take a while)...";
    resize();
  }

  say "Making the movie...";
  make_movie();

  say "Cleaning up...";
  cleanup();
}; 

if ($@) {
  say $@;
}
