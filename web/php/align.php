<?php session_start() ?>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
                      "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<title>alignment test</title>
<link rel="stylesheet" href="align.css" type="text/css">
<meta http-equiv="Content-Type" content="text/html;charset=utf-8" >

<?php include_once('java.inc'); ?>

</head>
<body>


<h1>Interactive Clue Alignment</h1>

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


require('config.inc');
require('display.inc');
require('cgi.inc');
require('alignment.inc');

if (!file_exists($DATADIR)){
    mkdir($DATADIR);
}

if ($_REQUEST['save']){
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
    }
    if (isset($_REQUEST['add'])){
	add_link($_REQUEST['add']);
    }
    if (isset($_REQUEST['rm'])){
	remove_link($_REQUEST['rm']);
    }

    get_alignments();
    print_clue_matrix();
    echo '<div class="alignments">';
    print_alignments();
    echo '</div>';

}

?>

<script language="JavaScript" type="text/javascript" src="wz_tooltip.js">
</script>
</body>
</html>
