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

package opennlp.grok.util;

import java.util.HashSet;
import java.util.Iterator;
import java.util.Collection;

/**
 * A special implementation of sets.  We should probably get rid of this and
 * use java sets, but we've had some problems with them.
 *
 * @author      Gann Bierner
 * @version     $Revision$, $Date$
 *
 */
public class GrokSet extends HashSet {

    public GrokSet(Collection c) {
	addAll(c);
    }
    
    public GrokSet() { super(); }
    
    public GrokSet intersect(GrokSet s) {
	GrokSet ns = new GrokSet();
	if (size() < s.size()) {
	    for(Iterator i = iterator(); i.hasNext();) {
		Object element = i.next();
		if(s.contains(element)) ns.add(element);		
	    }	    
	}
	else {
	    for(Iterator i = s.iterator(); i.hasNext();) {
		Object element = i.next();
		if(contains(element)) ns.add(element);		
	    }	    
	}	    
	return ns;
    }


    public GrokSet union(GrokSet s) {
	GrokSet ns;
	if (size() < s.size()) {
	    ns = (GrokSet)s.clone();
	    for(Iterator i = iterator(); i.hasNext();)
		ns.add(i.next());
	}
	else {
	    ns = (GrokSet)clone();	
	    for(Iterator i = s.iterator(); i.hasNext();)
		ns.add(i.next());
	}	    
	return ns;
    }


    public boolean subset(GrokSet s) {
	if (size() > s.size()) return false;
	for(Iterator i = iterator(); i.hasNext();) {
	    Object o1 = i.next();
	    boolean found = false;
	    for (Iterator j=s.iterator(); j.hasNext();) {
		if (o1.equals(j.next())) {
		    found = true;
		    break;
		}
	    }
	    if (!found) return false;
	}
	return true;
    }

    // default doesn't work in Blackdown linux version!
    public boolean contains(Object o) {
	for(Iterator i=iterator(); i.hasNext();) {
	    Object o2 = i.next();
	    if(o2!=null && o2.equals(o))
		return true;
	}
	return false;
    }
    
    // does a set contain and element in itself or in one of its subsets?
    private boolean containsDeep(Object o) {
	if (contains(o)) return true;
	Iterator i = iterator();
	while(i.hasNext()) {
	    Object item = i.next();
	    if(item instanceof GrokSet && ((GrokSet)item).contains(o))
		return true;
	}
	return false;
    }

    // set difference but removes any subset that contains the object
    // (as well as the object itself if it's on the top level)
    public GrokSet minusDeep(GrokSet s) {
	GrokSet ns = new GrokSet();
	Iterator iter = iterator();
	while(iter.hasNext()) {
	    Object check = iter.next();
	    if (check instanceof GrokSet) {
		Iterator remIter = s.iterator();
		    while(remIter.hasNext())
			if(!((GrokSet)check).containsDeep(remIter.next()))
			    ns.add(check);
	    } else if (!s.contains(check))
		ns.add(check);
	}
	return ns;
    }

    /**
     * Performs set difference on two sets.  Unfortunately, the
     * removeAll(Collection c) method of Collection doesn't seem to work, so I
     * have implemented the removal explicitly --jmb.
     */
    public GrokSet setDifference(GrokSet s) {
	GrokSet ns = (GrokSet)clone();
	for (Iterator i=s.iterator(); i.hasNext();) {
	    Object o1 = i.next();
	    for (Iterator j=ns.iterator(); j.hasNext();) {
		if (o1.equals(j.next())) j.remove();
	    }
	}
	return ns;
    }

    public GrokSet minus(Object d) {
	GrokSet ns = (GrokSet)clone();
	ns.remove(d);
	return ns;
    }

    // If set is flat, returns set.  Otherwise returns largest subset.
    private int elementSize(Object o) {
	if (o instanceof GrokSet) return ((GrokSet)o).size();
	else return 1;
    }
    public GrokSet max() {
	int maxSize=0;
	Object maxSet = null;
	Iterator iter = iterator();
	while(iter.hasNext()) {
	    Object o = iter.next();
	    int s = elementSize(o);
	    if(s > maxSize) { maxSize = s; maxSet = o; }
	}
	if (maxSize>1)
	    return (GrokSet)maxSet;
	else
	    return (GrokSet)clone();
//	  GrokSet ns = new GrokSet();
//	  iter = iterator();
//	  while(iter.hasNext()) {
//	      Object o = iter.next();
//	      if(elementSize(o) == maxSize)
//		  ns.add(o);
//	  }
//	  return ns;
    }

    // return the power set (the set of all subsets)
    // This method works by determining the number of subsets and
    // iterating an integer from 0 to that number minus one.  For each
    // of these numbers we use it's binary represenatation to
    // determine what elements to take from the original set for the
    // subset.
    public GrokSet pow() {
	GrokSet ans = new GrokSet();
	int poss = (int)Math.pow(2, size())-1;
	Object[] A = toArray();
	for(int i = 1; i<=poss; i++) {
	    GrokSet temp = new GrokSet();
	    String bs = Integer.toBinaryString(i);
	    int len = bs.length();
	    for(int j=0; j<len; j++) {
		if(bs.charAt(len-1-j) == '1')
		    temp.add(A[j]);
	    }
	    ans.add(temp);
	}
	return ans;
    }

    // Returns the power set without the singleton subsets
    public GrokSet multiPow() {
	GrokSet ans = pow();
	Iterator iter = ans.iterator();
	while(iter.hasNext())
	    if(((GrokSet)iter.next()).size()==1)
		iter.remove();
	return ans;
    }
    
    public static void main(String args[]) {
	GrokSet a = new GrokSet();
	a.add("1"); a.add("2"); a.add("3");

	GrokSet b = new GrokSet();
	b.add("1"); b.add("2"); b.add("4");

	GrokSet c = new GrokSet();
	c.add(a); c.add(b);

	GrokSet d = new GrokSet();
	d.add(a);

	GrokSet e = new GrokSet();
	e.add("1"); e.add("2");

	GrokSet f = new GrokSet();
	f.add("2"); f.add("3");

	GrokSet g = new GrokSet();
	g.add(a); g.add(e); g.add(f); g.add("1");

	GrokSet h = new GrokSet();
	h.add("4");

	GrokSet i = new GrokSet();
	i.add("1");

	System.out.println(g+"-*"+i+"="+g.minusDeep(i));
	System.out.println("max("+g+")="+g.max());
	System.out.println("pow("+a+")="+a.pow());
	System.out.println("multiPow("+a+")="+a.multiPow());
	//System.out.println(a.minus(b));
	//System.out.println(b.minus(h));
	//System.out.println(a.intersect(b));
	//System.out.println(c.intersect(d));
	//System.out.println(a.union(b));
	//System.out.println(c.union(d));
    }

    
    
}
