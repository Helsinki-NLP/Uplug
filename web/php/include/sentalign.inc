<?php

function show_bitext($srcfile,$trgfile,$srcstart,$trgstart,$max){
    global $src_ids,$trg_ids;
    global $new_src_boundary,$new_trg_boundary;
    global $removed_src_boundary,$removed_trg_boundary;
    global $PHP_SELF;

    $src = fopen($srcfile,"r") or exit("unable to open $srcfile!");
    $trg = fopen($trgfile,"r") or exit("unable to open $trgfile!");

    $src_count=0;
    $trg_count=0;

    if ($srcstart>0){
	while ($buffer = fgets($src,4096)) {
	    $src_count++;
	    if ($src_count == $srcstart) break;
	}
    }
    if ($trgstart>0){
	while ($buffer = fgets($trg,4096)) {
	    $trg_count++;
	    if ($trg_count == $trgstart) break;
	}
    }

    echo '<table class="bitext">';
    $continue=1;

    while ($continue){
	$continue = 0;

	$first = 1;
	$anchor = '';
	echo '<tr><td><table width="100%" class="bitext-src">';
	while ($buffer = fgets($src,4096)) {
	    echo '<a name="src'.$src_ids[$src_count].'">';
	    if ($src_count>4){
		$anchor = '#src'.$src_ids[$src_count-4];
	    }
	    if ($first){
		echo "\n<tr
                onMouseOver=\"setStyle(this,'backgroundColor','#fee')\" 
                onMouseOut=\"setStyle(this,'backgroundColor','white')\" 
                onClick=\"window.location='$PHP_SELF?srm=$src_count$anchor'\">";
		echo "<td
                onMouseOver=\"setStyle(this,'borderTop','medium solid red')\" 
                onMouseOut=\"setStyle(this,'borderTop','medium solid white')\">";
		echo $src_ids[$src_count].'</td>';
		echo "<td
                onMouseOver=\"setStyle(this,'borderTop','medium solid red')\" 
                onMouseOut=\"setStyle(this,'borderTop','medium solid white')\"";
	    }
	    else{
		echo "\n<tr
                onMouseOver=\"setStyle(this,'backgroundColor','#efe')\" 
                onMouseOut=\"setStyle(this,'backgroundColor','white')\" 
                onClick=\"window.location='$PHP_SELF?sadd=$src_count$anchor'\">";
		echo "<td
                onMouseOver=\"setStyle(this,'borderTop','medium solid #0a0')\" 
                onMouseOut=\"setStyle(this,'borderTop','medium solid white')\">";
		echo $src_ids[$src_count].'</td>';
		echo "<td
                onMouseOver=\"setStyle(this,'borderTop','medium solid #0a0')\" 
                onMouseOut=\"setStyle(this,'borderTop','medium solid white')\"";
	    }
	    if (isset($new_src_boundary)){
		if (($new_src_boundary == $src_ids[$src_count]) ||
		    ($new_src_boundary == $src_ids[$src_count+1])){
		    echo ' bgcolor="#fee"';
		}
	    }
	    if (isset($removed_src_boundary)){
		if (($removed_src_boundary == $src_ids[$src_count]) ||
		    ($removed_src_boundary == $src_ids[$src_count+1])){
		    echo ' bgcolor="#efe"';
		}
	    }
	    echo '>'.$buffer.'</td></tr>';

	    $first = 0;
	    $src_count++;
	    $continue++;
	    if (isset($_SESSION['source_hard_'.$src_ids[$src_count]])){
//		echo '<tr><td>hard</td><td>'.$src_ids[$src_count].'</td></tr>';
		break;
	    }
	    if (($src_count-$srcstart)>$max*1.5) break;
	}

	$first = 1;
	$anchor = '';
	echo '</table></td><td><table width="100%" class="bitext-trg">';
	while ($buffer = fgets($trg,4096)) {
	    echo '<a name="trg'.$trg_ids[$trg_count].'">';
	    if ($trg_count>4){
		$anchor = '#trg'.$trg_ids[$trg_count-4];
	    }
	    if ($first){
		echo "\n<tr
                onMouseOver=\"setStyle(this,'backgroundColor','#fee')\" 
                onMouseOut=\"setStyle(this,'backgroundColor','white')\" 
                onClick=\"window.location='$PHP_SELF?trm=$trg_count$anchor'\">";
		echo "<td
                onMouseOver=\"setStyle(this,'borderTop','medium solid red')\" 
                onMouseOut=\"setStyle(this,'borderTop','medium solid white')\">";
		echo $trg_ids[$trg_count].'</td>';
		echo "<td
                onMouseOver=\"setStyle(this,'borderTop','medium solid red')\" 
                onMouseOut=\"setStyle(this,'borderTop','medium solid white')\"";
	    }
	    else{
		echo "\n<tr
                onMouseOver=\"setStyle(this,'backgroundColor','#efe')\" 
                onMouseOut=\"setStyle(this,'backgroundColor','white')\" 
                onClick=\"window.location='$PHP_SELF?tadd=$trg_count$anchor'\">";
		echo "<td
                onMouseOver=\"setStyle(this,'borderTop','medium solid #0a0')\" 
                onMouseOut=\"setStyle(this,'borderTop','medium solid white')\">";
		echo $trg_ids[$trg_count].'</td>';
		echo "<td
                onMouseOver=\"setStyle(this,'borderTop','medium solid #0a0')\" 
                onMouseOut=\"setStyle(this,'borderTop','medium solid white')\"";
	    }
	    if (isset($new_trg_boundary)){
		if (($new_trg_boundary == $trg_ids[$trg_count]) ||
		    ($new_trg_boundary == $trg_ids[$trg_count+1])){
		    echo ' bgcolor="#fee"';
		}
	    }
	    if (isset($removed_trg_boundary)){
		if (($removed_trg_boundary == $trg_ids[$trg_count]) ||
		    ($removed_trg_boundary == $trg_ids[$trg_count+1])){
		    echo ' bgcolor="#efe"';
		}
	    }
	    echo '>'.$buffer.'</td></tr>';
	    $first = 0;
	    $trg_count++;
	    $continue++;
	    if (isset($_SESSION['target_hard_'.$trg_ids[$trg_count]])){
//		echo '<tr><td>hard</td><td>'.$trg_ids[$trg_count].'</td></tr>';
		break;
	    }
	    if (($trg_count-$trgstart)>$max*1.5) break;
	}
	echo '</table></td></tr>';
	if (($src_count-$srcstart)>$max || ($trg_count-$trgstart)>$max) break;
    }
    echo '</table>';

//    $_SESSION['last_src_fpos'] = ftell($src);
//    $_SESSION['last_trg_fpos'] = ftell($trg);

    fclose($src);
    fclose($trg);

////////////////////////////////////////////////////////////////////

    global $SHOWMAX;
    if (!isset($_SESSION['page'])){
	$_SESSION['page'] = 0;
	$_SESSION['src_page0'] = 0;
	$_SESSION['trg_page0'] = 0;
    }

    echo '<div class="index">';
    if ($_SESSION['page'] > 0){
	$prevpage = $_SESSION['page']-1;
	if ($prevpage>=0){
	    echo '<a href="'.$PHP_SELF.'?prev">&lt;&lt; previous page</a> | ';
	}
    }
    foreach (array(10,20,50) as $max){
	if ($_SESSION['show_max'] == $max){
	    echo $max.' | ';
	}
	else{
	    echo '<a href="'.$PHP_SELF.'?show='.$max.'">'.$max.'</a> | ';
	}
    }
    echo '<a href="'.$PHP_SELF.'?all">all</a>';
    if (($src_count<count($src_ids)) || ($trg_count<count($trg_ids))){
	$nextpage = $_SESSION['page']+1;
	$_SESSION['src_page'.$nextpage] = $src_count;
	$_SESSION['trg_page'.$nextpage] = $trg_count;
	echo ' | <a href="'.$PHP_SELF.'?next">next page &gt;&gt;</a>';
    }
    echo '</div>';

}



