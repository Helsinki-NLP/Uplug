///////////////////////////////////////////////////////////////////////////////
// Copyright (C) 2000 Jason Baldridge and Gann Bierner
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

import opennlp.common.*;
import opennlp.common.preprocess.*;
import opennlp.common.xml.*;
import java.util.*;
import java.io.*;
import java.net.*;


/**
 * A pipeline useable as a server for processing documents.
 *
 * @author      Gann Bierner
 * @version     $Revision$, $Date$
 **/
public class PipelineServer {    

    public static void main (String[] args)
	throws PipelineException, IOException  {

	Object input=null;
	boolean server = false;
	int port = 1058;
	gnu.getopt.Getopt g =
	    new gnu.getopt.Getopt("opennlp", args, "f:i:sp:");
	int c;
	while ((c = g.getopt()) != -1) {
	    switch(c) {
	    case 'f':
		input = new File(g.getOptarg());
		break;
	    case 'i':
		input = g.getOptarg();
		break;
	    case 's':
		server = true;
		break;
	    case 'p':
		port = Integer.parseInt(g.getOptarg());
		break;
	    }
	}
	
	if (!server && input==null) {
	    throw new PipelineException("No input specified");
	}

	   
	String[] nonOptArgs = new String[args.length-g.getOptind()];
	int optind = g.getOptind();
	for (int i=optind; i<args.length; i++) {
	    nonOptArgs[i-optind] = args[i];
	}

	Pipeline pipe = new Pipeline(nonOptArgs);
	
	if (!server) {
	    NLPDocument doc = pipe.run(input);
	    System.out.println(doc.toXml());
	} else {
	    ServerSocket serverSocket = null;
	    boolean listening = true;
	    
	    try {
		serverSocket = new ServerSocket(port);
	    } catch (IOException e) {
		System.err.println("Could not listen on port: " + port);
		System.exit(-1);
	    }
	    
	    while (listening) {
		System.out.println("Waiting for Connection");
		new PipelineServerThread(serverSocket.accept(), pipe).start();
	    }
	    serverSocket.close();
	}
    }
}

class PipelineServerThread extends Thread {
    private Socket socket;
    private Pipeline pipeline;
    
    public PipelineServerThread(Socket s, Pipeline p) {
        super("PipelineServerThread");
        socket = s;
	pipeline = p;
    }

    public void run() {
        try {
            PrintWriter out = new PrintWriter(socket.getOutputStream(), true);
	    BufferedReader in = new BufferedReader(new InputStreamReader(
						 socket.getInputStream()));
	    try {
		StringBuffer ans = new StringBuffer();
		String line;
		while(!(line=in.readLine()).equals("@OVER@")) {
		    ans.append(line + "\n");
		}
		NLPDocument doc = pipeline.run(ans.toString());
		System.out.println("sending document...");
		out.println(doc.toXml());
	    } catch (Exception e) {
		out.println("Error: " + e);
	    } finally {
		out.close();
		in.close();
		socket.close();
	    }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
