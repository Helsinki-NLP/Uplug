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
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU Lesser General Public
// License along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
//////////////////////////////////////////////////////////////////////////////

package opennlp.grokkit.gui;

import java.util.Properties;

public class Parameters extends Properties {
    public Parameters (Properties p) {
	super(p);
    }
    
    public boolean Bool (String s){
	return new Boolean((String)getProperty(s)).booleanValue();
    }
    public String Str (String s) {
	return (String)getProperty(s);
    }
    public int Int (String s) {
	return new Integer((String)getProperty(s)).intValue();
    }

    public void put (String s, boolean b) {
	setProperty(s,(new Boolean(b)).toString());
    }
    public void put (String s, int i) {
	setProperty(s,(new Integer(i)).toString());
    }
}

