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
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU Lesser General Public
// License along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
//////////////////////////////////////////////////////////////////////////////

package opennlp.grokkit;

import java.io.*;
import java.util.*;

import opennlp.grokkit.*;
import opennlp.common.generate.*;
import opennlp.common.parse.*;
import opennlp.common.*;

import opennlp.grok.*;
import opennlp.grok.parse.*;
import opennlp.grok.util.*;
import opennlp.grok.lexicon.*;
import opennlp.grokkit.gui.*;

public class Run {

    static Properties DEFAULTS = new Properties();
    static Parameters PARAMS;

    static {
	PARAMS = new Parameters(DEFAULTS);
    }


    public static void loadParameters() {
	loadStandard();
    }
    public static void saveParameters() {
	saveStandard();
    }

    public static void loadStandard() {
	String dir = System.getProperties().getProperty("user.home")+"/.grok";
	String file= dir + "/grok";
	try {
	    PARAMS.load(new FileInputStream(file));
	}
	catch(Exception E) {
	    File grokDir = new File(dir);
	    grokDir.mkdir();
	}
    }
    public static void saveStandard() {
	String file=
	    System.getProperties().getProperty("user.home") + "/.grok/grok";
	try {
	    PARAMS.store(new FileOutputStream(file),
			 "Standard Paramters for Grok");
	} catch (Exception E) { System.out.println(E); }
    }

    public static void init() throws IOException,
	LexException, PipelineException {
    }

    public static void process(String input)
	throws IOException, LexException {
	try {
	    if (input.equals("q"))
		System.exit(0);
	    else if (input.equals("n"))
		// agent.nextDerivation()
		    ;
	    else {
		System.out.println("Parsing `" + input + "'...");
	    }

	    System.out.println("Syntactic Category");
	    System.out.println("------------------");
	    System.out.println();
	    if(Params.getBoolean("Parsing:Semantics")) {
		System.out.println("Semantic Category");
		System.out.println("-----------------");
		System.out.println();
	 	String presups = "";
		if(!presups.equals("")) {
		    System.out.println("Presuppositions");
		    System.out.println("---------------");
		    System.out.println(presups);
		    System.out.println();
		}
		if(Params.getBoolean("Use Brain")) {
		    System.out.println("Discourse");
		    System.out.println("---------");
	 //	    System.out.println(agent.getDiscourse());
		    System.out.println();
		}
	    }
	}
	catch (Exception pe) {
	    System.out.println(pe);
	}
    }
    
    public static void main(String[] args)
	throws IOException, LexException, PipelineException {
	loadParameters();
	init();
	InputStreamReader isr = new InputStreamReader(System.in);
	BufferedReader    br  = new BufferedReader(isr);

	while(true) {
	    System.out.print("grok> ");
	    String input = br.readLine();
	    process(input);
	}
    }
}
