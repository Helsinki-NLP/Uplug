///////////////////////////////////////////////////////////////////////////////
// Copyright (C) 2002 Jason Baldridge and Gann Bierner
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

import opennlp.grok.util.Params;
import opennlp.common.synsem.*;
import gnu.trove.*;
import java.util.*;

/**
 * A set of signs.
 *
 * @author      Gann Bierner and Jason Baldridge
 * @version     $Revision$, $Date$
 */
public class SignHash extends THashMap {

    static {
	Params.register("Results:All Derivs", "false");
    }

    private static int UNIQUE = 0;
    private int num=0;
    
    /** Class constructor */
    public SignHash () {
	num=UNIQUE++;
    }


    /**
     * Class constructor: takes a word to start off with
     *
     * @param w the first word in the set.
     */
    public SignHash (Sign sign) {
	insert(sign);
	num=UNIQUE++;
    }


    /**
     * Class constructor: takes a collection to start off with
     *
     * @param c a collection of Signs
     */
    public SignHash (Collection c) {
	for (Iterator i = c.iterator(); i.hasNext();) {
	    insert((Sign)i.next());
	}
	num=UNIQUE++;
    }

    
    /**
     * puts a new Sign into the set.
     *
     * @param sign the Sign to add
     */
    public void insert(Sign sign) {
	if (Params.getBoolean("Results:All Derivs"))
	    put(Integer.toString(UNIQUE++), sign);
	else {
	    put(sign.getCategory().hashString(), sign);
	}
    }

    public void replace(String n, String o) {}

    public String toString () {
	StringBuffer sb = new StringBuffer();
	for (Iterator i=keySet().iterator(); i.hasNext();) {
	    String key = (String)i.next();
	    sb.append(key).append(" --> ").append(((Sign)get(key)).toString()).append('\n');
	}
	return sb.toString();
    }

}
