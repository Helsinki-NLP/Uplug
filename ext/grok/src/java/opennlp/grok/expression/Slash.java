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

package opennlp.grok.expression;

import opennlp.common.unify.*;
import gnu.trove.*;
import org.jdom.Element;

/**
 * A categorial slash which has an optional mode associated with it.
 *
 * @author      Jason Baldridge
 * @version     $Revision$, $Date$
 */
public final class Slash extends TLinkableAdaptor implements Unifiable {
    public static final byte L = 0;
    public static final byte B = 1;
    public static final byte R = 2;
    
    
    private final byte _dir;
    private final SlashMode _mode;
    
    public Slash (Element el) {
	String d = el.getAttributeValue("d");
	if (d == null) {
	    d = "|";
	}
	String m = el.getAttributeValue("m");
	if (m == null) {
	    _mode = new SlashMode();
	} else {
	    _mode = new SlashMode(m.charAt(1));
	}
	_dir = encode(d.charAt(0));
    }

    public Slash() {
	this('|');
    }
    
    public Slash(char sd) {
	_dir = encode(sd);
	_mode = new SlashMode();
    }

    public Slash(char sd, char md) {
	_dir = encode(sd);
	_mode = new SlashMode(md);
    }
    
    private Slash (byte d, SlashMode m) {
	_dir = d;
	_mode = m;
    }

    public Slash copy () {
	return new Slash(_dir, _mode);
    }

    public boolean occurs (Variable v) {
	return false;
    }
    
    public void unifyCheck (Object u) throws UnifyFailure {
	if (u instanceof Slash) {
	    if (!slashesMatch(_dir, ((Slash)u)._dir)) {
		throw new UnifyFailure();
	    }
	    _mode.unifyCheck(((Slash)u)._mode);
	} else {
	    throw new UnifyFailure();
	}
    }


    public Object unify (Object u, Substitution sub) 
	throws UnifyFailure {

	if (u instanceof Slash) {
	    Slash s2 = (Slash)u;
	    if (_dir == B) {
		return s2.copy();
	    } else if (s2._dir == B) {
		return this.copy();
	    } else if ((_dir == L && s2._dir == R)
		       || (_dir == R && s2._dir == L) ) {
		throw new UnifyFailure();
	    }
	    return this.copy();
	} else {
	    throw new UnifyFailure();
	}
	
    }

    public Object fill (Substitution sub){
	return copy();
    }


    public boolean equals(Slash s) {	
	return slashesMatch(_dir, s._dir);
    }

    private static byte encode (char sd) {
	switch (sd) {
	case '/': return R;
	case '\\': return L;
	default: return B;
	}
    }

    private static boolean slashesMatch(byte s1, byte s2) {
	if (s1 == B || s2 == B) {
	    return true;
	} else {
	    return s1 == s2;
	}
    }

    public String toString() {
	switch (_dir) {
	case R: return "/";
	case L: return "\\";
	default: return "|";
	}
    }

}
