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

package opennlp.grok.datarep;

import java.util.ArrayList;
import javax.swing.event.TableModelEvent;
import javax.swing.event.TableModelListener;

/**
 * A way of displaying lexicon data.
 *
 * @author      Jason Baldridge
 * @version $Revision$, $Date$
 */
public class DataModel extends ArrayList {
    private ArrayList listeners = new ArrayList();

    private final int stem = 0;
    private final int pred = 1;

    public DataModel() {}

    public int getRowCount() { return size(); }
    public int getColumnCount() { return 2; }
    public Class getColumnClass(int c) { return String.class; }   
    public boolean isCellEditable(int r, int c) { return true; }

    public String getColumnName(int c) {
        switch (c) {
        case stem: return "STEM";
        default: return "PRED";
	}
    }
    
    public Object getValueAt(int r, int c) {
	DataItem di = getItem(r);
	switch(c) {
	case stem: return di.getStem();
	default: return di.getPred();
	}
    }

    public void setValueAt(Object val, int r, int c) {
	DataItem di = getItem(r);
	switch(c) {
	case stem: di.setStem((String)val); break;
	default: di.setPred((String)val);
	}
    }
    
    public void addNew() { addItem(new DataItem()); }
    public void removeItem(int r) {
	remove(r);
    }
    
    public DataItem getItem(int r) { return (DataItem)get(r); }
    public void addItem(DataItem di) {
        add(di);
    }
    
    public boolean hasComment() { return true; }    
    public String getComment(int r) { return getItem(r).getComment(); }
    public void setComment(int r, String s) { getItem(r).setComment(s); }


    
}
