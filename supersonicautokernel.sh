#!/bin/bash
#######################################################################################
# Purpose: The purpose of this script is to automate the production of a subsonic
#          inviscid unsteady kernel
#
#
#  Author: Christopher Neal
#  Created: 03/27/2015
#  Edited: 03/27/2015
#
#######################################################################################

#This script should be executed in a directory that only has the 4 necessary to make a Rocflu run: 
# <>.inp , <>.bc , <>.hyb.asc , job.pbs

#ECHO INPUTS FOR USER TO SEE
echo "Number of Processors Requested:  $1"
echo "Number of Regions to Be Used: $2"
echo "Time Step for First Order Steady-State Run: $3"
echo "Max Time/Write Time for First Order Steady-State Run: $4"
echo "Fractional Perturbation Amount: $5"
echo "Time Step for Second Order Steady-State Run: $6"
echo "Max Time/Write Time for Second Order Steady-State Run: $7"
echo "Time Step for Second Order Perturbation Run: $8"
echo "Max Time/Write Time for Second Order Perturbation Run: $9"



#PRINT INPUTS TO FILE FOR LATER REFERENCE
echo "Number of Processors Requested:  $1" > autokernelInputs.txt
echo "Number of Regions to Be Used: $2" >> autokernelInputs.txt
echo "Time Step for First Steady-State Run: $3" >> autokernelInputs.txt
echo "Max Time/Write Time for First Steady-State Run: $4" >> autokernelInputs.txt
echo "Fractional Perturbation Amount: $5" >> autokernelInputs.txt
echo "Time Step for Second Order Steady-State Run: $6" >> autokernelInputs.txt
echo "Max Time/Write Time for Second Order Steady-State Run: $7" >> autokernelInputs.txt
echo "Time Step for Second Order Perturbation Run: $8" >> autokernelInputs.txt
echo "Max Time/Write Time for Second Order Perturbation Run: $9" >> autokernelInputs.txt



#Pause to Give User some time to examine the inputs that they gave
sleep 5s

#Create main directories
mkdir inputfiles map part init perturb ss ss2
echo 'Simulation Directories Created'

#Move a copy of input files into the inputfiles directory
cp cylds.inp cylds.bc cylds.hyb.asc job.pbs ./inputfiles
echo'Input Files Moved'

#rflumap step
echo 'Running rflumap'
rflumap -c cylds -v 1 -m 1 -p $1 -r $2

cp cylds.map ./map

#rflupart step
echo 'Running rflupart'
rflupart -c cylds -v 1

cp cylds.cmp* cylds.com* cylds.dim* cylds.grda* cylds.rin cylds.rnm* cylds.ptm ./part

#rfluinit part
echo 'Running rfluinit'
rfluinit -c cylds -v 1

cp cylds.mixt.cva* ./init

#Move all files to ss directory
mv cylds.* rflu* job.pbs ss/



#--------------First Order Steady-State Run Stage------------------
cd ss/

#Change timestep of input file
sed -i -e 's/TIMESTEP[ ]*[0-9\.]*[eE]*[+-]*[0-9]* /TIMESTEP   '"$3"' /g' cylds.inp

#Change maxtime and writetime of input file
sed -i -e 's/MAXTIME[ ]*[0-9\.]*[eE]*[+-]*[0-9]* /MAXTIME    '"$4"' /g' cylds.inp
sed -i -e 's/\<WRITIME[ ]*[0-9\.]*[eE]*[+-]*[0-9]*\> /WRITIME    '"$4"' /g' cylds.inp

#Change accuracy of method in input file to 1st Order
sed -i -e 's/ORDER[ ]*[0-9\.]*[eE]*[+-]*[0-9]* /ORDER    '"1"' /g' cylds.inp


#Submit the steady-state job
qsub job.pbs
echo 'Submitted First Steady-State Job'

#Loop until the job.log file for the steady-state run is present
while [ ! -f ./job.log ]
do

   if [ ! -f ./job.log ]; then

      echo 'Job Not Finished. Code will check again later.'
      #Wait for some time before testing to see if file exists
      sleep 2h

   fi

done


echo 'Log File Detected. First Order Steady-State Job Finished. Continuing...'

#--------------Second Order Steady-State Run Stage------------------

#Change timestep of input file
sed -i -e 's/TIMESTEP[ ]*[0-9\.]*[eE]*[+-]*[0-9]* /TIMESTEP   '"$6"' /g' cylds.inp

#Change maxtime and writetime of input file
sed -i -e 's/MAXTIME[ ]*[0-9\.]*[eE]*[+-]*[0-9]* /MAXTIME    '"$7"' /g' cylds.inp
sed -i -e 's/\<WRITIME[ ]*[0-9\.]*[eE]*[+-]*[0-9]*\> /WRITIME    '"$7"' /g' cylds.inp

