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
import gnu.trove.*;
import org.jdom.*;
import java.util.*;

/**
 * A stack of arguments with their associated slashes.
 *
 * @author      Jason Baldridge
 * @version     $Revision$, $Date$
 */
public class ArgStack {

    protected Arg[] _list;

    protected boolean _hasDollar = false;
    
    public ArgStack () {
	_list = new Arg[0];
    }

    public ArgStack (Arg c) {
	_list = new Arg[1];
	_list[0] = c;
    }

    public ArgStack (Slash s, Category c) {
	this(new BasicArg(s,c));
    }

    public ArgStack (Arg[] list) {
	_list = list;
    }

    //public ArgStack (List cats) {
    //	  _list = new Arg[cats.size()];
    //	  int index = 0;
    //	  for (Iterator i=cats.iterator(); i.hasNext();) {
    //	      _list[index++] = (Arg)i.next();
    //	  }
    //}

    public ArgStack (List info) {
	List args = new ArrayList();
	for (Iterator infoIt = info.iterator(); infoIt.hasNext();) {
	    Slash s = new Slash((Element)infoIt.next());
	    Element a = (Element)infoIt.next();
	    if (a.getName().equals("dollar")) {
		args.add(new Dollar(s, a));
		_hasDollar = true;
	    } else {
		args.add(new BasicArg(s, CatReader.getCat(a)));
	    }
	}
	_list = new Arg[args.size()];
	args.toArray(_list);
    }


    public void add (Arg c) {
	Arg[] $list = new Arg[_list.length+1];
	int last = insert(_list, $list, 0);
	$list[last] = c;
	_list = $list;
    }

    public void add (ArgStack cl) {
	Arg[] $list = new Arg[_list.length+cl._list.length];
	int last = insert(_list, $list, 0);
	insert(cl._list, $list, last);
	_list = $list;
    }

    public void addFront (Arg c) {
	Arg[] $list = new Arg[_list.length+1];
	$list[0] = c;
	insert(_list, $list, 1);
	_list = $list;
    }

    public int size () {
	return _list.length;
    }
    

    public boolean containsDollarArg () {
	return _hasDollar;
    }
    
    public Arg get (int i) {
	return _list[i];
    }

    public void set (int i, Arg c) {
	_list[i] = c;
    }

    public Arg getLast () {
	return _list[_list.length-1];
    }
    

    public void setLast (Arg c) {
	_list[_list.length-1] = c;
    }


    public ArgStack copy () {
	Arg[] $list = new Arg[_list.length];
	for (int i=0; i<$list.length; i++) {
	    $list[i] = _list[i].copy();
	}
	return new ArgStack($list);
    }

    public ArgStack copyWithout (int indexToRemove) {
	Arg[] $list = new Arg[_list.length-1];
	if ($list.length < 1) {
	    System.out.println("Removing last item from an argument stack!");
	}
	int index = 0;
	for (int i=0; i<_list.length; i++) {
	    if (i != indexToRemove) {
		$list[index++] = _list[i].copy();
	    }
	}
	return new ArgStack($list);
    }

    public ArgStack subList (int from) {
	return subList(from, _list.length);
    }
    
    public ArgStack subList (int from, int upto) {
	Arg[] $list = new Arg[upto-from];
	int index = 0;
	for (int i=from; i<upto; i++) {
	    $list[index++] = _list[i];
	}
	return new ArgStack($list);
    }

    
    public ArgStack shallowCopy () {
	return new ArgStack(_list);
    }


    public boolean occurs(Variable v) {
	for (int i=0; i<_list.length; i++) {
	    if (_list[i].occurs(v)) {
		return true;
	    }
	}
	return false;
    }
    
    public ArgStack fill (Substitution s) throws UnifyFailure {
	ArgStack args = new ArgStack();
	for (int i=0; i<_list.length; i++) {
	    Object value =  _list[i].fill(s);
	    if (value instanceof ArgStack) {
		args.add((ArgStack)value);
	    } else {
		args.add((Arg)value);
	    }
	}
	return args;
    }
    
    public void deepMap (ModFcn mf) {
	for (int i=0; i<_list.length; i++) {
	    _list[i].deepMap(mf);
	}
    }


    public int unifySuffix (ArgStack as, Substitution sub)
	throws UnifyFailure {
	
	int asIndex = as.size();
	for (int i=_list.length-1; i>=0; i--) {
	    asIndex--;
	    get(i).unify(as.get(asIndex), sub);
	}
	return asIndex;
    }

    public void unify (ArgStack as, Substitution sub)
	throws UnifyFailure {
	
	int asIndex = as.size();
	for (int i=_list.length-1; i>=0; i--) {
	    Arg argi = get(i);
	    if (argi instanceof Dollar) {
		if (i>0) {
		    throw new UnifyFailure();
		} else {
		    Slash dsl = ((Dollar)argi).getSlash();
		    for (int j=0; j<asIndex; j++) {
			as.get(j).unifySlash(dsl);
		    }
		    sub.makeSubstitution((Dollar)argi, as.subList(0,asIndex));
		}
	    } else {
		get(i).unify(as.get(--asIndex), sub);
	    }
	}
    }
	
    public String toString() {
	StringBuffer sb = new StringBuffer();
	for (int i=0; i<_list.length; i++) {
	    sb.append(_list[i].toString());
	}
	return sb.toString();
    }


    protected static int insert (Arg[] a, Arg[] b, int pos) {
	for (int i=0; i<a.length; i++) {
	    b[pos++] = a[i];
	}
	return pos;
    }
    

}
