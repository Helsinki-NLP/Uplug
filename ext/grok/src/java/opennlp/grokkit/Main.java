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

import opennlp.common.parse.*;
import opennlp.common.*;
import opennlp.common.synsem.*;

import opennlp.grok.*;
import opennlp.grok.io.*;

public class Main {

    public static void help() {
	BufferedReader br = new BufferedReader(new InputStreamReader(
			    Main.class.getResourceAsStream("data/help")));
	String line;
	try{
	    while((line=br.readLine())!=null)
		System.out.println(line);
	} catch(Exception E) {}
    }
    
    public static void main(String[] args) {
	try{
	    String mode = "gui";
	    gnu.getopt.Getopt g =
		new gnu.getopt.Getopt("grok", args, "hm:");
	    int c;
	    while ((c = g.getopt()) != -1) {
		switch(c) {
		case 'm':
		    String m = g.getOptarg();
		    mode = m;
		    break;
		case 'h':
		    help();
		    System.exit(0);
		}
	    }
	    String[] nonOptArgs = new String[args.length-g.getOptind()];
	    int optind = g.getOptind();
	    for (int i = optind; i < args.length ; i++) {
		nonOptArgs[i-optind] = args[i];
	    }
	    

	    if(mode.equals("text"))
		Run.main(nonOptArgs);
	    else if(mode.equals("gui"))
		Grok.main(nonOptArgs);
	    //else if(mode.equals("regress"))
	    //    Regression.main(nonOptArgs);
	    else if(mode.equals("pipe"))
		{ Pipeline p = new Pipeline(nonOptArgs);
		p.verify();
		p.run(nonOptArgs);
		}
	    
	} catch(Exception e) {
	    System.out.println("outside " + e); e.printStackTrace();
	}
    }
}
