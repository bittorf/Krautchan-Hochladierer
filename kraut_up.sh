#!/usr/bin/env bash

curl=$(which curl)
if [ -z "${curl}" ]; then
	echo "Dieses Skript benötigt cURL. Vergewissere dich dass es installiert ist und im Suchpfad liegt."
	exit 1
fi

ua="Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_7; en-us) AppleWebKit/533.21.1 (KHTML, like Gecko) Version/5.0.5 Safari/533.21.1"
post_url="http://krautchan.net/post"
#delete_url="http://krautchan.net/delete"
#pwd=""
bifs=${IFS}
name_allowed=""
optional=""
combo=0
files_allowed=""
count=0
arr_kind=(-iname "*.gif" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.psd" -o -iname "*.mp3" -o -iname "*.ogg" -o -iname "*.rar" -o -iname "*.zip" -o -iname "*.torrent" -o -iname "*.swf")

while getopts "hsoc:" opt; do
	case "${opt}" in
		h)
		echo "
kraut_up.sh [-soh] [-c 1-4] Datei ...

Erstellt Fäden und pfostiert alle auf Krautchan erlaubten Dateien aus einem oder mehreren Verzeichnissen.
Alternativ lassen sich die zu pfostierenden Dateien als Skript-Argument angeben (Dateigröße und Art werden
dabei nicht berücksichtigt).
Getestet mit OS X, Debian Stale und Cygwin.

Wiezu:
 -s	Säge!
 -c n	Begrenzt die erlaubten Dateien pro Pfostierung auf n. Nützlich für Combos.
	Berücksichtige, dass z.B. 11.jpg vor 2.jpg einsortiert wird!
 -o	Optionale Abfragen (Name, Betreff und Kommentar) werden aktiviert.
 -h	Diese Hilfe."
		exit
		;;
		s)
		sage=1
		;;
		o)
		optional=1
		;;
		c)
		combo=${OPTARG}
		;;
	esac
done

shift $((OPTIND-1))
arr_files+=("${@}")

choose() {
echo -ne "Wähle ein Brett aus
 (b,int,vip,a,c,d,e,f,fb,fit,jp,k,l,li,m,p,ph,sp,t,tv
  v,w,we,wp,x,n,rfk,z,zp,h,s,kc): "
read -e board

case "${board}" in #NEGER, BITTE!
	b|int|vip)
	name_allowed=no
	files_allowed=4
	max_file_size=10M
	;;
	a|jp)
	files_allowed=3
	max_file_size=9M
	;;
	k)
	files_allowed=3
	max_file_size=10M
	#max_post_size=15
	;;
	l|m)
	files_allowed=3
	max_file_size=20M
	#max_post_size=40
	;;
	c|fb|p|tv|v|we)
	files_allowed=3
	max_file_size=6M
	;;
	wp)
	arr_kind=(-iname "*.gif" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.psd")
	files_allowed=3
	max_file_size=6M
	;;
	rfk)
	files_allowed=3
	max_file_size=5M
	;;
	z|zp|s)
	arr_kind=(-iname "*.gif" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.psd")
	files_allowed=4
	max_file_size=6M
	;;
	h)
	arr_kind=(-iname "*.gif" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.psd")
	files_allowed=3
	max_file_size=3M
	;;
	d|e|f|fit|li|ph|sp|t|w|x|n|kc)
	files_allowed=3
	max_file_size=3M
	;;
	*)
	echo -e "\nDepp.\n"
	choose
	;;
esac
}

clear
choose

if [ "${combo}" -gt "${files_allowed}" ]; then
	echo -ne "\nEine ${combo}er-Combo ist nicht möglich da auf /${board}/ nur ${files_allowed} Dateien pro Pfostierung erlaubt sind.\n"
	exit
elif [ "${combo}" -lt "${files_allowed}" ]; then
	files_allowed=${combo}
fi

echo -ne "\nFaden-ID
 (z.B. 3025905 - leer lassen um einen neuen Faden zu erstellen): "
read -e id

if [ -z "${arr_files}" ]; then
	echo -ne "\nVerzeichniss(e) auswählen. Leerzeichen müssen escaped werden.
 (z.B.: /Users/bernd/penisbilder /home/bernadette/als\ ob):\n"
	read -ea arr_dir
	IFS='
'
	for dir in "${arr_dir[@]}"; do
		for files in $(find ${dir} -type f -size -${max_file_size} \( ${arr_kind[@]} \) ); do
			arr_files+=("${files}")
		done
	done
	IFS=${bifs}
fi

if [ -n "${optional}" ]; then
	if [ -z "${name_allowed}" ]; then
		echo -ne "\nName: "
		read -e name
	fi
	echo -ne "\nBetreff
 (Wird nur ein mal pfostiert): "
	read -e isub
	echo -ne "\nKommentar
 (Wird nur ein mal pfostiert): "
	read -e icom
elif [ -z "${id}" ] && [ -z "${icom}" ]; then
	echo -ne "\nKommentar
 (Ist nötig weil ein neuer Faden erstellt wird. Wird nur ein mal pfostiert): "
	read -e icom
fi

arr_files+=(END)

echo

for file in "${arr_files[@]}"; do
	((count += 1))
	if [ "${file}" != "END" ]; then
		if [ "${files_allowed}" -eq "1" ]; then
			arr_curl+=(-F file_0=@${file})
		elif [ "${count}" -eq "1" ]; then
			arr_curl+=(-F file_0=@${file})
			continue
		elif [ "${files_allowed}" -eq "2" ]; then
			arr_curl+=(-F file_1=@${file})
		elif [ "${count}" -eq "2" ]; then
			arr_curl+=(-F file_1=@${file})
			continue
		elif [ "${files_allowed}" -eq "3" ]; then
			arr_curl+=(-F file_2=@${file})
		elif [ "${count}" -eq "3" ]; then
			arr_curl+=(-F file_2=@${file})
			continue
		elif [ "${count}" -eq "4" ]; then
			arr_curl+=(-F file_3=@${file})
		fi
	# verhindert curl-fehler im falle von ${files_allowed}|${arr_files[@]}
	elif [ "${file}" = "END" ] && [ "${count}" -eq "1" ]; then
		exit
	fi

	output=$(${curl} -# -A "${ua}" -F "sage=${sage}" -F "board=${board}" -F "parent=${id}" -F "forward=thread" -F "internal_n=${name}" -F "internal_s=${isub}" -F "internal_t=${icom}" "${arr_curl[@]}" "${post_url}")

	if [ -z "${id}" ]; then
		[[ $output =~ .*thread-([0-9]*)\.html.* ]]
		id=${BASH_REMATCH[1]}
		echo "Neuen Faden erstellt: http://krautchan.net/${board}/thread-${id}.html"
	fi
	
	# debug
	#echo -ne "\n\n######################\n\n${output}" >> ${HOME}/Desktop/debug.txt
	
	count=0
	unset arr_curl
	isub=""
	icom=""
done
