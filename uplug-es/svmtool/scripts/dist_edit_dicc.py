# -*- coding: utf-8 -*-
#########################################################################
#                IMPORTS                    #
#########################################################################
import sys
import random
import string
import getopt
from collections import defaultdict
from time import gmtime, strftime
#########################################################################
#            FUNCTIONS DEFINITIONS                #
#########################################################################
#########################################################################
#########################################################################
#distance function
# calculates de levenstein distance between two strings
def distance(str1, str2):
  d=dict()
  for i in range(len(str1)+1):
     d[i]=dict()
     d[i][0]=i
  for i in range(len(str2)+1):
     d[0][i] = i
  for i in range(1, len(str1)+1):
     for j in range(1, len(str2)+1):
        d[i][j] = min(d[i][j-1]+1, d[i-1][j]+1, d[i-1][j-1]+(not str1[i-1] == str2[j-1]))
  return d[len(str1)][len(str2)]
#########################################################################
#########################################################################
#getoptions function
# gets the parameters indicated by the user
def getoptions():
  try:
        opts, args = getopt.getopt(sys.argv[1:], "hd",["help","distance"])
  except getopt.GetoptError, err:
        # print help information and exit:
        print str(err) # will print something like "option -a not recognized"
        help()
        sys.exit(2)
  return opts, args
#########################################################################
#########################################################################
#help function
# shows the usage of the script
def help():
    print 'Usage: add_noise.py [OPTIONS]'
    print '    options:'
    print '    -d ; --distance:         max distance among words'
    print 'call: python dist_edit_dicc.py testfile dictfile [-d|--distance value]'
    
#########################################################################
# diagonal function
# 
def diagonal(w,diccio):
	t=len(w)
	currmin=infty
	currbest=''
	j=0
	diccio_distances=dict()
	diccio_distances[0]=set()
	bestwords=[]
	if t  < MAXCHARS:
		#words=diccio[str(t)]
		words=diccio[t]
		#print words
		for p in  words:
		    dist=distance(w,p)
		    if dist<=currmin:
			currmin=dist
			currbest=p
			bestwords.append([dist,p])
			if j>= currmin:
				break
	j=1
	while j< currmin:
		if t+j < MAXCHARS:
			#words=diccio[str(t+j)]
			words=diccio[t+j]
			for p in words:
			    dist=distance(w,p)
			    if dist<=currmin:
				currmin=dist
				currbest=p
				bestwords.append([dist,p])

			    	if j>=currmin:
					break
			    if j>=currmin:
				break	
		
		if t-j >=0:
	      		#words=diccio[str(t-j)]
	      		words=diccio[t-j]
	      		for p in words: 
		  	    dist = distance(w,p)

		  	    if dist <= currmin:
		       		currmin=dist
		      		currbest=p
				bestwords.append([dist,p])
				if j>=currmin:
					break

	  	j=j+1
	bestwords.sort()
	return bestwords
#########################################################################
#diagonalDicts function
#
def diagonalDicts(w,diccio):
	t=len(w)
	currmin=infty
	currbest=''
	j=0

	#return a list of best candidates
	if t  < MAXCHARS:
		words=diccio[t]
		#print words
		#for p in  words:
		for i in range(len(diccio[t])-1):
		    dist=distance(w,diccio[t][i])
		    if dist<currmin:
			currmin=dist
			currbest=diccio[t][i]#p

			if j>= currmin:
				break
	j=1
	while j< currmin:
		if t+j < MAXCHARS:
			words=diccio[t+j]
			#for p in words:
			for i in range(len(diccio[t+j])-1):
			    dist=distance(w,diccio[t+j][i])#w,p)
			    if dist<currmin:
				currmin=dist
				currbest=diccio[t+j][i]#p
			    	if j>=currmin:
					break
			    if j>=currmin:
				break	
		
		if t-j >=0:
	      		words=diccio[t-j]
			for i in range(len(diccio[t-j])-1):
	      		#for p in words: 
		  	    dist = distance(w,diccio[t-j][i])#w,p)
		  	    if dist < currmin:
		       		currmin=dist
		      		currbest=diccio[t-j][i]#p
				if j>=currmin:
					break

	  	j=j+1
	#return a list of best candidates
	return currbest
	
#########################################################################
# isPunctuation function
# returns if a word is a punctuation mark or a combination of punctuation marks
def isPunctuation(w):
  ispunct=bool(0)
  if w in string.punctuation:
    ispunct=bool(1)
  else: #duplicated punctuation:.. !!!! < >-
    ispunct=bool(1)
    for i,l in enumerate(w):
      if l in string.punctuation:
	#print l
	ispunct=ispunct and bool(1)
      else:
	ispunct=ispunct and bool(0)
  return ispunct
