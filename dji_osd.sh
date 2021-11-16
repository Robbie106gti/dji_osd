#!/bin/bash
IFS=$'\n' 

div ()  # Arguments: dividend and divisor
{
        if [ $2 -eq 0 ]; then echo division by 0; exit; fi
        local p=2                             # precision
        local c=${c:-0}                       # precision counter
        local d=.                             # decimal separator
        local r=$(($1/$2)); echo -n $r        # result of division
        local m=$(($r*$2))
        [ $c -eq 0 ] && [ $m -ne $1 ] && echo -n $d
        [ $1 -eq $m ] || [ $c -eq $p ] && echo && return
        local e=$(($1-$m))
        c=$(($c+1))
        div $(($e*10)) $2
}  

writeLines() {
   IFS=', ' read -r -a strArr <<< "$2"
   batRaw=${strArr[3]//[!0-9]/}
   batV=$(div ${batRaw} 10)
   cells=${strArr[5]//[!0-9]/}
   cellsX=$((${cells} * 10))
   avrgCell=$(div ${batRaw} ${cellsX})
   mBit=$(div ${strArr[8]//[!0-9]/} 10)
   time=${strArr[2]//[!0-9]/}
   min=$((time / 60))
   sec=$((time-(min*60)))
   sign=
   n=$((${strArr[8]//[!0-9]/} / 20))
   chr="|"
   for ((i = 0; i < n; i++)); do 
      sign+=${chr}
   done
   echo  -DJI Telemetry- >> $1
   echo "Time: "${min}:${sec} >> $1
   echo "Bat:   "$avrgCell/$batV'v' >> $1
   echo "ms:    "${strArr[7]//[!0-9]/} >> $1
   echo "MBit:  "$mBit >> $1
   echo $sign >> $1
}

function formateDJI() {
   if [[ $2 != *"signal"* ]];
   then
      echo $2 >> $1
   else
      writeLines $1 $2
   fi
}

function makeFile() {
   echo $1 
   append="_formatted.srt"
   newfile="${1/.srt/$append}"
   touch $newfile

   while IFS= read -r line;
   do
      formateDJI $newfile ${line}
   done < $1
   echo "completed formatting srt: " $newfile
   echo "start video"
   makeVideoFile $1
}

function makeVideoFile() {
   echo $1 
   append="_formatted.srt"
   srt="${1/.srt/$append}"
   inputVideo="${1/.srt/.mp4}"
   outputVideo="${1/.srt/_tel.mp4}"
   echo ${inputVideo} ${srt} ${outputVideo}
   ffmpeg -i ${inputVideo} -s 1280x720 -aspect 16:9 -qp 25 -vf "[in] drawbox=0:0:1280:720:black@1:t=fill, subtitles=${srt}:force_style='Fontsize=16,Alignment=1,'" -y ${outputVideo}
}

files=$(ls *.srt)
for file in $files
do
if [[ $file != *"_formatted"* ]]; 
then
   makeFile $file
fi
done
