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

package opennlp.grok.util;

import opennlp.common.synsem.*;
import opennlp.common.unify.*;
import gnu.trove.*;
import java.util.*;

/**
 * A list that contains categories.
 *
 * @author      Jason Baldridge
 * @version     $Revision$, $Date$
 *
 */
public class CatList {

    private Category[] _list;
    
    public CatList () {
	_list = new Category[0];
    }

    public CatList (Category c) {
	_list = new Category[1];
	_list[0] = c;
    }

    public CatList (Category[] list) {
	_list = list;
    }

    public CatList (List cats) {
	_list = new Category[cats.size()];
	int index = 0;
	for (Iterator i=cats.iterator(); i.hasNext();) {
	    _list[index++] = (Category)i.next();
	}
    }
    
    public Category get (int i) {
	return _list[i];
    }

    public void set (int i, Category c) {
	_list[i] = c;
    }

    public Category getLast () {
	return _list[_list.length-1];
    }
    
    public void add (Category c) {
	Category[] $list = new Category[_list.length+1];
	int last = insert(_list, $list, 0);
	$list[last] = c;
	_list = $list;
    }

    public void add (CatList cl) {
	Category[] $list = new Category[_list.length+cl._list.length];
	int last = insert(_list, $list, 0);
	insert(cl._list, $list, last);
	_list = $list;
    }

    public void addFront (Category c) {
	Category[] $list = new Category[_list.length+1];
	$list[0] = c;
	insert(_list, $list, 1);
	_list = $list;
    }

    public int size () {
	return _list.length;
    }
    
    public CatList copy () {
	Category[] $list = new Category[_list.length];
	for (int i=0; i<$list.length; i++) {
	    $list[i] = _list[i].copy();
	}
	return new CatList($list);
    }

    public CatList copyWithout (int indexToRemove) {
	Category[] $list = new Category[_list.length-1];
	int index = 0;
	for (int i=0; i<_list.length; i++) {
	    if (i  != indexToRemove) {
		$list[index++] = _list[i].copy();
	    }
	}
	return new CatList($list);
    }

    public CatList subList (int from) {
	return subList(from, _list.length);
    }
    
    public CatList subList (int from, int upto) {
	Category[] $list = new Category[upto-from];
	int index = 0;
	for (int i=from; i<upto; i++) {
	    $list[index++] = _list[i];
	}
	return new CatList($list);
    }

    public boolean occurs(Variable v) {
	for (int i=0; i<_list.length; i++) {
	    if (_list[i].occurs(v)) {
		return true;
	    }
	}
	return false;
    }
    
    public CatList fill (Substitution s) throws UnifyFailure {
	Category[] $list = new Category[_list.length];
	for (int i=0; i<_list.length; i++) {
	    $list[i] = (Category)_list[i].fill(s);
	}
	return new CatList($list);
    }
    
    public void deepMap (ModFcn mf) {
	for (int i=0; i<_list.length; i++) {
	    _list[i].deepMap(mf);
	}
    }
    
    public String toString () {
	StringBuffer sb = new StringBuffer(10);
	sb.append(_list[0].toString());
	for (int i=1; i<_list.length; i++) {
	    sb.append(',').append(_list[i].toString());
	}
	return sb.toString();
    }

    private static int insert (Category[] a, Category[] b, int pos) {
	for (int i=0; i<a.length; i++) {
	    b[pos++] = a[i];
	}
	return pos;
    }
    

}
