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

package opennlp.grok.grammar;

import opennlp.grok.unify.*;
import opennlp.grok.util.*;
import opennlp.grok.expression.*;

import opennlp.common.parse.*;
import opennlp.common.synsem.*;
import opennlp.common.unify.*;

import java.util.*;

/**
 * Implements some default behavior for Rule objects.
 *
 * @author  Jason Baldridge
 * @version $Revision$, $Date$
 */
public abstract class AbstractRule implements Rule {
    protected String _name;

    public abstract List applyRule (Category[] inputs) throws UnifyFailure;
    public abstract String toString();

    protected void showApplyInstance (Category[] inputs) {
	StringBuffer sb = new StringBuffer();  
	sb.append(_name).append(": ");
	
	for (int i=0; i<inputs.length; i++) {
	    sb.append(inputs[i]).append(' ');
	}

	System.out.println(sb);
    }

    protected void showApplyInstance (Category first, Category second) {
	Category[] ca = {first,second};
	showApplyInstance(ca);
    }
    
    // Debugging flag
    public static boolean SHOW_DEBUG = false;
    
    /**
     * An integer used to help keep variables unique in rules.
     */
    protected static int _UNIQUE = 0;

    /**
     * A category function that makes variables unique.
     */
    protected static ModFcn _UNIQUE_FCN = new ModFcn() {
	public void modify (Mutable m) {
	    if (m instanceof Indexed) {
		((Indexed)m).setIndex(_UNIQUE);
	    }
	}};

    public static final FSCondenser CONDENSER = new FSCondenser();

    static {
      Debug.Register("Apply Rule", false);
      Debug.Register("Apply Rev Rule", false);
    }



}

