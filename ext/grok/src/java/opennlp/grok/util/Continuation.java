///////////////////////////////////////////////////////////////////////////////
// Copyright (C) 2000 Jason Baldridge and Gann Bierner
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

package opennlp.grok.util;

/*
 * This is basic support for an exit or entry continuation.  An exit
 * continuation is simple meant to throw an exception which should be caught
 * in the same place that made the continuation.
 * <p>
 * An  entry continuation is returned by a procedure and is expected to
 * produce the next answer for the procedure if that one was unsatisfactory.
 */
public interface Continuation {
    public Object apply();
}
