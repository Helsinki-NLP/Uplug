<?php

if (file_exists('include/config.isa')){
    include('include/config.isa');
}
else{
    include('include/config.inc');
}
include('include/xmldoc.inc');
include('include/sentalign.inc');


session_start();
if ($_POST['reset']){                      // reset button pressed -->
    if (isset($_SESSION['hardtag'])){      // destroy the session
	$hardtag = $_SESSION['hardtag'];   // but save the selected hard tag
    }
    session_destroy();
    session_start();
    if (isset($hardtag)){
	$_SESSION['hardtag']=$hardtag;
    }
}

$PHP_SELF = $_SERVER['PHP_SELF'];

// hard boundaries are stored in 
// $_SESSION['source_hard_ID'] and $_SESSION['target_hard_ID']
// (replace ID with valid sentence ID)
//
// hard boundary counters are in 
// $_SESSION['nr_source_hard'] and $_SESSION['nr_target_hard']



?>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
                      "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<title>alignment test</title>
<link rel="stylesheet" href="isa.css" type="text/css">
<meta http-equiv="Content-Type" content="text/html;charset=utf-8" >
<?php include('include/java.inc'); ?>
</head>
<body>

<h1>Interactive Sentence Alignment</h1>

<?php


$srcbase = str_replace('.xml','',$SRCXML);
$trgbase = str_replace('.xml','',$TRGXML);

$src_sent_file = $srcbase . '.sent';    // sentences one per line
$trg_sent_file = $trgbase . '.sent';

$src_id_file = $srcbase . '.ids';     // sentence IDs one per line
$trg_id_file = $trgbase . '.ids';



if (isset($BITEXT)) $sentalign = $BITEXT;
else $sentalign = $srcbase.'-'.$trgbase.'.ces';

if (!file_exists($src_sent_file) ||
    (filemtime($SRCXML) > filemtime($src_sent_file))){
    doc2sent($SRCXML);
    $_SESSION['nr_source_hard'] = 0;
    read_tag_file($SRCXML,'source');
    echo " nr hard boundaries: ".$_SESSION['nr_source_hard']."<br>";
}

if (! file_exists($trg_sent_file) ||
    (filemtime($TRGXML) > filemtime($trg_sent_file))){
    doc2sent($TRGXML);
    $_SESSION['nr_source_hard'] = 0;
    read_tag_file($TRGXML,'target');
    echo " nr hard boundaries: ".$_SESSION['nr_target_hard']."<br>";
}


$src_ids = file($src_id_file);
$trg_ids = file($trg_id_file);

$src_ids = array_map("rtrim",$src_ids);
$trg_ids = array_map("rtrim",$trg_ids);


if (!isset($_POST['reset'])){
    if (isset($_REQUEST['sadd'])){
	$idx = $_REQUEST['sadd'];
	if (isset($src_ids[$idx])){
	    if (! isset($_SESSION['source_hard_'.$src_ids[$idx]])){
		$_SESSION['source_hard_'.$src_ids[$idx]] = 1;
		$_SESSION['nr_source_hard']++;
		$new_src_boundary = $src_ids[$idx];
	    }
	}
    }
    if (isset($_REQUEST['srm'])){
	$idx = $_REQUEST['srm'];
	if (isset($src_ids[$idx])){
	    if (isset($_SESSION['source_hard_'.$src_ids[$idx]])){
		unset($_SESSION['source_hard_'.$src_ids[$idx]]);
		$_SESSION['nr_source_hard']--;
		$removed_src_boundary = $src_ids[$idx];
	    }
	}
    }
    if (isset($_REQUEST['tadd'])){
	$idx = $_REQUEST['tadd'];
	if (isset($trg_ids[$idx])){
	    if (! isset($_SESSION['target_hard_'.$trg_ids[$idx]])){
		$_SESSION['target_hard_'.$trg_ids[$idx]] = 1;
		$_SESSION['nr_target_hard']++;
		$new_trg_boundary = $trg_ids[$idx];
	    }
	}
    }
    if (isset($_REQUEST['trm'])){
	$idx = $_REQUEST['trm'];
	if (isset($trg_ids[$idx])){
	    if (isset($_SESSION['target_hard_'.$trg_ids[$idx]])){
		unset($_SESSION['target_hard_'.$trg_ids[$idx]]);
		$_SESSION['nr_target_hard']--;
		$removed_trg_boundary = $trg_ids[$idx];
	    }
	}
    }
}

