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

package opennlp.grok.datarep;

import opennlp.common.xml.*;

import org.jdom.*;
import org.jdom.input.*;

import java.io.*;
import java.util.*;


/**
 * A datastructure for morpholical entries.  Used by LMR grammars.
 *
 * @author      Jason Baldridge
 * @version $Revision$, $Date$
 */
public class MorphItem implements Serializable {
    private String word;
    private String stem;
    private String POS;
    private List macros;

    public MorphItem() {};

    public MorphItem (Element e) {

	String word = e.getAttributeValue("word");
	setWord(word);
	
	String stem = e.getAttributeValue("stem");
	if (stem == null) 
	    setStem(word);
	else 
	    setStem(stem);
	
	setPOS(e.getAttributeValue("pos"));
	
	List refs = e.getChildren("macro");
	macros = new ArrayList();
	for (int j=0; j<refs.size(); j++)
	    macros.add(((Element)refs.get(j)).getAttributeValue("ref"));
	
    }


    public void setWord(String s) { word=s; }
    public void setStem(String s) { stem=s; }
    public void setPOS(String s) { POS=s; }
    public void setMacros(List al) { macros = al; }

    public String getWord() { return word; }
    public String getStem() { return stem; }
    public String getPOS() { return POS; }
    public List getMacros() { return macros; }

    public void addMacro(String s) { macros.add(s); }
    public void removeMacro(String s) {
	macros.remove(macros.indexOf(s));
    }

    public MorphItem copy() {
	MorphItem mi = new MorphItem();
	mi.setWord(word);
	mi.setStem(stem);
	mi.setPOS(POS);
	mi.setMacros(macros);
	return mi;
    }

    public Element createXmlElement() {
	try {
	    return new SAXBuilder().build(new StringReader(toXml())).getRootElement();
	} catch (Exception e) { e.printStackTrace(); }
	return null;
    }
    
    
    public String toXml() {
	StringBuffer xml = new StringBuffer(128);
	xml.append("  <morph word=\"").append(XmlUtils.filt2XML(word)).append("\"");
	if (!stem.equals(word))
	    xml.append(" stem=\"").append(XmlUtils.filt2XML(stem)).append("\"");
	xml.append(" pos=\"").append(XmlUtils.filt2XML(POS)).append("\"");

	if (macros.size() == 0) {
	    xml.append("/>\n");
	} 
	else {
	    for (int j=0; j<macros.size(); j++)
		xml.append("     <macro ref=\"").append(XmlUtils.filt2XML((String)(macros.get(j)))).append("\" />\n");
	    xml.append("  </morph>");
	}
	return xml.toString();
    }

    public String toString() {
	return "{" + word + "=>" + stem + " " + POS + " " + macros + "}";
    }
    
}
