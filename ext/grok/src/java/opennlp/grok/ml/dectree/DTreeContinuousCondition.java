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

/**
 * A query asked by a decion tree that has specifically to do with the
 * value of a continuous (double) value in relation to a literal.
 *
 * @author      Gann Bierner
 * @version $Revision$, $Date$
 */
public class DTreeContinuousCondition implements DTreeCondition {

    private String feature;
    private String op;
    private Double val;

    private boolean equals=false;
    private boolean less=false;
    private boolean greater=false;
    
    public DTreeContinuousCondition(String f, String o, Double v) {
	feature = f; op = o; val = v;

	if(op.equals("=") || op.equals(">=") || op.equals("<="))
	    equals=true;
	if(op.equals("<") || op.equals("<="))
	    less=true;
	if(op.equals(">") || op.equals(">="))
	    greater=true;
    }
    
    public boolean eval(Map querier) {
	Double testval = (Double)querier.get(feature);
	int compare = testval.compareTo(val);
	return ((compare==0 && equals) ||
		(compare<0 && less) ||
		(compare>0 && greater));
    }
}
