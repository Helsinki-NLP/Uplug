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

import opennlp.hylo.*;
import opennlp.common.unify.*;
import opennlp.common.util.*;
import gnu.trove.*;
import org.jdom.*;
import java.util.*;
import java.io.*;


/**
 * A feature structure for use with Grok categories.
 *
 * @author      Jason Baldridge
 * @version     $Revision$, $Date$
 */
public class GFeatStruc 
    extends THashMap implements FeatureStructure {

    boolean _empty = true;
    int _index = 0;
    int _inheritorId = 0;
    
    TIntObjectHashMap _featureIndices = new TIntObjectHashMap();
    
    public GFeatStruc () {
	super(3);
    }

    public GFeatStruc (int i) {
	super(i);
    }

    public GFeatStruc (Element fsEl) {
	super(fsEl.getChildren().size());
	String index = fsEl.getAttributeValue("id");
	if (index != null) {
	    _index = Integer.parseInt(index);
	}
	String inherit = fsEl.getAttributeValue("inheritorId");
	if (inherit != null) {
	    _inheritorId = Integer.parseInt(inherit);
	}
	List feats = fsEl.getChildren();
	if (feats.size() == 0) {
	    setFeature(fsEl);
	}
	else {
	    for (Iterator featIt=feats.iterator(); featIt.hasNext();) {
		setFeature((Element)featIt.next());
	    }
	}
    }

    public void setFeature (String attribute, Object val) { 
	put(attribute, val);
	_empty = false;
    }

    private void setFeature (Element e) {
	String attr = e.getAttributeValue("a"); 
	if (attr == null) {
	    return;
	}
	String val = e.getAttributeValue("v");
	Object value;
	if (val != null) {
	    value = val;
	} else {
	    value = HyloHelper.getLF((Element)e.getChildren().get(0));
	}
	setFeature(attr, value);
    }
    
    public Object getValue (String attribute) {
	return get(attribute);
	//return f.getValue();
	//return ((Feature)get(attribute)).getValue();
    }

    public boolean hasAttribute (String attribute) {
	return containsKey(attribute);
    }

    public boolean attributeHasValue (String attribute, Object val) {
	return (val.equals(getValue(attribute)));
    }

    public Set getAttributes () {
	return keySet();
    }
    
    public void clear () { 
	clear();
	_empty = true;
    }

    public boolean equals (FeatureStructure fs) {
	if (!(fs instanceof GFeatStruc)) return false;
	GFeatStruc bfs = (GFeatStruc)fs;
	
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
	FeatureStructure $fs = new GFeatStruc(size());
	$fs.setIndex(_index);
	$fs.setInheritorIndex(_inheritorId);
	for (Iterator i=getAttributes().iterator(); i.hasNext();) {
	    String a = (String)i.next();
	    $fs.setFeature(a, getValue(a));
	}
	return $fs;
    }

    public FeatureStructure filter (FilterFcn ff) { 
	FeatureStructure $fs = new GFeatStruc(size());
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
	    FeatureStructure $fs = new GFeatStruc(size());
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
			Object val2 = fs2.getValue(k2);
			$fs.setFeature(k1, Unifier.unify(val1, val2, sub));
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
	    if (_index > 0) {
		$fs.setIndex(_index);
	    } else {
		$fs.setIndex(fs2.getIndex());
	    }
	    if (_inheritorId > 0) {
		$fs.setInheritorIndex(_inheritorId);
	    } else {
		$fs.setInheritorIndex(fs2.getInheritorIndex());
	    }
	    return $fs;
	}
    }

    public Object fill (Substitution sub) {
	return copy();
    }

    public FeatureStructure inherit (FeatureStructure fs) { 
	for (Iterator i = fs.getAttributes().iterator(); i.hasNext();) {
	    String a = (String)i.next();
	    if (!hasAttribute(a)) {
		setFeature(a, fs.getValue(a));
	    }
	}
	return this;
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
	if (_empty) {
	    return "";
	}

	StringBuffer sb = new StringBuffer(size()*4);
	//sb.append('(').append(Integer.toString(_index)).append('/').append(Integer.toString(_inheritorId)).append(')');

	
	sb.append('{');
	Iterator i = keySet().iterator();
	for(int size = size(); --size>0;) {
	    String k = (String)i.next();
	    sb.append(k).append('=').append(getValue(k).toString()).append(", ");
	}
	String lastKey = (String)i.next();
	sb.append(lastKey).append('=').append(getValue(lastKey).toString()).append('}');
	return sb.toString();
    }

}
