///////////////////////////////////////////////////////////////////////////////
// Copyright (C) 2000 Jason Baldridge and Gann Bierner
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

package opennlp.grok.preprocess.tokenize;

import opennlp.maxent.*;
import opennlp.maxent.io.*;
import java.io.*;
import java.util.zip.*;

/**
 * A tokenizer which uses default English data for the maxent model.
 *
 * @author      Jason Baldridge
 * @version     $Revision$, $Date$
 */
public class EnglishTokenizerME extends TokenizerME {
    private static final String modelFile = "data/EnglishTok.bin.gz";
    
    public EnglishTokenizerME() {
	super(getModel(modelFile));
    }

    private static MaxentModel getModel(String name) {
	try {
	    return
		new BinaryGISModelReader(
		    new DataInputStream(new GZIPInputStream(
            EnglishTokenizerME.class.getResourceAsStream(name)))).getModel();
	    
	} catch (IOException ioe) {
	    ioe.printStackTrace();
	}
	return null;
    }
	

    public static void main(String[] args) {
	String [] tokenSA = new EnglishTokenizerME().tokenize(args[0]);
	for (int i=0; i<tokenSA.length; i++) System.out.println(tokenSA[i]);
    }
    
}
