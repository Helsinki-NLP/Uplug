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

package opennlp.grokkit;

import java.io.*;
import java.util.*;
import java.net.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.border.*;
import java.util.List;

import opennlp.common.generate.*;
import opennlp.common.parse.*;
import opennlp.common.*;
import opennlp.common.synsem.*;

import opennlp.grok.lexicon.*;
import opennlp.grok.grammar.*;
import opennlp.grok.parse.*;
import opennlp.grok.expression.*;
import opennlp.common.unify.*;
import opennlp.common.util.*;
import opennlp.common.preprocess.Pipelink;

import opennlp.grok.*;
import opennlp.grok.io.*;
import opennlp.grok.util.*;
import opennlp.grokkit.gui.*;


public class Grok extends Run {
    static grokkit GF;
    public static Color bgcolor = Color.lightGray;
    public static Color textBgcolor = Color.white;

    static {
	DEFAULTS.setProperty("GFwidth", "800");
	DEFAULTS.setProperty("GFheight","600");
	DEFAULTS.setProperty("GFx","200");
	DEFAULTS.setProperty("GFy","200");
    }

    public static ImageIcon getImage(String name) {
	return new ImageIcon(Grok.class.getResource("pix/" + name));
    }

    public static void display(Exception E) {
	GF.display(E);
    }

    public static void display(String s) {
	GF.display(s);
    }

    public static void main(String[] args) {
	loadParameters();
	GF = new grokkit(PARAMS);

	// setup splash screen
	JWindow splash = new JWindow();
	JLabel grokLabel = new JLabel(getImage("splash.gif"));
	splash.getContentPane().add(grokLabel);
	grokLabel.setHorizontalTextPosition(SwingConstants.CENTER);
	grokLabel.setVerticalTextPosition(SwingConstants.BOTTOM);
	grokLabel.setOpaque(true);
	grokLabel.setBackground(Color.white);
	grokLabel.setText("Starting...");
	splash.pack();
	int splashW = splash.getSize().width;
	int splashH = splash.getSize().height;
	int gfW = PARAMS.Int("GFwidth");
	int gfH = PARAMS.Int("GFheight");
	int gfX = PARAMS.Int("GFx");
	int gfY = PARAMS.Int("GFy");
	splash.setLocation(gfX+((gfW-splashW)/2), gfY+((gfH-splashH)/2));
	splash.setVisible(true);
	
	grokLabel.setText("loading grammar...");
	try{ init(); }
	catch (LexException L) { GF.display(L); }
	catch (IOException I) { GF.display(I); }
	catch (PipelineException P) { GF.display(P); }
	
	// setup grok frame
	grokLabel.setText("Loading gui...");
	splash.toFront();
	
	splash.setVisible(false);
	GF.show();
    }
}




///////////////////////////////
// Frame Class
///////////////////////////////


class grokkit extends JFrame {
    // gui variables
    JMenuBar menuBar1 = new JMenuBar();
    JMenu menuFile = new JMenu();
    JMenu menuHelp = new JMenu();
    JMenuItem menuDisplayHelp = new JMenuItem();
    JMenu menuEdit = new JMenu();
    JMenuItem menuEditReadme = new JMenuItem();
    JMenuItem menuEditMorph = new JMenuItem();
    JMenuItem menuEditLexicon = new JMenuItem();
    JMenuItem menuEditRules = new JMenuItem();
    JMenuItem menuEditGrammar = new JMenuItem();
    JMenuItem menuEditFlatMorph = new JMenuItem();
    JMenuItem menuFileExit = new JMenuItem();
    JMenuItem menuLoadGrammar = new JMenuItem();
    BorderLayout borderLayout1 = new BorderLayout();

    // tabbed pane
    JTabbedPane main = new JTabbedPane();
    JEditorPane NLP = new JEditorPane();
    JEditorPane plainText = new JEditorPane();
    JEditorPane chart = new JEditorPane();
    NLPTextComponent NLPText= new NLPTextComponent();
    JScrollPane sNLPPane = new JScrollPane(NLPText);
    JScrollPane nNLPPane = new JScrollPane(NLP);
    JScrollPane pNLPPane = new JScrollPane(plainText);
    JScrollPane cNLPPane = new JScrollPane(chart);

