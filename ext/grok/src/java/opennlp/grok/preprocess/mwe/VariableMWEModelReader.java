///////////////////////////////////////////////////////////////////////////////

// Copyright (C) 2002 Mike Atkinson
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

package opennlp.grok.preprocess.mwe;

import java.io.*;
import opennlp.common.util.PerlHelp;

/**
 *  A reads a model holding the Fixed Lexicon Multi-Word Expressions.<p>
 *
 *  The model should consist of line containing the MWE which should be expressions
 *  which do not change in any way in English (e.g. "ad hoc").<p>
 *
 *  Anything after a '#' character is a comment. Lines are trimmed of whitespace
 *  at their beginning and end.
 *
 * @author     Mike Atkinson
 * @created    10 March 2002
 * @version    $Revision$, $Date$
 */

public class VariableMWEModelReader {

    private MWEModel model = new VariableMWEModel();

    public final static int NOUN = 1;
    public final static int ADVERB = 2;
    public final static int ADJECTIVE = 3;
    public final static int VERB = 4;

    /**
     *  Constructor for the MWEModelReader object
     *
     * @param  reader  Source of the model data.
     */
    public VariableMWEModelReader(Reader reader, int type) {
        addData(reader, type);
    }
    
    /**
     * Add more data to the model
     *
     * @param  reader  Source of the model data.
     */
    public void addData(Reader reader, int type) {
        if (type<NOUN || type>VERB) {
            throw new IllegalArgumentException("type expected to be one of"+
                                            "NOUN, ADVERB, ADJECTIVE or VERB");
        }
	try {
	    StringBuffer sb = new StringBuffer();
	    int chr = reader.read();
	    while (chr >= 0) {
		if (chr == '\n' || chr == '\r') {
		    String line = sb.toString();
		    int split = line.indexOf('#');
		    if (split >= 0) {
			line = line.substring(0, split);
		    }
		    line = line.trim();
		    if (line.length() > 0) {
                        switch (type) {
                            case NOUN:
                                // assume that thelast word in a noun MWE
                                // is variable.
                                String[] spaceSplit = PerlHelp.split(line);
			        model.addMWE(spaceSplit.length+" "+line);
                                break;
                            case ADJECTIVE:
                                // assume that an adjective MWE is fixed
			        model.addMWE("-1 "+line);
                                break;
                            case ADVERB:
                                // assume that an adverb MWE is fixed
			        model.addMWE("-1 "+line);
                                break;
                            case VERB:
                                // assume that the first word is the verb which
                                // changes.
			        model.addMWE("1 "+line);
                                break;                                
                        }
 		    }
		    sb.setLength(0); // reuse buffer
		} else {
		    sb.append((char) chr);
		}
		chr = reader.read();
	    }
	} catch (IOException e) {
	    e.printStackTrace();
	} catch (Exception e) {
	    e.printStackTrace();
	}
    }



    /**
     *  Gets the Model which the MWEModelReader has read from store.
     *
     * @return    The Model value
     */
    public MWEModel getModel() {
	return model;
    }
}

