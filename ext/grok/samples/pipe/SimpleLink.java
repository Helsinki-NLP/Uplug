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
import opennlp.common.preprocess.*;
import opennlp.common.xml.*;

import org.jdom.*;

import java.io.*;
import java.lang.*;
import java.util.*;

/**
 * A simple implementation of the Pipelink interface to play around with.
 *
 * @author      Jason Baldridge
 * @version     $Revision$, $Date$
 */

public class SimpleLink implements Pipelink {

    // play around with this method to experiment with manipulating the
    // content of an NLPDocument
    public void process (NLPDocument doc) {
	for (Iterator sentIt=doc.sentenceIterator(); sentIt.hasNext();) {
	    Element sentEl = (Element)sentIt.next();
	    for (Iterator tokIt=doc.tokenIterator(sentEl); tokIt.hasNext();) {
		Element tokEl = (Element)tokIt.next();
	    }
	}
    }

    
    public Set requires() {
        return Collections.EMPTY_SET;
    }
    

}
