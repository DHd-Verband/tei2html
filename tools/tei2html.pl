# tei2html.pl -- process a TEI file.

use strict;

use File::Temp qw(tmpnam);
use Getopt::Long;


#==============================================================================
# Configuration

my $toolsdir        = "C:\\Users\\Jeroen\\Documents\\eLibrary\\Tools\\tei2html\\tools";   # location of tools
my $patcdir         = $toolsdir . "\\patc\\transcriptions"; # location of patc transcription files.
my $xsldir          = "C:\\Users\\Jeroen\\Documents\\eLibrary\\Tools\\tei2html";  # location of xsl stylesheets
my $tmpdir          = "C:\\Temp";                       # place to drop temporary files
my $bindir          = "C:\\Bin";
my $catalog         = "C:\\Bin\\pubtext\\CATALOG";      # location of SGML catalog (required for nsgmls and sx)

my $prince          = "\"C:\\Program Files (x86)\\Prince\\Engine\\bin\\prince.exe\"";
my $saxon2          = "\"C:\\Program Files (x86)\\Java\\jre6\\bin\\java.exe\" -jar C:\\bin\\saxonhe9\\saxon9he.jar "; # (see http://saxon.sourceforge.net/)

my $epubcheck       = "\"C:\\Program Files (x86)\\Java\\jre6\\bin\\java.exe\" -jar C:\\bin\\epubcheck\\epubcheck-1.0.4.jar ";
my $epubpreflight   = "\"C:\\Program Files (x86)\\Java\\jre6\\bin\\java.exe\" -jar C:\\bin\\epubcheck\\epubpreflight-0.1.0.jar ";

#==============================================================================
# Arguments

my $makeTXT             = 1;
my $makeHTML            = 1;
my $makePDF             = 0;
my $makeEPUB            = 0;
my $makeReport          = 1;
my $customStylesheet    = "custom.css.xml";

GetOptions (
    't' => \$makeTXT,
    'h' => \$makeHTML,
    'e' => \$makeEPUB,
    'p' => \$makePDF,
    'r' => \$makeReport,
    'c=s' => \$customStylesheet);


my $argNumber = 0;
my $filename = $ARGV[$argNumber];


#==============================================================================


my $nsgmlresult = 0;



if ($filename eq "")
{
    my ($directory) = ".";
    my @files = ( );
    opendir(DIRECTORY, $directory) or die "Cannot open directory $directory!\n";
    @files = readdir(DIRECTORY);
    closedir(DIRECTORY);

    foreach my $file (@files)
    {
        if ($file =~ /^([A-Za-z0-9-]*?)(-([0-9]+\.[0-9]+))?\.tei$/)
        {
            processFile($file);
        }
    }
}
else
{
    processFile($filename);
}


