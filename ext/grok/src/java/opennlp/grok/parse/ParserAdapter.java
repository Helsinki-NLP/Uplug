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

import opennlp.grok.expression.*;
import opennlp.grok.lexicon.*;
import opennlp.grok.grammar.*;
import opennlp.grok.preprocess.namefind.*;
import opennlp.grok.util.*;

import opennlp.common.parse.*;
import opennlp.common.synsem.*;
import opennlp.common.unify.*;
import opennlp.common.xml.*;

import java.io.*;
import java.util.*;

/**
 * Fills in a few helpful methods for parsers.
 *
 * @author      Gann Bierner
 * @version     $Revision$, $Date$
 *
 */
public abstract class ParserAdapter implements Parser, ParamListener {

    static {
	Params.register("Results:Use Filter", "false");
	Params.register("Results:Filter", "[S{mode=(ind|int)}:SEM]");
    }
    
    Category Filter = null;

    protected Lexicon L;
    protected RuleGroup R;

    ParserAdapter(Lexicon _L, RuleGroup _R) {
	setGrammar(_L,_R);
	Params.addParamListener(this);
	setFilter(Params.getProperty("Results:Filter"));
    }

    ParserAdapter(String _L, String _R)
	throws FileNotFoundException, IOException, LexException {
	this((Lexicon)Module.New(Lexicon.class, _L, ""),
	     (RuleGroup)Module.New(RuleGroup.class, _R));
    }

    public void paramChanged(String param, String value){
	if (param.equals("Results:Filter")) {
	    setFilter(value);
	}
    }
    public void paramRegistered(String param, String value){}
    public void paramSaving() {}
    
    public void setGrammar(Lexicon _L, RuleGroup _R) { L=_L; R=_R; }
    
//    abstract public void parse(String s)
//	  throws CatParseException, LexException, ParseException, IOException;
//    abstract public void parse(Constituent[] inits)
//	  throws ParseException, CatParseException ;
    
    abstract public ArrayList getResult();

    public void setFilter(String c) {
	Filter = null;
    }

    public void setFilter(Category c) {
	Filter=c;
    }
    public Category getFilter() { return Filter; }
    
    public ArrayList getFilteredResult() {
	ArrayList A = getResult();
	if(Filter == null || !Params.getBoolean("Results:Use Filter"))
	    return A;
	else {
	    for(Iterator i=A.iterator(); i.hasNext();) {
		Sign w=(Sign)i.next();
		try {
		    Unifier.unify(w.getCategory(), Filter);
		}
		catch (UnifyFailure uf) {
		    i.remove();
		}
	    }
	    return A;
	}
    }

}
