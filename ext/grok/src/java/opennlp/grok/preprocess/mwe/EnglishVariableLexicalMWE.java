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

import java.io.*;
import java.util.zip.*;
import opennlp.maxent.*;
import opennlp.maxent.io.*;

/**
 *  A Fixed Lexicon Multi-Word Expression finder that uses "EnglishFixedLexicalMWE.data"
 *  for its content model.<p>
 *
 *  This finds both common and rare multi-word expressions which are completely fixed
 *  in English. Examples are "ad hoc", "au pair", "aes alienum", "ben trovato". Most
 *  are foreign language expressions which have been borrowed by English, although
 *  they might be analysable in their native language, the consitutent words make
 *  no sense when analysed with English grammar except as part of the MWE. Rather
 *  than extend the grammar to include these special usages it is much easier to
 *  treat the whole MWE as a lexicon entry with the right POS, semantic, etc. tags.
 *  <p>
 *
 *  Token tagging is delayed to a later stage in the pipeline.<p>
 *
 *  <pre>
 * &lt;?xml version="1.0" encoding="UTF-8"?&gt;
 * &lt;nlpDocument&gt;
 *   &lt;text&gt;
 *     &lt;p&gt;
 *       &lt;s&gt;
 *         &lt;t&gt;
 *           &lt;w&gt;ad&lt;/w&gt;
 *         &lt;/t&gt;
 *         &lt;t&gt;
 *           &lt;w&gt;hoc&lt;/w&gt;
 *         &lt;/t&gt;
 *       &lt;/s&gt;
 *     &lt;/p&gt;
 *   &lt;/text&gt;
 * &lt;/nlpDocument&gt;
 *
 * is transformed to:
 *
 * &lt;?xml version="1.0" encoding="UTF-8"?&gt;
 * &lt;nlpDocument&gt;
 *   &lt;text&gt;
 *     &lt;p&gt;
 *       &lt;s&gt;
 *         &lt;t type="mwe"&gt;
 *           &lt;w&gt;ad&lt;/w&gt;
 *           &lt;w&gt;hoc&lt;/w&gt;
 *         &lt;/t&gt;
 *       &lt;/s&gt;
 *     &lt;/p&gt;
 *   &lt;/text&gt;
 * &lt;/nlpDocument&gt;
 *
 * </pre>
 *
 *  This class just gets the MWE model, while the FixedLexicalMWE implements
 *  the matching algorithm.
 *
 * @author     Mike Atkinson
 * @created    10 March 2002
 * @version    $Revision$, $Date$
 */

public class EnglishVariableLexicalMWE extends LexicalMWE {
    private final static String nouns = "data/EnglishCompound.nouns.gz";
    private final static String adverbs = "data/EnglishCompound.advs.gz";
    private final static String adjectives = "data/EnglishCompound.adjs.gz";
    private final static String verbs = "data/EnglishCompound.verbs.gz";
    private final static String nonCompoundVerbs = "data/EnglishNonCompound.verbs.data";


    /**
     *  Constructor for the EnglishFixedLexicalMWE object, which creates the
     *  model.
     */
    public EnglishVariableLexicalMWE() {
        super(getModel(nouns, adverbs, adjectives, verbs, nonCompoundVerbs));
    }


    /**
     *  Creates the model from a data file.
     *
     * @param  name  Name of the data file, which is a resource available in
     *               this jar.
     * @return       The created Model
     */
    private static MWEModel getModel(String nouns, String adverbs, String adjectives, String verbs, String nonCompoundVerbs) {
        try {
            // nouns
            System.out.print("MWE adding nouns... ");
            InputStream resource = EnglishVariableLexicalMWE.class.getResourceAsStream(nouns);
            GZIPInputStream gzis = new GZIPInputStream(new BufferedInputStream(resource));
            InputStreamReader isr = new InputStreamReader(gzis);
            VariableMWEModelReader modelReader = new VariableMWEModelReader(isr, VariableMWEModelReader.NOUN);

            // adverbs
            System.out.print("adverbs... ");
            resource = EnglishVariableLexicalMWE.class.getResourceAsStream(adverbs);
            gzis = new GZIPInputStream(new BufferedInputStream(resource));
            isr = new InputStreamReader(gzis);
            modelReader.addData(isr, VariableMWEModelReader.ADVERB);


            // adjectives
            System.out.print("adjectives... ");
            resource = EnglishVariableLexicalMWE.class.getResourceAsStream(adjectives);
            gzis = new GZIPInputStream(new BufferedInputStream(resource));
            isr = new InputStreamReader(gzis);
            modelReader.addData(isr, VariableMWEModelReader.ADJECTIVE);

            // verbs
            System.out.println("verbs...");
            resource = EnglishVariableLexicalMWE.class.getResourceAsStream(verbs);
            gzis = new GZIPInputStream(new BufferedInputStream(resource));
            isr = new InputStreamReader(gzis);
            modelReader.addData(isr, VariableMWEModelReader.VERB);

            return modelReader.getModel();
        } catch (IOException e) {
            e.printStackTrace();
        }
        return null;
    }

}

