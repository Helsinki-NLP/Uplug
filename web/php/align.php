
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
                      "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<title>alignment test</title>
<link rel="stylesheet" href="align.css" type="text/css">
<meta http-equiv="Content-Type" content="text/html;charset=utf-8" >
</head>
<body>


<?php


$BITEXT = 'ensvfbell.ces';
$ID = 'ensvfbell1';
$LANGPAIR = 'ensv';
$INVLANG = 'sven';

$UPLUGHOME = 'uplug';
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

$IDS = array();
for ($i=1;$i<4210;$i++){
    $IDS[] = 'ensvfbell'.$i;
}

if (isset($_POST['id'])) $ID=$_POST['id'];
AlignForm();

if (isset($_POST['id'])){
    align($BITEXT,$ID);
}
elseif (isset($_REQUEST['showdbm'])){
    ShowDBM($_REQUEST['showdbm']);
}







function WeightSelectionBox($name,$selected){
    echo "<select name=\"$name\">";
    for ($i=0.01;$i<1;$i+=0.01){
	if ($i == $selected){
	    echo "<option selected>$i</option>\n";
	}
	else{
	    echo "<option>$i</option>\n";
	}
    }
    echo '</select>';
}


function SearchSelectionBox($selected){
    if (!isset($selected)) $selected='best_first';
    echo "<select name=\"search\">";
    $methods = array('src','trg','union','intersection',
		'refined','competitive','best_first');
    foreach ($methods as $method){
	if ($selected == $method){
	    echo "<option selected>$method</option>\n";
	}
	else{
	    echo "<option>$method</option>\n";
	}
    }
    echo '</select>';
}



//// make form

function AlignForm(){

    global $CLUES;
    global $IDS;

    echo '<form action="align.php" method="post">';

    $count = 0;
    echo '<table><tr>';

    foreach ($CLUES as $clue => $file){
	if (file_exists($file)){
	    if (($count == 0) || !($count % 10)){
		if ($count){
		    echo '</td></tr></table></td>';
		}
		echo '<td valign="top">';
		echo '<table cellpadding="0" cellspacing="0">';
		echo '<tr><th>clue</th><th>weight</th></tr>';
	    }
	    echo '<tr><td>';
	    if ($_POST[$clue]){
		echo "<input type=\"checkbox\" checked name=\"$clue\" value=\"1\">";
	    }
	    else{
		echo "<input type=\"checkbox\" name=\"$clue\" value=\"1\">";
	    }
	    echo '<a href=align.php?showdbm='.$clue.'>';
	    echo $clue;
	    echo '</a>&nbsp;&nbsp;';
	    echo '</td><td>';
	    WeightSelectionBox($clue.'_w',$_POST[$clue.'_w']);
	    echo '</td></tr>';
	    $count++;
	}
    }
    echo '</td></tr></table></td>';
    echo '</tr></table><br>';

    echo SearchSelectionBox($_POST['search']);
    echo '<br>';

    echo '<select name="id">';
    foreach ($IDS as $id){
	if (isset($_POST['id']) && ($_POST['id'] == $id)){
	    echo "<option selected>$id</option>\n";
	}
	else{
	    echo "<option>$id</option>\n";
	}
    }
    echo '</select>';

    echo '<input type="submit" value="align">';
    echo '</form>';
}






function align($BITEXT,$ID){

    global $CLUES;
    global $UPLUG;

    $command = $UPLUG.' align/word/test/link -html -in '.$BITEXT;

    $ClueSelected = 0;
    foreach ($CLUES as $clue => $file){
	if ($_POST[$clue]){
	    $command .= ' -'.$clue;
	    if ($_POST[$clue.'_w']){
		$command .= ' -'.$clue.'_w '.$_POST[$clue.'_w'];
	    }
	    $ClueSelected ++;
	}
    }
    if (isset($_POST['search'])){
	$command .= ' -search '.$_POST['search'];
    }
    $command .= ' -id '.$ID;

    if ($ClueSelected){
	echo $command;
	echo '<div class="align">';
	system('ulimit -t 5;'.$command);
	echo '</div>';
    }
    else{
	echo "<b>Select one or more clues!</b>";
    }
}







