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

import java.io.*;
import java.net.*;

/**
 * A client for accessing a pipeline server thread.
 *
 * @author      Gann Bierner
 * @version     $Revision$, $Date$
 **/
public class PipelineClient {

    public static void main (String[] args) throws IOException {

	int port = 1058;
	String host = "localhost";
	boolean file = false;
	
	gnu.getopt.Getopt g =
	    new gnu.getopt.Getopt("PipelineClient", args, "fp:h:");
	int c;
	while ((c = g.getopt()) != -1) {
	    switch(c) {
	    case 'f':
		file = true;
		break;
	    case 'p':
		port = Integer.parseInt(g.getOptarg());
		break;
	    case 'h':
		host = g.getOptarg();
		break;
	    }
	}
	
        Socket socket = null;
        PrintWriter out = null;
        BufferedReader in = null;
	String dataStr = args[g.getOptind()];
	BufferedReader data;
	if (file) {
	    data = new BufferedReader(new FileReader(dataStr));
	} else {
	    data = new BufferedReader(new StringReader(dataStr));
	}

        try {
            socket = new Socket(host, port);
            out = new PrintWriter(socket.getOutputStream(), true);
            in = new BufferedReader(new InputStreamReader(socket.getInputStream()));
        } catch (UnknownHostException e) {
            System.err.println("Don't know about host.");
            System.exit(1);
        } catch (IOException e) {
            System.err.println("Couldn't get I/O for the connection.");
            System.exit(1);
        }

	StringBuffer fromServer = new StringBuffer();
	String line;
	while ((line=data.readLine())!=null) {
	    out.println(line);
	}
	out.println("@OVER@");
	while ((line = in.readLine()) != null) {
	    if(line.startsWith("Error:")) {
		System.out.println(line);
		break;
	    } else {
		fromServer.append(line+"\n");
		if (line.equals("</nlpDocument>")) {
		    break;
		}
	    }
	}
	
	System.out.println(fromServer);
	
	out.close();
        in.close();
        socket.close();
    }
}
