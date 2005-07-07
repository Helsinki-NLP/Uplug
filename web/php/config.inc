<?php

//////////////////////////////////////////////////////////
// you should change the following settings
//////////////////////////////////////////////////////////

$BITEXT = 'ensvfbell.ces';   // sentence alignments of your bitext (full path)
$LANGPAIR = 'ensv';          // language IDs for your language pair
$INVLANG = 'sven';           // (and target -> source language)

$IDS = array();              // this is an array of all bitext segment IDs
for ($i=1;$i<4210;$i++){     // in your corpus ... maybe you should read this
    $IDS[] = 'ensvfbell'.$i; // from a file
}
$UPLUGHOME = 'uplug';        // the relative (or absolute) path to Uplug
                             // this has to be accessible for the PHP script!
$DATADIR = 'aligned';        // directory for saving data (has to be writable!)

///////////////////////////////////////////////////////////////////
// ... but you probably don't have to touch the settings below ...
///////////////////////////////////////////////////////////////////


$UPLUG = $UPLUGHOME.'/uplug';
$CLUEDIR = 'data/runtime';
$LANGCLUEDIR = $UPLUGHOME.'/lang/'.$LANGPAIR;

$CLUES = array(
    'dice' => $CLUEDIR.'/dice.dbm',                  // basic clues
    'mi' => $CLUEDIR.'/mi.dbm',
    'tscore' => $CLUEDIR.'/tscore.dbm',
    'sim' => $CLUEDIR.'/str.dbm',
    'gw' => $CLUEDIR.'/giza-word.dbm',               // giza clues
    'gwi' => $CLUEDIR.'/giza-word-i.dbm',
    'gp' => $CLUEDIR.'/giza-pos.dbm',
    'gpi' => $CLUEDIR.'/giza-pos-i.dbm',
    'gwp' => $CLUEDIR.'/giza-word-prefix.dbm',
    'gwpi' => $CLUEDIR.'/giza-word-prefix-i.dbm',
    'gws' => $CLUEDIR.'/giza-word-suffix.dbm',
    'gwsi' => $CLUEDIR.'/giza-word-suffix-i.dbm',
    'dl3x' => $CLUEDIR.'/dl3x.dbm',                  // dynamic clues
    'dl' => $CLUEDIR.'/dl.dbm',
    'dlp' => $CLUEDIR.'/dlp.dbm',
    'dlx' => $CLUEDIR.'/dlx.dbm',
    'dpx' => $CLUEDIR.'/dpx.dbm',
    'dp3x' => $CLUEDIR.'/dp3x.dbm',
    'dc3' => $CLUEDIR.'/dc3.dbm',
    'dc3p' => $CLUEDIR.'/dc3p.dbm',
    'dc3x' => $CLUEDIR.'/dc3x.dbm',
    $LANGPAIR.'p' => $LANGCLUEDIR.'/pos.dbm',         // static clues
    $LANGPAIR.'pp' => $LANGCLUEDIR.'/pos2.dbm',
    $LANGPAIR.'c' => $LANGCLUEDIR.'/chunk.dbm',


    'ep-'.$LANGPAIR.'-gw' => $LANGCLUEDIR.'/ep-giza-word-'.$LANGPAIR.'.dbm',
    'ep-'.$LANGPAIR.'-gwi' => $LANGCLUEDIR.'/ep-giza-word-'.$INVLANG.'.dbm'
);


?>
