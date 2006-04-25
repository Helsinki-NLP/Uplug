<?php 

session_start() ;

if (isset($_POST['newcorpus'])){
    unset($_SESSION['corpus']);
    session_destroy();
    session_start();
}

if (isset($_POST['corpus'])){
    $_SESSION['corpus'] = $_POST['corpus'];
}

?>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
                      "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<title>Interactive Clue Aligner (ICA)</title>
<link rel="stylesheet" href="ica.css" type="text/css">
<meta http-equiv="Content-Type" content="text/html;charset=utf-8" >

<?php include('include/java.inc'); ?>

</head>
<body>


<h2><a href="index.php">ISA &amp; ICA</a> / Interactive Clue Alignment
<?php if (isset($_SESSION['corpus'])){echo " / ".$_SESSION['corpus'];} ?>
</h2>

<div class="help"><a  target="_blank" href="doc/ica.html">Help?</a></div>

<?php


/////////////////////////////////////////////////////////////////
// change settings in the config.inc file
// (you have to specify parameters of the corpus you want to use!)
/////////////////////////////////////////////////////////////////
// open issues:
//    - changing config.inc is painful
//    - works only for latin-1 right now 
//      (read align output in latin-1 and saves alignments in UTF-8)
//      conversion is hard-coded (see save_alignments in alignment.inc)
//    - displaying a matrix and links for long sentences is not user friendly
//      (and slow)
//    - learning from alignment changes would be nice!


/*
if (file_exists('include/config.ica')){
    include('include/config.ica');
}
else{
    include('include/config.inc');
}
*/

include('include/display.inc');
include('include/cgi.inc');
include('include/wordalign.inc');
include('include/xmldoc.inc');

if (isset($_SESSION['corpus'])){
    if (file_exists('corpora/'.$_SESSION['corpus'].'/config.inc')){
	include('corpora/'.$_SESSION['corpus'].'/config.inc');
    }
    elseif (file_exists('corpora/'.$_SESSION['corpus'].'/config.ica')){
	include('corpora/'.$_SESSION['corpus'].'/config.ica');
    }
    else{
	echo "<br /><br /><br /><h2 style=\"color:red\">Cannot find ICA configuration file for corpus '".$_SESSION['corpus']."'!</h2>";
	echo '<br /><h3>Select a corpus:</h3><p>';
	select_corpus_radio('ica');
	echo '</p></body></html>';
	exit;
    }
}
else{
    echo '<br /><br /><br /><br /><h3>Select a corpus:</h3><p>';
    select_corpus_radio('ica');
    echo '</p></body></html>';
    exit;
}


if (!file_exists($DATADIR)){
    mkdir($DATADIR);
}
if (!file_exists($DATADIR.'/align')){
    mkdir($DATADIR.'/align');
}
if (file_exists($BITEXT) && !file_exists($BITEXT.'.ids')){
    make_id_file($BITEXT,$BITEXT.'.ids');
}
if (file_exists($BITEXT.'.ids')){ // file with sentence link IDs
    $IDS = file($BITEXT.'.ids');  // used by ICA
}


if ($_REQUEST['save'] && !$DISABLE_SAVE){
    echo '<div class="status">';
    link_clusters();
    get_alignments();
    save_alignments();
    echo '</div>';
}

// put all CGI data into the SESSION variable!

if (isset($_POST['id'])){
    foreach ($CLUES as $clue => $file){
	unset($_SESSION[$clue]);
    }
}
foreach ($_REQUEST as $key => $val){
    $_SESSION[$key] = $_REQUEST[$key];
}

// print the alignment form

echo '<div class="alignform">';
AlignForm();
echo '</div>';

// 1) show a clue DBM if requested

if (isset($_REQUEST['showdbm']) && !isset($_REQUEST['id'])){
    ShowDBM($_REQUEST['showdbm']);
}

// 2) show the alignment matrix for the current bitext segment
//    - run the align if necessary, i.e. if the align button was pressed
//    - add manual alignments if any
//    - remove alignments (if any)

else{
    if ($_REQUEST['align']){
	$output = array();
	clear_session();
	align($BITEXT,$_REQUEST['id'],$output);
	parse_align_output($output);
	unset($_REQUEST['add']);
	unset($_REQUEST['rm']);
	if ($_SESSION['search'] == 'none'){
	    unalign();
	}
    }
    if ($_REQUEST['read']){
	$output = array();
//	clear_session();
//	align($BITEXT,$_REQUEST['id'],$output);
//	parse_align_output($output);
	read_alignments();
	unset($_REQUEST['add']);
	unset($_REQUEST['rm']);
    }
    if (isset($_REQUEST['add'])){
	add_link($_REQUEST['add']);
    }
    if (isset($_REQUEST['rm'])){
	remove_link($_REQUEST['rm']);
    }
    if (isset($_REQUEST['ms'])){
	$_SESSION['marked_src'] = $_REQUEST['ms'];
    }
    if (isset($_REQUEST['mt'])){
	$_SESSION['marked_trg'] = $_REQUEST['mt'];
    }
    if (isset($_REQUEST['us'])){
	unset($_SESSION['marked_src']);
    }
    if (isset($_REQUEST['ut'])){
	unset($_SESSION['marked_trg']);
    }
    if (isset($_SESSION['marked_src']) && isset($_SESSION['marked_trg'])){
	add_link($_SESSION['marked_src'].':'.$_SESSION['marked_trg']);
	unset($_SESSION['marked_src']);
	unset($_SESSION['marked_trg']);
    }


    get_alignments();
    print_bitext_segment();
    print_clue_matrix();
    print_alignments();

}

?>

<script language="JavaScript" type="text/javascript" src="include/wz_tooltip.js">
</script>
</body>
</html>