function read_next_segment(&$fh,&$text,$language){
    $read = '';
    $id = '';

    if (feof($fh)){return 0;}

    while ($buffer = fgets($fh,4096)) {
//	$buffer = utf8_decode($buffer);
	$buffer = rtrim($buffer);
	if ($buffer == '<hard>'){
	    if ($id != ''){
		$text[$id]=$read;
	    }
	    return 1;
	}
	if (substr($buffer,0,7) == '<s id="'){
	    if ($id != ''){
		$text[$id]=rtrim($read);
		$read = '';
	    }
	    list($before,$id,$after)=explode('"',$buffer);
	}
	else{
	    $read .= $buffer.' ';
	}
    }
	
    $text[$id]=rtrim($read);
    return 1;
}


function save_sentence_alignment($srcdoc,$trgdoc,$aligndoc){

    global $src_ids,$trg_ids;

    $FH = fopen($aligndoc,"w") or exit("unable to open $aligndoc!");
    fwrite($FH,'<?xml version="1.0" encoding="utf-8"?>'."\n");
    fwrite($FH,'<!DOCTYPE cesAlign PUBLIC "-//CES//DTD XML cesAlign//EN" "">'."\n");
    fwrite($FH,'<cesAlign version="1.0" fromDoc="');
    fwrite($FH,$srcdoc.'" toDoc="'.$trgdoc."\">\n");
    fwrite($FH,'<linkGrp targType="s" fromDoc="');
    fwrite($FH,$srcdoc.'" toDoc="'.$trgdoc."\">\n");

    $src = array();
    foreach ($src_ids as $id){
	if (isset($_SESSION['source_hard_'.$id])){
	    $src[count($src)] = $id.' ';
	}
	else{
	    $src[count($src)-1] .= $id.' ';
	}
    }
    $src = array_map("rtrim",$src);

    $trg = array();
    foreach ($trg_ids as $id){
	if (isset($_SESSION['target_hard_'.$id])){
	    $trg[count($trg)] = $id.' ';
	}
	else{
	    $trg[count($trg)-1] .= $id.' ';
	}
    }
    $trg = array_map("rtrim",$trg);

    $nr = count($src);
    if (count($trg)>$nr){$nr=count($trg);}

    for ($i=0;$i<$nr;$i++){
	fwrite($FH,'<link id="SL'.$i.'" xtargets="');
	fwrite($FH,$src[$i].';'.$trg[$i].'" />'."\n");
    }
    fwrite($FH,"</linkGrp>\n</cesAlign>\n");
    fclose($FH);

    if (file_exists($aligndoc.'.ids')){    // if there is an link-ID-file:
	unlink($aligndoc.'.ids');          // delete it (links are new now!)
    }
}

