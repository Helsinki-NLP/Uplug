///////////////////////////////////////////////////////////////////////////////
// Copyright (C) 2002 Joerg Tiedemann
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

package opennlp.grok.preprocess.chunk;

import java.io.*;
import java.text.*;
import java.util.*;

import org.jdom.*;

import opennlp.common.preprocess.*;
import opennlp.common.xml.*;
import opennlp.common.util.*;

import opennlp.maxent.*;
import opennlp.maxent.io.*;

/**
 * A shallow parser that uses maximum entropy.  Trys to predict whether
 * words are in chunks depending on their surrounding context.
 *
 * @author     Joerg Tiedemann
 * @version $Revision$, $Date$
 */
public class ChunkerME implements Evalable, POSTagger {

    /**
     * The maximum entropy model to use to evaluate contexts.
     */
    protected MaxentModel _chunkModel;

    /**
     * The feature context generator.
     */
    protected ContextGenerator _contextGen = new ChunkerContextGenerator();

    /**
     * Decides whether a word can be assigned a particular closed class tag.
     */
    protected FilterFcn _closedClassTagsFilter;

    
    /**
     * Says whether a filter should be used to check whether a tag assignment
     * is to a word outside of a closed class.
     */
    protected boolean _useClosedClassTagsFilter = false;
    
    
    protected ChunkerME () {}

    public ChunkerME (MaxentModel mod) {
	this(mod, new ChunkerContextGenerator());
    }
    
    public ChunkerME (MaxentModel mod, ContextGenerator cg) {
	_chunkModel = mod;
	_contextGen = cg;
    }

    public String getNegativeOutcome() { return ""; }
    public EventCollector getEventCollector(Reader r) {
       	return new ChunkerEventCollector(r,_contextGen);
    }
    
	

    /**
     * creates chunk tags in a document.
     */

    public void process(NLPDocument doc){
	for (Iterator sentIt=doc.sentenceIterator(); sentIt.hasNext();) {
	    Element sentEl = (Element)sentIt.next();
	    List wordEls = doc.getWordElements(sentEl);
	    List words = new ArrayList(wordEls.size());
	    List pos = new ArrayList(wordEls.size());
	    for (Iterator wordIt=wordEls.iterator(); wordIt.hasNext();){
		Element word=(Element)wordIt.next();
		words.add(word.getText());
		pos.add(word.getAttributeValue("pos"));
	    }
	    List tags = bestSequence(words,pos);

	    for(int i=0; i<tags.size(); i++) {
		String tag = (String)tags.get(i);
		//		if (tag.charAt(0) == 'B') {
		if ((tag.charAt(0) == 'B') ||
		    (tag.charAt(0) == 'I')) {

		    Element wordEl = (Element)wordEls.get(i);
		    Element parentToken =
			(Element)wordEl.getParent();
		    int split = tag.lastIndexOf("-");
		    if (split>0){
			String type = tag.substring(split+1);
			Element chunkEl = new Element("chunk");
			chunkEl.setAttribute("type", type);
			//	    Element token = NLPDocument.createTOK("");
			Element token = new Element("t");
			token.addContent(wordEl.detach());
			chunkEl.addContent(token);
			while (++i < tags.size() && 
			       ((String)tags.get(i)).charAt(0) == 'I') {
			    wordEl = (Element)wordEls.get(i);
			    chunkEl.addContent(wordEl.getParent().detach());
			}
			XmlUtils.replace(parentToken,chunkEl);
			i--;
		    }
		}
	    }
	}
    }


    public void processSimple (NLPDocument doc){
	for (Iterator sentIt=doc.sentenceIterator(); sentIt.hasNext();) {
	    Element sentEl = (Element)sentIt.next();
	    List wordEls = doc.getWordElements(sentEl);
	    List words = new ArrayList(wordEls.size());
	    List pos = new ArrayList(wordEls.size());
	    for (Iterator wordIt=wordEls.iterator(); wordIt.hasNext();){
		Element word=(Element)wordIt.next();
		words.add(word.getText());
		pos.add(word.getAttributeValue("pos"));
	    }
	    List tags = bestSequence(words,pos);
	    int index = 0;
	    for (Iterator wordIt=wordEls.iterator(); wordIt.hasNext();) {
		((Element)wordIt.next()).
		    setAttribute("chunk", (String)tags.get(index++));
	    }
	}
    }

    private static Pair split(String s) {
	int split = s.lastIndexOf("/");
	if (split == -1) {
	    System.out.println("There is a problem in your training data: "
			       + s
			       + " does not conform to the format WORD/TAG.");
	    return new Pair(s, "UNKNOWN");
	}
	return new Pair(s.substring(0, split), s.substring(split+1));
    }
    
    public List tag(List sentence,List pos) {
	return bestSequence(sentence,pos);
    }

