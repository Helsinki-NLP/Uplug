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

/**
 *
 * @author      Gann Bierner
 * @version     $Revision$, $Date$
 */

public class SwedishPOSTaggerME extends POSTaggerME {
    private static final String modelFile = "data/SwedishPOS.bin.gz";

    /**
     * No-arg constructor which loads the Swedish POS tagging model
     * transparently.
     */
    public SwedishPOSTaggerME() {
	super(getModel(modelFile),
	      new POSContextGenerator(new BasicSwedishAffixes()));
	//	_useClosedClassTagsFilter = true;
	//	_closedClassTagsFilter = new SwedishClosedClassTags();
    }

    private static MaxentModel getModel(String name) {
	try {
	    return
		new BinaryGISModelReader(
	            new DataInputStream(new GZIPInputStream(new BufferedInputStream(
	    SwedishPOSTaggerME.class.getResourceAsStream(name))))).getModel();

	} catch (IOException E) { E.printStackTrace(); return null; }
    }
    
    /**
     * <p>Part-of-speech tag a string passed in on the command line. For
     * example: 
     *
     * <p>java opennlp.grok.preprocess.postag.SwedishPOSTaggerME -test "Mr. Smith gave a car to his son on Friday."
     */
    public static void main(String[] args) throws IOException {
	System.out.println(new SwedishPOSTaggerME().tag(args[0]));

	if (args[0].equals("-test")) {
	    System.out.println(new SwedishPOSTaggerME().tag(args[0]));
	}
	else {
	    TrainEval.run(args, new SwedishPOSTaggerME());
	}
    }

}

