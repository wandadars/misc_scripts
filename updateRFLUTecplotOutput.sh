#!/bin/bash

# Purpose: Add zero to rflupost output files in the exponential part of the file
#          name.
#
# Description: Adds an additional zero to the exponential part of the rflupost
#              output in order for output to be readable by Tecplot macros.
#              Example: cylds_3.00035E-02.plt ---> cylds_3.00035E-002.plt
#
# Author: Christopher Neal
# Date:	  6/14/2014
# Updated: 07/14/2016

echo "Converting solution files to Windows compatible format"

#Put all files in current directory into a text file
for f in *; do echo "$f"; done >temp.txt


#Print the occurences of the *.plt solution files to a new file. This may include some repeated *.pat.plt files.
sed -n "/\.plt/p" temp.txt >temp2.txt

# remove the duplicate *.pat.plt files that are unnecessary
sed -i "/\.pat/d" temp2.txt 

#Trim filename up the first underscore.
sed -n -i "s/[^_]*_//p" temp2.txt

#Flip Lines
sed -i '/\n/!G;s/\(.\)\(.*\n\)/&\2\1/;//D;s/.//' temp2.txt

#Trim filenames up to the first period.
sed  -i 's/^[^.]*.//' temp2.txt

#Reverse lines back to orginal orientation
sed  -i '/\n/!G;s/\(.\)\(.*\n\)/&\2\1/;//D;s/.//' temp2.txt


#Remove temporary files
rm -rf temp.txt 

#At this point we have all of the times, but they are not sorted.
#Sort the times that are in Extracted_Data_Labels.txt

sort -k1g temp2.txt > Extracted_Data_Labels.txt

#Remove temporary files
rm -rf temp2.txt


#-------------------TECPLOT FILENAME ADJUSTMENT SECTION--------------------------
echo "Adjusting all Tecplot files to have extra exponential digit"

#Store old values of time stamps in a temporary file
cp Extracted_Data_Labels.txt temp1.txt

# Add a zero to the 11th element of the filename string. This is specific to
# how this version of Rocflu outputs tecplot data, and this is limited to exponents
# that are less than 100.
sed -i "s/^\(.\{10\}\)/\10/" Extracted_Data_Labels.txt


#Copy old .plt files to new .plt files with updates names.
exec 3<temp1.txt
exec 4<Extracted_Data_Labels.txt

while IFS= read -r line1 <&3
IFS= read -r line2 <&4        
do 

   cp ./cylds_$line1.plt ./cylds_$line2.plt
   cp ./cylds_$line1.pat.plt ./cylds_$line2.pat.plt

   # Remove old .plt files
   rm -rf ./cylds_$line1.plt
   rm -rf ./cylds_$line1.pat.plt   

done 

#Clean up junk files
rm -rf temp1.txt 

echo "Script Finished Running. Check Extracted_Data_Labels.txt for list of files processed"
#-----------------------------------------------------------------------------
