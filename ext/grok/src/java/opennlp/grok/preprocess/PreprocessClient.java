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

import java.io.*;
import java.net.*;

public class PreprocessClient {

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
	    System.out.println("Exception here" + e);
	    return null;
	}
    }
    
    public static void main(String[] args) throws IOException {

	int port = 1059;
	String host = "localhost";
	String file = null;
	
	gnu.getopt.Getopt g =
	    new gnu.getopt.Getopt("PreprocessClient", args, "f:p:h:");
	int c;
	while ((c = g.getopt()) != -1) {
	    switch(c) {
	    case 'f':
		file = g.getOptarg();
		break;
	    case 'p':
		port = Integer.parseInt(g.getOptarg());
		break;
	    case 'h':
		host = g.getOptarg();
		break;
	    }
	}
	
        Socket socket =null;
        PrintWriter out = null;
	DataOutputStream binaryOut = null;
	DataInputStream in = null;
	BufferedReader data;
	if(file!=null) data = new BufferedReader(new FileReader(file));
	else data = new BufferedReader(new InputStreamReader(System.in));

        try {
            socket = new Socket(host, port);
            out = new PrintWriter(socket.getOutputStream(), true);
	    binaryOut = new DataOutputStream(socket.getOutputStream());
            in = new DataInputStream(socket.getInputStream());
        } catch (UnknownHostException e) {
            System.err.println("Don't know about host.");
            System.exit(1);
        } catch (IOException e) {
            System.err.println("Couldn't get I/O for the connection.");
            System.exit(1);
        }

	String line;
	if(file==null) {
	    System.out.print("preprocess> ");
	    System.out.flush();
	}
	while((line=data.readLine())!=null) {
	    line = "618 " + line;
	    binaryOut.writeInt(line.length());
	    out.print(line);
	    out.flush();
	    //System.out.println(in.readLine());
	    System.out.println(getMessage(in).substring(4));
	    if(file==null) {
		System.out.print("preprocess> ");
		System.out.flush();
	    }
	}
	
	out.close();
        in.close();
        socket.close();
    }
}
