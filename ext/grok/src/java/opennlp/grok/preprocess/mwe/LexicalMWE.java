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
import java.util.*;

import org.jdom.*;

import opennlp.common.preprocess.*;
import opennlp.common.xml.*;
import opennlp.common.util.*;

import opennlp.maxent.*;

/**
 *  A Fixed Lexicon Multi-Word Expression finder that uses a list of MWE to determine
 *  if a sequence of words is in the MWE model.<p>
 *
 *  This finds common multi-word expressions which are completely fixed in English.
 *  Examples are "ad hoc", "au pair". Most are foreign language expressions which
 *  have been borrowed by English, although they might be analysable in their native
 *  language, the consitutent words make no sense when analysed with English grammar
 *  except as part of the MWE. Rather than extend the grammar to include these special
 *  usages it is much easier to treat the whole MWE as a lexicon entry with the right
 *  POS, semantic, etc. tags.<p>
 *
 *  Token tagging is delayed to a later stage in the pipeline.<p>
 *
 *  <pre>
 * &lt;?xml version="1.0" encoding="UTF-8"?&gt;
 * &lt;nlpDocument&gt;
 *   &lt;text&gt;
 *     &lt;p&gt;
 *       &lt;s&gt;
 *         &lt;t&gt;
 *           &lt;w&gt;ad&lt;/w&gt;
 *         &lt;/t&gt;
 *         &lt;t&gt;
 *           &lt;w&gt;hoc&lt;/w&gt;
 *         &lt;/t&gt;
 *       &lt;/s&gt;
 *     &lt;/p&gt;
 *   &lt;/text&gt;
 * &lt;/nlpDocument&gt;
 *
 * is transformed to:
 *
 * &lt;?xml version="1.0" encoding="UTF-8"?&gt;
 * &lt;nlpDocument&gt;
 *   &lt;text&gt;
 *     &lt;p&gt;
 *       &lt;s&gt;
 *         &lt;t type="mwe"&gt;
 *           &lt;w&gt;ad&lt;/w&gt;
 *           &lt;w&gt;hoc&lt;/w&gt;
 *         &lt;/t&gt;
 *       &lt;/s&gt;
 *     &lt;/p&gt;
 *   &lt;/text&gt;
 * &lt;/nlpDocument&gt;
 *
 * </pre>
 *
 *  This class implements the matching algorithm, while subclasses are used
 *  to load particular models (lists on MWEs).<p>
 *
 *  It requires a Tokenizer class to be ahead of it in the pipeline.<p>
 *
 *  There is no EventCollector defined, as this does not use the maximum entropy
 *  algorithm.
 *
 * @author     Mike Atkinson
 * @created    10 March 2002
 * @version    $Revision$, $Date$
 */

public class LexicalMWE implements NameFinder, Evalable {

    /**
     *  The multi-word expression model to use to find MWEs.
     */
    protected MWEModel model;


    /**
     *  Constructor for the LexicalMWE object
     *
     * @param  mod  The model to use to find MWEs.
     */
    public LexicalMWE(MWEModel mod) {
        model = mod;
    }


    /**
     *  Constructor for the LexicalMWE object
     */
    protected LexicalMWE() { }


    /**
     *  Gets the NegativeOutcome attribute of the LexicalMWE object
     *
     * @return    The NegativeOutcome value
     */
    public String getNegativeOutcome() {
        return "F";
    }


    /**
     *  Gets the EventCollector attribute of the LexicalMWE object
     *
     * @param  r  Source of the event collector data.
     * @return    always returns <code>null</code>
     */
    public EventCollector getEventCollector(Reader r) {
        return null;
    }


    /**
     *  NOT IMPLEMENTED
     *
     * @param  model    Maximum Entropy models are not used by this class.
     * @param  r        Source of the data.
     * @param  e        
     * @param  verbose  
     */
    public void localEval(MaxentModel model, Reader r, Evalable e, boolean verbose) {
    }


    /**
     *  Find the Fixed Lecical Multi-Word Expressions in a document.
     *
     * @param  doc  A JDOM document which contains the results of previous pipe stages processing.
     */
    public void process(NLPDocument doc) {
        for (Iterator sentIt = doc.sentenceIterator(); sentIt.hasNext(); ) {
            Element sentEl = (Element) sentIt.next();
            String[] wordList = doc.getWords(sentEl);
            List tokenEls = doc.getTokenElements(sentEl);
            int[] tokenToWord = new int[tokenEls.size()];
            int elNum = 0;
            int wordNum = 0;
            for (Iterator i = tokenEls.iterator(); i.hasNext(); ) {
                Object o = i.next();
                //System.out.println(o);
                Element token = (Element) o;
                List wordsInToken = XmlUtils.getChildrenNested(token, NLPDocument.WORD_LABEL);
                tokenToWord[elNum++] = wordNum;
                wordNum += wordsInToken.size();
            }
            for (int i = 0; i < tokenEls.size(); i++) {
                String[] words = model.getMWE(wordList, tokenToWord[i]);
                if (words != null && words.length > 0) {
                    Element tok = (Element) tokenEls.get(i);
                    tok.setAttribute("type", "mwe");
                    for (int j = 1; j < words.length; j++) {
                        tok.addContent(new Element("w").addContent(words[j]));
                    }
                    for (int j = 1; j < words.length; ) {
                        Element tokenToRemove = (Element) tokenEls.get(i + j);
                        int size = tokenToRemove.getChildren().size();
                        sentEl.removeContent(tokenToRemove);
                        j += size;
                    }
                }
            }
        }
    }


    /**
     *  It requires a Tokenizer class to be ahead of it in the pipeline.
     *
     * @return    contains the required classes which must be before this class in the pipeline.
     */
    public Set requires() {
        Set set = new HashSet();
        set.add(Tokenizer.class);
        return set;
    }


    /**
     *  Finds if there is a MWE at a position in the sequence of words by using the
     *  set model.
     *
     * @param  l    An array of the words to be searched.
     * @param  pos  The position in the array of the first word of the MWE.
     * @return      <code>true</code> when a MWE has been found at that position.
     */
    //protected boolean isMWE(String[] l, int pos) {
    //    return model.isMWE(l, pos);
   // }

}

