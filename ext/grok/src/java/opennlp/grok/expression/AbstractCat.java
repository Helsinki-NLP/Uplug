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

package opennlp.grok.expression;

import opennlp.grok.util.*;
import opennlp.common.synsem.*;
import opennlp.common.unify.*;
import opennlp.common.util.*;
import gnu.trove.*;
import java.util.*;

/**
 * The adapter for CCG categories.  Creates some reasonable default behavior.
 *
 * @author      Gann Bierner
 * @version $Revision$, $Date$ */
public abstract class AbstractCat implements Category, TLinkable {
    // Static stuff
    static {
	Params.register("Display:Features", "false");
	Params.register("Display:Indices", "false");
	Params.register(":Print Length", "20");
    }

    // the feature structure associated with this AbstractCat
    protected FeatureStructure _featStruc;

    // methods from Category which should be implemented by subclasses of
    // AbstractCat
    public abstract String toString();
    public abstract boolean equals(Object c);
    public abstract boolean occurs(Variable v);
    public abstract Category copy();
    public abstract Object fill (Substitution s) throws UnifyFailure;
    public abstract void unifyCheck (Object u) throws UnifyFailure;
    public abstract Object unify (Object u, Substitution sub) 
	throws UnifyFailure;

    
    public boolean shallowEquals(Object o) { 
	return equals(o); 
    }

    public void deepMap (ModFcn mf) { 
	mf.modify(this);
    }

    public void forall(CategoryFcn f) { 
	f.forall(this); 
    }
    
    public FeatureStructure getFeatureStructure () { 
	return _featStruc; 
    }

    public void setFeatureStructure (FeatureStructure fs) { 
	_featStruc = fs; 
    }
    
    // methods to support printing of Categories
    public String prettyPrint() { return prettyPrint(""); }
    protected String prettyPrint(String pad) { return pad+toString(); }

    protected int prettyLength(String s) {
	int max=0, cur=0;
	for(int i=0; i<s.length(); i++)
	    if(s.charAt(i) == '\n') {
		max = Math.max(cur, max);
		cur = 0;
	    } else cur++;
	return Math.max(max, cur);
    }
    
    //protected String makeString (int l) {
    //	  StringBuffer sb = new StringBuffer();
    //	  for(int i=0; i<l; i++) s+=" ";
    //	  return s;
    //}

    // stuff for hashing
    private HashMap hashStringMap = new HashMap();
    String getHashString(HashMap subst, int[] c) { return toString(); }
    public String hashString() {
	String sf = Params.getProperty("Display:Features");
	String si = Params.getProperty("Display:Indices");
	Params.setProperty("Display:Features", "true");
	Params.setProperty("Display:Indices", "false");
	hashStringMap.clear();
	int[] c = {0};
	String hashStr = getHashString(hashStringMap, c);
	Params.setProperty("Display:Features", sf);
	Params.setProperty("Display:Indices", si);
	return hashStr;
    }

    public static boolean showFeature() {
	return Params.getBoolean("Display:Features");
    }

    public static int tooLong(){
	return Integer.parseInt(Params.getProperty(":Print Length"));
    }

    //public static final TIntObjectHashMap INDEX_TO_FEAT_STRUCS =
    //	new TIntObjectHashMap();

    protected TLinkable _previous, _next;
 
    /**
     * Returns the linked list node after this one.
     *
     * @return a <code>TLinkable</code> value
     */
    public TLinkable getNext() {
        return _next;
    }
 
    /**
     * Returns the linked list node before this one.
     *
     * @return a <code>TLinkable</code> value
     */
    public TLinkable getPrevious() {
        return _previous;
    }
    
    /**
     * Sets the linked list node after this one.
     *
     * @param linkable a <code>TLinkable</code> value
     */
    public void setNext(TLinkable linkable) {
        _next = linkable;
    }
 
    /**
     * Sets the linked list node before this one.
     *
     * @param linkable a <code>TLinkable</code> value
     */
    public void setPrevious(TLinkable linkable) {
        _previous = linkable;
    }

}
