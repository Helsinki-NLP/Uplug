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
 * Super class for composition rules.
 *
 * @author  Jason Baldridge
 * @version $Revision$, $Date$
 */
public abstract class AbstractCompositionRule extends AbstractApplicationRule {
    protected Slash _argSlash;

    protected List apply (Category xyCat, Category yzCat)
	throws UnifyFailure {
	
	if (xyCat instanceof CurriedCat && yzCat instanceof CurriedCat) {

	    CurriedCat xyCurCat = (CurriedCat)xyCat;
	    CurriedCat yzCurCat = (CurriedCat)yzCat;
	    Arg xyOuter = xyCurCat.getOuterArg();
	    xyOuter.unifySlash(_functorSlash);

	    Substitution sub = new SelfCondensingSub();
	    Category result;
	    ArgStack zStack;

	    if (xyOuter instanceof BasicArg) {
		Category xyOuterCat = ((BasicArg)xyOuter).getCat();
		if (xyOuterCat instanceof AtomCat) {
		    // e.g. s/s Y/Z
		    Arg yzInner = yzCurCat.getArg(0);
		    yzInner.unifySlash(_argSlash);
		    Category yzTarget = yzCurCat.getTarget();
		    GUnifier.unify(xyOuterCat, yzTarget, sub);		 
		    result = xyCurCat.getResult();
		    zStack = yzCurCat.getArgStack();
		} else if (xyOuterCat instanceof CurriedCat) {
		    // e.g. s/(s/n) Y/Z
		    if (((CurriedCat)xyOuterCat).arity() > 1) {
			throw new UnifyFailure();
		    }
		    GUnifier.unify(((CurriedCat)xyOuterCat).getTarget(),
				   yzCurCat.getTarget(),
				   sub);
		    //ArgStack xyStackOfOuter =
		    //	  ((CurriedCat)xyOuterCat).getArgStack();
		    ArgStack yzStack = yzCurCat.getArgStack();
		    Arg xyOuterOuter = ((CurriedCat)xyOuterCat).getArg(0);
		    //Slash slashOfOuter = ((CurriedCat)xyOuterCat).getOuterSlash();
		    Arg yzStackInner = yzStack.get(0);
		    if (yzStackInner instanceof SetArg) {
			throw new UnifyFailure();
			// e.g. s/(s/n) s/{s,n}
			//GUnifier.unify(((CurriedCat)xyOuterCat).getTarget(),
			//	     yzCurCat.getTarget(),
			//	     sub);
			//SetCat aoa_sc = (SetCat)yzStackInner;
			//int iaIndex = aoa_sc.indexOf(outerOfOuter);
			//GUnifier.unify(aoa_sc.get(iaIndex), outerOfOuter, sub);
			//zStack = yzStack.copy();
			//zStack.set(0, aoa_sc.copyWithout(iaIndex));
		    } else {
			// e.g. s/(s/n) s/n/s
			if (yzStack.size() < 2) {
			    throw new UnifyFailure();
			}
			xyOuterOuter.unify(yzStackInner, sub);
			zStack = yzStack.subList(1).copy();
		    }
		    result = xyCurCat.getResult();
		} else {
		    throw new UnifyFailure();
		}
		
	    } else if (xyOuter instanceof SetArg) {
		// e.g. s/{s,n} Y/Z
		Category yzTarget = yzCurCat.getTarget();
		SetArg xyOuterSet = (SetArg)xyOuter;
		int targetIndex = xyOuterSet.indexOf(yzTarget);
		GUnifier.unify(xyOuterSet.getCat(targetIndex), yzTarget, sub);
		result = xyCurCat.copy();
		((CurriedCat)result).setOuterArgument(xyOuterSet.copyWithout(targetIndex));
		zStack = yzCurCat.getArgStack();
	    } else {
		throw new UnifyFailure();
	    }

	    //the dog that Calvin likes devours cats
	    //Category $outer = yzCurCat.getOuterArgument();
	    
	    //if (SHOW_DEBUG) System.out.println(_name + "      Syn unify: " + sub);
	     
	    result = (Category)result.fill(sub);
	    if (result instanceof CurriedCat) {
		((CurriedCat)result).add(zStack.fill(sub));
	    } else {
		result = new CurriedCat((TargetCat)result, zStack.fill(sub));
	    }
	    
	    if (SHOW_DEBUG) System.out.println(_name + ":  " + result);
	    
	    List results = new ArrayList();
	    results.add(result);
	    return results;
	} else {
	    throw new UnifyFailure();
	}

    }


    
}

