///////////////////////////////////////////////////////////////////////////////
// Copyright (C) 2002 Meghan Pike
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

import javax.swing.text.*;
import javax.swing.*;

import opennlp.common.synsem.Sign;
import opennlp.common.synsem.Category;
import opennlp.common.unify.FeatureStructure;

import java.util.ArrayList;
import java.util.Set;
import java.util.Iterator;

/**
 *  A class to display the results of a parse.
 *
 *  @author     Meghan Pike
 *  @version $Revision$, $Date$
 **/

public class NLPTextComponent extends JTextArea {
    private ArrayList content;

    //////////////////////////
    //  constructors
    //////////////////////////

    public NLPTextComponent(ArrayList answers) {
	super();
	content = answers;
	setEditable(false);
	initialiseDocument();
    }

    public NLPTextComponent() {
	super();
	setEditable(false);
    }

    //////////////////////////
    // methods
    //////////////////////////

    public void setContent(ArrayList answers) {
	content = answers;
	initialiseDocument();
    }

    private void initialiseDocument() {
	setText("");
	StringBuffer text = new StringBuffer();
	for(int i = 0; i<content.size(); i++) {
	    Sign constituent = (Sign)content.get(i);
	    if (constituent == null) {
		continue;
	    }
	    Category category = constituent.getCategory();
	    if (category == null) {
		continue;
	    }
	    text.append(i).append(": Category: ").append(category.toString()).append('\n').append("     Orthography: ").append(constituent.getOrthography()).append('\n');
	    FeatureStructure feats = category.getFeatureStructure();
	    if (feats == null) {
		continue;
	    }
	    Set attributes = feats.getAttributes();
	    if (attributes == null) {
		continue;
	    }
	    text.append("        FeatureStructure: ").append('\n');
	    for (Iterator iter = attributes.iterator(); iter.hasNext(); ) {
		text.append("            Attribute: ").append(iter.next().toString()).append('\n');
	    }
	}
	setText(text.toString());
    }
}
