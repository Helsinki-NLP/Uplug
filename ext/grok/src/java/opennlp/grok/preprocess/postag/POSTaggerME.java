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

package opennlp.grok.preprocess.postag;

import java.io.*;
import java.util.*;

import org.jdom.*;

import opennlp.common.preprocess.*;
import opennlp.common.xml.*;
import opennlp.common.util.*;

import opennlp.maxent.*;
import opennlp.maxent.io.*;

/**
 * A part-of-speech tagger that uses maximum entropy.  Trys to predict whether
 * words are nouns, verbs, or any of 70 other POS tags depending on their
 * surrounding context.
 *
 * @author      Gann Bierner
 * @version $Revision$, $Date$
 */
public class POSTaggerME implements Evalable, POSTagger {

    /**
     * The maximum entropy model to use to evaluate contexts.
     */
    protected MaxentModel _posModel;

    /**
     * The feature context generator.
     */
    protected ContextGenerator _contextGen = new POSContextGenerator();

    /**
     * Decides whether a word can be assigned a particular closed class tag.
     */
    protected FilterFcn _closedClassTagsFilter;

    
    /**
     * Says whether a filter should be used to check whether a tag assignment
     * is to a word outside of a closed class.
     */
    protected boolean _useClosedClassTagsFilter = false;
    
    
    protected POSTaggerME () {}

    public POSTaggerME (MaxentModel mod) {
	this(mod, new POSContextGenerator());
    }
    
    public POSTaggerME (MaxentModel mod, ContextGenerator cg) {
	_posModel = mod;
	_contextGen = cg;
    }

    public String getNegativeOutcome() { return ""; }
    
    public EventCollector getEventCollector(Reader r) {
       	return new POSEventCollector(r,_contextGen);
    }
	
    /**
     * POS tag the words in a document.
     */
    public void process (NLPDocument doc){
	for (Iterator sentIt=doc.sentenceIterator(); sentIt.hasNext();) {
	    Element sentEl = (Element)sentIt.next();
	    List wordEls = doc.getWordElements(sentEl);
	    List words = new ArrayList(wordEls.size());
	    for (Iterator wordIt=wordEls.iterator(); wordIt.hasNext();)
		words.add(((Element)wordIt.next()).getText());
	    List tags = bestSequence(words);
	    int index = 0;
	    for (Iterator wordIt=wordEls.iterator(); wordIt.hasNext();) {
		((Element)wordIt.next()).
		    setAttribute("pos", (String)tags.get(index++));
	    }
	}
    }
    
    public List tag(List sentence) {
	return bestSequence(sentence);
    }

    public String[] tag(String[] sentence) {
	ArrayList l = new ArrayList();
	for(int i=0; i<sentence.length; i++)
	    l.add(sentence[i]);
	List t = tag(l);
	
	String[] tags = new String[t.size()];
	int c=0;
	for(Iterator i=t.iterator(); i.hasNext(); c++)
	    tags[c]=(String)i.next();

	return tags;
    }

    public String tag(String sentence) {
	ArrayList toks = new ArrayList();
	StringTokenizer st = new StringTokenizer(sentence);
	while(st.hasMoreTokens())
	    toks.add(st.nextToken());
	List tags = tag(toks);
	StringBuffer sb = new StringBuffer();
	for(int i=0; i<tags.size(); i++)
	    sb.append(toks.get(i) + "/" + tags.get(i) + " ");
	return sb.toString().trim();
    }

    public void localEval(MaxentModel posModel, Reader r,
			  Evalable e, boolean verbose) {

	_posModel = posModel;
	float total=0, correct=0, sentences=0, sentsCorrect=0, independent=0;
	BufferedReader br = new BufferedReader(r);
	String line;
	ArrayList contexts = new ArrayList();
	try {
	    while((line=br.readLine())!=null) {
		sentences++;
		Pair p = POSEventCollector.convertAnnotatedString(line);
		List words = (List)p.a;
		List outcomes = (List)p.b;
		List tags = bestSequence(words);
		
		int c=0;
		boolean sentOk = true;
		for(Iterator t=tags.iterator(); t.hasNext(); c++) {
		    total++;
		    String tag = (String)t.next();
		    if(tag.equals(outcomes.get(c)))
			correct++;
		    else
			sentOk=false;
		}
		if(sentOk) sentsCorrect++;
	    }
	} catch (IOException E) { E.printStackTrace(); }
	
	System.out.println("Accuracy         : " + correct/total);
	System.out.println("Sentence Accuracy: " + sentsCorrect/sentences);

    }

    ///////////////////////////////////////////////////////////////////
    // Do a beam search to compute best sequence of results (as in pos)
    // taken from Ratnaparkhi (1998), PhD diss, Univ. of Pennsylvania
    ///////////////////////////////////////////////////////////////////
    private static class Sequence extends ArrayList implements Comparable {
	double score=1;
	Sequence() {};
	Sequence(double s) { score = s; }
	public int compareTo(Object o) {
	    Sequence s = (Sequence)o;
	    if(score<s.score) return 1;
	    else if(score==s.score) return 0;
	    else return -1;
	}
	public Sequence copy() {
	    Sequence s = new Sequence(score);
	    s.addAll(this);
	    return s;
	}

	public void add(String t, double d) {
	    super.add(t);
	    score*=d;
	}
	public String toString() { return super.toString() + " " + score; }
    }

    public List bestSequence (List words) {
	int n = words.size();
	int N = 3;
	Sequence s = new Sequence();
	SortedSet[] h = new SortedSet[n+1];
	
	for(int i=0; i<h.length; i++)
	    h[i] = new TreeSet();

	h[0].add(new Sequence());

	for(int i=0; i<n; i++) {
	    int sz = Math.min(N, h[i].size());
	    for(int j=1; j<=sz; j++) {
		Sequence top = (Sequence)h[i].first();
		h[i].remove(top);
		Object[] params = {words, top, new Integer(i)};
		double[] scores = _posModel.eval(_contextGen.getContext(params));
		for(int p=0; p<scores.length; p++) {
		    if (!_useClosedClassTagsFilter
			|| _closedClassTagsFilter.filter(
			      (String)words.get(i),
			      _posModel.getOutcome(p))) {
			Sequence newS = top.copy();
			newS.add(_posModel.getOutcome(p), scores[p]);
			h[i+1].add(newS);
		    }
		}
	    }
	}

	return (List)h[n].first();
    }
    
    
    public Set requires() {
	Set set = new HashSet();
	set.add(Tokenizer.class);
	return set;
    }

    public static void main(String[] args) throws IOException {
	if (args[0].equals("-test")) {
	    System.out.println(new POSTaggerME(new SuffixSensitiveGISModelReader(new File(args[1])).getModel()).tag(args[3]));
	    return;
	}
	else {
	    TrainEval.run(args, new POSTaggerME());
	}
    }
}
