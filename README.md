##WIE-ZU:

**kraut_up.sh** [-sordh] [-c 1-4] [-p \<integer\>] [-x \<proxyhost[:port]\>] [-k \<komturcode\>] Datei ...

Erstellt Fäden und pfostiert alle auf Krautchan erlaubten Dateien aus einem oder mehreren Verzeichnissen.
Alternativ lassen sich die zu pfostierenden Dateien als Skript-Argument angeben (Dateigröße und Art werden
dabei nicht berücksichtigt).
Während des Upload-Vorgangs lassen sich mittels ctrl-c Kommentare hinzufügen.
Getestet mit OS X, Debian Stale und Cygwin.

**-s**	Säge!

**-c *n***	Begrenzt die erlaubten Dateien pro Pfostierung auf n. Nützlich für Combos.	Berücksichtige, dass z.B. 11.jpg vor 2.jpg einsortiert wird!

**-o**	Optionale Abfragen (Name, Betreff und Kommentar) werden aktiviert.

**-r**	Dateien in einer zufälligen Reihenfolge pfostieren.

**-p *n***	Pause von n Sekunden zwischen Pfostierungen einlegen.

**-x *n***	Proxy.

**-k *n***	Komturcode.

**-d**	Debug-Texte aktivieren.

**-h**	Diese Hilfe.