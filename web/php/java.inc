

<script type="text/javascript">
// <![CDATA[

	function setStyle(obj,style,value){
		getRef(obj).style[style]= value;
	}
	
	function getRef(obj){
		return (typeof obj == "string") ?
			 document.getElementById(obj) : obj;
	}

        function markCell(obj,s,t,l){
	    obj.style["border"] = "2pt solid #0000ff";
	    document.getElementById(t).style["color"] = "#ff0000";
	    document.getElementById(s).style["color"] = "#ff0000";
	    document.getElementById(l).style["color"] = "#ff0000";
        }

        function unmarkCell(obj,s,t,color,l){
	    obj.style["border"] = "2pt solid " + color;
	    document.getElementById(t).style["color"] = "black";
	    document.getElementById(s).style["color"] = "black";
	    document.getElementById(l).style["color"] = "black";
        }

// ]]>
</script>
