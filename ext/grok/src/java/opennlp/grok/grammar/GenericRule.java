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

import opennlp.grok.lexicon.*;
import opennlp.grok.unify.*;
import opennlp.grok.util.*;
import opennlp.grok.expression.*;

import opennlp.common.parse.*;
import opennlp.common.synsem.*;
import opennlp.common.unify.*;

import gnu.trove.*;
import java.util.*;

/**
 * The representation of a CCG rule.  The rule itself is * represented as an
 * array, with the result category as the last element. For example, the
 * function application rule will produce the array [ X/Y , Y , X ] for cats.
 *
 * @author      Gann Bierner
 * @version $Revision$, $Date$
 **/

public class GenericRule extends AbstractRule {

    /**
     * An array of the categories which define this rule.
     */   
    protected Category[] _arguments;

    protected Category _result;

    public GenericRule (Category[] args, Category result, String n) {
	_name = n;
	_arguments = args;
	_result = result;
    }
    
    public int arity() { 
	return _arguments.length; 
    }


    public List applyRule (Category[] inputs) throws UnifyFailure {
	if (inputs.length != _arguments.length) {
	    throw new UnifyFailure();
	}

	boolean showDebug = Debug.On("Apply Rule");

	//// make variables (relatively) unique
	for (int i=0; i < _arguments.length; i++) {
	    _arguments[i].deepMap(_UNIQUE_FCN);
	}
	_result.deepMap(_UNIQUE_FCN);

	_UNIQUE++;

	if (showDebug) {              
	    StringBuffer sb = new StringBuffer();  
	    sb.append(_name).append(": ");          
	    for (int i=0; i<inputs.length; i++)     
		sb.append(inputs[i]).append(' ');   	 
	    sb.append("\n   ").append("Rule cats: ");            
	    for (int i=0; i<inputs.length; i++)     
		sb.append(_arguments[i]).append(' ');    
	    sb.append("=> ").append(_result);
	    sb.append("\n   ").append("Word cats: ");	           	 
	    for (int i=0; i<inputs.length; i++)     	 
		sb.append(inputs[i]).append(' ');
	    System.out.println(sb);                
	}                                          

	Substitution sub = new SelfCondensingSub();

	//for (int i=0; i<_arguments.length; i++) {
	//    _arguments[i].unifyCheck(inputs[i]);
	//}

	for (int i=0; i<_arguments.length; i++) {
	    GUnifier.unify(inputs[i], _arguments[i], sub);
	}

	if (showDebug)
	    System.out.println("Syn unify: " + sub);

	CONDENSER.condense(sub);
	
	Category $result = (Category)_result.fill(sub);
	
	if (showDebug)
	    System.out.println("Result: " + $result);
	
	List results = new ArrayList();
	results.add($result);
	return results;
    }


    public String toString() {
	StringBuffer sb = new StringBuffer();
	sb.append(_name).append(": ");
	for (int i=0; i<_arguments.length; i++) {
	    sb.append(_arguments[i]).append(' ');
	}
	sb.append("=> ").append(_result);
	return sb.toString();
    }

}