    JTextField inputText;
    JTextField outputText;
    Parameters PARAMS;
    Properties GRAMMAR;
    Grok grok;
    JLabel status = new JLabel("Status: Happy");
    JButton GROKButton = new JButton(Grok.getImage("brainTiny.gif"));

    // parsing variables
    Properties _grammarInfo = new Properties();
    Parser _parser;
    Pipeline _pipeline;
    Lexicon _lexicon;
    boolean showSyntax = true;
    boolean showSemantics = true;

    String[] ppLinks;
    ArrayList PPLinks = new ArrayList();

    String grokHome =
	new String(System.getProperties().getProperty("grok.dir"));
    String grammar_file = grokHome + "/samples/grammar/simple.gram";

    /////////////////////////////
    //  constructors
    /////////////////////////////

    public grokkit () {
	enableEvents(AWTEvent.WINDOW_EVENT_MASK);
	try {
	    Init();
	} catch (Exception e) {
	    e.printStackTrace();
	}
    }

    public grokkit (Parameters P) {
	super("Grok");
	PARAMS = P;
	setSize(800, 600);
	setLocation(200, 200);
	enableEvents(AWTEvent.WINDOW_EVENT_MASK);
	try {
	    Init();
	} catch (Exception e) {
	    e.printStackTrace();
	}
    }


    
  ///////////////////////////////////////
  // Useful methods nicked from grokling
  ///////////////////////////////////////
    void loadGrammar (URL grammar) throws IOException {
	_grammarInfo.load(grammar.openStream());

	String gram = grammar.toString();
	String dir = gram.substring(0, gram.lastIndexOf('/'));

	for(Iterator it = _grammarInfo.keySet().iterator(); it.hasNext();) {
	    String key = (String)it.next();
	    
	    String file = _grammarInfo.getProperty(key);

	    if(file.charAt(0)=='/')
		_grammarInfo.setProperty(key, "file:"+file);
	    else
		_grammarInfo.setProperty(key, dir+"/"+file);
	}
    }

    public Pair[] grok (String s)
	throws ParseException, PipelineException, LexException {

	if(s.equals("")) throw new ParseException("Nothing to Parse!");
	opennlp.common.xml.NLPDocument doc = _pipeline.run(s);
	NLP.setText(doc.toXml());

	List entries = _lexicon.getWords(doc);
	Chart table = ((CKY)_parser).getInitializedTable(entries);

	((CKY)_parser).parse(table , entries.size());
	System.setProperty("line.seperator", "\r");

	// Major hack approaching. //
	try {
	    //chart = new JEditorPane((new File(redirectChart(table))).toURL());
	    chart.read(new FileInputStream(new File(redirectChart(table))), null);
	} catch (MalformedURLException m) {
	    display(m);
	} catch (IOException o) {
	    display(o);
	}

	ArrayList interps = getPreferredResult(_parser.getResult());
	if (interps.isEmpty()) {
	    throw new ParseException("No result ");
	}

	Pair[] answers = new Pair[interps.size()];
	for (int curIndex=0; curIndex<answers.length; curIndex++) {
	    Sign constit = (Sign)interps.get(curIndex);
	    answers[curIndex] =
		new Pair(constit.getCategory().toString(), "no LF");
	}
	return answers;
    }

    public ArrayList grokAndReturnSigns (String s)
	throws ParseException, PipelineException, LexException {

	if(s.equals("")) throw new ParseException("Nothing to Parse!");
	opennlp.common.xml.NLPDocument doc = _pipeline.run(s);
	NLP.setText(doc.toXml());

	List entries = _lexicon.getWords(doc);
	Chart table = ((CKY)_parser).getInitializedTable(entries);

	((CKY)_parser).parse(table , entries.size());

	ArrayList interps = getPreferredResult(_parser.getResult());
	if (interps.isEmpty()) {
	    throw new ParseException("No result ");
	}

	return interps;
    }

    public String[] grokAndReturnStrings (String sentence)
	throws LexException, ParseException, IOException, PipelineException {

	Pair[] res = grok(sentence);
	String[] s = new String[res.length];
	if (showSyntax && showSemantics) {
	    for (int i=0; i< res.length; i++)
		s[i] = res[i].a.toString() + " : " + res[i].b.toString();
	} else if (showSemantics) {
	    for (int i=0; i< res.length; i++)
		s[i] = res[i].b.toString();
	} else {
	    for (int i=0; i< res.length; i++)
		s[i] = res[i].a.toString();
	}
	return s;
    }

