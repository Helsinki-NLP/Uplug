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

package opennlp.grok.unify;

import opennlp.common.unify.*;
import opennlp.common.util.*;
import gnu.trove.THashMap;
import org.jdom.*;
import java.util.*;
import java.io.*;


/**
 * A basic implementation of a feature structure.
 *
 * @author      Jason Baldridge
 * @version     $Revision$, $Date$
 */
public class BasicFeatureStructure 
    extends THashMap implements FeatureStructure {

    boolean _empty = true;
    int _index = -1;
    int _inheritorId = -1;
    
    public BasicFeatureStructure () {
	super(3);
    }

    public BasicFeatureStructure (int i) {
	super(i);
    }

    public BasicFeatureStructure (Element fsEl) {
	super(fsEl.getChildren().size());
	List feats = fsEl.getChildren();
	if (feats.size() == 0) {
	    setFeature(fsEl.getAttributeValue("a"), 
		       fsEl.getAttributeValue("v"));
	}
	else {
	    for (int i=0; i<feats.size(); i++) {
		Element fel = (Element)feats.get(i);
		setFeature(fel.getAttributeValue("a"),
			   fel.getAttributeValue("v"));
	    }
	}
	_empty = false;
    }

    public void setFeature (String attribute, Object val) { 
	put(attribute, val);
	_empty = false;
    }

    public Object getValue (String attribute) {
	return get(attribute);
    }

    public boolean hasAttribute (String attribute) {
	return containsKey(attribute);
    }

    public boolean attributeHasValue (String attribute, Object val) {
	return (val.equals(get(attribute)));
    }

    public Set getAttributes () {
	return keySet();
    }
    
    public void clear () { 
	clear();
    }

    public boolean equals (FeatureStructure fs) {
	if (!(fs instanceof BasicFeatureStructure)) return false;
	BasicFeatureStructure bfs = (BasicFeatureStructure)fs;
	
	if (size() != bfs.size())
	    return false;
	
	Set atts1 = getAttributes();
	Set atts2 = bfs.getAttributes();
	if (atts1.containsAll(atts2) && atts2.containsAll(atts1)) {
	    for (Iterator i1 = atts1.iterator(); i1.hasNext();) {
		String a1 = (String)i1.next();
		boolean foundA1 = false;
		for (Iterator i2 = atts2.iterator(); !foundA1 && i2.hasNext();) {
		    String a2 = (String)i2.next();
		    if (a1.equals(a2)) {
			if (!getValue(a1).equals(bfs.getValue(a2)))
			    return false;
			foundA1 = true;
		    }
		}
	    }
	    return true;
	}
	else {
	    return false;
	}
    }

    public FeatureStructure copy() { 
	FeatureStructure $fs = new BasicFeatureStructure(size());
	for (Iterator i=getAttributes().iterator(); i.hasNext();) {
	    String a = (String)i.next();
	    $fs.setFeature(a, getValue(a));
	}
	return $fs;
    }

    public FeatureStructure filter (FilterFcn ff) { 
	FeatureStructure $fs = new BasicFeatureStructure(size());
	for (Iterator i=getAttributes().iterator(); i.hasNext();) {
	    String key = (String)i.next();
	    if (ff.filter(key))
		$fs.setFeature(key, getValue(key));
	}
	return $fs;
   }
    
    
    public boolean contains (FeatureStructure fs) { 
	if (size() < fs.size())
	    return false;
	
	Set atts1 = getAttributes();
	Set atts2 = fs.getAttributes();
	if (atts1.containsAll(atts2)) {
	    for (Iterator i2 = atts2.iterator(); i2.hasNext();) {
		String a2 = (String)i2.next();
		boolean foundA2 = false;
		for (Iterator i1 = atts1.iterator(); !foundA2 && i1.hasNext();) {
		    String a1 = (String)i1.next();
		    if (a1.equals(a2)) {
			if (!getValue(a1).equals(fs.getValue(a2)))
			    return false;
			foundA2 = true;
		    }
		}
	    }
	    return true;
	}
	else {
	    return false;
	}
    }

    public boolean occurs (Variable v) {
	for (Iterator i = values().iterator(); i.hasNext();) {
	    Object $_ = i.next();
	    if ($_ instanceof Unifiable && ((Unifiable)$_).occurs(v))
		return true;
	}
	return false;
    }

    public void unifyCheck (Object u) throws UnifyFailure {
	if (!(u instanceof FeatureStructure)) {
	    throw new UnifyFailure();
	}
    }

    public Object unify (Object u, Substitution sub) 
	throws UnifyFailure { 
	
	if (!(u instanceof FeatureStructure)) {
	    throw new UnifyFailure();
	} else {
	    FeatureStructure fs2 = (FeatureStructure)u;
	    FeatureStructure $fs = new BasicFeatureStructure(size());
	    Set keys1 = getAttributes();
	    Set keys2 = fs2.getAttributes();
	    for (Iterator i1=keys1.iterator(); i1.hasNext();) {
		String k1 = (String)i1.next();
		Object val1 = getValue(k1);
		boolean foundK1 = false;
		for (Iterator i2=keys2.iterator(); !foundK1 && i2.hasNext();) {
		    String k2 = (String)i2.next();
		    if (k1.equals(k2)) {
			foundK1 = true;
			if (val1.equals(fs2.getValue(k2))) {
			    $fs.setFeature(k1, val1);
			}
			else {
			    throw new UnifyFailure();
			}
		    }
		}
		if (!foundK1)
		    $fs.setFeature(k1, val1);
	    }
	    for (Iterator i2=keys2.iterator(); i2.hasNext();) {
		String k2 = (String)i2.next();
		if (!keys1.contains(k2))
		    $fs.setFeature(k2, fs2.getValue(k2));
	    }
	    return $fs;
	}
    }

    public Object fill (Substitution sub) {
	return copy();
    }

    public FeatureStructure inherit (FeatureStructure fs) { 
	return fs;
	//FeatureStructure $fs = copy();
	//
	//if ($fs.size() < fs.size()) {
	//    for (Iterator i = $fs.getAttributes().iterator(); i.hasNext();) {
	//	  String a = (String)i.next();
	//	  if (fs.hasAttribute(a))
	//	      $fs.setFeature(a, fs.getValue(a));
	//    }
	//}
	//else {
	//    for (Iterator i = fs.getAttributes().iterator(); i.hasNext();) {
	//	  String a = (String)i.next();
	//	  if ($fs.hasAttribute(a))
	//	      $fs.setFeature(a, fs.getValue(a));
	//    }
	//}
	//return $fs; 
    }

    public int getIndex () {
	return _index;
    }

    public void setIndex (int index) {
	_index = index;
    }
    
    public int getInheritorIndex () {
	return _inheritorId;
    }

    public void setInheritorIndex (int inheritorId) {
	_inheritorId = inheritorId;
    }

    public String toString() {
	if (_empty) return "";

	StringBuffer sb = new StringBuffer(size()*4);
	sb.append('{');

	Iterator i = keySet().iterator();
	for(int size = size(); --size>1;) {
	    String k = (String)i.next();
	    sb.append(k).append('=').append(getValue(k).toString()).append(", ");
	}
	String lastKey = (String)i.next();
	sb.append(lastKey).append('=').append(getValue(lastKey).toString()).append('}');
	return sb.toString();
    }

}
