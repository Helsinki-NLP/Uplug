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
 * Type-raising, e.g. X => Y/(Y\X)
 *
 * @author  Jason Baldridge
 * @version $Revision$, $Date$
 */
public abstract class AbstractTypeRaisingRule extends AbstractRule {
    protected Slash _upperSlash;
    protected Slash _embeddedSlash;
    protected VarCat _argVar;
    protected VarCat _resultVar;
    
    protected AbstractTypeRaisingRule (String name,
				       VarCat argVar, VarCat resultVar,
				       Slash upper, Slash embedded) {
	_name = name;
	_argVar = argVar;
	_resultVar = resultVar;
	_upperSlash = upper;
	_embeddedSlash = embedded;
    }

    public int arity () {
	return 1;
    }

    public List applyRule (Category[] inputs) throws UnifyFailure {
	if (inputs.length != 1) {
	    throw new UnifyFailure();
	}
	return apply(inputs[0]);
    }

    
    protected List apply (Category input) throws UnifyFailure {
	_argVar.unify(input, new EmptySubstitution());
	Category result =
	    new CurriedCat(
	      _resultVar,
	      new BasicArg(_upperSlash,
			   new CurriedCat(_resultVar,
					  new BasicArg(_embeddedSlash,
						       input))));

	if (SHOW_DEBUG) System.out.println(_name+":  " + result);

	List results = new ArrayList();
	results.add(result);
	return results;
    }


}

