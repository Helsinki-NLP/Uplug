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
 * A non-recursive representation of curried categories.
 *
 * @author      Jason Baldridge
 * @version     $Revision$, $Date$
 */
public final class CurriedCat extends AbstractCat {

    private TargetCat _target;
    private ArgStack _args;

    public CurriedCat (TargetCat target, ArgStack args) {
	_target = target;
	if (args.size() < 1) {
	    System.out.println("WARNING!!! Creating a CurriedCat with"
			       + " empty argument stack!");
	}
	_args = args;
    }

    public CurriedCat (TargetCat target, Arg arg) {
	_target = target;
	_args = new ArgStack(arg);
    }

    public CurriedCat (Element el) {
	List info = el.getChildren();
	_target = (TargetCat)CatReader.getCat((Element)info.get(0));
	_args = new ArgStack(info.subList(1, info.size()));
    }
    
    public TargetCat getTarget () {
	return _target;
    }

    public Arg getArg (int pos) {
	return _args.get(pos);
    }

    public Arg getOuterArg () {
	return _args.getLast();
    }

    public Category getResult () {
	return getSubResult(arity()-1);
    }

    public Category getSubResult (int upto) {
	if (upto == 0) {
	    return _target;
	} else {
	    return new CurriedCat(_target, _args.subList(0, upto));
	}
    }

    public ArgStack getArgStack () {
	return _args;
    }

    public ArgStack getArgStack (int from) {
	return _args.subList(from);
    }
    
    public void add (Arg a) {
	_args.add(a);
    }

    public void add (ArgStack as) {
	_args.add(as);
    }

    public void set (int index, Arg c) {
	_args.set(index, c);
    }

    public void setOuterArgument (Arg c) {
	_args.setLast(c);
    }
    
    public int arity () {
	return _args.size();
    }
    
    public Category copy() {
	return new CurriedCat((TargetCat)_target.copy(), _args.copy());
    }

    public Category shallowCopy() {
	return new CurriedCat(_target, _args);
    }

    public void deepMap (ModFcn mf) {
	mf.modify(this);
	_target.deepMap(mf);
	_args.deepMap(mf);
    }

    public void forall(CategoryFcn f) {
	f.forall(this);
	_target.forall(f);
	//for (int i=0; i<_args.length; i++) {
	//    _args[i].forall(f);
	//}
    }

    public void unifyCheck (Object u) throws UnifyFailure {
	//if (u instanceof CurriedCat) {
	//    CurriedCat sc = (CurriedCat)u;
	//    for (int i=0; i<_args.length; i++) {
	//	  _args[i].unifyCheck(sc._args[i]);
	//    }
	//} else if (!(u instanceof Variable)) {
	//    throw new UnifyFailure();
	//}
    }

    public Object unify (Object u, Substitution sub) 
	throws UnifyFailure {

	if (u instanceof CurriedCat) {
	    CurriedCat cc = (CurriedCat)u;
	    if (arity() > cc.arity()) {
		return cc.unify(this, sub);
	    }
	    if (cc._args.containsDollarArg()) {
		cc._args.unify(_args, sub);
	    } else {
		_args.unify(cc._args, sub);
	    }
		//int matchedUpto = _args.unifySuffix(cc._args, sub);
		//if (matchedUpto > 0) {
		//    System.out.println("Failed.");
		//    throw new UnifyFailure();
		//}
	    GUnifier.unify(_target, cc._target, sub);
	    return copy();
	} else {
	    throw new UnifyFailure();
	} 
    }

    public boolean occurs(Variable v) {
	return _target.occurs(v) || _args.occurs(v);
    }

    public Object fill (Substitution s) throws UnifyFailure {
	Category $target = (Category)_target.fill(s);
	if ($target instanceof TargetCat) {
	    return new CurriedCat((TargetCat)$target, _args.fill(s));
	} else if ($target instanceof CurriedCat) {
	    ((CurriedCat)$target).add(_args.fill(s));
	    return $target;
	} else {
	    throw new UnifyFailure();
	}
    }

    public boolean equals(Object c) {
	return false;
    }

    public String toString() {
	StringBuffer sb = new StringBuffer();
	sb.append(_target.toString()).append(_args.toString());
	return sb.toString();
    }

}


