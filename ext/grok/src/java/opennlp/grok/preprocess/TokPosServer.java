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

package opennlp.grok.preprocess;

import java.util.*;
import java.io.*;
import java.net.*;
import opennlp.grok.preprocess.tokenize.*;
import opennlp.grok.preprocess.postag.*;
import opennlp.common.preprocess.*;

class TokPosServer extends Thread {
    private Socket socket;
    private POSTagger tagger = new EnglishPOSTaggerME();
    private Tokenizer tokenizer = new EnglishTokenizerME();
    private int responseCode = 619;

    public TokPosServer(Socket s, int c) {
        super("TokPosTaggerThread");
	responseCode = c;
        socket = s;
    }

    public static String getMessage(DataInputStream in)  {
	int inLen = 0;
	int totalAmtRead = 0;
	boolean RC = true;
	
	try {
	    inLen = in.readInt();
	    byte input[] = new byte[inLen];	
	    
	    // get the actual response
	    if (inLen < 100000)  {
		in.readFully(input, 0, inLen);
		return new String(input);
	    } else {
		return null;
	    }
	} catch(Exception e) {
	    return null;
	}
    }
    
    public void run() {
        try {
            PrintWriter out = new PrintWriter(socket.getOutputStream(), true);
	    DataOutputStream binaryOut = new DataOutputStream(socket.getOutputStream());	    
	    DataInputStream in = new DataInputStream(socket.getInputStream());
	    try {
		String line;
		//while((line=in.readLine())!=null) {
		while((line=getMessage(in))!=null) {		
		    if(line.length() == 0)
			continue;

		    line=line.substring(4);

		    if(line.endsWith("?") || line.endsWith(".") ||
		       line.endsWith("!")) {
			line = line.substring(0, line.length()-1) + " " + line.substring(line.length()-1);
		    }

		    String[] tokens = tokenizer.tokenize(line);
		    String[] tags = tagger.tag(tokens);
		    StringBuffer message = new StringBuffer();
		    message.append(tokens[0] + "_" + tags[0]);
		    for(int i=1; i<tokens.length; i++)
			    message.append(" " + tokens[i]+"_"+tags[i]);
		    
		    String messageStr = responseCode + " "  + message.toString();
		    binaryOut.writeInt(messageStr.length());
		    
		    out.print(messageStr);
		    out.flush();
		}
	    } catch (Exception E) { out.println("Error: " + E); }
	      finally {
	          System.out.println("Closing connection");
		  out.close();
		  in.close();
		  socket.close();
	      }
        } catch (IOException e) {
            e.printStackTrace();
        }
   } 

    public static void main(String[] args) throws IOException {
	ServerSocket serverSocket = null;
	boolean listening = true;
	int port = 1059;
	int code = 619;

	gnu.getopt.Getopt g =
	    new gnu.getopt.Getopt("PipeClient", args, "p:c:");
	int c;
	while ((c = g.getopt()) != -1) {
	    switch(c) {
	    case 'p':
		port = Integer.parseInt(g.getOptarg());
		break;
	    case 'c':
		code = Integer.parseInt(g.getOptarg());
		break;
	    }
	}
	
	try {
	    serverSocket = new ServerSocket(port);
	} catch (IOException e) {
	    System.err.println("Could not listen on port: " + port);
	    System.exit(-1);
	}
	
	while (listening) {
	    System.out.println("Waiting for Connection");
	    new TokPosServer(serverSocket.accept(), code).start();
	    //new TokPosServer(serverSocket.accept()).run();
	}
	serverSocket.close();
    }
    
}
