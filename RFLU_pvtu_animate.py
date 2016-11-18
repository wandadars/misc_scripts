#! /usr/bin/env python
####################################################################
#Purpose: To read the solution files for Rocflu and create a single
#	  *.pvd file that contains the *.pvtu files for all of the 
#	  simulation solutions 
#
#
# Author: Christoher Neal
# Date:   11/18/2016
#####################################################################

import os
import glob
import xml.etree.ElementTree as ET
import xml.dom.minidom as minidom
import sys
import fnmatch

#Read user argument - 0 for no folder option, 1 for folders
if len(sys.argv) < 3:
	print "No Arguments Detected. Please pass arguments to the script."
	print "First Argument"
	print "\t0 - For cases that do not use the 'Folder' option in Rocflu i.e. data is written to a single directory"
	print "\t1 - For cases that use 'Folder' option i.e. each solution is in a separate folder"
	print "Second Argument"
	print "\t0 - For cases that do not have particles"
	print "\t1 - For cases that have particles"
	sys.exit()
else:
	print 'Argument Detected: ', str(sys.argv)

if sys.argv[1] == '0':
	FolderFlag = 0
elif sys.argv[1] == '1':
	FolderFlag = 1
else:
	print "Error - Invalid First Argument"
	print "0 - For cases that do not use the 'Folder' option in Rocflu i.e. data is written to a single directory"
        print "1 - For cases that use 'Folder' option i.e. each solution is in a separate folder"
	sys.exit()

if sys.argv[2] == '0':
	ParticlesFlag = 0
elif sys.argv[2] == '1':
	ParticlesFlag = 1
else:
	print "Error - Invalid Second Argument"
	print "\t0 - For cases that do not have particles"
	print "\t1 - For cases that have particles"
	sys.exit()


#Get the name of the cases from the <casename>.inp file in the head Rocflu
#directory
case_name = glob.glob('*.inp')
if(len(case_name) > 1):
	print "Error - More than 1 *.inp file was detected. Resolution of casename is unable to be completed"
	sys.exit()
else:
	#Extract the casename without the *.inp part
	case_name = case_name[0].split(".")[0]
	print "Detected case name is: ", case_name



###TIME STAMP EXTRACTION###
if(FolderFlag == 0):
	solution_files = [ file for file in os.listdir('.') if fnmatch.fnmatch(file, '*.pvtu') ]
	print solution_files

	#Get the timestamps that are stored in the directory names i.e. PARAVIEW_1.0000E+00,
        # 1.0000E+00 is the timestamp for that directory
        time_stamps = [name.split("_")[-1].rsplit(".",1)[0] for name in solution_files ]

elif(FolderFlag == 1):
	#Get the names of all of the directories at the head level of the simulation
	all_directories = [name for name in os.listdir(".") if os.path.isdir(name)]
	#print all_directories

	#Get all of the directories that have "PARAVIEW' in the name.
	output_directories = [name for name in all_directories if "PARAVIEW" in name]

	if len(output_directories) > 0:
		print "Detected output directories are:\n" 
		for DirName in output_directories:
			print DirName			
	else:
		print "Error - Not output directories detected"
		sys.exit()


	#Get the timestamps that are stored in the directory names i.e. PARAVIEW_1.0000E+00,
	# 1.0000E+00 is the timestamp for that directory
	time_stamps = [name.split("_")[-1] for name in output_directories ]
	


#Sort the time stamps from lowest to largest and remove any repeats
time_stamps = list(set(time_stamps))  #To remove any repeats that may exist
time_stamps = sorted(time_stamps, key=float) # sort by numerical order from small to large
print "\nExtracted timestamps from directory names are:" 
for times in  time_stamps:
	print times




###CHECK FOR SINGLE PROCESSOR OUTPUT, AND APPLY FIX TO .VTU FILE NAME CONTAINED IN .PVTU FILES FROM A BUG IN ROCFLU###

#Check to see if single processor case was run(this is the case where the naming convention is screwed up)
if(FolderFlag == 0):
	file_name = case_name + "_"+time_stamps[0] + ".pvtu"
elif(FolderFlag == 1):
	file_name = "PARAVIEW_"+time_stamps[0]+"/"+case_name + "_"+time_stamps[0] + ".pvtu"

region_count = 0
searchfile= open(file_name,"r")
for line in searchfile:
	if "<Piece Source" in line: region_count = region_count + 1

