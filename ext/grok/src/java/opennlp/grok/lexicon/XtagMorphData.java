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

package opennlp.grok.lexicon;

import opennlp.grok.util.*;
import opennlp.grok.datarep.*;

import opennlp.common.morph.*;
import opennlp.common.preprocess.*;
import opennlp.common.util.*;
import opennlp.common.xml.*;

import org.jdom.*;

import java.io.*;
import java.net.*;
import java.util.zip.*;
import java.util.*;
import java.sql.*;

interface XtagMorphDataIntf extends MorphData {
    boolean init(Properties g);
}

class XtagMorphDataFlat implements XtagMorphDataIntf {
    private HashMap H = new HashMap();
    private Map S = new GroupMap();

    boolean printActivity = true;

    // removed so that we don't depend on gnu.regexp
    //private static gnu.regexp.RE infRegex;
    //static {
    //	  try {
    //	      infRegex = new gnu.regexp.RE("INF");
    //	  } catch (gnu.regexp.REException E) { System.out.println(E); }
    //}

    public XtagMorphDataFlat() {
	printActivity = false;
    }
    public XtagMorphDataFlat(Properties g) {
	this();
	init(g);
    }

    public boolean init(Properties g) {
	String file = g.getProperty("morphdata");
	if (file == null)
	    return false;
	
	InputStreamReader isr;
	try {
	    if (file.endsWith(".gz")) {
		isr = new InputStreamReader(
		           new GZIPInputStream(new URL(file).openStream()));
	    }
	    else {
		isr = new InputStreamReader(new URL(file).openStream());
	    }
	}
	catch (Exception e) {
	    System.out.println("Morph file exception (" + file + "):" + e);
	    return false;
	}
	BufferedReader br = new BufferedReader(isr);
	try {
	    String line = br.readLine();
	    int c = 0;
	    while(line!=null) {
		line = line.trim();
		if(!line.startsWith(";")) {
		    int split = line.indexOf(' ');
		    String word = line.substring(0, split).trim();
		    if(word.indexOf("'")==-1) {

			// index line of morph
			String data = line.substring(split).trim();
			H.put(word, data);
		    }

		    if((c++ % 1000) == 0) print(".");
		}

		line = br.readLine();
	    }
	} catch (IOException IO) { IO.printStackTrace(); }
	return true;
    }

    private void print(String s)   { if(printActivity) System.out.print(s); }
    private void println(String s) { if(printActivity) System.out.println(s); }
    private void println()         { if(printActivity) System.out.println(); }

    private void addMorphItem(ArrayList morphItems,
			      String word,
			      String morphStr) {
	StringTokenizer mt = new StringTokenizer(morphStr);
	String stem = mt.nextToken();
	String pos = mt.nextToken();
	
	MorphItem mi = new MorphItem();
	mi.setWord(word);
	mi.setStem(stem);
	mi.setPOS(pos);

	while(mt.hasMoreTokens()) {
	    String macro = mt.nextToken();
	    mi.addMacro("@"+macro);

	    // if this is an INF macro, also translate to non 3sg categories
	    // (since this is English and XTAG morph does this annoying
	    // shortcut).

	    // removed so that we don't depend on gnu.regexp

	    //if(macro.equals("INF"))
	    //	  addMorphItem(morphItems, word,
	    //		       infRegex.substituteAll(morphStr, "not-3sg PRES"));
	}
	morphItems.add(mi);
    }
    

    private Collection getMorphItems(String word, String morphStr) {
	StringTokenizer st = new StringTokenizer(morphStr, "#");
	ArrayList morphItems = new ArrayList();

	while(st.hasMoreTokens())
	    addMorphItem(morphItems, word, st.nextToken());

	return morphItems;
    }

    public Collection getMorphItems(String word) {
	print("Retrieving: `" + word + "'");
	
	String morphStr = (String)H.get(word);
	if(morphStr==null) { println(); return null; }

	Collection morphItems = getMorphItems(word, morphStr);

	println("  --> " + morphItems.size() + " results");
	
	return morphItems;
    }

    public Collection getHeadMorphs(String word) {
	print("Retrieving from head: `" + word + "'");
	
	Collection morphStrs = (Collection)S.get(word);
	Collection morphItems = new HashSet();

	for(Iterator I=morphStrs.iterator(); I.hasNext();) {
	    Pair data = (Pair)I.next();
	    morphItems.addAll(getMorphItems((String)data.a, (String)data.b));
	}

	println("  --> " + morphItems.size() + " results");
	
	return morphItems;
    }
}

class XtagMorphDataDB implements XtagMorphDataIntf {
    Connection C;
    String[] macros = new String[32];

    XtagMorphDataDB() { }
    
    public boolean init(Properties g) {
	// load the JDBC driver
	try {
	    Class.forName("org.gjt.mm.mysql.Driver").newInstance(); 
	}
	catch (Exception E) {
	    System.err.println("Unable to load driver.");
	    return false;
	}
	String host = g.getProperty("host");
	String db = "jdbc:mysql://"+host+ "/xtagmorph?user=jdbc";

	// test the connection
	if(host!=null) {
	    try{ C = DriverManager.getConnection(db); }
	    catch (SQLException E) {
		System.out.println("SQLException: " + E.getMessage());
		return false;
	    }
	} else
	    return false;

	// get macros
	try{
	    Statement stmt = C.createStatement();
	    String query = "Select * from macros";
	    ResultSet RS = stmt.executeQuery(query);

	    while (RS.next())
		macros[RS.getInt("bit")] = RS.getString("macro");
	} catch(SQLException E) { E.printStackTrace(); return false; }

	return true;
    }

