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
import opennlp.grok.util.*;
import opennlp.common.synsem.*;
import opennlp.common.unify.*;
import org.jdom.*;
import java.util.*;


/**
 * An adapter for variables that implements many of the requirements of
 * variables and categories.
 *
 * @author      Gann Bierner
 * @version     $Revision$, $Date$
 */
public class VarCat extends AbstractVarCat implements TargetCat {

    private static int VAR_COUNT=0; // used to make unique variables

    protected CatHashSet _cannotCats;   // categories that cannot be unified with
    protected CatHashSet _mustCats;    // categories allowed to unify with

    public VarCat (String n) {
    	  super(n);
    }
    
    public VarCat (String s, FeatureStructure fs) {
	this(s);
	_featStruc=fs;
    }

    public VarCat (String s, FeatureStructure fs, Collection nu, Collection rs) {
	  this(s,fs);
	  _cannotCats = (CatHashSet)nu;
	  _mustCats = (CatHashSet)rs;
    }

    public VarCat (Element e) {
	this(e.getAttributeValue("n"));
	Element fsEl = e.getChild("fs");
	if (fsEl != null)
	    _featStruc = new GFeatStruc(fsEl);

	Element notCats = e.getChild("nonUnifiers");
	if (notCats != null)
	    _cannotCats = new CatHashSet(notCats.getChildren());
	
	Element restrictCats = e.getChild("restrictionSet");
	if (restrictCats != null) {
	    _mustCats = new CatHashSet(restrictCats.getChildren());
	}
	    
    }

    
    public Category copy() {
	VarCat $v = new VarCat(_name, _featStruc, _cannotCats, _mustCats);
	$v.setIndex(_index);
	return $v;
    }

    public Object unify (Object u, Substitution sub) 
	throws UnifyFailure {

	if (u instanceof Category && ((Category)u).occurs(this)) {
	    throw new UnifyFailure();
	} else if (u instanceof AbstractCat) {
	    if (u instanceof VarCat) {
		VarCat var2 = (VarCat)u;
		CatHashSet $mustCats = new CatHashSet();
		FeatureStructure $featStruc;
		if (_featStruc != null) {
		    if (var2._featStruc != null)
			$featStruc = 
			    (FeatureStructure)_featStruc.unify(var2._featStruc, sub);
		    else
			$featStruc = _featStruc;
		}
		else {
		    $featStruc = var2._featStruc;
		}
		
		if (_mustCats != null) {
		    if (var2._mustCats != null) {
			boolean success = false;
			for (Iterator i1=_mustCats.iterator(); i1.hasNext();) {
			    Unifiable u1 = (Unifiable)i1.next();
			    for (Iterator i2=_mustCats.iterator(); i2.hasNext();) {
				try {
				    Object $u = 
					Unifier.unify(u1, (Unifiable)i2.next());
				    $mustCats.addCategory((Category)$u);
				    success = true;
				} catch (UnifyFailure uf) {}
			    }
			}
			if (!success)
			    throw new UnifyFailure();
		    }
		    else {
			$mustCats = _mustCats;
		    }
		}
		else {
		    $mustCats = var2._mustCats;
		}
		
		CatHashSet $cannotCats = null;
		if (_cannotCats != null) {
		    $cannotCats = new CatHashSet(_cannotCats);
		    if (var2._cannotCats != null)
			$cannotCats.addAll(var2._cannotCats);
		}
		else if (var2._cannotCats != null) {
		    $cannotCats = new CatHashSet(var2._cannotCats);
		}
		
		Variable $var = 
		    new VarCat(_name+var2._name, $featStruc,
			       $cannotCats, $mustCats);

		sub.makeSubstitution(this, $var);
		sub.makeSubstitution(var2, $var);
		return $var;
	    } else {
		if (_mustCats != null) {
		    for (Iterator i=_mustCats.iterator(); i.hasNext();) {
			try {
			    Category $c = 
				(Category)Unifier.unify(u, (Unifiable)i.next());
			    return sub.makeSubstitution(this, $c);
		    }
			catch (UnifyFailure uf) {}
		    }
		    throw new UnifyFailure();
		}
		if (_cannotCats != null) {
		    for (Iterator i=_cannotCats.iterator(); i.hasNext();) {
			try {
			    Unifier.unify(u, (Unifiable)i.next());
			    throw new UnifyFailure();
			}
			catch (UnifyFailure uf) {}
		    }
		}
		return sub.makeSubstitution(this, u);
	    }
	} else {
	    throw new UnifyFailure();
	}
    }


    public Object fill (Substitution s) throws UnifyFailure {
	Object val = s.getValue(this);
	if (val != null) {
	    if (_mustCats != null) {
		boolean success = false;
		try {
		    for (Iterator i=_mustCats.iterator();
			 !success && i.hasNext();) {
			Unifier.unify(val, (Unifiable)i.next());
			success = true;
		    }
		} catch (UnifyFailure uf) {}
		if (success) {
		    return val;
		} else {
		    throw new UnifyFailure();
		}
	    } else {
		return val;
	    }
	} else {
	    return this;
	}
    }

    public boolean equals(Object c) {
	if (c instanceof VarCat) {
	    VarCat va = (VarCat)c;
	    if (!_name.equals(va._name) || _index != va._index)
		return false;
	    if (_featStruc != null 
		&& va._featStruc != null 
		&& !_featStruc.equals(va._featStruc))
		return false;
	    return true;
	} else 
	    return false;
    }
    

    public static VarCat genVar() { 
	return new VarCat("GVC"+(VAR_COUNT++)); 
    }

}


