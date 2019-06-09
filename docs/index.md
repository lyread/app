[![Google Play Store](assets/img/play.svg)](https://play.google.com/store/apps/details?id=app.lyread)

## Bände

| Reihe               | Verlag                     | Links                                                                                   |
|:--------------------|:---------------------------|:----------------------------------------------------------------------------------------|
| Digitale Bibliothek | Directmedia Publishing     | [Wikipedia](https://de.wikipedia.org/wiki/Digitale_Bibliothek_(Produkt))                |
| Dudenbände 1-12     | Bibliographisches Institut | [Wikipedia](https://de.wikipedia.org/wiki/Duden#Duden_in_zw%C3%B6lf_B%C3%A4nden_(2017)) |

## Directmedia
1. Vertrieb durch Buchhandel:
   * Als CD-Rom oder Download bei [Versand-AS](https://www.versand-as.de/Digitale-Bibliothek/)
   * Nur CD-Rom siehe [Directmedia Publishing](https://www.buchpreis24.de/verlag/Directmedia%20Publishing) und das [Historische Wörterbuch der Philosophie](https://www.buchpreis24.de/isbn/9783796526855)
2. Auf dem Telefon den Ordner »Directmedia« anlegen, in den Einstellungen von Lyread auswählen.
   1. CD-Rom: Pro Band einen Unterordner anlegen mit den Ordnern »Data« und »Images« von der CD-Rom.
   2. Download: Die .dbz-Datei hineinkopieren, alternativ mit [7-Zip](http://www.7-zip.de) entpacken.

```
Directmedia
├── Band1
│   ├── Data
│   └── Images
├── Band2
│   ├── Data
│   └── Images
├── Band3.dbz
└── Band4.dbz
```

## Duden
1. Wörterbücher als [Software-Download](https://www.duden.de/Shop/Deutsche-Sprache?medium=1120), mit Systemvoraussetzungen »Duden Bibliothek 6 oder höher«.
2. Auf dem Telefon den Ordner »Duden« anlegen, in den Einstellungen von Lyread auswählen.
3. Rechtsklick auf die heruntergeladene .exe-Datei, [7-Zip](http://www.7-zip.de) > Öffnen. Die .dbb-Datei im Ordner »data« entpacken.
4. Um die Aussprache abzuspielen, die Datei [dbmedia.bdb](http://www.duden-bibliothek.de/data/dbmedia.bdb) herunterladen.

```
Duden
├── duden1.dbb
├── duden2.dbb
├── ...
└── dbmedia.bdb
```
