#!/bin/bash

################################################################################
#
# Purpose: To repeatedly call the rflupost routine on the data that is present
#	   in the directory where this program is executed.
#
#
# Description: This code determines how many solution files are present in the
#	       directory and runs the Rocflu post processing routine,rflupost,
#	       on the files in the directory. It also creates a file called 
#	       "Extracted_Data_Labels.txt" that holds all of the timestamps 
#	       of the solution files that were processed.
#
#
# 
#
#
# Author: Christopher Neal
# Date:	  6/14/2014
# Updated: 01/22/2015
################################################################################

echo "Running RFLUpost on Solution Files"

#Put all files in current directory into a text file
for f in *; do echo "$f"; done >temp.txt

#Print the occurences of the first processor solution files to a new file
sed -n "/.mixt.cva_00001_/p" temp.txt >temp2.txt


#Trim filename up the first underscore.
sed -n -i "s/[^_]*_//p" temp2.txt


#Trim filename up to the second underscore.
sed -n -i "s/[^_]*_//p" temp2.txt


#Remove temporary files
rm -rf temp.txt

#At this point we have all of the times, but they are not sorted.
#Sort the times that are in Extracted_Data_Labels.txt

sort -k1g temp2.txt > Extracted_Data_Labels.txt

#Remove temporary files
rm -rf temp2.txt

#Run rflupost on the file times that are in the file Extracted_Data_Labels.txt
c=1
while read line1
do

   echo "Running rflupost on file $c ."
   c=$(($c+1))

   rflupost -c $1 -v 0 -s $line1 ##ADJUST TO WHATEVER RFLUPOST NAME YOU USE###

done < Extracted_Data_Labels.txt


#---------------------------------------------------------------------------------


#Clean up junk files
rm -rf temp1.txt 

echo "Script Finished Running. Check Extracted_Data_Labels.txt for list of files processed"
#-----------------------------------------------------------------------------
