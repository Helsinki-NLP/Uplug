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

import opennlp.grok.expression.*;
import opennlp.grok.io.*;
import opennlp.common.synsem.*;
import org.jdom.*;
import java.util.ArrayList;

/**
 * Data structure for storing information about a families categories.
 * Specifically used by LMR grammars.
 *
 * @author      Jason Baldridge
 * @version $Revision$, $Date$
 */
public class EntriesItem {
    private Boolean active = new Boolean(true);
    private String name = "";
    private String stem = "";
    private Category cat;
    private String sem = "";
    private String comment = "";
    
    public EntriesItem() {}

    public EntriesItem(Element el) {
	name = el.getAttributeValue("name");

	stem = el.getAttributeValue("stem");
	if (stem == null)
	    stem = "[*DEFAULT*]";

	String isActive = el.getAttributeValue("active");
	if(isActive != null && isActive.equals("false"))
	    active = new Boolean(false);

	comment = el.getAttributeValue("comment");
	if (comment == null)
	    comment = null;

	cat = CatReader.getCat((Element)el.getChildren().get(0));
	LexiconReader.cathash.put(name, cat);
    }

    public void setActive(Boolean b) { active = b; }
    public void setName(String s) { name = s; }
    public void setStem(String s) { stem = s; }
    public void setCat(Category c) { cat = c; }
    public void setSem(String s) { sem = s; }
    public void setComment(String s) { comment = s; }

    public Boolean getActive() { return active; }
    public String getName() { return name; }
    public String getStem() { return stem; }
    public Category getCat() { return cat; }
    public String getSem() { return sem; }
    public String getComment() { return comment; }
    
    // For backward compatibility in order to compile.  Will remove.
    public void addPresup(String s) {}
    public void setPresup(ArrayList a) {}
    public ArrayList getPresup() { return new ArrayList(); }
    
    public String toString () {
	return name + ":" + stem + " :- " + cat;
    }
    
}
