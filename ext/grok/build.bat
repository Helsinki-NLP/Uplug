rem    Grok Build.bat file. 
rem    
rem    Finds it very hard to identify JAVA_HOME as a variable. I don't know if this is the way I've 
rem    written it or a windows problem. 
rem    Can't figure out where that syntax error crept in. 	
rem    Just change Java_home in here if you want. Also tzmappings is in the JRE directory so if you 
rem    don't want that error, change that. I'm not really sure what's going on. I'm just happy it 
rem    compiles the class files. 
rem    
rem    megpike


	echo off
	@CLS
	echo "Grok Build System"
	echo "-----------------"
	echo.
@if  "%JAVA_HOME%" == ""  
  echo ERROR: JAVA_HOME not found in your environment.
  echo Please, set the JAVA_HOME variable in your environment to match the
  echo location of the Java Virtual Machine you want to use.
  echo Default of C:\jdk1.4 will be used. 
  echo Optionally the second argument can be used to specify a java_home. 
  @echo off	

pause
set LOCALCLASSPATH=C:\jdk1.4\lib\tools.jar;
set DIRLIBS=lib\xerces.jar;lib\trove.jar;lib\opennlp.jar;lib\maxent.jar;lib\jdom.jar;lib\jaxp.jar;lib\java-getopt.jar;lib\jakarta-ant-optional.jar;lib\gnu-regexp.jar;lib\freebies.jar;lib\crimson.jar;lib\ant.jar;
SET ANT_HOME=.\lib
SET JAVA_HOME = C:\jdk1.4
set ADDITIONALCLASSPATH = %DIRLIBS%;%ANT_HOME%
@if %2 == * SET JAVA_HOME = C:\%2

echo Building with classpath %LOCALCLASSPATH%;%DIRLIBS%

java -Dant.home=%ANT_HOME% -Djava.home=%JAVA_HOME% -classpath C:\grok\lib\ant.jar;"%LOCALCLASSPATH%;%ADDITIONALCLASSPATH%" org.apache.tools.ant.Main %1

@exit
exit