    public List tag(List sentence) {

	List s = new ArrayList();
	List p = new ArrayList();
	for(int i=0; i<sentence.size(); i++) {
	    Pair pair = split((String)sentence.get(i));
	    s.add(pair.a);
	    p.add(pair.b);
	}
	return tag(s,p);
    }


    public String[] tag(String[] sentence) {
	ArrayList l = new ArrayList();
	ArrayList p = new ArrayList();
	for(int i=0; i<sentence.length; i++){
	    Pair pair = split((String)sentence[i]);
	    l.add(pair.a);
	    p.add(pair.b);
	}
	List t = tag(l,p);
	
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


    public String tagTest(String sentence) {
	ArrayList toks = new ArrayList();
	ArrayList correct = new ArrayList();
	StringTokenizer st = new StringTokenizer(sentence);
	while(st.hasMoreTokens()){
	    Pair pair = split((String)st.nextToken());
	    toks.add(pair.a);
	    correct.add(pair.b);
	}
	List tags = tag(toks);
	StringBuffer sb = new StringBuffer();
	for(int i=0; i<tags.size(); i++)
	    sb.append(toks.get(i) + " " + correct.get(i) + " " + tags.get(i) + "\n");
	return sb.toString().trim();
    }


    private static void increment(Hashtable hash, String key){
	int value=0;
	if (key != null){
	    if (hash.containsKey(key))
		value = Integer.parseInt((String)hash.get(key));
	    value++;
	    hash.put(key, Integer.toString(value));
	}
    }

    private static boolean chunkStart(String loc,String prevLoc,
				   String type,String prevType){
	if (loc.charAt(0)=='B') return true;
	if (loc.charAt(0)=='I' && prevLoc.charAt(0)=='O') return true;
	if (loc.charAt(0)!='O' && !type.equals(prevType)) return true;
	return false;
    }

    private static boolean chunkEnd(String loc,String prevLoc,
				   String type,String prevType){
	if (loc.charAt(0)=='B' || loc.charAt(0)=='O') return true;
	if (loc.charAt(0)!='O' && !type.equals(prevType)) return true;
	return false;
    }

    public void localEval(MaxentModel chunkModel, Reader r,
			  Evalable e, boolean verbose) {
	_chunkModel = chunkModel;
	BufferedReader br = new BufferedReader(r);
	String line;
	float nrSent=0,nrWords=0,nrCorrectSent=0,nrCorrectTags=0;
	Hashtable nrCorrectChunks=new Hashtable();
	Hashtable nrMarkedChunks=new Hashtable();
	Hashtable nrCorrectMarkedChunks=new Hashtable();
	boolean currentChunk;
	String chunkType;

	try {
	    while((line=br.readLine())!=null) {
		nrSent++;
		ArrayList toks = new ArrayList();
		ArrayList pos = new ArrayList();
		ArrayList label = new ArrayList();
		StringTokenizer st = new StringTokenizer(line);
		while(st.hasMoreTokens()){
		    nrWords++;
		    Pair pair = split((String)st.nextToken());
		    label.add(pair.b);
		    pair = split((String)pair.a);
		    toks.add(pair.a);
		    pos.add(pair.b);
		}
		List tags = tag(toks,pos);
		StringBuffer sb = new StringBuffer();
		String prevCorrect="O";
		String prevGuessed="O";
		String prevCorrectType=null;
		String prevGuessedType=null;
		boolean correctChunk=false;
		for(int i=0; i<tags.size(); i++){
		    String guessed=(String)tags.get(i);
		    String correct=(String)label.get(i);
		    // System.out.println(correct + ' ' + guessed);
		    int split = guessed.lastIndexOf("-");
		    String guessedType = guessed.substring(split+1);
		    split = correct.lastIndexOf("-");
		    String correctType = correct.substring(split+1);


		    // check if there is a chunk border before the current tag
		    boolean correctEnd=false,guessedEnd=false;
		    if (prevCorrectType != null)
			correctEnd=chunkEnd(correct,prevCorrect,
					    correctType,prevCorrectType);
		    if (prevGuessedType != null)
			guessedEnd=chunkEnd(guessed,prevGuessed,
					    guessedType,prevGuessedType);
		    if (correctChunk){
			if (correctEnd && guessedEnd &&
			    prevCorrectType.equals(prevGuessedType)){
			    increment(nrCorrectMarkedChunks,prevGuessedType);
			    correctChunk=false;
			}
			else{
			    if ((correctEnd != guessedEnd) ||
				!correctType.equals(guessedType)){
				correctChunk=false;
			    }
			}
		    }

		    // check i a new chunk starts
		    boolean correctStart=
			chunkStart(correct,prevCorrect,
				   correctType,correctType);
		    boolean guessedStart=
			chunkStart(guessed,prevGuessed,
				   guessedType,guessedType);
		    
		    if (correctStart)
			increment(nrCorrectChunks,correctType);
		    if (guessedStart){
			increment(nrMarkedChunks,guessedType);
			if (correctStart && correctType.equals(guessedType)){
			    correctChunk=true;
			}
		    }

		    prevCorrect=correct;
		    prevGuessed=guessed;
		    prevCorrectType=correctType;
		    prevGuessedType=guessedType;

		    if (correct.charAt(0) == 'O') prevCorrectType=null;
		    if (guessed.charAt(0) == 'O') prevGuessedType=null;

		    if(guessed.equals(correct)){
			nrCorrectTags++;
		    }
		}
		if (correctChunk){
		    increment(nrCorrectMarkedChunks,prevGuessedType);
		}
	    }
	} catch (IOException E) { E.printStackTrace(); }
	
	System.out.println("\tphrase\tprecision\trecall\t\tFB1");

	DecimalFormat format = new DecimalFormat("#0.0000");
	FieldPosition field = new FieldPosition(0);

	float totalNrCorrect=0,totalNrMarked=0,totalNrCorrectMarked=0;
	float pre,rec,f;
	for (Enumeration en=nrCorrectChunks.keys() ; en.hasMoreElements() ;) {
	    String key=(String)en.nextElement();
	    float a=0,b=0,c=0;
	    if (nrCorrectChunks.containsKey(key))
		a = Integer.parseInt((String)nrCorrectChunks.get(key));
	    if (nrMarkedChunks.containsKey(key))
		b = Integer.parseInt((String)nrMarkedChunks.get(key));
	    if (nrCorrectMarkedChunks.containsKey(key))
		c = Integer.parseInt((String)nrCorrectMarkedChunks.get(key));
	    totalNrCorrect+=a;
	    totalNrMarked+=b;
	    totalNrCorrectMarked+=c;
	    pre=c/b;
	    rec=c/a;
	    f=2*pre*rec/(pre+rec);
	    StringBuffer pr = new StringBuffer();
	    format.format(pre, pr, field);
	    StringBuffer re = new StringBuffer();
	    format.format(rec, re, field);
	    StringBuffer fb = new StringBuffer();
	    format.format(f, fb, field);

	    System.out.println("\t"+ key + "\t" + pr + "\t\t"+re+"\t\t"+fb);
	}

	pre=totalNrCorrectMarked/totalNrMarked;
	rec=totalNrCorrectMarked/totalNrCorrect;
	f=2*pre*rec/(pre+rec);
	System.out.println("\ttotal"+ "\t" + pre + "\t" + rec + "\t" + f);

	System.out.println("processed " + nrWords + " tokens with " + totalNrCorrect + " phrases; found " + totalNrMarked + "; correct " + totalNrCorrectMarked);

	// System.out.println("\nnr words         : " + nrWords);
	System.out.println("\nnr correct tags  : " + nrCorrectTags);
	System.out.println("accuracy         : " + nrCorrectTags/nrWords);

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


    public List bestSequence (List words,List pos) {
	int n = words.size();
	int N = 3;
	Sequence s = new Sequence();
	SortedSet[] h = new SortedSet[n+1];

	//System.out.println(words.size() + "tokens");
	
	for(int i=0; i<h.length; i++)
	    h[i] = new TreeSet();

	h[0].add(new Sequence());

	for(int i=0; i<n; i++) {
	    int sz = Math.min(N, h[i].size());
	    for(int j=1; j<=sz; j++) {
		Sequence top = (Sequence)h[i].first();
		h[i].remove(top);
		Object[] params = {words, pos, top, new Integer(i)};
		double[] scores = _chunkModel.eval(_contextGen.getContext(params));
		for(int p=0; p<scores.length; p++) {
		    if (!_useClosedClassTagsFilter
			|| _closedClassTagsFilter.filter(
			      (String)words.get(i),
			      _chunkModel.getOutcome(p))) {
			Sequence newS = top.copy();
			newS.add(_chunkModel.getOutcome(p), scores[p]);
			h[i+1].add(newS);
		    }
		}
	    }
	}

	return (List)h[n].first();
    }

    /*    public List bestSequence (List words,List pos) {
     *
     *	ArrayList tags = new ArrayList();
     *	for (int i=0; i<words.size(); i++) {
     *	    Object[] params = {words, pos, tags, new Integer(i)};
     *	    String[] context = _contextGen.getContext(params);
     *	    tags.add(_chunkModel.getBestOutcome(_chunkModel.eval(context)));
     *	}
     *	return tags;
     *    }
     */
    
    
    public Set requires() {
	Set set = new HashSet();
	set.add(Tokenizer.class);
	return set;
    }

    public static void main(String[] args) throws IOException {
	if (args[0].equals("-test")) {
	    System.out.println(new ChunkerME(new SuffixSensitiveGISModelReader(new File(args[1])).getModel()).tag(args[3]));
	    return;
	}
	else {
	    TrainEval.run(args, new ChunkerME());
	}
    }
}