    private Collection collect(ResultSet RS) {

	Collection list = new ArrayList();
	try{
	    while (RS.next()) {
		MorphItem mi = new MorphItem();
		mi.setWord(RS.getString("word"));
		mi.setStem(RS.getString("stem"));
		mi.setPOS(RS.getString("pos"));
		
		boolean inf=false;
		int bits = RS.getInt("macros");
		for(int i=0; i<macros.length; i++) {
		    if((bits & 1)==1) {
			mi.addMacro("@"+macros[i]);
			if(macros[i].equals("INF")) inf=true;
		    }
		    bits = bits >> 1;
		}
		list.add(mi);
		if(inf) {
		    MorphItem mi2 = mi.copy();
		    mi2.removeMacro("@INF");
		    mi2.addMacro("@not-3sg");
		    mi2.addMacro("@PRES");
		    list.add(mi2);
		}
	    }
	} catch(SQLException E) { E.printStackTrace(); return list; }
	return list;
    }

    public Collection getMorphItems(String word) {
	try{
	    Statement stmt = C.createStatement();
	    String query =
		"select * from morphs where " +
		"STRCMP(word, \""+word+"\")=0";
	    ResultSet RS = stmt.executeQuery(query);
	    return collect(RS);
	} catch(SQLException E) { E.printStackTrace(); return null; }
    }

    public Collection getHeadMorphs(String word) {
	try{
	    Statement stmt = C.createStatement();
	    String query =
		"select * from morphs where " +
		"stem=\""+word+"\"";
	    ResultSet RS = stmt.executeQuery(query);
	    return collect(RS);
	} catch(SQLException E) { E.printStackTrace(); return null; }
    }
}


/**
 * Produces morphological information for strings specifically retrieved from
 * the XTag morphological database.  This is a crappy way of doing things
 * because it is so slow, but so far nothing better has presented itself other
 * than $30,000 program from Xerox Parc.
 * 
 *
 * @author      Gann Bierner
 * @version     $Revision$, $Date$
 */
public class XtagMorphData
    implements MorphData, ParamListener, MorphAnalyzer, Pipelink {

    XtagMorphDataIntf xtag;
    Cache macroCache = new Cache("XtagDataMorphs", 100, 2);
    Cache headCache = new Cache("XtagDataHeads", 100, 2);
    Properties gram;

    public XtagMorphData(Properties g) {
	gram=g;
	init();
	Params.addParamListener(this);
    }

    private void init(){
	boolean useDB = Params.getBoolean("Enable:Databases");
	if(useDB) {
	    xtag = new XtagMorphDataDB();
	    useDB = xtag.init(gram);
	}
	
	if(!useDB) {
	    xtag = new XtagMorphDataFlat();
	    xtag.init(gram);
	}
    }

    /**
     * Returns the morphological information for a word.
     *
     * @param word  The string representation of the word to be analyzed.
     * @return A String with the morph info, such as root, tense, person,
     *         etc.  Eventually, this should be a class instead of a String.
     */
    public String analyze(String word) {
	return getMorphItems(word).toString();
    }


    /**
     * Returns the prefixes of a word. NOT IMPLEMENTED.
     *
     * @param word  The string representation of the word to be analyzed.
     * @return A String[] containing all the suffixes of the word.
     */
    public String[] getPrefixes (String word) {
	return new String[0];
    }

    
    /**
     * Returns the suffixes of a word. NOT IMPLEMENTED.
     *
     * @param word  The string representation of the word to be analyzed.
     * @return A String[] containing all the suffixes of the word.
     */
    public String[] getSuffixes (String word) {
	return new String[0];
    }

    
    public Collection getMorphItems(String word) {
	Collection c = (Collection)macroCache.get(word);
	if(c==null) {
	    c = xtag.getMorphItems(word);
	    macroCache.put(word, c);
	}
	return c;
    }
    public Collection getHeadMorphs(String word) {
	Collection c = (Collection)headCache.get(word);
	if(c==null) {
	    c = xtag.getHeadMorphs(word);
	    headCache.put(word, c);
	}
	return c;
    }

    public void paramRegistered(String param, String value) {}
    public void paramSaving() {}
    public void paramChanged(String param, String value) {
	if(param.equals("Enable:Databases"))
	    init();
    }
    
    public void process(NLPDocument doc) {
	
	//for (Iterator i=doc.tokenIterator(); i.hasNext();) {
	//    Element tokEl = (Element)i.next();
	//    Collection c = getMorphItems(tokEl.getChildText("w"));
	//    if(c!=null) {
	//	  for (Iterator iter = c.iterator(); iter.hasNext();) {
	//	      MorphItem mi = (MorphItem)iter.next();
	//	      tokEl.addContent(mi.createXmlElement());
	//	  }
	//    }
	//}
    }

    public Set requires() {
	Set set = new HashSet();
	set.add(Tokenizer.class);
	return set;
    }

    
}

