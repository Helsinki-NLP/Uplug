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

package opennlp.grok.expression;

import opennlp.grok.datarep.*;
import opennlp.grok.io.*;
import opennlp.grok.unify.*;
import opennlp.grok.util.*;
import opennlp.hylo.*;
import opennlp.common.synsem.*;
import opennlp.common.unify.*;
import org.jdom.*;
import java.util.*;

public class CatReader {
    
    public static Category getCat(Element catel) {
	Category cat = null;
	String catType = catel.getName();
	if (catType.equals("ac")) {    
	    cat =  new AtomCat(catel);
	} else if (catType.equals("cc")) {    
	    cat =  new CurriedCat(catel);
	} else if (catType.equals("v")) {
	    cat = new VarCat(catel);
	//} else if (catType.equals("sc")) {
	//    cat = new SetCat(catel);
	} else if (catType.equals("ec")) {
	    String parent = catel.getAttributeValue("parent");
	    Category pcat = (Category)LexiconReader.cathash.get(parent);
	    List ecEls = catel.getChildren();
	    pcat = pcat.copy();
	    Iterator toAdd = ecEls.iterator();
	    mergeLF(pcat, HyloHelper.getLF((Element)toAdd.next()));
	    Slash addSlash = new Slash((Element)toAdd.next());
	    Category addCat = getCat((Element)toAdd.next());
	    Arg arg = new BasicArg(addSlash, addCat);
	    if (pcat instanceof CurriedCat) {
		((CurriedCat)pcat).add(arg);
	    } else {
		pcat = new CurriedCat((TargetCat)pcat, arg);
	    }
	    return pcat;
	} else if (catType.equals("cat")) {
	    String ref = catel.getAttributeValue("ref");
	    return (Category)LexiconReader.cathash.get(ref);
	}

	//System.out.println(cat + ":\n" + vars);
	return cat;
    }

    public static void mergeLF (Category c, LF lf) {
	if (c instanceof AtomCat) {
	    AtomCat ac = (AtomCat)c;
	    LF original = ac.getLF();
	    try {
		ac.setLF((LF)Unifier.unify(original, lf));
	    } catch (UnifyFailure uf) {}

	    //if (original instanceof Op 
	    //	  && ((Op)original).getName().equals("conj")) {
	    //	  ((Op)original).addArgument(lf);
	    //} else {
	    //	  ac.setLF(new Op("conj", original, lf));
	    //}
	} else if (c instanceof CurriedCat) {
	    CurriedCat cc = (CurriedCat)c;
	    mergeLF(((CurriedCat)c).getResult(), lf);
	}
    }

}
