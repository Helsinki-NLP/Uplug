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
import gnu.trove.*;
import java.util.*;

/**
 * A stack that contains categories.
 *
 * @author      Jason Baldridge
 * @version     $Revision$, $Date$
 *
 */
public class CatStack extends TLinkedList {
    
    public CatStack () {}

    public CatStack (CatStack cs) {
	addAll(cs);
    }

    public Category getHead () {
	return (Category)_head;
    }

    public Category getTail () {
	return (Category)_tail;
    }
    
    public void addHead (Category c) {
	addFirst(c);
    }

    public void addTail (Category c) {
	addLast(c);
    }

    public CatStack copy () {
	CatStack $cs = new CatStack();
	for (Iterator i=iterator(); i.hasNext();) {
	    $cs.addTail(((Category)i.next()).copy());
	}
	return $cs;
    }

    public CatStack sublistCopy (int upto) {
	CatStack $cs = new CatStack();
	for (ListIterator i=listIterator(upto); i.hasPrevious();) {
	    $cs.addHead(((Category)i.previous()).copy());
	}
	return $cs;
    }

    public String toString () {
	StringBuffer sb = new StringBuffer();
	for (Iterator i=iterator(); i.hasNext();) {
	    sb.append(i.next().toString()).append(' ');
	}
	return sb.toString().trim();
    }
    
}
