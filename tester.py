import os
import glob  

os.system('make');				#Install App

path = './exampleinputshellscriptfiles/*.sh'   	#Get file list
files=glob.glob(path)   
for file in files: 
	split1 = file.split("/")[2]
	justFilename = split1.split(".")[0]		#Foreach parse it
	sil = os.system('./BashToPerl exampleinputshellscriptfiles/'+ justFilename +'.sh ./tests/' + justFilename + '.pl > /dev/null')	#Outputs to tests folder
	print ("----------------OUTPUT OF MY PERL FILE " + justFilename + "----------------");
	os.system('perl ./tests/'+ justFilename +'.pl');
	print ("----------------OUTPUT OF EXAMPLE FILE " + justFilename + "----------------");
	os.system('perl ./exampleoutputperlfiles/'+ justFilename +'.pl');

	

