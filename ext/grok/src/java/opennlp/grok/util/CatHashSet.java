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
import opennlp.common.synsem.*;
import gnu.trove.THashSet;
import org.jdom.Element;
import java.util.*;

/**
 * A set that contains categories.
 *
 * @author      Jason Baldridge
 * @version     $Revision$, $Date$
 *
 */
public class CatHashSet extends HashSet {

    public CatHashSet () {}

    public CatHashSet (CatHashSet csh) {
	addAll(csh);
    }

    public CatHashSet (List l) {
	for (Iterator i=l.iterator(); i.hasNext();)
	    addCategory(CatReader.getCat((Element)i.next()));
    }

    public void addCategory (Category c) {
	add(c);
    }

    public void addAll (CatHashSet chs) {
	for (Iterator i=chs.iterator(); i.hasNext();)
	    addCategory((Category)i.next());
    }

    public String toString () {
	StringBuffer sb = new StringBuffer();
	for (Iterator i=iterator(); i.hasNext();)
	    sb.append(i.next().toString()).append(' ');
	return sb.toString();
    }
    
}
