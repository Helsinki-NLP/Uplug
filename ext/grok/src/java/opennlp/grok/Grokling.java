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
package opennlp.grok;

import opennlp.grok.io.*;
import opennlp.grok.lexicon.*;
import opennlp.grok.grammar.*;
import opennlp.grok.parse.*;
import opennlp.grok.util.*;
import opennlp.grok.expression.*;
import opennlp.common.*;
import opennlp.common.parse.*;
import opennlp.common.synsem.*;
import opennlp.common.unify.*;
import opennlp.common.util.*;

import java.io.*;
import java.net.*;
import java.util.*;

/**
 * Grokling is an easy entry point into the Grok library for parsing.
 *
 * @author  Jason Baldridge
 * @version $Revision$, $Date$ */
public class Grokling {

    public boolean interpreting = false;
    public boolean showSyntax = true;
    public boolean showSemantics = false;
    
    private Properties _grammarInfo = new Properties();
    private Parser _parser;
    
    private Pipeline _pipeline;

    private String[] ppLinks = {
	"opennlp.grok.preprocess.sentdetect.EnglishSentenceDetectorME" ,
	"opennlp.grok.preprocess.tokenize.EnglishTokenizerME"
    };

    //private String[] ppLinks = {
    //	  "opennlp.grok.preprocess.sentdetect.EnglishSentenceDetectorME" ,
    //	  "opennlp.grok.preprocess.tokenize.EnglishTokenizerME" ,
    //	  "opennlp.grok.preprocess.namefind.EmailDetector" ,
    //	  "opennlp.grok.preprocess.namefind.EnglishNameFinderME"
    //}; 

    public Grokling(Lexicon lexicon, RuleGroup rules) {
	_parser = new CKY(lexicon, rules);
    }
    
    public Grokling(URL grammar) throws IOException, PipelineException {

	loadGrammar(grammar);
	
	Params.setProperty("Enable:Databases", "false");
	Params.setProperty("Results:All Derivs", "false");
	//Params.setProperty("Display:Features", "true");
	//Params.setProperty("Results:Filter","[s:XXX]");
	
	System.out.print("Loading Lex... ");
	Lexicon lexicon = new LMRLexicon(_grammarInfo);

	System.out.print("Rules... ");
	RuleGroup rules = RuleReader.getRules(_grammarInfo.getProperty("rules"));
	_parser = new CKY(lexicon, rules);

	System.out.println("Pipeline... ");
	_pipeline = new Pipeline(ppLinks);
    }

    
    public Pair[] grok (String s) throws ParseException, PipelineException {

	if(s.equals("")) throw new ParseException("Nothing to Parse!");
	interpreting = true;
	opennlp.common.xml.NLPDocument doc = _pipeline.run(s);
	//System.out.println(doc);
	_parser.parse(doc); 

	//interps = _parser.getResult();
	//interps = _parser.getFilteredResult();
	ArrayList interps = getPreferredResult(_parser.getResult());
	if (interps.isEmpty()) {
	    throw new ParseException("No result ");
	}

	Pair[] answers = new Pair[interps.size()];
	for (int curIndex=0; curIndex<answers.length; curIndex++) {
	    Sign constit = (Sign)interps.get(curIndex);
	    answers[curIndex] = 
		new Pair(constit.getCategory().toString(), "no LF");
	}
	return answers;
    }

    public String[] grokAndReturnStrings(String sentence)
	throws	LexException, ParseException,
	IOException, PipelineException {

	Pair[] res = grok(sentence);
	String[] s = new String[res.length];
	if (showSyntax && showSemantics) {
	    for (int i=0; i< res.length; i++)
		s[i] = res[i].a.toString() + " : " + res[i].b.toString();
	}
	else if (showSemantics) {
	    for (int i=0; i< res.length; i++)
		s[i] = res[i].b.toString();
	}
	else {
	    for (int i=0; i< res.length; i++)
		s[i] = res[i].a.toString();
	}
	return s;
    }
    
