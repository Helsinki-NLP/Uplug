///////////////////////////////////////////////////////////////////////////////
// Copyright (C) 2002 Jason Baldridge
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
 * A variable that can stand for any set of categories.
 *
 * @author      Jason Baldridge
 * @version     $Revision$, $Date$
 */
public class SetVar extends AbstractVarCat {
    
    private static int UNIQUE_STAMP = 0;
    
    public SetVar () {
	this("SV"+UNIQUE_STAMP++);
    }
    
    public SetVar (String name) {
	super(name);
    }

    protected SetVar (String name, int index) {
	super(name, index);
    }
    
    public Category copy () {
	return new SetVar(_name, _index);
    }

    public boolean equals (Object o) {
	if (o instanceof SetVar && super.equals(o)) {
	    return true;
	} else {
	    return false;
	}
    }

    public void unifyCheck (Object u) throws UnifyFailure {
	if (!(u instanceof SetCat)
	    || !(u instanceof SetVar)) {
	    throw new UnifyFailure();
	}
    }
    
    public Object unify (Object u, Substitution sub) throws UnifyFailure {
	if (u instanceof SetCat) {
	    if (((SetCat)u).occurs(this)) {
		throw new UnifyFailure();
	    }
	    return sub.makeSubstitution(this, u);
	}
	else {
	    throw new UnifyFailure();
	}
    }

    
    public String toString () {	
	return _name+_index;
    }

}
