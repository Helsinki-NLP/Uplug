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

public class LexiconReader {
    public static HashMap cathash = new HashMap();

    public static LexiconModel getLexicon(String filename) {
	try {
	    if(filename==null)
		return new LexiconModel();
	    else
		return getLexicon(new FileInputStream(filename));
	} catch(FileNotFoundException FE) {
	    System.out.println("Could not find lexicon file: " + filename);
	    return new LexiconModel();
	}
    }
    
    public static LexiconModel getLexicon(InputStream istr) {	
	LexiconModel lexicon = new LexiconModel();
	SAXBuilder builder = new SAXBuilder();
	
	try {	    
	    Document doc = builder.build(istr);
	    List families = doc.getRootElement().getChildren("family");	    
	    for (int i=0; i<families.size(); i++) {
		lexicon.add(new Family((Element)families.get(i)));
	    }
	}

	catch (Exception e) {
	    System.out.println(e);
	    return lexicon;
	}
	return lexicon;
    }

    public static void main(String[] args) {
	LexiconModel lm = LexiconReader.getLexicon(args[0]);
    }

}
