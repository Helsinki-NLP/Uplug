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

public class NFEventCollector implements EventCollector {

    private BufferedReader br;
    private ContextGenerator cg = new NFContextGenerator();
    
    public NFEventCollector(Reader data) {
	br = new BufferedReader(data);
    }
    
    public static Pair convertAnnotatedString(String str) {
	// build datalist to send to Event generator.  Also build
	// outcomes for each token.
	ArrayList tokens = new ArrayList();
	ArrayList outcomes = new ArrayList();
	StringTokenizer st = new StringTokenizer(str);
	boolean inName=false;
	while(st.hasMoreTokens()) {
	    String tok = st.nextToken();
	    if(tok.equals("{@")) {
		outcomes.add("T");
		tokens.add(st.nextToken());
		inName=true;
	    } else if(tok.equals("@}")) {
		inName=false;
	    } else if(inName) {
		outcomes.add("T");
		tokens.add(tok);
	    } else {
		outcomes.add("F");
		tokens.add(tok);
	    }
	}
	return new Pair(tokens, outcomes);
    }
    
    /** 
     * Builds up the list of features using the Reader as input.  For now, this
     * should only be used to create training data.
     */
    public Event[] getEvents() {
	return getEvents(false);
    }
    public Event[] getEvents(boolean evalMode) {
	ArrayList elist = new ArrayList();
	int numMatches;
	
	try {
	    String s = br.readLine();
	    
	    while (s != null) {
		Pair p = convertAnnotatedString(s);
		List tokenList = (ArrayList)p.a;
		String[] tokens = new String[tokenList.size()];
		tokenList.toArray(tokens);
		ArrayList outcomes = (ArrayList)p.b;
		
		for (int i=0; i<tokens.length; i++) {
		    String[] context =
			cg.getContext(new ObjectIntPair(tokens, i));
		    Event e = new Event((String)outcomes.get(i), context);
		    elist.add(e);
		    //System.out.println(e);
		}
		s = br.readLine();
	    }
	} catch (Exception e) { e.printStackTrace(); }

	Event[] events = new Event[elist.size()];
        for(int i=0; i<events.length; i++)
            events[i] = (Event)elist.get(i);
 
        return events;
    }
 
}
