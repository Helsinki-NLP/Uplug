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

package opennlp.grok.preprocess.tokenize;

import opennlp.maxent.*;
import opennlp.maxent.io.*;
import opennlp.common.preprocess.*;
import opennlp.common.util.*;
import opennlp.common.xml.*;

import org.jdom.*;

import java.io.*;
import java.lang.*;
import java.util.*;

/**
 * A Tokenizer for converting raw text into separated tokens.  It uses Maximum
 * Entropy to make its decisions.  The features are loosely based off of Jeff
 * Reynar's UPenn thesis "Topic Segmentation: Algorithms and Applications.",
 * which is available from his homepage: <http://www.cis.upenn.edu/~jcreynar>.
 *
 * @author      Tom Morton
 * @version $Revision$, $Date$
 */

public class TokenizerME implements Tokenizer {

    /**
     * The maximum entropy model to use to evaluate contexts.
     */
    private MaxentModel model;

    /**
     * The context generator.
     */
    private final ContextGenerator cg = new TokContextGenerator();

    /**
     * Class constructor which takes the string locations of the information
     * which the maxent model needs.
     */
    public TokenizerME(MaxentModel mod) {
	model = mod;
    }


    /**
     * Tokenize an NLPDocument.
     *
     * @param nlpd  The NLPDocument to be tokenized.
     */
    public void process(NLPDocument doc) { 
	for (Iterator i=doc.wordIterator(); i.hasNext();) {
	    Element oldWord = (Element)i.next();
	    String[] tokenized = tokenize(oldWord.getText());
	    if (tokenized.length > 1) {
		Element parentToken = oldWord.getParent();
		String tokenType = parentToken.getAttributeValue("type");
		if (tokenType == null) {
		    List $toks = new ArrayList(tokenized.length);
		    for (int j=0; j<tokenized.length; j++) {
			$toks.add(NLPDocument.createTOK(tokenized[j]));
		    }
		    XmlUtils.replace(parentToken, $toks);
		}
	    }
	}
    }

    public Set requires() {
	Set set = new HashSet();
	//set.add(SentenceDetector.class);
	return set;
    }
    
    /**
     * Tokenize a String.
     *
     * @param s  The string to be tokenized.
     * @return   A string array containing individual tokens as elements.
     *           
     */
    public String[] tokenize(String s) {
	String[] toksByWhitespace = PerlHelp.splitByWhitespace(s);
	List tokens = new ArrayList();
	
	for (int i=0; i<toksByWhitespace.length; i++) {
	    String tok = toksByWhitespace[i];
	    if (tok.length()>0 && PerlHelp.isAlphanumeric(tok)) {
		tokens.add(tok);
	    }
	    else {
		int index = 0;
		int end = tok.length();
		StringBuffer sb = new StringBuffer(tok);
		for (int j=0; j<end; j++) {
		    double[] probs =
			model.eval(cg.getContext(new ObjectIntPair(sb,j)));
		    String best = model.getBestOutcome(probs);
		    char c = sb.charAt(j);
		    if ((best.equals("T") || c=='?')
			&& (index <= j-1)
			&& (c != '.' || i==tokens.size()-1)) {

			// We check for a possessive "'s" or contracted 'be'
			// ('s and 're) in the next few chars since the model
			// seems to be in error on this.  This hack will need
			// to be fixed by making sure that the model's
			// training data is correct and is being read
			// correctly. - Jason
			int nextIndex;
			if ((j<=end-1
			     && (c=='x' || c=='s' || c=='z')
			     && sb.charAt(j+1) == '\'')
			    || (j<=end-2
				&& sb.charAt(j+1) == '\''
				&& sb.charAt(j+2) == 's')
			    || (j<=end-3
				&& sb.charAt(j+1) == '\''
				&& sb.charAt(j+2) == 'r'
				&& sb.charAt(j+3) == 'e'))
			    nextIndex = j+1;
			else
			    nextIndex = j;
			String tokToAdd = sb.substring(index,nextIndex);
			if (tokToAdd.length() > 0)
			    tokens.add(tokToAdd);
			index=nextIndex;
		    }
		}
		if (index <= end) {
		    String suffixTok = sb.substring(index, end);
		    if (suffixTok.length() > 0)
			tokens.add(suffixTok);
		}
	    }
	}
	
	String[] tokenSA = new String[tokens.size()];
	tokens.toArray(tokenSA);
	return tokenSA;
    }

   public static void train(String[] args) {
	try {
	    FileReader datafr = new FileReader(new File(args[0]));
	    File output = new File(args[1]);
	    EventStream evc =
		new EventCollectorAsStream(new TokEventCollector(datafr));
	    GISModel tokMod = GIS.trainModel(evc, 100, 10);
	    new SuffixSensitiveGISModelWriter(tokMod, output).persist();
	} catch (Exception e) {
	    e.printStackTrace();
	}
	
    }


    /**
     * Trains a new model. Call from the command line with "java opennlp.grok.preprocess.tokenize.TokenizerME trainingdata modelname"
     */
    public static void main(String[] args) {
	TokenizerME.train(args);
    }


    
}