    private ArrayList getPreferredResult (ArrayList unranked) {
	ArrayList reranked = new ArrayList();
	for (Iterator i=unranked.iterator(); i.hasNext();) {
	    Sign w=(Sign)i.next();
	    Category syn =w.getCategory();
	    if (syn instanceof AtomCat) {
		String type = ((AtomCat)syn).getType();
		if (type.equals("s")) {
		    reranked.add(w);
		    i.remove();
		}
	    }
   	}
	for (Iterator i=unranked.iterator(); i.hasNext();) {
	    Sign w=(Sign)i.next();
	    Category syn =w.getCategory();
	    if (syn instanceof AtomCat) {
		String type = ((AtomCat)syn).getType();
		if (type.equals("n")) {
		    reranked.add(w);
		    i.remove();
		}
	    }
	}
	reranked.addAll(unranked);
	return reranked;
    }

    private String redirectChart (Chart table) {
	try {
	    PrintStream temp = System.out;
	    PrintStream newOut =
		new PrintStream(new BufferedOutputStream(new FileOutputStream(new File(grokHome + "/samples/grammar/chart.txt"))));
	    System.setOut(newOut);
	    table.printChart();
	    newOut.flush();
	    newOut.close();
	    System.setOut(temp);
	    return grokHome + "/samples/grammar/chart.txt";
	} catch(FileNotFoundException e) {}
	return "";
    }

    ////////////////////////////////
    //Component initialization
    ////////////////////////////////

    // makes a nice menu for the preprocess pipelinks
    private JMenu initPPLinks(String userhome) {
	JMenu ppMenu = new JMenu("Preprocess");
	JMenuItem help = new JMenuItem("Click to add-to/remove-from pipeline");
	JMenuItem help2 = new JMenuItem("Warning: order sensitive [I think]");
	ppMenu.add(help);
	ppMenu.add(help2);
	ppMenu.addSeparator();
	
	File preprocess = new File(userhome + "/opennlp/grok/preprocess/");
	File[] insides = preprocess.listFiles();
	for (int i = 0; i < insides.length; i++) {
	    if (insides[i].isDirectory()) {
		File[] files = insides[i].listFiles();
		if (files == null) continue;
		JMenu submenu1 = new JMenu(insides[i].getName());
		ppMenu.add(submenu1);
		for (int n = 0; n < files.length; n++) {
		    if(files[n].isFile()) {
			String name = "opennlp.grok.preprocess."
			    + insides[i].getName() + "." + files[n].getName();
			if (name.endsWith(".class")) {
			    name = name.substring(0, name.length() - 6);
			}
			try {
			    Class test = Class.forName(name);
			    if (Pipelink.class.isAssignableFrom(test)) {
				JMenuItem classMI = new JRadioButtonMenuItem(name);
				if (name.equals("opennlp.grok.preprocess.sentdetect.EnglishSentenceDetectorME")
				    || name.equals("opennlp.grok.preprocess.tokenize.EnglishTokenizerME")) {
				    classMI.setSelected(true);
				    PPLinks.add(name);
				}
				classMI.addActionListener(new grokkit_menuPreprocessRadioButton_ActionAdapter(this));
				submenu1.add(classMI);
			    }
			} catch(ClassNotFoundException c) {}
		    }
		    //if(submenu1.getItemCount() == 0)
		    //ppMenu.remove(submenu1);   <- not really working
		}
	    }
	}
	return ppMenu;
    }

