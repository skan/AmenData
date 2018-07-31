#!/bin/bash
# Shell script to reformat csv file to have only one column for both credit and debit amounts 
# 
# input: formatted CSV file from amennet xls. format is: 
# account_num; Date_operation;Description;number_piece;Date_value;debit;credit
# output QIF file for winancial
# 

if [ $# -lt 1 ] ; then
    echo "Usage: $0 input_amen.csv Encours.txt"^M
    echo "encours data are parset since v2.0"^M
    echo output is : input_amen.qif
    exit 0
fi

DEFAULT_CSV=$1
CARTES_TXT=$2
OUTPUT_CSV=$(basename "$DEFAULT_CSV")
OUTPUT_CSV="${OUTPUT_CSV%.*}"
OUTPUT_CSV=output_$OUTPUT_CSV.csv

rm -rfv $OUTPUT_CSV
echo "input 1 $CARTES_TXT"
echo "input 2 $OUTPUT_CSV"

echo "Converting $DEFAULT_CSV"
echo "Writing to $OUTPUT_CSV"
echo

#format csv file to have "|" as separator with take care of the comma inside quotes
awk -F'"' '{gsub(/,/,"|",$1);gsub(/,/,"|",$3);} 1' $DEFAULT_CSV > temp_formatted.csv

DEFAULT_CSV=temp_formatted.csv
export IFS="|"

cat $DEFAULT_CSV | while read account_num date_op description num date_val debit credit 
do 
   echo $date_op $description
   cacs=`echo $description | grep 'ACHAT\|TPE' `
   if [ ! -z $cacs ]; then
     debitClean=`echo $debit| sed -e "s/ //g"`
	 if [ ! -z $debitClean ] ; then
     	details=`grep -w $debitClean $2 | cut -d "|" -f4`
	 else #annulation achat
     	creditClean=`echo $credit| sed -e "s/ //g"`
     	details=`grep $creditClean $2 | cut -d "|" -f4`
	 fi
     if [ ! -z $details ]; then  #amount is found in encours file, replace commercant name
        echo -e "\t: $description --> $details"
        description=$details
     else
        echo -e "\t error: amount not found in cacs"
     fi
   fi
   echo -n "$date_op" >> $OUTPUT_CSV
   echo -n ";" >> $OUTPUT_CSV
   echo -n "$description" >> $OUTPUT_CSV
   echo -n ";" >> $OUTPUT_CSV
   if [ $debit ] ; then 
      echo "-$debit" | sed -e "s/ //g" >> $OUTPUT_CSV #this sed is used to erase the space left on the inside quote value
   else
      echo "$credit" | sed -e "s/ //g" >> $OUTPUT_CSV
   fi 
done

outputNumberOfLines=`cat $OUTPUT_CSV | wc -l`
inputNumberOfLines=`cat $DEFAULT_CSV | wc -l`
if [ $outputNumberOfLines = $inputNumberOfLines ]; then
	echo "Done! $inputNumberOfLines transactions"
else
	echo "output lines $outputNumberOfLines is different from input : $inputNumberOfLines"
fi

rm temp_formatted.csv

exit 1
