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

package opennlp.grok.expression;

import opennlp.common.unify.*;
import gnu.trove.*;
import org.jdom.Element;

/**
 * A mode that can decorate a categorial slash.
 *
 * @author      Jason Baldridge
 * @version     $Revision$, $Date$
 */
public final class SlashMode extends TLinkableAdaptor {

    public static final byte All = 0;
    public static final byte ApplicationOnly = 1;
    public static final byte Associative = 2;
    public static final byte Crossing = 3;
    public static final byte CrossingAndAssociative = 4;

    private byte _mode;

    public SlashMode (Element el) {
	String m = el.getAttributeValue("m");
	if (m == null) {
	    m = "o";
	}
	
	init(m.charAt(0));
    }

    public SlashMode () {
	this('o');
    }

    public SlashMode (char m) {
	init(m);
    }

    private SlashMode (byte m) {
	_mode = m;
    }

    public SlashMode copy () {
	return new SlashMode(_mode);
    }


    private void init (char m) {
	switch (m) {
	case 'o': _mode = All; break;
	case '*': _mode = ApplicationOnly; break;
	case '^': _mode = Associative; break;
	case 'x': _mode = Crossing; break;
	case '%': _mode = CrossingAndAssociative; break;
	default: _mode = Associative;
	}
    }

    public boolean equals (SlashMode m) {	
	return modesMatch(_mode, m._mode);
    }

    public void unifyCheck (SlashMode m) throws UnifyFailure {
	if (!modesMatch(_mode, m._mode)) {
	    throw new UnifyFailure();
	}
    }
    
    private static boolean modesMatch(byte m1, byte m2) {
	if (m1 == All || m2 == All) return true;
	if (m1 == CrossingAndAssociative && m2 != ApplicationOnly)
	    return true; 
	if (m2 == CrossingAndAssociative && m1 != ApplicationOnly)
	    return true;
	return m1 == m2;
    }	
    
    public String toString() {
	switch (_mode) {
	case All                    : return "o";
	case ApplicationOnly        : return "*";
	case Associative            : return "^";
	case Crossing               : return "x";
	case CrossingAndAssociative : return "%";
	default                     : return "o";
	}
    }

}
