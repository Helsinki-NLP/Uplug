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

import opennlp.maxent.*;

import opennlp.common.util.*;

import java.io.*;
import java.util.*;

/**
 * An event generator for the maxent POS Tagger.
 *
 * @author      Gann Bierner
 * @version     $Revision$, $Date$
 */

public class POSEventCollector implements EventCollector {

    private BufferedReader br;
    private ContextGenerator cg;
    
    public POSEventCollector(Reader data, ContextGenerator gen) {
	br = new BufferedReader(data);
	cg = gen;
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
    
    public static Pair convertAnnotatedString(String s) {
	ArrayList tokens = new ArrayList();
	ArrayList outcomes = new ArrayList();
	StringTokenizer st = new StringTokenizer(s);
	while(st.hasMoreTokens()) {
	    Pair p = split(st.nextToken());
	    tokens.add(p.a);
	    outcomes.add(p.b);
	}
	return new Pair(tokens, outcomes);
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
		    String tok = (String)split(st.nextToken()).a;
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
		Pair p = convertAnnotatedString(s);
		ArrayList tokens = (ArrayList)p.a;
		ArrayList outcomes = (ArrayList)p.b;
		ArrayList tags = new ArrayList();
		
		for (int i=0; i<tokens.size(); i++) {
		    Object[] params = {tokens, tags, new Integer(i)};
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
	String data = "the/DT stories/NNS about/IN well-heeled/JJ communities/NNS and/CC developers/NNS";
	EventCollector ec = new POSEventCollector(new StringReader(data),
						  new POSContextGenerator());
	Event[] events = ec.getEvents();
	for(int i=0; i<events.length; i++)
	    System.out.println(events[i].getOutcome());
    }
    
}
