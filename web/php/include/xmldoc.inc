<?php


$sent_id = null;
$found_hard = false;

$out = null;            // global file output handler


function doc2sent($xmlfile,$sentfile,$idfile,$boundfile){

    status("XML document converted to plain text ... ");

    global $language,$found_hard;

    global $sentFH;
    global $idFH;
    global $boundFH;

    $_SESSION['nr_'.$language.'_hard'] = 0;

    $in = fopen($xmlfile,"r") or exit("unable to open $xmlfile!");
    $sentFH = fopen($sentfile,"w") or exit("unable to open $sentfile!");
    $idFH = fopen($idfile,"w") or exit("unable to open $idfile!");
    $boundFH = fopen($boundfile,"w") or exit("unable to open $boundfile!");

    $xml_parser = xml_parser_create();
    xml_parser_set_option($xml_parser, XML_OPTION_CASE_FOLDING, false);
    xml_set_element_handler($xml_parser, "startElement", "endElement");
    xml_set_character_data_handler($xml_parser, "characterData");

    $found_hard = true;    // always start with a hard boundary!

    while ($data = fread($in, 4096)) {
	if (!xml_parse($xml_parser, $data, feof($in))) {
	    die(sprintf("XML error: %s at line %d",
			xml_error_string(xml_get_error_code($xml_parser)),
			xml_get_current_line_number($xml_parser)));
	}
    }
    xml_parser_free($xml_parser);
    fclose($sentFH);
    fclose($idFH);
    fclose($boundFH);
    fclose($in);

//    echo "done!<br>";

}



function get_doc_hard($xmlfile,$idfile,$boundfile){

    status("hard boundaries read from XML document ... ");

    global $language,$found_hard;

    global $idFH;
    global $boundFH;

    $_SESSION['nr_'.$language.'_hard'] = 0;

    $in = fopen($xmlfile,"r") or exit("unable to open $xmlfile!");
    $idFH = fopen($idfile,"w") or exit("unable to open $idfile!");
    $boundFH = fopen($boundfile,"w") or exit("unable to open $boundfile!");

    $xml_parser = xml_parser_create();
    xml_parser_set_option($xml_parser, XML_OPTION_CASE_FOLDING, false);
    xml_set_element_handler($xml_parser, "startElement","endElementSent");

    $found_hard = true;    // always start with a hard boundary!

    while ($data = fread($in, 4096)) {
	if (!xml_parse($xml_parser, $data, feof($in))) {
	    die(sprintf("XML error: %s at line %d",
			xml_error_string(xml_get_error_code($xml_parser)),
			xml_get_current_line_number($xml_parser)));
	}
    }
    xml_parser_free($xml_parser);
    fclose($idFH);
    fclose($boundFH);
    fclose($in);

//    echo "done!<br>";

}



// xml parser handler functions


function startElement($parser, $name, $attrs)
{
    global $SENTTAG;         // sentence tag name
    global $sent_id;          // current sentence ID
    global $found_hard;       // hard boundary tag found earlier?
    global $language;         // source | target

    global $idFH;
    global $boundFH;

    $hard_tag = $_SESSION['hardtag'];

    if ($name == $SENTTAG){
	$sent_id = $attrs['id'];
	fwrite($idFH,$attrs['id']."\n");
	if (isset($_SESSION[$language.'_hard_'.$sent_id])){
	    $_SESSION['nr_'.$language.'_hard']++;
	    fwrite($boundFH,$attrs['id']."\n");
	    $found_hard = false;
	}
	elseif ($found_hard && ($sent_id != null)){
	    $_SESSION['nr_'.$language.'_hard']++;
	    $_SESSION[$language.'_hard_'.$sent_id]=1;
	    fwrite($boundFH,$attrs['id']."\n");
	    $found_hard = false;
//	    echo "$language - $sent_id - <br>";
	}

    }
    if ($name == $hard_tag){
	$found_hard = true;
    }
}


function endElementSent($parser, $name)
{
    global $SENTTAG;
    global $sent_id;

    if ($name == $SENTTAG){
	$sent_id = null;
    }
}


function endElement($parser, $name)
{
    global $SENTTAG;
    global $sent_id;
    global $sentFH;

    if ($name == $SENTTAG){
	fwrite($sentFH,"\n");
	$sent_id = null;
    }
}


function characterData($parser, $data)
{
    global $sent_id;
    global $sentFH;
    $data = rtrim($data);

    if (($sent_id != null) && ($data != "")){
	fwrite($sentFH,utf8_decode($data)." ");
    }
}



function status($message){
    echo '<div class="status">'.htmlentities($message).'</div>';
}




// make the id-file for sentence alignments (used by ICA)

$sidFH = null;

function make_id_file($bitext,$idfile){

    global $sidFH;

    $inFH = fopen($bitext,"r") or exit("unable to open $bitext!");
    $sidFH = fopen($idfile,"w") or exit("unable to open $idfile!");

//    status("create link ID file ...");

    $xml_parser = xml_parser_create();
    xml_parser_set_option($xml_parser, XML_OPTION_CASE_FOLDING, false);
    xml_set_element_handler($xml_parser, "IdStartElement","IdEndElement");

    while ($data = fread($inFH, 4096)) {
	if (!xml_parse($xml_parser, $data, feof($inFH))) {
	    die(sprintf("XML error: %s at line %d",
			xml_error_string(xml_get_error_code($xml_parser)),
			xml_get_current_line_number($xml_parser)));
	}
    }
    xml_parser_free($xml_parser);
    fclose($sidFH);
    fclose($inFH);
    status("link ID file created!");
}

// start a new XML tag: print id if it is a sentence link

function IdStartElement($parser, $name, $attrs)
{
    global $sidFH;
    global $SENTLINKTAG;

    if ($name == $SENTLINKTAG){
	fwrite($sidFH,$attrs['id']."\n");
    }
}

// this function does nothing

function IdEndElement($parser, $name)
{
}



?>
