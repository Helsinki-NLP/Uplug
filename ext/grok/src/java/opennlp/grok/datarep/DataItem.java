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

import opennlp.hylo.*;
import opennlp.common.synsem.*;
import org.jdom.*;
import java.util.ArrayList;

/**
 * Data structure for storing information about a lexical entry.  Specifically
 * used by LMR grammars.
 *
 * @author      Jason Baldridge
 * @version $Revision$, $Date$
 */
public class DataItem {
    private String stem = "";
    private String pred = "";
    private LF _semantics;
    private String comment = "";
    private ArrayList feats = new ArrayList();
    
    public DataItem() {}

    public DataItem(Element datael) {
	stem = datael.getAttributeValue("stem");	
	pred = stem;

	Element lf = datael.getChild("lf");
	if (lf != null) {
	    _semantics = HyloHelper.getLF(lf);
	}

	comment = datael.getAttributeValue("note");
	if (comment == null) comment = "";
    }

    public void setStem(String s) { stem = s; }
    public void setPred(String s) { pred = s; }
    public void setComment(String s) { comment = s; }

    public String getStem() { return stem; }
    public String getPred() { return pred; }
    public String getComment() { return comment; }

    public LF getLF () {
	return _semantics;
    }

    // For backward compatibility in order to compile.  Will remove.
    public ArrayList getPresup() { return new ArrayList(); }
    public ArrayList getFeat() { return new ArrayList(); }


}
