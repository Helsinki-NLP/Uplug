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

import opennlp.common.synsem.*;
import opennlp.common.unify.*;

import java.util.*;

/**
 * Super class for application rules.
 *
 * @author  Jason Baldridge
 * @version $Revision$, $Date$
 */
public abstract class AbstractApplicationRule extends AbstractRule {
    protected Slash _functorSlash;

    public int arity () {
	return 2;
    }
    
    protected List apply (Category xyCat, Category yCat)
	throws UnifyFailure {

	if (xyCat instanceof CurriedCat) {
	    CurriedCat xyCurCat = (CurriedCat)xyCat;
	    Arg xyOuter = xyCurCat.getOuterArg();
	    xyOuter.unifySlash(_functorSlash);
	    Substitution sub = new SelfCondensingSub();
	    Category result;
	    
	    if (xyOuter instanceof BasicArg) {
		Category xyOuterCat = ((BasicArg)xyOuter).getCat();
		GUnifier.unify(xyOuterCat, yCat, sub);
		result = xyCurCat.getResult();
	    } else if (xyOuter instanceof SetArg) {
		SetArg xyOuterSet = (SetArg)xyOuter;
		int targetIndex = xyOuterSet.indexOf(yCat);
		GUnifier.unify(xyOuterSet.getCat(targetIndex), yCat, sub);
		result = xyCurCat.copy();
		((CurriedCat)result).setOuterArgument(xyOuterSet.copyWithout(targetIndex));
	    } else {
		throw new UnifyFailure();
	    }

	    //if (SHOW_DEBUG) System.out.println(_name + ":  Syn unify: " + sub);
		
	    result = (Category)result.fill(sub);
	    
	    if (SHOW_DEBUG) System.out.println(_name+":  " + result);
	    
	    List results = new ArrayList();
	    results.add(result);
	    return results;
	} else {
	    throw new UnifyFailure();
	}

    }

}

