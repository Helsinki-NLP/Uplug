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

package opennlp.grok.lexicon;

import opennlp.grok.expression.*;
import opennlp.grok.unify.*;
import opennlp.grok.util.*;
import opennlp.grok.datarep.*;
import opennlp.grok.io.*;
import opennlp.hylo.*;
import opennlp.common.parse.*;
import opennlp.common.synsem.*;
import opennlp.common.unify.*;
import opennlp.common.util.*;

import java.rmi.*;
import java.util.*;
import java.net.*;


/**
 * Grabs Constituents from LMR grammars.
 *
 * @author      Gann Bierner
 * @version     $Revision$, $Date$
 */

public class LMRLexicon extends LexiconAdapter {

    private CategoryFcn semanticDefaultReplacer;
    
    static { 
	Debug.Register("Lexicon", false); 
    }

    MorphData _morphServer;

    HashMap _closed = new HashMap();
    GroupMap _words;
    GroupMap _stems;
    GroupMap _macros;
    GroupMap _defaultMacros;

    GroupMap _posToEntries;
    
    /*************************************************************
     * Constructor
     *************************************************************/
    public LMRLexicon(Properties g) {
	super(g);

	LexiconModel lexicon = null;
	MacroModel macroModel = null;
	MorphModel morph = null;

	try {
	    lexicon =
		LexiconReader.getLexicon(new URL(g.getProperty("lexicon")).openStream());
	}
	catch (Exception e) { 
	    System.out.println("Unable to load lexicon.");
	    System.out.println(e); 
	}

	try {
	    macroModel =
		MacroReader.getMacro(new URL(g.getProperty("morphology"))
				   .openStream());
	} 
	catch (Exception e) { 
	    System.out.println("Unable to load macros.");
	    System.out.println(e); 
	}
	
	try {
	    morph =
		MorphReader.getMorph(new URL(g.getProperty("morphology"))
				 .openStream());
	} 
	catch (Exception e) { 
	    System.out.println("Unable to load morphology.");
	    System.out.println(e); 
	}

	// index the words
	_words = new GroupMap();
	for(Iterator I=morph.iterator(); I.hasNext();) {
	    MorphItem mi = (MorphItem)I.next();
	    _words.put(mi.getWord(), mi);
	}

	// index entries based on stem+pos
	_stems = new GroupMap();
	_posToEntries = new GroupMap();

	HashSet pHeads = new HashSet();
	
	for(Iterator L=lexicon.iterator(); L.hasNext();) {
	    Family family = (Family)L.next();
	    
	    EntriesModel entries = family.getEntries();
	    DataModel data = family.getData();

	    // for generic use when we get an unknown stem
	    // from the morphological analyzer
	    _posToEntries.put(family.getPOS(), entries);

	    // scan through entries
	    for(Iterator E=entries.iterator(); E.hasNext();) {
		EntriesItem eItem = (EntriesItem)E.next();
		_closed.put(eItem, family.getClosed());
		
		if(!eItem.getStem().equals(""))
		    _stems.put(eItem.getStem()+family.getPOS(), eItem);
	    }

	    // scan through data
	    for(Iterator D=data.iterator(); D.hasNext();) {
		DataItem dItem = (DataItem)D.next();
		
		_stems.put(dItem.getStem()+family.getPOS(),
			  new Pair(dItem,entries));
	    }
	}


	// index the macros
	_macros = new GroupMap();
	_defaultMacros = new GroupMap();
	for(Iterator M=macroModel.iterator(); M.hasNext();) {
	    MacroItem mi = (MacroItem)M.next();
	    List specs = mi.getSpecs();
	    for(Iterator S=specs.iterator(); S.hasNext();)
		putMacro(mi.getName().startsWith("%")? _defaultMacros : _macros,
			 mi.getName(),
			 (String)S.next());
	}


	_morphServer = new XtagMorphData(g);
    }


    public MorphData getMorphData() { 
	return _morphServer;
    }


