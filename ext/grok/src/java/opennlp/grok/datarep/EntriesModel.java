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
 * A way of displaying a familie's categories
 *
 * @author      Jason Baldridge
 * @version $Revision$, $Date$
 */
public class EntriesModel extends ArrayList {
    private ArrayList listeners = new ArrayList();

    private final int name = 0;
    private final int stem = 1;
    private final int cat = 2;
    private final int sem = 3;
    private final int active = 4;

    public int getRowCount() { return size(); }
    public int getColumnCount() { return 5; }
    public Class getColumnClass(int c) {
	if(c==4) return Boolean.class;
	else return String.class;
    }
    public boolean isCellEditable(int r, int c) { return true; }

    public String getColumnName(int c) {
        switch (c) {
        case name: return "NAME";
        case stem: return "STEM";
        case cat: return "CAT";
        case sem: return "SEM";
        default: return "ACTIVE";
	}
    }

   public Object getValueAt(int r, int c) {
       EntriesItem ei = getItem(r);
       switch(c) {
       case name: return ei.getName();
       case stem: return ei.getStem();
       case cat: return ei.getCat();
       case sem: return ei.getSem();
       default: return ei.getActive();
       }
   }

    public void setValueAt(Object val, int r, int c) {
	EntriesItem ei = getItem(r);
	switch(c) {
	case name: ei.setName((String)val); break;
	case stem: ei.setStem((String)val); break;
	    //case cat: ei.setCat((String)val); break;
	case sem: ei.setSem((String)val); break;
	default: ei.setActive((Boolean)val);
	}
    }
    

    public void addNew() { addItem(new EntriesItem()); }

    public EntriesItem getItem(int r) { return (EntriesItem)get(r); }    

    public void removeItem(int r) {
	remove(r);
    }
    
    public void addItem(EntriesItem ei) {
        add(ei);
    }

    public boolean hasComment() { return true; }   
    public String getComment(int r) { return getItem(r).getComment(); }
    public void setComment(int r, String s) { getItem(r).setComment(s); }

   
}
