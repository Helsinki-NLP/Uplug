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
 * A stack that contains slashes.
 *
 * @author      Jason Baldridge
 * @version     $Revision$, $Date$
 *
 */
public class SlashStack extends TLinkedList {
    
    public SlashStack () {}

    public SlashStack (SlashStack cs) {
	addAll(cs);
    }

    public Slash getHead () {
	return (Slash)_head;
    }

    public Slash getTail () {
	return (Slash)_tail;
    }
    
    public void addHead (Slash c) {
	addFirst(c);
    }

    public void addTail (Slash c) {
	addLast(c);
    }

    public SlashStack copy () {
	SlashStack $cs = new SlashStack();
	for (Iterator i=iterator(); i.hasNext();) {
	    $cs.addTail(((Slash)i.next()).copy());
	}
	return $cs;
    }

    public SlashStack sublistCopy (int upto) {
	SlashStack $cs = new SlashStack();
	for (ListIterator i=listIterator(upto); i.hasPrevious();) {
	    $cs.addHead(((Slash)i.previous()).copy());
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
