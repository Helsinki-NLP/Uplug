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

package opennlp.grok.lexicon;

import opennlp.common.util.PerlHelp;

/**
 * Takes a string which is a name and cuts it into Title, First, Last name,
 * etc.  Currently just a dumb hack.
 *
 * @author      Jason Baldridge
 * @version     $Revision$, $Date$
 **/

public class NameChopper {

    public static String segmentName(String name) {
	String[] spaceSplit = PerlHelp.split(name);
	if (spaceSplit.length == 1) return name;
	if (spaceSplit.length ==2)
	    return "^FIRST("+spaceSplit[0]+"),^LAST("+spaceSplit[1]+")";
	return name;
    }

}
