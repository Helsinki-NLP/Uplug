///////////////////////////////////////////////////////////////////////////////
// Copyright (C) 2001 Artifactus Ltd
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
import opennlp.common.*;

/**
 * A simple example of how to set up a pipeline.
 *
 * @author      Jason Baldridge
 * @version     $Revision$, $Date$
 */
public class SimplePipe {
    
    public static void main (String[] args) {
	String toProcess;
	String s1 = "First, it's a sentence with John Smith and the date 16/01/74 in it. Now, this is another one written on Monday.\n\nFinally, this is a sentence in a new paragraph.";
	String s2 = "The Grok project is dedicated to developing a large collection of basic tools for use in natural language software. A particularly important aspect of Grok is that its natural language modules should not be ad hoc and should instead follow specific guidelines, or interfaces, so that they may be freely exchanged with other modules of the same type. To this goal, Grok provides a library of modules that implement the interfaces specified by OpenNLP.";
	
	String s3 = "Finally, this is a sentence in a new paragraph.";

	String s4 = "First, here is a sentence with John Smith in it. Now, this is another one written on Monday.";
	if (args.length == 0)
	    toProcess = s2;
	else
	    toProcess = args[0];

	String[] ppLinks = {
	    //"SimpleLink"
	    "opennlp.grok.preprocess.sentdetect.EnglishSentenceDetectorME",
	    "opennlp.grok.preprocess.tokenize.EnglishTokenizerME",
	    "opennlp.grok.preprocess.postag.EnglishPOSTaggerME",
	    "opennlp.grok.preprocess.mwe.EnglishFixedLexicalMWE",
	    "opennlp.grok.preprocess.namefind.EnglishNameFinderME"
	}; 

	Pipeline pipe = null;
	try {
	    pipe = new Pipeline(ppLinks);
	    opennlp.common.xml.NLPDocument doc = pipe.run(toProcess);
	    System.out.println(doc.toXml());
	    System.out.println(doc.toString());
	} catch (PipelineException ple) {
	    System.out.println("Pipeline error: " + ple.toString());
	    System.exit(0);
	}
    }
}
