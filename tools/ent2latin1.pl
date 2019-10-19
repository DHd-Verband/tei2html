use strict;
use warnings;
while (<>) {

    my $line = $_;

    $line =~ s/\&iexcl;/�/g;
    $line =~ s/\&iquest;/�/g;
    $line =~ s/\&raquo;/�/g;
    $line =~ s/\&laquo;/�/g;

    $line =~ s/\&pm;/�/g;
    $line =~ s/\&mult;/�/g;
    $line =~ s/\&div;/�/g;

    $line =~ s/\&cent;/�/g;
    $line =~ s/\&pound;/�/g;
    $line =~ s/\&yen;/�/g;

    $line =~ s/\&sect;/�/g;

    $line =~ s/\&Aacute;/�/g;
    $line =~ s/\&aacute;/�/g;
    $line =~ s/\&Agrave;/�/g;
    $line =~ s/\&agrave;/�/g;
    $line =~ s/\&Acirc;/�/g;
    $line =~ s/\&acirc;/�/g;
    $line =~ s/\&Auml;/�/g;
    $line =~ s/\&auml;/�/g;
    $line =~ s/\&Atilde;/�/g;
    $line =~ s/\&atilde;/�/g;
    $line =~ s/\&Aring;/�/g;
    $line =~ s/\&aring;/�/g;
    $line =~ s/\&AElig;/�/g;
    $line =~ s/\&aelig;/�/g;

    $line =~ s/\&Ccedil;/�/g;
    $line =~ s/\&ccedil;/�/g;

    $line =~ s/\&ETH;/�/g;
    $line =~ s/\&eth;/�/g;

    $line =~ s/\&Eacute;/�/g;
    $line =~ s/\&eacute;/�/g;
    $line =~ s/\&Egrave;/�/g;
    $line =~ s/\&egrave;/�/g;
    $line =~ s/\&Ecirc;/�/g;
    $line =~ s/\&ecirc;/�/g;
    $line =~ s/\&Euml;/�/g;
    $line =~ s/\&euml;/�/g;

    $line =~ s/\&Iacute;/�/g;
    $line =~ s/\&iacute;/�/g;
    $line =~ s/\&Igrave;/�/g;
    $line =~ s/\&igrave;/�/g;
    $line =~ s/\&Icirc;/�/g;
    $line =~ s/\&icirc;/�/g;
    $line =~ s/\&Iuml;/�/g;
    $line =~ s/\&iuml;/�/g;

    $line =~ s/\&Ntilde;/�/g;
    $line =~ s/\&ntilde;/�/g;

    $line =~ s/\&Oacute;/�/g;
    $line =~ s/\&oacute;/�/g;
    $line =~ s/\&Ograve;/�/g;
    $line =~ s/\&ograve;/�/g;
    $line =~ s/\&Ocirc;/�/g;
    $line =~ s/\&ocirc;/�/g;
    $line =~ s/\&Ouml;/�/g;
    $line =~ s/\&ouml;/�/g;
    $line =~ s/\&Otilde;/�/g;
    $line =~ s/\&otilde;/�/g;
    $line =~ s/\&Oslash;/�/g;
    $line =~ s/\&oslash;/�/g;

    $line =~ s/\&szlig;/�/g;

    $line =~ s/\&THORN;/�/g;
    $line =~ s/\&thorn;/�/g;

    $line =~ s/\&Uacute;/�/g;
    $line =~ s/\&uacute;/�/g;
    $line =~ s/\&Ugrave;/�/g;
    $line =~ s/\&ugrave;/�/g;
    $line =~ s/\&Ucirc;/�/g;
    $line =~ s/\&ucirc;/�/g;
    $line =~ s/\&Uuml;/�/g;
    $line =~ s/\&uuml;/�/g;

    $line =~ s/\&Yacute;/�/g;
    $line =~ s/\&yacute;/�/g;
    $line =~ s/\&yuml;/�/g;

    print $line;
}
