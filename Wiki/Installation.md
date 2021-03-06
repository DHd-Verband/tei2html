# Required Downloads #

The `tei2html` code has a range of dependencies on third-party software. This page lists those.


## Saxon ##

An XSLT 3.0 processor is required for `tei2html`, any XSLT 3.0 processor should work, however, I've developed these stylesheets with Saxon (using the freely available version Saxon HE).

You should download a reasonable recent version of Saxon-HE product from [saxonica.com](http://www.saxonica.com/products.html). I will take care `tei2html` will continue to work with the free versions of Saxon, no matter how tempting the additional features in the paid versions are (such as higher order functions, binary file handling, etc.)


## Java ##

Saxon-HE requires Java.

Make sure that the java executables can be found on the path.

If you do not have Java, you can download it from http://java.com/en/


## Perl ##

If you are using the provided Perl scripts to glue things together, you'll need a Perl interpreter.

For Windows, my advise is to download [Strawberry Perl](http://strawberryperl.com/). Use either the 32 or 64 bits version, to match your system.

*Note* Upgrading Strawberry Perl does not work properly: please saveguard local installations in your site directory before upgrading, as the uninstaller will throw those files away.

### Packages used ###

* Image::Size
* Lingua::BO::Wylie         (Only for Tibetan support: download from [www.thlib.org](https://www.thlib.org/reference/transliteration/wyconverter.php))
* HTML::Entities;
* Text::Levenshtein::XS 
* Statistics::Descriptive
* File::Basename
* Getopt::Long
* Image::Info 
* MIME::Base64
* XML::XPath
* Unicode::Normalize

If you are missing a package, it can easily be installed using CPAN: `cpan install <package>`.

## SX, NSGML ##

_Optional, only needed you want to use SGML as source format._

SX is an SGML to XML translator, and NSGML is an SGML validator, part of the SP package. Since XSLT only supports XML, you will need both those two tools to be able to work with SGML. They can be downloaded from [James Clark website](http://www.jclark.com/). For windows, get [sp 1.3.4](ftp://ftp.jclark.com/pub/sp/win32/sp1_3_4.zip).

To enable SX and NSGML to understand your document types, you need to configure a catalog of DTDs (Which maps public DTDs to local resources containing their definitions). The scripts assume this is located in a file named `tools/pubtext/CATALOG`.

You will need to add the `teilite.dtd` to the CATALOG. This DTD can be found here: http://www.tei-c.org/Vault/P4/Lite/DTD/

A short explanation of Catalog files can be found in the SP documentation on James Clark's website referenced above.


## ZIP ##

To compress ePub files, you will need a zip utility. `tei2html` uses [info-zip](http://www.info-zip.org/Zip.html) to handle the peculiar requirements of the ePub format. (See e.g. [this blog entry on creating ePub files](http://www.snee.com/bobdc.blog/2008/03/creating-epub-files.html).)


## Node.js ##

_Optional, only needed when you use mathematical formulas in TeX notation._

To convert mathematical formulas in TeX format to a format that can be included in static HTML pages, you will need to install the following:

  * Node.js (see the [node.js website](https://nodejs.org/en/)).
  * mathjax-node-cli ([source at GitHub](https://github.com/mathjax/mathjax-node-cli), most conveniently installed by using `npm` after installing Node.js.


## Patc ##

_Optional, only needed when you use the transcription schemes for non-Latin scripts I use in SGML._

Patc (pattern changer) is a small utility written in C to do multiple find-and-replace actions at once. You will need a C compiler to get it to work. It enables you to execute multiple find-replace actions in an efficient way. Mostly used to change the transliteration of non-Roman scripts I've used. If you don't use that, you'll not need it. (I've successfully compiled this on a variety of platforms, including Unix, and Windows; a solution file for Visual Studio 7.0 is included; contact me if you need a Windows binary.)


## epubcheck ##

_Optional, only needed if you want to check generated ePubs._

Epubcheck is a tool to validate epub books, it can be obtained from: https://github.com/IDPF/epubcheck. Note that `tei2html` doesn't automatically generate correct ePubs: you can still do a lot of things that make ePubs non-conform, for example by including CSS3 constructs, or referring to resources in CSS and not including them in the ePub spine manually.

This tool also requires Java; the scripts assume you use `epubcheck-3.0.1.jar`, placed in the tools/lib subdirectory.


## Prince XML ##

_Optional, only needed if you want generated PDF output._

Note that Prince is a commercial product; a free version can be used for strictly private purposes, and downloaded from: https://www.princexml.com/. The free version does include a small icon on the first page to promote Prince. Shouldn't be a big nuisance.


# Configuration #

## Environment variables ##

To run `tei2html` from the command line, it will be practical to configure a number of environment variables, that is

  * set `TEI2HTML_HOME` to the location of the checked-out `tei2html` directory.
  * set `SAXON_HOME` to the location where Saxon is installed.
  * (_optional_) set `PRINCE_HOME` to the location where Prince is installed.

