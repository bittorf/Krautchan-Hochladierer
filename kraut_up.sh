#!/usr/bin/env bash

CURL=$(which curl)
if [ -z "${CURL}" ]; then
	echo "Dieses Skript benötigt cURL. Vergewissere dich dass es installiert ist und im Suchpfad liegt."
	exit 1
fi

UA="Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_7; en-us) AppleWebKit/533.21.1 (KHTML, like Gecko) Version/5.0.5 Safari/533.21.1"
PWD=""
POST_URL="http://krautchan.net/post"
DELETE_URL="http://krautchan.net/delete"
BIFS=${IFS}
NAME_ALLOWED=""
COUNT="0"
ARR_KIND=(-iname "*.gif" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.psd" -o -iname "*.mp3" -o -iname "*.ogg" -o -iname "*.rar" -o -iname "*.zip" -o -iname "*.torrent" -o -iname "*.swf")

choose() {
echo -ne "Wähle ein Brett aus>
 (b,int,vip,a,c,d,e,f,fb,fit,jp,k,l,li,m,p,ph,sp,t,tv
  v,w,we,wp,x,n,rfk,z,zp,h,s,kc): "
read -e BOARD

case "${BOARD}" in #NEGER, BITTE!
	b|int|vip)
	NAME_ALLOWED=no
	FILES_ALLOWED=4
	MAX_FILE_SIZE=10M
	;;
	a|jp)
	FILES_ALLOWED=3
	MAX_FILE_SIZE=9M
	;;
	k)
	FILES_ALLOWED=3
	MAX_FILE_SIZE=10M
	#MAX_POST_SIZE=15
	;;
	l|m)
	FILES_ALLOWED=3
	MAX_FILE_SIZE=20M
	#MAX_POST_SIZE=40
	;;
	c|fb|p|tv|v|we)
	FILES_ALLOWED=3
	MAX_FILE_SIZE=6M
	;;
	wp)
	ARR_KIND=(-iname "*.gif" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.psd")
	FILES_ALLOWED=3
	MAX_FILE_SIZE=6M
	;;
	rfk)
	FILES_ALLOWED=3
	MAX_FILE_SIZE=5M
	;;
	z|zp|s)
	ARR_KIND=(-iname "*.gif" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.psd")
	FILES_ALLOWED=4
	MAX_FILE_SIZE=6M
	;;
	h)
	ARR_KIND=(-iname "*.gif" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.psd")
	FILES_ALLOWED=3
	MAX_FILE_SIZE=3M
	;;
	d|e|f|fit|li|ph|sp|t|w|x|n|kc)
	FILES_ALLOWED=3
	MAX_FILE_SIZE=3M
	;;
	*)
	echo -e "\nDepp.\n"
	choose
	;;
esac
}

clear
choose

echo -ne "\nFaden-ID>
 (z.B. 3025905 - leer lassen um einen neuen Faden zu erstellen): "
read -e ID

echo -ne "\nVerzeichniss(e) auswählen. Leerzeichen müssen escaped werden.
 (z.B.: /Users/bernd/penisbilder /home/bernadette/als\ ob):\n"
read -a ARR_DIR

IFS='
'
for DIR in ${ARR_DIR[@]}; do
	for FILES in $(find ${DIR} -type f -size -${MAX_FILE_SIZE} \( ${ARR_KIND[@]} \) ); do
		ARR_FILES+=("${FILES}")
	done
done
IFS=${BIFS}
#echo ${ARR_FILES[@]}
ARR_FILES+=(END)

if [ -z ${NAME_ALLOWED} ]; then
	echo -ne "\nName>
 (Optional): "
	read -e NAME
fi

echo -ne "\nBetreff>
 (Optional, wird nur ein mal pfostiert): "
read -e ISUB

echo -ne "\nKommentar>
 (Notwendig für neue Fäden, wird nur ein mal pfostiert): "
read -e ICOM

echo

for FILE in "${ARR_FILES[@]}"; do
	let "COUNT += 1"
	if [ "${FILE}" != "END" ]; then
		if [ ${COUNT} -eq "1" ]; then
			ARR_CURL+=(-F file_0=@${FILE})
			continue
		elif [ ${COUNT} -eq "2" ]; then
			ARR_CURL+=(-F file_1=@${FILE})
			continue
		elif [ ${FILES_ALLOWED} -eq "3" ]; then
			ARR_CURL+=(-F file_2=@${FILE})
		elif [ ${COUNT} -eq "3" ]; then
			ARR_CURL+=(-F file_2=@${FILE})
			continue
		elif [ ${COUNT} -eq "4" ]; then
			ARR_CURL+=(-F file_3=@${FILE})
		fi
	# verhindert curl-fehler im falle von ${FILES_ALLOWED}|${ARR_FILES[@]}
	elif [ "${FILE}" = "END" ] && [ ${COUNT} -eq "1" ]; then
		exit
	fi

	OUTPUT=$(${CURL} -# -A "${UA}" -F "board=${BOARD}" -F "parent=${ID}" -F "forward=thread" -F "internal_n=${NAME}" -F "internal_s=${ISUB}" -F "internal_t=${ICOM}" "${ARR_CURL[@]}" "${POST_URL}")

	if [ -z ${ID} ]; then
		ID=$(echo ${OUTPUT} | egrep -o '\-[0-9]+\.' | egrep -o '[0-9]+')
		echo "Neuen Faden erstellt: http://krautchan.net/${BOARD}/thread-${ID}.html"
	fi
	
	# debug
	#echo -ne "\n\n######################\n\n${OUTPUT}" >> ${HOME}/Desktop/debug.txt
	
	COUNT="0"
	unset ARR_CURL
	ISUB=""
	ICOM=""
	
done