#
# processFile -- process a TEI file.
#
sub processFile($)
{
    my $filename = shift;

    if ($filename eq "" || $filename !~ /\.tei$/)
    {
        die "File: '$filename' is not a .TEI file\n";
    }

    $filename =~ /^([A-Za-z0-9-]*?)(-([0-9]+\.[0-9]+))?\.tei$/;
    my $basename    = $1;
    my $version     = $3;
    my $currentname = $filename;

    
    print "Processing TEI-file '$basename' version $version\n";

    sgml2xml($filename, $basename . ".xml");


    # convert from TEI P4 to TEI P5  (experimental)
    # system ("$saxon2 $basename.xml $xsldir/p4top5.xsl > $basename-p5.xml");

    collectImageInfo();

    my $pwd = `pwd`;
    chop($pwd);
    $pwd =~ s/\\/\//g;

    # Since the XSLT processor cannot find files easily, we have to provide the imageinfo file with a full path in a parameter.
    my $fileImageParam = "";
    if (-f "imageinfo.xml")
    {
        $fileImageParam = "imageInfoFile=\"file:/$pwd/imageinfo.xml\"";
    }

    # Since the XSLT processor cannot find files easily, we have to provide the custom CSS file with a full path in a parameter.
    my $cssFileParam = "";
    if (-f $customStylesheet)
    {
        print "Adding custom stylesheet: $customStylesheet ...\n";
        $cssFileParam = "customCssFile=\"file:/$pwd/$customStylesheet\"";
    }

    my $opfManifestFileParam = "";
    if (-f "opf-manifest.xml")
    {
        print "Adding additional elements for the OPF manifest...\n";
        $opfManifestFileParam = "opfManifestFile=\"file:/$pwd/opf-manifest.xml\"";
    }


    if ($makeHTML == 1) 
    {
        my $tmpFile = tmpnam();
        print "Create HTML version...\n";
        system ("$saxon2 $basename.xml $xsldir/tei2html.xsl $fileImageParam $cssFileParam > $tmpFile");
        system ("perl $toolsdir/wipeids.pl $tmpFile > $basename.html");
        system ("tidy -m -wrap 72 -f $basename-tidy.err $basename.html");
        unlink($tmpFile);
    }

    if ($makePDF == 1)
    {
        my $tmpFile1 = tmpnam();
        my $tmpFile2 = tmpnam();

        # Do the HTML transform again, but with an additional parameter to apply Prince specific rules in the XSLT transform.
        print "Create PDF version...\n";
        system ("$saxon2 $basename.xml $xsldir/tei2html.xsl $fileImageParam $cssFileParam optionPrinceMarkup=\"Yes\" > $tmpFile1");
        system ("perl $toolsdir/wipeids.pl $tmpFile1 > $tmpFile2");
        system ("sed \"s/^[ \t]*//g\" < $tmpFile2 > $basename-prince.html");
        system ("$prince $basename-prince.html $basename.pdf");

        unlink($tmpFile1);
        unlink($tmpFile2);
    }

    if ($makeEPUB == 1)
    {
        my $tmpFile = tmpnam();
        print "Create ePub version...\n";
        system ("$saxon2 $basename.xml $xsldir/tei2epub.xsl $fileImageParam $cssFileParam $opfManifestFileParam basename=\"$basename\" > $tmpFile");

        system ("del $basename.epub");
        chdir "epub";
        system ("zip -Xr9Dq ../$basename.epub mimetype");
        system ("zip -Xr9Dq ../$basename.epub * -x mimetype");
        chdir "..";

        # system ("$epubcheck $basename.epub");
        system ("$epubpreflight $basename.epub");
        unlink($tmpFile);
    }

    if ($makeTXT == 1)
    {
        my $tmpFile1 = tmpnam();
        my $tmpFile2 = tmpnam();

        print "Create text version...\n";
        system ("perl $toolsdir/exNotesHtml.pl $filename");
        system ("cat $filename.out $filename.notes > $tmpFile1");
        system ("perl $toolsdir/tei2txt.pl $tmpFile1 > $tmpFile2");
        system ("fmt -sw72 $tmpFile2 > $basename.txt");
        system ("gutcheck $basename.txt > $basename.gutcheck");
        system ("$bindir\\jeebies $basename.txt > $basename.jeebies");

        unlink("$filename.out");
        unlink("$filename.notes");
        unlink($tmpFile1);
        unlink($tmpFile2);

        # check for required manual intervetions
        my $containsError = system ("grep -q \"\\[ERROR:\" $basename.txt");
        if ($containsError == 0)
        {
            print "NOTE: Please check $basename.txt for [ERROR: ...] messages.\n";
        }
        my $containsTable = system ("grep -q \"TABLE\" $basename.txt");
        if ($containsTable == 0)
        {
            print "NOTE: Please check $basename.txt for TABLEs.\n";
        }
        my $containsFigure = system ("grep -q \"FIGURE\" $basename.txt");
        if ($containsFigure == 0)
        {
            print "NOTE: Please check $basename.txt for FIGUREs.\n";
        }
    }

    if ($makeReport == 1)
    {
        my $tmpFile = tmpnam();
        print "Report on word usage...\n";
        system ("perl $toolsdir/ucwords.pl $basename.xml > $tmpFile");
        system ("perl $toolsdir/ent2ucs.pl $tmpFile > $basename-words.html");
        unlink($tmpFile);

        # Create a text heat map.
        if (-f "heatmap.xml")
        {
            print "Create text heat map...\n";
            system ("$saxon2 heatmap.xml $xsldir/tei2html.xsl customCssFile=\"file:style\\heatmap.css.xml\" > $basename-heatmap.html");
        }
    }

    print " Done!\n";

    if ($nsgmlresult != 0)
    {
        print "WARNING: NSGML found validation errors in $filename.\n";
    }
}


