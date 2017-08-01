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
FORMATTED_QIF=$(basename "$DEFAULT_CSV")
FORMATTED_QIF="${FORMATTED_QIF%.*}"
FORMATTED_QIF=$FORMATTED_QIF.qif
echo $CARTES_TXT
echo "$FORMATTED_QIF"

echo "Converting $DEFAULT_CSV, writing to $FORMATTED_QIF"

#format csv file to have "|" as separator with take care of the comma inside quotes
awk -F'"' '{gsub(/,/,"|",$1);gsub(/,/,"|",$3);} 1' $DEFAULT_CSV > temp_formatted.csv

DEFAULT_CSV=temp_formatted.csv
export IFS="|"

cat $DEFAULT_CSV | while read account_num date_op description num date_val debit credit 
do 
   cacs=`echo $description | grep 'ACHAT\|TPE' `
   if [ ! -z $cacs ]; then
     debitClean=`echo $debit| sed -e "s/ //g"`
     echo $debitClean
     details=`grep $debitClean $2 | cut -d "|" -f4`
     echo $details
     if [ ! -z $details ]; then  
        echo "replacing $description with sum = $debitClean with $details"
        description=$details
     fi
   fi
   echo "D$date_op" >> $FORMATTED_QIF
   echo "M$description" >> $FORMATTED_QIF
   echo "N$num" >> $FORMATTED_QIF
   if [ $debit ] ; then 
      echo "T-$debit" | sed -e "s/ //g" >> $FORMATTED_QIF #this sed is used to erase the space left on the inside quote value
   else
      echo "T$credit" | sed -e "s/ //g" >> $FORMATTED_QIF
   fi 
   echo "^" >> $FORMATTED_QIF
done

rm temp_formatted.csv

echo Done!
exit 1