#Change accuracy of method in input file back to 2nd Order
sed -i -e 's/ORDER[ ]*[0-9\.]*[eE]*[+-]*[0-9]* /ORDER    '"2"' /g' cylds.inp

#Delete job.log file(so that next job can detect completion by presence of .log file)
rm -rf job.log

#Submit the Second Order steady-state job
qsub job.pbs
echo 'Submitted Second Order Steady-State Job'

#Loop until the job.log file for the steady-state run is present
while [ ! -f ./job.log ]
do

   if [ ! -f ./job.log ]; then

      echo 'Job Not Finished. Code will check again later.'
      #Wait for some time before testing to see if file exists
      sleep 2h

   fi

done


echo 'Log File Detected. Second Order Steady-State Job Finished. Continuing...'




#--------------Second Order Steady-State Run 2 Stage-----------------
-
#Copy the latest solution file that was printed to the ss directory(Multi-step Process)
echo 'Beginning solution file transfer to ss2 directory'

#Print all file names to a temporary file
for f in *; do echo "$f"; done >temp.txt


#Print the occurences of the first processor solution files to a new file
sed -n "/cylds.mixt.cva_00001_/p" temp.txt >temp2.txt

#Trim filename up the first underscore.
sed -n -i "s/[^_]*_//p" temp2.txt


#Trim filename up to the second underscore.
sed -n -i "s/[^_]*_//p" temp2.txt

#Remove temporary files
rm -rf temp.txt

#At this point we have all of the times, but they are not sorted.
#Sort the times that are in Extracted_Data_Labels.txt
sort -k1g temp2.txt > Extracted_Data_Labels.txt

#Take only the last occurence of the solution file, and only take the time stamp
maxtime=$(tail -1 Extracted_Data_Labels.txt)

#Remove temporary files
rm -rf Extracted_Data_Labels.txt
rm -rf temp2.txt


#At this time, the time of the latest solution file should be stored in the variable maxtime. Use this to copy
#solution files to the ss2 directory.
echo "Copying Latest Solution File For Time:$maxtime To ss2 Directory"
cp cylds.mixt.*$maxtime ../ss2/

#Clean up Temporary Data Files
rm -rf  temp.txt temp2.txt



#----------------------Second Steady-State Stage-------------------------

#Change directory to the ss2 directory
echo "Entering ss2 Directory"
cd ../ss2

#Copy files from inputfiles, part, and map into the ss2 directory
echo "Copying Run Files to ss2 Directory"
cp ../inputfiles/* ../map/* ../part/* ./

#Change timestep of input file
sed -i -e 's/TIMESTEP[ ]*[0-9\.]*[eE]*[+-]*[0-9]* /TIMESTEP   '"$8"' /g' cylds.inp

#Change maxtime and writetime of input file
sed -i -e 's/MAXTIME[ ]*[0-9\.]*[eE]*[+-]*[0-9]* /MAXTIME    '"$9"' /g' cylds.inp
sed -i -e 's/\<WRITIME[ ]*[0-9\.]*[eE]*[+-]*[0-9]*\> /WRITIME    '"$9"' /g' cylds.inp



#Run rfluconv to convert the solution file to time equal to zero i.e. initial file
echo 'Converting Solution files to Time=0 using rfluconv'
rfluconv -c cylds -v 2 -s $maxtime <<EOF
42
0
EOF


#Remove the solution files that are not the newly created initial files
echo 'Removing non time equal to zero solution files'
mkdir temp
cp cylds.mixt.cva*E+00 ./temp
rm -rf cylds.mixt.cva*
mv ./temp/cylds.mixt.cva* ./
rm -rf temp


#Before Submitting ss2 job, copy initialization files to the perturb directory
echo 'Moving Initialization Files to Perturb Directory'
cp cylds.mixt.cva* ../perturb


#submit ss2 job
echo "Submitting ss2 Job"
qsub job.pbs



#---------------------------Perturbation Stage----------------------------------
echo 'Moving on to perturbation step'
echo 'ENTERING PERTURB DIRECTORY'
cd ../perturb

loc=$(pwd)
echo "Current Directory: $loc"

#Copy run files to the perturb directory
echo 'Copying run files to perturb directory'
cp ../inputfiles/* ../part/* ../map/* ./

#Change timestep of input file
sed -i -e 's/TIMESTEP[ ]*[0-9\.]*[eE]*[+-]*[0-9]* /TIMESTEP   '"$8"' /g' cylds.inp

#Change maxtime and writetime of input file
sed -i -e 's/MAXTIME[ ]*[0-9\.]*[eE]*[+-]*[0-9]* /MAXTIME    '"$9"' /g' cylds.inp
sed -i -e 's/\<WRITIME[ ]*[0-9\.]*[eE]*[+-]*[0-9]*\> /WRITIME    '"$9"' /g' cylds.inp


#Edit the BOUNDARY CONDITION File to reflect perturbed Mach number.
echo 'Adjusting Boundary Condition File'

#Extract the MACH string from the Boundary Condition file.
var=$(grep "MACH" cylds.bc)

#Store the MACH string into a temporary file.
echo "$var" | sed 's%.*/\(.*\),.*%\1%'>junk.txt

