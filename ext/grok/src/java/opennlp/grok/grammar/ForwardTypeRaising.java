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

/**
 * Forward type-raising: X => Y/(Y\X)
 *
 * @author  Jason Baldridge
 * @version $Revision$, $Date$
 */
public class ForwardTypeRaising extends AbstractTypeRaisingRule {

    public ForwardTypeRaising (VarCat argVar, VarCat resultVar) {
	super(">T", argVar, resultVar, new Slash('/'), new Slash('\\'));
    }
    
    public String toString() {
	return "X => Y/(Y\\X)";
    }


}

