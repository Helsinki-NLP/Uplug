///////////////////////////////////////////////////////////////////////////////
// Copyright (C) 2002 Mike Atkinson
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

package opennlp.grok.preprocess.mwe;

import opennlp.common.util.PerlHelp;
import java.util.*;

/**
 *  A model holding the Fixed Lexicon Multi-Word Expressions.<p>
 *
 *  It uses the first word to index into a Map. As most first words for Fixed Lexicon
 *  MWEs are not normal English words they occur very infrequently except as part
 *  of the MWE. Therefore this algorithm is very fast only taking a single Hash Map
 *  lookup for words which do not start any MWE (the vast majority of words in any
 *  normal English text).
 *
 * @author     Mike Atkinson
 * @created    10 March 2002
 * @version    $Revision$, $Date$
 */

public class FixedMWEModel implements MWEModel {

    Map map = new HashMap();


    /**
     *  Finds if there is a MWE at a position in the sequence of words.
     *
     * @param  l    An array of the words to be searched.
     * @param  pos  The position in the array of the first word of the MWE.
     * @return      <code>true</code> when a MWE has been found at that position.
     */
    public boolean isFixedMWE(String[] l, int pos) {
        List list = (List) map.get(l[pos]);
        if (list != null) {
            for (Iterator i = list.iterator(); i.hasNext(); ) {
                ModelData mwe = (ModelData) i.next();
                if (mwe != null) {
                    try {
                        String[] mweWords = mwe.getWords();
                        for (int j = 1; j < mweWords.length; j++) {
                            if (!mweWords[j].equals(l[pos + j])) {
                                return false;
                            }
                        }
                        //for (int j = 0; j < mweWords.length; j++) {
                        //    System.out.print(mweWords[j]);
                        //    System.out.print(" ");
                        //}
                        //System.out.println(" found at " + pos);
                        return true;
                    }
                    catch (Exception e) {
                        return false;
                    }
                }
            }
        }
        return false;
    }


    /**
     *  Finds the MWE (if any) at a position in the sequence of words.
     *
     * @param  l    An array of the words to be searched.
     * @param  pos  The position in the array of the first word of the MWE.
     * @return      <b>if</b> <code>null</code> then a MWE has not been found at that position, 
     *              <b>else</b> the longest MWE found at that position.
     */
    public String[] getMWE(String[] l, int pos) {
        //System.out.println("getFixedMWE: "+l[pos]);
        List list = (List) map.get(l[pos]);
        if (list != null) {
            for (Iterator i = list.iterator(); i.hasNext(); ) {
                ModelData mwe = (ModelData) i.next();
                if (tryMWE(mwe, l, pos)) {
                    return mwe.getWords();
                }
            }
        }
        return null;
    }



    /**
     *  Adds a MWE to the model.
     *
     * @param  mweWords  The space separated MWE to add to the model.
     */
    public void addMWE(String mweWords) {
        String[] spaceSplit = PerlHelp.split(mweWords);
        if (spaceSplit.length<2) {
            System.out.println("+addFixedMWE: "+mweWords + " has a wrong format");
            return;
        }
        ModelData mwe = new ModelData(spaceSplit);
        String indexWord = spaceSplit[mwe.getIndexWord()];
        List l = (List) map.get(indexWord);
        if (l == null) {
            l = new ArrayList();
            map.put(indexWord, l);
        }
        l.add(mwe);
        //FIXME should sort in order of size
    }



    /**
     *  Tries to match a MWE with a sequence of words (the first word is already matched).
     *
     * @param  mwe  The Multi-word expression to try.
     * @param  l    The list of words
     * @param  pos  The position in the list of words of the first word of the MWE
     * @return      <code>true</code> if the MWE is found at that position.
     */
    private boolean tryMWE(ModelData mwe, String[] l, int pos) {
        String[] mweWords = mwe.getWords();
        try {
            for (int i = 1; i < mweWords.length; i++) {
                if (!mweWords[i].equals(l[pos + i])) {
                    return false;
                }
            }
            //for (int i = 0; i < mweWords.length; i++) {
            //    System.out.print(mweWords[i]);
            //    System.out.print(" ");
            //}
            //System.out.println(" found at " + pos);
            return true;
        }
        catch (Exception e) {
            return false;
        }
    }
    
    public static class ModelData {
        private String[] words;
        public ModelData(String[] words) {
            this.words = words;
        }
        public String[] getWords() { return words; }
        public int getIndexWord() { return 0; }
    }
}