    private ArrayList getPreferredResult(ArrayList unranked) {
	ArrayList reranked = new ArrayList();
	for(Iterator i=unranked.iterator(); i.hasNext();) {
	    Sign w=(Sign)i.next();
	    Category syn =w.getCategory();
	    if (syn instanceof AtomCat) {
		String type = ((AtomCat)syn).getType();
		if (type.equals("s")) {
		    reranked.add(w);
		    i.remove();
		}
	    }
	}
	for(Iterator i=unranked.iterator(); i.hasNext();) {
	    Sign w=(Sign)i.next();
	    Category syn =w.getCategory();
	    if (syn instanceof AtomCat) {
		String type = ((AtomCat)syn).getType();
		if (type.equals("n")) {
		    reranked.add(w);
		    i.remove();
		}
	    }
	}
	reranked.addAll(unranked);
	return reranked;
    }

    
    private void loadGrammar(URL grammar) throws IOException {
	_grammarInfo.load(grammar.openStream());
	
	String gram = grammar.toString();
	String dir = gram.substring(0, gram.lastIndexOf('/'));
	
	for(Iterator it = _grammarInfo.keySet().iterator(); it.hasNext();) {
	    String key = (String)it.next();
	    String file = _grammarInfo.getProperty(key);
	    if(file.charAt(0)=='/')
		_grammarInfo.setProperty(key, "file:"+file);
	    else
		_grammarInfo.setProperty(key, dir+"/"+file);
	}
    }


    private static String flattenStringArray(String[] a) {
	String f = "";
	for (int i=1; i<=a.length; i++)
	    f += "Interpretation " + i + ":\n " + a[i-1] + "\n\n";
	return f;
    }
    
    public static void main(String[] args) 
	throws IOException, LexException, PipelineException {
	
	if (args.length == 0) {
	    System.out.println("\nUsage: java opennlp.grok.Grokling <grammar file>\n");
	    System.exit(0);
	}

	String gram = args[0];
	if (gram.charAt(0) == '/') {
	    gram="file:"+gram;
	}
	else {
	    gram = "file:"+System.getProperty("user.dir")+"/"+gram;
	}
	System.out.println("Loading grammar at URL: " + gram);

	Grokling g = null;
	try {	
	    g = new Grokling(new URL(gram));
	} catch (PipelineException ple) {
	    System.out.println("Something wrong with preprocessing pipeline: "
			       + ple.toString());
	    System.exit(0);
	}


	BufferedReader br =
	    new BufferedReader(new InputStreamReader(System.in));

	boolean showall = false;
	System.out.println("\nEnter sentences to parse. Ctrl-C to quit.\n");
	while(true) {
	    try {
		System.out.print("grok> ");
		String input = br.readLine();
		if (input.equals(":filter off")
		    || input.equals(":foff")) {	
		    Params.setProperty("Results:Use Filter", "false");
		} else if (input.equals(":filter on")
			   || input.equals(":fon")) {
		    Params.setProperty("Results:Use Filter", "true");
		} else if (input.equals(":debug on")
			   || input.equals(":don")) {
		    //Debug.Register("Chart Parser", true);
		    //Debug.Register("Lexicon", true);
		    Debug.Register("Apply Rule", true);
		    //Debug.Register("Unify", true);
		    //Params.register("Display:CKY Chart", "true");
		} else if (input.equals(":debug off")
			   || input.equals(":doff")) {
		    Debug.Register("Chart Parser", false);
		    Debug.Register("Lexicon", false);
		} else if (input.equals(":show feats")
			   || input.equals(":feats")) {
		    Params.setProperty("Display:Features", "true");
		} else if (input.equals(":show syntax")
			   || input.equals(":syn")) {
		    g.showSyntax = true;
		} else if (input.equals(":show all")
			   || input.equals(":all")) {
		    showall = true;
		} else if (input.equals(":show best")
			   || input.equals(":best")) {
		    showall = false;
		} else {		
		    String[] sa = g.grokAndReturnStrings(input);
		    int resLength = sa.length;
		    switch (resLength) {
		    case 0: break;
		    case 1: 
			System.out.println(resLength + " parse found."); 
			break;
		    default: System.out.println(resLength + " parses found."); 
		    }

		    if (showall) {
			for (int i=0; i<resLength; i++)
			    System.out.println(sa[i]);
		    }
		    else
			System.out.println(sa[0]);
		}
	    }
	    catch(ParseException pe) {
		System.out.println(pe);
	    }
	}
    }
    
}

