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

import opennlp.grok.io.*;
import opennlp.grok.unify.*;
import opennlp.grok.util.*;
import opennlp.common.synsem.*;
import opennlp.common.unify.*;
import opennlp.common.util.*;
import org.jdom.*;
import java.util.*;

/**
 * A variable representing a stack of arguments
 *
 * @author      Jason Baldridge
 * @version     $Revision$, $Date$
 */
public final class Dollar implements Arg,Variable {

    private final Slash _slash;
    private final String _name;
    private int _index = 0;

    public Dollar (String name) {
	this (new Slash(), name);
    }

    public Dollar (Slash s, String name) {
	_slash = s;
	_name = name;
    }

    public Dollar (Slash s, Element e) {
	this (s, e.getAttributeValue("n"));
    }

    public String name () {
	return _name;
    }
    
    public int getIndex () {
	return _index;
    }

    public void setIndex (int uniqueIndex) {
	_index = uniqueIndex;
    }

    public Arg copy () {
	return new Dollar(_slash.copy(), _name);
    }
    
    public Slash getSlash () {
	return _slash;
    }

    public boolean equals (Object o) {
	return (o instanceof Dollar && _slash.equals(((Dollar)o).getSlash()));
    }

    public int hashCode() { 
	return toString().hashCode(); 
    }

    public boolean occurs (Variable v) {
	return (v instanceof Dollar && equals(v));
    }

    public Object fill (Substitution sub) throws UnifyFailure {
	Object value = sub.getValue(this);
	if (value == null) {
	    return this;
	} else {
	    return ((ArgStack)value).fill(sub);
	}
    }

    public void unifySlash (Slash s) throws UnifyFailure {
	_slash.unifyCheck(s);
    }
    
    public void unifyCheck (Object u) throws UnifyFailure {}
    
    public Object unify (Object u, Substitution sub)
	throws UnifyFailure {
	if (u instanceof ArgStack && !((ArgStack)u).occurs(this)) {
	    sub.makeSubstitution(this, u);
	    return u;
	} else {
	  throw new UnifyFailure();
	}
	
    }

    public void deepMap (ModFcn mf) {
	mf.modify(this);
    }
    
    public String toString () {
	StringBuffer sb = new StringBuffer();
	sb.append(_slash.toString()).append('$').append(_name).append(_index);
	return sb.toString();
    }
    
}
