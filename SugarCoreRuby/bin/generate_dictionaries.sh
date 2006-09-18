#!/bin/sh

XSLTPROC=`which xsltproc`

$XSLTPROC --stringparam outputtype 'ic' --output data/ic-dictionary.xml xslt/derive_dictionary.xslt data/dictionary.xml
$XSLTPROC --stringparam outputtype 'dkfz' --output data/dkfz-dictionary.xml xslt/derive_dictionary.xslt data/dictionary.xml