    // does the same but for PARAMS
    private JMenu initParams() {
	JMenu menuParams = new JMenu("Parameters");
	JMenuItem help = new JMenuItem("Click to flip parameters");
	JMenuItem help2 = new JMenuItem("Or type value");
	menuParams.add(help);
	menuParams.add(help2);
	menuParams.addSeparator();
	
	JMenu radios = new JMenu("Boolean Parameters:");
	JMenu type = new JMenu("Other:");
	menuParams.add(radios);
	menuParams.add(type);

	PARAMS.setProperty("Results:Use Filter", "false");
	PARAMS.setProperty("Display:CKY Chart", "false");
	PARAMS.setProperty("Display:Features", "false");
	PARAMS.setProperty("Enable:Databases", "false");
	PARAMS.setProperty("Results:All Derivs", "false");

	for (Enumeration e = PARAMS.propertyNames(); e.hasMoreElements(); ) {
	    String name = (String)e.nextElement();
	    String value = PARAMS.getProperty(name);
	    
	    if (value.equals("false") || value.equals("true")) {
		JMenuItem paramMI = new JRadioButtonMenuItem(name);
		if (value.equals("true")) paramMI.setSelected(true);
		radios.add(paramMI);
		paramMI.addActionListener(new grokkit_menuRadios_ActionAdapter(this));
	    } else {
		JLabel nameL = new JLabel(name);
		JTextField field = new JTextField(value);
		field.setText(value);
		field.setColumns(15);
		JPanel p = new JPanel();
		p.setLayout(new BorderLayout());
		p.add(nameL, BorderLayout.CENTER);
		p.add(field, BorderLayout.EAST);
		
		field.addActionListener(new grokkit_menuType_ActionAdapter(this));
		
		type.add(p);
	    }
	}
	return menuParams;
    }

    private void Init() throws Exception {
	setLocation(200, 200);
	
	// icon init
	Icon icon = Grok.getImage("brainBig.gif");
	if (icon!=null) setIconImage(((ImageIcon)icon).getImage());
	setBackground(Grok.bgcolor);
	
	// input panel init
	GridBagLayout ig = new GridBagLayout();
	GridBagConstraints ic = new GridBagConstraints();
	JPanel input = new JPanel(ig);
	ic.insets=new Insets(0,10,0,10);
	ic.fill = GridBagConstraints.HORIZONTAL;
	ic.gridwidth = GridBagConstraints.REMAINDER;
	ic.insets=new Insets(0,10,10,10);
	ic.gridwidth = 1;
	
	input.add(new JLabel(Grok.getImage("listen.gif")));
	inputText = new JTextField();
	//ExtendKeyMap.addEmacsBindings(inputText);
	inputText.setBackground(Grok.textBgcolor);
	inputText.setText("Hobbes devours mice");
	
	inputText.addActionListener(new grokkit_inputText_ActionAdapter(this));
	ic.fill = GridBagConstraints.HORIZONTAL;
	ic.weightx=1.0;
	ic.gridwidth=GridBagConstraints.REMAINDER;
	ig.setConstraints(inputText, ic);
	input.add(inputText);
	
	input.add(new JLabel(Grok.getImage("talk.gif")));
    
	outputText = new JTextField();
	outputText.setEditable(false);
	outputText.setBackground(Color.white);
	ig.setConstraints(outputText, ic);
	input.add(outputText);
	
	// main tabbed pane init
	main.addTab("XML Document", nNLPPane);
	main.addTab("Plain Text", pNLPPane);
	main.addTab("Chart", cNLPPane);
	main.addTab("NLP Document", sNLPPane);
	
	// Main main init
	this.getContentPane().setLayout(borderLayout1);
	this.setSize(new Dimension(800, 600));
	this.setTitle("Grok");

	// menu init
	menuFile.setText("File");
	menuFileExit.setText("Exit");
	menuHelp.setText("Help");
	menuDisplayHelp.setText("Help");
	menuLoadGrammar.setText("Set Grammar Path");
	menuDisplayHelp.addActionListener(new grokkit_menuDisplayHelp_ActionAdapter(this));
	menuLoadGrammar.addActionListener(new grokkit_menuLoadGrammar_ActionAdapter(this));
	menuFileExit.addActionListener(new grokkit_menuFileExit_ActionAdapter(this));

	// Edit menu
	menuEdit.setText("Edit");
	menuEditReadme.setText("Edit Readme");
	menuEditMorph.setText("Edit Morph.XML");
	menuEditLexicon.setText("Edit Lexicon.XML");
	menuEditRules.setText("Edit Rules.XML");
	menuEditGrammar.setText("Edit .gram file");
	menuEditFlatMorph.setText("Edit flat_morph_db");
	menuEdit.add(menuEditReadme);
	menuEdit.addSeparator();
	menuEdit.add(menuEditMorph);
	menuEdit.add(menuEditLexicon);
	menuEdit.add(menuEditRules);
	menuEdit.add(menuEditGrammar);
	menuEdit.add(menuEditFlatMorph);
	menuEdit.addSeparator();
	menuEditReadme.addActionListener(new grokkit_menuEdit_ActionAdapter(this));
	menuEditMorph.addActionListener(new grokkit_menuEdit_ActionAdapter(this));
	menuEditLexicon.addActionListener(new grokkit_menuEdit_ActionAdapter(this));
	menuEditRules.addActionListener(new grokkit_menuEdit_ActionAdapter(this));
	menuEditGrammar.addActionListener(new grokkit_menuEdit_ActionAdapter(this));
	menuEditFlatMorph.addActionListener(new grokkit_menuEdit_ActionAdapter(this));

	// adding menus to bar
	menuFile.add(menuLoadGrammar);
	menuFile.addSeparator();
	menuFile.add(menuFileExit);
	menuHelp.add(menuDisplayHelp);
	menuBar1.add(menuFile);
	menuBar1.add(menuEdit);
	menuBar1.add(initPPLinks(grokHome + "/output/classes"));
	menuBar1.add(initParams());
	menuBar1.add(menuHelp);
	
	this.setJMenuBar(menuBar1);
	
	// extra panel init
	JPanel seperator = new JPanel();
	BorderLayout updown = new BorderLayout();
	seperator.setLayout(updown);
	
	JPanel grokButton = new JPanel();
	BorderLayout cenleft = new BorderLayout();
	grokButton.setLayout(cenleft);
	grokButton.add(input, BorderLayout.CENTER);
	grokButton.add(GROKButton, BorderLayout.EAST);
	
	seperator.add(grokButton, BorderLayout.SOUTH);
	
	GROKButton.addActionListener(new grokkit_grokButton_ActionAdapter(this));
	
	// add everything to content pane
	this.getContentPane().add(seperator, BorderLayout.NORTH);
	this.getContentPane().add(main, BorderLayout.CENTER);
	this.getContentPane().add(status, BorderLayout.SOUTH);
	
	File f = new File(".");
	//System.out.println("HOME:" + f);
	//System.out.println("Grok Home:" + grokHome);
    }
    

