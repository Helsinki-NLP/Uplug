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

package opennlp.grok.preprocess.sentdetect;

import opennlp.maxent.*;
import opennlp.maxent.io.*;

import opennlp.maxent.IntegerPool;
import opennlp.common.preprocess.*;
import opennlp.common.util.*;
import opennlp.common.xml.*;

import org.jdom.*;

import java.io.*;
import java.lang.*;
import java.util.*;

/**
 * A sentence detector for splitting up raw text into sentences.  A maximum
 * entropy model is used to evaluate the characters ".", "!", and "?" in a
 * string to determine if they signify the end of a sentence.
 *
 * @author      Jason Baldridge
 * @version     $Revision$, $Date$
 */

public class SentenceDetectorME implements SentenceDetector {

    // The maximum entropy model to use to evaluate contexts.
    private MaxentModel model;

    // The feature context generator.
    private final ContextGenerator cgen;

    // The EndOfSentenceScanner to use when scanning for end of
    // sentence offsets.
    private final EndOfSentenceScanner scanner;

    // a pool of read-only java.lang.Integer objects in the range 0..100
    private static final IntegerPool INT_POOL = new IntegerPool(100);

    // the index of the "true" outcome in the model
    private final int _trueIndex;

    /**
     * Constructor which takes a MaxentModel and calls the three-arg
     * constructor with that model, an SDContextGenerator, and the
     * default end of sentence scanner.
     *
     * @param m The MaxentModel which this SentenceDetectorME will use to
     *          evaluate end-of-sentence decisions.
     */
    public SentenceDetectorME(MaxentModel m) {
        this (m, new SDContextGenerator(),new DefaultEndOfSentenceScanner());
    }

    /**
     * Constructor which takes a MaxentModel and a ContextGenerator.
     * calls the three-arg constructor with a default ed of sentence scanner.
     *
     * @param m The MaxentModel which this SentenceDetectorME will use to
     *          evaluate end-of-sentence decisions.
     * @param cg The ContextGenerator object which this SentenceDetectorME
     *           will use to turn Strings into contexts for the model to
     *           evaluate.
     */
    public SentenceDetectorME(MaxentModel m, ContextGenerator cg) {
        this(m,cg,new DefaultEndOfSentenceScanner());
    }

    /**
     * Creates a new <code>SentenceDetectorME</code> instance.
     *
     * @param m The MaxentModel which this SentenceDetectorME will use to
     *          evaluate end-of-sentence decisions.
     * @param cg The ContextGenerator object which this SentenceDetectorME
     *           will use to turn Strings into contexts for the model to
     *           evaluate.
     * @param s the EndOfSentenceScanner which this SentenceDetectorME
     *          will use to locate end of sentence indexes.
     */
    public SentenceDetectorME(MaxentModel m,
                              ContextGenerator cg,
                              EndOfSentenceScanner s) {
        model = m;
	_trueIndex = model.getIndex("T");
        cgen = cg;
        scanner = s;
    }


