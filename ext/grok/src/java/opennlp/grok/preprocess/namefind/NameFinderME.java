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
import opennlp.common.util.*;

import opennlp.maxent.*;

/**
 * A Name Finder that uses maximum entropy to determine if a word is a name or
 * not a name. 
 *
 * @author      Gann Bierner
 * @version     $Revision$, $Date$
 */

public class NameFinderME implements NameFinder, Evalable {

    /**
     * The maximum entropy model to use to evaluate contexts.
     */
    protected MaxentModel model;

    /**
     * The feature context generator.
     */
    protected static final ContextGenerator cg = new NFContextGenerator();
    
    protected NameFinderME() {}
    
    public NameFinderME(MaxentModel mod) {
	model = mod;
    }

    public String getNegativeOutcome() {
	return "F";
    }

    public EventCollector getEventCollector(Reader r) {
	return new NFEventCollector(r);
    }

    public void localEval(MaxentModel model, Reader r,
			  Evalable e, boolean verbose) {
    }    

    protected boolean isName(String[] l, int pos) {
	ObjectIntPair info = new ObjectIntPair(l, pos);
	String guess = model.getBestOutcome(model.eval(cg.getContext(info)));
	return guess.equals("T");
    }
	
    /**
     * Find the names in a document.
     */
    public void process(NLPDocument doc){
	for (Iterator sentIt=doc.sentenceIterator(); sentIt.hasNext();) {
	    Element sentEl = (Element)sentIt.next();
	    List wordEls = doc.getWordElements(sentEl);
	    String[] wordList = doc.getWords(sentEl);

	    for(int i=0; i<wordList.length; i++) {
		if (isName(wordList, i)) {
		    Element wordEl = (Element)wordEls.get(i);
		    if (wordEl.getParent().getAttributeValue("type") == null) {
			// check that the part-of-speech is a Noun type
			String pos = wordEl.getAttributeValue("pos");
			if (pos == null
			    || (pos.charAt(0) == 'N' && pos.charAt(1) == 'N')) {
			    Element parentToken =
				((Element)wordEls.get(i)).getParent();
			    parentToken.setAttribute("type", "name");  
			    while (++i < wordList.length && isName(wordList, i)) {
				wordEl = (Element)wordEls.get(i);
				wordEl.getParent().detach();
				parentToken.addContent(wordEl.detach());
			    }
			}
		    }
		}
	    }
	}
    }

   public Set requires() {
	Set set = new HashSet();
	set.add(Tokenizer.class);
	return set;
    }

    /**
     * Example training call:
     * <p> java -mx512m opennlp.grok.preprocess.namefind.NameFinderME -t -d ./ -c 5 -s NewEngNF5.bin.gz nameTrain.data
     * </p>
     **/
     public static void main(String[] args) throws IOException {
	TrainEval.run(args, new NameFinderME());
    }
}
