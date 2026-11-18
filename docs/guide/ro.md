# DRX to LUT — Ghid de utilizare
v{{VERSION}} · DaVinci Resolve Studio 21.2 · macOS 13+ (Apple silicon)

## 1. Ce face
DRX to LUT transformă un grading făcut în DaVinci Resolve într-un LUT .cube 65³. Exporți grading-ul din Resolve ca fișier DRX, îl tragi în aplicație, vezi ce noduri pot intra într-un LUT, confirmi intrarea și ieșirea și apeși „Creează LUT 65”. Totul rulează pe Mac-ul tău; nimic nu se încarcă nicăieri.

## 2. Înainte de a începe
- DaVinci Resolve Studio trebuie să fie pornit, cu scripting extern activat: Preferences > System > General > External scripting using > Local. Aplicația a fost verificată cu Resolve Studio 21.2; alte versiuni și ediția gratuită nu au fost verificate.
- Efectele OFX folosite în DRX (de exemplu GDC STYLE Client, instalat separat) trebuie să fie instalate pe acest Mac. Dacă lipsește unul, aplicația spune asta și nu creează nimic, pentru că LUT-ul ar fi incomplet.
- Salvează mai întâi proiectul tău din Resolve. Aplicația lucrează într-un proiect separat numit „DRX to LUT - work project”. Dacă Resolve este în alt proiect, aplicația întreabă înainte să schimbe și apoi îți oferă revenirea la al tău. Proiectul tău nu este niciodată salvat de aplicație.

## 3. Instalare
Deschide DRXtoLUT-{{VERSION}}.pkg, urmează instalatorul (cere parola Mac-ului) și deschide DRX to LUT din Aplicații. La prima deschidere, macOS poate cere confirmarea pentru o aplicație descărcată de pe internet; aplicația este semnată cu certificat Developer ID și notarizată de Apple.

## 4. Exportă un DRX din Resolve
Pe pagina Color, fă grading pe un clip. Salvează un still (clic dreapta pe viewer > Grab Still). În galerie, clic dreapta pe still, alege Export, formatul DRX și un nume.

## 5. Creează LUT-ul
Trage DRX-ul în fereastră sau apasă „Alege DRX…”.
![idle]
Aplicația deschide grading-ul în Resolve și listează nodurile. Bifează nodurile care să intre în LUT. Nodurile care nu pot fi într-un LUT sunt excluse și blocate.
![review]
Citește caseta Intrare și ieșire și bifează confirmarea. Alege numele și folderul de destinație și apasă „Creează LUT 65”. O bară de progres arată pașii; Anulează se oprește în siguranță și nu lasă niciun fișier incomplet. Dacă există deja un fișier cu același nume, aplicația întreabă înainte să-l înlocuiască.
![done]
În folder primești: fișierul .cube, o copie a DRX-ului, un fișier de note (.README.txt) și un fișier citibil de mașină (.lutinfo.json).

## 6. Aplică LUT-ul corect în Resolve
1. În Resolve deschide Project Settings > Color Management > Lookup Tables și apasă „Open LUT Folder”. Copiază acolo .cube, apoi apasă „Update Lists”.
2. Pe un nod al clipului, clic dreapta > 3D LUT și alege fișierul. Setează interpolarea 3D LUT la Tetrahedral.
3. Clipul trebuie să fie în spațiul de culoare de intrare confirmat în aplicație. Nu adăuga a doua oară transformările de intrare sau ieșire: LUT-ul conține deja nodurile bifate.

## 7. Ce nu poate ține un LUT
Un LUT schimbă culoarea pixel cu pixel. Blur, grain, halation, reducerea zgomotului, măști, tracking și orice depinde de pixelii vecini sau de alte cadre nu pot fi într-un LUT. Aplicația folosește patru etichete:
- Intră în LUT: operații de culoare pixel cu pixel pe care aplicația le recunoaște.
- Nu poate fi într-un LUT: efecte spațiale sau temporale. Excluse automat și trecute în note.
- Efect necunoscut: un efect OFX pe care aplicația nu îl poate clasifica. Exclus implicit; decizi tu.
- Operație Resolve neidentificată: instrumentele native ale lui Resolve nu pot fi identificate complet. Blur, reducerea zgomotului, măști sau qualifiers dintr-un astfel de nod nu sunt detectate și ar produce un LUT incorect.
Detectarea se bazează pe numele efectelor vizibile în Resolve; nu este o analiză completă a imaginii. Un LUT 65³ este o aproximare: pot apărea mici diferențe în culori extreme sau lângă tranziții abrupte. Aplicația nu afirmă că un LUT arată identic cu DRX-ul; compară-le pe materialul tău.

## 8. Dacă ceva nu merge
![failed]
- „DaVinci Resolve nu este pornit”: pornește Resolve Studio și încearcă din nou.
- „Resolve nu acceptă conexiunea”: activează scripting-ul extern (secțiunea 2).
- „Efecte lipsă pe acest Mac”: instalează efectele OFX din DRX, apoi deschide din nou DRX-ul.
- „Fișierul DRX pare corupt”: exportă-l din nou din Resolve.
- „Rezultatul randării este degenerat”: de obicei media offline sau un nod care distruge imaginea; nu se scrie niciun LUT.

## 9. Actualizări, confidențialitate, dezinstalare
Aplicația caută actualizări la pornire și verifică semnătura, suma de control și versiunea pachetului înainte de instalare. Fișierele DRX, LUT-urile și datele tale personale nu părăsesc Mac-ul; singura conexiune la rețea este verificarea de actualizări. Un jurnal local se păstrează în ~/Library/Logs/DRXtoLUT.log; din Setări poți exporta un pachet de diagnostic redactat pe care îl trimiți tu, dacă vrei. Setări > „Dezinstalează complet aplicația” șterge aplicația și datele ei.
DRX to LUT este un proiect independent sub licență MIT, furnizat „ca atare”, și nu este afiliat cu Blackmagic Design. Include un runtime Python 3.12; vezi OPEN_SOURCE_NOTICES.md. Cod sursă și probleme: https://github.com/gordasgdc/drx-to-lut
