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
 * A basic argument that contains a slash and a category.
 *
 * @author      Jason Baldridge
 * @version     $Revision$, $Date$
 */
public final class BasicArg implements Arg {

    private final Slash _slash;
    private final Category _cat;

    public BasicArg (Slash s, Category c) {
	_slash = s;
	_cat = c;
    }

    public Arg copy () {
	return new BasicArg(_slash.copy(), _cat.copy());
    }
    
    public Slash getSlash () {
	return _slash;
    }

    public Category getCat () {
	return _cat;
    }
	
    
    public boolean occurs (Variable v) {
	return _cat.occurs(v);
    }

    public Object fill (Substitution sub) throws UnifyFailure {
	return new BasicArg ((Slash)_slash.fill(sub), (Category)_cat.fill(sub));
    }

    public void unifySlash (Slash s) throws UnifyFailure {
	_slash.unifyCheck(s);
    }
    
    public void unifyCheck (Object u) throws UnifyFailure {}
    
    public Object unify (Object u, Substitution sub)
	throws UnifyFailure {
	if (u instanceof BasicArg) {
	    return new BasicArg((Slash)_slash.unify(((BasicArg)u)._slash, sub),
				(Category)_cat.unify(((BasicArg)u)._cat, sub));
	} else {
	  throw new UnifyFailure();
	}
	
    }

    public void deepMap (ModFcn mf) {
	_cat.deepMap(mf);
    }
    
    public String toString () {
	StringBuffer sb = new StringBuffer();
	sb.append(_slash.toString());
	if (_cat instanceof CurriedCat) {
	    sb.append('(').append(_cat).append(')');
	} else {
	    sb.append(_cat);
	}
	return sb.toString();
    }
    
}
