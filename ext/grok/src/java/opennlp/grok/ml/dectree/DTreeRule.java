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

package opennlp.grok.ml.dectree;

import java.util.*;
import java.io.*;

/**
 * A rule in a desicion tree.  It can require any number of conditions which
 * are conjoined.
 *
 * @author      Gann Bierner
 * @version $Revision$, $Date$
 */
public class DTreeRule implements Serializable {

    private Object result;
    private List conditions;

    public DTreeRule(Object r, List c) { result=r; conditions=c; }

    public void addCondition(DTreeCondition cond) {
	if(conditions==null) conditions = new ArrayList();
	conditions.add(cond);
    }

    public Object getResult() { return result; }
    
    public boolean eval(Map querier) {
	if(conditions!=null) {
	    for(Iterator condsI=conditions.iterator(); condsI.hasNext();) {
		DTreeCondition cond = (DTreeCondition)condsI.next();
		if(!cond.eval(querier))
		    return false;
	    }
	}
	return true;
    }

}
