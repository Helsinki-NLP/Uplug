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

package opennlp.grok.preprocess.cattag;

import java.io.*;
import java.util.*;

import org.jdom.*;

import opennlp.common.preprocess.*;
import opennlp.common.xml.*;
import opennlp.common.util.*;

import opennlp.maxent.*;
import opennlp.maxent.io.*;
import opennlp.grok.preprocess.postag.*;

/**
 * Tags words with a category (from categorial grammar) based on their
 * surrounding contexts and a maximum entropy model.  This is very similar to
 * "supertagging" from work in the Tree Adjoining Grammar tradition
 * (e.g. Bangalore's U. of Pennsylvania Ph.D.).
 *
 * @author      Gann Bierner
 * @version     $Revision$, $Date$
 */

public class CatterME implements Evalable, POSTagger {

    /**
     * The maximum entropy model to use to evaluate contexts.
     */
    protected MaxentModel model;

    /**
     * The feature context generator.
     */
    protected final ContextGenerator cg = new POSContextGenerator();

    protected CatterME () {}
    
    public CatterME (MaxentModel mod) {
	model = mod;
    }

    public String getNegativeOutcome() { return ""; }
    public EventCollector getEventCollector(Reader r) {
	return new CatEventCollector(r);
    }
	
    /**
     * Label the words in a document with categories.
     */
    public void process(NLPDocument doc){
	for (Iterator sentIt=doc.sentenceIterator(); sentIt.hasNext();) {
	    Element sentEl = (Element)sentIt.next();
	    List wordEls = doc.getWordElements(sentEl);
	    List words = new ArrayList(wordEls.size());
	    for (Iterator wordIt=wordEls.iterator(); wordIt.hasNext();)
		words.add(((Element)wordIt.next()).getText());
	    List tags = bestSequence(words, model, cg);
	    int index = 0;
	    for (Iterator wordIt=wordEls.iterator(); wordIt.hasNext();) {
		((Element)wordIt.next()).
		    setAttribute("cat", (String)tags.get(index++));
	    }
	}
    }


    
    
    public List tag(List sentence) {
	return bestSequence(sentence, model, cg);
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
	    sb.append(toks.get(i) + "|" + tags.get(i) + " ");
	return sb.toString().trim();
    }

    public void localEval(MaxentModel model, Reader r,
			  Evalable e, boolean verbose) {
	float total=0, correct=0, sentences=0, sentsCorrect=0, independent=0;

	BufferedReader br = new BufferedReader(r);
	String line;
	ArrayList contexts = new ArrayList();
	try {
	    while((line=br.readLine())!=null) {
		sentences++;
		Pair p = CatEventCollector.convertAnnotatedString(line);
		List words = (List)p.a;
		List outcomes = (List)p.b;
		List tags = bestSequence(words, model, cg);
		
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
    static class Sequence extends ArrayList implements Comparable {
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

    public static List bestSequence(List words, MaxentModel model,
				    ContextGenerator cg) {
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
		double[] scores = model.eval(cg.getContext(params));
		for(int p=0; p<scores.length; p++) {
		    Sequence newS = top.copy();
		    newS.add(model.getOutcome(p), scores[p]);
		    h[i+1].add(newS);
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
	/**
	 * Example calls: 
	 * <p>
	 * java -mx1024m opennlp.grok.preprocess.cattag.CatterME -t -d ./ -s EnglishCatter.bin.gz -c 10 /data/catter.train7
	 * <p>
	 * java -mx1024m opennlp.grok.preprocess.cattag.CatterME -use CattagModel.bin.gz "The company invested 1.5 million dollars in its subsidiary ."
 	 *
	 * -c is for cutoff, -d is for output directory, -t means to train, and the final argument is the data file.
	 */
	if (args[0].equals("-use")) {
	    try {
		System.out.println(
		    new CatterME(new SuffixSensitiveGISModelReader(
		        new File(args[1])).getModel()).tag(args[2]));
	    }
	    catch (Exception e) {
		e.printStackTrace();
	    }
	}
	else {
	    TrainEval.run(args, new CatterME());
	}
    }
}