    public Collection getWord (String w) throws LexException {
	// get macros from internal (small) data structure
	Collection morphItems = (Collection)_words.get(w);

	// get macros from the morph server
	Collection morphsFromDB = null;
	if(_morphServer!=null) { // && morphItems.isEmpty()) {
	    morphsFromDB = _morphServer.getMorphItems(w);
	}
	
	// condense our macros
	if(morphItems==null && morphsFromDB==null)
	    throw new LexException(w + " not in lexicon");
	else if(morphItems==null)
	    morphItems = morphsFromDB;
	else if(morphsFromDB!=null)
	    morphItems.addAll(morphsFromDB);

	
	/////////////////////////////////////////////
        if (Debug.On("Lexicon"))                   //
	    show(morphItems, w);
        /////////////////////////////////////////////
	
	SignHash result = new SignHash();
	for(Iterator MI = morphItems.iterator(); MI.hasNext();)
	    getWithMorphItem(w, (MorphItem)MI.next(), result);

	/////////////////////////////////////////////
        if (Debug.On("Lexicon"))                   //
            System.out.println(result.values());   //
        /////////////////////////////////////////////

	return result.values();
    }


    // given MorphItem
    private void getWithMorphItem (String w, MorphItem mi, SignHash result) {

	//HashSet defMacros = (HashSet)_defaultMacros.get("%"+mi.getPOS());
	//if (defMacros == null) 
	//    defMacros = new HashSet();

	HashSet defMacros = new HashSet();

	HashSet macros = new HashSet();
	Collection newMacros = mi.getMacros();
	if(newMacros!=null) macros.addAll(newMacros);

	String stem = mi.getStem();
	String pos = mi.getPOS();

	// if we have this stem in our lexicon
	if(_stems.containsKey(stem+pos)) {
	    Collection stemItems = (Collection)_stems.get(stem+pos);

	    for(Iterator I=stemItems.iterator(); I.hasNext();) {
		Object item = I.next();

		// see if it's an EntriesItem
		if(item instanceof EntriesItem) {
		    getWithEntriesItem (w, 
					w, 
					(EntriesItem)item,
					(HashSet)macros.clone(), 
					defMacros,
					null, 
					result);
		}
		// otherwise it has to be a Pair containing a DataItem and 
		// an EntriesModel
		else {
		    getWithDataItem(w,
				    (DataItem)((Pair)item).a,
				    (EntriesModel)((Pair)item).b,
				    (HashSet)macros.clone(), 
				    defMacros,
				    result);
		}
	    }
	}
	// it's not in our lexicon so we have to make it up.
	else {
	    Collection entrySets = (Collection)_posToEntries.get(pos);
	    DataItem di = new DataItem();
	    di.setStem(stem);
	    di.setPred(stem);
	    for(Iterator E=entrySets.iterator(); E.hasNext();)
		getWithDataItem(w, 
				di, 
				(EntriesModel)E.next(),
				(HashSet)macros.clone(), 
				defMacros, 
				result);
	}
    }

    // given DataItem
    private void getWithDataItem (String w, 
				  DataItem item, 
				  EntriesModel entries,
				  HashSet macros, 
				  HashSet defaultMacros,
				  SignHash result) {

	macros.addAll(item.getFeat());
	for(Iterator I=entries.iterator(); I.hasNext();) {
	    EntriesItem ei = (EntriesItem)I.next();
	    if(ei.getStem().equals("[*DEFAULT*]"))
		getWithEntriesItem(w,
				   item.getStem(),
				   ei,
				   macros, 
				   defaultMacros,
				   item.getLF(), 
				   result);
	}
    }


    private String REPLACEMENT = "";
    private ModFcn defaultReplacer = new ModFcn() {
	public void modify (Mutable m) {
	    if (m instanceof Proposition 
		&& ((Proposition)m).toString().equals("[*DEFAULT*]")) {
		((Proposition)m).setAtomName(REPLACEMENT);
	    }
	}};