    /**
     * Sentence detect a document.
     *
     * @param doc  The NLPDocument on which to perform sentence detection.
     */
    public void process(NLPDocument doc) {
	for (Iterator sentIt=doc.sentenceIterator(); sentIt.hasNext();) {
	    Element sentEl = (Element)sentIt.next();
	    List wordEls = doc.getWordElements(sentEl);
	    int lastWordIndex = wordEls.size()-1;
	    List elementsWithSentenceBreak = new ArrayList();
	    List positionWithinEachBreakElement = new ArrayList();
	    for (int i=0; i<=lastWordIndex; i++) {
		Element current = (Element)wordEls.get(i);
		String parentType = 
		    current.getParent().getAttributeValue("type");
		if (parentType != null) 
		    break;
		String word = current.getText();
		List enders = scanner.getPositions(word);
		int endersSize = enders.size();
		if (endersSize > 0) {
		    String previous = "", next = "";
		    if (i>0)
			previous = ((Element)wordEls.get(i-1)).getText();
		    if (i<lastWordIndex)
			next = ((Element)wordEls.get(i+1)).getText();
		    Integer mostLikely = null;
		    double highest = 0.0; 
		    for (int j=0; j<endersSize; j++) {
			String[] info = { previous, word, next };
			Integer position = (Integer)enders.get(j);
			double[] probs = 
			    model.eval(cgen.getContext(new Pair(info, position)));
			if (model.getBestOutcome(probs).equals("T") 
			    && probs[_trueIndex] > highest) {
			    highest = probs[_trueIndex];
			    mostLikely = position;
			}
		    }
		    if (mostLikely != null) {
			elementsWithSentenceBreak.add(current);
			positionWithinEachBreakElement.add(mostLikely);
		    }
		}
	    }
	    int size = elementsWithSentenceBreak.size();
	    if (size == 0)
		break;
	    int tokenIndex = 0;
	    List oldSentToks = doc.getTokenElements(sentEl);
	    int numOfOldToks = oldSentToks.size();
	    List $sents = new ArrayList();
	    List $toks = new ArrayList();
	    for (int i=0; i<size; i++) {
		Element breaker = (Element)elementsWithSentenceBreak.get(i);
		Element breakerToken = breaker.getParent();
		boolean found = false;
		for (; tokenIndex<numOfOldToks && !found; tokenIndex++) {
		    Element oldTok = (Element)oldSentToks.get(tokenIndex);
		    if (oldTok == breakerToken) {
			found = true;
			int pos = 
			    ((Integer)positionWithinEachBreakElement.get(i)).intValue();
			String word = breaker.getText();
			breaker.setText(word.substring(0, pos));
			Element enderToken = 
			    NLPDocument.createTOK(word.substring(pos, pos+1));
			$toks.add(breakerToken.detach());
			$toks.add(enderToken);
			$sents.add(new Element(NLPDocument.SENTENCE_LABEL).setChildren($toks));
			$toks = new ArrayList();
			if (pos<word.length()-1) {
			    Element suffixToken = 
				NLPDocument.createTOK(word.substring(pos+1));
			    $toks.add(suffixToken);
			}
		    }
		    else {
			if (tokenIndex == numOfOldToks-1)
			    addLastTokenOfSentence((Element)oldSentToks.get(numOfOldToks-1),
						   $toks);
			else {
			    $toks.add(oldTok.detach());
			}
		    }
		}
	    }
	    if (tokenIndex<numOfOldToks-1) {
		for (;tokenIndex<numOfOldToks-1; tokenIndex++)
		    $toks.add(((Element)oldSentToks.get(tokenIndex)).detach());
		addLastTokenOfSentence((Element)oldSentToks.get(numOfOldToks-1),
				       $toks);
		$sents.add(new Element(NLPDocument.SENTENCE_LABEL).setChildren($toks));
	    }
	    XmlUtils.replace(sentEl, $sents);
	}
    }

    private void addLastTokenOfSentence (Element lastToken, List toks) {
	toks.add(lastToken.detach());
	String word = lastToken.getChildText(NLPDocument.WORD_LABEL);
	int lastIndex = word.length()-1;
	if (!Character.isUnicodeIdentifierPart(word.charAt(lastIndex))) {
	    lastToken.getChild(NLPDocument.WORD_LABEL).setText(word.substring(0, lastIndex));
	    toks.add(NLPDocument.createTOK(word.substring(lastIndex)));
	}
    }
    
    public Set requires() {
        return Collections.EMPTY_SET;
    }
    
    /**
     * Detect sentences in a String.
     *
     * @param s  The string to be processed.
     * @return   A string array containing individual sentences as elements.
     *           
     */
    public String[] sentDetect(String s) {
        StringBuffer sb = new StringBuffer(s);
        List enders = scanner.getPositions(sb);

        int index = 0;
        List sents = new ArrayList();

        for (int i=0, end = enders.size(); i < end; i++) {
            Integer candidate = (Integer)enders.get(i);
            int cint = candidate.intValue();

            // skip over the leading parts of contiguous delimiters
            if (((i + 1) < end) &&
                (((Integer)enders.get(i + 1)).intValue() == (cint + 1))) {
                continue;
            }

            Pair pair = new Pair(sb,candidate);
            double[] probs = model.eval(cgen.getContext(pair));

            if (model.getBestOutcome(probs).equals("T")
                && isAcceptableBreak(s,index,cint)) {
                String sent = sb.substring(index, cint+1).trim();
                if (sent.length() > 0) {
                    sents.add(sent);
                }
                index=cint+1;
            }
        }

        if (index < sb.length()) {
            String sent = sb.substring(index).trim();
            if (sent.length() > 0) sents.add(sent);
        }

        String[] sentSA = new String[sents.size()];
        sentSA = (String[])sents.toArray(sentSA);
        return sentSA;
    }

