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

import org.jdom.*;
import java.util.*;

public class Family {
    private String name = "";
    private Boolean closed = Boolean.FALSE;
    private String pos = "";
    private DataModel data = new DataModel();
    private EntriesModel entries = new EntriesModel();

    public Family(Element famel) {
	name = famel.getAttributeValue("name");

	pos = famel.getAttributeValue("pos");

	String isClosed = famel.getAttributeValue("closed");
	if(isClosed != null && isClosed.equals("true"))
	    setClosed(Boolean.TRUE);

	EntriesModel em = new EntriesModel();
	List entries = famel.getChildren("entry");
	for(int j=0; j<entries.size(); j++)
	    em.addItem(new EntriesItem((Element)entries.get(j)));
	setEntries(em);

 	DataModel dm = new DataModel();
	List members = famel.getChildren("member");
	for(int j=0; j<members.size(); j++)
	    dm.addItem(new DataItem((Element)members.get(j)));
	setData(dm);			
    }


    public Family(String s) { name = s; }
	
    public void setName(String s) { name = s; }
    public void setClosed(Boolean b) { closed = b; }
    public void setPOS(String s) { pos = s; }
    public void setData(DataModel dm) {	data = dm; }
    public void setEntries(EntriesModel em) { entries = em; }

    public String getName() { return name; }
    public Boolean getClosed() { return closed; }
    public String getPOS() { return pos; }
    public DataModel getData() { return data; }
    public EntriesModel getEntries() { return entries; }
    
}
