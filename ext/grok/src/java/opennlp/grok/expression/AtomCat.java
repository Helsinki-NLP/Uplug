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

import opennlp.grok.unify.*;
import opennlp.hylo.*;
import opennlp.common.synsem.*;
import opennlp.common.unify.*;
import org.jdom.*;

/**
 * The most basic CG catagory.
 * <p>
 * Syntax: n | s
 *
 * @author      Gann Bierner and Jason Baldridge
 * @version     $Revision$, $Date$
 */
public final class AtomCat extends AbstractCat implements TargetCat {

    public static final int NP = 0;
    public static final int N  = 1;
    public static final int S  = 2;

    private int type;
    private LF _semantics;
    private int _index = 0;
    

    public AtomCat (Element acel) {
	type = getType(acel.getAttributeValue("t"));
	String id = acel.getAttributeValue("id");
	if (id != null) {
	    _index = Integer.parseInt(id);
	}
	
	Element fsEl = acel.getChild("fs");
	if (fsEl != null) {
	    _featStruc = new GFeatStruc(fsEl);
	}
	else {
	    _featStruc = new GFeatStruc();
	}

	_featStruc.setIndex(_index);
	
	Element lf = acel.getChild("lf");
	if (lf != null) {
	    _semantics = HyloHelper.getLF((Element)lf.getChildren().get(0));
	}
	else {
	    _semantics = new HyloVar();
	}
    }

    
    public AtomCat (String t) {
	type = getType(t);
	_featStruc = new GFeatStruc();
	_semantics = new HyloVar();
    }


    protected AtomCat (int t, FeatureStructure fs, LF s) {
	type = t; 
	_featStruc = fs; 
	_semantics = s;
    }


    public String getType() {
	switch(type) {
	case 0: return "np";
	case 1: return "n";
	case 2: return "s";
	default: return null;
	}
    }

    public void setLF (LF lf) {
	_semantics = lf;
    }

    public LF getLF () {
	return _semantics;
    }
    
    public Category copy() {
	return new AtomCat(type, _featStruc.copy(), _semantics.copy());
    }

    public void deepMap (ModFcn mf) { 
	_semantics.deepMap(mf);
	mf.modify(this);
    }

    public boolean occurs (Variable v) { 
	return _semantics.occurs(v); 
    }

    public void unifyCheck (Object u) throws UnifyFailure {
	if (u instanceof AtomCat) {
	    if (type != ((AtomCat)u).type) {
		throw new UnifyFailure();
	    }
	} else if (!(u instanceof Variable)) {
	    throw new UnifyFailure();
	}
    }

    public Object unify (Object u, Substitution sub) 
	throws UnifyFailure {

	if (u instanceof AtomCat && type == ((AtomCat)u).type) {
	    AtomCat u_ac = (AtomCat)u;
	    FeatureStructure $fs;
	    if (_featStruc == null) {
		$fs = u_ac._featStruc;
	    } else if (u_ac._featStruc == null) {
		$fs = _featStruc;
	    } else {
		$fs = (FeatureStructure)_featStruc.unify(u_ac._featStruc, sub);
	    }

	    LF $sem = (LF)Unifier.unify(_semantics, u_ac._semantics, sub);
	    return new AtomCat(type, $fs, $sem);
	}
	else {
	    throw new UnifyFailure();
	}
    }

    public Object fill (Substitution s) throws UnifyFailure {
	AtomCat $ac =
	    new AtomCat(type, _featStruc.copy(), (LF)_semantics.fill(s));
	return $ac;
    }

    public boolean shallowEquals(Object c) {
	if (c instanceof AtomCat) {
	    AtomCat ac = (AtomCat)c;
	    return type == ac.type;
	}
	return false;
    }
    
    public boolean equals(Object c) {
	if (c instanceof AtomCat) {
	    AtomCat ac = (AtomCat)c;
	    return type == ac.type && _featStruc.equals(ac._featStruc);
	}
	return false;
    }

    public String toString() {

	StringBuffer sb = new StringBuffer();
	switch (type) {
	case NP : sb.append("np"); break;
	case N  : sb.append('n'); break;
	case S  : sb.append('s');
	}

	if(_featStruc != null && showFeature())
	    sb.append(_featStruc.toString());
	
	sb.append(':').append(_semantics.toString());

	if (sb.length() == 0) return "UnknownCat";
	return sb.toString();
    }

    protected String getHashString(java.util.HashMap subst, int[] c) {
	return toString();
    }

    private static int getType (String type) {
	if (type==null) {
	    return N;
	} else {
	    if (type.equalsIgnoreCase("s")) {
		return S;
	    } else if (type.equalsIgnoreCase("n")) {
		return N;
	    } else if (type.equalsIgnoreCase("NP")) {
		return NP;
	    } else {
		return N;
	    }
	}
    }
    
}