#Extract just the numeric part of the MACH string.
Mach=$(sed "s/[^0-9\.]//g" junk.txt)

#Remove temporary file
rm -rf junk.txt

#Use bc to perform floating point math to compute the new perturbed Mach number
#using the input for the fractional increase in Mach number i.e. 2%-->0.02
echo "Perturbation Amount is: $5"
MachPerturbed=$(bc <<< "scale=15; $Mach+$Mach*$5")
echo "Perturbed Mach Number is: $MachPerturbed ."

#SECTION TO ADD PADDING LEADING ZERO FOR SUBSONIC CASES. NOT NECESSAY IF SUPERSONIC. The
# numerical value of the less than comparison may need to be changed for Mach numbers greater than
# or equal to 10 i.e. -lt 18
#while [ ${#MachPerturbed} -lt 17 ] 
#do
#   MachPerturbed="0$MachPerturbed"
#done


#Replace the value of the MACH number in the boundary condition file with the newly computed perturbed Mach number
sed -i 's/.*MACH.*/MACH            '"$MachPerturbed"'/' cylds.bc


#Edit the INPUT FILE to perturb the particle
echo 'Editing the Input File'

#Remove the first line after the string # INITFLOW not including the #INITFLOW line in the cylds.inp file.
sed -i  '/# INITFLOW/{n;d;}' cylds.inp


#Add the text "FLAG 5" and "RVAL -10000000" after where the string # INITFLOW is located.
sed -i '/# INITFLOW/ a \FLAG   5\
RVAL1 -100000000' cylds.inp



#Remove the first line after the string # MVFRAME not including the # MVFRAME line in the cylds.inp file.
sed -i  '/# MVFRAME/{n;d;}' cylds.inp

#Add the text "FLAG 1    !Turn is 'ON' when steady-state is reached"  after where the string # MVFRAME is located.
sed -i "/# MVFRAME/ a \FLAG            1 ! Turn is 'ON' when steady state is reached" cylds.inp



#Change the perturbation velocity in the MVFRAME region of the input file  to whatever it needs to be given the
#Mach number(from the BC file) and given perturbation amount.

#Extract the value of GAMMA from input file
gamma=$(grep "GAMMA" cylds.inp)

#Store the GAMMA string into a temporary file
echo "$gamma" | sed 's%.*/\(.*\),.*%\1%'>junk.txt

#Extract just the numeric part of the GAMMA string
gamma=$(sed "s/[^0-9\.]//g" junk.txt)

#Remove temporary file
rm -rf junk.txt



#Extract the value of PRESS from the input file from the REFERNCE section
press=$(grep -m 1 "PRESS" cylds.inp)

#Store the PRESS string into a temporary file
echo "$press" | sed 's%.*/\(.*\),.*%\1%'>junk.txt

#Extract just the numeric part of the PRESS  string
press=$(sed "s/[^0-9\.]//g" junk.txt)

#Remove temporary file
rm -rf junk.txt



#Extract the value of density from the input file from the REFERNCE section
dens=$(grep -m 1 "DENS" cylds.inp)

#Store the DENS string into a temporary file
echo "$dens" | sed 's%.*/\(.*\),.*%\1%'>junk.txt

#Extract just the numeric part of the DENS string
dens=$(sed "s/[^0-9\.]//g" junk.txt)

#Remove temporary file
rm -rf junk.txt



#Compute the speed of sound that corresponds to the given  properties gamma, dens, press (Ideal gas relation)
c=$(bc <<< "scale=15; sqrt($gamma*$press/$dens)/1")

#Determine what the perturbed velocity is
deltaU=$(bc <<< "scale=15; ($Mach*$c*$5)/1")

#Write the new perturbation velocity to the input file in the MVFRAME section for VELX. Note that the comment in the original
#input file after the VELX must remain present in order for this code to properly locate the line.
sed -i 's/.*VELX.*! Unit.*/VELX           -'"$deltaU"' ! Unit step change in velocity /g' cylds.inp


#Run the rfluinit to perturb the particle
echo 'Running rfluinit'
rfluinit -c cylds -v 1

#Now UNDO the changes to the MVFRAME section of the input file
echo 'Reverting changes to MVFRAME Section'
#Remove the first line after the string # MVFRAME is located not including the # MVFRAME line in the cylds.inp file.
sed -i  '/# MVFRAME/{n;d;}' cylds.inp

#Add the text "FLAG 0    !Turn is 'ON' when steady-state is reached"  after where the string # MVFRAME is located.
sed -i "/# MVFRAME/ a \FLAG            0 ! Turn is 'ON' when steady state is reached" cylds.inp

echo 'Submitting Perturbation Job'
#Now submit job
qsub job.pbs

echo 'Program Finished....Quitting'













