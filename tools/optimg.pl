#!/usr/bin/perl -w

#
# Optimize various types of images.
#

use strict;
use File::Basename;

my $pngout = "pngout.exe";              # see http://advsys.net/ken/util/pngout.htm
my $jpegoptim = "jpegoptim.exe";        # see http://freshmeat.net/projects/jpegoptim/; http://pornel.net/jpegoptim
my $temp = "C:\\Temp";

my $errorCount = 0;
my $totalOriginalSize = 0;
my $totalResultSize = 0;
my $imagesConverted = 0;


sub list_recursively($)
{
    my ($directory) = @_;
    my @files = (  );

    unless (opendir(DIRECTORY, $directory))
    {
        print "Cannot open directory $directory!\n";
        exit;
    }

    # Read the directory, ignoring special entries "." and ".."
    @files = grep (!/^\.\.?$/, readdir(DIRECTORY));

    closedir(DIRECTORY);

    foreach my $file (@files)
    {
        if (-f "$directory\\$file")
        {
            handle_file("$directory\\$file");
        }
        elsif (-d "$directory\\$file")
        {
            list_recursively("$directory\\$file");
        }
    }
}


sub handle_file($)
{
    my ($file) = @_;

    if ($file =~ m/^(.*)\.(png|jpg)$/)
    {
        my $path = $1;
        my $extension = $2;
        my $base = basename($file, '.' . $extension);
        my $dirname = dirname($file);

        my $newfile = $dirname . '\\' . $base . '-copy.' . $extension;

        print "Compressing image: $file\n";
        my $originalSize = -s $file;

        if ($extension eq 'png') 
        {
            my $returnCode = system ("$pngout /y \"$file\" \"$file\"");
        }
        elsif ($extension eq 'jpg') 
        {
            my $returnCode = system ("$jpegoptim --strip-all \"$file\"");
        }

        my $resultSize = -s $file;

        $imagesConverted++;
        $totalOriginalSize += $originalSize;
        $totalResultSize += $resultSize;
    }
}


sub main()
{
    ## initial call ... $ARGV[0] is the first command line argument
    list_recursively($ARGV[0]);

    print "Number of images:          $imagesConverted\n";
    print "Number of errors:          $errorCount\n";
    print "Original size of images:   $totalOriginalSize bytes\n";
    print "New size of images:        $totalResultSize bytes\n";
    print "Space saved:               " . ($totalOriginalSize - $totalResultSize) . " bytes\n";
}


main();
