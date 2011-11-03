#!/usr/bin/env bash

if [[ -z "$(type -P curl)" ]]; then
	echo "Dieses Skript benötigt cURL. Vergewissere dich dass es installiert ist und im Suchpfad liegt."; exit 1
fi

ua="Krautchan-Hochladierer"
post_url="http://krautchan.net/post"
debug_file=${HOME}/debug.txt
pause=0
c_retry=3; c_delay=120; c_timeout=900; count=0; period_count=0; optional=0; combo=0; name_allowed=1; debug=0; interact=0; twist=0
bifs=${IFS}; id=; name=; isub=; icom=; start_time=0
#delete_url="http://krautchan.net/delete"
#pwd=""
arr_kind=(-iname "*.gif" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.psd" -o -iname "*.mp3" -o -iname "*.ogg" -o -iname "*.rar" -o -iname "*.zip" -o -iname "*.torrent" -o -iname "*.swf")

kchelp="\n${0##*/} [-sordh] [-c 1-4] [-p <integer>] [-x <proxyhost[:port]>] [-k <komturcode>] Datei ...

Erstellt Fäden und pfostiert alle auf Krautchan erlaubten Dateien aus einem oder mehreren Verzeichnissen.
Alternativ lassen sich die zu pfostierenden Dateien als Skript-Argument angeben (Dateigröße und Art werden
dabei nicht berücksichtigt).
Während des Upload-Vorgangs lassen sich mittels ctrl-c Kommentare hinzufügen.
Getestet mit OS X, Debian Stale und Cygwin.

Wiezu:
 -s	Säge!
 -c n	Begrenzt die erlaubten Dateien pro Pfostierung auf n. Nützlich für Combos.
	Berücksichtige, dass z.B. 11.jpg vor 2.jpg einsortiert wird!
 -o	Optionale Abfragen (Name, Betreff und Kommentar) werden aktiviert.
 -r	Dateien werden in einer zufälligen Reihenfolge pfostiert.
 -p n	Zwischen den Pfostierungen wird eine Pause von n-Sekunden eingelegt.
 -x n	HTTP-Proxy.
 -k n	Komturcode.
 -d	Debugoutput wird aktiviert (${debug_file}).
 -h	Diese Hilfe."

randomize() {
n=${#arr_files[@]}
while ((n)); do
	indices=("${!arr_files[@]}")		# kopiert den array-index in ein neues array
	i=${indices[RANDOM%n--]}			# rand modulo elementanzahl des arrays / post-decrement n
	echo "${arr_files[i]}"
	unset "arr_files[i]"
done
}

while getopts ":soc:rp:x:k:dh" opt; do
	case "${opt}" in
		s) 	sage=1 ;;
		c) 	[[ "${OPTARG}" != [1-4] ]] && echo -e "\nAch, Bernd! Nur die Ziffern 1 bis 4 machen Sinn ..." && exit 1
			combo=${OPTARG} ;;
		o) 	optional=1 ;;
		r)	twist=1 ;;
		p)	[[ "${OPTARG}" != *[!0-9]* ]] && pause="${OPTARG}" || exit 1 ;;
		x)	arr_proxy=(-x ${OPTARG}) ;;
		k)	arr_komtur=(-b desuchan.komturcode=${OPTARG}) ;;
		d)	debug=1 ;;
		h) 	echo -e "${kchelp}"; exit 0 ;;
		\?)	echo -e "\n -${OPTARG} gibt es nicht!\n${kchelp}"; exit 1 ;;
		:)	echo -e "\n -${OPTARG} benötigt ein Argument!\n${kchelp}"; exit 1 ;;
	esac
done

shift $((OPTIND-1))
[[ "${1}" == -- ]] && shift
arr_files=("${@}")

choose() {
echo -e "Wähle ein Brett aus\n (b,int,vip,a,c,d,e,f,fb,fit,jp,k,l,li,m,p,ph,sp,t,tv\n  v,w,we,wp,x,n,rfk,z,zp,h,s,kc)"
read -en 4 -p "> " board

case "${board}" in #NEGER, BITTE!
	b|int|vip)		files_allowed=4; max_file_size=10M; name_allowed=0 ;;
	a|jp)			files_allowed=3; max_file_size=9M ;;
	k)				files_allowed=3; max_file_size=10M ;; #max_post_size=15
	l|m)			files_allowed=3; max_file_size=20M ;; #max_post_size=40
	c|fb|p|tv|v|we) files_allowed=3; max_file_size=6M ;;
	wp)				files_allowed=3; max_file_size=6M
					arr_kind=(-iname "*.gif" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.psd") ;;
	rfk)			files_allowed=3; max_file_size=5M ;;
	z|zp|s)			files_allowed=4; max_file_size=6M
					arr_kind=(-iname "*.gif" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.psd") ;;
	h)				files_allowed=3; max_file_size=3M
					arr_kind=(-iname "*.gif" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.psd") ;;
	d|e|f|fit|li|ph|sp|t|w|x|n|kc)		files_allowed=3; max_file_size=3M ;;
	*)				echo -e "\nDepp.\n"; choose ;;
esac
}

clear; choose

if [[ "${combo}" -gt "${files_allowed}" ]]; then
	echo -e "\nEine ${combo}er-Combo ist nicht möglich, da auf /${board}/ nur ${files_allowed} Dateien pro Pfostierung erlaubt sind."
	exit 1
elif [[ "${combo}" -ne "0" ]]; then
	files_allowed=${combo}
fi

echo -e "\nFaden-ID\n (z.B. 3025905 - leer lassen um einen neuen Faden zu erstellen)"
read -ep "> " id

