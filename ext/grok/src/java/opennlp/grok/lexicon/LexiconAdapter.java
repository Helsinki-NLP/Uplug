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

package opennlp.grok.lexicon;

import opennlp.grok.preprocess.namefind.*;
import opennlp.grok.preprocess.tokenize.*;
import opennlp.grok.preprocess.sentdetect.*;
import opennlp.grok.expression.*;
import opennlp.common.parse.*;
import opennlp.common.preprocess.*;
import opennlp.common.synsem.*;
import opennlp.common.xml.*;

import org.jdom.*;

import java.util.*;

/**
 * A helpful class which lexicons can extend so that the string can be
 * preprocessed.  At this moment, the string is sentence detected, tokenized,
 * and name tagged.  Names are automatically given NP categories and all other
 * tokens are retrieved from sub-lexicon.
 *
 * @author      Gann Bierner
 * @version     $Revision$, $Date$
 */
public abstract class LexiconAdapter implements Lexicon {
    //private static final SentenceDetector sdetect =
    //new EnglishSentenceDetectorME();
    // private static final NameFinder nf = new EnglishNameFinderME();
    //private static final TokenizerME tokenizer = new EnglishTokenizerME();

    public LexiconAdapter(Properties g) { }

    /**
     * Given a string, preprocesses it and gets lexical entries for individual
     * components.  Right now, this can only handle a single sentence.
     *
     * @param s The string whose components need to be retrieved from the
     *          lexicon.
     * @return a list of WordHashes
     */
    public List getWords(NLPDocument doc) throws LexException {
	List entries = new ArrayList();
	snarfTokens(doc, entries);
	return entries;
    }

    public List getWords (String s) throws LexException { 
	List entries = new ArrayList();
	StringTokenizer st = new StringTokenizer(s);
	while(st.hasMoreTokens()) {
	    String w = st.nextToken();
	    Collection c = getWord(w);
	    if (c.size() == 0) {
		c = new ArrayList();
		c.add(unknownWord(w));
	    }
	    entries.add(new SignHash(c));
	}
	return entries;
    }

    private Sign unknownWord (String w) {
	return new GSign(w, new AtomCat("n"));
    }
	    

    protected void snarfTokens (NLPDocument doc, List entries)
	throws LexException {
	//String namefeat = "per=3, num=s, 3sg=+, dem=+";

	for (Iterator i=doc.tokenIterator(); i.hasNext();) {
	    Element tokEl = (Element)i.next();
	    String type = tokEl.getAttributeValue("type");
	    if (type == null) {
		List wordEls = doc.getWordElements(tokEl);
		for (Iterator j=wordEls.iterator(); j.hasNext();) {
		    String orthog = ((Element)j.next()).getText();
		    if(orthog.length() > 0) {
			Collection c = getWord(orthog);		    
			if (c.size() == 0) {
			    c = new ArrayList();
			    c.add(unknownWord(orthog));
			}
			entries.add(new SignHash(c));
		    }
		}
	    }
	    else {
		String orth = XmlUtils.getAllTextNested(tokEl);
		StringBuffer sem = new StringBuffer();
		if (type.equals("name")) {
		    sem.append("^NAME(").
			append(NameChopper.segmentName(orth)).append(')');
		}
		else if (type.equals("email")) {
		    sem.append("^EMAIL(").append(orth).append(')');
		}
		entries.add(new SignHash(unknownWord(sem.toString())));
	    }
	}
    }    
	

}
