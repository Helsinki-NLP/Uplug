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
import opennlp.grok.preprocess.sentdetect.*;
import opennlp.common.preprocess.*;

class SentDetectServer extends Thread {
    private Socket socket;
    private SentenceDetector sentdetector = new EnglishSentenceDetectorME();
    private int responseCode = 621;
    static boolean verbose = false;


    public SentDetectServer(Socket s, int c) {
        super("SentenceDetectorThread");
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
		String answer = new String(input);
		return answer;
	    } else {
		return null;
	    }
	} catch(IOException e) {
	    return null;
	} catch (Exception e2) {
		e2.printStackTrace();
		return null;
	}
    }
    
    public void run() {
        try {
            PrintWriter out = new PrintWriter(socket.getOutputStream(), true);
	    DataOutputStream binaryOut = new DataOutputStream(socket.getOutputStream());	    
	    DataInputStream in = new DataInputStream(socket.getInputStream());
	    try {
		String doc;
		while((doc=getMessage(in))!=null) {
//		      if(doc.length()>30)
//			  System.out.println(doc.substring(0, 30)+"...");
//		      else
//			  System.out.println(doc);
		    
		    if(doc.length() == 0)
			continue;

		    // get rid of code/size information
		    doc=doc.substring(4);

		    int[] sentPositions = sentdetector.sentPosDetect(doc);
		    StringBuffer message = new StringBuffer();
		    for(int i=0; i<sentPositions.length; i++) {
			    if(verbose && i>0)
				System.out.println(doc.substring(sentPositions[i-1], sentPositions[i]));
			    message.append(sentPositions[i]+"\0");
		    }
		    if(verbose)
			System.out.println(doc.substring(sentPositions[sentPositions.length-1]));
		    
		    String messageStr = responseCode + " "  + 
			    message.length() + "\0"  + message.toString();
		    binaryOut.writeInt(messageStr.length());
		    
		    out.print(messageStr);
		    out.flush();
		}
	    } catch (Exception E) {
		    System.out.println("Error: " + E);
		    E.printStackTrace();
	    }
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
	int port = 1060;
	int code = 619;

	gnu.getopt.Getopt g =
	    new gnu.getopt.Getopt("SentDetectClient", args, "p:c:v");
	int c;
	while ((c = g.getopt()) != -1) {
	    switch(c) {
	    case 'p':
		port = Integer.parseInt(g.getOptarg());
		break;
	    case 'c':
		code = Integer.parseInt(g.getOptarg());
		break;
	    case 'v':
		verbose = true;
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
	    //new SentDetectServer(serverSocket.accept(), code).start();
	    new SentDetectServer(serverSocket.accept(), code).start();
	    //new TokPosServer(serverSocket.accept()).run();
	}
	serverSocket.close();
    }
    
}
