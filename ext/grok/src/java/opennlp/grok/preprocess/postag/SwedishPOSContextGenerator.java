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

import opennlp.common.morph.*;
import opennlp.common.util.*;
import opennlp.maxent.*;

import java.io.*;
import java.util.*;

/**
 * A context generator for the Swedish POS Tagger.
 *
 * @author      Joerg Tiedemann
 * @version     $Revision$, $Date$
 */

public class SwedishPOSContextGenerator implements ContextGenerator {
    private MorphAnalyzer _manalyzer;
    private static final boolean DEBUG = false;
    private static final boolean USELEX = true;
    private static final boolean TEST = true;

    
    public SwedishPOSContextGenerator () {
	_manalyzer = null;
    }
    
    public SwedishPOSContextGenerator (MorphAnalyzer ma) {
	_manalyzer = ma;
	//	System.out.println("new constructor - yes!\n");
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
	int pos = ((Integer)data[2]).intValue();      // current position

	String next, nextnext, lex, prev, prevprev;
	String tagprev, tagprevprev,tagprev3;
	tagprev=tagprevprev=tagprev3=null;
	next=nextnext=lex=prev=prevprev=null;
	
	lex = (String)ls.get(pos);                      // current word
	if (ls.size()>pos+1)     {                      //    >1 words left
	    next = (String)ls.get(pos+1);
	    //	    next = filterEOS((String)ls.get(pos+1));	    

	    if (isEOS((String)ls.get(pos+1)))
		nextnext = "*SE*";
	    else{
		if (ls.size()>pos+2)                    //    >2 words left
		    nextnext = (String)ls.get(pos+2);
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
	    tagprev = (String)tags.get(pos-1);

	    if(pos-2>=0) {
		prevprev = (String)ls.get(pos-2);
		tagprevprev = (String)tags.get(pos-2);
	    }
	    else {
		prevprev = "*SB*"; // Sentence Beginning
	    }
	    if(pos-3>=0) {
		tagprev3 = (String)tags.get(pos-3);
	    }
	}
	else {
	    if (ls.size()>1) {                          // if more than 1 word!
		prev = "*SB*";                          // Sentence Beginning
	    }
	}


	//****************************************************************


	ArrayList e = new ArrayList();

	if (TEST){

	    if (DEBUG) System.out.println(lex);

	    // add the word itself
	    if(!rare || all) {
		e.add("w="+lex.toLowerCase());
		e.add("w="+lex.toLowerCase());
		e.add("w="+lex.toLowerCase());
		e.add("w="+lex.toLowerCase());
		if (DEBUG) System.out.println("  w="+lex.toLowerCase());
	    }
	    e.add("l="+lex.length());
	    
	    // do some basic suffix analysis		
	    if (_manalyzer != null) {
		String[] affs = _manalyzer.getSuffixes(lex);
		for(int i=0; i<affs.length; i++) {
		    if (DEBUG) System.out.println("  suf="+affs[i]);
		    e.add("suf="+affs[i]);
		}
	    }
	    // see if the word has any special characters
	    if (lex.indexOf('-') != -1) {
		if (DEBUG) System.out.println("  h");
		e.add("h");
	    }
	    if (PerlHelp.hasCap(lex)) {
		if (DEBUG) System.out.println("  c");
		e.add("c");
	    }
	    if (PerlHelp.hasNum(lex)) {
		if (DEBUG) System.out.println("  d");
		e.add("d");
	    }
	    // add the words and pos's of the surrounding context

	    if(prev!=null) {
		e.add("p="+prev.toLowerCase());
		if (DEBUG) System.out.println("  p="+prev.toLowerCase());
	    }
	    if (tagprev!=null) {
		if (DEBUG) System.out.println("  t="+tagprev);
		e.add("t="+tagprev);
		if (DEBUG) System.out.println("  tpref="+tagPrefix(tagprev));
       		e.add("tpref="+tagPrefix(tagprev));
	    }
	    if (next!=null) {
		if (DEBUG) System.out.println("  n="+next.toLowerCase());
		e.add("n="+next.toLowerCase());
	    }
	}
	else{



	if (DEBUG) System.out.println(lex);
	// add the word itself
	if(!rare || all) {
	    lex.toLowerCase();
	    e.add("w="+lex.toLowerCase());
	    if (DEBUG) System.out.println("  w="+lex.toLowerCase());
	}

	// do some basic suffix analysis		
	if (_manalyzer != null) {

	    String[] affs = _manalyzer.getSuffixes(lex);
	    for(int i=0; i<affs.length; i++) {
		if (DEBUG) System.out.println("  suf="+affs[i]);
		e.add("suf="+affs[i]);
	    }


	    // don't use context if the lexicon is included in training
	    if (!USELEX){
		if (next != null) {
		    affs = _manalyzer.getSuffixes(next);
		    for(int i=0; i<affs.length; i++) {
			if (DEBUG) System.out.println("  nsuf="+affs[i]);
			e.add("nsuf="+affs[i]);
		    }
		}
		if (nextnext != null) {
		    affs = _manalyzer.getSuffixes(nextnext);
		    for(int i=0; i<affs.length; i++) {
			if (DEBUG) System.out.println("  nnsuf="+affs[i]);
			e.add("nnsuf="+affs[i]);
		    }
		}
	    }
	}

	// see if the word has any special characters
	if (lex.indexOf('-') != -1) {
	    if (DEBUG) System.out.println("  h");
	    e.add("h");
	}

	if (PerlHelp.hasCap(lex)) {
	    if (DEBUG) System.out.println("  c");
	    e.add("c");
	}
	
	if (PerlHelp.hasNum(lex)) {
	    if (DEBUG) System.out.println("  d");
	    e.add("d");
	}


	// add the words and pos's of the surrounding context
	if(prev!=null) {

	    // don't use context if the lexicon is included in training
	    if (!USELEX){
		e.add("p="+prev.toLowerCase());
		if (DEBUG) System.out.println("  p="+prev.toLowerCase());
	    }

	    if (tagprev!=null) {

		// don't use context if the lexicon is included in training
		if (!USELEX){
		    if (DEBUG) System.out.println("  t="+tagprev);
		    e.add("t="+tagprev);
		}

		if (DEBUG) System.out.println("  tpref="+tagPrefix(tagprev));
       		e.add("tpref="+tagPrefix(tagprev));
	    }

	    if(prevprev!=null) {
		// don't use context if the lexicon is included in training
		if (!USELEX){
		    if (DEBUG) System.out.println("  pp="+
						  prevprev.toLowerCase());
		    e.add("pp="+prevprev.toLowerCase());
		}
		if(tagprevprev!=null) {
		    if (!USELEX){
			if (DEBUG) System.out.println("  tt="+tagprevprev);
			e.add("tt="+tagprevprev);
		    }
		    if (DEBUG) System.out.println("  ttpref="+
						  tagPrefix(tagprevprev));
		    e.add("ttpref="+tagPrefix(tagprevprev));
		}
	    }
	}

	// don't use context if the lexicon is included in training
	if (!USELEX){
	    if (next!=null) {
		if (DEBUG) System.out.println("  n="+next.toLowerCase());
		e.add("n="+next.toLowerCase());
		if (nextnext!=null) {
		    if (DEBUG) System.out.println("  nn="+
						  nextnext.toLowerCase());
		    e.add("nn="+nextnext.toLowerCase());
		}
	    }
	}

	/*
	if (prev==null && next==null){
	    if (DEBUG) System.out.println("  4X w="+lex.toLowerCase());
	    e.add("w="+lex.toLowerCase());    // assume it is a lexical item!
	    e.add("w="+lex.toLowerCase());    // add 4 more events!
	    e.add("w="+lex.toLowerCase());
	    e.add("w="+lex.toLowerCase());
	}
	*/

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

    private static final String tagPrefix(String s) {
	if (s != null){
	    if (s.length() > 1) 
		return s.substring(0,2);
	    if (s.length() == 1) 
		return s.substring(0,1);
	}
	return "";
    }
    
    public static void main(String[] args) {
	  
	  SwedishPOSContextGenerator gen = new SwedishPOSContextGenerator();
	  String[] lexA = {"the", "stories", "about", "well-heeled",
			   "communities", "and", "developers"};
	  String[] tagsA = {"DT", "NNS", "IN", "JJ", "NNS", "CC", "NNS"};
	  ArrayList lex = new ArrayList();
	  ArrayList tags = new ArrayList();
	  for(int i=0; i<lexA.length; i++) {
	      lex.add(lexA[i]);
	      tags.add(tagsA[i]);
	  }

	  Object[] a = {lex, tags, new Integer(2)};
	  Object[] b = {lex, tags, new Integer(0)};

	  String[] ans1 = gen.getContext(new Pair(a, Boolean.FALSE));
	  String[] ans2 = gen.getContext(b);

	  for(int i=0; i<ans1.length; i++)
	      System.out.println(ans1[i]);
	  System.out.println();
	  for(int i=0; i<ans2.length; i++)
	      System.out.println(ans2[i]);
    }
 
}





