<?php


//////////////////////////////////////////////////////
// add a one-to-one word link and update link clusters

function add_link($link){
    list($s,$t) = explode(':',$link);
    if (!isset($_SESSION['link:'.$s.':'.$t])){
	$_SESSION['link:'.$s.':'.$t]=$s.':'.$t.':'.'manual';
	link_clusters();
	global $DATADIR;
	$logfile = $DATADIR.'/.added';
	$fh = fopen($logfile,'a');
	if ($fh){
	    fwrite($fh,$_SESSION['srcToken:'.$s]."\t".$_SESSION['trgToken:'.$t]."\n");
	    fclose($fh);
	}
    }
}

//////////////////////////////////////////////////////
// renmove a one-to-one word link
// (don't update link clusters ....)

function remove_link($link){
    list($s,$t) = explode(':',$link);
    if (isset($_SESSION['link:'.$s.':'.$t])){
//	echo 'remove link:'.$sid.':'.$tid.'<br>';
	unset($_SESSION['link:'.$s.':'.$t]);
	global $DATADIR;
	$logfile = $DATADIR.'/.removed';
	$fh = fopen($logfile,'a');
	if ($fh){
	    fwrite($fh,$_SESSION['srcToken:'.$s]."\t".$_SESSION['trgToken:'.$t]."\n");
	    fclose($fh);
	}
    }
}


////////////////////////////////////////////////////
// save word alignments in a file
//  - one file per bitext segment (overwrite)
//  - filename: $CLUEDIR/aligned/bitext-segment-id

function save_alignments(){
    global $DATADIR;
    $dir = $DATADIR;

    $filename = $dir.'/'.$_SESSION['id'];
    $fh = fopen($filename,'w');
    if ($fh){
	fwrite($fh,$_SESSION['sentlink']."\n");
	$count=0;
	while (isset($_SESSION['alignLex:'.$count])){
	    list($src,$trg) = explode(':',$_SESSION['alignLex:'.$count]);
	    list($sid,$tid) = explode(':',$_SESSION['alignXtrg:'.$count]);
	    $score = $_SESSION['alignScore:'.$count];
	    fwrite($fh,'<wordlink xtargets="'.$sid.';'.$tid.'" ');
	    // fwrite($fh,'certainty="'.$_SESSION['alignScore:'.$count].'" ');
	    fwrite($fh,'lexPair="'.utf8_encode($src).';'.utf8_encode($trg).'" />'."\n");
	    $count++;
	}
	fwrite($fh,"</link>");
	fclose($fh);
	echo "alignments saved to $filename<br>";
    }
}


////////////////////////////////////////////////////////////////////
// get the actual word alignments from the clue matrix

function get_alignments(){
    $links = array();
    for ($x=0;$x<=$_SESSION['nrSrc'];$x++){
	for ($y=0;$y<=$_SESSION['nrTrg'];$y++){
	    if (isset($_SESSION['link:'.$x.':'.$y])){
		list($sids,$tids,$score) = 
		    explode(':',$_SESSION['link:'.$x.':'.$y]);
		$links[$sids.':'.$tids]=$score;
	    }
	}
    }

    $i = 0;
    foreach ($links as $link => $score){

	list($sidx,$tidx) = explode(':',$link);
	$sidxs = explode('+',$sidx);
	$tidxs = explode('+',$tidx);

	$swords = array();
	$twords = array();

	$sids = array();
	$tids = array();

	foreach ($sidxs as $s){
	    $swords[] = $_SESSION['srcToken:'.$s];
	    $sids[] = $_SESSION['srcID:'.$s];
	    foreach ($tidxs as $t){
		$_SESSION['inLink:'.$s.':'.$t] = $i;
	    }
	}
	foreach ($tidxs as $t){
	    $twords[] = $_SESSION['trgToken:'.$t];
	    $tids[] = $_SESSION['trgID:'.$t];
	}
	$_SESSION['alignLex:'.$i] = implode(' ',$swords);
	$_SESSION['alignLex:'.$i] .= ':';
	$_SESSION['alignLex:'.$i] .= implode(' ',$twords);

	$_SESSION['alignXtrg:'.$i] = implode('+',$sids);
	$_SESSION['alignXtrg:'.$i] .= ':';
	$_SESSION['alignXtrg:'.$i] .= implode('+',$tids);

	$_SESSION['alignScore:'.$i] = $score;
	$i++;
    }
    while (isset($_SESSION['alignLex:'.$i])){
	unset($_SESSION['alignLex:'.$i]);
	unset($_SESSION['alignXtrg:'.$i]);
	unset($_SESSION['alignScore:'.$i]);
	$i++;
    }
}


