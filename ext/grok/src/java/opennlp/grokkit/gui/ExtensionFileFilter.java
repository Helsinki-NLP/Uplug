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
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU Lesser General Public
// License along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
//////////////////////////////////////////////////////////////////////////////

package opennlp.grokkit.gui;

import java.io.File;
import java.io.FilenameFilter;
import javax.swing.filechooser.FileFilter;

/**
 * Filters files according to a given extension.
 *
 * @author  Meghan Pike
 * @version $Revision$, $Date$
 */
public class ExtensionFileFilter extends FileFilter implements FilenameFilter {
    String extension = null;
    
    public ExtensionFileFilter (String ext) {
	extension = ext;
    }

    public boolean accept (File dir, String name) {
	int ext = name.indexOf(".");
	if (ext==-1) {
	    return false;
	} else {
	    return name.substring(ext+1).equals(extension);
	}
    }
    
    public boolean accept (File f) {
	if (f.isDirectory()) {
	    return true;
	}
	String n = f.getName();
	return accept(f.getParentFile(), n);
    }
    
    public String getDescription() {
	return "*." + extension;
    }

}
