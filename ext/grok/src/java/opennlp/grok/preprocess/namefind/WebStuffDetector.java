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
 * Find web-related strings in a text and mark them.  Pretty simple at the
 * moment but should cover a lot of cases.
 *
 * @author      Jason Baldridge
 * @version     $Revision$, $Date$
 */

public class WebStuffDetector implements Pipelink {    

    public boolean isUrl(String s) {
	if (s.indexOf(' ') != -1 || s.indexOf('@') != -1) {
	    return false;
	} else if (s.indexOf("http:") != -1 || s.indexOf("file:") != -1
		   || s.indexOf("ftp:") != -1 || s.indexOf("www") != -1
		   || s.endsWith(".com") || s.endsWith(".net")
		   || s.endsWith(".org") || s.endsWith(".edu")
		   || s.endsWith(".gov") || s.endsWith(".uk")) {
	    return true;
	} else {
	    return false;
	}

    }
    
    public boolean isEmail(String s) {
	if (s.indexOf(' ') != -1) {
	    return false;
	}
	int atId = s.indexOf('@');
	if (atId == -1) {
	    return false;}
	else {
	    if (s.indexOf('.', atId) != -1) {
		return true;
	    }
	    else {
		return false;
	    }
	}
    }
    
    /**
     * Find the email addresses in a document.
     */
    public void process(NLPDocument doc){
        for (Iterator tokIt = doc.tokenIterator(); tokIt.hasNext();) {
	    Element tokEl = (Element)tokIt.next();
	    if (isEmail(XmlUtils.getAllTextNested(tokEl))) {
		tokEl.setAttribute("type", "email");
	    } else if (isUrl(XmlUtils.getAllTextNested(tokEl))) {
		tokEl.setAttribute("type", "url");
	    }
	}
    }

    public Set requires() {
	return Collections.EMPTY_SET;
    }

}