///////////////////////////////////////////////////////////////////
// show the contents of a clue DBM file


function ShowDBM($dbm){
    global $UPLUGHOME;
    global $CLUES;

    // navigation links (start, previous, next)

    echo '<table><tr>';
    echo '<td><form action="align.php" method="post">';
    echo '<input type="hidden" name="showdbm" value="';
    echo $_REQUEST['showdbm'].'">';
    if (isset($_REQUEST['sort'])){
	echo '<input type="hidden" name="sort" value="';
	echo $_REQUEST['sort'].'">';
    }
    echo '<a href="#" style="text-decoration:none" onclick="parentNode.submit()">&lt;&lt;</a>';
    echo '</form></td>';

    if (isset($_REQUEST['skip'])){
	if (($_REQUEST['skip'] - 25) > 0){
	    $prev = $_REQUEST['skip'] - 25;
	    echo '<td><form action="align.php" method="post">';
	    echo '<input type="hidden" name="showdbm" value="';
	    echo $_REQUEST['showdbm'].'">';
	    echo '<input type="hidden" name="skip" value="'.$prev.'">';
	    if (isset($_REQUEST['sort'])){
		echo '<input type="hidden" name="sort" value="';
		echo $_REQUEST['sort'].'">';
	    }
	    echo '<a href="#" style="text-decoration:none" onclick="parentNode.submit()">&lt;</a>';
	    echo '</form></td>';
	}
    }

    echo '<td valign="top"> [ '.$_REQUEST['showdbm'].' ] </td>';

    $next = $_REQUEST['skip'] + 25;
    echo '<td><form action="align.php" method="post">';
    echo '<input type="hidden" name="showdbm" value="';
    echo $_REQUEST['showdbm'].'">';
    echo '<input type="hidden" name="skip" value="'.$next.'">';
    if (isset($_REQUEST['sort'])){
	echo '<input type="hidden" name="sort" value="';
	echo $_REQUEST['sort'].'">';
    }
    echo '<a href="#" style="text-decoration:none" onclick="parentNode.submit()">&gt;</a>';
    echo '</form></td></tr></table>';

    // end of navigation links

    echo '<div class="dbm">';
    echo '<table><tr>';

    // table header:
    // sort source links

    echo '<th><form action="align.php" method="post">';
    echo '<input type="hidden" name="showdbm" value="';
    echo $_REQUEST['showdbm'].'">';
    if (isset($_REQUEST['skip'])){
	echo '<input type="hidden" name="skip" value="';
	echo $_REQUEST['skip'].'">';
    }
    if ($_REQUEST['sort'] == 'src'){
	echo '<input type="hidden" name="sort" value="rsrc">';
    }
    else{
	echo '<input type="hidden" name="sort" value="src">';
    }
    echo '<a href="#" style="text-decoration:none" onclick="parentNode.submit()">source</a>';
    echo '</form></th>';

    // sort target links

    echo '<th><form action="align.php" method="post">';
    echo '<input type="hidden" name="showdbm" value="';
    echo $_REQUEST['showdbm'].'">';
    if (isset($_REQUEST['skip'])){
	echo '<input type="hidden" name="skip" value="';
	echo $_REQUEST['skip'].'">';
    }
    if ($_REQUEST['sort'] == 'trg'){
	echo '<input type="hidden" name="sort" value="rtrg">';
    }
    else{
	echo '<input type="hidden" name="sort" value="trg">';
    }
    echo '<a href="#" style="text-decoration:none" onclick="parentNode.submit()">target</a>';
    echo '</form></th>';


    // sort scores links

    echo '<th><form action="align.php" method="post">';
    echo '<input type="hidden" name="showdbm" value="';
    echo $_REQUEST['showdbm'].'">';
    if (isset($_REQUEST['skip'])){
	echo '<input type="hidden" name="skip" value="';
	echo $_REQUEST['skip'].'">';
    }
    if ($_REQUEST['sort'] == 'score'){
	echo '<input type="hidden" name="sort" value="rscore">';
    }
    else{
	echo '<input type="hidden" name="sort" value="score">';
    }
    echo '<a href="#" style="text-decoration:none" onclick="parentNode.submit()">score</a>';
    echo '</form></th></tr>';
    //echo '<th>source</th><th>target</th><th>score</th></tr>';

    // end f table header

    // search form

    echo '<form action="align.php" method="post"><tr><td>';
    echo '<input type="text" name="source" size="12"></td>';
    echo '<td><input type="text" name="target" size="12"></td>';
    echo '<td><input type="submit" value="search">';
    echo '<input type="hidden" name="showdbm" value="';
    echo $_REQUEST['showdbm'].'">';
    echo '</td></tr></form>';



    $command = $UPLUGHOME.'/tools/dumpdbm '.$CLUES[$dbm];
    $command .= ' | tr "\00=>" "~~~" | cut -d "~" -f1,2,5';

    ///////////////////////////////////////////////////////////////////////
    // query the clue DBM ... (this is not safe!!!!)

    if (($_POST['source'] != "") || ($_POST['target'] != "")){
	if ($_POST['target'] == ""){
	    $command .= " | egrep '^ *".utf8_encode($_POST['source'])." *~'";
	}
	elseif ($_POST['source'] == ""){
	    $command .= " | egrep '~ *".utf8_encode($_POST['target'])." *~'";
	}
	else{
	    $command = $UPLUGHOME.'/tools/searchdbm '.$CLUES[$dbm];
	    $command .= ' '.utf8_encode($_POST['source']);
	    $command .= ' '.utf8_encode($_POST['target']);
	    $output = shell_exec('ulimit -t 2;'.$command);
	    list($key,$val) = explode(' => ',$output);
	    list($src,$trg) = explode("\x00",$key);
	    list($field,$score) = explode("\x00",$val);
	    echo '<tr><td>'.utf8_decode($src).'</td>';
	    echo '<td>'.utf8_decode($trg).'</td>';
	    echo '<td>'.$score.'</td></tr>';
	    echo '</table></div>';
	    return $output;
	}
    }

    elseif (isset($_REQUEST['sort'])){
	if ($_REQUEST['sort'] == 'trg'){
	    $command .= ' | sort +1 -t "~"';
	}
	elseif ($_REQUEST['sort'] == 'rtrg'){
	    $command .= ' | sort +2 -r -t "~"';
	}
	elseif ($_REQUEST['sort'] == 'score'){
	    $command .= ' | sort +2 -n -t "~"';
	}
	elseif ($_REQUEST['sort'] == 'rscore'){
	    $command .= ' | sort +2 -n -r -t "~"';
	}
	elseif ($_REQUEST['sort'] == 'rsrc'){
	    $command .= ' | sort +2 -r -t "~"';
	}
	else{
	    $command .= ' | sort -t "~"';
	}
    }
    $command .= ' | tr "~~~" "\t\t\t"';
    if (isset($_REQUEST['skip'])){
	$command .= ' | tail +'.$_REQUEST['skip'];
    }
    $command .= ' | head -25';

    echo $command.'<br>';

    $output = shell_exec('ulimit -t 2;'.$command);
    $lines = explode("\n",$output);


    foreach ($lines as $line){
	list($src,$trg,$score) = explode("\t",$line);
	$src = utf8_decode($src);
	$trg = utf8_decode($trg);

	echo '<tr><td>'.$src.'</td><td>'.$trg.'</td><td>'.$score.'</td></tr>';
    }
    echo '</table></div>';
}

/// end of ShowDBM
/////////////////////////////////////////////////////////////////////////



?>

</div>

</body>
</html>
