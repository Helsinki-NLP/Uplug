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

import org.jdom.*;
import java.util.*;

/**
 * Data structure for storing information about morphological macros.
 * Specifically used by LMR grammars.
 *
 * @author      Jason Baldridge
 * @version $Revision$, $Date$
 */
public class MacroItem {
    private String name;
    private ArrayList specs = new ArrayList();

    public MacroItem() {};

    public MacroItem (Element e) {
	name = e.getAttributeValue("name");
	List specEls = e.getChildren("spec");
	for (int i=0; i<specEls.size(); i++)
	    specs.add(((Element)specEls.get(i)).getAttributeValue("val"));
    }
    
    public void setName(String s) { name=s; }
    public void setSpecs(ArrayList al) {specs = al; }

    public String getName() { return name; }
    public ArrayList getSpecs() { return specs; }

    public void addSpec(String s) { specs.add(s); }
    public void removeSpec(String s) {
	specs.remove(specs.indexOf(s));
    }
    
}