    // given EntriesItem
    private void getWithEntriesItem (String w, 
				     String stem, 
				     EntriesItem item,
				     HashSet macros, 
				     HashSet defaultMacros,
				     LF lf,
				     SignHash result) {
	
	if(!item.getActive().booleanValue()) 
	    return;

	Category cat = item.getCat().copy();
	REPLACEMENT = stem;
	cat.deepMap(defaultReplacer);

	if (lf != null) {
	    CatReader.mergeLF(cat, lf);
	}
	
	result.insert(new GSign(w, cat));

	//try {
	//   result.insert(
	//	    getWithStringInfo(w, 
	//			      stem,
	//			      pred,
	//			      //makeSemantics(item.getCat(), pred), 
	//			      macros, 
	//			      defaultMacros,
	//			      pred,
	//			      //makeSemantics(item.getSem(), pred),
	//			      ((Boolean)closed.get(item)).booleanValue()));
	//catch (UnifyException UE) {}
    }


    // given final string representations
//    private Constituent getWithStringInfo (String word, 
//					     String stem, 
//					     String cat,
//					     HashSet macros, 
//					     HashSet defaultMacros,
//					     String sem, 
//					     boolean closed) {
//
//
//	  // acount for multi-word lexical items
//	  //sem = multiWordSemantics(sem, stem);
//	  //cat = multiWordSyntax(cat, stem);
//
//	  System.out.println("!!!!!!!! " + word + " : " + stem + " : " + cat + " : " + sem);
//	  
//	  Category c = null;
//	  try {
//	      c = addMacros(CategoryHelper.makeSyntax(cat),
//			    macros,
//			    defaultMacros);
//	  }
//	  catch (CatParseException e) {
//	      System.out.println("Unable to create category: " + cat);
//	      System.out.println(e);
//	  }
//
//	  // check to see if we have a bundle already and return it, ignoring
//	  // presuppositions
//	  //if (sem.equals("")) return new Word(word, c);
//	  //
//	  //Stack semAndPresups = CategoryHelper.makeSemantics(sem, presup);
//	  //Denoter s = (Denoter)semAndPresups.pop();
//	  //Denoter presupCat = new AltSet(null, semAndPresups.toArray());
//
//	  // transfer appropriate syn features to sem
//	  //if(c.getFeature()!=null) {
//	  //    Feature filtered = c.getFeature().filter(filterFcn);
//	  //    if(s.getFeature()==null)
//	  //	  s.setFeature(filtered.copy());
//	  //    else
//	  //	  s.setFeature(s.getFeature().unify(filtered));
//	  //}
//	  //    
//	  //Word w = new Word(word, CategoryHelper.bundleUp(c, s, presupCat));
//	  //w.setClosedClass(closed);
//	  //return w;
//	  return new Word(word, c);
//    }

    
    /*************************************************************
     * Do some indexing for quick access
     *************************************************************/




    private void putMacro(GroupMap map, String name, String val) {
//	  if(val.startsWith("#") ||  val.startsWith("@")) {
//	      Collection newMacros=(Collection)macros.get(val);
//	      for(Iterator I=newMacros.iterator(); I.hasNext();) {
//		  Object next = I.next();
//		  if(next instanceof String)
//		      putMacro(map, name, (String)next);
//		  else
//		      map.put(name, next);
//	      }
//	  } else if(val.startsWith("_"))
//	      map.put(name, CatParse.getFeature(val));
//	  else
//	      map.put(name, CategoryHelper.makeSyntax(val));
    }

    /*************************************************************
     * create final strings representation
     *************************************************************/

    // go through a category and insert morph features.
    private static HashMap catIndices;
    private static HashMap featIndices;
    private static boolean indexedFeaturesSuccess=true;
    private static ModFcn addIndexedFeatures = new ModFcn() {
	public void modify(Mutable c) {
	    //if(c.getFeatureStructure()!=null 
	    //	 && c.getFeatureStructure().hasNameIndex()) {
	    //
	    //	  Integer index = c.getFeature().getNameIndex();
	    //	  Feature featF = (Feature)featIndices.get(index);
	    //	  Feature catF  = (Feature)catIndices.get(((AtomCat)c).getType()+
	    //						  index);
	    //
	    //	  if (featF!=null) {
	    //	      c.setFeatureStructure(c.getFeatureStructure().unify(featF));
	    //	  }
	    //	  if (catF!=null) {
	    //	      c.setFeatureStructure(c.getFeatureStructure().unify(catF));
	    //
	    //	  // a unification didn't work, so these
	    //	  // features are incompatible
	    //	  if(c.getFeatureStructure()==null) {
	    //	      indexedFeaturesSuccess = false;
	    //	      return c;
	    //	  }
	    //}
	    //return c;
	}};
	
