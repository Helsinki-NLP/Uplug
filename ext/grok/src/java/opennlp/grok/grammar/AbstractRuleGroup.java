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

package opennlp.grok.grammar;

import opennlp.grok.expression.*;
import opennlp.grok.unify.*;
import opennlp.grok.util.*;
import opennlp.common.parse.*;
import opennlp.common.synsem.*;
import opennlp.common.unify.*;
import java.util.*;

/**
 * Implements default behavior for RuleGroups.
 *
 * @author      Gann Bierner
 * @version     $Revision$, $Date$
 */
public abstract class AbstractRuleGroup implements RuleGroup {

    protected List _unaryRules = new ArrayList();
    protected List _binaryRules = new ArrayList();
    protected List _naryRules = new ArrayList();

    public void addRule (Rule r) {
	if (r.arity() == 1) {
	    _unaryRules.add(r);
	} else if (r.arity() == 2) {
	    _binaryRules.add(r);
	} else {
	    _naryRules.add(r);
	}
    }
    
    public List applyRules (Sign[] inputs) {

	AbstractRule.SHOW_DEBUG = Debug.On("Apply Rule");
	
	StringBuffer orthBuf = new StringBuffer();
	for (int i=0; i<inputs.length; i++) {
	    orthBuf.append(inputs[i].getOrthography()).append(' ');
	}
	String orth = orthBuf.toString().trim();

	Category[] cats = new Category[inputs.length];
	for (int i=0; i<cats.length; i++) {
	    cats[i] = inputs[i].getCategory();
	}

	List results = new ArrayList();
	Iterator ruleIt;
	if (cats.length == 1) {
	    ruleIt = _unaryRules.iterator();
	} else if (cats.length == 2) {
	    ruleIt = _binaryRules.iterator();
	} else {
	    ruleIt = _naryRules.iterator();
	}
	for (; ruleIt.hasNext();) {
	    try {
		List ruleResultList = ((Rule)ruleIt.next()).applyRule(cats);
		for (Iterator ruleResultIt=ruleResultList.iterator();
		     ruleResultIt.hasNext();) {
		    Category catResult = (Category)ruleResultIt.next();
		    results.add(new GSign(orth,catResult));
		}
	    } catch (UnifyFailure uf) {}
	}
	return results;
    }
    
}
