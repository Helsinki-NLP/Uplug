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
import opennlp.maxent.*;
import opennlp.common.util.*;

import java.io.*;
import java.util.*;

/**
 * An event generator for the maxent Shallow Parser.
 *
 * @author      Joerg Tiedemann
 * @version     $Revision$, $Date$
 */

public class ChunkerEventCollector  implements EventCollector {

    private BufferedReader br;
    private ContextGenerator cg = new ChunkerContextGenerator();

    public ChunkerEventCollector(Reader data) {
	br = new BufferedReader(data);
    }

    public ChunkerEventCollector(Reader data, ContextGenerator gen) {
	br = new BufferedReader(data);
	cg = gen;
    }

    public Event[] getEvents() {
	return getEvents(false);
    }

    private Set getFrequent(BufferedReader br) {
	HashMap map = new HashMap();

	try {
	    for(String s = br.readLine(); s!=null; s=br.readLine()) {
		StringTokenizer st = new StringTokenizer(s);
		while(st.hasMoreTokens()) {
		    String tagged = (String)split(st.nextToken()).a;
		    String tok = (String)split(tagged).a;
		    Counter c = (Counter)map.get(tok);
		    if(c!=null)
			c.increment();
		    else
			map.put(tok, new Counter());
		}
	    }
	} catch (IOException e) { e.printStackTrace(); }

	HashSet set = new HashSet();
	for(Iterator i=map.entrySet().iterator(); i.hasNext();) {
	    Map.Entry entry = (Map.Entry)i.next();
	    if(((Counter)entry.getValue()).passesCutoff(5))
		set.add(entry.getKey());
	}

	return set;
    }

    private static Pair split(String s) {
	int split = s.lastIndexOf("/");
	if (split == -1) {
	    System.out.println("There is a problem in your training data: "
			       + s
			       + " does not conform to the format WORD/TAG.");
	    return new Pair(s, "UNKNOWN");
	}
	return new Pair(s.substring(0, split), s.substring(split+1));
    }
    
    /** 
     * Builds up the list of features using the Reader as input.  For now, this
     * should only be used to create training data.
     */
    public Event[] getEvents(boolean evalMode) {
	ArrayList elist = new ArrayList();
	int numMatches;
	Set frequent;
	
	if(!evalMode) {
	    System.out.println("Reading in all the data");
	    try {
		StringBuffer sb = new StringBuffer();
		for(String s = br.readLine(); s!=null; s=br.readLine())
		    sb.append(s+"\n");
		System.out.println("Getting most frequent words");
		frequent =
		    getFrequent(new BufferedReader(
				     new StringReader(sb.toString())));
		br = new BufferedReader(new StringReader(sb.toString()));
		sb=null;
	    } catch (IOException e) { e.printStackTrace(); }
	}

	//System.out.println("Collecting events");
	try {
	    String s = br.readLine();
	    
	    while (s != null) {
		ArrayList tokens = new ArrayList();
		ArrayList first = new ArrayList();
		ArrayList outcomes = new ArrayList();
		StringTokenizer st = new StringTokenizer(s);
		while(st.hasMoreTokens()) {
		    Pair p = split(st.nextToken());
		    Pair pt = split((String)p.a);
		    tokens.add(pt.a);
		    first.add(pt.b);
		    outcomes.add(p.b);
		}
		ArrayList tags = new ArrayList();
		
		//System.out.println(tokens.size() + "tokens");
		for (int i=0; i<tokens.size(); i++) {
		    Object[] params = {tokens, first, tags, new Integer(i)};
		    String[] context = cg.getContext(params);
		    Event e = new Event((String)outcomes.get(i), context);
		    tags.add(outcomes.get(i));
		    elist.add(e);
		}
		s = br.readLine();
	    }
	} catch (Exception e) { e.printStackTrace(); }

	Event[] events = new Event[elist.size()];
        for(int i=0; i<events.length; i++)
            events[i] = (Event)elist.get(i);
 
        return events;
    }

    public static void main(String[] args) {
	String data = "Rockwell/NNP/B-NP said/VBD/B-VP the/DT/B-NP agreement/NN/I-NP calls/VBZ/B-VP for /IN/B-SBAR it/PRP/B-NP to/TO/B-VP supply/VB/I-VP 200/CD/B-NP additional/JJ/I-NP so-called/JJ/I-NP shipsets/NNS/I-NP for/IN/B-PP the/DT/B-NP planes/NNS/I-NP ././O";
	EventCollector ec = new ChunkerEventCollector(new StringReader(data));
	Event[] events = ec.getEvents();
	for(int i=0; i<events.length; i++)
	    System.out.println(events[i].getOutcome());
    }
    
}