#########################################################################
#########################################################################
# isRepeated function
# returns if a word is made by the repetition of the same symbol
def isRepeated(w):
  isrepeat=bool(1)
  for i,l in enumerate(w):
      if i<len(w)-1:
	if l == w[i+1]:
	  isrepeat=isrepeat and bool(1)
	else:
	  isrepeat=isrepeat and bool(0)
  return isrepeat
#########################################################################
# POSpunctuation function
# returns the POS tag for a word w as if w were a punctuation mark
def POSpunctuation(w):
  if w in "!?.": #si entramos por aqui es q ! no esta en el diccionario
    return "."
  elif w=="#":
    return "#"
  elif w in ";:_-":
    return ":"
  elif w=="...":
    return ":"
  elif w==",":
    return ","
  elif w=='(' or w=='[':
    return "("
  elif w==')' or w==']':
    return ")"
  elif w=="$":
    return "$"
  elif w=="\"":
    return '"'
  elif w=="``":
    return "``"
  elif w in "+-/": 
    return "SYM"
  elif len(w)>1 and isRepeated(w):
      return POSpunctuation(w[0])
  else:
    return "OSYM"
#########################################################################
#
############## main program #################3
#
infty=100000000

#get the option selected by the user
opts,args=getoptions()


if len(args)<2:
  help()
  sys.exit()

test_filename=args[0]
dict_filename=args[1]

dist=-1
if len(args)==4 and (args[2]=='-d' or args[2]=='--distance'):
  dist=int(args[3] )
else:
  dist=-1


test_file=open(test_filename,'rw')
dict_file=open(dict_filename,'rw')

test_content=test_file.read()
dict_content=dict_file.read()

test_list=test_content.split('\n')
b=[]
pos=[]

#get test words in test_list
for l in test_list:
	if l!='':
		pair=l.split(' ')
		b.append(pair[0])
test_list=b


#put the words in a dictionary
dict_words=[]
dict_list=dict_content.split('\n')
b=[]
#make a list of the words
for l in dict_list:
	if len(l)>0:
		w=l.split(' ')[0]
		num_pos=int(l.split(' ')[2])
		k=0
		w_pos=[]
		i=0
		#store the POS of the word w in a dictionary las POS de la w en el diccionario
		#[pos,num_pos]		
		while k<num_pos:
			w_pos.append([l.split(' ')[3+i],l.split(' ')[3+i+1]])
			i=i+2
			k=k+1	 

		dict_words.append(w)
		pos.append(w_pos)
		b.append([len(w),w])
b.sort()
dict_list=b
#MAX OF CHARACTERS FOR A WORD IN OUR DICTIONARY....
MAXCHARS=200

#set a dictionary with the list of words
diccio2=dict()
for i in range(MAXCHARS):
	diccio2[i]=set()

for k,v in dict_list:
   diccio2[len(v)].add(v)

#diccionary to store the POS added to a candidate 
diccio_add=dict()


dict_file.close()


#output_file=open('output_aux.txt','w')

#FOR EVERY WORD IN THE INPUT WE CHECK:
for ind,w in enumerate(test_list):
  
	#IF IS AN EOS MARK
	if w=='<s>': #eos mark
		wordbest=w #WE DONT DO ANYTHING
	#if word in diccionary --> do nothing
	elif w in diccio2[len(w)]: 
		wordbest= w
	#w is a punctuation mark
	elif isPunctuation(w):#which punctuation mark? 
		pos_punct=POSpunctuation(w)
		  
		if pos_punct in diccio2[len(pos_punct)]:
			wordbest=pos_punct
			pos_aux=[]
			for k,ww in enumerate(dict_words):
				if ww==wordbest:
					pos_aux=pos[k]
			aux=0
			pos_wbest=''
			num_pos=0
			veces=0
			if pos_aux!=[]: #we get the POSes of the wbest
				for elem in pos_aux:
					pos_wbest=pos_wbest+' '+elem[0]+' '+elem[1]
					num_pos=num_pos+1
					veces=veces+int(elem[1])

			#we save the candidates info to write at the end the info
			if w not in diccio_add:
				diccio_add[w]=set()
				diccio_add[w].add(str(veces)+' '+str(num_pos)+pos_wbest)

#			output_file.write(w+' '+wordbest+' '+str(veces)+' '+str(num_pos)+pos_wbest+'\n')


		else:

			if w not in diccio_add:
				diccio_add[w]=set()
				diccio_add[w].add(' 1 1 '+pos_punct+' 1')
