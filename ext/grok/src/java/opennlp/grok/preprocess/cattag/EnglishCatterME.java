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

package opennlp.grok.preprocess.cattag;

import java.io.*;
import java.util.zip.*;
import opennlp.maxent.*;
import opennlp.maxent.io.*;

/**
 * 
 *
 * @author      Gann Bierner
 * @version     $Revision$, $Date$
 */

public class EnglishCatterME extends CatterME {
    private static final String modelFile = "data/EnglishCatter.bin.gz";

    public EnglishCatterME() {
	super(getModel(modelFile));
    }

    private static MaxentModel getModel(String name) {
	try {
	    return
		new BinaryGISModelReader(
		    new DataInputStream(new GZIPInputStream(
	    EnglishCatterME.class.getResourceAsStream(name)))).getModel();

	} catch (IOException E) { E.printStackTrace(); return null; }
    }
    
    public static void main(String[] args) throws IOException {
	System.out.println(new EnglishCatterME().tag(args[0]));
    }

}
