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

import opennlp.grok.expression.*;
import gnu.trove.*;
import java.util.*;

/**
 * A list that contains categories.
 *
 * @author      Jason Baldridge
 * @version     $Revision$, $Date$
 *
 */
public class SlashList {

    private Slash[] _list;
    
    public SlashList () {
	_list = new Slash[0];
    }

    public SlashList (Slash c) {
	_list = new Slash[1];
	_list[0] = c;
    }

    public SlashList (Slash[] list) {
	_list = list;
    }

    public Slash get (int i) {
	return _list[i];
    }

    public Slash getLast () {
	return _list[_list.length-1];
    }
    
    public void add (Slash c) {
	Slash[] $list = new Slash[_list.length+1];
	int last = insert(_list, $list, 0);
	$list[last] = c;
	_list = $list;
    }

    public void add (SlashList cl) {
	Slash[] $list = new Slash[_list.length+cl._list.length];
	int last = insert(_list, $list, 0);
	insert(cl._list, $list, last);
	_list = $list;
    }


    public void addFront (Slash c) {
	Slash[] $list = new Slash[_list.length+1];
	$list[0] = c;
	insert(_list, $list, 1);
	_list = $list;
    }

    public int size () {
	return _list.length;
    }
    
    public SlashList copy () {
	Slash[] $list = new Slash[_list.length];
	for (int i=0; i<$list.length; i++) {
	    $list[i] = _list[i].copy();
	}
	return new SlashList($list);
    }

    public SlashList subList (int from) {
	return subList(from, _list.length);
    }
    
    public SlashList subList (int from, int upto) {
	Slash[] $list = new Slash[upto-from];
	int index = 0;
	for (int i=from; i<upto; i++) {
	    $list[index++] = _list[i];
	}
	return new SlashList($list);
    }

    public String toString () {
	StringBuffer sb = new StringBuffer();
	for (int i=0; i<_list.length; i++) {
	    sb.append(_list[i].toString()).append(' ');
	}
	return sb.toString().trim();
    }

    private static int insert (Slash[] a, Slash[] b, int pos) {
	for (int i=0; i<a.length; i++) {
	    b[pos++] = a[i];
	}
	return pos;
    }
    

}
