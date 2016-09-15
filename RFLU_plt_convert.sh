#!/bin/bash

################################################################################
#
# Purpose: To extract the time stamps on all of the .mixt.cvs solution files in a
#	   directory and store them sorted from smallest to largest into a file
#          called Extracted_Data_Labels.txt.
#
#
#
#
# Author: Christopher Neal
# Date:	  04/23/2015
# Updated: 04/23/2015
################################################################################

echo "Extracting Times From .plt Solution Files"

#Put all files in current directory into a text file
for f in *; do echo "$f"; done >temp.txt

#Print the occurences of the first processor solution files to a new file
sed -n "/.plt/p" temp.txt >temp2.txt


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

#Rename .plt solution files that match the file times that are in the file Extracted_Data_Labels.txt
c=1
while read line1
do

   echo "Running rflupost on file $c ."
   c=$(($c+1))
   
   mv cylds*$line1*.plt cylds_$c.plt

done < Extracted_Data_Labels.txt


echo "Script Finished Running. Check Extracted_Data_Labels.txt for list of timestamps."
#-----------------------------------------------------------------------------
