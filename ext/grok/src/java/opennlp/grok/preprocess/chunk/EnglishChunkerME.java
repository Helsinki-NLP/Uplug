///////////////////////////////////////////////////////////////////////////////
// Copyright (C) 2002 Joerg Tiedemann
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

package opennlp.grok.preprocess.chunk;

import java.io.*;
import java.util.zip.*;
import opennlp.common.english.*;
import opennlp.maxent.*;
import opennlp.maxent.io.*;

import java.util.*;
import opennlp.common.util.*;


/**
 * A shallow parser for English
 * (based on POSTaggerME)
 *
 * @author      Joerg Tiedemann
 * @version     $Revision$, $Date$
 */

public class EnglishChunkerME extends ChunkerME {
    private static final String modelFile = "data/EnglishChunker.bin.gz";

    /**
     * No-arg constructor which loads the English chunker model
     * transparently.
     */

    public EnglishChunkerME() {
	super(getModel(modelFile),
	      new ChunkerContextGenerator(new BasicEnglishAffixes()));

	_useClosedClassTagsFilter = true;
	_closedClassTagsFilter = new EnglishClosedClassTags();
    }


    private static MaxentModel getModel(String name) {
	try {
	    return
                new BinaryGISModelReader(
                    new DataInputStream(
			new GZIPInputStream(
			    new BufferedInputStream(
            EnglishChunkerME.class.getResourceAsStream(name))))).getModel();
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



    /**
     * <p>Chunks a string passed in on the command line.
     *
     */

    public static void main(String[] args) throws IOException {

	//	System.out.println(new EnglishPOSTaggerME().tag(args[0]));

	if (args[0].equals("-test")) {
	    System.out.println(new EnglishChunkerME().tag(args[0]));
	}
	else {
	    TrainEval.run(args, new EnglishChunkerME());
	}
    }

}
