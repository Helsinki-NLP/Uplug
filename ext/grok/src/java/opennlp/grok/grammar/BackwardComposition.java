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
 * Backward composition, e.g. Y\Z X\Y => X\Z
 *
 * @author  Jason Baldridge
 * @version $Revision$, $Date$
 */
public class BackwardComposition extends AbstractCompositionRule {

    public BackwardComposition () {
	this(true);
    }
    
    public BackwardComposition (boolean isHarmonic) {
	_functorSlash = new Slash('\\');
	if (isHarmonic) {
	    _name = "<B";
	    _argSlash = new Slash('\\');
	} else {
	    _name = "<Bx";
	    _argSlash = new Slash('/');
	}
    }
    
    public List applyRule (Category[] inputs) throws UnifyFailure {
	if (inputs.length != 2) {
	    throw new UnifyFailure();
	}

	return apply(inputs[1], inputs[0]);
    }


    public String toString() {
	StringBuffer sb = new StringBuffer();
	sb.append("Y").append(_argSlash.toString()).append("Z ").append("X\\Y => X").append(_argSlash.toString()).append("Z");
	return sb.toString();
    }


}

