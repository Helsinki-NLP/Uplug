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

public interface MWEModel {

    /**
     *  Finds the MWE (if any) at a position in the sequence of words.
     *
     * @param  l    An array of the words to be searched.
     * @param  pos  The position in the array of the first word of the MWE.
     * @return      <b>if</b> <code>null</code> then a MWE has not been found at that position, 
     *              <b>else</b> the longest MWE found at that position.
     */
    public String[] getMWE(String[] l, int pos);



    /**
     *  Adds a MWE to the model.
     *
     * @param  mweWords  The space separated MWE to add to the model.
     */
    public void addMWE(String mweWords);

}

