///////////////////////////////////////////////////////////////////////////////
// Copyright (C) 2000 Jason Baldridge and Gann Bierner
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

import gnu.trove.*;
import java.util.*;

/**
 * A map where putting a value does not replace an old value but is rather
 * included in a group of values for that one key.
 *
 * @author      Gann Bierner
 * @version     $Revision$, $Date$
 *
 */
public class GroupMap extends THashMap {
    public Object put (Object key, Object value) {
	Set val = (THashSet)get(key);
	if(val==null) {
	    val = new THashSet();
	    val.add(value);
	    super.put(key, val); 
	} else
	    val.add(value);
	return val;
    }

    public Object putAll (Object key, Collection vals) {
	for(Iterator I = vals.iterator(); I.hasNext();)
	    put(key, I.next());
	return get(key);
    }

    // maybe a weird semantics for get, but worth a shot.
    public Object get (Object key) {
	Object ans = super.get(key);
	if(ans==null) {
	    Set val = new THashSet();
	    super.put(key, val);
	    return val;
	}
	else return ans;
    }
}