//////////////////////////////////////////////////////////
// put overlaping one-to-one word links together
// to create "link clusters"

function link_clusters(){

    $srclink = array();
    $trglink = array();
    $xtrg = array();

    for ($s=0;$s<=$_SESSION['nrSrc'];$s++){
	for ($t=0;$t<=$_SESSION['nrTrg'];$t++){
	    if (isset($_SESSION['link:'.$s.':'.$t])){

		if (!isset($srclink[$s])){
		    if (!isset($trglink[$t])){
			$i = count($xtrg);
			$xtrg[$i][0][$s] = 1;
			$xtrg[$i][1][$t] = 1;
		    }
		    else{
			$i=$trglink[$t];
			$xtrg[$i][0][$s] = 1;
		    }
		}
		elseif (!isset($trglink[$t])){
		    $i=$srclink[$s];
		    $xtrg[$i][1][$t] = 1;
		}
		else{
		    $i=$srclink[$s];
		    $j=$trglink{$t};
		    if ($i!=$j){
			foreach (array_keys($xtrg[$j][0]) as $idx){
			    $xtrg[$i][0][$idx] = 1;
			    $srclink[$idx] = $i;
			}
			foreach (array_keys($xtrg[$j][1]) as $idx){
			    $xtrg[$i][1][$idx] = 1;
			    $trglink[$idx] = $i;
			}
			unset($xtrg[$j][0]);
			unset($xtrg[$j][1]);
		    }
		}
		$srclink[$s]=$i;
		$trglink[$t]=$i;
	    }
	}
    }
    for ($i=0;$i<count($xtrg);$i++){

	if (!is_array($xtrg[$i][0])){continue;}
	if (!is_array($xtrg[$i][1])){continue;}

	$sids = implode('+',array_Keys($xtrg[$i][0]));
	$tids = implode('+',array_keys($xtrg[$i][1]));

	foreach (array_keys($xtrg[$i][0]) as $s){
	    foreach (array_keys($xtrg[$i][1]) as $t){
		$_SESSION['link:'.$s.':'.$t] = 
		    $sids.':'.$tids.':'.'manual';
	    }
	}
    }
}


//////////////////////////////////////////////////////////////
// run the clue aligner with the given parameters
//   - only for one bitext segment
//   - with ulimit = 5 seconds


function align($BITEXT,$ID,&$output){

    global $CLUES;
    global $UPLUG;

    $command = $UPLUG.' align/word/test/link -v -in '.$BITEXT;

    $ClueSelected = 0;
    foreach ($CLUES as $clue => $file){
	if ($_SESSION[$clue]){
	    $command .= ' -'.$clue;
	    if ($_SESSION[$clue.'_w']){
		$command .= ' -'.$clue.'_w '.$_SESSION[$clue.'_w'];
	    }
	    $ClueSelected ++;
	}
    }
    if (isset($_SESSION['search'])){
	$command .= ' -search '.$_SESSION['search'];
    }
    $command .= ' -id '.$ID;

    if ($ClueSelected){
	//echo $command;
	exec('ulimit -t 5;'.$command.' 2>&1',$output);
//	echo '<pre>';
//	echo implode("\n",$output);
//	echo '</pre>';
	//exec($command);
    }
    else{
	echo "<b>Select one or more clues!</b>";
    }
}




/////////////////////////////////////////////////////////////
// parse alignment output and save everything in $_SESSION
// ATTENTION: this really works only with the verbose output of the
//            current Uplug aligner (reading from STDERR!!!)


