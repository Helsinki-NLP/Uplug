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

import java.util.*;
import java.io.*;

import opennlp.common.util.Pair;

/**
 * Implements a cache parameterized by size and associativity.  It can also
 * save to and load from a file.  Nothing amazing, but it gets the job done.
 * It also relies on Params to make its properties user specifiable.
 *
 * @author      Gann Bierner
 * @version     $Revision$, $Date$
 *
 */
public class Cache implements ParamListener, Serializable {

    class Block implements Serializable {
	Object key;
	Object value;
	long time;
	Block(Object k, Object v, long d) {
	    key=k; value=v; time=d;
	}
    }

    String paramPrefix;
    Block[][] cache;
    int size;
    int assoc;
    boolean enabled;
    
    public Cache(String id, int length, int assoc) {
	paramPrefix = "Caches:"+id+":";
	String userHome = System.getProperties().getProperty("user.home");
	Params.register(paramPrefix+"size", length+"x"+assoc);
	Params.register(paramPrefix + "file",
			userHome+File.separator+".grok"+File.separator+
			"caches"+File.separator+id);
	Params.register(paramPrefix+"save on exit", "true");
	Params.register(paramPrefix+"enabled", "true");

	Pair p = splitSize(Params.getProperty(paramPrefix+"size"));
	this.size = Integer.parseInt((String)p.a);
	this.assoc = Integer.parseInt((String)p.b);
	enabled = Params.getBoolean(paramPrefix+"enabled");

	// see if there is a saved cache
	File f = new File(Params.getProperty(paramPrefix+"file"));
	if(f.exists()) {
	    try{
		FileInputStream istream = new FileInputStream(f);
		ObjectInputStream ois = new ObjectInputStream(istream);
	    
		cache = (Block[][])ois.readObject();
	    } catch(Exception E) {
		System.out.println("Inconsistent objects-- clearing cache.");
		cache = new Block[this.size][this.assoc];
	    }
	} else
	    cache = new Block[this.size][this.assoc];

	Params.addParamListener(this);
    }

    public void clear() {
	for(int i=0; i<size; i++)
	    for(int j=0; j<assoc; j++)
		cache[i][j]=null;
    }

    private Pair splitSize(String size) {
	int split = size.indexOf("x");
	Pair p = new Pair(size.substring(0,split), size.substring(split+1));
	return p;
    }

    private int getRow(Object o, int size) {
	return Math.abs(o.hashCode()) % size;
    }
    
    public void put(Object key, Object val) {
	if(!enabled) return;
	
	int row = getRow(key, size);

	long time = System.currentTimeMillis();
	int lru = -1;
	long lruTime = time;
	boolean ok = false;
	for(int col=0; col<assoc; col++) {
	    Block b = cache[row][col];
	    if(b==null) {
		cache[row][col] = new Block(key, val, time);
		ok=true;
		break;
	    } else if(b.key.equals(key)) {
		b.time = time;
		ok=true;
		break;
	    } else {
		if(b.time < lruTime) {
		    lru = col;
		    lruTime = b.time;
		}
	    }
	}
	if(!ok)
	    cache[row][lru] = new Block(key,val,time);
    }

    public Object get(Object key) {
	if(!enabled) return null;
	
	int row = getRow(key, size);

	for(int col=0; col<assoc; col++) {
	    Block b = cache[row][col];
	    if(b!=null && b.key.equals(key)) {
		b.time = System.currentTimeMillis();
		return b.value;
	    }
	}

	return null;
    }

    public void paramChanged(String param, String value){
	if(param.equals(paramPrefix+"enabled"))
	    enabled = Boolean.getBoolean(value);
	else if(param.equals(paramPrefix+"size")) {
	    Block[][] oldCache = cache;
	    int oldSize = size;
	    int oldAssoc = assoc;

	    Pair p = splitSize(value);
	    size = Integer.parseInt((String)p.a);
	    assoc = Integer.parseInt((String)p.b);
	    cache = new Block[size][assoc];

	    for(int i=0; i<oldSize; i++)
		for(int j=0; j<oldAssoc; j++)
		    if(oldCache[i][j]!=null)
			put(oldCache[i][j].key, oldCache[i][j].value);
	} 
    }
    
    public void paramSaving() {
	if(Params.getBoolean(paramPrefix+"save on exit")) {
	    try{
		File f = new File(Params.getProperty(paramPrefix+"file"));
		f.getParentFile().mkdirs();
		f.createNewFile();
		FileOutputStream ostream = new FileOutputStream(f);
		ObjectOutputStream p = new ObjectOutputStream(ostream);
	    
		p.writeObject(cache);
		
		p.flush();
		ostream.close();
	    } catch (Exception E) { System.out.println(E); }
	}
    }
    
    public void paramRegistered(String param, String value){}
    
}
