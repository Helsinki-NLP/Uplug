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
package opennlp.grok.unify;

import opennlp.common.unify.*;

/**
 * A Substitution which does not hold any substitutions.
 *
 * @author      Jason Baldridge
 * @version $Revision$, $Date$
 **/
public class EmptySubstitution implements Substitution {

    public Object makeSubstitution (Variable var, Object u) 
	throws UnifyFailure {
	return u;
    }

    public Object getValue (Variable var) {
	return null;
    }

    public java.util.Iterator varIterator () {
	return null;
    }
    
}