function sentence_align($srcfile,$trgfile){

    global $ALIGN;

    $srcbase = str_replace('.sent','',$srcfile);
    $trgbase = str_replace('.sent','',$trgfile);

    $srctokfile = $srcbase . '.tok';
    $trgtokfile = $trgbase . '.tok';

    make_align_input($srcfile,$trgfile,
		     $srctokfile,$trgtokfile,
		     $_SESSION['src_start'],
		     $_SESSION['trg_start'],
		     $_SESSION['show_max']);

    $command = $ALIGN.' -v -D "<hard>" -d "<soft>"';
    $command .= ' '.$srctokfile.' '.$trgtokfile;

//    status("aligning input files ... $command");
    status("input files aligned (if ulimit of 5 seconds not exceeded)!");

    exec('ulimit -t 5;'.$command);

    parse_align_result($srctokfile.'.al','source');
    parse_align_result($trgtokfile.'.al','target');

    if (file_exists($srctokfile)) unlink($srctokfile);
    if (file_exists($trgtokfile)) unlink($trgtokfile);
    if (file_exists($srctokfile.'.al')) unlink($srctokfile.'.al');
    if (file_exists($trgtokfile.'.al')) unlink($trgtokfile.'.al');

}


function parse_align_result($file,$language){

    $FH = fopen($file,"r") or exit("unable to open $file!");
    $sid = null;
    $score = null;
    $soft_found = false;

    while ($buffer = fgets($FH,4096)) {
	if (substr($buffer,0,6) == '.Score'){
	    list($before,$score) = explode(' ',$buffer);
	    //echo "found score $score<br>";
	}
	elseif (substr($buffer,0,7) == '<s id="'){
	    list($before,$sid,$after) = explode('"',$buffer);
	    //echo "found sid $sid<br>";
	    if ($soft_found){
		if (!isset($_SESSION[$language.'_hard_'.$sid])){
		    //echo "set boundary before $sid<br>";
		    $_SESSION[$language.'_hard_'.$sid] = 1;
		    $_SESSION[$language.'_score_'.$sid] = $score;
		    $_SESSION['nr_'.$language.'_hard']++;
		}
	    }
	    $soft_found = false;
	}
	elseif (substr($buffer,0,6) == '<soft>'){
	    //echo "found soft boundary<br>";
	    $soft_found = true;
	}
    }
    fclose($FH);
}