if [[ -z "${arr_files}" ]]; then
	echo -e "\nVerzeichniss(e) auswählen. Leerzeichen müssen escaped werden.\n (z.B.: /Users/bernd/penisbilder /home/bernadette/als\ ob)"
	read -ep "> " -a arr_dir
	
	IFS=$'\n' # erlaubt leerzeichen in dateipfaden und dateinamen, trennt den find/randomize output in einzelne elemente
	
	for dir in "${arr_dir[@]}"; do
		for files in $(find "${dir}" -type f -size -${max_file_size} \( ${arr_kind[@]} \) ); do
			arr_files+=("${files}")
		done
	done
	
	IFS=${bifs}
fi

echo -e "\n${#arr_files[@]} Dateien gefunden."

if [[ "${twist}" -eq "1" ]]; then
	echo "Zufällige Reihenfolge wird erstellt …"
	IFS=$'\n'
	arr_files=( $(randomize) )
	IFS=${bifs}
fi

if [[ "${optional}" -eq "1" ]]; then
	if [[ "${name_allowed}" -eq "1" ]]; then
		echo -e "\nName"
		read -ep "> " name
	fi
	echo -e "\nBetreff\n (Wird nur ein mal pfostiert)"
	read -ep "> " isub
	echo -e "\nKommentar\n (Wird nur ein mal pfostiert)"
	read -ep "> " icom
elif [[ -z "${id}" ]] && [[ -z "${icom}" ]]; then
	echo -e "\nKommentar\n (Ist nötig weil ein neuer Faden erstellt wird. Wird nur ein mal pfostiert)"
	read -ep "> " icom
fi

arr_files+=(END)

echo

trap 'interact=1' 2

for file in "${arr_files[@]}"; do
	((count += 1))
	if [[ "${file}" != "END" ]]; then
		if [[ "${files_allowed}" -eq "1" ]]; then
			arr_curl+=(-F file_0=@${file})
		elif [[ "${count}" -eq "1" ]]; then
			arr_curl+=(-F file_0=@${file})
			continue
		elif [[ "${files_allowed}" -eq "2" ]]; then
			arr_curl+=(-F file_1=@${file})
		elif [[ "${count}" -eq "2" ]]; then
			arr_curl+=(-F file_1=@${file})
			continue
		elif [[ "${files_allowed}" -eq "3" ]]; then
			arr_curl+=(-F file_2=@${file})
		elif [[ "${count}" -eq "3" ]]; then
			arr_curl+=(-F file_2=@${file})
			continue
		elif [[ "${count}" -eq "4" ]]; then
			arr_curl+=(-F file_3=@${file})
		fi
	# verhindert curl-fehler im falle von ${files_allowed}|${arr_files[@]}
	elif [[ "${file}" = "END" ]] && [[ "${count}" -eq "1" ]]; then
		exit 0
	fi
	
	if [[ "${interact}" -eq "1" ]]; then
		echo -e "\nSkript wirklich [b]eenden oder [K]ommentar hinzufügen und fortsetzen?"
		read -en 1 interact_ans
		case "${interact_ans}" in
			b|B)	exit 0 ;;
			k|K)	read -ep "Kommentar: " icom; interact=0 ;;
			*)		exit 1 ;;
		esac
	fi
	
	output=$(trap '' 2; curl "${arr_proxy[@]}" "${arr_komtur[@]}" --retry "${c_retry}" --retry-delay "${c_delay}" --max-time "${c_timeout}" -# -A "${ua}" -F "sage=${sage}" -F "board=${board}" -F "parent=${id}" -F "forward=thread" -F "internal_n=${name}" -F "internal_s=${isub}" -F "internal_t=${icom}" "${arr_curl[@]}" "${post_url}")
	date +%s
	
	((period_count += 1))
	
	if [[ "${period_count}" -gt "3" ]]; then
		((start_diff = $(date +%s) - start_time))
		if [[ "${start_diff}" -lt "60" ]]; then
			echo "Pause für $((60 - start_diff)) Sekunden um das Pfostenlimit von 4 Pfosten pro Minute nicht zu überschreiten."
			sleep $((60 - start_diff))
			period_count=0
			start_time=0
		fi
	fi
	
	[[ "${start_time}" -eq "0" ]] && [[ "${period_count}" -ge "1" ]] && start_time=$(date +%s)
	
	[[ ${output} =~ .*banned.* ]] && echo "Sie, mein Herr, sind banniert! Glückwunsch! (http://krautchan.net/banned)" && exit 1
	
	[[ ${output} =~ .*Verification\ code\ wrong.* ]] || [[ ${output} =~ .*Verifizierungscode\ falsch\..* ]] && echo "Captchas sind aktiv ;_;" && exit 1
	
	[[ ${output} =~ .*Posts\ in\ 60\ Sekunden.* ]] && echo "Mehr als 4 Pfosten pro Minute sind nicht erlaubt. Verworfen."
	
	[[ "${debug}" -eq "1" ]] && echo -ne "${arr_curl[@]}\n\n${icom}\n\n${id}\n\n${output}\n\n##\n##\n\n" >> ${debug_file}
	
	if [[ -z "${id}" ]]; then
		[[ $output =~ .*thread-([0-9]*)\.html.* ]]
		id=${BASH_REMATCH[1]}
		echo "Neuen Faden erstellt: http://krautchan.net/${board}/thread-${id}.html"
	fi
	
	[[ "${pause}" -gt "0" ]] && echo "Pause: ${pause} Sekunden" && sleep ${pause}
	
	unset arr_curl
	count=0; isub=; icom=
done

exit 0