if (isset($_REQUEST['hardtag'])){
    $oldhardtag = $_SESSION['hardtag'];
    $_SESSION['hardtag'] = $_REQUEST['hardtag'];
    if (isset($oldhardtag)){
	if ($oldhardtag != $_REQUEST['hardtag']){
	    read_tag_file($SRCXML,'source');
	    read_tag_file($TRGXML,'target');
	}
    }
}
if (!isset($_SESSION['hardtag'])){
    $_SESSION['hardtag'] = 'p';
}


//////////////////////////////////////////////////////////////////////////

if (!isset($_SESSION['src_start'])) $_SESSION['src_start']=0;
if (!isset($_SESSION['trg_start'])) $_SESSION['trg_start']=0;
if (!isset($_SESSION['show_max'])) $_SESSION['show_max']=$SHOWMAX;

if (isset($_REQUEST['next'])){
    if (isset($_SESSION['page'])){
	$page = $_SESSION['page']+1;
	if (isset($_SESSION['src_page'.$page]) &&
	    isset($_SESSION['trg_page'.$page])){
	    $_SESSION['src_start']=$_SESSION['src_page'.$page];
	    $_SESSION['trg_start']=$_SESSION['trg_page'.$page];
	    $_SESSION['page']++;
	}
    }
}
if (isset($_REQUEST['prev'])){
    if (isset($_SESSION['page'])){
	$page = $_SESSION['page']-1;
	if (isset($_SESSION['src_page'.$page]) &&
	    isset($_SESSION['trg_page'.$page])){
	    $_SESSION['src_start']=$_SESSION['src_page'.$page];
	    $_SESSION['trg_start']=$_SESSION['trg_page'.$page];
	    $_SESSION['page']--;
	}
    }
}
if (isset($_REQUEST['all'])){
    $_SESSION['page']=0;
    $_SESSION['src_start']=0;
    $_SESSION['trg_start']=0;
    $_SESSION['show_max'] = max(count($src_ids),count($trg_ids));
}
if (isset($_REQUEST['show'])){
    $_SESSION['show_max'] = $_REQUEST['show'];
}



if ($_POST['align']){
    sentence_align($src_sent_file,$trg_sent_file);
}
elseif ($_POST['save']){
    save_sentence_alignment($SRCXML,$TRGXML,$sentalign);
    status("bitext saved to ".$sentalign);
}
elseif ($_POST['reset']){
    $_SESSION['nr_source_hard'] = 0;
    $_SESSION['nr_target_hard'] = 0;
    read_tag_file($SRCXML,'source');
    read_tag_file($TRGXML,'target');
}



echo '<div class="alignform">';
echo "<form action=\"$PHP_SELF\" method=\"post\">";
echo '<input type="submit" name="reset" value="reset">';

$srctags = explode(' ',$_SESSION['tags_source']);
$trgtags = explode(' ',$_SESSION['tags_target']);
$structags = array_intersect($srctags,$trgtags);

if (count($structags)>1){
    echo '<select onChange="JavaScript:submit()" name="hardtag">';
    foreach ($structags as $tag){
	if ($_SESSION['hardtag'] == $tag){
	    echo '<option selected value="'.$tag.'">'.$tag.'</option>';
	}
	else{
	    echo '<option value="'.$tag.'">'.$tag.'</option>';
	}
    }
    echo '</select>';
}
echo '<input type="submit" name="save" value="save">';
echo '<input type="submit" name="align" value="align">';
echo '</form>';
echo '</div>';




show_bitext($src_sent_file,$trg_sent_file,
	    $_SESSION['src_start'],
	    $_SESSION['trg_start'],
	    $_SESSION['show_max']);


?>