    ////////////////////////////////////////////
    // Calls to Inner Event classes.
    ////////////////////////////////////////////

    protected void processWindowEvent(WindowEvent e) {
	super.processWindowEvent(e);
	if (e.getID() == WindowEvent.WINDOW_CLOSING) {
	    fileExit_actionPerformed(null);
	}
    }

    protected void fileExit_actionPerformed(ActionEvent e) {
	System.exit(0);
    }

    void display (String s) {
	String err =
	    "An internal error occurred.\n" +
	    "Please report this message to the maintainers\n" +
	    "As well as the garbage that probably appeared" +
	    "in your terminal window\n\n";
	System.out.println(err + " ERROR " + s);
	status.setText("Status: ERROR");
	JOptionPane.showMessageDialog(this, err+s, "Error", JOptionPane.ERROR_MESSAGE);
    }

    void display(Exception e) {
	System.out.println(" ERROR " + e);
	status.setText("Status: ERROR");
	JOptionPane.showMessageDialog(this, e.toString(), "Error", JOptionPane.ERROR_MESSAGE);
    }
}


///////////////////////////////////////
//  Outside event classes.
///////////////////////////////////////

class grokkit_menuFileExit_ActionAdapter implements ActionListener {
    grokkit adaptee;
    
    grokkit_menuFileExit_ActionAdapter(grokkit adaptee) {
	this.adaptee = adaptee;
    }

    public void actionPerformed(ActionEvent e) {
	adaptee.fileExit_actionPerformed(e);
    }
}

class grokkit_menuType_ActionAdapter implements ActionListener {
    grokkit adaptee;
    
    grokkit_menuType_ActionAdapter(grokkit adaptee) {
	this.adaptee = adaptee;
    }
    
    public void actionPerformed(ActionEvent e) {
	adaptee.PARAMS.setProperty(e.getActionCommand(),
				   ((JTextField)e.getSource()).getText());
    }
}

class grokkit_menuRadios_ActionAdapter implements ActionListener {
  grokkit adaptee;

