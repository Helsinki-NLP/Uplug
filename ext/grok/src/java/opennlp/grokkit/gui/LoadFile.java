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

import javax.swing.JFrame;
import javax.swing.JFileChooser;
    
public class LoadFile extends JFrame {
    JFileChooser fc;
    
    public LoadFile(String extension, String curDir){
	super();
	fc = new JFileChooser(curDir);
	fc.setFileFilter(new ExtensionFileFilter(extension));
    }

    public String getFile() {
	int returnVal = fc.showOpenDialog(this);
	if (returnVal==JFileChooser.APPROVE_OPTION) {
	    return fc.getSelectedFile().getAbsolutePath();
	} else {
	    return null;
	}
    }

}
