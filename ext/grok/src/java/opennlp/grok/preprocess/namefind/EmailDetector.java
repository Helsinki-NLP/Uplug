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

package opennlp.grok.preprocess.namefind;

import java.io.*;
import java.util.*;

import org.jdom.*;

import opennlp.common.preprocess.*;
import opennlp.common.xml.*;

import opennlp.common.util.PerlHelp;
import opennlp.maxent.*;

/**
 * Find emails in a text and mark them.  Not much of a detector at the
 * moment as it only checks whether there is a "@" in the string.
 *
 * @author      Jason Baldridge
 * @version     $Revision$, $Date$
 */

public class EmailDetector implements Pipelink {    

    public boolean isEmail(String s) {
	return s.indexOf('@') != -1;
    }
    
    /**
     * Find the email addresses in a document.
     */
    public void process(NLPDocument doc){
        for (Iterator tokIt = doc.tokenIterator(); tokIt.hasNext();) {
	    Element tokEl = (Element)tokIt.next();
	    if (isEmail(XmlUtils.getAllTextNested(tokEl)))
		tokEl.setAttribute("type", "email");
	}
    }

    public Set requires() {
	return Collections.EMPTY_SET;
    }

}



