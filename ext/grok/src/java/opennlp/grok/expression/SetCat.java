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
public final class SetCat extends AbstractCat {

    private CatList _cats;

    public SetCat (Element el) {
	List info = el.getChildren();
	List cats = new ArrayList();
	//_slashes = new SlashList();
	for (Iterator infoIt = info.iterator(); infoIt.hasNext();) {
	    infoIt.next();
	    //_slashes.add(new Slash((Element)infoIt.next()));
	    cats.add(CatReader.getCat((Element)infoIt.next()));
	}
	_cats = new CatList(cats);
    }

    public SetCat (CatList cats) {
	_cats = cats;
    }

    public int size () {
	return _cats.size();
    }

    public Category get (int index) {
	return _cats.get(index);
    }
    
    public Category copy() {
	return new SetCat(_cats.copy());
    }

    public Category copyWithout (int indexToRemove) {
	if (size() == 2) {
	    if (indexToRemove == 0) {
		return _cats.get(1).copy();
	    } else {
		return _cats.get(0).copy();
	    }
	} else {
	    return new SetCat(_cats.copyWithout(indexToRemove));
	}
    }
    
    public void deepMap (ModFcn mf) {
	mf.modify(this);
	_cats.deepMap(mf);
    }

    public void forall(CategoryFcn f) {
	f.forall(this);
    }
    
    public int indexOf (Category c) throws UnifyFailure {
	int index = -1;
	for (int i=0; i<size() && index<0; i++) {
	    try {
		GUnifier.unify(_cats.get(i), c);
		index = i;
	    } catch (UnifyFailure uf) {}
	}
	if (index<0) {
	    throw new UnifyFailure();
	} else {
	    return index;
	}
    }
    
    public void unifyCheck (Object u) throws UnifyFailure {
	if (u instanceof SetCat) {
	    if (size() == ((SetCat)u).size()) {
		return;
	    }
	    throw new UnifyFailure();
	} else if (!(u instanceof Variable)) {
	    throw new UnifyFailure();
	}
    }

    public Object unify (Object u, Substitution sub) 
	throws UnifyFailure {

	if (u instanceof SetCat && size() == ((SetCat)u).size()) {
	    SetCat sc = (SetCat)u;
	    Category[] $cats = new Category[size()];
	    int index = 0;
	    for (int i=0; i<size(); i++) {
		boolean foundMatch = false;
		for (int j=0; !foundMatch && j<sc.size(); j++) {
		    try {
			$cats[index++] =
			    GUnifier.unify(_cats.get(i), sc._cats.get(j), sub);
			foundMatch = true;
		    } catch (UnifyFailure uf) {}
		}
		if (!foundMatch) {
		    throw new UnifyFailure();
		}
	    }
	    return new SetCat(new CatList($cats));
	} else {
	    throw new UnifyFailure();
	} 
    }

    public boolean occurs(Variable v) {
	return _cats.occurs(v);
    }

    public Object fill (Substitution s) throws UnifyFailure {
	return new SetCat(_cats.fill(s));
    }

    public boolean equals (Object c) {
	return false;
    }

    public String toString() {
	StringBuffer sb = new StringBuffer(10);
	sb.append('{').append(_cats.toString()).append('}');
	return sb.toString();
    }

}


