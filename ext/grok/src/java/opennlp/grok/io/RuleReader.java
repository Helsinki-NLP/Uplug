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

import opennlp.grok.expression.*;
import opennlp.grok.grammar.*;
import opennlp.common.parse.*;
import opennlp.common.synsem.*;

import org.jdom.*;
import org.jdom.input.*;
import org.jdom.output.*;

import java.io.*;
import java.net.*;
import java.util.*;

public class RuleReader {

    public static RuleGroup getRules (String filename) {
	try {
	    if (filename==null) {
		return new CustomRuleGroup();
	    } else {
		return getRules(new URL(filename).openStream());
	    }
	} catch (IOException e) {
	    System.out.println("Problem loading rules file: " + filename);
	    e.printStackTrace();
	    return new CustomRuleGroup();
	}
    }
    
    public static RuleGroup getRules (InputStream istr) {
	RuleGroup rules = new CustomRuleGroup();

	SAXBuilder builder = new SAXBuilder();

	try {	    
	    Document doc = builder.build(istr);
	    List entries = doc.getRootElement().getChildren();
	    
	    for (int i=0; i<entries.size(); i++) {
		Element ruleEl = (Element)entries.get(i);
		String active = ruleEl.getAttributeValue("active");
		if (active == null || active.equals("true")) {
		    String type = ruleEl.getName();
		    if (type.equals("application")) {
			String dir = ruleEl.getAttributeValue("dir");
			if (dir.equals("forward")) {
			    rules.addRule(new ForwardApplication());
			} else {
			    rules.addRule(new BackwardApplication());
			}
		    } else if (type.equals("composition")) {
			String dir = ruleEl.getAttributeValue("dir");
			String harmonic = ruleEl.getAttributeValue("harmonic");
			boolean isHarmonic =
			    new Boolean(harmonic).booleanValue();
			if (dir.equals("forward")) {
			    rules.addRule(new ForwardComposition(isHarmonic));

			} else {
			    rules.addRule(new BackwardComposition(isHarmonic));
			}
		    } else if (type.equals("typeraising")) {
			VarCat argVar = 
			    (VarCat)CatReader.getCat(
			        (Element)ruleEl.getChild("argVar").getChildren().get(0));
			VarCat resultVar = 
			    (VarCat)CatReader.getCat(
				(Element)ruleEl.getChild("resultVar").getChildren().get(0));
			String dir = ruleEl.getAttributeValue("dir");
			if (dir.equals("forward")) {
			    rules.addRule(new ForwardTypeRaising(argVar,
								 resultVar));
			} else {
			    rules.addRule(new BackwardTypeRaising(argVar,
								  resultVar));
			}
		    } else if (type.equals("rule")) {
			rules.addRule(getRule(ruleEl));
		    } else {
			throw new JDOMException("Invalid element in rules: "
						+ type);
		    }
		}
	    }
	    
	} catch (Exception e) {
	    e.printStackTrace();
	    return rules;
	}
	
	return rules;
    }

    private static Rule getRule (Element el) {
	String rname = el.getAttributeValue("name");
	
	List arguments = el.getChild("args").getChildren();
	Category[] args = new Category[arguments.size()];
	for (int i=0; i<args.length; i++) {
	    args[i] = CatReader.getCat((Element)arguments.get(i));
	}
	Category result = 
	    CatReader.getCat((Element)el.getChild("result").getChildren().get(0));
	
	return new GenericRule(args, result, rname);
    }



}
