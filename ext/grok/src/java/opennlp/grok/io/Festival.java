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

package opennlp.grok.io;

import opennlp.common.generate.*;

import java.io.*;
import java.util.*;

/**
 * A shell for communicating with the Festival speech synthesis program.
 *
 * @author      Gann Bierner
 * @version     $Revision$, $Date$
 */
public class Festival implements Synthesizer {
    PrintStream utter;
    BufferedReader hear;
    
    public Festival() { }

    public void clear() {};

    public void open() {
	Process festival=null;
	try { festival = Runtime.getRuntime().exec("festival"); }
	catch (java.io.IOException IOE) { System.out.println(IOE); }
	utter = new PrintStream(festival.getOutputStream());
	
	utter.println("(voice_us1_mbrola)");
	utter.println("(require 'tobi)");
	utter.println("(require 'tobi_rules)");
	utter.println("(setup_tobi_f0_method)");
	utter.println("(Parameter.set 'Default_Topline 200)");
	utter.println("(Parameter.set 'Default_Start_Baseline 150)");
	utter.println("(Parameter.set 'Current_Topline"+
		      "(Parameter.get 'Default_Topline))");
	utter.println("(Parameter.set 'Valley_Dip 130)");
	utter.flush();
    }

    public void close() {
	// print eof to say we are done
	utter.println("(exit)");
	utter.flush();	
    }

    private String getTone(String s) {
	if(s.endsWith("%"))
	    return s.substring(0,1) + "-" + s.substring(1);
	else return null;
    }
    

    public void speak(String s) {
	StringTokenizer st = new StringTokenizer(s);
	ArrayList words = new ArrayList();
	while (st.hasMoreTokens())
	    words.add(st.nextToken().trim());

	String sentence = "";
	for(int i=0; i<words.size(); i++) {
	    String word = (String)words.get(i);
	    int index = word.indexOf("_");
	    String accent=null;
	    String tone=null;
	    // has accent
	    if(index != -1) {
		accent = word.substring(index+1);
		word = word.substring(0, index);
		// this is very temporary
		if(accent.endsWith("2"))
		    accent = accent.substring(0, accent.length()-1);
		// is there a boundary tone next?  Must combine here
		if(i<words.size()-1) tone = getTone((String)words.get(i+1));
		String newWord = "(" + word + "((accent " + accent + ")";
		if(tone!=null) newWord += "(tone " + tone + ")";
		newWord+="))";
		sentence += newWord + " ";
	    }
	    // boundary tone
	    else if(word.endsWith("%")) continue;
	    // regular word
	    else {
		// is there a boundary tone next?  Must combine here
		if(i<words.size()-1) tone = getTone((String)words.get(i+1));
		if(tone!=null) sentence += "("+word+"((tone "+tone+")))";
		else sentence += word + " ";
	    }
	    
	}
	utter.println("(set! utt (Utterance Words (" + sentence + ")))");
	utter.println("(utt.synth utt)");
	utter.println("(utt.play utt)");
	utter.flush();	
    }

    public static void main(String[] args) {
//	  Mouth fest = new Festival();
//	  fest.open();
//	  fest.speak("John likes LH% spam_H* LL%");
//	  try{Thread.sleep(5000);} catch(Exception E){}
//	  fest.close();
    }
}
