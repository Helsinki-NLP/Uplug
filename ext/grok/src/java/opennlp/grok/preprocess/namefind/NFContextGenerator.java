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

package opennlp.grok.preprocess.namefind;

import opennlp.maxent.*;

import opennlp.common.util.*;

import java.io.*;
import java.util.*;

/**
 * An event generator for the maxent NameFinder.
 *
 * @author      Gann Bierner
 * @version     $Revision$, $Date$
 */

public class NFContextGenerator implements ContextGenerator {

    /**
     * Builds up the list of features, anchored around a position within the
     * String[]. 
     */
    public String[] getContext(Object o) {	
	String[] ls = (String[])((ObjectIntPair)o).a;
	int i = ((ObjectIntPair)o).b;

	List e = new ArrayList();

	String lex = ls[i];
	e.add("w="+lex);
	if (Character.isUpperCase(lex.charAt(0))) {
	    e.add("cap");
	}


	String prev="";
	if(i>0) {
	    prev = ls[i-1];
	    if (prev.equals("")) {
		e.add("firstword");
	    } else {
		if (PerlHelp.isPunctuation(prev)) {
		    e.add("prevpunct");
		}
		if (Character.isUpperCase(prev.charAt(0))) {
		    e.add("prevcap");
		}
		if (i<2 || ls[i-2].equals("")) {
		    e.add("prevfirstword");
		}
	    }
	} else {
	    e.add("firstword");
	}
	
	String next = "";
        if (i < ls.length-1) {
	    next = ls[i+1];
	    if (Character.isUpperCase(next.charAt(0))) {
		e.add("nextcap");
	    }
	}


	
	String[] context = new String[e.size()];
	e.toArray(context);
        return context;  
    }

//    public static void main(String[] args) {
//	  String data = 
//	     "But the {@ Bush @} administration says it wants to see evidence that all {@ Cocom @} members are complying fully with existing export-control procedures before it will support further liberalization .\nTo make its point , it is challenging the Italian government to explain reports that {@ Olivetti @} may have supplied the {@ Soviet Union @} with sophisticated computer-driven devices that could be used to build parts for combat aircraft .\nThe {@ New York Times @} is great .";
//	  NFEventGenerator nteg = new NFEventGenerator();
//	  nteg.generateEventList(new StringReader(data));
//    }
 
}