#
# sgml2xml -- convert a file from SGML TEI to XML, also converting various notations if needed.
#
sub sgml2xml($$)
{
    my $sgmlFile = shift;
    my $xmlFile = shift;

    print "Convert SGML file '$sgmlFile' to XML file '$xmlFile'.\n";

    # Translate Latin-1 characters to entities
    my $currentFile = tmpnam();
    print "Convert Latin-1 characters to entities...\n";
    system ("patc -p $toolsdir/win2sgml.pat $sgmlFile $currentFile");

    $currentFile = transcribeGreek($currentFile);
    $currentFile = transcribeNotation($currentFile, "<AR>", "Arabic",               "$patcdir/arabic/ar2sgml.pat");
    $currentFile = transcribeNotation($currentFile, "<AS>", "Assamese",             "$patcdir/indic/as2ucs.pat");
    $currentFile = transcribeNotation($currentFile, "<BN>", "Bengali",              "$patcdir/indic/bn2ucs.pat");
    $currentFile = transcribeNotation($currentFile, "<HB>", "Hebrew",               "$patcdir/hebrew/he2sgml.pat");
    $currentFile = transcribeNotation($currentFile, "<TL>", "Tagalog (Baybayin)",   "$patcdir/tagalog/tagalog.pat");
    $currentFile = transcribeNotation($currentFile, "<TM>", "Tamil",                "$patcdir/indic/tm2ucs.pat");

    print "Check SGML...\n";
    $nsgmlresult = system ("nsgmls -c \"$catalog\" -wall -E5000 -g -f $sgmlFile.err $currentFile > $sgmlFile.nsgml");
    system ("rm $sgmlFile.nsgml");

    my $tmpFile1 = tmpnam();
    my $tmpFile2 = tmpnam();
    my $tmpFile3 = tmpnam();
    my $tmpFile4 = tmpnam();

    print "Convert SGML to XML...\n";
    # hide entities for parser
    system ("sed \"s/\\&/|xxxx|/g\" < $currentFile > $tmpFile1");
    system ("sx -c $catalog -E10000 -xlower -xcomment -xempty -xndata  $tmpFile1 > $tmpFile2");
    system ("$saxon2 $tmpFile2 $xsldir/tei2tei.xsl > $tmpFile3");
    # restore entities
    system ("sed \"s/|xxxx|/\\&/g\" < $tmpFile3 > $tmpFile4");
    system ("perl $toolsdir/ent2ucs.pl $tmpFile4 > $xmlFile");

    unlink($tmpFile1);
    unlink($tmpFile2);
    unlink($tmpFile3);
    unlink($tmpFile4);
}


#
# transcribeGreek -- transcribe Greek in a specific notation to Greek script, and add transcription in choice elements.
#
sub transcribeGreek($)
{
    my $currentFile = shift;

    # Check for presence of Greek transcription
    my $containsGreek = system ("grep -q \"<GR>\" $currentFile");
    if ($containsGreek == 0)
    {
        my $tmpFile1 = tmpnam();
        my $tmpFile2 = tmpnam();
        my $tmpFile3 = tmpnam();

        print "Converting Greek transcription...\n";
        print "Adding Greek transcription in choice elements...\n";
        system ("perl $toolsdir/gr2trans.pl -x $currentFile > $tmpFile1");
        system ("patc -p $patcdir/greek/grt2sgml.pat $tmpFile1 $tmpFile2");
        system ("patc -p $patcdir/greek/gr2sgml.pat $tmpFile2 $tmpFile3");
        $currentFile = $tmpFile3;
        unlink($tmpFile1);
        unlink($tmpFile2);
    }
    return $currentFile;
}


#
# transcribeNotation -- transcribe some specific notation using patc.
#
sub transcribeNotation($$$$)
{
    my $currentFile = shift;
    my $tag = shift;
    my $name = shift;
    my $patternFile = shift;

    # Check for presence of transcription notation
    my $containsNotation = system ("grep -q \"$tag\" $currentFile");
    if ($containsNotation == 0)
    {
        my $tmpFile = tmpnam();

        print "Converting $name transcription...\n";
        system ("patc -p $patternFile $currentFile $tmpFile");
        $currentFile = $tmpFile;
    }
    return $currentFile;
}


#
# collectImageInfo -- collect some information about images in the imageinfo.xml file.
#
# add -c to called script arguments to also collect contour information with this script.
#
sub collectImageInfo()
{
    if (-d "images")
    {
        print "Collect image dimensions...\n";
        system ("perl $toolsdir/imageinfo.pl images > imageinfo.xml");
    }
    elsif (-d "Gutenberg\\images")
    {
        print "Collect image dimensions...\n";
        system ("perl $toolsdir/imageinfo.pl -s Gutenberg\\images > imageinfo.xml");
    }
}
