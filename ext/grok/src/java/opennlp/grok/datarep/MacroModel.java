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
 * A way of displaying morphological macro information
 *
 * @author      Jason Baldridge
 * @version $Revision$, $Date$
 */
public class MacroModel extends ArrayList implements InfoTableModel {
    private ArrayList listeners = new ArrayList();

    public MacroModel() {}    

    public int getRowCount() { return size(); }
    public int getColumnCount() { return 1; }
    public Class getColumnClass(int c) { return String.class; }
    public boolean isCellEditable(int r, int c) { return true; }
    public String getColumnName(int c) { return "MACRO NAME"; }
    public Object getValueAt(int r, int c) { return getItem(r).getName(); }

    public void setValueAt(Object val, int r, int c) {
	getItem(r).setName((String)val);
    }
    
    public void addTableModelListener(TableModelListener l) {
	if (!listeners.contains(l)) listeners.add(l);
    }
    
    public void removeTableModelListener(TableModelListener l) {
	if (listeners.contains(l))
	    listeners.remove(listeners.indexOf(l));
    }

    public void addNew() { addItem(new MacroItem()); }
    public MacroItem getItem(int r) { return (MacroItem)get(r); }

    public void removeItem(int r) { 
	remove(r);
	notifyListeners();
    }

    public void addItem(MacroItem re) {
	add(re);
	notifyListeners();
    }

    public ArrayList getArray(int r) { return getItem(r).getSpecs(); }
    public void addArrayItem(String s, int row) { getItem(row).addSpec(s); }
    public void removeArrayItems(int[] intArray, int r) {
	ArrayList al = getArray(r);
	for(int i=intArray.length-1; i>=0; i--)
	    al.remove(intArray[i]);
    }

    public boolean hasComment() { return false; }
    public void setComment(int r, String comment) {}
    public String getComment(int r) { return ""; }

    public void notifyListeners() {
	TableModelEvent e = new TableModelEvent(this);
	for(int i=0; i<listeners.size(); i++)
            ((TableModelListener)listeners.get(i)).tableChanged(e);
    }
    
}
