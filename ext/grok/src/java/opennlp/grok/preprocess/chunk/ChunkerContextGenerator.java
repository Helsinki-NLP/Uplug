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

import opennlp.common.morph.*;
import opennlp.common.util.*;
import opennlp.maxent.*;

import java.io.*;
import java.util.*;

/**
 * A context generator for the Shallow Parser.
 *
 * @author      Joerg Tiedemann
 * @version     $Revision$, $Date$
 */

public class ChunkerContextGenerator implements ContextGenerator {
    private MorphAnalyzer _manalyzer;
    private static final boolean DEBUG = false;
    
    public ChunkerContextGenerator () {
	_manalyzer = null;
    }
    
    public ChunkerContextGenerator (MorphAnalyzer ma) {
	_manalyzer = ma;
    }

    /**
     * Either: (rare?, [words, tags, position])
     * or    : [words, tags, position]
     *
     * right now this will be very inefficient for a linked list.
     */
    public String[] getContext (Object o) {

	boolean rare=false;
	boolean all=true;
	if(o instanceof Pair) {
	    rare = ((Boolean)((Pair)o).b).booleanValue();
	    all = false;
	    o=((Pair)o).a;
	}
	Object[] data = (Object[])o;
	List ls = (List)data[0];                      // list of words
	List tags = (List)data[1];                    // list of tags
	List labels = (List)data[2];                  // list of labels
	int pos = ((Integer)data[3]).intValue();      // current position

	String tag, ntag, ptag, nntag, pptag;
	String next, nextnext, lex, prev, prevprev;
	String labelprev, labelprevprev;
	labelprev=labelprevprev=null;
	next=nextnext=lex=prev=prevprev=null;
	ntag=nntag=ptag=pptag=null;
	
	lex = (String)ls.get(pos);                      // current word
	tag = (String)tags.get(pos);                    // POS tag

	if (ls.size()>pos+1)     {                      //    >1 words left
	    next = (String)ls.get(pos+1);
	    ntag = (String)tags.get(pos+1);
	    // next = filterEOS((String)ls.get(pos+1));	    

	    if (isEOS((String)ls.get(pos+1)))
		nextnext = "*SE*";
	    else{
		if (ls.size()>pos+2) {                  //    >2 words left
		    nextnext = (String)ls.get(pos+2);
		    nntag = (String)tags.get(pos+2);
		}
	    }

	    //	    if (ls.size()>pos+2)
	    //		nextnext = filterEOS((String)ls.get(pos+2));
	    //	    else
	    //		nextnext = "*SE*";
	    
	}
	else {
	    if (ls.size()>1) {                          // if more than 1 word!
		next = "*SE*";                          //     Sentence End
	    }
	}
	    
	if(pos-1>=0) {
	    prev = (String)ls.get(pos-1);
	    labelprev = (String)labels.get(pos-1);
	    ptag = (String)tags.get(pos-1);

	    if(pos-2>=0) {
		prevprev = (String)ls.get(pos-2);
		labelprevprev = (String)labels.get(pos-2);
		ptag = (String)tags.get(pos-2);
	    }
	    else {
		prevprev = "*SB*";                     // Sentence Beginning
	    }
	}
	else {
	    if (ls.size()>1) {                          // if more than 1 word!
		prev = "*SB*";                          // Sentence Beginning
	    }
	}


	//*****************************************************************
	// add features
	//*****************************************************************

	ArrayList e = new ArrayList();

	if (DEBUG) System.out.println(lex);
	if(!rare || all) {                            // add the word itself
	    //e.add("w="+lex.toLowerCase());
	    e.add("w="+lex);
	    if (DEBUG) System.out.println("  w="+lex.toLowerCase());
	}
	e.add("s="+lex.length());

	e.add("t="+tag);                             // add the POS tag
	if (DEBUG) System.out.println("  t="+tag);

	if (ntag != null) {
	    e.add("nt="+ntag);                      // next POS tag
	    if (DEBUG) System.out.println("  nt="+ntag);
	}

	if (ptag != null) {
	    e.add("pt="+ptag);                      // prev POS tag
	    if (DEBUG) System.out.println("  pt="+ptag);
	}

	// add the words and labels of the surrounding context
	if(prev!=null) {
	    //e.add("p="+prev.toLowerCase());        // add previous word
	    e.add("p="+prev);                        // add previous word
	    if (DEBUG) System.out.println("  p="+prev.toLowerCase());
	    if (labelprev!=null) {
		if (DEBUG) System.out.println("  l="+labelprev);
		e.add("l="+labelprev);              // add previous label
	    }
    
	    
	    if(prevprev!=null) {
		if (DEBUG) System.out.println("  pp="+prevprev.toLowerCase());
		//e.add("pp="+prevprev.toLowerCase());   // add prevprev word
		if(labelprevprev!=null) {
		    if (DEBUG) System.out.println("  lp="+labelprevprev);
		    e.add("lp="+labelprevprev);        // add prevprev label
		}
	    }
	    
	}

	if (next!=null) {
	    if (DEBUG) System.out.println("  n="+next.toLowerCase());
	    //e.add("n="+next.toLowerCase());            // add next word
	    e.add("n="+next);                            // add next word
	}
	
	
       	String[] context = new String[e.size()];
	e.toArray(context);
        return context;  

    }

    private static final String filterEOS(String s) {
	if (!(s.length() == 1))
	    return s;
	char c = s.charAt(0);
	if (c=='.' || c=='?' | c=='!')
	    return "*SE*";
	return s;
    }
 
    private static final boolean isEOS(String s) {
	if (!(s.length() == 1))
	    return false;
	char c = s.charAt(0);
	if (c=='.' || c=='?' | c=='!')
	    return true;
	return false;
    }

    public static void main(String[] args) {
	  
	  ChunkerContextGenerator gen = new ChunkerContextGenerator();
    }
 
}
