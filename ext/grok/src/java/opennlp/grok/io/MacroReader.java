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

package opennlp.grok.io;

import opennlp.grok.datarep.*;

import org.jdom.*;
import org.jdom.input.*;
import org.jdom.output.*;

import java.io.*;
import java.util.*;

/**
 * Read in Morph info from a LMR grammar.
 *
 * @author      Jason Baldridge
 * @version     $Revision$, $Date$
 */
public class MacroReader {

    public static MacroModel getMacro(String filename) {
	try {
	    if(filename==null)
		return new MacroModel();
	    else
		return getMacro(new FileInputStream(filename));
	} catch(FileNotFoundException FE) {
	    System.out.println("Could not find morphology file: " + filename);
	    return new MacroModel();
	}
    }
    
    public static MacroModel getMacro(InputStream istr) {

	MacroModel morph = new MacroModel();
	SAXBuilder builder = new SAXBuilder();
	
	MacroItem entry;
	try {	    
	    Document doc = builder.build(istr);
	    List entries = doc.getRootElement().getChildren("entry");	  

	    for (int i=0; i<entries.size(); i++)
		morph.add(new MacroItem((Element)entries.get(i)));
	}

	catch (Exception e) {
	    System.out.println(e);
	    return morph;
	}
	return morph;
    }

    public static void main(String[] args) {
	MacroModel mm = MacroReader.getMacro(args[0]);
    }

    
}
