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

import java.util.*;

import opennlp.common.synsem.*;
import opennlp.common.unify.*;

import opennlp.grok.unify.*;
import opennlp.grok.util.*;

/**
 * An adapter for variables that implements many of the requirements of
 * variables and categories.
 *
 * @author      Gann Bierner
 * @version     $Revision$, $Date$
 */
public abstract class AbstractVarCat 
    extends AbstractCat
    implements Variable, Indexed {

    protected String _name;           // String rep of this variable

    protected int _index = 0;

    protected AbstractVarCat() {}
    
    protected AbstractVarCat (String n) {
    	  _name = n;
    }

    protected AbstractVarCat (String n, int index) {
    	  _name = n;
	  _index = index;
    }
    
    public int getIndex () {
	return _index;
    }

    public void setIndex (int uniqueIndex) {
	_index = uniqueIndex;
    }

    public String name() { 
	return _name; 
    }
    
    public int hashCode() { 
	return _name.hashCode() + _index; 
    }

    public boolean equals (Object o) {
	if (o instanceof AbstractVarCat
	    && _index == ((AbstractVarCat)o)._index
	    && _name.equals(((AbstractVarCat)o)._name)) {
	    return true;
	} else {
	    return false;
	}
    }

    public boolean occurs (Variable v) { 
	return equals(v); 
    }

    public void unifyCheck (Object u) throws UnifyFailure {
	if (!(u instanceof Category)) {
	    throw new UnifyFailure();
	}
    }

    public Object fill (Substitution sub) throws UnifyFailure {
	Object val = sub.getValue(this);
	if (val != null) {
	    return val;
	} else {
	    return this;
	}
    }


    protected String getHashString(HashMap subst, int[] c) {
	if(subst.containsKey(_name))
	    return "V" + (String)subst.get(_name);
	else {
	    c[0]++;
	    String s = String.valueOf(c[0]);
	    subst.put(_name, s);
	    return "V"+s;
	}
    }

    public String toString() {
	//String fs = showFeature() && F!=null? F.toString() : "";
	StringBuffer sb = new StringBuffer();
	sb.append(_name).append(_index);
	return sb.toString();
    }

}


