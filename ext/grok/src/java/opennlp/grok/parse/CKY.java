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

package opennlp.grok.parse;

import opennlp.grok.lexicon.*;
import opennlp.grok.expression.*;
import opennlp.grok.grammar.*;
import opennlp.grok.util.*;

import opennlp.common.parse.*;
import opennlp.common.synsem.*;
import opennlp.common.unify.*;
import opennlp.common.xml.*;

import gnu.trove.*;
import java.util.*;
import java.io.*;

/**
 * CKY is a chart parser that is used, in this case, with the CCG
 * grammar formalism.
 *
 * @author      Gann Bierner
 * @version     $Revision$, $Date$
 */
public class CKY extends ParserAdapter {

    ArrayList result;

    static {
	Debug.Register("Chart Parser", false);
	Params.register("Display:CKY Chart", "false");
    }
    
    /**
     * class constructor: sets lexicon and rules
     *
     * @param lex    The URL where lexicon is located.
     * @param rule   The URL where the rules are located.
     
     * @exception java.io.FileNotFoundException
     *                                If cannot find file
     * @exception java.io.IOException If cannot find file
     * @exception CatParseException   Cannot parse semantics
     *                                in rule of lex file
     */
    public CKY (String lex, String rule) 
	throws FileNotFoundException, IOException, LexException {
	super(lex, rule);
    }

    public CKY (Lexicon l, RuleGroup r) {
	super(l, r);
    }

    public void createResult (Chart table, int size) throws ParseException {
	// create answer ArrayLists to loop through.
	result = new ArrayList();
	for (Iterator e=table.get(0,size-1).values().iterator(); e.hasNext();) {
	    result.add(e.next());
	}
	debug(table);
	if (result.size() == 0) {
	    throw new ParseException("Unable to parse");
	}
    }
    
    public void parse (Chart table, int size) throws ParseException {
	// actual CKY parsing
	for(int i=0; i<size; i++) table.insertCell(i,i);
	for(int j=1; j<size; j++) {
	    for(int i=j-1; i>=0; i--) {
		for(int k=i; k<j; k++) {
		    table.insertCell(i,k, k+1,j, i,j);
		}
		table.insertCell(i,j);
	    }
	}
	createResult(table, size);
    }

    protected Chart getChart (int size, RuleGroup r) {
	return new Chart(size, r);
    }
    

    public Chart getInitializedTable (List entries) {
	// initialize the Table
	UNIQUE = 0;
	_fsIndex = 1;
	Chart table = getChart(entries.size(), R);
	int i = 0;
	for (Iterator entryIt=entries.iterator(); entryIt.hasNext(); i++) {
	    SignHash wh = (SignHash)entryIt.next();
	    for(Iterator whI=wh.values().iterator(); whI.hasNext();) {
		Category cat = ((Sign)whI.next()).getCategory();
		//cat.setSpan(i, i);
		reindexFeatureStructures(cat);
		cat.deepMap(uniqueFcn);
		UNIQUE++;
	    }
	    table.set(i,i,wh);
	}
	return table;
    }


    /**
     * An integer used to help keep variables unique in lexical items.
     */
    private static int UNIQUE = 0;

    /**
     * A function that makes variables unique.
     */
    private static ModFcn uniqueFcn = new ModFcn() {
	public void modify (Mutable m) {
	    if (m instanceof Indexed) {
		((Indexed)m).setIndex(UNIQUE);
	    }
	}};


    private Set _catFeatStrucs;
    private TIntIntHashMap _reindexed;
    private int _fsIndex = 1;

    private CategoryFcn indexFcn = new CategoryFcnAdapter() {
    	public void forall (Category c) {
	    FeatureStructure fs = c.getFeatureStructure();
	    if (fs != null) {
		_catFeatStrucs.add(fs);
		int index = fs.getIndex();
		if (index > 0) {
		    int $index = _fsIndex++;
		    fs.setIndex($index);
		    _reindexed.put(index, $index); 
		}
	    }
	}};

    private void reindexFeatureStructures (Category c) {
	_catFeatStrucs = new THashSet();
	_reindexed = new TIntIntHashMap();

	c.forall(indexFcn);

	for (Iterator fsIt=_catFeatStrucs.iterator(); fsIt.hasNext();) {
	    FeatureStructure fs = (FeatureStructure)fsIt.next();
	    int inheritorId = fs.getInheritorIndex();
	    if (inheritorId > 0) {
		int $inheritorId = _reindexed.get(inheritorId);
		if ($inheritorId > 0) {
		    fs.setInheritorIndex($inheritorId);
		}
	    }
	}
    }
    

    
    private void debug (Chart table) {
	if(Params.getBoolean("Display:CKY Chart")) {
	    table.printChart();
	    System.out.println(table);
	}
    }
    
    public void parse (String s) throws ParseException {
	try {
	    List entries = L.getWords(s);
	    Chart table = getInitializedTable(entries);
	    parse(table, entries.size());
	    debug(table);
	} catch (LexException e) {
	    throw new ParseException("Unable to retrieve lexical entries.");
	}
    }
    
    public void parse (NLPDocument d) throws ParseException {
	try {
	    List entries = L.getWords(d);	
	    Chart table = getInitializedTable(entries);
	    parse(table, entries.size());
	    debug(table);
	} catch (LexException e) {
	    throw new ParseException("Unable to retrieve lexical entries.");
	}
    }

    public void parse (Sign[] inits) throws ParseException {
	Chart table = getChart(inits.length, R);
	for(int i=0; i<inits.length; i++)
	    table.set(i,i,new SignHash(inits[i]));

	parse(table, inits.length);
    }

    public ArrayList getResult() { return result; }
}

