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

package opennlp.grok.datarep;

import java.util.ArrayList;

/**
 * A way of displaying morpholical entries.  
 *
 * @author      Jason Baldridge
 * @version $Revision$, $Date$
 */
public class MorphModel extends ArrayList {

    public void addNew() { addMorphItem(new MorphItem()); }
    public void removeItem(int r) {
	remove(r);
    }

    public MorphItem getItem(int r) { return (MorphItem)get(r); }
    public void addMorphItem(MorphItem re) {
	add(re);
    }
     
}