    private Category addIndexedFeatures(HashMap catI, HashMap featI, Category c)
	throws UnifyFailure {
	catIndices = catI;
	featIndices = featI;
	indexedFeaturesSuccess = true;
	Category ans = c.copy();
	ans.deepMap(addIndexedFeatures);
	catIndices = null;
	featIndices = null;
	if(!indexedFeaturesSuccess) throw new UnifyFailure();
	return ans;
    }
	
    private Category addMacros(Category cat, HashSet macroSet,
			       HashSet defaultMacros)
	throws UnifyFailure {

	HashMap catIndices  = new HashMap();
	HashMap featIndices  = new HashMap();

	// collect all of the features of macroSet together
	//for(Iterator M=macroSet.iterator(); M.hasNext();) {
	//    String macro = (String)M.next();
	//    Collection features = (Collection)_macros.get(macro);
	//    
	//    for(Iterator F=features.iterator(); F.hasNext();) {
	//	  Object o = F.next();
	//	  if(o instanceof Feature) {
	//	      Integer index = ((Feature)o).getNameIndex();
	//	      Feature f = (Feature)featIndices.get(index);
	//	      if(f==null)
	//		  featIndices.put(index, o);
	//	      else
	//		  featIndices.put(index, f.unify((Feature)f));
	//	  }
	//	  else {
	//	      AtomCat newC = (AtomCat)o;
	//	      Integer index = newC.getFeature().getNameIndex();
	//	      Feature f = (Feature)catIndices.get(newC.getType()+index);
	//	      if(f==null)
	//		  catIndices.put(newC.getType()+index, newC.getFeature());
	//	      else
	//		  catIndices.put(newC.getType()+index, f.unify(newC.getFeature()));
	//	  }
	//    }
	//}
	
	// add in all the features from defaultMacros as long as they don't
	// conflict.
	//for(Iterator D=defaultMacros.iterator(); D.hasNext();) {
	//    Object o = D.next();
	//    Feature dF = (o instanceof Feature)? (Feature)o : ((Category)o).getFeature();
	//    Integer index = dF.getNameIndex();
	//    Feature f = (Feature)featIndices.get(index);
	//    Feature c = (Feature)catIndices.get(((AtomCat)o).getType()+index);
	//
	//    Feature unifyF=null;
	//    Feature unifyC=null;
	//    if(f!=null) unifyF = f.unify(dF);
	//    if(c!=null) unifyC = c.unify(dF);
	//
	//    if((f==null || unifyF!=null) &&
	//	 (c==null || unifyC!=null)) {
	//	  if(o instanceof Feature)
	//	      featIndices.put(index, unifyF);
	//	  else {
	//	      if(unifyC==null)
	//		  catIndices.put(((AtomCat)o).getType()+index, dF);
	//	      else
	//		  catIndices.put(((AtomCat)o).getType()+index, unifyC);
	//	  }
	//    }
	//}

	return addIndexedFeatures(catIndices, featIndices, cat);
    }
    
//    private String makeSemantics(String sem, String pred) {
//	  StringBuffer buf = new StringBuffer(sem);
//	  int start = sem.indexOf("[*DEFAULT*]");
//	  if(start==-1)
//	      return sem;
//	  else
//	      return
//		  makeSemantics(buf.replace(start, start+11, pred).toString(),
//				pred);
//    }


    
			 


    // little debugging method
    private void show (Collection c, String w) {
	if (c==null) return;
	StringBuffer foo = new StringBuffer(w).append(": ");
	for (Iterator i=c.iterator(); i.hasNext();)
	    foo.append(i.next().toString()).append(" || ");
	System.out.println(foo.toString());
    }

}
