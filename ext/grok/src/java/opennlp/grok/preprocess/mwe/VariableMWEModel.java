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

public class VariableMWEModel implements MWEModel {

    Map map = new HashMap();


    /**
     *  Finds the MWE (if any) at a position in the sequence of words.
     *
     * @param  l    An array of the words to be searched.
     * @param  pos  The position in the array of the first word of the MWE.
     * @return      <b>if</b> <code>null</code> then a MWE has not been found at that position, 
     *              <b>else</b> the longest MWE found at that position.
     */
    public String[] getMWE(String[] l, int pos) {
        //System.out.println("getVariableMWE: "+l[pos]);
        for (int x=0; x<3; x++) {
            if (pos+x<l.length) {
                //System.out.println("x="+x+", trying="+l[pos+x]);
                List[] lists = (List[]) map.get(l[pos+x]);
                if (lists!=null && lists[x]!=null) {
                    for (Iterator i = lists[x].iterator(); i.hasNext(); ) {
                        ModelData mwe = (ModelData) i.next();
                        if (tryMWE(mwe, l, pos, x)) {
                            return mwe.getWords();
                        }
                    }
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
        try {
            String[] spaceSplit = PerlHelp.split(mweWords);
            if (spaceSplit.length<3) {
                System.out.println("+addVariableMWE: "+mweWords + " has a wrong format");
                return;
            }
            int n = Integer.parseInt(spaceSplit[0]);
            String[] newSplit = new String[spaceSplit.length-1];
            for (int i=0; i<spaceSplit.length-1; i++) {
                newSplit[i] = spaceSplit[i+1];
            }
            ModelData mwe = new ModelData(newSplit, n);
            String indexWord = newSplit[mwe.getIndexWord()];
            
            addMWE(indexWord, mwe);

            // add in some irregular verbs
            if (n==1 && newSplit[n-1].equals("lie")) {
                addMWE(indexWord, newSplit, 1, "lying");
            } else if (n==1 && newSplit[n-1].equals("die")) {
                addMWE(indexWord, newSplit, 1, "dying");
            } else if (n==1 && newSplit[n-1].equals("tie")) {
                addMWE(indexWord, newSplit, 1, "tying");
            } else if (n==1 && indexWord.endsWith("e")) {
                String newIndexWord = indexWord.substring(0,indexWord.length()-1)+"ing";
                newSplit[mwe.getIndexWord()] = "newIndexWord";
                mwe = new ModelData(newSplit, n);
                addMWE(newIndexWord, mwe);
            }
            
            //System.out.println("indexWord="+indexWord+", x="+mwe.getIndexWord());
            //FIXME should sort in order of size
        } catch (Exception e) {
            System.out.println("+addVariableMWE: "+mweWords + " has a wrong format");
        }
    }

    private void addMWE(String indexWord, String[] oldSplit, int n, String newStr) {
        String[] newSplit = new String[oldSplit.length];
        for (int i=0; i<oldSplit.length; i++) {
            newSplit[i] = oldSplit[i];
        }
        newSplit[n-1] = newStr;
        ModelData mwe = new ModelData(newSplit, n);
        addMWE(indexWord, mwe);
    }
    private void addMWE(String indexWord, ModelData mwe) {
        List[] l = (List[]) map.get(indexWord);
        if (l == null) {
            l = new List[3];
            map.put(indexWord, l);
        }
        if (l[mwe.getIndexWord()]==null) {
            l[mwe.getIndexWord()] = new ArrayList();
        }
        l[mwe.getIndexWord()].add(mwe);
    }

    /**
     *  Tries to match a MWE with a sequence of words (the first word is already matched).
     *
     * @param  mwe  The Multi-word expression to try.
     * @param  l    The list of words
     * @param  pos  The position in the list of words of the first word of the MWE
     * @return      <code>true</code> if the MWE is found at that position.
     */
    private boolean tryMWE(ModelData mwe, String[] l, int pos, int x) {
        //System.out.println("tryMWE(..,..,"+pos+","+x+")");
        String[] mweWords = mwe.getWords();
        try {
            for (int i = 0; i < mweWords.length; i++) {
                if (i==x) {
                    // already processed (map index)
                    //System.out.println("   - already processed: "+ l[pos + i]);
                } else if (i==mwe.getVariableWord()) {
                    //System.out.println("   - variable word: "+ l[pos + i]);
                    if (l[pos + i].indexOf(mweWords[i]) != 0) {
                        return false;
                    }
                } else {
                    if (!mweWords[i].equals(l[pos + i])) {
                        return false;
                    }
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
        private int variableWord;
        private int indexWord;
        public ModelData(String[] words) {
            this.words = words;
            this.variableWord = -1;
            this.indexWord=0;
        }
        public ModelData(String[] words, int variableWord) {
            this.words = words;
            this.variableWord = variableWord-1;
            if (this.variableWord>0) {
                this.indexWord=0;
            } else {
                this.indexWord=1;
            }
        }
        public String[] getWords() { return words; }
        public int getVariableWord() { return variableWord; }
        public int getIndexWord() { return indexWord; }
        public String toString() {
            StringBuffer sb = new StringBuffer();
            for (int i=0; i<words.length; i++) {
                sb.append(words[i]).append(" ");
            }
            return sb.toString();
        }
    }
}

