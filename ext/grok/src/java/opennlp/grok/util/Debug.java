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

import java.util.*;

/**
 * Debugging aid
 *
 * @author      Gann Bierner
 * @version     $Revision$, $Date$
 */

public class Debug {

    private static HashMap H = new HashMap();
    private static ArrayList listeners = new ArrayList();

    public static void addDebugListener(DebugListener o) {
	listeners.add(o);
    }
    
    public static void Register(String key, boolean val) {
	H.put(key, new Boolean(val));
	for(int i=0; i<listeners.size(); i++)
	    ((DebugListener)listeners.get(i)).debugAction(key);
    }
    
    public static void Toggle(String key) {
	H.put(key, new Boolean(!On(key)));
    }

    public static void Set(String key, boolean b) {
	H.put(key, new Boolean(b));
    }
    
    public static boolean On(String key) {
	return ((Boolean)(H.get(key))).booleanValue();
    }

    public static void out(String o) { System.out.println(o); }

    public static Iterator Keys() { return H.keySet().iterator(); }

}