if(region_count < 2):
	print "\nOnly 1 region found in dataset. Fixing ROCFLU naming convention in the .pvtu files for cases with single regions"
	print "Example in .pvtu files:  <Piece Source=\"xdsp_4.50165E-06_00001.vtu\" />  --changed to->  <Piece Source=\"xdsp_4.50165E-06_00000.vtu\" /> "
	#Update all .pvtu files to have correct naming convention
	for time in time_stamps:
	        if(FolderFlag == 0):
	                file_name = case_name + "_"+time + ".pvtu"
	        elif(FolderFlag == 1):
	                file_name = "PARAVIEW_"+time+"/"+case_name + "_"+time + ".pvtu"

		#String to be inserted into file to update name to proper convention
		new_string = case_name + "_"+time + "_" + "00000" + ".vtu"
	
		xmldoc = minidom.parse(file_name)
		Source=xmldoc.getElementsByTagName("Piece")
		firstchild = Source[0]
		firstchild.attributes["Source"].value = new_string

		pretty_xml_as_string = xmldoc.toxml()
		#print pretty_xml_as_string

		new_root = ET.fromstring(pretty_xml_as_string)
		#print type(new_root)

		document = ET.ElementTree(new_root)
		document.write(file_name, encoding='utf-8', xml_declaration=True)


		if(ParticlesFlag == 1): #Update the particle .pcls.pvtu files as well
			if(FolderFlag == 0):
	                        file_name = case_name + "_"+time + ".pcls.pvtu"
	                elif(FolderFlag == 1):
        	                file_name = "PARAVIEW_"+time+"/"+case_name + "_"+time + ".pcls.pvtu"

        	        #String to be inserted into file to update name to proper convention
       	        	new_string = case_name + "_"+time + "_" + "00000" + ".pcls.vtu"

               		xmldoc = minidom.parse(file_name)
                	Source=xmldoc.getElementsByTagName("Piece")
                	firstchild = Source[0]
                	firstchild.attributes["Source"].value = new_string

                	pretty_xml_as_string = xmldoc.toxml()
                	#print pretty_xml_as_string
	
        	        new_root = ET.fromstring(pretty_xml_as_string)
        	        #print type(new_root)

               	 	document = ET.ElementTree(new_root)
                	document.write(file_name, encoding='utf-8', xml_declaration=True)


		

###BUILD PVD FILE###
print "Constructing ParaView *.pvd file"
#Construct the header of the *.pvd XML formatted ascii file
root = ET.Element('VTKFile')
Collection = ET.SubElement(root,"Collection")
root.attrib['type']='Collection'
root.attrib['version']='0.1'
root.attrib['byte_order']='LittleEndian'

for time in time_stamps:
	if(FolderFlag == 0):
		file_name = case_name + "_"+time + ".pvtu"
	elif(FolderFlag == 1):
		file_name = "PARAVIEW_"+time+"/"+case_name + "_"+time + ".pvtu"
	
	time_stamp_xml_entry = ET.SubElement(Collection,'DataSet')
	time_stamp_xml_entry.attrib['timestep']=time
	time_stamp_xml_entry.attrib['group']=''
	time_stamp_xml_entry.attrib['part']='0'
	time_stamp_xml_entry.attrib['file']=file_name

	if(ParticlesFlag == 1):
		
		if(FolderFlag == 0):
			file_name = case_name + "_"+time + ".pcls.pvtu"
		elif(FolderFlag == 1):
			file_name = "PARAVIEW_"+time+"/"+case_name + "_"+time + ".pcls.pvtu"
	
		time_stamp_xml_entry = ET.SubElement(Collection,'DataSet')
		time_stamp_xml_entry.attrib['timestep']=time
		time_stamp_xml_entry.attrib['group']=''
		time_stamp_xml_entry.attrib['part']='0'
		time_stamp_xml_entry.attrib['file']=file_name


#Convert the curent string to xml
xmlstr = ET.tostring(root, encoding='utf8', method='xml')
#print xmlstr

xml = minidom.parseString(xmlstr) # or xml.dom.minidom.parseString(xml_string)
pretty_xml_as_string = xml.toprettyxml()
#print pretty_xml_as_string

new_root = ET.fromstring(pretty_xml_as_string)
#print type(new_root)

document = ET.ElementTree(new_root)
document.write('paraview.pvd', encoding='utf-8', xml_declaration=True)