    grokkit_menuRadios_ActionAdapter(grokkit adaptee) {
	this.adaptee = adaptee;
    }

    public void actionPerformed (ActionEvent e) {
	if ((adaptee.PARAMS.getProperty(e.getActionCommand())).equals("true")) {
	    adaptee.PARAMS.setProperty(e.getActionCommand(), "false");
	} else {
	    adaptee.PARAMS.setProperty(e.getActionCommand(), "true");
	}
    }
}

class grokkit_menuEdit_ActionAdapter implements ActionListener {
    grokkit adaptee;
    
    grokkit_menuEdit_ActionAdapter(grokkit adaptee) {
	this.adaptee = adaptee;
    }

    public void actionPerformed(ActionEvent e) {
	String command = e.getActionCommand();
	adaptee.status.setText("Status: Editing");
	
	JFrame edit = new JFrame("Edit");
	edit.setDefaultCloseOperation(WindowConstants.DISPOSE_ON_CLOSE);
	JScrollPane scroll;
	File url = new File("");
	BorderLayout bored = new BorderLayout();

	if (command.equals("Edit Readme")) {
	    url = new File(adaptee.grokHome + "/samples/grammar/Readme");
	} else if (command.equals("Edit Morph.XML")) {
	    url = new File(adaptee.grokHome + "/samples/grammar/morph.xml");
	} else if (command.equals("Edit Lexicon.XML")) {
	    url = new File(adaptee.grokHome + "/samples/grammar/lexicon.xml");
	} else if (command.equals("Edit Rules.XML")) {
	    url = new File(adaptee.grokHome + "/samples/grammar/rules.xml");
	} else if (command.equals("Edit .gram file")) {
	    if(adaptee.grammar_file.equals("")) {
		url = new File(adaptee.grokHome +
			       "/samples/grammar/simple.gram");
	    } else {
		url = new File(adaptee.grammar_file);
	    }
	} else if (command.equals("Edit flat_morph_db")) {
	    url = new File(adaptee.grokHome + "/samples/grammar/flat_morph_db");
	}

	try {
	    final JEditorPane main = new JEditorPane(url.toURL());
	    scroll = new JScrollPane(main);
	    final File url2 = new File(url.toString());
	    JButton save = new JButton("Save");
	    save.addActionListener(new ActionListener() {
		public void actionPerformed(ActionEvent eSave) {
		    try {
			main.write(new FileWriter(url2));
		    } catch(IOException k) {
			System.out.println("Error saving: " + k);
			adaptee.display(k);
		    }
		}
	    });

	    JPanel buttonPanel = new JPanel();
	    buttonPanel.setLayout(new BorderLayout());
	    buttonPanel.add(save, BorderLayout.WEST);

	    main.setEditable(true);
	    edit.getContentPane().setLayout(bored);
	    edit.getContentPane().add(buttonPanel, BorderLayout.SOUTH);
	    edit.getContentPane().add(scroll);
	    edit.setSize(new Dimension(500, 600));
	    edit.setLocation(200, 200);
	    edit.show();
	} catch(MalformedURLException r) {
	    adaptee.display(r);
	} catch(IOException o) {
	    adaptee.display(o);
	}
	adaptee.status.setText("Status: Happy");
    }
}

class grokkit_menuDisplayHelp_ActionAdapter implements ActionListener {
    grokkit adaptee;

    grokkit_menuDisplayHelp_ActionAdapter(grokkit adaptee) {
	this.adaptee = adaptee;
    }

    public void actionPerformed(ActionEvent e) {
	try {
	    JFrame help = new JFrame("Help");
	    help.setDefaultCloseOperation(WindowConstants.DISPOSE_ON_CLOSE);
	    File dir = new File(adaptee.grokHome + "/samples/grammar/Readme");
	    JEditorPane pane = new JEditorPane(dir.toURL());
	    JScrollPane spane = new JScrollPane(pane);
	    pane.setEditable(false);
	    help.getContentPane().add(spane);
	    help.setSize(new Dimension(500, 600));
	    help.setLocation(200, 200);
	    help.show();
	} catch(Exception ee) {}
    }
}

class grokkit_menuLoadGrammar_ActionAdapter implements ActionListener {
    grokkit adaptee;
    
