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
import opennlp.common.util.*;

import java.io.*;
import java.util.*;

/**
 * Generate events for maxent decisions for tokenization.
 *
 * @author      Jason Baldridge
 * @version     $Revision$, $Date$
 */

public class TokContextGenerator implements ContextGenerator {

    /**
     * Builds up the list of features based on the information in the Object,
     * which is a pair containing a StringBuffer and and Integer which
     * indicates the index of the position we are investigating.
     */
    public String[] getContext(Object o) {	
	StringBuffer sb = (StringBuffer)((ObjectIntPair)o).a;
	int id = ((ObjectIntPair)o).b;
		
	List preds = new ArrayList();
	if (id>0) {
	    addCharPreds("p1", sb.charAt(id-1), preds);
	    if (id>1) {
		addCharPreds("p2", sb.charAt(id-2), preds);
	    }
	}
	addCharPreds("f1",sb.charAt(id), preds);
	if (id+1 < sb.length()) {
	    addCharPreds("f2", sb.charAt(id+1), preds);
	}

	String[] context = new String[preds.size()];
	preds.toArray(context);
	return context;
    }
    

    /**
     * Helper function for getContext.
     */
    private void addCharPreds(String key, char c, List preds) {
	preds.add(key + "=" + c);
	if (Character.isLetter(c)) {
	    preds.add(key+"_alpha");
	    if (Character.isUpperCase(c)) {
		preds.add(key+"_caps");
	    }
	} else if (Character.isDigit(c)) {
	    preds.add(key+"_num");
	} else if (Character.isWhitespace(c)) {
	    preds.add(key+"_ws");
	} else {
	    if (c=='.' || c=='?' || c=='!') {
		preds.add(key+"_eos");
	    } else if (c=='`' || c=='"' || c=='\'') {
		preds.add(key+"_quote");
	    } else if (c=='[' || c=='{' || c=='(') {
		preds.add(key+"_lp");
	    } else if (c==']' || c=='}' || c==')') {
		preds.add(key+"_rp");
	    }
	}
    }

 
}