function make_align_input($srcin,$trgin,$srcout,$trgout,
			  $srcstart,$trgstart,$max){

    global $src_ids,$trg_ids;

    $nrHard = $_SESSION['nr_source_hard'];       // nr hard boundaries
    if ($_SESSION['nr_target_hard']<$nrHard){    // (take minimum
	$nrHard = $_SESSION['nr_target_hard'];
    }

    $srcInFH = fopen($srcin,"r") or exit("unable to open $srcin!");
    $trgInFH = fopen($trgin,"r") or exit("unable to open $trgin!");

    $srcOutFH = fopen($srcout,"w") or exit("unable to open $srcout!");
    $trgOutFH = fopen($trgout,"w") or exit("unable to open $trgout!");

    $src_count=0;
    $trg_count=0;

    $src_CountHard=0;
    $trg_CountHard=0;

    if ($srcstart>0){
	while ($buffer = fgets($srcInFH,4096)) {
	    $src_count++;
	    if ($src_count == $srcstart) break;
	}
    }
    if ($trgstart>0){
	while ($buffer = fgets($trgInFH,4096)) {
	    $trg_count++;
	    if ($trg_count == $trgstart) break;
	}
    }

    fwrite($srcOutFH,'<hard>'."\n");
    fwrite($trgOutFH,'<hard>'."\n");

    $continue=1;
    while ($continue){
	$continue = 0;

	$first = 1;
	while ($buffer = fgets($srcInFH,4096)) {
	    fwrite($srcOutFH,'<s id="'.$src_ids[$src_count].'">'."\n");
	    $buffer = rtrim($buffer);
	    $buffer = str_replace(' ',"\n",$buffer);
	    fwrite($srcOutFH,$buffer."\n");
	    fwrite($srcOutFH,'<soft>'."\n");
	    $src_count++;
	    $continue++;
	    if (($src_countHard<$nrHard) &&
		(isset($_SESSION['source_hard_'.$src_ids[$src_count]]))){
		fwrite($srcOutFH,'<hard>'."\n");
		$src_countHard++;
		break;
	    }
	    if (($src_count-$srcstart)>$max*1.5) break;
	}


	$first = 1;
	while ($buffer = fgets($trgInFH,4096)) {
	    fwrite($trgOutFH,'<s id="'.$trg_ids[$trg_count].'">'."\n");
	    $buffer = rtrim($buffer);
	    $buffer = str_replace(' ',"\n",$buffer);
	    fwrite($trgOutFH,$buffer."\n");
	    fwrite($trgOutFH,'<soft>'."\n");
	    $trg_count++;
	    $continue++;
	    if (($trg_countHard<$nrHard) &&
		(isset($_SESSION['target_hard_'.$trg_ids[$trg_count]]))){
		fwrite($trgOutFH,'<hard>'."\n");
		$trg_countHard++;
		break;
	    }
	    if (($trg_count-$trgstart)>$max*1.5) break;
	}

	if (($src_count-$srcstart)>$max || ($trg_count-$trgstart)>$max) break;
    }

    fwrite($srcOutFH,"<hard>\n");
    fwrite($trgOutFH,"<hard>\n");
    fclose($srcOutFH);
    fclose($trgOutFH);
    fclose($srcInFH);
    fclose($trgInFH);

}


?>