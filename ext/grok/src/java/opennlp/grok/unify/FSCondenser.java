package opennlp.grok.unify;

import opennlp.grok.expression.*;
import opennlp.common.synsem.*;
import opennlp.common.unify.*;
import gnu.trove.*;
import java.util.*;

public class FSCondenser {
    
    private TIntObjectHashMap _indicesToFeatStrucs;
    private Set _allFeatStrucs;
    
    public FSCondenser () {}


    public void condense (Substitution sub) {
	_indicesToFeatStrucs = new TIntObjectHashMap();
	_allFeatStrucs = new THashSet();

	// collect all the feature structures in the categories of the sub
	for (Iterator subIt = sub.varIterator(); subIt.hasNext();) {
	    Object val = sub.getValue((Variable)subIt.next());
	    if (val instanceof Category) {
		((Category)val).forall(fsCollector);
	    }
	}
	//printMap();
	//printFSs();
	
	// perform the inheritance
	for (Iterator fsIt = _allFeatStrucs.iterator(); fsIt.hasNext();) {
	    FeatureStructure fs = (FeatureStructure)fsIt.next();
	    int inheritorId = fs.getInheritorIndex();
	    if (inheritorId > 0) {
		FeatureStructure inheritor =
		    (FeatureStructure)_indicesToFeatStrucs.get(inheritorId);
		if (inheritor != null) {
		    inheritor.inherit(fs);

		    int id = fs.getIndex();
		    if (id > 0) {
			_indicesToFeatStrucs.put(id, inheritor);
		    }
		}
	    }
	}

	//printMap();
	
	// reindex
	for (Iterator fsIt = _allFeatStrucs.iterator(); fsIt.hasNext();) {
	    FeatureStructure fs = (FeatureStructure)fsIt.next();
	    int inheritorId = fs.getInheritorIndex();
	    if (inheritorId > 0) {
		FeatureStructure inheritor =
		    (FeatureStructure)_indicesToFeatStrucs.get(inheritorId);
		if (inheritor != null) {
		    fs.setInheritorIndex(inheritor.getIndex());
		}
	    }	    
	}

	_indicesToFeatStrucs.clear();
	_allFeatStrucs.clear();
    }

    private CategoryFcn fsCollector = new CategoryFcnAdapter() {
	public void forall (Category c) {
	    FeatureStructure fs = c.getFeatureStructure();
	    if (fs != null) {
		_allFeatStrucs.add(fs);
		int index = fs.getIndex();
		if (index > 0) {
		    _indicesToFeatStrucs.put(index, fs);
		}
	    }
	}};

    private void printMap() {
	System.out.println("### ");
	int[] keys = _indicesToFeatStrucs.keys();
	for (int i = 0; i<keys.length; i++) {
	    System.out.println(keys[i] + " => "
			       + _indicesToFeatStrucs.get(keys[i]));
	}
    }

    private void printFSs() {
	System.out.println("@@@");
	for (Iterator i=_allFeatStrucs.iterator(); i.hasNext();) {
	    System.out.println(i.next());
	}
    }
    
    public String toString () {
	StringBuffer sb = new StringBuffer();
	for (Iterator fsIt = _allFeatStrucs.iterator(); fsIt.hasNext();) {
	    sb.append(fsIt.next().toString()).append('\n');
	}
	return sb.toString();
    }

}
