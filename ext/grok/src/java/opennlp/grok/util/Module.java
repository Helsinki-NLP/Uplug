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

import java.lang.reflect.Constructor;
import java.io.*;
import java.util.*;

/**
 * A central resource for choosing modules based on the interfaces they
 * implement.  Basically, this class needs to be initialized with a mapping
 * from interfaces to implementations.  Then, when asked for an interface,
 * this class returns the appropriate implementation.  This allows you to
 * switch modules (parsers, lexicons, etc) on the fly.
 *
 * @author      Gann Bierner
 * @version     $Revision$, $Date$
 *
 */
public class Module {

    private static ArrayList listeners = new ArrayList();
    private static Map CHOICES = new GroupMap();
    private static Properties CURRENT;

    public static void addListener(ModuleListener l) {
	listeners.add(l);
    }
    
    public static void Init(String file, String current) {
	try {
	    Init(new FileInputStream(file),
		 new FileInputStream(current));
	}
	catch (Exception E) {
	    System.out.println("Unable to load module file: " + E);
	}
    }
    public static void Init(InputStream file, InputStream current) {
	Properties DEFAULTS = new Properties();
	CURRENT = new Properties(DEFAULTS);
	try { CURRENT.load(current); }
	catch (Exception E) {
	    System.out.println("Unable to load module file: " + current);
	}
	
	BufferedReader br = new BufferedReader(new InputStreamReader(file));
	try {
	    String line = br.readLine();
	    while(line!=null) {
		line = line.trim();
		if(!line.equals("")) {
		    StringTokenizer st = new StringTokenizer(line);
		    String module = st.nextToken().trim();
		    String def = st.nextToken().trim();
		    DEFAULTS.setProperty(module, def);
		    CHOICES.put(module, def);
		    while(st.hasMoreTokens())
			CHOICES.put(module, st.nextToken().trim());
		}
		line = br.readLine();
	    }
	} catch (IOException IO) { IO.printStackTrace(); }
    }

    public static void Save(String file) {
	try {
	    CURRENT.store(new FileOutputStream(file),
			  "Current user modules for Grok");
	} catch (Exception E) { System.out.println(E); }
    }

    // find the constructor that matches the params types
    private static Constructor getConstructor(Class modClass, Class[] types) {
	Constructor[] constrs = modClass.getDeclaredConstructors();

	for(int c=0; c<constrs.length; c++) {
	    
	    Class[] constrParamTypes = constrs[c].getParameterTypes();
	    if(constrParamTypes.length != types.length)
		continue;

	    boolean found = true;
	    for(int t=0; t<types.length; t++)
		if(!constrParamTypes[t].isAssignableFrom(types[t])) {
		    found = false;
		    break;
		}
	    if(found)
		return constrs[c];
	}
	return null;
    }
    
    private static Object New(String module,
			     Object[] params,
			     Class[] paramTypes) {
	Object modInst;
	try{
	    // get the class for the default instantiation of the module
	    Class modClass = Class.forName(getDefault(module));
	    // get the appropriate constructor for this class given the params
	    Constructor constr = getConstructor(modClass, paramTypes);
	    // get the object
	    modInst = constr.newInstance(params);
	} catch (Exception E) {
	    System.out.println(module + " " + getDefault(module));
	    E.printStackTrace(); return null;
	}
	return modInst;
    }

    private static Object New(String module, Object[] params) {
	// get parameter types
	Class[] paramTypes = new Class[params.length];
	for(int i=0; i<paramTypes.length; i++) {
	    paramTypes[i] = params[i].getClass();
	}
	return New(module, params, paramTypes);
    }

    public static Object New(Class c, Object[] params) {
	return New(c.getName(), params);
    }
    public static Object New(Class c) {
	Object[] params = {};
	return New(c.getName(), params);
    }
    public static Object New(Class c, Object p1) {
	Object[] params = {p1};
	return New(c.getName(), params);
    }
    public static Object New(Class c, Object p1, Object p2) {
	Object[] params = {p1, p2};
	return New(c.getName(), params);
    }
    public static Object New(Class c, Object p1, Object p2, Object p3) {
	Object[] params = {p1, p2, p3};
	return New(c.getName(), params);
    }

    public static Iterator getModules() {
	return CHOICES.keySet().iterator();
    }
    public static String getDefault(String module) {
	return CURRENT.getProperty(module);
    }
    public static void setDefault(String module, String def) {
	CURRENT.setProperty(module, def);
	for(Iterator i=listeners.iterator(); i.hasNext();)
	    ((ModuleListener)i.next()).ModuleChanged(module, def);
    }
    public static Iterator getInstancesIterator(String module) {
	return ((Collection)CHOICES.get(module)).iterator();
    }
    public static Collection getInstances(String module) {
	return (Collection)CHOICES.get(module);
    }
}
