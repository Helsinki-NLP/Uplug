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
 * A category which contains an unordered set of categories.
 *
 * @author      Jason Baldridge
 * @version     $Revision$, $Date$
 */
public final class SetArg implements Arg {

    private ArgStack _args;
    
    public SetArg (Element el) {
	List info = el.getChildren();
	List args = new ArrayList();
	for (Iterator infoIt = info.iterator(); infoIt.hasNext();) {
	    Slash s = new Slash((Element)infoIt.next());
	    Category c = CatReader.getCat((Element)infoIt.next());
	    args.add(new BasicArg(s, c));
	}
	Arg[] list = new Arg[args.size()];
	args.toArray(list);
	_args = new ArgStack(list);
    }

    public SetArg (Arg[] args) {
	_args = new ArgStack(args);
    }

    public SetArg (ArgStack args) {
	_args = args;
    }

    public Arg copy () {
	return new SetArg(_args.copy());
    }

    public SetArg copyWithout (int pos) {
	return new SetArg(_args.copyWithout(pos));
    }

    public Arg get (int pos) {
	return _args.get(pos);
    }

    public Category getCat (int pos) {
	return ((BasicArg)_args.get(pos)).getCat();
    }
    
    public int indexOf (Category cat) throws UnifyFailure {
	int index = -1;
	for (int i=0; i<_args.size() && index<0; i++) {
	    try {
		GUnifier.unify(getCat(i), cat);
		index = i;
	    } catch (UnifyFailure uf) {}
	}
	if (index<0) {
	    throw new UnifyFailure();
	} else {
	    return index;
	}
    }
    
    public void unifySlash (Slash s) throws UnifyFailure {
	for (int i=0; i<_args.size(); i++) {
	    _args.get(i).unifySlash(s);
	}
    }
    
    public void unifyCheck (Object u) throws UnifyFailure {
    }

    public Object unify (Object u, Substitution sub) 
	throws UnifyFailure {

//	  if (u instanceof SetArg && size() == ((SetArg)u).size()) {
//	      SetCat sc = (SetArg)u;
//	      Category[] $args = new Category[size()];
//	      int index = 0;
//	      for (int i=0; i<size(); i++) {
//		  boolean foundMatch = false;
//		  for (int j=0; !foundMatch && j<sc.size(); j++) {
//		      try {
//			  $args[index++] =
//			      GUnifier.unify(_args.get(i), sc._args.get(j), sub);
//			  foundMatch = true;
//		      } catch (UnifyFailure uf) {}
//		  }
//		  if (!foundMatch) {
//		      throw new UnifyFailure();
//		  }
//	      }
//	      return new SetCat(new CatList($args));
//	  } else {
//	      throw new UnifyFailure();
//	  }
	return copy();
    }


    public Object fill (Substitution s) throws UnifyFailure {
	return new SetArg(_args.fill(s));
    }

    public void deepMap (ModFcn mf) {
	_args.deepMap(mf);
    }

    public boolean occurs (Variable v) {
	return _args.occurs(v);
    }
    
    public boolean equals (Object c) {
	return false;
    }

    public String toString() {
	StringBuffer sb = new StringBuffer(10);
	sb.append('{').append(_args.toString()).append('}');
	return sb.toString();
    }

}