    private int getFirstNonWS(String s, int pos) {
        while(pos < s.length() && Character.isWhitespace(s.charAt(pos)))
            pos++;
        return pos;
    }
	
    /**
     * Detect the position of the first words of sentences in a String.
     *
     * @param s  The string to be processed.
     * @return   A integer array containing the positions of the beginning of
     *          every sentence
     *           
     */
    public int[] sentPosDetect(String s) {
                StringBuffer sb = new StringBuffer(s);
        List enders = scanner.getPositions(s);
        List positions = new ArrayList(enders.size());

        positions.add(INT_POOL.get(getFirstNonWS(s, 0)));

        for (int i = 0, end = enders.size() - 1, index = 0; i < end; i++) {
            Integer candidate = (Integer)enders.get(i);
            int cint = candidate.intValue();

            // skip over the leading parts of contiguous delimiters
            if (((i + 1) < end) &&
                (((Integer)enders.get(i + 1)).intValue() == (cint + 1))) {
                continue;
            }

            Pair pair = new Pair(sb,candidate);
            double[] probs = model.eval(cgen.getContext(pair));
            if (model.getBestOutcome(probs).equals("T")
                && isAcceptableBreak(s, index, cint)) {
                if(index != cint) {
                    positions.add(INT_POOL.get(getFirstNonWS(s, cint + 1)));
                }
                index= cint + 1;
            }
        }

        int[] sentPositions = new int[positions.size()];
        for (int i=0; i<sentPositions.length; i++) {
            sentPositions[i] = ((Integer)positions.get(i)).intValue();
        }
        return sentPositions;
    }

    /** 
     * Allows subclasses to check an overzealous (read: poorly
     * trained) model from flagging obvious non-breaks as breaks based
     * on some boolean determination of a break's acceptability.
     *
     * <p>The implementation here always returns true, which means
     * that the MaxentModel's outcome is taken as is.</p>
     * 
     * @param s the string in which the break occured. 
     * @param fromIndex the start of the segment currently being evaluated 
     * @param candidateIndex the index of the candidate sentence ending 
     * @return true if the break is acceptable 
     */
    protected boolean isAcceptableBreak(String s,
                                        int fromIndex,
                                        int candidateIndex) { 
        return true;
    } 

    public static GISModel train(EventStream es, int iterations, int cut)
        throws IOException {

	    return GIS.trainModel(es, iterations, cut);
    }


    /**
     * Use this training method if you wish to supply an end of
     * sentence scanner which provides a different set of ending chars
     * than the default one, which is "\\.|!|\\?|\\\"|\\)".
     *
     */
    public static GISModel train(File inFile, int iterations,
                                 int cut, EndOfSentenceScanner scanner)
        throws IOException {
        EventStream es;
        DataStream ds;
        Reader reader;

        reader = new BufferedReader(new FileReader(inFile));
        ds = new PlainTextByLineDataStream(reader);
	    es = new SDEventStream(ds, scanner);
	    return GIS.trainModel(es, iterations, cut);
    }


    /**
     * <p>Trains a new sentence detection model.</p>
     *
     * <p>Usage: java opennlp.grok.preprocess.sentdetect.SentenceDetectorME data_file new_model_name (iterations cutoff)?</p>
     *
     */
    public static void main(String[] args) throws IOException {
        try {
            File inFile = new File(args[0]);
            File outFile = new File(args[1]);

            GISModel mod;

            EventStream es =
                new SDEventStream(
                                  new PlainTextByLineDataStream(new FileReader(inFile)));
	    
            if (args.length > 3) 
                mod = train(es,
                            Integer.parseInt(args[2]),
                            Integer.parseInt(args[3]));
            else 
                mod = train(es, 100, 5);

            System.out.println("Saving the model as: " + args[1]);
            new SuffixSensitiveGISModelWriter(mod, outFile).persist();

        } catch (Exception e) {
            e.printStackTrace();
        }
	
    }
}
