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

import java.util.Properties;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.HashMap;
import java.util.Iterator;
import java.io.FileInputStream;
import java.io.FileOutputStream;

/**
 * A central location to store and manage parameters that may or may not be
 * user definable.
 *
 * @author      Gann Bierner
 * @version     $Revision$, $Date$
 *
 */
public class Params {

    static ArrayList listeners = new ArrayList();
    static Properties props;
    static Properties defaults;

    static {
	defaults = new Properties();
	props = new Properties(defaults);
    }

    public static void addParamListener(ParamListener l) {
	listeners.add(l);
    }

    public static Iterator iterator() {
	HashSet H = new HashSet();
	H.addAll(defaults.keySet());
	H.addAll(props.keySet());
	return H.iterator();
    }
    
    public static void register(String key, String value) {
	defaults.setProperty(key, value);
	if(props.get(key)==null) 
	    for(Iterator I=listeners.iterator(); I.hasNext();)
		((ParamListener)I.next()).paramRegistered(key, value);
    }

    public static void init(String file) {
	try { props.load(new FileInputStream(file)); }
	catch (Exception E) {}
    }

    public static void save(String file) {
	for(Iterator I=listeners.iterator(); I.hasNext();)
	    ((ParamListener)I.next()).paramSaving();	
	try {
	    props.store(new FileOutputStream(file),
			"Current internal parameters for Grok");
	} catch (Exception E) { System.out.println(E); }
    }

    
    public static String getProperty(String key) {
	return props.getProperty(key);
    }
    public static String getDefault(String key) {
	return defaults.getProperty(key);
    }
    public static boolean getBoolean(String key) {
	return (new Boolean(props.getProperty(key))).booleanValue();
    }
    public static int getInteger(String key) {
	return Integer.parseInt(props.getProperty(key));
    }

    public static void setProperty(String key, String val) {
	props.setProperty(key, val);
	for(Iterator I=listeners.iterator(); I.hasNext();)
	    ((ParamListener)I.next()).paramChanged(key, val);
    }

}