function parse_align_output(&$output){

    $parse_src = true;   // first bitext segment is sourc
    $type = '';
    $clues = array();
    $src_idx = array();
    $trg_idx = array();

    clear_session();

    foreach ($output as $line){

	// get the sentence alignment tag
	if (substr($line,0,6) == '<link ') $_SESSION['sentlink'] = $line;

	// skip some lines .....
	if (substr($line,0,1) == '<') continue;         // skip xml
	if (substr($line,0,2) == ' <') continue;        // skip <wordLinks
//	if (substr($line,0,5) == '<?xml'){break;}
//	if (substr($line,0,4) == '<ces'){break;}
	if (strstr($line,'overall time')) continue;
	if (strstr($line,'linked source tokens')) continue;
	if (strstr($line,'processing time')) continue;
	if (strstr($line,'total processing time')) continue;
	if (substr($line,0,5) == '=====') continue;
	if ($line == '') continue;

	// change input mode
	if ($line == 'matching clue scores'){$type = 'clues';continue;}
	if ($line == 'final clue matrix scores'){$type = 'scores';continue;}
	if ($line == 'word alignments'){$type = 'links';continue;}
	if ($line == 'bitext segment'){$type = 'tokens';continue;}
	if (substr($line,0,11) == 'clue matrix'){$type = '';continue;}
//	    list($nr_src, $nr_trg) = sscanf($line, "clue matrix %s x %sn");
//	    continue;
//	}

	//////////////////////////////////////////
	// read bitext tokens (id:token pairs)

	if ($type == 'tokens'){
	    $tokens = explode(' ',$line);
	    if ($parse_src){
		$parse_src = false;
		$idx=0;
		foreach ($tokens as $token){
		    list($id,$tok) = explode(':',$token);
		    $_SESSION['srcID:'.$idx] = $id;
		    $_SESSION['srcToken:'.$idx] = $tok;
		    $_SESSION['nrSrc'] = $idx;
		    $src_idx[$id] = $idx;
		    $idx++;
		}
	    }
	    else{
		$idx=0;
		foreach ($tokens as $token){
		    list($id,$tok) = explode(':',$token);
		    $_SESSION['trgID:'.$idx] = $id;
		    $_SESSION['trgToken:'.$idx] = $tok;
		    $_SESSION['nrTrg'] = $idx;
		    $trg_idx[$id] = $idx;
		    $idx++;
		}
	    }
	}

	//////////////////////////////////////////
	// read clue matrix scores (and save highest and lowest scores)

	if ($type == 'scores'){
	    list($sidx, $tidx, $src, $trg, $score) = 
		sscanf($line, "[%d %d] %s - %s %s\n");
	    if (isset($score)){
		$_SESSION['matrix:'.$sidx.':'.$tidx] = $score;

		if (($_SESSION['highestScore'] == null) || 
		    ($score > $_SESSION['highestScore'])){
		    $_SESSION['highestScore'] = $score;
		}
		if (($_SESSION['lowestScore'] == null) || 
		    ($score < $_SESSION['lowestScore'])){
		    $_SESSION['lowestScore'] = $score;
		}
	    }
	}

	//////////////////////////////////////////
	// read applied clues and there scores

	if ($type == 'clues'){
	    list($clue,$sidx, $tidx, $src, $trg, $score) = 
		explode("\t",$line);
//		sscanf($line, "%s [ %s %s ] %s - %s %s\n");
	    if (isset($score)){
		$sidxs = explode(':',$sidx);
		$tidxs = explode(':',$tidx);
		foreach ($sidxs as $s){
		    foreach ($tidxs as $t){
			$clues[$s][$t][$clue.':'.$src.':'.$trg]=$score;
		    }
		}
	    }
	}

	//////////////////////////////////////////
	// read word alignments and their scores

	if ($type == 'links'){
	    list($id, $sid, $tid, $src, $trg, $score) = 
		explode("\t",$line);

	    if (isset($score)){
		$sids = explode(':',$sid);
		$tids = explode(':',$tid);

		// create a link of token positions (e.g. 0+1+2:3+4)

		$sidxs = array();
		foreach ($sids as $sid){
		    $sidxs[] = $src_idx[$sid];
		}
		$tidxs = array();
		foreach ($tids as $tid){
		    $tidxs[] = $trg_idx[$tid];
		}
		$link = implode('+',$sidxs);
		$link .= ':';
		$link .= implode('+',$tidxs);

		foreach ($sids as $sid){
		    foreach ($tids as $tid){
			$s = $src_idx[$sid];
			$t = $trg_idx[$tid];
	    		$_SESSION['link:'.$s.':'.$t]=$link.':'.$score;
		    }
		}
	    }
	}
    }
    make_clue_strings($clues);
}


function make_clue_strings(&$clues){

    if (isset($_SESSION['nrSrc']) && isset($_SESSION['nrTrg'])){
	for ($i=0;$i<=$_SESSION['nrSrc'];$i++){
	    for ($j=0;$j<=$_SESSION['nrTrg'];$j++){
		if ((isset($clues[$i])) && (isset($clues[$i][$j]))){
		    $str = '<table>';
		    $str .= '<tr><th>type</th><th>source</th><th>target</th>';
		    $str .= '<th>score</th></tr>';
		    foreach ($clues[$i][$j] as $clue => $score){
			list($type,$src,$trg) = explode(':',$clue);
			$str .= '<tr><td>';
			$str .= $type;
			$str .= '</td><td>';
			$str .= htmlentities(str_replace('"','&quot;',
				    str_replace("'","\\'",$src)));
			$str .= '</td><td>';
			$str .= htmlentities(str_replace('"','&quot;',
				    str_replace("'","\\'",$trg)));
			$str .= '</td><td>';
			$str .= $score;
			$str .= '</td></tr>';
		    }
		    $str .= "</table>";

		    $_SESSION['clues:'.$i.':'.$j] = $str;
		}
	    }
	}
    }
}


?>