#			output_file.write(w + ' 1 1 '+pos_punct+' 1\n')  
		
	elif w.upper() in diccio2[len(w)]:
		wordbest=w.upper()
		#add the 'new' word
		#get the pos_wbest
		pos_aux=[]
		for k,ww in enumerate(dict_words):
			if ww==wordbest: #we get the pos_wbest
				pos_aux=pos[k]
		aux=0
		pos_wbest=''
		num_pos=0
		veces=0
		if pos_aux!=[]: #we get the POSes of the wbest
				for elem in pos_aux:
					pos_wbest=pos_wbest+' '+elem[0]+' '+elem[1]
					num_pos=num_pos+1
					veces=veces+int(elem[1])


		if w not in diccio_add:
			diccio_add[w]=set()
			diccio_add[w].add(str(veces)+' '+str(num_pos)+pos_wbest)
	
#		output_file.write(w+' '+wordbest+' '+str(veces)+' '+str(num_pos)+pos_wbest+'\n')

	elif w.capitalize() in diccio2[len(w)]:
		wordbest=w.capitalize()
		pos_aux=[]
		for k,ww in enumerate(dict_words):
			if ww==wordbest: #we get the pos_wbest
				pos_aux=pos[k]
		aux=0
		pos_wbest=''
		num_pos=0
		veces=0
		if pos_aux!=[]: #we get the POSes of the wbest
				for elem in pos_aux:
					pos_wbest=pos_wbest+' '+elem[0]+' '+elem[1]
					num_pos=num_pos+1
					veces=veces+int(elem[1])

		if w not in diccio_add:
			diccio_add[w]=set()
			diccio_add[w].add(str(veces)+' '+str(num_pos)+pos_wbest)
#		output_file.write(w+' '+wordbest+' '+str(veces)+' '+str(num_pos)+pos_wbest+'\n')

	elif w.lower() in diccio2[len(w)]:
		wordbest=w.lower()
		pos_aux=[]
		for k,ww in enumerate(dict_words):
			if ww==wordbest: #we get the pos_wbest
				pos_aux=pos[k]
		aux=0
		pos_wbest=''
		num_pos=0
		veces=0
		if pos_aux!=[]: #we get the POSes of the wbest
				for elem in pos_aux:
					pos_wbest=pos_wbest+' '+elem[0]+' '+elem[1]
					num_pos=num_pos+1
					veces=veces+int(elem[1])

		if w not in diccio_add:
			diccio_add[w]=set()
			diccio_add[w].add(str(veces)+' '+str(num_pos)+pos_wbest)
#		output_file.write(w+' '+wordbest+' '+str(veces)+' '+str(num_pos)+pos_wbest+'\n')

		
	else:

		wordbest_list=diagonal(w,diccio2)

		#wordbest_list=sorted list of candidates to substitute the word w
		if wordbest_list!=[]:
			score=dist
			if dist > 0: #user indicated a distance threshold
			    score = dist #distance indicated by the user
			else:
			    score=wordbest_list[0][0]
			veces=0
			num_pos=0
			pos_wbest=''
			diccio_pos=dict()
			for ww in wordbest_list:
				if ww[0] <= score: #manage a list of the best candidates
					
					pos_aux=[]
					for k,www in enumerate(dict_words):
						if www==ww[1]: #we get the pos_wbest
							pos_aux=pos[k]
					
					if pos_aux!=[]: #we get the pos of the wbest
						for elem in pos_aux:
							if elem[0] not in diccio_pos:
								diccio_pos[elem[0]]=set()
								diccio_pos[elem[0]].add(int(elem[1]))
							else:
								diccio_pos[elem[0]].add(int(elem[1]))
			#print diccio_pos
			for elem in diccio_pos:
				suma=sum(diccio_pos[elem])
				pos_wbest=pos_wbest+' '+elem+' '+str(suma)
				num_pos=num_pos+1							
				veces=veces+suma
				#print pos_wbest						
			
			if w not in diccio_add and veces>0:
				diccio_add[w]=set()
				diccio_add[w].add(str(veces)+' '+str(num_pos)+pos_wbest)

#			output_file.write(w+' '+str(wordbest_list)+' '+str(veces)+' '+str(num_pos)+pos_wbest+'\n')

#write de add_file
for w in diccio_add:
	output=''
	output=output+w
	for element in diccio_add[w]:
		output=output+' '+element
		print output


test_file.close()

#output_file.close()
		














