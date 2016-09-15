#! /usr/bin/env python
####################################################################
#Purpose: To read and change the names of the rocflu Paraview output
# data files.


#####################################################################
####### Make sure to have updateRFLUEnsightOutput in bin folder else 
####### subprocess.call command may not work

#for use of reading and writing files
import os
import glob

#To allow calling of shell code in python script
import subprocess


#Call the bash script "updateRFLUEnsightOutput.sh"
subprocess.call(['updateRFLUEnsightOutput'])

#Read in the file with the time step times 
timeSteps_filename = "Extracted_Data_Labels.txt"

time_step = []
step_zeros = '000'
#If file exists, open it
if timeSteps_filename in os.listdir(os.getcwd()):
	input_file = open(timeSteps_filename)
#Go through file and put time steps into an array
#Assumed the times are already a sorted from bash script
#Grabbing only the time no \n value	
	for line in input_file:
		time_step.append(line[:11])
	input_file.close()
	print (time_step)
	
#####Assumes that rflupost outputs files in the form of cylds."scalar"_00001_"timestep"
#####Example: cylds.r_00001_0.00000E+00

#Go through files in current directory
for filename in os.listdir(os.getcwd()):
	match_found = False
#	print(filename)
#If the scalar data files has default name from RFLUPost
	if filename.startswith("cylds.r_00001_"):
#Grab the tail end of the file name, which is the time step time
		time_check = filename[14:]
		match_found = True
		front_filename = filename[:7]

	elif filename.startswith("cylds.rv_00001_"):
		time_check = filename[15:]
		match_found = True
		front_filename = filename[:8]
	#	print(time_check)
	#	print(front_filename)

	elif filename.startswith("cylds.rE_00001_"):
		time_check = filename[15:]
		match_found = True
		front_filename = filename[:8]
	
	elif filename.startswith("cylds.p_00001_"):
		time_check = filename[14:]
		match_found = True
		front_filename = filename[:7]
	
	elif filename.startswith("cylds.T_00001_"):
		time_check = filename[14:]
		match_found = True
		front_filename = filename[:7]
	
	elif filename.startswith("cylds.a_00001_"):
		time_check = filename[14:]
		match_found = True
		front_filename = filename[:7]
	else:
		match_found = False

	if match_found == True:
		count = 0
		time_matchFound = False
		while count <= (len(time_step)-1) and time_matchFound == False:
			if time_step[count] == time_check:
				if count > 999:
					mid_filename = ''
				elif count > 99:
					mid_filename = step_zeros[:1]
				elif count > 9:
					mid_filename = step_zeros[:2]
				else:
					mid_filename = step_zeros

				time_matchFound = True
				count_s = str(count)
				full_filename = front_filename + '_'  + mid_filename  + count_s # + '_' + time_check
				os.rename(filename,full_filename)
			count +=1
	if match_found == True and time_matchFound == False:
		print("Error: time step not found!")


os.rename('cylds.case_00001','cylds.case.00001')
#Rename the file in a format that paraview can open as a multi file transient set
		
case_filename = "cylds.case.00001"
append_line = '****'

lines_2add = []

lines_2add.append('FORMAT')
lines_2add.append('type: ensight gold')
lines_2add.append('GEOMETRY')
lines_2add.append('model: ./cylds.geo_00001_000000')
lines_2add.append('VARIABLE')
lines_2add.append('scalar per element: Density ./cylds.r_****')
lines_2add.append('scalar per element: Energy ./cylds.rE_****')
lines_2add.append('scalar per element: Pressure ./cylds.p_****')
lines_2add.append('scalar per element: Temperature ./cylds.T_****')
lines_2add.append('scalar per element: Soundspeed ./cylds.a_****')
lines_2add.append('vector per element: Momentum ./cylds.rv_****')
lines_2add.append('TIME')
lines_2add.append('time set:             1')
lines_2add.append('number of steps:      ' + str(len(time_step)))
lines_2add.append('filename start number:  0')
lines_2add.append('filename increment:   1')
lines_2add.append('time values:  ') 


write_file = open(case_filename,'w+')
write_count = 0

while write_count <= (len(lines_2add)-1):
	write_file.write(lines_2add[write_count])
	write_count +=1
	write_file.write("\n")

count = 0
while count <= (len(time_step)-1):
	write_file.write(time_step[count])
	write_file.write("\n")
	count +=1

write_file.close()