    grokkit_menuLoadGrammar_ActionAdapter(grokkit adaptee) {
	this.adaptee = adaptee;
    }

    public void actionPerformed(ActionEvent e) {
	adaptee.status.setText("Status: Out of Focus");
	File home = new File(".");
	JFileChooser fc = new JFileChooser(home);
	fc.setFileFilter(new ExtensionFileFilter("gram"));

	int returnVal = fc.showOpenDialog(adaptee);
	if (returnVal == JFileChooser.CANCEL_OPTION) {
	    adaptee.status.setText("Status: Canceled");
	}
	else if (returnVal==JFileChooser.APPROVE_OPTION) {
	    adaptee.grammar_file =fc.getSelectedFile().getAbsolutePath();
	    adaptee.status.setText("Status: File-> "
				   + fc.getSelectedFile().getAbsolutePath());
	}
    }
}

class grokkit_grokButton_ActionAdapter implements ActionListener {
    grokkit adaptee;

    grokkit_grokButton_ActionAdapter(grokkit adaptee) {
	this.adaptee = adaptee;
    }

    public void actionPerformed(ActionEvent e) {
	Icon icon = Grok.getImage("brainBig.gif");
	String message= "by Gann Bierner and Jason Baldridge\n\n" +
	    "Copyright 2002\n"; 
	JOptionPane.showMessageDialog(adaptee, message, "About Grok",
				      JOptionPane.
				      INFORMATION_MESSAGE,
				      icon);
    }
}

class grokkit_inputText_ActionAdapter implements java.awt.event.ActionListener {
    grokkit adaptee;
    
    grokkit_inputText_ActionAdapter(grokkit adaptee) {
	this.adaptee = adaptee;
    }

    public void actionPerformed(ActionEvent e) {
	////////////////////////////////////////
	// Mostly the main method from grokling
	////////////////////////////////////////
	adaptee.status.setText("Status: Parsing");
	String[] ppLinks = {};
	ppLinks = (String[])adaptee.PPLinks.toArray(ppLinks);
	if (adaptee.grammar_file.equals("")) {
	    adaptee.grammar_file =adaptee.grokHome +
		"/samples/grammar/simple.gram";
	}
	
	File f = new File(adaptee.grammar_file);
	try {
	    adaptee.loadGrammar(f.toURL());
	} catch (MalformedURLException w) {
	    adaptee.display(w);
	} catch (IOException i) {
	    adaptee.display(i);
	}

	adaptee._lexicon = new LMRLexicon(adaptee._grammarInfo);
	RuleGroup rules =
	    RuleReader.getRules(adaptee._grammarInfo.getProperty("rules"));
	adaptee._parser = new CKY(adaptee._lexicon, rules);
	try {
	    adaptee._pipeline = new Pipeline(ppLinks);

	    String[] sa =
		adaptee.grokAndReturnStrings(adaptee.inputText.getText());

	    ArrayList st =
		adaptee.grokAndReturnSigns(adaptee.inputText.getText());

	    adaptee.NLPText.setContent(st);
      
	    int resLength = sa.length;
	    switch (resLength) {
	    case 0: break;
	    case 1:
		adaptee.plainText.setText(resLength + " parse found.");
		break;
	    default: adaptee.plainText.setText(resLength + " parses found.");
	    }
	    String flat = new String();
	    for (int i=0; i<resLength; i++) {
		flat += sa[i] + " ";
	    }
	    adaptee.plainText.setText(flat);

	} catch (PipelineException n) {
	    adaptee.display(n);
	} catch(IOException i) {
	    adaptee.display(i);
	} catch(ParseException o) {
	    adaptee.display(o);
	} catch(LexException p) {
	    adaptee.display(p);
	}
	adaptee.status.setText("Status: Finished Parsing");
    }
}

class grokkit_menuPreprocessRadioButton_ActionAdapter
    implements ActionListener {

    grokkit adaptee;
    
    grokkit_menuPreprocessRadioButton_ActionAdapter(grokkit adaptee) {
	this.adaptee = adaptee;
    }

    public void actionPerformed(ActionEvent e) {
	if (adaptee.PPLinks.contains(e.getActionCommand())) {
	    adaptee.PPLinks.remove(e.getActionCommand());
	} else {
	    adaptee.PPLinks.add(e.getActionCommand());
	}
    }
}
