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

package opennlp.grok.parse;

import opennlp.grok.lexicon.*;
import opennlp.grok.grammar.*;
import opennlp.grok.util.*;

import opennlp.common.parse.*;
import opennlp.common.synsem.*;
import opennlp.common.unify.*;

import java.util.*;
import java.io.*;

/**
 * CKY is a chart parser that is used, in this case, with the CCG
 * grammar formalism.
 *
 * @author      Gann Bierner
 * @version     $Revision$, $Date$
 */
public class MaxIncrCKY extends CKY {

    /**
     * class constructor: sets lexicon and rules
     *
     * @param lex    The URL where lexicon is located.
     * @param rule   The URL where the rules are located.
     
     * @exception java.io.FileNotFoundException
     *                                If cannot find file
     * @exception java.io.IOException If cannot find file
     */
    public MaxIncrCKY(String lex, String rule) 
	throws FileNotFoundException, IOException, LexException {
	super(lex, rule);
    }


    public MaxIncrCKY(Lexicon l, RuleGroup r) { 
	super(l, r); 
    }

    
    public void parse(Chart table, int size) throws ParseException {
	// actual MaxIncrCKY parsing
	for(int i=1; i<size; i++) {
	    table.insertCell(i,i);	    
	    table.insertCell(0,i-1, i,i, 0,i);
	    table.insertCell(0,i);
	}
	createResult(table, size);
    }
}

