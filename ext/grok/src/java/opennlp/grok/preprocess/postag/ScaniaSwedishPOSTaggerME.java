///////////////////////////////////////////////////////////////////////////////
// Copyright (C) 2002 Jason Baldridge and Gann Bierner
// 
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
// 
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
// 
// You should have received a copy of the GNU Lesser General Public
// License along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
//////////////////////////////////////////////////////////////////////////////

package opennlp.grok.preprocess.postag;

import java.io.*;
import java.util.zip.*;
import opennlp.common.swedish.*;
import opennlp.maxent.*;
import opennlp.maxent.io.*;

import java.util.*;
import opennlp.common.util.*;


/**
 * A part of speech tagger for Swedish
 * (basically a copy of EnglishPOSTaggerME, 
 *  but uses ScaniaSwedishPOSContextGenerator)
 *
 * @author      Joerg Tiedemann
 * @version     $Revision$, $Date$
 */

public class ScaniaSwedishPOSTaggerME extends POSTaggerME {
    private static final String modelFile = "data/ScaniaSwedishPOS.bin.gz";

    /**
     * No-arg constructor which loads the Swedish POS tagging model
     * transparently.
     */

    public ScaniaSwedishPOSTaggerME() {
	super(getModel(modelFile),
	      new ScaniaSwedishPOSContextGenerator(new BasicSwedishAffixes()));

	_useClosedClassTagsFilter = true;
	_closedClassTagsFilter = new SwedishClosedClassTags();
    }


    private static MaxentModel getModel(String name) {
	try {
	    return
                new BinaryGISModelReader(
                    new DataInputStream(
			new GZIPInputStream(
			    new BufferedInputStream(
            ScaniaSwedishPOSTaggerME.class.getResourceAsStream(name))))).getModel();
	} catch (IOException E) { E.printStackTrace(); return null; }
    }

    public static ArrayList convertInputLine(String s) {
	ArrayList tokens = new ArrayList();
	StringTokenizer st = new StringTokenizer(s);
	while(st.hasMoreTokens()) {
	    tokens.add(st.nextToken());
	}
	return tokens;
    }

    /*
     *    public String tag(String line) {
     *
     *	String result = "";
     *	ArrayList p = convertInputLine(line);
     *	List words = (List)p;
     *	List tags = bestSequence(words);
     *	int c=0;
     *	for(Iterator t=tags.iterator(); t.hasNext(); c++) {
     *	    String tag = (String)t.next();
     *	    result=result+words.get(c)+"/"+tag+" ";
     *	}
     *	return result;
     *    }
    */

    public String tag(Reader r) {
	BufferedReader br = new BufferedReader(r);
	String line;
	try {
	    while((line=br.readLine())!=null) {
		Pair p = POSEventCollector.convertAnnotatedString(line);
		List words = (List)p.a;
		List outcomes = (List)p.b;
		List tags = bestSequence(words);
		
		int c=0;
		String result="";
		for(Iterator t=tags.iterator(); t.hasNext(); c++) {
		    String tag = (String)t.next();
		    result = result+words.get(c)+"/"+outcomes.get(c)+"/"+tag+" ";
		    //		    System.out.println(words.get(c)+"/"+outcomes.get(c)+"/"+tag);
		}
		System.out.println(result);
	    }
	} catch (IOException E) { E.printStackTrace(); }
	return "";
    }

/*
    public String tag(Reader r) {

	BufferedReader br = new BufferedReader(r);
	String line;
	String result = "";
	try {
	    while((line=br.readLine())!=null) {
		ArrayList p = convertInputLine(line);
		List words = (List)p;
		List tags = bestSequence(words);

		int c=0;
		for(Iterator t=tags.iterator(); t.hasNext(); c++) {
		    String tag = (String)t.next();
		    result=result+words.get(c)+"/"+tag+" ";
		}

		result=result+"\n";
	    }
	} catch (IOException E) { E.printStackTrace(); }
	return result;
    }
*/

    
    /**
     * <p>Part-of-speech tag a string passed in on the command line. For
     * example: 
     *
     * <p>java opennlp.grok.preprocess.postag.ScaniaSwedishPOSTaggerME -test "Mr. Smith gave a car to his son on Friday."
     */

    public static void main(String[] args) throws IOException {

	//	System.out.println(new ScaniaSwedishPOSTaggerME().tag(args[0]));

	if (args[0].equals("-test")) {
	    System.out.println(new ScaniaSwedishPOSTaggerME().tag(args[0]));
	}
	else {
	    TrainEval.run(args, new ScaniaSwedishPOSTaggerME());
	}
    }

}
