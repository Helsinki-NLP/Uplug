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

package opennlp.grok.ml.dectree;

import java.util.*;

/**
 * A special map that computes values on the fly basied on FeatureComputers.
 * So you don't have to compute a feature value until it is asked for and
 * therefore save some work.
 *
 * @author      Gann Bierner
 * @version $Revision$, $Date$
 */
public class DTreeFeatureMap extends HashMap {

    Map computers = new HashMap();
    Object[] data;

    public DTreeFeatureMap(Collection c) {
	this();
	for(Iterator i=c.iterator(); i.hasNext();)
	    addFeatureComputer((DTreeFeatureComputer)i.next());
    }
    public DTreeFeatureMap() { }


    public void addFeatureComputer(DTreeFeatureComputer comp) {
	String[] features = comp.getFeatures();
	for(int i=0; i<features.length; i++)
	    computers.put(features[i], comp);
    }
    
    public void setData(Object[] d) {
	clear();
	data = d;
    }
    
    public Object get(Object o) {
	if(!containsKey(o)) {
	    DTreeFeatureComputer computer =
		(DTreeFeatureComputer)computers.get((String)o);
	    computer.compute(data, this);
	}
	return super.get(o);
    }
}
