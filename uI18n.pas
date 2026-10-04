unit uI18n;

{ i18n - tabela tlumaczen z katalogow (katalogi = zrodlo prawdy).
  DFM-y trzymaja tekst angielski; TranslateForm podmienia go wg aktywnego jezyka.
  Jezyki bez tlumaczen wracaja do angielskiego. }

interface

uses
  System.SysUtils, System.Generics.Collections, Vcl.Forms, Vcl.Controls,
  Vcl.Menus, Vcl.ComCtrls;

type
  TLanguage = (lgPolish, lgEnglish, lgGerman, lgFrench, lgSpanish, lgItalian, lgCzech, lgPortuguese, lgAfrikaans);

  TTextRec = record
    EN: string;
    PL: string;
    CS: string;
    FR: string;
    DE: string;
    IT: string;
    ES: string;
    PT: string;
    AF: string;
  end;

const
  // EN-klucze rekordow nazw jezykow w TextTable; dialog wyboru jezyka czyta je przez T()
  cLanguageKeys: array[TLanguage] of string = ('Polski (Polish)', 'English', 'Deutsch (German)', 'Français (French)', 'Español (Spanish)', 'Italiano (Italian)', 'Čeština (Czech)', 'Português (Portuguese)', 'Afrikaans');

function T(const AEnglishText: string): string;
procedure SetLanguage(ALang: TLanguage);
function DetectLanguage: TLanguage;
function CurrentLanguage: TLanguage;
procedure TranslateForm(AForm: TForm);
procedure TranslateMenuItem(M: TMenuItem);

type
  TI18nEvents = class
  public
    procedure ActiveFormChanged(Sender: TObject);
  end;

var
  gI18nEvents: TI18nEvents;

implementation

uses
  System.TypInfo, System.Variants, System.Classes,
  System.IOUtils, Winapi.Windows, uTitleBar;

const
  // BEGIN GENERATED TEXTABLE - nie edytować ręcznie, generuje tools\gen_i18n.ps1
  TextTable: array[0..1047] of TTextRec = (
    (EN: 'File'; PL: 'Plik'; CS: 'Soubor';
     FR: 'Fichier'; DE: 'Datei'; IT: 'File';
     ES: 'Archivo'; PT: 'Ficheiro'; AF: 'Lêer'),
    (EN: 'Edit'; PL: 'Edycja'; CS: 'Úpravy';
     FR: 'Édition'; DE: 'Bearbeiten'; IT: 'Modifica';
     ES: 'Editar'; PT: 'Editar'; AF: 'Wysig'),
    (EN: 'Effect Blend'; PL: 'Mieszanie efektów'; CS: 'Míchání efektů';
     FR: 'Mélange d’effets'; DE: 'Effekt-Mischung'; IT: 'Fusione effetti';
     ES: 'Mezcla de efectos'; PT: 'Mistura de efeitos'; AF: 'Effekmengsel'),
    (EN: 'View'; PL: 'Widok'; CS: 'Zobrazení';
     FR: 'Affichage'; DE: 'Ansicht'; IT: 'Visualizza';
     ES: 'Ver'; PT: 'Ver'; AF: 'Bekyk'),
    (EN: 'Analyze'; PL: 'Analiza'; CS: 'Analýza';
     FR: 'Analyse'; DE: 'Analyse'; IT: 'Analizza';
     ES: 'Analizar'; PT: 'Analisar'; AF: 'Ontleed'),
    (EN: 'Adjust'; PL: 'Korektor'; CS: 'Úpravy';
     FR: 'Ajuster'; DE: 'Anpassen'; IT: 'Regola';
     ES: 'Ajustar'; PT: 'Ajustar'; AF: 'Pas aan'),
    (EN: 'Colors'; PL: 'Kolory'; CS: 'Barvy';
     FR: 'Couleurs'; DE: 'Farben'; IT: 'Colori';
     ES: 'Colores'; PT: 'Cores'; AF: 'Kleure'),
    (EN: 'Effects'; PL: 'Efekty'; CS: 'Efekty';
     FR: 'Effets'; DE: 'Effekte'; IT: 'Effetti';
     ES: 'Efectos'; PT: 'Efeitos'; AF: 'Effekte'),
    (EN: 'Print'; PL: 'Druk'; CS: 'Tisk';
     FR: 'Imprimer'; DE: 'Drucken'; IT: 'Stampa';
     ES: 'Imprimir'; PT: 'Imprimir'; AF: 'Druk'),
    (EN: 'Experimental'; PL: 'Eksperymentalne'; CS: 'Experimentální';
     FR: 'Expérimental'; DE: 'Experimentell'; IT: 'Sperimentale';
     ES: 'Experimental'; PT: 'Experimental'; AF: 'Eksperimenteel'),
    (EN: 'Distortions'; PL: 'Zniekształcenia'; CS: 'Zkreslení';
     FR: 'Distorsions'; DE: 'Verzerrungen'; IT: 'Distorsioni';
     ES: 'Distorsiones'; PT: 'Distorções'; AF: 'Verdistortings'),
    (EN: 'Amiga'; PL: 'Amigowe'; CS: 'Amiga';
     FR: 'Amiga'; DE: 'Amiga'; IT: 'Amiga';
     ES: 'Amiga'; PT: 'Amiga'; AF: 'Amiga'),
    (EN: 'Help'; PL: 'Pomoc'; CS: 'Pomoc';
     FR: 'Aide'; DE: 'Helfen'; IT: 'Aiuto';
     ES: 'Ayuda'; PT: 'Ajuda'; AF: 'Hulp'),
    (EN: 'Open...'; PL: 'Otwórz...'; CS: 'Otevřít...';
     FR: 'Ouvrir…'; DE: 'Öffnen...'; IT: 'Apri...';
     ES: 'Abrir...'; PT: 'Abrir...'; AF: 'Maak oop...'),
    (EN: 'Save as...'; PL: 'Zapisz jako...'; CS: 'Uložit jako...';
     FR: 'Enregistrer sous…'; DE: 'Speichern unter...'; IT: 'Salva con nome...';
     ES: 'Guardar como...'; PT: 'Guardar como...'; AF: 'Stoor as...'),
    (EN: 'Image info'; PL: 'Informacja o obrazie'; CS: 'Informace o obrázku';
     FR: 'Informations sur l’image'; DE: 'Bildinfo'; IT: 'Informazioni immagine';
     ES: 'Información de la imagen'; PT: 'Informações da imagem'; AF: 'Beeldinligting'),
    (EN: '(none)'; PL: '(nic)'; CS: '(žádný)';
     FR: '(Aucune image)'; DE: '(kein Bild)'; IT: '(Nessuna)';
     ES: '(Ninguna)'; PT: '(Nenhuma)'; AF: '(Geen)'),
    (EN: 'Close'; PL: 'Zamknij'; CS: 'Zavřít';
     FR: 'Fermer'; DE: 'Schließen'; IT: 'Chiudi';
     ES: 'Cerrar'; PT: 'Fechar'; AF: 'Sluit'),
    (EN: 'Preferences...'; PL: 'Preferencje...'; CS: 'Předvolby...';
     FR: 'Préférences…'; DE: 'Einstellungen...'; IT: 'Preferenze...';
     ES: 'Preferencias...'; PT: 'Preferências...'; AF: 'Voorkeure...'),
    (EN: 'Quit'; PL: 'Wyjście'; CS: 'Konec';
     FR: 'Quitter'; DE: 'Beenden'; IT: 'Esci';
     ES: 'Salir'; PT: 'Sair'; AF: 'Verlaat'),
    (EN: 'Undo'; PL: 'Cofnij'; CS: 'Zpět';
     FR: 'Annuler'; DE: 'Rückgängig'; IT: 'Annulla';
     ES: 'Deshacer'; PT: 'Anular'; AF: 'Ontdoen'),
    (EN: 'Redo'; PL: 'Ponów'; CS: 'Znovu';
     FR: 'Rétablir'; DE: 'Wiederholen'; IT: 'Ripristina';
     ES: 'Rehacer'; PT: 'Refazer'; AF: 'Herdoen'),
    (EN: 'Copy'; PL: 'Kopiuj'; CS: 'Kopírovat';
     FR: 'Copier'; DE: 'Kopieren'; IT: 'Copia';
     ES: 'Copiar'; PT: 'Copiar'; AF: 'Kopieer'),
    (EN: 'Paste'; PL: 'Wklej'; CS: 'Vložit';
     FR: 'Coller'; DE: 'Einfügen'; IT: 'Incolla';
     ES: 'Pegar'; PT: 'Colar'; AF: 'Plak'),
    (EN: 'Revert to original'; PL: 'Przywróć oryginał'; CS: 'Obnovit originál';
     FR: 'Restaurer l’original'; DE: 'Original wiederherstellen'; IT: 'Ripristina originale';
     ES: 'Restaurar original'; PT: 'Repor original'; AF: 'Herstel oorspronklike'),
    (EN: 'Clear history'; PL: 'Wyczyść historię'; CS: 'Vymazat historii';
     FR: 'Effacer l’historique'; DE: 'Verlauf löschen'; IT: 'Cancella cronologia';
     ES: 'Borrar historial'; PT: 'Limpar histórico'; AF: 'Vee geskiedenis uit'),
    (EN: 'Effect Blend...'; PL: 'Mieszanie efektów...'; CS: 'Míchání efektů...';
     FR: 'Mélange d’effets…'; DE: 'Effekt-Mischung...'; IT: 'Fusione effetti...';
     ES: 'Mezcla de efectos...'; PT: 'Mistura de efeitos...'; AF: 'Effekmengsel...'),
    (EN: 'Blend (0=A, 100=B):'; PL: 'Mieszanie (0=A, 100=B):'; CS: 'Míchání (0=A, 100=B):';
     FR: 'Mélange (0=A, 100=B) :'; DE: 'Mischung (0=A, 100=B):'; IT: 'Fusione (0=A, 100=B):';
     ES: 'Mezcla (0=A, 100=B):'; PT: 'Mistura (0=A, 100=B):'; AF: 'Mengsel (0=A, 100=B):'),
    (EN: 'Merge visible'; PL: 'Połącz widoczne'; CS: 'Sloučit viditelné';
     FR: 'Fusionner les calques visibles'; DE: 'Sichtbare zusammenführen'; IT: 'Unisci livelli visibili';
     ES: 'Combinar capas visibles'; PT: 'Unir camadas visíveis'; AF: 'Voeg sigbare lae saam'),
    (EN: 'Delete all'; PL: 'Wymaż wszystko'; CS: 'Smazat vše';
     FR: 'Supprimer tout'; DE: 'Alle löschen'; IT: 'Elimina tutto';
     ES: 'Eliminar todo'; PT: 'Eliminar tudo'; AF: 'Verwyder alles'),
    (EN: 'Zoom in'; PL: 'Powiększ'; CS: 'Přiblížit';
     FR: 'Zoom avant'; DE: 'Vergrößern'; IT: 'Zoom avanti';
     ES: 'Acercar'; PT: 'Ampliar'; AF: 'Zoem in'),
    (EN: 'Zoom out'; PL: 'Pomniejsz'; CS: 'Oddálit';
     FR: 'Zoom arrière'; DE: 'Verkleinern'; IT: 'Zoom indietro';
     ES: 'Alejar'; PT: 'Reduzir'; AF: 'Zoem uit'),
    (EN: 'Fit to window'; PL: 'Dopasuj do okna'; CS: 'Přizpůsobit oknu';
     FR: 'Adapter à la fenêtre'; DE: 'An Fenster anpassen'; IT: 'Adatta alla finestra';
     ES: 'Ajustar a la ventana'; PT: 'Ajustar à janela'; AF: 'Pas by venster'),
    (EN: '100%'; PL: '100%'; CS: '100%';
     FR: '100 %'; DE: '100%'; IT: '100%';
     ES: '100%'; PT: '100%'; AF: '100%'),
    (EN: '50%'; PL: '50%'; CS: '50%';
     FR: '50 %'; DE: '50%'; IT: '50%';
     ES: '50%'; PT: '50%'; AF: '50%'),
    (EN: '25%'; PL: '25%'; CS: '25%';
     FR: '25 %'; DE: '25%'; IT: '25%';
     ES: '25%'; PT: '25%'; AF: '25%'),
    (EN: '200%'; PL: '200%'; CS: '200%';
     FR: '200 %'; DE: '200%'; IT: '200%';
     ES: '200%'; PT: '200%'; AF: '200%'),
    (EN: '400%'; PL: '400%'; CS: '400%';
     FR: '400 %'; DE: '400%'; IT: '400%';
     ES: '400%'; PT: '400%'; AF: '400%'),
    (EN: 'Histogram...'; PL: 'Histogram...'; CS: 'Histogram...';
     FR: 'Histogramme…'; DE: 'Histogramm...'; IT: 'Istogramma...';
     ES: 'Histograma...'; PT: 'Histograma...'; AF: 'Histogram...'),
    (EN: 'Equalize histogram...'; PL: 'Wyrównanie histogramu...'; CS: 'Vyrovnat histogram...';
     FR: 'Égaliser l’histogramme…'; DE: 'Histogramm ausgleichen...'; IT: 'Equalizza istogramma...';
     ES: 'Ecualizar histograma...'; PT: 'Equalizar histograma...'; AF: 'Egaliseer histogram...'),
    (EN: 'Mirror horizontally'; PL: 'Lustro poziome'; CS: 'Zrcadlit vodorovně';
     FR: 'Retourner horizontalement'; DE: 'Horizontal spiegeln'; IT: 'Rifletti orizzontalmente';
     ES: 'Voltear horizontalmente'; PT: 'Espelhar horizontalmente'; AF: 'Spieël horisontaal'),
    (EN: 'Mirror vertically'; PL: 'Lustro pionowe'; CS: 'Zrcadlit svisle';
     FR: 'Retourner verticalement'; DE: 'Vertikal spiegeln'; IT: 'Rifletti verticalmente';
     ES: 'Voltear verticalmente'; PT: 'Espelhar verticalmente'; AF: 'Spieël vertikaal'),
    (EN: 'Rotate left'; PL: 'Obrót w lewo'; CS: 'Otočit doleva';
     FR: 'Pivoter à gauche'; DE: 'Nach links drehen'; IT: 'Ruota a sinistra';
     ES: 'Girar a la izquierda'; PT: 'Rodar para a esquerda'; AF: 'Draai links'),
    (EN: 'Rotate right'; PL: 'Obrót w prawo'; CS: 'Otočit doprava';
     FR: 'Pivoter à droite'; DE: 'Nach rechts drehen'; IT: 'Ruota a destra';
     ES: 'Girar a la derecha'; PT: 'Rodar para a direita'; AF: 'Draai regs'),
    (EN: 'Straighten scan...'; PL: 'Prostuj skan...'; CS: 'Narovnat sken...';
     FR: 'Redresser le scan…'; DE: 'Scan begradigen...'; IT: 'Raddrizza scansione...';
     ES: 'Enderezar escaneo...'; PT: 'Endireitar digitalização...'; AF: 'Maak skandering reguit...'),
    (EN: 'Contrast...'; PL: 'Kontrast...'; CS: 'Kontrast...';
     FR: 'Contraste…'; DE: 'Kontrast...'; IT: 'Contrasto...';
     ES: 'Contraste...'; PT: 'Contraste...'; AF: 'Kontras...'),
    (EN: 'Brightness...'; PL: 'Jasność...'; CS: 'Jas...';
     FR: 'Luminosité…'; DE: 'Helligkeit...'; IT: 'Luminosità...';
     ES: 'Brillo...'; PT: 'Luminosidade...'; AF: 'Helderheid...'),
    (EN: 'Gamma correction...'; PL: 'Korekcja gamma...'; CS: 'Korekce gama...';
     FR: 'Correction gamma…'; DE: 'Gamma-Korrektur...'; IT: 'Correzione gamma...';
     ES: 'Corrección gamma...'; PT: 'Correção de gama...'; AF: 'Gamma-korreksie...'),
    (EN: 'Levels...'; PL: 'Poziomy...'; CS: 'Úrovně...';
     FR: 'Niveaux…'; DE: 'Tonwertkorrektur...'; IT: 'Livelli...';
     ES: 'Niveles...'; PT: 'Níveis...'; AF: 'Vlakke...'),
    (EN: 'White balance...'; PL: 'Balans bieli...'; CS: 'Vyvážení bílé...';
     FR: 'Balance des blancs…'; DE: 'Weißabgleich...'; IT: 'Bilanciamento del bianco...';
     ES: 'Balance de blancos...'; PT: 'Balanço de brancos...'; AF: 'Witbalans...'),
    (EN: 'Sharpen...'; PL: 'Wyostrzenie...'; CS: 'Doostřit...';
     FR: 'Netteté…'; DE: 'Schärfen...'; IT: 'Nitidezza...';
     ES: 'Enfocar...'; PT: 'Nitidez...'; AF: 'Verskerp...'),
    (EN: 'Vivid...'; PL: 'Soczystość...'; CS: 'Živé barvy...';
     FR: 'Éclat…'; DE: 'Brillant...'; IT: 'Vividezza...';
     ES: 'Intensificar...'; PT: 'Vividez...'; AF: 'Lewendigheid...'),
    (EN: 'Photo enhancement...'; PL: 'Wzmocnienie zdjęcia...'; CS: 'Vylepšení fotografie...';
     FR: 'Amélioration photo…'; DE: 'Fotoverstärkung...'; IT: 'Miglioramento fotografico...';
     ES: 'Mejora fotográfica...'; PT: 'Melhoria fotográfica...'; AF: 'Fotoverbetering...'),
    (EN: 'Crop...'; PL: 'Przycięcie...'; CS: 'Oříznout...';
     FR: 'Recadrer…'; DE: 'Zuschneiden...'; IT: 'Ritaglia...';
     ES: 'Recortar...'; PT: 'Recortar...'; AF: 'Sny uit...'),
    (EN: 'Resize...'; PL: 'Zmiana rozmiaru...'; CS: 'Změnit velikost...';
     FR: 'Redimensionner…'; DE: 'Größe ändern...'; IT: 'Ridimensiona...';
     ES: 'Redimensionar...'; PT: 'Redimensionar...'; AF: 'Verander grootte...'),
    (EN: 'Colorize...'; PL: 'Kolorowanie...'; CS: 'Kolorovat...';
     FR: 'Coloriser…'; DE: 'Einfärben...'; IT: 'Colorizza...';
     ES: 'Colorear...'; PT: 'Colorir...'; AF: 'Kleur in...'),
    (EN: 'HSB balance...'; PL: 'Balans HSB...'; CS: 'HSB vyvážení...';
     FR: 'Équilibre HSB…'; DE: 'HSB-Gleichgewicht...'; IT: 'Bilanciamento HSB...';
     ES: 'Balance HSB...'; PT: 'Balanço HSB...'; AF: 'HSB-balans...'),
    (EN: 'Solarize...'; PL: 'Solaryzacja...'; CS: 'Solarizace...';
     FR: 'Solariser…'; DE: 'Solarisieren...'; IT: 'Solarizza...';
     ES: 'Solarizar...'; PT: 'Solarizar...'; AF: 'Solariseer...'),
    (EN: 'Duotone...'; PL: 'Dwukolor...'; CS: 'Duotón...';
     FR: 'Duotone…'; DE: 'Duoton....'; IT: 'Duotono...';
     ES: 'Duotono...'; PT: 'Duotom...'; AF: 'Duotoon...'),
    (EN: 'Sepia...'; PL: 'Sepia...'; CS: 'Sépie...';
     FR: 'Sépia…'; DE: 'Sepia...'; IT: 'Seppia...';
     ES: 'Sepia...'; PT: 'Sépia...'; AF: 'Sepia...'),
    (EN: 'Cyanotype'; PL: 'Cyanotypia'; CS: 'Kyanotypie';
     FR: 'Cyanotypie'; DE: 'Cyanotypie'; IT: 'Cianotipia';
     ES: 'Cianotipia'; PT: 'Cianotipia'; AF: 'Sianotipe'),
    (EN: 'Salt print'; PL: 'Fotografia solna'; CS: 'Sůl-tisk';
     FR: 'Tirage au sel'; DE: 'Salzdruck'; IT: 'Stampa ai sali';
     ES: 'Impresión a la sal'; PT: 'Impressão a sal'; AF: 'Soutdruk'),
    (EN: 'X-Ray'; PL: 'Rentgen'; CS: 'Rentgen';
     FR: 'Rayons X'; DE: 'Röntgen'; IT: 'Raggi X';
     ES: 'Rayos X'; PT: 'Raios X'; AF: 'X-strale'),
    (EN: 'False-color infrared'; PL: 'Podczerwień fałszywobarwna'; CS: 'Falešné barvy IR';
     FR: 'Infrarouge en fausses couleurs'; DE: 'Falschfarben-Infrarot'; IT: 'Infrarosso a falsi colori';
     ES: 'Infrarrojo en falso color'; PT: 'Infravermelho em falsas cores'; AF: 'Valskleur-infrarooi'),
    (EN: 'Night vision'; PL: 'Noktowizor'; CS: 'Noční vidění';
     FR: 'Vision nocturne'; DE: 'Nachtsicht'; IT: 'Visione notturna';
     ES: 'Visión nocturna'; PT: 'Visão noturna'; AF: 'Nagvisie'),
    (EN: 'Orton'; PL: 'Orton'; CS: 'Orton';
     FR: 'Orton'; DE: 'Orton'; IT: 'Orton';
     ES: 'Orton'; PT: 'Orton'; AF: 'Orton'),
    (EN: 'Black & white...'; PL: 'Czarno-biały...'; CS: 'Černobíle...';
     FR: 'Noir et blanc…'; DE: 'Schwarz & Weiß...'; IT: 'Bianco e nero...';
     ES: 'Blanco y negro...'; PT: 'Preto e branco...'; AF: 'Swart en wit...'),
    (EN: 'Grayscale'; PL: 'Szarość'; CS: 'Odstíny šedi';
     FR: 'Niveaux de gris'; DE: 'Graustufen'; IT: 'Scala di grigi';
     ES: 'Escala de grises'; PT: 'Escala de cinzentos'; AF: 'Grysskaal'),
    (EN: 'Negative'; PL: 'Negatyw'; CS: 'Negativ';
     FR: 'Négatif'; DE: 'Negativ'; IT: 'Negativo';
     ES: 'Negativo'; PT: 'Negativo'; AF: 'Negatief'),
    (EN: 'Film grain...'; PL: 'Ziarno filmowe...'; CS: 'Zrno filmu...';
     FR: 'Grain argentique…'; DE: 'Filmkorn...'; IT: 'Grana della pellicola...';
     ES: 'Grano de película...'; PT: 'Grão de película...'; AF: 'Filmkorrel...'),
    (EN: 'Oil paint...'; PL: 'Obraz olejny...'; CS: 'Olejomalba...';
     FR: 'Peinture à l’huile…'; DE: 'Ölgemälde...'; IT: 'Pittura a olio...';
     ES: 'Pintura al óleo...'; PT: 'Pintura a óleo...'; AF: 'Olieverf...'),
    (EN: 'Charcoal...'; PL: 'Węgiel...'; CS: 'Uhel...';
     FR: 'Fusain…'; DE: 'Kohlezeichnung...'; IT: 'Carboncino...';
     ES: 'Carboncillo...'; PT: 'Carvão...'; AF: 'Houtskool...'),
    (EN: 'Blur...'; PL: 'Rozmycie...'; CS: 'Rozmazání...';
     FR: 'Flou…'; DE: 'Weichzeichner...'; IT: 'Sfocatura...';
     ES: 'Desenfoque...'; PT: 'Desfocar...'; AF: 'Vervaag...'),
    (EN: 'Emboss...'; PL: 'Wytłaczanie...'; CS: 'Reliéf...';
     FR: 'Estampage…'; DE: 'Prägen...'; IT: 'Rilievo...';
     ES: 'Relieve...'; PT: 'Relevo...'; AF: 'Reliëf...'),
    (EN: 'Pixelate...'; PL: 'Pikselizacja...'; CS: 'Pixelace...';
     FR: 'Pixeliser…'; DE: 'Pixelieren...'; IT: 'Pixelizza...';
     ES: 'Pixelar...'; PT: 'Pixelizar...'; AF: 'Pikseleer...'),
    (EN: 'Vignette...'; PL: 'Winietowanie...'; CS: 'Vinětace...';
     FR: 'Vignette…'; DE: 'Vignette...'; IT: 'Vignettatura...';
     ES: 'Vineta...'; PT: 'Vinheta...'; AF: 'Vignet...'),
    (EN: 'Posterize...'; PL: 'Posteryzacja...'; CS: 'Posterizace...';
     FR: 'Postériser…'; DE: 'Posterisieren...'; IT: 'Posterizza...';
     ES: 'Posterizar...'; PT: 'Posterizar...'; AF: 'Posteriseer...'),
    (EN: 'Edge detection...'; PL: 'Detekcja krawędzi...'; CS: 'Detekce hran...';
     FR: 'Détection des contours…'; DE: 'Kantenerkennung...'; IT: 'Rilevamento bordi...';
     ES: 'Detección de bordes...'; PT: 'Deteção de contornos...'; AF: 'Randopsporing...'),
    (EN: 'Linocut...'; PL: 'Linoryt...'; CS: 'Linoryt...';
     FR: 'Linogravure…'; DE: 'Linolschnitt...'; IT: 'Linoleografia...';
     ES: 'Linograbado...'; PT: 'Linogravura...'; AF: 'Linosnee...'),
    (EN: 'Engraving...'; PL: 'Grawerowanie...'; CS: 'Rytina...';
     FR: 'Gravure…'; DE: 'Gravur...'; IT: 'Incisione...';
     ES: 'Grabado...'; PT: 'Gravura...'; AF: 'Gravering...'),
    (EN: 'Crosshatch...'; PL: 'Krzyżowanie...'; CS: 'Křížové šrafování...';
     FR: 'Hachures…'; DE: 'Schraffur...'; IT: 'Tratteggio incrociato...';
     ES: 'Tramado cruzado...'; PT: 'Hachura cruzada...'; AF: 'Kruisarsering...'),
    (EN: 'Halftone...'; PL: 'Raster...'; CS: 'Půltón...';
     FR: 'Tramage…'; DE: 'Raster...'; IT: 'Mezzitoni...';
     ES: 'Semitonos...'; PT: 'Meios-tons...'; AF: 'Halftoon...'),
    (EN: 'Stipple...'; PL: 'Kropkowanie...'; CS: 'Tečkování...';
     FR: 'Pointillisme…'; DE: 'Punktierung...'; IT: 'Puntinatura...';
     ES: 'Punteado...'; PT: 'Pontilhado...'; AF: 'Stippeling...'),
    (EN: 'Dice...'; PL: 'Kostkowanie...'; CS: 'Kostky...';
     FR: 'Dés…'; DE: 'Würfel...'; IT: 'Dadi...';
     ES: 'Dados...'; PT: 'Dados...'; AF: 'Dobbelstene...'),
    (EN: 'Risograph v1...'; PL: 'Risografia v1...'; CS: 'Risograf v1...';
     FR: 'Risographie v1…'; DE: 'Risografie v1...'; IT: 'Risografia v1...';
     ES: 'Risografía v1...'; PT: 'Risografia v1...'; AF: 'Risografie v1...'),
    (EN: 'Screen print...'; PL: 'Sitodruk...'; CS: 'Sítotisk...';
     FR: 'Sérigraphie…'; DE: 'Siebdruck...'; IT: 'Serigrafia...';
     ES: 'Serigrafía...'; PT: 'Serigrafia...'; AF: 'Sifdruk...'),
    (EN: 'Barrel distortion...'; PL: 'Dystorsja beczkowa...'; CS: 'Soudkové zkreslení...';
     FR: 'Distorsion en barillet…'; DE: 'Tonnenverzerrung...'; IT: 'Distorsione a barilotto...';
     ES: 'Distorsión de barril...'; PT: 'Distorção de barril...'; AF: 'Vatvervorming...'),
    (EN: 'Arc distortion...'; PL: 'Dystorsja łukowa...'; CS: 'Obloukové zkreslení...';
     FR: 'Distorsion en arc…'; DE: 'Bogenverzerrung...'; IT: 'Distorsione ad arco...';
     ES: 'Distorsión de arco...'; PT: 'Distorção em arco...'; AF: 'Boogvervorming...'),
    (EN: 'Swirl...'; PL: 'Wir...'; CS: 'Víření...';
     FR: 'Tourbillon…'; DE: 'Wirbel...'; IT: 'Vortice...';
     ES: 'Remolino...'; PT: 'Redemoinho...'; AF: 'Draaikolk...'),
    (EN: 'Water ripple...'; PL: 'Fale wodne...'; CS: 'Vodní vlnění...';
     FR: 'Ondulation…'; DE: 'Wasserwelle...'; IT: 'Increspatura dell''acqua...';
     ES: 'Ondulación del agua...'; PT: 'Ondulação da água...'; AF: 'Waterrimpeling...'),
    (EN: 'Polar distortion...'; PL: 'Zniekształcenie biegunowe...'; CS: 'Polární zkreslení...';
     FR: 'Distorsion polaire…'; DE: 'Polarverzerrung...'; IT: 'Distorsione polare...';
     ES: 'Distorsión polar...'; PT: 'Distorção polar...'; AF: 'Polêre vervorming...'),
    (EN: 'Workbench 1.x palette (OCS)'; PL: 'Paleta Workbench 1.x (OCS)'; CS: 'Paleta Workbench 1.x (OCS)';
     FR: 'Palette Workbench 1.x (OCS)'; DE: 'Workbench 1.x Palette (OCS)'; IT: 'Tavolozza Workbench 1.x (OCS)';
     ES: 'Paleta Workbench 1.x (OCS)'; PT: 'Paleta Workbench 1.x (OCS)'; AF: 'Workbench 1.x-palet (OCS)'),
    (EN: 'Workbench 2.x/3.x palette'; PL: 'Paleta Workbench 2.x/3.x'; CS: 'Paleta Workbench 2.x/3.x';
     FR: 'Palette Workbench 2.x/3.x'; DE: 'Workbench 2.x/3.x Palette'; IT: 'Tavolozza Workbench 2.x/3.x';
     ES: 'Paleta Workbench 2.x/3.x'; PT: 'Paleta Workbench 2.x/3.x'; AF: 'Workbench 2.x/3.x-palet'),
    (EN: 'OCS 32-color palette...'; PL: 'Paleta OCS 32 kolory...'; CS: 'OCS 32barevná paleta...';
     FR: 'Palette OCS 32 couleurs…'; DE: 'OCS 32-Farben-Palette...'; IT: 'Tavolozza OCS a 32 colori...';
     ES: 'Paleta OCS de 32 colores...'; PT: 'Paleta OCS de 32 cores...'; AF: 'OCS 32-kleurpalet...'),
    (EN: 'EHB 64-color palette...'; PL: 'Paleta EHB 64 kolory...'; CS: 'EHB 64barevná paleta...';
     FR: 'Palette EHB 64 couleurs…'; DE: 'EHB 64-Farben-Palette...'; IT: 'Tavolozza EHB a 64 colori...';
     ES: 'Paleta EHB de 64 colores...'; PT: 'Paleta EHB de 64 cores...'; AF: 'EHB 64-kleurpalet...'),
    (EN: 'AGA 256-color palette...'; PL: 'Paleta AGA 256 kolorów...'; CS: 'AGA 256barevná paleta...';
     FR: 'Palette AGA 256 couleurs…'; DE: 'AGA 256-Farben-Palette...'; IT: 'Tavolozza AGA a 256 colori...';
     ES: 'Paleta AGA de 256 colores...'; PT: 'Paleta AGA de 256 cores...'; AF: 'AGA 256-kleurpalet...'),
    (EN: 'Workbench 256-color palette...'; PL: 'Paleta Workbench 256 kolorów...'; CS: 'Workbench 256barevná paleta...';
     FR: 'Palette Workbench 256 couleurs…'; DE: 'Workbench 256-Farben-Palette...'; IT: 'Tavolozza Workbench a 256 colori...';
     ES: 'Paleta Workbench de 256 colores...'; PT: 'Paleta Workbench de 256 cores...'; AF: 'Workbench 256-kleurpalet...'),
    (EN: 'MagicWB palette (8 colors)...'; PL: 'Paleta MagicWB (8 kolorów)...'; CS: 'MagicWB paleta (8 barev)...';
     FR: 'Palette MagicWB (8 couleurs)…'; DE: 'MagicWB-Palette (8 Farben)...'; IT: 'Tavolozza MagicWB (8 colori)...';
     ES: 'Paleta MagicWB (8 colores)...'; PT: 'Paleta MagicWB (8 cores)...'; AF: 'MagicWB-palet (8 kleure)...'),
    (EN: 'About'; PL: 'O programie'; CS: 'O programu';
     FR: 'À propos'; DE: 'Über'; IT: 'Informazioni';
     ES: 'Acerca de'; PT: 'Acerca de'; AF: 'Aangaande'),
    (EN: 'Open an image file'; PL: 'Otwórz plik obrazu'; CS: 'Otevřít soubor s obrázkem';
     FR: 'Ouvrir un fichier image'; DE: 'Bilddatei öffnen'; IT: 'Apri un file immagine';
     ES: 'Abrir un archivo de imagen'; PT: 'Abrir um ficheiro de imagem'; AF: 'Maak ''n beeldlêer oop'),
    (EN: 'Save image under a new name'; PL: 'Zapisz obraz pod nową nazwą'; CS: 'Uložit obrázek pod novým názvem';
     FR: 'Enregistrer l’image sous un nouveau nom'; DE: 'Bild unter neuem Namen speichern'; IT: 'Salva l''immagine con un nuovo nome';
     ES: 'Guardar la imagen con un nombre nuevo'; PT: 'Guardar a imagem com um novo nome'; AF: 'Stoor die beeld onder ''n nuwe naam'),
    (EN: 'Show image details'; PL: 'Pokaż szczegóły obrazu'; CS: 'Zobrazit podrobnosti obrázku';
     FR: 'Afficher les informations sur l’image'; DE: 'Bilddetails anzeigen'; IT: 'Mostra informazioni sull''immagine';
     ES: 'Mostrar información de la imagen'; PT: 'Mostrar informações da imagem'; AF: 'Wys beeldinligting'),
    (EN: 'Close current image'; PL: 'Zamknij bieżący obraz'; CS: 'Zavřít aktuální obrázek';
     FR: 'Fermer l’image actuelle'; DE: 'Aktuelles Bild schließen'; IT: 'Chiudi l''immagine corrente';
     ES: 'Cerrar la imagen actual'; PT: 'Fechar a imagem atual'; AF: 'Sluit die huidige beeld'),
    (EN: 'Program settings'; PL: 'Ustawienia programu'; CS: 'Nastavení programu';
     FR: 'Paramètres du programme'; DE: 'Programmeinstellungen'; IT: 'Impostazioni del programma';
     ES: 'Configuración del programa'; PT: 'Definições do programa'; AF: 'Programinstellings'),
    (EN: 'Quit the program'; PL: 'Wyjście z programu'; CS: 'Ukončit program';
     FR: 'Quitter le programme'; DE: 'Programm beenden'; IT: 'Esci dal programma';
     ES: 'Salir del programa'; PT: 'Sair do programa'; AF: 'Verlaat die program'),
    (EN: 'Undo last operation'; PL: 'Cofnij ostatnia operację'; CS: 'Zpět poslední operaci';
     FR: 'Annuler la dernière opération'; DE: 'Letzten Schritt rückgängig machen'; IT: 'Annulla l''ultima operazione';
     ES: 'Deshacer la última operación'; PT: 'Anular a última operação'; AF: 'Ontdoen die laaste bewerking'),
    (EN: 'Redo undone operation'; PL: 'Ponów cofniętą operację'; CS: 'Znovu vrácenou operaci';
     FR: 'Rétablir la dernière opération annulée'; DE: 'Rückgängig gemachten Schritt wiederholen'; IT: 'Ripristina l''operazione annullata';
     ES: 'Rehacer la última operación deshecha'; PT: 'Refazer a última operação anulada'; AF: 'Herdoen die ontdane bewerking'),
    (EN: 'Copy image to clipboard'; PL: 'Kopiuj obraz do schowka'; CS: 'Kopírovat obrázek do schránky';
     FR: 'Copier l’image dans le presse-papiers'; DE: 'Bild in Zwischenablage kopieren'; IT: 'Copia l''immagine negli appunti';
     ES: 'Copiar la imagen al portapapeles'; PT: 'Copiar a imagem para a área de transferência'; AF: 'Kopieer die beeld na die knipbord'),
    (EN: 'Paste image from clipboard as new layer'; PL: 'Wklej obraz ze schowka jako nową warstwę'; CS: 'Vložit obrázek ze schránky jako novou vrstvu';
     FR: 'Coller l’image du presse-papiers comme nouveau calque'; DE: 'Bild aus Zwischenablage als neue Ebene einfügen'; IT: 'Incolla l''immagine dagli appunti come nuovo livello';
     ES: 'Pegar la imagen del portapapeles como una nueva capa'; PT: 'Colar a imagem da área de transferência como nova camada'; AF: 'Plak die beeld vanaf die knipbord as ''n nuwe laag'),
    (EN: 'Restore image to original state'; PL: 'Przywróć obraz do stanu pierwotnego'; CS: 'Obnovit původní stav obrázku';
     FR: 'Restaurer l’image à son état d’origine'; DE: 'Bild in Originalzustand zurückversetzen'; IT: 'Ripristina l''immagine allo stato originale';
     ES: 'Restaurar la imagen a su estado original'; PT: 'Repor a imagem ao estado original'; AF: 'Herstel die beeld na sy oorspronklike toestand'),
    (EN: 'Clear operation history - irreversible'; PL: 'Usuń historię operacji — nieodwracalne'; CS: 'Vymazat historii operací - nevratné';
     FR: 'Effacer l’historique des opérations - irréversible'; DE: 'Operationsverlauf löschen - nicht umkehrbar'; IT: 'Cancella la cronologia delle operazioni - irreversibile';
     ES: 'Borrar el historial de operaciones - irreversible'; PT: 'Limpar o histórico de operações - irreversível'; AF: 'Vee die bewerkingsgeskiedenis uit - onomkeerbaar'),
    (EN: 'Blend two effects with a slider'; PL: 'Połącz dwa efekty za pomocą suwaka'; CS: 'Míchání dvou efektů posuvníkem';
     FR: 'Mélanger deux effets à l’aide d’un curseur'; DE: 'Zwei Effekte mit Schieberegler mischen'; IT: 'Fondi due effetti con un cursore';
     ES: 'Mezclar dos efectos mediante un control deslizante'; PT: 'Misturar dois efeitos com um controlo deslizante'; AF: 'Meng twee effekte met ''n skuifbalk'),
    (EN: 'Čeština (Czech)'; PL: 'Čeština (czeski)'; CS: 'Čeština';
     FR: 'Čeština (Tchèque)'; DE: 'Čeština (Tschechisch)'; IT: 'Čeština (Ceco)';
     ES: 'Čeština (Checo)'; PT: 'Čeština (Tcheco)'; AF: 'Čeština (Tsjeggies)'),
    (EN: 'Português (Portuguese)'; PL: 'Português (portugalski)'; CS: 'Português (Portugalština)';
     FR: 'Português (Portugais)'; DE: 'Português (Portugiesisch)'; IT: 'Português (Portoghese)';
     ES: 'Português (Portugués)'; PT: 'Português'; AF: 'Português (Portugees)'),
    (EN: 'Afrikaans'; PL: 'Afrikaans (afrykanerski)'; CS: 'Afrikaans';
     FR: 'Afrikaans'; DE: 'Afrikaans'; IT: 'Afrikaans';
     ES: 'Afrikaans (Afrikáans)'; PT: 'Afrikaans'; AF: 'Afrikaans'),
    (EN: 'Zoom in view'; PL: 'Powiększ widok'; CS: 'Přiblížit zobrazení';
     FR: 'Agrandir l’affichage'; DE: 'Bild vergrößern'; IT: 'Ingrandisci la visualizzazione';
     ES: 'Acercar la vista'; PT: 'Ampliar a visualização'; AF: 'Zoem in op die beeld'),
    (EN: 'Zoom out view'; PL: 'Pomniejsz widok'; CS: 'Oddálit zobrazení';
     FR: 'Réduire l’affichage'; DE: 'Bild verkleinern'; IT: 'Riduci la visualizzazione';
     ES: 'Alejar la vista'; PT: 'Reduzir a visualização'; AF: 'Zoem uit op die beeld'),
    (EN: 'Fit image to window'; PL: 'Dopasuj obraz do okna'; CS: 'Přizpůsobit obrázek oknu';
     FR: 'Adapter l’image à la fenêtre'; DE: 'Bild an Fenster anpassen'; IT: 'Adatta l''immagine alla finestra';
     ES: 'Ajustar la imagen a la ventana'; PT: 'Ajustar a imagem à janela'; AF: 'Pas die beeld by die venster'),
    (EN: 'View at 1:1 scale'; PL: 'Podgląd w skali 1:1'; CS: 'Zobrazit v měřítku 1:1';
     FR: 'Afficher l’image à l’échelle 1:1'; DE: 'Bild im Maßstab 1:1 anzeigen'; IT: 'Visualizza in scala 1:1';
     ES: 'Ver a escala 1:1'; PT: 'Visualizar à escala 1:1'; AF: 'Wys teen 1:1-skaal'),
    (EN: 'View at 50% scale'; PL: 'Podgląd w skali 50%'; CS: 'Zobrazit v měřítku 50%';
     FR: 'Afficher l’image à l’échelle 50 %'; DE: 'Bild im Maßstab 50% anzeigen'; IT: 'Visualizza al 50%';
     ES: 'Ver al 50%'; PT: 'Visualizar a 50%'; AF: 'Wys teen 50%-skaal'),
    (EN: 'View at 25% scale'; PL: 'Podgląd w skali 25%'; CS: 'Zobrazit v měřítku 25%';
     FR: 'Afficher l’image à l’échelle 25 %'; DE: 'Bild im Maßstab 25% anzeigen'; IT: 'Visualizza al 25%';
     ES: 'Ver al 25%'; PT: 'Visualizar a 25%'; AF: 'Wys teen 25%-skaal'),
    (EN: 'View at 200% scale'; PL: 'Podgląd w skali 200%'; CS: 'Zobrazit v měřítku 200%';
     FR: 'Afficher l’image à l’échelle 200 %'; DE: 'Bild im Maßstab 200% anzeigen'; IT: 'Visualizza al 200%';
     ES: 'Ver al 200%'; PT: 'Visualizar a 200%'; AF: 'Wys teen 200%-skaal'),
    (EN: 'View at 400% scale'; PL: 'Podgląd w skali 400%'; CS: 'Zobrazit v měřítku 400%';
     FR: 'Afficher l’image à l’échelle 400 %'; DE: 'Bild im Maßstab 400% anzeigen'; IT: 'Visualizza al 400%';
     ES: 'Ver al 400%'; PT: 'Visualizar a 400%'; AF: 'Wys teen 400%-skaal'),
    (EN: 'Show color histogram'; PL: 'Pokaż historię'; CS: 'Zobrazit barevný histogram';
     FR: 'Afficher l’histogramme des couleurs'; DE: 'Farbhistogramm anzeigen'; IT: 'Mostra l''istogramma dei colori';
     ES: 'Mostrar el histograma de colores'; PT: 'Mostrar o histograma de cores'; AF: 'Wys kleurhistogram'),
    (EN: 'Equalize histogram - improve contrast'; PL: 'Wyrównaj histogram — popraw kontrast'; CS: 'Vyrovnat histogram - zlepšit kontrast';
     FR: 'Égaliser l’histogramme - améliorer le contraste'; DE: 'Histogramm ausgleichen - Kontrast verbessern'; IT: 'Equalizza l''istogramma - migliora il contrasto';
     ES: 'Ecualizar el histograma - mejorar el contraste'; PT: 'Equalizar o histograma - melhorar o contraste'; AF: 'Egaliseer histogram - verbeter kontras'),
    (EN: 'Flip image horizontally'; PL: 'Odbij obraz w poziomie'; CS: 'Převrátit obrázek vodorovně';
     FR: 'Retourner l’image horizontalement'; DE: 'Bild horizontal spiegeln'; IT: 'Rifletti l''immagine orizzontalmente';
     ES: 'Voltear la imagen horizontalmente'; PT: 'Espelhar a imagem horizontalmente'; AF: 'Spieël die beeld horisontaal'),
    (EN: 'Flip image vertically'; PL: 'Odbij obraz w pionie'; CS: 'Převrátit obrázek svisle';
     FR: 'Retourner l’image verticalement'; DE: 'Bild vertikal spiegeln'; IT: 'Rifletti l''immagine verticalmente';
     ES: 'Voltear la imagen verticalmente'; PT: 'Espelhar a imagem verticalmente'; AF: 'Spieël die beeld vertikaal'),
    (EN: 'Rotate image 90 degrees left'; PL: 'Obróć obraz o 90° w lewo'; CS: 'Otočit obrázek o 90° doleva';
     FR: 'Pivoter l’image de 90° vers la gauche'; DE: 'Bild 90° nach links drehen'; IT: 'Ruota l''immagine di 90° a sinistra';
     ES: 'Girar la imagen 90 grados a la izquierda'; PT: 'Rodar a imagem 90 graus para a esquerda'; AF: 'Draai die beeld 90 grade links'),
    (EN: 'Rotate image 90 degrees right'; PL: 'Obróć obraz o 90° w prawo'; CS: 'Otočit obrázek o 90° doprava';
     FR: 'Pivoter l’image de 90° vers la droite'; DE: 'Bild 90° nach rechts drehen'; IT: 'Ruota l''immagine di 90° a destra';
     ES: 'Girar la imagen 90 grados a la derecha'; PT: 'Rodar a imagem 90 graus para a direita'; AF: 'Draai die beeld 90 grade regs'),
    (EN: 'Rotate image 180 degrees'; PL: 'Obróć obraz o 180°'; CS: 'Otočit obrázek o 180°';
     FR: 'Pivoter l’image de 180°'; DE: 'Bild 180° drehen'; IT: 'Ruota l''immagine di 180°';
     ES: 'Girar la imagen 180 grados'; PT: 'Rodar a imagem 180 graus'; AF: 'Draai die beeld 180 grade'),
    (EN: 'Straighten scan - rotate up to +/- 10 degrees with auto-crop'; PL: 'Prostuj skan — obrót o +/- 10 stopni z automatycznym przycinaniem'; CS: 'Narovnat sken - otočení až +/-10° s auto-oříznutím';
     FR: 'Redresser le scan - rotation jusqu’à +/- 10° avec recadrage automatique'; DE: 'Scan begradigen - bis +/- 10 Grad mit automatischem Zuschnitt'; IT: 'Raddrizza la scansione - ruota fino a +/- 10° con ritaglio automatico';
     ES: 'Enderezar escaneo: girar hasta +/- 10 grados con recorte automático'; PT: 'Endireitar digitalização - rodar até +/- 10 graus com recorte automático'; AF: 'Maak skandering reguit - draai tot +/- 10 grade met outomatiese uitsny'),
    (EN: 'Adjust contrast'; PL: 'Dostosuj kontrast'; CS: 'Upravit kontrast';
     FR: 'Régler le contraste'; DE: 'Kontrast einstellen'; IT: 'Regola il contrasto';
     ES: 'Ajustar el contraste'; PT: 'Ajustar o contraste'; AF: 'Pas kontras aan'),
    (EN: 'Adjust brightness'; PL: 'Dostosuj jasność'; CS: 'Upravit jas';
     FR: 'Régler la luminosité'; DE: 'Helligkeit einstellen'; IT: 'Regola la luminosità';
     ES: 'Ajustar el brillo'; PT: 'Ajustar a luminosidade'; AF: 'Pas helderheid aan'),
    (EN: 'Gamma correction'; PL: 'Korekcja gamma'; CS: 'Korekce gama';
     FR: 'Correction gamma'; DE: 'Gamma-Korrektur'; IT: 'Correzione gamma';
     ES: 'Corrección gamma'; PT: 'Correção de gama'; AF: 'Gamma-korreksie'),
    (EN: 'Set black point, gamma and white point - full tonal control'; PL: 'Ustaw czarny punkt, gamma, biały punkt — pełna kontrola tonalna'; CS: 'Nastavit černý bod, gama a bílý bod - plná tonální kontrola';
     FR: 'Définir le point noir, le gamma et le point blanc - contrôle tonal complet'; DE: 'Schwarzpunkt, Gamma und Weißpunkt einstellen - volle Tonwertkontrolle'; IT: 'Imposta punto di nero, gamma e punto di bianco - controllo tonale completo';
     ES: 'Ajustar punto negro, gamma y punto blanco: control tonal completo'; PT: 'Definir ponto de preto, gama e ponto de branco - controlo tonal completo'; AF: 'Stel swartpunt, gamma en witpunt in - volledige toonbeheer'),
    (EN: 'White balance - color temperature correction'; PL: 'Balans bieli — korekcja temperatury barwowej'; CS: 'Vyvážení bílé - korekce barevné teploty';
     FR: 'Balance des blancs - correction de la température de couleur'; DE: 'Weißabgleich - Farbtemperatur korrigieren'; IT: 'Bilanciamento del bianco - correzione della temperatura colore';
     ES: 'Balance de blancos: corrección de la temperatura de color'; PT: 'Balanço de brancos - correção da temperatura da cor'; AF: 'Witbalans - kleurtemperatuurkorreksie'),
    (EN: 'Sharpen image'; PL: 'Wyostrz obraz'; CS: 'Doostřit obrázek';
     FR: 'Accentuer la netteté de l’image'; DE: 'Bild schärfen'; IT: 'Aumenta la nitidezza dell''immagine';
     ES: 'Enfocar la imagen'; PT: 'Aumentar a nitidez da imagem'; AF: 'Verskerp die beeld'),
    (EN: 'Vivid - saturated, vibrant colours'; PL: 'Soczystość — nasycone, żywe kolory'; CS: 'Živé barvy - syté, zářivé barvy';
     FR: 'Éclat - couleurs saturées et vives'; DE: 'Brillant - gesättigte, lebendige Farben'; IT: 'Vividezza - colori saturi e brillanti';
     ES: 'Intensificar: colores vivos y saturados'; PT: 'Vividez - cores vivas e saturadas'; AF: 'Lewendigheid - versadigde, lewendige kleure'),
    (EN: 'Photo enhancement (Multiply)'; PL: 'Wzmocnienie zdjęcia (Multiply)'; CS: 'Vylepšení fotografie (Násobení)';
     FR: 'Amélioration photo (Multiplier)'; DE: 'Fotoverstärkung (Multiplizieren)'; IT: 'Miglioramento fotografico (Moltiplica)';
     ES: 'Mejora fotográfica (Multiplicar)'; PT: 'Melhoria fotográfica (Multiplicar)'; AF: 'Fotoverbetering (Vermenigvuldig)'),
    (EN: 'Crop image'; PL: 'Przytnij obraz'; CS: 'Oříznout obrázek';
     FR: 'Recadrer l’image'; DE: 'Bild zuschneiden'; IT: 'Ritaglia l''immagine';
     ES: 'Recortar la imagen'; PT: 'Recortar a imagem'; AF: 'Sny die beeld uit'),
    (EN: 'Resize image'; PL: 'Zmień rozmiar obrazu'; CS: 'Změnit velikost obrázku';
     FR: 'Redimensionner l’image'; DE: 'Bildgröße ändern'; IT: 'Ridimensiona l''immagine';
     ES: 'Redimensionar la imagen'; PT: 'Redimensionar a imagem'; AF: 'Verander die grootte van die beeld'),
    (EN: 'Tint image with selected color'; PL: 'Pokoloruj obraz wybranym kolorem'; CS: 'Obarvit obrázek vybranou barvou';
     FR: 'Teinter l’image avec la couleur sélectionnée'; DE: 'Bild mit ausgewählter Farbe einfärben'; IT: 'Colorizza l''immagine con il colore selezionato';
     ES: 'Tenir la imagen con el color seleccionado'; PT: 'Colorir a imagem com a cor selecionada'; AF: 'Kleur die beeld met die gekose kleur in'),
    (EN: 'Adjust brightness, saturation and hue'; PL: 'Dostosuj jasność, nasycenie i odcień'; CS: 'Upravit jas, sytost a odstín';
     FR: 'Régler la luminosité, la saturation et la teinte'; DE: 'Helligkeit, Sättigung und Farbton einstellen'; IT: 'Regola luminosità, saturazione e tonalità';
     ES: 'Ajustar brillo, saturación y tono'; PT: 'Ajustar luminosidade, saturação e tonalidade'; AF: 'Pas helderheid, versadiging en tint aan'),
    (EN: 'Solarize - invert bright tones'; PL: 'Solaryzacja — odwrócenie jasnych tonów światła'; CS: 'Solarizace - invertovat světlé tóny';
     FR: 'Solariser - inverser les tons clairs'; DE: 'Solarisieren - helle Töne invertieren'; IT: 'Solarizza - inverti i toni chiari';
     ES: 'Solarizar: invertir los tonos claros'; PT: 'Solarizar - inverter os tons claros'; AF: 'Solariseer - keer ligte kleure om'),
    (EN: 'Two-color effect - shadows and highlights'; PL: 'Dwukolorowy efekt — cienie i światła'; CS: 'Dvoubarevný efekt - stíny a světla';
     FR: 'Effet bicolore - ombres et hautes lumières'; DE: 'Zweifarbeneffekt - Schatten und Lichter'; IT: 'Effetto a due colori - ombre e luci';
     ES: 'Efecto de dos colores: sombras y luces'; PT: 'Efeito de duas cores - sombras e realces'; AF: 'Tweekleur-effek - skaduwees en hoogtepunte'),
    (EN: 'Sepia - warm brown monochrome'; PL: 'Sepia — ciepły brązowy monochromat'; CS: 'Sépie - teplá hnědá monochromie';
     FR: 'Sépia - monochrome brun chaud'; DE: 'Sepia - warmes Braun-Monochrom'; IT: 'Seppia - monocromatico marrone caldo';
     ES: 'Sepia: monocromo marrón cálido'; PT: 'Sépia - monocromático castanho quente'; AF: 'Sepia - warm bruin monochroom'),
    (EN: 'Cyanotype - blue monochrome'; PL: 'Cyjanotypia — niebieski monochromat'; CS: 'Kyanotypie - modrá monochromie';
     FR: 'Cyanotypie - monochrome bleu'; DE: 'Cyanotypie - blaues Monochrom'; IT: 'Cianotipia - monocromatico blu';
     ES: 'Cianotipia: monocromo azul'; PT: 'Cianotipia - monocromático azul'; AF: 'Sianotipe - blou monochroom'),
    (EN: 'Salt print - warm brown'; PL: 'Fotografia solna — ciepły brąz'; CS: 'Sůl-tisk - teplá hnědá';
     FR: 'Tirage au sel - brun chaud'; DE: 'Salzdruck - warmes Braun'; IT: 'Stampa ai sali - marrone caldo';
     ES: 'Impresión a la sal: marrón cálido'; PT: 'Impressão a sal - castanho quente'; AF: 'Soutdruk - warm bruin'),
    (EN: 'X-Ray - inverted colors'; PL: 'Rentgen — odwrócone kolory'; CS: 'Rentgen - invertované barvy';
     FR: 'Rayons X - couleurs inversées'; DE: 'Röntgen - invertierte Farben'; IT: 'Raggi X - colori invertiti';
     ES: 'Rayos X: colores invertidos'; PT: 'Raios X - cores invertidas'; AF: 'X-strale - omgekeerde kleure'),
    (EN: 'False-color IR - channel swap, red plants, blue sky'; PL: 'Fałszywe kolory IR — zamiana kanałów, czerwone rośliny, błękitne niebo'; CS: 'Falešné barvy IR - prohození kanálů, červené rostliny, modrá obloha';
     FR: 'Infrarouge en fausses couleurs - permutation des canaux, végétation rouge, ciel bleu'; DE: 'Falschfarben-IR - Kanaltausch, rote Pflanzen, blauer Himmel'; IT: 'Infrarosso a falsi colori - scambio dei canali, vegetazione rossa, cielo blu';
     ES: 'Infrarrojo en falso color: intercambio de canales, vegetación roja, cielo azul'; PT: 'Infravermelho em falsas cores - troca de canais, vegetação vermelha, céu azul'; AF: 'Valskleur-infrarooi - kanaalomruiling, rooi plante, blou lug'),
    (EN: 'Night vision - grayscale + green phosphor'; PL: 'Nocne widzenie — szarość i zielony fosfor'; CS: 'Noční vidění - šedá + zelený fosfor';
     FR: 'Vision nocturne - niveaux de gris + phosphore vert'; DE: 'Nachtsicht - Graustufen + grünes Phosphor'; IT: 'Visione notturna - scala di grigi + fosforo verde';
     ES: 'Visión nocturna: escala de grises + fósforo verde'; PT: 'Visão noturna - escala de cinzentos + fósforo verde'; AF: 'Nagvisie - grysskaal + groen fosfor'),
    (EN: 'Thermal - false-color view'; PL: 'Termiczny — podgląd we fałszywych kolorach'; CS: 'Termální - falešné barvy';
     FR: 'Thermique - affichage en fausses couleurs'; DE: 'Thermal - Falschfarben-Ansicht'; IT: 'Termico - visualizzazione a falsi colori';
     ES: 'Térmico: visualización en falso color'; PT: 'Térmico - visualização em falsas cores'; AF: 'Termies - valskleur-aansig'),
    (EN: 'Orton - blurred glow, dreamy mood'; PL: 'Efekt Ortona — rozmyta poświata, bajkowy nastrój'; CS: 'Orton - rozmazaná záře, snová nálada';
     FR: 'Orton - halo flou, atmosphère onirique'; DE: 'Orton - weicher Leuchteffekt, verträumte Stimmung'; IT: 'Orton - bagliore sfocato, atmosfera sognante';
     ES: 'Orton: resplandor difuso, ambiente onírico'; PT: 'Orton - brilho difuso, atmosfera onírica'; AF: 'Orton - sagte gloed, droomagtige atmosfeer'),
    (EN: 'Convert to B&W with dither option'; PL: 'Konawersja do czarno-białego z opcją roztrząsania'; CS: 'Převést na ČB s možností ditheringu';
     FR: 'Convertir en noir et blanc avec option de tramage'; DE: 'In Schwarz & Weiß umwandeln mit Dither-Option'; IT: 'Converti in bianco e nero con opzione di retinatura';
     ES: 'Convertir a blanco y negro con opción de tramado'; PT: 'Converter para preto e branco com opção de meios-tons'; AF: 'Skakel na swart en wit om met halftoon-opsie'),
    (EN: 'Convert to grayscale'; PL: 'Konswersja doskali szarości'; CS: 'Převést na odstíny šedi';
     FR: 'Convertir en niveaux de gris'; DE: 'In Graustufen umwandeln'; IT: 'Converti in scala di grigi';
     ES: 'Convertir a escala de grises'; PT: 'Converter para escala de cinzentos'; AF: 'Skakel na grysskaal om'),
    (EN: 'Invert colors - negative'; PL: 'Odwrócone kolory — negatyw'; CS: 'Invertovat barvy - negativ';
     FR: 'Inverser les couleurs - négatif'; DE: 'Farben invertieren - Negativ'; IT: 'Inverti i colori - negativo';
     ES: 'Invertir colores - negativo'; PT: 'Inverter cores - negativo'; AF: 'Keer kleure om - negatief'),
    (EN: 'Add film grain - random noise'; PL: 'Dodaj ziarno filmowe — szum losowy'; CS: 'Přidat zrno filmu - náhodný šum';
     FR: 'Ajouter un grain argentique - bruit aléatoire'; DE: 'Filmkorn hinzufügen - zufälliges Rauschen'; IT: 'Aggiungi grana della pellicola - rumore casuale';
     ES: 'Añadir grano de película - ruido aleatorio'; PT: 'Adicionar grão de película - ruído aleatório'; AF: 'Voeg filmkorrel by - ewekansige geraas'),
    (EN: 'Oil paint - brush simulation'; PL: 'Efekt olejny — symulacja pędzla'; CS: 'Olejomalba - simulace štětce';
     FR: 'Peinture à l’huile - simulation de pinceau'; DE: 'Ölgemälde - Pinselsimulation'; IT: 'Pittura a olio - simulazione del pennello';
     ES: 'Pintura al óleo - simulación de pincel'; PT: 'Pintura a óleo - simulação de pincel'; AF: 'Olieverf - kwassimulasie'),
    (EN: 'Charcoal - charcoal drawing simulation'; PL: 'Węgiel — symulacja rysunku węglowego'; CS: 'Uhel - simulace kresby uhlem';
     FR: 'Fusain - simulation de dessin au fusain'; DE: 'Kohlezeichnung - Simulation von Kohlezeichnung'; IT: 'Carboncino - simulazione di disegno a carboncino';
     ES: 'Carboncillo - simulación de dibujo al carboncillo'; PT: 'Carvão - simulação de desenho a carvão'; AF: 'Houtskool - houtskooltekensimulasie'),
    (EN: 'Blur image'; PL: 'Rozmycie obrazu'; CS: 'Rozmazat obrázek';
     FR: 'Flouter l’image'; DE: 'Bild weichzeichnen'; IT: 'Sfoca l''immagine';
     ES: 'Desenfocar la imagen'; PT: 'Desfocar a imagem'; AF: 'Vervaag die beeld'),
    (EN: 'Emboss - relief'; PL: 'Efekt wypukłości — relief'; CS: 'Reliéf';
     FR: 'Estampage - relief'; DE: 'Prägen - Relief'; IT: 'Rilievo';
     ES: 'Relieve'; PT: 'Relevo'; AF: 'Reliëf'),
    (EN: 'Pixelate - mosaic effect'; PL: 'Pikselizacja — efekt mozaiki'; CS: 'Pixelace - mozaikový efekt';
     FR: 'Pixeliser - effet mosaïque'; DE: 'Pixelieren - Mosaikeffekt'; IT: 'Pixelizza - effetto mosaico';
     ES: 'Pixelar - efecto mosaico'; PT: 'Pixelizar - efeito de mosaico'; AF: 'Pikseleer - mosaïekeffek'),
    (EN: 'Vignette - darken edges'; PL: 'Winietowanie — przyciemnianie krawędzi'; CS: 'Vinětace - ztmavení okrajů';
     FR: 'Vignette - assombrir les bords'; DE: 'Vignette - Ränder abdunkeln'; IT: 'Vignettatura - scurisci i bordi';
     ES: 'Vineta - oscurecer los bordes'; PT: 'Vinheta - escurecer as margens'; AF: 'Vignet - verdonker die rande'),
    (EN: 'Posterize - reduce color count'; PL: 'Posteryzacja — redukcja liczby kolorów'; CS: 'Posterizace - snížit počet barev';
     FR: 'Postériser - réduire le nombre de couleurs'; DE: 'Posterisieren - Farbanzahl reduzieren'; IT: 'Posterizza - riduci il numero di colori';
     ES: 'Posterizar - reducir el número de colores'; PT: 'Posterizar - reduzir o número de cores'; AF: 'Posteriseer - verminder die aantal kleure'),
    (EN: 'Edge detection - sketch effect'; PL: 'Detekcja krawędzi — efekt szkicu'; CS: 'Detekce hran - efekt skici';
     FR: 'Détection des contours - effet esquisse'; DE: 'Kantenerkennung - Skizzen-Effekt'; IT: 'Rilevamento bordi - effetto schizzo';
     ES: 'Detección de bordes - efecto de boceto'; PT: 'Deteção de contornos - efeito de esboço'; AF: 'Randopsporing - sketseffek'),
    (EN: 'Linocut - sharp B&W contrast'; PL: 'Linoryt — ostry, czarno-biały kontrast'; CS: 'Linoryt - ostrý ČB kontrast';
     FR: 'Linogravure - fort contraste noir et blanc'; DE: 'Linolschnitt - scharfer S/W-Kontrast'; IT: 'Linoleografia - forte contrasto in bianco e nero';
     ES: 'Linograbado - fuerte contraste en blanco y negro'; PT: 'Linogravura - forte contraste a preto e branco'; AF: 'Linosnee - sterk swart-en-wit-kontras'),
    (EN: 'Engraving - line engraving simulation'; PL: 'Grawerowanie — symulacja linii rytowniczych'; CS: 'Rytina - simulace rytiny';
     FR: 'Gravure - simulation de gravure'; DE: 'Gravur - Linienstich-Simulation'; IT: 'Incisione - simulazione di incisione a linee';
     ES: 'Grabado - simulación de grabado lineal'; PT: 'Gravura - simulação de gravura em linhas'; AF: 'Gravering - simulasie van lyngravering'),
    (EN: 'Crosshatch lines at two angles'; PL: 'Krzyżowanie linii pod dwoma kątami'; CS: 'Křížové šrafování pod dvěma úhly';
     FR: 'Hachures - hachures croisées à deux angles'; DE: 'Schraffur - Kreuzschraffur in zwei Winkeln'; IT: 'Tratteggio incrociato a due angolazioni';
     ES: 'Tramado cruzado en dos ángulos'; PT: 'Hachura cruzada em dois ângulos'; AF: 'Kruisarsering teen twee hoeke'),
    (EN: 'Halftone - growing dots based on brightness'; PL: 'Raster — rosnące kropki zależnie od jasności'; CS: 'Půltón - rostoucí body podle jasu';
     FR: 'Tramage - points de taille variable selon la luminosité'; DE: 'Raster - wachsende Punkte basierend auf Helligkeit'; IT: 'Mezzitoni - punti di dimensione variabile in base alla luminosità';
     ES: 'Semitonos - puntos de tamaño variable según el brillo'; PT: 'Meios-tons - pontos de tamanho variável conforme a luminosidade'; AF: 'Halftoon - groeiende kolletjies volgens helderheid'),
    (EN: 'Stipple - dot density based on brightness'; PL: 'Kropkowanie — gęstość kropek zależnie od jasności'; CS: 'Tečkování - hustota bodů podle jasu';
     FR: 'Pointillisme - densité des points selon la luminosité'; DE: 'Punktierung - Punktedichte basierend auf Helligkeit'; IT: 'Puntinatura - densità dei punti in base alla luminosità';
     ES: 'Punteado - densidad de puntos según el brillo'; PT: 'Pontilhado - densidade de pontos conforme a luminosidade'; AF: 'Stippeling - puntdigtheid volgens helderheid'),
    (EN: 'Dice - dice eyes pattern'; PL: 'Kostkowanie — oczka kostki do gry'; CS: 'Kostky - vzor ok kostek';
     FR: 'Dés - motif en points de dés'; DE: 'Würfel - Würfelaugen-Muster'; IT: 'Dadi - motivo con punti da dado';
     ES: 'Dados - patrón de puntos de dados'; PT: 'Dados - padrão de pontos de dado'; AF: 'Dobbelstene - dobbelsteenpatroon'),
    (EN: 'Risograph - layered print with color offset'; PL: 'Rizograf — druk warstwowy z offsetem kolorów'; CS: 'Risograf - vrstvený tisk s posunem barev';
     FR: 'Risographie - impression en couches avec décalage des couleurs'; DE: 'Risografie - Schichtdruck mit Farbversatz'; IT: 'Risografia - stampa a livelli con sfalsamento dei colori';
     ES: 'Risografía - impresión por capas con desplazamiento de color'; PT: 'Risografia - impressão em camadas com desvio de cores'; AF: 'Risografie - gelaagde drukwerk met kleurverskuiwing'),
    (EN: 'Single-color screen print - grayscale + halftone on background'; PL: 'Sitodruk jednokolorowy — szary + tło  półtonowe'; CS: 'Jednobarevný sítotisk - šedá + půltón na pozadí';
     FR: 'Sérigraphie monochrome - niveaux de gris + tramage sur fond'; DE: 'Einfarbiger Siebdruck - Graustufen + Raster auf Hintergrund'; IT: 'Serigrafia monocromatica - scala di grigi + mezzitoni sullo sfondo';
     ES: 'Serigrafía monocromática - escala de grises + semitonos sobre el fondo'; PT: 'Serigrafia monocromática - escala de cinzentos + meios-tons sobre o fundo'; AF: 'Enkelkleur-sifdruk - grysskaal + halftoon op agtergrond'),
    (EN: 'Barrel / pincushion distortion'; PL: 'Zniekształcenie beczkowate / poduszkowe'; CS: 'Soudkové / poduškové zkreslení';
     FR: 'Distorsion en barillet / en coussinet'; DE: 'Tonnen- / Kissenverzerrung'; IT: 'Distorsione a barilotto / cuscinetto';
     ES: 'Distorsión de barril / cojín'; PT: 'Distorção de barril / almofada'; AF: 'Vat- / kussingvervorming'),
    (EN: 'Arc distortion - bend image'; PL: 'Zniekształcenie łukowe — zginanie obrazu'; CS: 'Obloukové zkreslení - prohnout obrázek';
     FR: 'Distorsion en arc - courber l’image'; DE: 'Bogenverzerrung - Bild biegen'; IT: 'Distorsione ad arco - incurva l''immagine';
     ES: 'Distorsión de arco - curvar la imagen'; PT: 'Distorção em arco - curvar a imagem'; AF: 'Boogvervorming - buig die beeld'),
    (EN: 'Swirl - twist image'; PL: 'Wiruj — przekręć obraz'; CS: 'Víření - zkroutit obrázek';
     FR: 'Tourbillon - déformer l’image en spirale'; DE: 'Wirbel - Bild verwirbeln'; IT: 'Vortice - ruota l''immagine a spirale';
     ES: 'Remolino - retorcer la imagen'; PT: 'Redemoinho - torcer a imagem'; AF: 'Draaikolk - draai die beeld'),
    (EN: 'Water ripple effect'; PL: 'Fale wodne'; CS: 'Vodní vlnění';
     FR: 'Effet d’ondulation'; DE: 'Wasserwellen-Effekt'; IT: 'Effetto increspatura dell''acqua';
     ES: 'Efecto de ondulación del agua'; PT: 'Efeito de ondulação da água'; AF: 'Waterrimpel-effek'),
    (EN: 'Polar distortion - tunnel, fisheye'; PL: 'Zniekształcenia biegunowe — tunel, rybie oko'; CS: 'Polární zkreslení - tunel, rybí oko';
     FR: 'Distorsion polaire - tunnel, œil-de-poisson'; DE: 'Polarverzerrung - Tunnel, Fischauge'; IT: 'Distorsione polare - tunnel, occhio di pesce';
     ES: 'Distorsión polar - túnel, ojo de pez'; PT: 'Distorção polar - túnel, olho de peixe'; AF: 'Polêre vervorming - tonnel, visoog'),
    (EN: '4-color palette - Workbench 1.x (OCS)'; PL: 'Paleta 4 kolorów — Workbench 1.x (OCS)'; CS: '4barevná paleta - Workbench 1.x (OCS)';
     FR: 'Palette 4 couleurs - Workbench 1.x (OCS)'; DE: '4-Farben-Palette - Workbench 1.x (OCS)'; IT: 'Tavolozza a 4 colori - Workbench 1.x (OCS)';
     ES: 'Paleta de 4 colores - Workbench 1.x (OCS)'; PT: 'Paleta de 4 cores - Workbench 1.x (OCS)'; AF: '4-kleurpalet - Workbench 1.x (OCS)'),
    (EN: '4-color palette - Workbench 2.x/3.x'; PL: 'Paleta 4 kolorów — Workbench 2.x/3.x'; CS: '4barevná paleta - Workbench 2.x/3.x';
     FR: 'Palette 4 couleurs - Workbench 2.x/3.x'; DE: '4-Farben-Palette - Workbench 2.x/3.x'; IT: 'Tavolozza a 4 colori - Workbench 2.x/3.x';
     ES: 'Paleta de 4 colores - Workbench 2.x/3.x'; PT: 'Paleta de 4 cores - Workbench 2.x/3.x'; AF: '4-kleurpalet - Workbench 2.x/3.x'),
    (EN: '32-color palette (4x4x2) - OCS'; PL: 'Paleta 32 kolorów (4x4x2) — OCS'; CS: '32barevná paleta (4x4x2) - OCS';
     FR: 'Palette 32 couleurs (4×4×2) - OCS'; DE: '32-Farben-Palette (4x4x2) - OCS'; IT: 'Tavolozza a 32 colori (4x4x2) - OCS';
     ES: 'Paleta de 32 colores (4x4x2) - OCS'; PT: 'Paleta de 32 cores (4x4x2) - OCS'; AF: '32-kleurpalet (4x4x2) - OCS'),
    (EN: '64-color palette (4x4x4) - EHB'; PL: 'Paleta 64 kolorów (4x4x4) — EHB'; CS: '64barevná paleta (4x4x4) - EHB';
     FR: 'Palette 64 couleurs (4×4×4) - EHB'; DE: '64-Farben-Palette (4x4x4) - EHB'; IT: 'Tavolozza a 64 colori (4x4x4) - EHB';
     ES: 'Paleta de 64 colores (4x4x4) - EHB'; PT: 'Paleta de 64 cores (4x4x4) - EHB'; AF: '64-kleurpalet (4x4x4) - EHB'),
    (EN: '256-color palette - AGA'; PL: 'Paleta 256 kolorów — AGA'; CS: '256barevná paleta - AGA';
     FR: 'Palette 256 couleurs - AGA'; DE: '256-Farben-Palette - AGA'; IT: 'Tavolozza a 256 colori - AGA';
     ES: 'Paleta de 256 colores - AGA'; PT: 'Paleta de 256 cores - AGA'; AF: '256-kleurpalet - AGA'),
    (EN: '256-color palette - Workbench 3.x'; PL: 'Paleta 256 kolorów — Workbench 3.x'; CS: '256barevná paleta - Workbench 3.x';
     FR: 'Palette 256 couleurs - Workbench 3.x'; DE: '256-Farben-Palette - Workbench 3.x'; IT: 'Tavolozza a 256 colori - Workbench 3.x';
     ES: 'Paleta de 256 colores - Workbench 3.x'; PT: 'Paleta de 256 cores - Workbench 3.x'; AF: '256-kleurpalet - Workbench 3.x'),
    (EN: '8-color palette - MagicWB (MUI)'; PL: 'Paleta 8 kolorów — MagicWB (MUI)'; CS: '8barevná paleta - MagicWB (MUI)';
     FR: 'Palette 8 couleurs - MagicWB (MUI)'; DE: '8-Farben-Palette - MagicWB (MUI)'; IT: 'Tavolozza a 8 colori - MagicWB (MUI)';
     ES: 'Paleta de 8 colores - MagicWB (MUI)'; PT: 'Paleta de 8 cores - MagicWB (MUI)'; AF: '8-kleurpalet - MagicWB (MUI)'),
    (EN: 'Fotografista'; PL: 'Fotografista'; CS: 'Fotografista';
     FR: 'Fotografista'; DE: 'Fotografista'; IT: 'Fotografista';
     ES: 'Fotografista'; PT: 'Fotografista'; AF: 'Fotografista'),
    (EN: 'No image'; PL: 'Brak obrazu'; CS: 'Žádný obrázek';
     FR: 'Aucune image'; DE: 'Kein Bild'; IT: 'Nessuna immagine';
     ES: 'Sin imagen'; PT: 'Sem imagem'; AF: 'Geen beeld'),
    (EN: 'OK'; PL: 'OK'; CS: 'OK';
     FR: 'OK'; DE: 'OK'; IT: 'OK';
     ES: 'Aceptar'; PT: 'OK'; AF: 'OK'),
    (EN: 'Cancel'; PL: 'Anuluj'; CS: 'Zrušit';
     FR: 'Annuler'; DE: 'Abbrechen'; IT: 'Annulla';
     ES: 'Cancelar'; PT: 'Cancelar'; AF: 'Kanselleer'),
    (EN: 'Preview'; PL: 'Podgląd'; CS: 'Náhled';
     FR: 'Aperçu'; DE: 'Vorschau'; IT: 'Anteprima';
     ES: 'Vista previa'; PT: 'Pré-visualização'; AF: 'Voorskou'),
    (EN: 'Show preview'; PL: 'Pokaż podgląd'; CS: 'Zobrazit náhled';
     FR: 'Afficher l’aperçu'; DE: 'Vorschau anzeigen'; IT: 'Mostra anteprima';
     ES: 'Mostrar vista previa'; PT: 'Mostrar pré-visualização'; AF: 'Wys voorskou'),
    (EN: 'Apply and close'; PL: 'Zastosuj i zamknij'; CS: 'Použít a zavřít';
     FR: 'Appliquer et fermer'; DE: 'Übernehmen und schließen'; IT: 'Applica e chiudi';
     ES: 'Aplicar y cerrar'; PT: 'Aplicar e fechar'; AF: 'Pas toe en sluit'),
    (EN: 'Close without applying'; PL: 'Zamknij bez stosowania'; CS: 'Zavřít bez použití';
     FR: 'Fermer sans appliquer'; DE: 'Ohne Übernehmen schließen'; IT: 'Chiudi senza applicare';
     ES: 'Cerrar sin aplicar'; PT: 'Fechar sem aplicar'; AF: 'Sluit sonder om toe te pas'),
    (EN: 'Photo editor'; PL: 'Edytor zdjęć'; CS: 'Fotografický editor';
     FR: 'Éditeur de photos'; DE: 'Bildbearbeitung'; IT: 'Editor fotografico';
     ES: 'Editor de fotografías'; PT: 'Editor de fotografias'; AF: 'Fotoredigeerder'),
    (EN: 'Build'; PL: 'Kompilacja'; CS: 'Build';
     FR: 'Build'; DE: 'Build'; IT: 'Build';
     ES: 'Compilación'; PT: 'Compilação'; AF: 'Bou'),
    (EN: 'Width (px):'; PL: 'Szerokość (px):'; CS: 'Šířka (px):';
     FR: 'Largeur (px) :'; DE: 'Breite (px):'; IT: 'Larghezza (px):';
     ES: 'Ancho (px):'; PT: 'Largura (px):'; AF: 'Breedte (px):'),
    (EN: 'Height (px):'; PL: 'Wysokość (px):'; CS: 'Výška (px):';
     FR: 'Hauteur (px) :'; DE: 'Höhe (px):'; IT: 'Altezza (px):';
     ES: 'Alto (px):'; PT: 'Altura (px):'; AF: 'Hoogte (px):'),
    (EN: 'Apply resize'; PL: 'Zastosuj zmianę rozmiaru'; CS: 'Použít změnu velikosti';
     FR: 'Appliquer le redimensionnement'; DE: 'Größenänderung übernehmen'; IT: 'Applica ridimensionamento';
     ES: 'Aplicar redimensionado'; PT: 'Aplicar redimensionamento'; AF: 'Pas grootte aan'),
    (EN: 'Cancel changes'; PL: 'Anuluj zmiany'; CS: 'Zrušit změny';
     FR: 'Annuler les modifications'; DE: 'Änderungen verwerfen'; IT: 'Annulla modifiche';
     ES: 'Cancelar cambios'; PT: 'Cancelar alterações'; AF: 'Kanselleer veranderinge'),
    (EN: 'X (px):'; PL: 'X (px):'; CS: 'X (px):';
     FR: 'X (px) :'; DE: 'X (px):'; IT: 'X (px):';
     ES: 'X (px):'; PT: 'X (px):'; AF: 'X (px):'),
    (EN: 'Y (px):'; PL: 'Y (px):'; CS: 'Y (px):';
     FR: 'Y (px) :'; DE: 'Y (px):'; IT: 'Y (px):';
     ES: 'Y (px):'; PT: 'Y (px):'; AF: 'Y (px):'),
    (EN: 'Apply crop'; PL: 'Zastosuj przycięcie'; CS: 'Použít oříznutí';
     FR: 'Appliquer le recadrage'; DE: 'Zuschnitt übernehmen'; IT: 'Applica ritaglio';
     ES: 'Aplicar recorte'; PT: 'Aplicar recorte'; AF: 'Pas knip toe'),
    (EN: 'Cancel crop'; PL: 'Anuluj przycięcie'; CS: 'Zrušit oříznutí';
     FR: 'Annuler le recadrage'; DE: 'Zuschnitt abbrechen'; IT: 'Annulla ritaglio';
     ES: 'Cancelar recorte'; PT: 'Cancelar recorte'; AF: 'Kanselleer knip'),
    (EN: 'Select color'; PL: 'Wybierz kolor'; CS: 'Vybrat barvu';
     FR: 'Choisir une couleur'; DE: 'Farbe wählen'; IT: 'Seleziona colore';
     ES: 'Seleccionar color'; PT: 'Selecionar cor'; AF: 'Kies kleur'),
    (EN: 'Text color'; PL: 'Kolor tekstu'; CS: 'Barva textu';
     FR: 'Couleur du texte'; DE: 'Textfarbe'; IT: 'Colore del testo';
     ES: 'Color del texto'; PT: 'Cor do texto'; AF: 'Tekskleur'),
    (EN: 'Font...'; PL: 'Wybierz czcionkę...'; CS: 'Písmo...';
     FR: 'Police…'; DE: 'Schriftart...'; IT: 'Carattere...';
     ES: 'Fuente...'; PT: 'Tipo de letra...'; AF: 'Lettertipe...'),
    (EN: 'Direction'; PL: 'Kierunek'; CS: 'Směr';
     FR: 'Direction'; DE: 'Richtung'; IT: 'Direzione';
     ES: 'Dirección'; PT: 'Direção'; AF: 'Rigting'),
    (EN: 'Increase'; PL: 'Zwiększ'; CS: 'Zvýšit';
     FR: 'Augmenter'; DE: 'Erhöhen'; IT: 'Aumenta';
     ES: 'Aumentar'; PT: 'Aumentar'; AF: 'Vergroot'),
    (EN: 'Decrease'; PL: 'Zmniejsz'; CS: 'Snížit';
     FR: 'Diminuer'; DE: 'Verringern'; IT: 'Diminuisci';
     ES: 'Disminuir'; PT: 'Diminuir'; AF: 'Verklein'),
    (EN: 'Dithering'; PL: 'Roztrząsanie'; CS: 'Dithering';
     FR: 'Tramage'; DE: 'Dithering'; IT: 'Retinatura';
     ES: 'Difuminado'; PT: 'Reticulação'; AF: 'Dither'),
    (EN: 'With dither (better quality)'; PL: 'Z roztrząsaniem (lepsza jakość)'; CS: 'S ditheringem (lepší kvalita)';
     FR: 'Avec tramage (meilleure qualité)'; DE: 'Mit Dither (bessere Qualität)'; IT: 'Con retinatura (qualità migliore)';
     ES: 'Con difuminado (mejor calidad)'; PT: 'Com reticulação (melhor qualidade)'; AF: 'Met dither (beste gehalte)'),
    (EN: 'With dither'; PL: 'Z roztrząsaniem'; CS: 'S ditheringem';
     FR: 'Avec tramage'; DE: 'Mit Dither'; IT: 'Con retinatura';
     ES: 'Con difuminado'; PT: 'Com reticulação'; AF: 'Met dither'),
    (EN: 'Without dither'; PL: 'Bez roztrząsania'; CS: 'Bez ditheringu';
     FR: 'Sans tramage'; DE: 'Ohne Dither'; IT: 'Senza retinatura';
     ES: 'Sin difuminado'; PT: 'Sem reticulação'; AF: 'Sonder dither'),
    (EN: 'Enabled'; PL: 'Włączone'; CS: 'Povoleno';
     FR: 'Activé'; DE: 'Aktiviert'; IT: 'Abilitato';
     ES: 'Activado'; PT: 'Ativado'; AF: 'Aangeskakel'),
    (EN: 'Disabled'; PL: 'Wyłączone'; CS: 'Zakázáno';
     FR: 'Désactivé'; DE: 'Deaktiviert'; IT: 'Disabilitato';
     ES: 'Desactivado'; PT: 'Desativado'; AF: 'Afgeskakel'),
    (EN: 'Intensity (1-10):'; PL: 'Intensywność (1–10):'; CS: 'Intenzita (1-10):';
     FR: 'Intensité (1-10) :'; DE: 'Intensität (1-10):'; IT: 'Intensità (1-10):';
     ES: 'Intensidad (1-10):'; PT: 'Intensidade (1-10):'; AF: 'Intensiteit (1-10):'),
    (EN: 'Brightness (0-200, default 100):'; PL: 'Jasność (0–200, domyślnie 100):'; CS: 'Jas (0-200, výchozí 100):';
     FR: 'Luminosité (0-200, valeur par défaut 100) :'; DE: 'Helligkeit (0-200, Standard 100):'; IT: 'Luminosità (0-200, predefinito 100):';
     ES: 'Brillo (0-200, predeterminado 100):'; PT: 'Luminosidade (0-200, predefinido 100):'; AF: 'Helderheid (0-200, standaard 100):'),
    (EN: 'Gamma (100 = no change):'; PL: 'Gamma (100 = brak zmian):'; CS: 'Gama (100 = beze změny):';
     FR: 'Gamma (100 = aucun changement) :'; DE: 'Gamma (100 = keine Änderung):'; IT: 'Gamma (100 = nessuna modifica):';
     ES: 'Gamma (100 = sin cambios):'; PT: 'Gama (100 = sem alteração):'; AF: 'Gamma (100 = geen verandering):'),
    (EN: 'Red (100 = no change):'; PL: 'Czerwony (100 = brak zmian):'; CS: 'Červená (100 = beze změny):';
     FR: 'Rouge (100 = aucun changement) :'; DE: 'Rot (100 = keine Änderung):'; IT: 'Rosso (100 = nessuna modifica):';
     ES: 'Rojo (100 = sin cambios):'; PT: 'Vermelho (100 = sem alteração):'; AF: 'Rooi (100 = geen verandering):'),
    (EN: 'Green (100 = no change):'; PL: 'Zielony (100 = brak zmian):'; CS: 'Zelená (100 = beze změny):';
     FR: 'Vert (100 = aucun changement) :'; DE: 'Grün (100 = keine Änderung):'; IT: 'Verde (100 = nessuna modifica):';
     ES: 'Verde (100 = sin cambios):'; PT: 'Verde (100 = sem alteração):'; AF: 'Groen (100 = geen verandering):'),
    (EN: 'Blue (100 = no change):'; PL: 'Niebieski (100 = brak zmian):'; CS: 'Modrá (100 = beze změny):';
     FR: 'Bleu (100 = aucun changement) :'; DE: 'Blau (100 = keine Änderung):'; IT: 'Blu (100 = nessuna modifica):';
     ES: 'Azul (100 = sin cambios):'; PT: 'Azul (100 = sem alteração):'; AF: 'Blou (100 = geen verandering):'),
    (EN: 'Intensity (1-100):'; PL: 'Intensywność (1–100):'; CS: 'Intenzita (1-100):';
     FR: 'Intensité (1-100) :'; DE: 'Intensität (1-100):'; IT: 'Intensità (1-100):';
     ES: 'Intensidad (1-100):'; PT: 'Intensidade (1-100):'; AF: 'Intensiteit (1-100):'),
    (EN: 'Intensity (0-100):'; PL: 'Intensywność (0–100):'; CS: 'Intenzita (0-100):';
     FR: 'Intensité (0-100) :'; DE: 'Intensität (0-100):'; IT: 'Intensità (0-100):';
     ES: 'Intensidad (0-100):'; PT: 'Intensidade (0-100):'; AF: 'Intensiteit (0-100):'),
    (EN: 'Radius (1-5):'; PL: 'Promień (1–5)'; CS: 'Poloměr (1-5):';
     FR: 'Rayon (1-5) :'; DE: 'Radius (1-5):'; IT: 'Raggio (1-5):';
     ES: 'Radio (1-5):'; PT: 'Raio (1-5):'; AF: 'Radius (1-5):'),
    (EN: 'Intensity (1-50):'; PL: 'Intensywność (1–50):'; CS: 'Intenzita (1-50):';
     FR: 'Intensité (1-50) :'; DE: 'Intensität (1-50):'; IT: 'Intensità (1-50):';
     ES: 'Intensidad (1-50):'; PT: 'Intensidade (1-50):'; AF: 'Intensiteit (1-50):'),
    (EN: 'Cell size (1-100):'; PL: 'Rozmiar komórki (1–100):'; CS: 'Velikost buňky (1-100):';
     FR: 'Taille de cellule (1-100) :'; DE: 'Zellgröße (1-100):'; IT: 'Dimensione cella (1-100):';
     ES: 'Tamaño de celda (1-100):'; PT: 'Tamanho da célula (1-100):'; AF: 'Selgrootte (1-100):'),
    (EN: 'Angle (0-179°):'; PL: 'Kąt linii (0–179°):'; CS: 'Úhel (0-179°):';
     FR: 'Angle (0-179°) :'; DE: 'Winkel (0-179°):'; IT: 'Angolo (0-179°):';
     ES: 'Ángulo (0-179°):'; PT: 'Ângulo (0-179°):'; AF: 'Hoek (0-179°):'),
    (EN: 'Cell size (4-16 px):'; PL: 'Rozmiar komórki (4–16 px):'; CS: 'Velikost buňky (4-16 px):';
     FR: 'Taille de cellule (4-16 px) :'; DE: 'Zellgröße (4-16 px):'; IT: 'Dimensione cella (4-16 px):';
     ES: 'Tamaño de celda (4-16 px):'; PT: 'Tamanho da célula (4-16 px):'; AF: 'Selgrootte (4-16 px):'),
    (EN: 'Max line thickness (1-8):'; PL: 'Maksymalna grubość linii (1–8):'; CS: 'Max. tloušťka čáry (1-8):';
     FR: 'Épaisseur maximale de ligne (1-8) :'; DE: 'Max. Linienstärke (1-8):'; IT: 'Spessore massimo della linea (1-8):';
     ES: 'Grosor máximo de línea (1-8):'; PT: 'Espessura máxima da linha (1-8):'; AF: 'Maksimum lyndikte (1-8):'),
    (EN: 'Cell size (4-64 px):'; PL: 'Rozmiar komórki (4–64 px):'; CS: 'Velikost buňky (4-64 px):';
     FR: 'Taille de cellule (4-64 px) :'; DE: 'Zellgröße (4-64 px):'; IT: 'Dimensione cella (4-64 px):';
     ES: 'Tamaño de celda (4-64 px):'; PT: 'Tamanho da célula (4-64 px):'; AF: 'Selgrootte (4-64 px):'),
    (EN: 'Subcell dot size (3-8 px):'; PL: 'Rozmiar podkomórki kropki (3–8 px):'; CS: 'Velikost bodu v buňce (3-8 px):';
     FR: 'Taille des sous-points (3-8 px) :'; DE: 'Punktgröße (3-8 px):'; IT: 'Dimensione del punto della sottocella (3-8 px):';
     ES: 'Tamaño de punto de subcelda (3-8 px):'; PT: 'Tamanho do ponto da subcélula (3-8 px):'; AF: 'Subsel-puntgrootte (3-8 px):'),
    (EN: 'Threshold (1-100):'; PL: 'Prog (1–100):'; CS: 'Práh (1-100):';
     FR: 'Seuil (1-100) :'; DE: 'Schwellwert (1-100):'; IT: 'Soglia (1-100):';
     ES: 'Umbral (1-100):'; PT: 'Limiar (1-100):'; AF: 'Drempel (1-100):'),
    (EN: 'Ink amount (lighter = less):'; PL: 'Ilość tuszu (jaśniejsze = mniej):'; CS: 'Množství inkoustu (světlejší = méně):';
     FR: 'Quantité d’encre (plus clair = moins) :'; DE: 'Tintenmenge (heller = weniger):'; IT: 'Quantità di inchiostro (più chiaro = meno):';
     ES: 'Cantidad de tinta (más claro = menos):'; PT: 'Quantidade de tinta (mais claro = menos):'; AF: 'Inkhoeveelheid (ligter = minder):'),
    (EN: 'Strength (0-100):'; PL: 'Siła efektu (0–100):'; CS: 'Síla (0-100):';
     FR: 'Force (0-100) :'; DE: 'Stärke (0-100):'; IT: 'Intensità (0-100):';
     ES: 'Intensidad (0-100):'; PT: 'Intensidade (0-100):'; AF: 'Intensiteit (0-100):'),
    (EN: 'Saturation (0-100):'; PL: 'Nasycenie (0–100):'; CS: 'Sytost (0-100):';
     FR: 'Saturation (0-100) :'; DE: 'Sättigung (0-100):'; IT: 'Saturazione (0-100):';
     ES: 'Saturación (0-100):'; PT: 'Saturação (0-100):'; AF: 'Versadiging (0-100):'),
    (EN: 'Contrast (0-100):'; PL: 'Kontrast (0–100):'; CS: 'Kontrast (0-100):';
     FR: 'Contraste (0-100) :'; DE: 'Kontrast (0-100):'; IT: 'Contrasto (0-100):';
     ES: 'Contraste (0-100):'; PT: 'Contraste (0-100):'; AF: 'Kontras (0-100):'),
    (EN: 'Curve (1-5):'; PL: 'Krzywa (1–5):'; CS: 'Křivka (1-5):';
     FR: 'Courbe (1-5) :'; DE: 'Kurve (1-5):'; IT: 'Curva (1-5):';
     ES: 'Curva (1-5):'; PT: 'Curva (1-5):'; AF: 'Kurwe (1-5):'),
    (EN: 'Smart Curves (0-100):'; PL: 'Sprytne krzywe (0–100):'; CS: 'Chytré křivky (0-100):';
     FR: 'Smart Curves (0-100) :'; DE: 'Smart Curves (0-100):'; IT: 'Curve intelligenti (0-100):';
     ES: 'Curvas inteligentes (0-100):'; PT: 'Curvas inteligentes (0-100):'; AF: 'Slim kurwes (0-100):'),
    (EN: 'Black point (0-255):'; PL: 'Czarny punkt (0–255):'; CS: 'Černý bod (0-255):';
     FR: 'Point noir (0-255) :'; DE: 'Schwarzpunkt (0-255):'; IT: 'Punto di nero (0-255):';
     ES: 'Punto negro (0-255):'; PT: 'Ponto de preto (0-255):'; AF: 'Swartpunt (0-255):'),
    (EN: 'White point (0-255):'; PL: 'Biały punkt (0–255):'; CS: 'Bílý bod (0-255):';
     FR: 'Point blanc (0-255) :'; DE: 'Weißpunkt (0-255):'; IT: 'Punto di bianco (0-255):';
     ES: 'Punto blanco (0-255):'; PT: 'Ponto de branco (0-255):'; AF: 'Witpunt (0-255):'),
    (EN: 'Straighten angle (-10 to +10°):'; PL: 'Kąt prostowania (-10 do +10 stopni):'; CS: 'Úhel narovnání (-10 až +10°):';
     FR: 'Angle de redressement (-10 à +10°) :'; DE: 'Begradigungswinkel (-10 bis +10°):'; IT: 'Angolo di raddrizzamento (-10 a +10°):';
     ES: 'Ángulo de enderezado (-10 a +10°):'; PT: 'Ângulo de endireitamento (-10 a +10°):'; AF: 'Reguitmaakhoek (-10 tot +10°):'),
    (EN: 'Apply straighten and close'; PL: 'Zastosuj prostowanie i zamknij'; CS: 'Použít narovnání a zavřít';
     FR: 'Appliquer le redressement et fermer'; DE: 'Begradigung übernehmen und schließen'; IT: 'Applica raddrizzamento e chiudi';
     ES: 'Aplicar enderezado y cerrar'; PT: 'Aplicar endireitamento e fechar'; AF: 'Pas reguitmaak toe en sluit'),
    (EN: 'Apply layer changes and close'; PL: 'Zastosuj zmiany warstw i zamknij'; CS: 'Použít změny vrstev a zavřít';
     FR: 'Appliquer les modifications du calque et fermer'; DE: 'Ebenen-Änderungen übernehmen und schließen'; IT: 'Applica modifiche del livello e chiudi';
     ES: 'Aplicar cambios de la capa y cerrar'; PT: 'Aplicar alterações da camada e fechar'; AF: 'Pas laagveranderinge toe en sluit'),
    (EN: 'Close without saving'; PL: 'Zamknij bez zapisywania'; CS: 'Zavřít bez uložení';
     FR: 'Fermer sans enregistrer'; DE: 'Ohne Speichern schließen'; IT: 'Chiudi senza salvare';
     ES: 'Cerrar sin guardar'; PT: 'Fechar sem guardar'; AF: 'Sluit sonder om te stoor'),
    (EN: 'Shadow color'; PL: 'Kolor cieni'; CS: 'Barva stínů';
     FR: 'Couleur de l’ombre'; DE: 'Schattenfarbe'; IT: 'Colore delle ombre';
     ES: 'Color de las sombras'; PT: 'Cor da sombra'; AF: 'Skadukleur'),
    (EN: 'Highlight color'; PL: 'Kolor świateł'; CS: 'Barva světel';
     FR: 'Couleur des hautes lumières'; DE: 'Lichtfarbe'; IT: 'Colore delle luci';
     ES: 'Color de las luces'; PT: 'Cor da luz'; AF: 'Hoogtepuntkleur'),
    (EN: 'Ink color'; PL: 'Kolor tuszu'; CS: 'Barva inkoustu';
     FR: 'Couleur de l’encre'; DE: 'Tintenfarbe'; IT: 'Colore dell''inchiostro';
     ES: 'Color de la tinta'; PT: 'Cor da tinta'; AF: 'Inkkleur'),
    (EN: 'Paper color'; PL: 'Kolor papieru'; CS: 'Barva papíru';
     FR: 'Couleur du papier'; DE: 'Papierfarbe'; IT: 'Colore della carta';
     ES: 'Color del papel'; PT: 'Cor do papel'; AF: 'Papierkleur'),
    (EN: 'Preset name:'; PL: 'Nazwa ustawienia:'; CS: 'Název předvolby:';
     FR: 'Nom du préréglage :'; DE: 'Voreinstellungsname:'; IT: 'Nome del predefinito:';
     ES: 'Nombre del preajuste:'; PT: 'Nome da predefinição:'; AF: 'Voorinstellingsnaam:'),
    (EN: 'Load'; PL: 'Wczytaj'; CS: 'Načíst';
     FR: 'Charger'; DE: 'Laden'; IT: 'Carica';
     ES: 'Cargar'; PT: 'Carregar'; AF: 'Laai'),
    (EN: 'Delete'; PL: 'Usuń'; CS: 'Smazat';
     FR: 'Supprimer'; DE: 'Löschen'; IT: 'Elimina';
     ES: 'Eliminar'; PT: 'Eliminar'; AF: 'Vee uit'),
    (EN: 'Setting'; PL: 'Ustawienie'; CS: 'Nastavení';
     FR: 'Réglage'; DE: 'Einstellung'; IT: 'Impostazione';
     ES: 'Ajuste'; PT: 'Definição'; AF: 'Instelling'),
    (EN: 'Brightness'; PL: 'Jasność'; CS: 'Jas';
     FR: 'Luminosité'; DE: 'Helligkeit'; IT: 'Luminosità';
     ES: 'Brillo'; PT: 'Luminosidade'; AF: 'Helderheid'),
    (EN: 'Sharpen'; PL: 'Wyostrzenie'; CS: 'Doostřit';
     FR: 'Netteté'; DE: 'Schärfen'; IT: 'Nitidezza';
     ES: 'Enfocar'; PT: 'Nitidez'; AF: 'Verskerp'),
    (EN: 'Solarize'; PL: 'Solaryzacja'; CS: 'Solarizace';
     FR: 'Solariser'; DE: 'Solarisieren'; IT: 'Solarizza';
     ES: 'Solarizar'; PT: 'Solarizar'; AF: 'Solariseer'),
    (EN: 'Sepia'; PL: 'Sepia'; CS: 'Sépie';
     FR: 'Sépia'; DE: 'Sepia'; IT: 'Seppia';
     ES: 'Sepia'; PT: 'Sépia'; AF: 'Sepia'),
    (EN: 'Oil paint'; PL: 'Obraz olejny'; CS: 'Olejomalba';
     FR: 'Peinture à l’huile'; DE: 'Ölgemälde'; IT: 'Pittura a olio';
     ES: 'Pintura al óleo'; PT: 'Pintura a óleo'; AF: 'Olieverf'),
    (EN: 'Charcoal'; PL: 'Węgiel'; CS: 'Uhel';
     FR: 'Fusain'; DE: 'Kohlezeichnung'; IT: 'Carboncino';
     ES: 'Carboncillo'; PT: 'Carvão'; AF: 'Houtskool'),
    (EN: 'Blur'; PL: 'Rozmycie'; CS: 'Rozmazání';
     FR: 'Flou'; DE: 'Weichzeichner'; IT: 'Sfocatura';
     ES: 'Desenfoque'; PT: 'Desfocar'; AF: 'Vervaag'),
    (EN: 'Pixelate'; PL: 'Pikselizacja'; CS: 'Pixelace';
     FR: 'Pixeliser'; DE: 'Pixelieren'; IT: 'Pixelizza';
     ES: 'Pixelar'; PT: 'Pixelizar'; AF: 'Pikseleer'),
    (EN: 'Vignette'; PL: 'Winietowanie'; CS: 'Vinětace';
     FR: 'Vignette'; DE: 'Vignette'; IT: 'Vignettatura';
     ES: 'Vineta'; PT: 'Vinheta'; AF: 'Vignet'),
    (EN: 'Edge detection'; PL: 'Detekcja krawędzi'; CS: 'Detekce hran';
     FR: 'Détection des contours'; DE: 'Kantenerkennung'; IT: 'Rilevamento bordi';
     ES: 'Detección de bordes'; PT: 'Deteção de contornos'; AF: 'Randopsporing'),
    (EN: 'Film grain'; PL: 'Ziarno filmowe'; CS: 'Zrno filmu';
     FR: 'Grain argentique'; DE: 'Filmkorn'; IT: 'Grana della pellicola';
     ES: 'Grano de película'; PT: 'Grão de película'; AF: 'Filmkorrel'),
    (EN: 'Save Duotone preset'; PL: 'Zapisz ustawienie'; CS: 'Uložit předvolbu duotónu';
     FR: 'Enregistrer le préréglage Duotone'; DE: 'Duoton-Voreinstellung speichern'; IT: 'Salva predefinito Duotono';
     ES: 'Guardar preajuste de Duotono'; PT: 'Guardar predefinição Duotom'; AF: 'Stoor duotoon-voorinstelling'),
    (EN: 'Load Duotone preset'; PL: 'Wczytaj ustawienie'; CS: 'Načíst předvolbu duotónu';
     FR: 'Charger le préréglage Duotone'; DE: 'Duoton-Voreinstellung laden'; IT: 'Carica predefinito Duotono';
     ES: 'Cargar preajuste de Duotono'; PT: 'Carregar predefinição Duotom'; AF: 'Laai duotoon-voorinstelling'),
    (EN: 'Contrast'; PL: 'Kontrast'; CS: 'Kontrast';
     FR: 'Contraste'; DE: 'Kontrast'; IT: 'Contrasto';
     ES: 'Contraste'; PT: 'Contraste'; AF: 'Kontras'),
    (EN: 'Crop'; PL: 'Kadrowanie'; CS: 'Oříznutí';
     FR: 'Recadrer'; DE: 'Zuschneiden'; IT: 'Ritaglia';
     ES: 'Recortar'; PT: 'Recortar'; AF: 'Knip'),
    (EN: 'Resize'; PL: 'Zmiana rozmiaru'; CS: 'Změna velikosti';
     FR: 'Redimensionner'; DE: 'Größe ändern'; IT: 'Ridimensiona';
     ES: 'Redimensionar'; PT: 'Redimensionar'; AF: 'Verander grootte'),
    (EN: 'White balance'; PL: 'Balans bieli'; CS: 'Vyvážení bílé';
     FR: 'Balance des blancs'; DE: 'Weißabgleich'; IT: 'Bilanciamento del bianco';
     ES: 'Balance de blancos'; PT: 'Balanço de brancos'; AF: 'Witbalans'),
    (EN: 'Levels'; PL: 'Poziomy'; CS: 'Úrovně';
     FR: 'Niveaux'; DE: 'Tonwertkorrektur'; IT: 'Livelli';
     ES: 'Niveles'; PT: 'Níveis'; AF: 'Vlakke'),
    (EN: 'Vivid'; PL: 'Soczystość'; CS: 'Živé barvy';
     FR: 'Éclat'; DE: 'Brillant'; IT: 'Vividezza';
     ES: 'Intensificar'; PT: 'Vividez'; AF: 'Lewendigheid'),
    (EN: 'Photo enhancement'; PL: 'Wzmocnienie zdjęcia'; CS: 'Vylepšení fotografie';
     FR: 'Amélioration photo'; DE: 'Fotoverstärkung'; IT: 'Miglioramento fotografico';
     ES: 'Mejora fotográfica'; PT: 'Melhoria fotográfica'; AF: 'Fotoverbetering'),
    (EN: 'Layers'; PL: 'Warstwy'; CS: 'Vrstvy';
     FR: 'Calques'; DE: 'Ebenen'; IT: 'Livelli';
     ES: 'Capas'; PT: 'Camadas'; AF: 'Lae'),
    (EN: 'Straighten scan'; PL: 'Prostowanie skanu'; CS: 'Narovnat sken';
     FR: 'Redresser le scan'; DE: 'Scan begradigen'; IT: 'Raddrizza scansione';
     ES: 'Enderezar escaneo'; PT: 'Endireitar digitalização'; AF: 'Reguit maak'),
    (EN: 'Colorize'; PL: 'Kolorowanie'; CS: 'Kolorovat';
     FR: 'Coloriser'; DE: 'Einfärben'; IT: 'Colorizza';
     ES: 'Colorear'; PT: 'Colorir'; AF: 'Kleur in'),
    (EN: 'HSB balance'; PL: 'Balans HSB'; CS: 'HSB vyvážení';
     FR: 'Équilibre HSB'; DE: 'HSB-Gleichgewicht'; IT: 'Bilanciamento HSB';
     ES: 'Balance HSB'; PT: 'Balanço HSB'; AF: 'HSB-balans'),
    (EN: 'Black & white'; PL: 'Czarno-biały'; CS: 'Černobíle';
     FR: 'Noir et blanc'; DE: 'Schwarz & Weiß'; IT: 'Bianco e nero';
     ES: 'Blanco y negro'; PT: 'Preto e branco'; AF: 'Swart en wit'),
    (EN: 'Posterize'; PL: 'Posteryzacja'; CS: 'Posterizace';
     FR: 'Postériser'; DE: 'Posterisieren'; IT: 'Posterizza';
     ES: 'Posterizar'; PT: 'Posterizar'; AF: 'Posteriseer'),
    (EN: 'Engraving'; PL: 'Grawerowanie'; CS: 'Rytina';
     FR: 'Gravure'; DE: 'Gravur'; IT: 'Incisione';
     ES: 'Grabado'; PT: 'Gravura'; AF: 'Gravering'),
    (EN: 'Crosshatch'; PL: 'Krzyżowanie'; CS: 'Křížové šrafování';
     FR: 'Hachures'; DE: 'Schraffur'; IT: 'Tratteggio incrociato';
     ES: 'Tramado cruzado'; PT: 'Hachura cruzada'; AF: 'Kruisarsering'),
    (EN: 'Halftone'; PL: 'Raster'; CS: 'Půltón';
     FR: 'Tramage'; DE: 'Raster'; IT: 'Mezzitoni';
     ES: 'Semitonos'; PT: 'Meios-tons'; AF: 'Halftoon'),
    (EN: 'Stipple'; PL: 'Kropkowanie'; CS: 'Tečkování';
     FR: 'Pointillisme'; DE: 'Punktierung'; IT: 'Puntinatura';
     ES: 'Punteado'; PT: 'Pontilhado'; AF: 'Stippeling'),
    (EN: 'Dice'; PL: 'Kostkowanie'; CS: 'Kostky';
     FR: 'Dés'; DE: 'Würfel'; IT: 'Dadi';
     ES: 'Dados'; PT: 'Dados'; AF: 'Dobbelstene'),
    (EN: 'Linocut'; PL: 'Linoryt'; CS: 'Linoryt';
     FR: 'Linogravure'; DE: 'Linolschnitt'; IT: 'Linoleografia';
     ES: 'Linograbado'; PT: 'Linogravura'; AF: 'Linosnee'),
    (EN: 'Risograph'; PL: 'Risografia'; CS: 'Risograf';
     FR: 'Risographie'; DE: 'Risografie'; IT: 'Risografia';
     ES: 'Risografía'; PT: 'Risografia'; AF: 'Risografie'),
    (EN: 'Screen print'; PL: 'Sitodruk'; CS: 'Sítotisk';
     FR: 'Sérigraphie'; DE: 'Siebdruck'; IT: 'Serigrafia';
     ES: 'Serigrafía'; PT: 'Serigrafia'; AF: 'Sifdruk'),
    (EN: 'OCS 32-color palette'; PL: 'Paleta OCS 32 kolory'; CS: 'OCS 32barevná paleta';
     FR: 'Palette OCS 32 couleurs'; DE: 'OCS 32-Farben-Palette'; IT: 'Tavolozza OCS a 32 colori';
     ES: 'Paleta OCS de 32 colores'; PT: 'Paleta OCS de 32 cores'; AF: 'OCS 32-kleurpalet'),
    (EN: 'EHB 64-color palette'; PL: 'Paleta EHB 64 kolory'; CS: 'EHB 64barevná paleta';
     FR: 'Palette EHB 64 couleurs'; DE: 'EHB 64-Farben-Palette'; IT: 'Tavolozza EHB a 64 colori';
     ES: 'Paleta EHB de 64 colores'; PT: 'Paleta EHB de 64 cores'; AF: 'EHB 64-kleurpalet'),
    (EN: 'AGA 256-color palette'; PL: 'Paleta AGA 256 kolorów'; CS: 'AGA 256barevná paleta';
     FR: 'Palette AGA 256 couleurs'; DE: 'AGA 256-Farben-Palette'; IT: 'Tavolozza AGA a 256 colori';
     ES: 'Paleta AGA de 256 colores'; PT: 'Paleta AGA de 256 cores'; AF: 'AGA 256-kleurpalet'),
    (EN: 'Workbench 256-color palette'; PL: 'Paleta Workbench 256 kolorów'; CS: 'Workbench 256barevná paleta';
     FR: 'Palette Workbench 256 couleurs'; DE: 'Workbench 256-Farben-Palette'; IT: 'Tavolozza Workbench a 256 colori';
     ES: 'Paleta Workbench de 256 colores'; PT: 'Paleta Workbench de 256 cores'; AF: 'Workbench 256-kleurpalet'),
    (EN: 'MagicWB 8-color palette'; PL: 'Paleta MagicWB 8 kolorów'; CS: 'MagicWB 8barevná paleta';
     FR: 'Palette MagicWB 8 couleurs'; DE: 'MagicWB 8-Farben-Palette'; IT: 'Tavolozza MagicWB a 8 colori';
     ES: 'Paleta MagicWB de 8 colores'; PT: 'Paleta MagicWB de 8 cores'; AF: 'MagicWB 8-kleurpalet'),
    (EN: 'Barrel distortion'; PL: 'Dystorsja'; CS: 'Soudkové zkreslení';
     FR: 'Distorsion en barillet'; DE: 'Tonnenverzerrung'; IT: 'Distorsione a barilotto';
     ES: 'Distorsión de barril'; PT: 'Distorção de barril'; AF: 'Vatvervorming'),
    (EN: 'Arc distortion'; PL: 'Dystorsja łukowa'; CS: 'Obloukové zkreslení';
     FR: 'Distorsion en arc'; DE: 'Bogenverzerrung'; IT: 'Distorsione ad arco';
     ES: 'Distorsión de arco'; PT: 'Distorção em arco'; AF: 'Boogvervorming'),
    (EN: 'Swirl'; PL: 'Wir'; CS: 'Víření';
     FR: 'Tourbillon'; DE: 'Wirbel'; IT: 'Vortice';
     ES: 'Remolino'; PT: 'Redemoinho'; AF: 'Draaikolk'),
    (EN: 'Water ripple'; PL: 'Fale wodne'; CS: 'Vodní vlnění';
     FR: 'Ondulation'; DE: 'Wasserwelle'; IT: 'Increspatura dell''acqua';
     ES: 'Ondulación del agua'; PT: 'Ondulação da água'; AF: 'Waterrimpeling'),
    (EN: 'Polar distortion'; PL: 'Zniekształcenie biegunowe'; CS: 'Polární zkreslení';
     FR: 'Distorsion polaire'; DE: 'Polarverzerrung'; IT: 'Distorsione polare';
     ES: 'Distorsión polar'; PT: 'Distorção polar'; AF: 'Polêre vervorming'),
    (EN: 'Preferences'; PL: 'Jakość zapisu'; CS: 'Předvolby';
     FR: 'Préférences'; DE: 'Einstellungen'; IT: 'Preferenze';
     ES: 'Preferencias'; PT: 'Preferências'; AF: 'Voorkeure'),
    (EN: 'Saturation (0-200, default 100):'; PL: 'Nasycenie (0–200, domyślnie 100):'; CS: 'Sytost (0-200, výchozí 100):';
     FR: 'Saturation (0-200, valeur par défaut 100) :'; DE: 'Sättigung (0-200, Standard 100):'; IT: 'Saturazione (0-200, predefinito 100):';
     ES: 'Saturación (0-200, predeterminado 100):'; PT: 'Saturação (0-200, predefinido 100):'; AF: 'Versadiging (0-200, standaard 100):'),
    (EN: 'Hue (0-200, default 100):'; PL: 'Odcień (0–200, domyślnie 100):'; CS: 'Odstín (0-200, výchozí 100):';
     FR: 'Teinte (0-200, valeur par défaut 100) :'; DE: 'Farbton (0-200, Standard 100):'; IT: 'Tonalità (0-200, predefinito 100):';
     ES: 'Tono (0-200, predeterminado 100):'; PT: 'Tonalidade (0-200, predefinido 100):'; AF: 'Tint (0-200, standaard 100):'),
    (EN: 'Contrast (0-10):'; PL: 'Kontrast przed konwersją (0–10):'; CS: 'Kontrast (0-10):';
     FR: 'Contraste (0-10) :'; DE: 'Kontrast (0-10):'; IT: 'Contrasto (0-10):';
     ES: 'Contraste (0-10):'; PT: 'Contraste (0-10):'; AF: 'Kontras (0-10):'),
    (EN: 'Number of colors (2-64):'; PL: 'Liczba kolorów (2–64):'; CS: 'Počet barev (2-64):';
     FR: 'Nombre de couleurs (2-64) :'; DE: 'Farbanzahl (2-64):'; IT: 'Numero di colori (2-64):';
     ES: 'Número de colores (2-64):'; PT: 'Número de cores (2-64):'; AF: 'Aantal kleure (2-64):'),
    (EN: 'Opacity:'; PL: 'Krycie'; CS: 'Krytí:';
     FR: 'Opacité :'; DE: 'Deckkraft:'; IT: 'Opacità:';
     ES: 'Opacidad:'; PT: 'Opacidade:'; AF: 'Ondeursigtigheid:'),
    (EN: 'Mode:'; PL: 'Tryb:'; CS: 'Režim:';
     FR: 'Mode :'; DE: 'Modus:'; IT: 'Modalità:';
     ES: 'Modo:'; PT: 'Modo:'; AF: 'Modus:'),
    (EN: 'Select color...'; PL: 'Wybierz kolor...'; CS: 'Vybrat barvu...';
     FR: 'Choisir une couleur…'; DE: 'Farbe wählen...'; IT: 'Seleziona colore...';
     ES: 'Seleccionar color...'; PT: 'Selecionar cor...'; AF: 'Kies kleur...'),
    (EN: 'Select type:'; PL: 'Wybierz rodzaj:'; CS: 'Vyberte typ:';
     FR: 'Choisir le type :'; DE: 'Typ wählen:'; IT: 'Seleziona tipo:';
     ES: 'Seleccionar tipo:'; PT: 'Selecionar tipo:'; AF: 'Kies tipe:'),
    (EN: 'Select arc angle:'; PL: 'Wybierz kąt łuku:'; CS: 'Vyberte úhel oblouku:';
     FR: 'Choisir l’angle de l’arc :'; DE: 'Bogenwinkel auswählen:'; IT: 'Seleziona l''angolo dell''arco:';
     ES: 'Seleccionar ángulo del arco:'; PT: 'Selecionar ângulo do arco:'; AF: 'Kies booghoek:'),
    (EN: 'Select intensity:'; PL: 'Wybierz intensywność:'; CS: 'Vyberte intenzitu:';
     FR: 'Choisir l’intensité :'; DE: 'Intensität auswählen:'; IT: 'Seleziona intensità:';
     ES: 'Seleccionar intensidad:'; PT: 'Selecionar intensidade:'; AF: 'Kies intensiteit:'),
    (EN: 'Select variant:'; PL: 'Wybierz wariant:'; CS: 'Vyberte variantu:';
     FR: 'Choisir la variante :'; DE: 'Variante auswählen:'; IT: 'Seleziona variante:';
     ES: 'Seleccionar variante:'; PT: 'Selecionar variante:'; AF: 'Kies variant:'),
    (EN: 'Weak barrel'; PL: 'Słaba beczka'; CS: 'Slabý soudek';
     FR: 'Barillet faible'; DE: 'Schwache Tonne'; IT: 'Barilotto debole';
     ES: 'Barril suave'; PT: 'Barril fraco'; AF: 'Ligte vatvervorming'),
    (EN: 'Medium barrel'; PL: 'Średnia beczka'; CS: 'Střední soudek';
     FR: 'Barillet moyen'; DE: 'Mittlere Tonne'; IT: 'Barilotto medio';
     ES: 'Barril medio'; PT: 'Barril médio'; AF: 'Medium vatvervorming'),
    (EN: 'Strong barrel'; PL: 'Mocna beczka'; CS: 'Silný soudek';
     FR: 'Barillet fort'; DE: 'Starke Tonne'; IT: 'Barilotto forte';
     ES: 'Barril fuerte'; PT: 'Barril forte'; AF: 'Sterk vatvervorming'),
    (EN: 'Weak pincushion'; PL: 'Słaba poduszka'; CS: 'Slabá poduška';
     FR: 'Coussinet faible'; DE: 'Schwaches Kissen'; IT: 'Cuscinetto debole';
     ES: 'Cojín suave'; PT: 'Almofada fraca'; AF: 'Ligte kussingvervorming'),
    (EN: 'Medium pincushion'; PL: 'Średnia poduszka'; CS: 'Střední poduška';
     FR: 'Coussinet moyen'; DE: 'Mittleres Kissen'; IT: 'Cuscinetto medio';
     ES: 'Cojín medio'; PT: 'Almofada média'; AF: 'Medium kussingvervorming'),
    (EN: 'Strong pincushion'; PL: 'Mocna poduszka'; CS: 'Silná poduška';
     FR: 'Coussinet fort'; DE: 'Starkes Kissen'; IT: 'Cuscinetto forte';
     ES: 'Cojín fuerte'; PT: 'Almofada forte'; AF: 'Sterk kussingvervorming'),
    (EN: '45°'; PL: '45°'; CS: '45°';
     FR: '45°'; DE: '45°'; IT: '45°';
     ES: '45°'; PT: '45°'; AF: '45°'),
    (EN: '90°'; PL: '90°'; CS: '90°';
     FR: '90°'; DE: '90°'; IT: '90°';
     ES: '90°'; PT: '90°'; AF: '90°'),
    (EN: '180°'; PL: '180°'; CS: '180°';
     FR: '180°'; DE: '180°'; IT: '180°';
     ES: '180°'; PT: '180°'; AF: '180°'),
    (EN: '360°'; PL: '360°'; CS: '360°';
     FR: '360°'; DE: '360°'; IT: '360°';
     ES: '360°'; PT: '360°'; AF: '360°'),
    (EN: '90° + rotate'; PL: '90° + obrót'; CS: '90° + otočit';
     FR: '90° + rotation'; DE: '90° + drehen'; IT: '90° + ruota';
     ES: '90° + girar'; PT: '90° + rodar'; AF: '90° + draai'),
    (EN: '180° + rotate'; PL: '180° + obrót'; CS: '180° + otočit';
     FR: '180° + rotation'; DE: '180° + drehen'; IT: '180° + ruota';
     ES: '180° + girar'; PT: '180° + rodar'; AF: '180° + draai'),
    (EN: 'Weak (45°)'; PL: 'Słaby (45°)'; CS: 'Slabé (45°)';
     FR: 'Faible (45°)'; DE: 'Schwach (45°)'; IT: 'Debole (45°)';
     ES: 'Suave (45°)'; PT: 'Fraco (45°)'; AF: 'Lig (45°)'),
    (EN: 'Medium (90°)'; PL: 'Średní (90°)'; CS: 'Střední (90°)';
     FR: 'Moyen (90°)'; DE: 'Mittel (90°)'; IT: 'Medio (90°)';
     ES: 'Medio (90°)'; PT: 'Médio (90°)'; AF: 'Medium (90°)'),
    (EN: 'Strong (180°)'; PL: 'Silny (180°)'; CS: 'Silné (180°)';
     FR: 'Fort (180°)'; DE: 'Stark (180°)'; IT: 'Forte (180°)';
     ES: 'Fuerte (180°)'; PT: 'Forte (180°)'; AF: 'Sterk (180°)'),
    (EN: 'Very strong (270°)'; PL: 'Bardzo mocny (270°)'; CS: 'Velmi silné (270°)';
     FR: 'Très fort (270°)'; DE: 'Sehr stark (270°)'; IT: 'Molto forte (270°)';
     ES: 'Muy fuerte (270°)'; PT: 'Muito forte (270°)'; AF: 'Baie sterk (270°)'),
    (EN: 'Full (360°)'; PL: 'Pełny (360°)'; CS: 'Plné (360°)';
     FR: 'Complet (360°)'; DE: 'Voll (360°)'; IT: 'Completo (360°)';
     ES: 'Completo (360°)'; PT: 'Completo (360°)'; AF: 'Volledig (360°)'),
    (EN: 'Reverse'; PL: 'Odwrócony'; CS: 'Obrátit';
     FR: 'Inverser'; DE: 'Umgekehrt'; IT: 'Invertito';
     ES: 'Invertido'; PT: 'Invertido'; AF: 'Omgekeer'),
    (EN: 'Light'; PL: 'Delikatne'; CS: 'Světlé';
     FR: 'Léger'; DE: 'Leicht'; IT: 'Leggero';
     ES: 'Suave'; PT: 'Suave'; AF: 'Lig'),
    (EN: 'Medium'; PL: 'Średnie'; CS: 'Střední';
     FR: 'Moyen'; DE: 'Mittel'; IT: 'Medio';
     ES: 'Medio'; PT: 'Médio'; AF: 'Medium'),
    (EN: 'Strong'; PL: 'Silne'; CS: 'Silné';
     FR: 'Fort'; DE: 'Stark'; IT: 'Forte';
     ES: 'Fuerte'; PT: 'Forte'; AF: 'Sterk'),
    (EN: 'Concentric'; PL: 'Koncentryczne'; CS: 'Soustředné';
     FR: 'Concentrique'; DE: 'Konzentrisch'; IT: 'Concentrico';
     ES: 'Concéntrico'; PT: 'Concêntrico'; AF: 'Konsentries'),
    (EN: 'From corner'; PL: 'Od rogu'; CS: 'Z rohu';
     FR: 'Depuis le coin'; DE: 'Von der Ecke'; IT: 'Dall''angolo';
     ES: 'Desde la esquina'; PT: 'A partir do canto'; AF: 'Vanaf hoek'),
    (EN: 'Dense'; PL: 'Gęste'; CS: 'Husté';
     FR: 'Dense'; DE: 'Dicht'; IT: 'Denso';
     ES: 'Denso'; PT: 'Denso'; AF: 'Dig'),
    (EN: 'Full'; PL: 'Pełny'; CS: 'Plné';
     FR: 'Complet'; DE: 'Voll'; IT: 'Completo';
     ES: 'Completo'; PT: 'Completo'; AF: 'Volledig'),
    (EN: 'Half angle'; PL: 'Połowa kąta'; CS: 'Poloviční úhel';
     FR: 'Demi-angle'; DE: 'Halber Winkel'; IT: 'Mezzo angolo';
     ES: 'Medio ángulo'; PT: 'Meio ângulo'; AF: 'Halwe hoek'),
    (EN: 'Quarter angle'; PL: 'Ćwierć kąta'; CS: 'Čtvrtinový úhel';
     FR: 'Quart d’angle'; DE: 'Viertelwinkel'; IT: 'Quarto di angolo';
     ES: 'Cuarto de ángulo'; PT: 'Quarto de ângulo'; AF: 'Kwarthoek'),
    (EN: 'Ring'; PL: 'Pierścień'; CS: 'Prstenec';
     FR: 'Anneau'; DE: 'Ring'; IT: 'Anello';
     ES: 'Anillo'; PT: 'Anel'; AF: 'Ring'),
    (EN: 'Small radius'; PL: 'Mały promień'; CS: 'Malý poloměr';
     FR: 'Petit rayon'; DE: 'Kleiner Radius'; IT: 'Raggio piccolo';
     ES: 'Radio pequeño'; PT: 'Raio pequeno'; AF: 'Klein radius'),
    (EN: 'Smooth'; PL: 'Wygładzony'; CS: 'Hladké';
     FR: 'Lisse'; DE: 'Glatt'; IT: 'Morbido';
     ES: 'Suave'; PT: 'Suave'; AF: 'Glad'),
    (EN: 'Tunnel'; PL: 'Tunel'; CS: 'Tunel';
     FR: 'Tunnel'; DE: 'Tunnel'; IT: 'Tunnel';
     ES: 'Túnel'; PT: 'Túnel'; AF: 'Tonnel'),
    (EN: 'Fisheye'; PL: 'Rybie oko'; CS: 'Rybí oko';
     FR: 'Œil-de-poisson'; DE: 'Fischauge'; IT: 'Occhio di pesce';
     ES: 'Ojo de pez'; PT: 'Olho de peixe'; AF: 'Visoog'),
    (EN: 'Outer stretch'; PL: 'Rozciągnięcie zewnętrzne'; CS: 'Vnější roztažení';
     FR: 'Étirement extérieur'; DE: 'Äußere Dehnung'; IT: 'Stiramento esterno';
     ES: 'Estiramiento exterior'; PT: 'Estiramento exterior'; AF: 'Buite-uitrekking'),
    (EN: 'Error'; PL: 'Błąd'; CS: 'Chyba';
     FR: 'Erreur'; DE: 'Fehler'; IT: 'Errore';
     ES: 'Error'; PT: 'Erro'; AF: 'Fout'),
    (EN: 'Unsupported file format.'; PL: 'Nieobsługiwany format pliku'; CS: 'Nepodporovaný formát souboru.';
     FR: 'Format de fichier non pris en charge.'; DE: 'Nicht unterstütztes Dateiformat.'; IT: 'Formato file non supportato.';
     ES: 'Formato de archivo no compatible.'; PT: 'Formato de ficheiro não suportado.'; AF: 'Lêerformaat word nie ondersteun nie.'),
    (EN: 'Snapshot'; PL: 'Migawka'; CS: 'Snímek';
     FR: 'Instantané'; DE: 'Schnappschuss'; IT: 'Istantanea';
     ES: 'Instantánea'; PT: 'Instantâneo'; AF: 'Kiekie'),
    (EN: 'Original'; PL: 'Oryginał'; CS: 'Originál';
     FR: 'Original'; DE: 'Original'; IT: 'Originale';
     ES: 'Original'; PT: 'Original'; AF: 'Oorspronklik'),
    (EN: 'Gamma (10-500, 100=1.0):'; PL: 'Gamma (10–500, 100=1.0):'; CS: 'Gama (10-500, 100=1,0):';
     FR: 'Gamma (10-500, 100 = 1,0) :'; DE: 'Gamma (10–500, 100=1,0):'; IT: 'Gamma (10-500, 100 = 1,0):';
     ES: 'Gamma (10-500, 100 = 1,0):'; PT: 'Gama (10-500, 100 = 1,0):'; AF: 'Gamma (10-500, 100 = 1,0):'),
    (EN: 'Add layer'; PL: 'Efekt A'; CS: 'Přidat vrstvu';
     FR: 'Ajouter un calque'; DE: 'Ebene hinzufügen'; IT: 'Aggiungi livello';
     ES: 'Añadir capa'; PT: 'Adicionar camada'; AF: 'Voeg laag by'),
    (EN: 'Merge layers'; PL: 'Efekt B'; CS: 'Sloučit vrstvy';
     FR: 'Fusionner les calques'; DE: 'Ebenen zusammenführen'; IT: 'Unisci livelli';
     ES: 'Combinar capas'; PT: 'Unir camadas'; AF: 'Voeg lae saam'),
    (EN: 'Histogram equalization'; PL: 'Wyrównanie histogramu'; CS: 'Vyrovnání histogramu';
     FR: 'Égalisation de l’histogramme'; DE: 'Histogramm-Entzerrung'; IT: 'Equalizzazione dell''istogramma';
     ES: 'Ecualización del histograma'; PT: 'Equalização do histograma'; AF: 'Histogram-egalisering'),
    (EN: 'Undo:'; PL: 'Cofnij'; CS: 'Zpět:';
     FR: 'Annuler :'; DE: 'Rückgängig:'; IT: 'Annulla:';
     ES: 'Deshacer:'; PT: 'Anular:'; AF: 'Ontdoen:'),
    (EN: 'Redo:'; PL: 'Ponów'; CS: 'Znovu:';
     FR: 'Rétablir :'; DE: 'Wiederholen:'; IT: 'Ripristina:';
     ES: 'Rehacer:'; PT: 'Refazer:'; AF: 'Herdoen:'),
    (EN: 'HDR 2'; PL: 'Wzmocnienie zdjęcia'; CS: 'HDR 2';
     FR: 'HDR 2'; DE: 'HDR 2'; IT: 'HDR 2';
     ES: 'HDR 2'; PT: 'HDR 2'; AF: 'HDR 2'),
    (EN: 'WB 1.x'; PL: 'Workbench 1.x'; CS: 'WB 1.x';
     FR: 'WB 1.x'; DE: 'WB 1.x'; IT: 'WB 1.x';
     ES: 'WB 1.x'; PT: 'WB 1.x'; AF: 'WB 1.x'),
    (EN: 'WB 2.x'; PL: 'Workbench 2.x'; CS: 'WB 2.x';
     FR: 'WB 2.x'; DE: 'WB 2.x'; IT: 'WB 2.x';
     ES: 'WB 2.x'; PT: 'WB 2.x'; AF: 'WB 2.x'),
    (EN: 'OCS 32'; PL: 'OCS 32'; CS: 'OCS 32';
     FR: 'OCS 32'; DE: 'OCS 32'; IT: 'OCS 32';
     ES: 'OCS 32'; PT: 'OCS 32'; AF: 'OCS 32'),
    (EN: 'EHB'; PL: 'EHB'; CS: 'EHB';
     FR: 'EHB'; DE: 'EHB'; IT: 'EHB';
     ES: 'EHB'; PT: 'EHB'; AF: 'EHB'),
    (EN: 'AGA 256'; PL: 'AGA 256'; CS: 'AGA 256';
     FR: 'AGA 256'; DE: 'AGA 256'; IT: 'AGA 256';
     ES: 'AGA 256'; PT: 'AGA 256'; AF: 'AGA 256'),
    (EN: 'WB 256'; PL: 'WB 256'; CS: 'WB 256';
     FR: 'WB 256'; DE: 'WB 256'; IT: 'WB 256';
     ES: 'WB 256'; PT: 'WB 256'; AF: 'WB 256'),
    (EN: 'MagicWB'; PL: 'MagicWB'; CS: 'MagicWB';
     FR: 'MagicWB'; DE: 'MagicWB'; IT: 'MagicWB';
     ES: 'MagicWB'; PT: 'MagicWB'; AF: 'MagicWB'),
    (EN: 'Flip horizontal'; PL: 'Lustro poziome'; CS: 'Převrátit vodorovně';
     FR: 'Retourner horizontalement'; DE: 'Horizontal spiegeln'; IT: 'Rifletti orizzontalmente';
     ES: 'Voltear horizontalmente'; PT: 'Espelhar horizontalmente'; AF: 'Spieël horisontaal'),
    (EN: 'Flip vertical'; PL: 'Lustro pionowe'; CS: 'Převrátit svisle';
     FR: 'Retourner verticalement'; DE: 'Vertikal spiegeln'; IT: 'Rifletti verticalmente';
     ES: 'Voltear verticalmente'; PT: 'Espelhar verticalmente'; AF: 'Spieël vertikaal'),
    (EN: 'Rotate 180'; PL: 'Obrót 180'; CS: 'Otočit 180';
     FR: 'Pivoter de 180°'; DE: '180° drehen'; IT: 'Ruota di 180°';
     ES: 'Girar 180°'; PT: 'Rodar 180°'; AF: 'Draai 180°'),
    (EN: 'Straighten'; PL: 'Prostowanie'; CS: 'Narovnat';
     FR: 'Redresser'; DE: 'Geraderichten'; IT: 'Raddrizza';
     ES: 'Enderezar'; PT: 'Endireitar'; AF: 'Reguit maak'),
    (EN: 'False-color IR'; PL: 'Podczerwień'; CS: 'Falešné barvy IR';
     FR: 'Infrarouge en fausses couleurs'; DE: 'Falschfarben-IR'; IT: 'Infrarosso a falsi colori';
     ES: 'Infrarrojo en falso color'; PT: 'Infravermelho em falsas cores'; AF: 'Valskleur-infrarooi'),
    (EN: 'Thermal'; PL: 'Termiczny'; CS: 'Termální';
     FR: 'Thermique'; DE: 'Thermisch'; IT: 'Termico';
     ES: 'Térmico'; PT: 'Térmico'; AF: 'Termies'),
    (EN: 'Emboss'; PL: 'Wytłaczanie'; CS: 'Reliéf';
     FR: 'Estampage'; DE: 'Relief'; IT: 'Rilievo';
     ES: 'Relieve'; PT: 'Relevo'; AF: 'Reliëf'),
    (EN: 'Duotone'; PL: 'Dwukolor'; CS: 'Duotón';
     FR: 'Duotone'; DE: 'Duoton'; IT: 'Duotono';
     ES: 'Duotono'; PT: 'Duotom'; AF: 'Duotoon'),
    (EN: 'Contrast (before conversion)'; PL: 'Kontrast (przed konwersją)'; CS: 'Kontrast (před převodem)';
     FR: 'Contraste (avant conversion)'; DE: 'Kontrast (vor der Umwandlung)'; IT: 'Contrasto (prima della conversione)';
     ES: 'Contraste (antes de la conversión)'; PT: 'Contraste (antes da conversão)'; AF: 'Kontras (voor omskakeling)'),
    (EN: 'Red'; PL: 'Czerwona'; CS: 'Červená';
     FR: 'Rouge'; DE: 'Rot'; IT: 'Rosso';
     ES: 'Rojo'; PT: 'Vermelho'; AF: 'Rooi'),
    (EN: 'Green'; PL: 'Zielona'; CS: 'Zelená';
     FR: 'Vert'; DE: 'Grün'; IT: 'Verde';
     ES: 'Verde'; PT: 'Verde'; AF: 'Groen'),
    (EN: 'Hue'; PL: 'Odcień'; CS: 'Odstín';
     FR: 'Teinte'; DE: 'Farbton'; IT: 'Tonalità';
     ES: 'Tono'; PT: 'Tonalidade'; AF: 'Tint'),
    (EN: 'Saturation'; PL: 'Saturacja'; CS: 'Sytost';
     FR: 'Saturation'; DE: 'Sättigung'; IT: 'Saturazione';
     ES: 'Saturación'; PT: 'Saturação'; AF: 'Versadiging'),
    (EN: 'Gamma'; PL: 'Gamma'; CS: 'Gama';
     FR: 'Gamma'; DE: 'Gamma'; IT: 'Gamma';
     ES: 'Gamma'; PT: 'Gama'; AF: 'Gamma'),
    (EN: 'Strength'; PL: 'Siła'; CS: 'Síla';
     FR: 'Force'; DE: 'Stärke'; IT: 'Intensità';
     ES: 'Intensidad'; PT: 'Intensidade'; AF: 'Sterkte'),
    (EN: 'Threshold'; PL: 'Próg'; CS: 'Práh';
     FR: 'Seuil'; DE: 'Schwellwert'; IT: 'Soglia';
     ES: 'Umbral'; PT: 'Limiar'; AF: 'Drempel'),
    (EN: 'Angle'; PL: 'Kąt'; CS: 'Úhel';
     FR: 'Angle'; DE: 'Winkel'; IT: 'Angolo';
     ES: 'Ángulo'; PT: 'Ângulo'; AF: 'Hoek'),
    (EN: 'Cell size'; PL: 'Wielkość komórki'; CS: 'Velikost buňky';
     FR: 'Taille de cellule'; DE: 'Zellgröße'; IT: 'Dimensione cella';
     ES: 'Tamaño de celda'; PT: 'Tamanho da célula'; AF: 'Selgrootte'),
    (EN: 'Thickness'; PL: 'Grubość'; CS: 'Tloušťka';
     FR: 'Épaisseur'; DE: 'Stärke'; IT: 'Spessore';
     ES: 'Grosor'; PT: 'Espessura'; AF: 'Dikte'),
    (EN: 'Dot size'; PL: 'Wielkość kropkek'; CS: 'Velikost bodu';
     FR: 'Taille des points'; DE: 'Punktgröße'; IT: 'Dimensione punto';
     ES: 'Tamaño del punto'; PT: 'Tamanho do ponto'; AF: 'Kolgrootte'),
    (EN: 'Radius'; PL: 'Promień'; CS: 'Poloměr';
     FR: 'Rayon'; DE: 'Radius'; IT: 'Raggio';
     ES: 'Radio'; PT: 'Raio'; AF: 'Radius'),
    (EN: 'Unknown'; PL: 'Nieznany'; CS: 'Neznámé';
     FR: 'Inconnu'; DE: 'Unbekannt'; IT: 'Sconosciuto';
     ES: 'Desconocido'; PT: 'Desconhecido'; AF: 'Onbekend'),
    (EN: 'Information'; PL: 'Informacja'; CS: 'Informace';
     FR: 'Informations'; DE: 'Information'; IT: 'Informazioni';
     ES: 'Información'; PT: 'Informação'; AF: 'Inligting'),
    (EN: 'Name:'; PL: 'Nazwa:'; CS: 'Název:';
     FR: 'Nom :'; DE: 'Name:'; IT: 'Nome:';
     ES: 'Nombre:'; PT: 'Nome:'; AF: 'Naam:'),
    (EN: 'Alpha channel:'; PL: 'Kanał Alfa:'; CS: 'Alfa kanál:';
     FR: 'Canal alpha :'; DE: 'Alphakanal:'; IT: 'Canale alfa:';
     ES: 'Canal alfa:'; PT: 'Canal alfa:'; AF: 'Alfa-kanaal:'),
    (EN: 'Width:'; PL: 'Szerokość:'; CS: 'Šířka:';
     FR: 'Largeur :'; DE: 'Breite:'; IT: 'Larghezza:';
     ES: 'Ancho:'; PT: 'Largura:'; AF: 'Breedte:'),
    (EN: 'Height:'; PL: 'Wysokość:'; CS: 'Výška:';
     FR: 'Hauteur :'; DE: 'Höhe:'; IT: 'Altezza:';
     ES: 'Alto:'; PT: 'Altura:'; AF: 'Hoogte:'),
    (EN: 'Size:'; PL: 'Wielkość:'; CS: 'Velikost:';
     FR: 'Taille :'; DE: 'Größe:'; IT: 'Dimensione:';
     ES: 'Tamaño:'; PT: 'Tamanho:'; AF: 'Grootte:'),
    (EN: 'Date:'; PL: 'Data:'; CS: 'Datum:';
     FR: 'Date :'; DE: 'Datum:'; IT: 'Data:';
     ES: 'Fecha:'; PT: 'Data:'; AF: 'Datum:'),
    (EN: 'Time:'; PL: 'Godzina:'; CS: 'Čas:';
     FR: 'Heure :'; DE: 'Zeit:'; IT: 'Ora:';
     ES: 'Hora:'; PT: 'Hora:'; AF: 'Tyd:'),
    (EN: 'Yes'; PL: 'Tak'; CS: 'Ano';
     FR: 'Oui'; DE: 'Ja'; IT: 'Sì';
     ES: 'Sí'; PT: 'Sim'; AF: 'Ja'),
    (EN: 'No'; PL: 'Nie'; CS: 'Ne';
     FR: 'Non'; DE: 'Nein'; IT: 'No';
     ES: 'No'; PT: 'Não'; AF: 'Nee'),
    (EN: 'Thumbnail'; PL: 'Miniatura'; CS: 'Náhled';
     FR: 'Miniature'; DE: 'Vorschaubild'; IT: 'Miniatura';
     ES: 'Miniatura'; PT: 'Miniatura'; AF: 'Kleinkiekie'),
    (EN: 'Select size:'; PL: 'Wybierz rozmiar:'; CS: 'Vyberte velikost:';
     FR: 'Choisir la taille :'; DE: 'Größe auswählen:'; IT: 'Seleziona dimensione:';
     ES: 'Seleccionar tamaño:'; PT: 'Selecionar tamanho:'; AF: 'Kies grootte:'),
    (EN: '100 px'; PL: '100 px'; CS: '100 px';
     FR: '100 px'; DE: '100 px'; IT: '100 px';
     ES: '100 px'; PT: '100 px'; AF: '100 px'),
    (EN: '200 px'; PL: '200 px'; CS: '200 px';
     FR: '200 px'; DE: '200 px'; IT: '200 px';
     ES: '200 px'; PT: '200 px'; AF: '200 px'),
    (EN: '320 x 240'; PL: '320 x 240'; CS: '320 x 240';
     FR: '320 x 240'; DE: '320 x 240'; IT: '320 x 240';
     ES: '320 x 240'; PT: '320 x 240'; AF: '320 x 240'),
    (EN: '640 x 480'; PL: '640 x 480'; CS: '640 x 480';
     FR: '640 x 480'; DE: '640 x 480'; IT: '640 x 480';
     ES: '640 x 480'; PT: '640 x 480'; AF: '640 x 480'),
    (EN: 'Done'; PL: 'Gotowe'; CS: 'Hotovo';
     FR: 'Terminé'; DE: 'Fertig'; IT: 'Fatto';
     ES: 'Hecho'; PT: 'Concluído'; AF: 'Klaar'),
    (EN: 'Thumbnail saved.'; PL: 'Miniatura zapisana'; CS: 'Náhled uložen.';
     FR: 'Vignette enregistrée.'; DE: 'Vorschaubild gespeichert.'; IT: 'Miniatura salvata.';
     ES: 'Miniatura guardada.'; PT: 'Miniatura guardada.'; AF: 'Kleinkiekie gestoor.'),
    (EN: 'Save thumbnail as'; PL: 'Zapisz miniaturę jako'; CS: 'Uložit náhled jako';
     FR: 'Enregistrer la vignette sous'; DE: 'Vorschaubild speichern unter'; IT: 'Salva miniatura con nome';
     ES: 'Guardar miniatura como'; PT: 'Guardar miniatura como'; AF: 'Stoor kleinkiekie as'),
    (EN: 'JPEG compression quality (0-100):'; PL: 'Jakość zapisu JPEG (0–100):'; CS: 'Kvalita komprese JPEG (0-100):';
     FR: 'Qualité de compression JPEG (0-100) :'; DE: 'JPEG-Komprimierungsqualität (0-100):'; IT: 'Qualità di compressione JPEG (0-100):';
     ES: 'Calidad de compresión JPEG (0-100):'; PT: 'Qualidade de compressão JPEG (0-100):'; AF: 'JPEG-kompressiegehalte (0-100):'),
    (EN: 'Normal'; PL: 'Normalna'; CS: 'Normální';
     FR: 'Normal'; DE: 'Normal'; IT: 'Normale';
     ES: 'Normal'; PT: 'Normal'; AF: 'Normaal'),
    (EN: 'Multiply'; PL: 'Mnożenie'; CS: 'Násobení';
     FR: 'Multiplier'; DE: 'Multiplizieren'; IT: 'Moltiplica';
     ES: 'Multiplicar'; PT: 'Multiplicar'; AF: 'Vermenigvuldig'),
    (EN: 'Screen'; PL: 'Ekran'; CS: 'Obrazovka';
     FR: 'Écran'; DE: 'Negativ multiplizieren'; IT: 'Schermo';
     ES: 'Pantalla'; PT: 'Ecrã'; AF: 'Skerm'),
    (EN: 'Overlay'; PL: 'Nakładka'; CS: 'Překrytí';
     FR: 'Superposition'; DE: 'Überlagern'; IT: 'Sovrapponi';
     ES: 'Superposición'; PT: 'Sobrepor'; AF: 'Oorleg'),
    (EN: 'Soft Light'; PL: 'Miękkie światło'; CS: 'Měkké světlo';
     FR: 'Lumière douce'; DE: 'Weiches Licht'; IT: 'Luce soffusa';
     ES: 'Luz suave'; PT: 'Luz suave'; AF: 'Sagte Lig'),
    (EN: 'Darker'; PL: 'Ciemniejszy'; CS: 'Tmavší';
     FR: 'Plus sombre'; DE: 'Dunkler'; IT: 'Più scuro';
     ES: 'Más oscuro'; PT: 'Mais escuro'; AF: 'Donkerder'),
    (EN: 'Lighter'; PL: 'Jaśniejszy'; CS: 'Světlejší';
     FR: 'Plus clair'; DE: 'Heller'; IT: 'Più chiaro';
     ES: 'Más claro'; PT: 'Mais claro'; AF: 'Ligter'),
    (EN: 'Background (original)'; PL: 'Tło (oryginał)'; CS: 'Pozadí (originál)';
     FR: 'Arrière-plan (original)'; DE: 'Hintergrund (Original)'; IT: 'Sfondo (originale)';
     ES: 'Fondo (original)'; PT: 'Fundo (original)'; AF: 'Agtergrond (oorspronklik)'),
    (EN: 'Crimson + Cyan'; PL: 'Karmazyn + Cyjan'; CS: 'Karmínová + Azurová';
     FR: 'Cramoisi + Cyan'; DE: 'Cyjan + Magenta'; IT: 'Cremisi + Ciano';
     ES: 'Carmesí + Cian'; PT: 'Carmesim + Ciano'; AF: 'Karmosyn + Siaan'),
    (EN: 'Black + Yellow'; PL: 'Czerń + Żółty'; CS: 'Černá + Žlutá';
     FR: 'Noir + Jaune'; DE: 'Schwarz + Gelb'; IT: 'Nero + Giallo';
     ES: 'Negro + Amarillo'; PT: 'Preto + Amarelo'; AF: 'Swart + Geel'),
    (EN: 'Blue + Orange'; PL: 'Niebieski + Pomarańczowy'; CS: 'Modrá + Oranžová';
     FR: 'Bleu + Orange'; DE: 'Blau + Orange'; IT: 'Blu + Arancione';
     ES: 'Azul + Naranja'; PT: 'Azul + Laranja'; AF: 'Blou + Oranje'),
    (EN: 'Crimson + Cyan + Yellow'; PL: 'Karmazyn + Cyjan + Żółty'; CS: 'Karmínová + Azurová + Žlutá';
     FR: 'Cramoisi + Cyan + Jaune'; DE: 'Cyjan + Magenta + Gelb'; IT: 'Cremisi + Ciano + Giallo';
     ES: 'Carmesí + Cian + Amarillo'; PT: 'Carmesim + Ciano + Amarelo'; AF: 'Karmosyn + Siaan + Geel'),
    (EN: 'Black + Crimson + Yellow'; PL: 'Czerń + Karmazyn + Żółty'; CS: 'Černá + Karmínová + Žlutá';
     FR: 'Noir + Cramoisi + Jaune'; DE: 'Schwarz + Magenta + Gelb'; IT: 'Nero + Cremisi + Giallo';
     ES: 'Negro + Carmesí + Amarillo'; PT: 'Preto + Carmesim + Amarelo'; AF: 'Swart + Karmosyn + Geel'),
    (EN: 'CMYK (4 colors)'; PL: 'CMYK (4 kolory)'; CS: 'CMYK (4 barvy)';
     FR: 'CMJN (4 couleurs)'; DE: 'CMYK (4 Farben)'; IT: 'CMYK (4 colori)';
     ES: 'CMYK (4 colores)'; PT: 'CMYK (4 cores)'; AF: 'CMYK (4 kleure)'),
    (EN: 'Select equalization mode:'; PL: 'Wybierz tryb wyrównania:'; CS: 'Vyberte režim vyrovnání:';
     FR: 'Choisir le mode d’égalisation :'; DE: 'Entzerrungsmodus auswählen:'; IT: 'Seleziona modalità di equalizzazione:';
     ES: 'Seleccionar modo de ecualización:'; PT: 'Selecionar modo de equalização:'; AF: 'Kies egalisasiemodus:'),
    (EN: 'Luminance'; PL: 'Luminancja'; CS: 'Jas';
     FR: 'Luminance'; DE: 'Luminanz'; IT: 'Luminanza';
     ES: 'Luminancia'; PT: 'Luminância'; AF: 'Luminessensie'),
    (EN: 'All'; PL: 'Wszystkie'; CS: 'Vše';
     FR: 'Tous'; DE: 'Alle'; IT: 'Tutti';
     ES: 'Todos'; PT: 'Todos'; AF: 'Alles'),
    (EN: 'Histogram'; PL: 'Histogram'; CS: 'Histogram';
     FR: 'Histogramme'; DE: 'Histogramm'; IT: 'Istogramma';
     ES: 'Histograma'; PT: 'Histograma'; AF: 'Histogram'),
    (EN: 'Keyboard shortcuts'; PL: 'Skróty klawiszowe'; CS: 'Klávesové zkratky';
     FR: 'Raccourcis clavier'; DE: 'Tastenkombinationen'; IT: 'Scorciatoie da tastiera';
     ES: 'Atajos de teclado'; PT: 'Atalhos de teclado'; AF: 'Sleutelbordkortpaaie'),
    (EN: 'Macro'; PL: 'Makro'; CS: 'Makro';
     FR: 'Macro'; DE: 'Makro'; IT: 'Macro';
     ES: 'Macro'; PT: 'Macro'; AF: 'Makro'),
    (EN: 'Start recording'; PL: 'Rozpocznij nagrywanie'; CS: 'Spustit nahrávání';
     FR: 'Démarrer l’enregistrement'; DE: 'Aufnahme starten'; IT: 'Avvia registrazione';
     ES: 'Iniciar grabación'; PT: 'Iniciar gravação'; AF: 'Begin opname'),
    (EN: 'Stop and save'; PL: 'Zatrzymaj i zapisz'; CS: 'Zastavit a uložit';
     FR: 'Arrêter et enregistrer'; DE: 'Stoppen und speichern'; IT: 'Arresta e salva';
     ES: 'Detener y guardar'; PT: 'Parar e guardar'; AF: 'Stop en stoor'),
    (EN: 'Cancel recording'; PL: 'Anuluj nagrywanie'; CS: 'Zrušit nahrávání';
     FR: 'Annuler l’enregistrement'; DE: 'Aufnahme abbrechen'; IT: 'Annulla registrazione';
     ES: 'Cancelar grabación'; PT: 'Cancelar gravação'; AF: 'Kanselleer opname'),
    (EN: 'Manage macros...'; PL: 'Zarządzaj makrami...'; CS: 'Spravovat makra...';
     FR: 'Gérer les macros…'; DE: 'Makros verwalten...'; IT: 'Gestisci macro...';
     ES: 'Administrar macros...'; PT: 'Gerir macros...'; AF: 'Bestuur makro''s...'),
    (EN: 'Macros'; PL: 'Makra'; CS: 'Makra';
     FR: 'Macros'; DE: 'Makros'; IT: 'Macro';
     ES: 'Macros'; PT: 'Macros'; AF: 'Makro''s'),
    (EN: 'Play'; PL: 'Odtwórz'; CS: 'Spustit';
     FR: 'Lire'; DE: 'Abspielen'; IT: 'Riproduci';
     ES: 'Reproducir'; PT: 'Reproduzir'; AF: 'Speel'),
    (EN: 'Save macro'; PL: 'Zapisz makro'; CS: 'Uložit makro';
     FR: 'Enregistrer la macro'; DE: 'Makro speichern'; IT: 'Salva macro';
     ES: 'Guardar macro'; PT: 'Guardar macro'; AF: 'Stoor makro'),
    (EN: 'Macro name:'; PL: 'Nazwa makra:'; CS: 'Název makra:';
     FR: 'Nom de la macro :'; DE: 'Makroname:'; IT: 'Nome macro:';
     ES: 'Nombre de la macro:'; PT: 'Nome da macro:'; AF: 'Makronaam:'),
    (EN: 'Recording is already active.'; PL: 'Nagrywanie jest już aktywne.'; CS: 'Nahrávání je již aktivní.';
     FR: 'L’enregistrement est déjà actif.'; DE: 'Aufnahme ist bereits aktiv.'; IT: 'La registrazione è già attiva.';
     ES: 'La grabación ya está activa.'; PT: 'A gravação já está ativa.'; AF: 'Opname is reeds aktief.'),
    (EN: 'Add this step to macro?'; PL: 'Dodać ten krok do makra?'; CS: 'Přidat tento krok do makra?';
     FR: 'Ajouter cette étape à la macro ?'; DE: 'Diesen Schritt zum Makro hinzufügen?'; IT: 'Aggiungere questo passaggio alla macro?';
     ES: '¿Añadir este paso a la macro?'; PT: 'Adicionar este passo à macro?'; AF: 'Voeg hierdie stap by makro?'),
    (EN: 'Yes|No'; PL: 'Tak|Nie'; CS: 'Ano|Ne';
     FR: 'Oui|Non'; DE: 'Ja|Nein'; IT: 'Sì|No';
     ES: 'Sí|No'; PT: 'Sim|Não'; AF: 'Ja|Nee'),
    (EN: 'Recording is not active.'; PL: 'Nagrywanie nie jest aktywne.'; CS: 'Nahrávání není aktivní.';
     FR: 'L’enregistrement n’est pas actif.'; DE: 'Aufnahme ist nicht aktiv.'; IT: 'La registrazione non è attiva.';
     ES: 'La grabación no está activa.'; PT: 'A gravação não está ativa.'; AF: 'Opname is nie aktief nie.'),
    (EN: 'No steps to save.'; PL: 'Brak kroków do zapisania.'; CS: 'Žádné kroky k uložení.';
     FR: 'Aucune étape à enregistrer.'; DE: 'Keine Schritte zum Speichern.'; IT: 'Nessun passaggio da salvare.';
     ES: 'No hay pasos para guardar.'; PT: 'Não há passos para guardar.'; AF: 'Geen stappe om te stoor nie.'),
    (EN: 'No image loaded.'; PL: 'Nie wczytano obrazu.'; CS: 'Není načten žádný obrázek.';
     FR: 'Aucune image chargée.'; DE: 'Kein Bild geladen.'; IT: 'Nessuna immagine caricata.';
     ES: 'No hay ninguna imagen cargada.'; PT: 'Nenhuma imagem carregada.'; AF: 'Geen beeld gelaai nie.'),
    (EN: 'steps'; PL: 'kroków'; CS: 'kroků';
     FR: 'étapes'; DE: 'Schritte'; IT: 'passaggi';
     ES: 'pasos'; PT: 'passos'; AF: 'stappe'),
    (EN: 'Recording macro'; PL: 'Nagrywanie makra'; CS: 'Nahrávání makra';
     FR: 'Enregistrement de la macro'; DE: 'Makro wird aufgenommen'; IT: 'Registrazione macro';
     ES: 'Grabación de macro'; PT: 'Gravação de macro'; AF: 'Makro-opname'),
    (EN: 'HAM6 - 16 colors + Hold-Modify'; PL: 'HAM6 — 16 kolorów + Hold-Modify'; CS: 'HAM6 - 16 barev + Hold-Modify';
     FR: 'HAM6 - 16 couleurs + Hold-Modify'; DE: 'HAM6 - 16 Farben + Hold-Modify'; IT: 'HAM6 - 16 colori + Hold-Modify';
     ES: 'HAM6 - 16 colores + Hold-Modify'; PT: 'HAM6 - 16 cores + Hold-Modify'; AF: 'HAM6 - 16 kleure + Hou-Wysig'),
    (EN: 'HAM8 - 64 colors + Hold-Modify'; PL: 'HAM8 — 64 kolory + Hold-Modify'; CS: 'HAM8 - 64 barev + Hold-Modify';
     FR: 'HAM8 - 64 couleurs + Hold-Modify'; DE: 'HAM8 - 64 Farben + Hold-Modify'; IT: 'HAM8 - 64 colori + Hold-Modify';
     ES: 'HAM8 - 64 colores + Hold-Modify'; PT: 'HAM8 - 64 cores + Hold-Modify'; AF: 'HAM8 - 64 kleure + Hou-Wysig'),
    (EN: 'HAM6 simulation (16 base colors with hold-modify modes)'; PL: 'Symulacja HAM6 (16 kolorów podstawowych z trybami hold-modify)'; CS: 'Simulace HAM6 (16 základních barev s režimy hold-modify)';
     FR: 'Simulation HAM6 (16 couleurs de base avec modes Hold-Modify)'; DE: 'HAM6-Simulation (16 Grundfarben mit Hold-Modify-Modi)'; IT: 'Simulazione HAM6 (16 colori base con modalità Hold-Modify)';
     ES: 'Simulación HAM6 (16 colores base con modos Hold-Modify)'; PT: 'Simulação HAM6 (16 cores base com modos Hold-Modify)'; AF: 'HAM6-simulasie (16 basiskleure met hou-wysig-modusse)'),
    (EN: 'HAM8 simulation (64 base colors with hold-modify modes)'; PL: 'Symulacja HAM8 (64 kolory podstawowe z trybami hold-modify)'; CS: 'Simulace HAM8 (64 základních barev s režimy hold-modify)';
     FR: 'Simulation HAM8 (64 couleurs de base avec modes Hold-Modify)'; DE: 'HAM8-Simulation (64 Grundfarben mit Hold-Modify-Modi)'; IT: 'Simulazione HAM8 (64 colori base con modalità Hold-Modify)';
     ES: 'Simulación HAM8 (64 colores base con modos Hold-Modify)'; PT: 'Simulação HAM8 (64 cores base com modos Hold-Modify)'; AF: 'HAM8-simulasie (64 basiskleure met hou-wysig-modusse)'),
    (EN: 'HAM6'; PL: 'HAM6'; CS: 'HAM6';
     FR: 'HAM6'; DE: 'HAM6'; IT: 'HAM6';
     ES: 'HAM6'; PT: 'HAM6'; AF: 'HAM6'),
    (EN: 'HAM8'; PL: 'HAM8'; CS: 'HAM8';
     FR: 'HAM8'; DE: 'HAM8'; IT: 'HAM8';
     ES: 'HAM8'; PT: 'HAM8'; AF: 'HAM8'),
    (EN: 'Crop to selection'; PL: 'Przytnij do zaznaczenia'; CS: 'Oříznout na výběr';
     FR: 'Recadrer selon la sélection'; DE: 'Auf Auswahl zuschneiden'; IT: 'Ritaglia alla selezione';
     ES: 'Recortar a la selección'; PT: 'Recortar à seleção'; AF: 'Knip na seleksie'),
    (EN: 'Selection size...'; PL: 'Ustaw wymiary zaznaczenia...'; CS: 'Velikost výběru...';
     FR: 'Taille de la sélection…'; DE: 'Auswahlgröße...'; IT: 'Dimensione selezione...';
     ES: 'Tamaño de la selección...'; PT: 'Tamanho da seleção...'; AF: 'Seleksiegrootte...'),
    (EN: 'Save icon...'; PL: 'Zapisz ikonę...'; CS: 'Uložit ikonu...';
     FR: 'Enregistrer l’icône…'; DE: 'Symbol speichern...'; IT: 'Salva icona...';
     ES: 'Guardar icono...'; PT: 'Guardar ícone...'; AF: 'Stoor ikoon...'),
    (EN: 'Icon size:'; PL: 'Rozmiar ikony:'; CS: 'Velikost ikony:';
     FR: 'Taille de l’icône :'; DE: 'Symbolgröße:'; IT: 'Dimensione icona:';
     ES: 'Tamaño del icono:'; PT: 'Tamanho do ícone:'; AF: 'Ikoongrootte:'),
    (EN: 'Icon format:'; PL: 'Format ikony:'; CS: 'Formát ikony:';
     FR: 'Format de l’icône :'; DE: 'Symbolformat:'; IT: 'Formato icona:';
     ES: 'Formato del icono:'; PT: 'Formato do ícone:'; AF: 'Ikoonformaat:'),
    (EN: 'Icon saved.'; PL: 'Ikona zapisana.'; CS: 'Ikona uložena.';
     FR: 'Icône enregistrée.'; DE: 'Symbol gespeichert.'; IT: 'Icona salvata.';
     ES: 'Icono guardado.'; PT: 'Ícone guardado.'; AF: 'Ikoon gestoor.'),
    (EN: 'Warning: this effect is very demanding. For images above 6 MP processing may take 30-60 seconds.'; PL: 'Ten efekt jest bardzo wymagający obliczeniowo.\nDla zdjęć powyżej 6 MP czas może przekroczyć 30–60 sekund.'; CS: 'Varování: tento efekt je velmi náročný. U obrázků nad 6 MP může zpracování trvat 30-60 sekund.';
     FR: 'Attention : cet effet est très exigeant. Pour les images de plus de 6 MP, le traitement peut prendre de 30 à 60 secondes.'; DE: 'Warnung: Dieser Effekt ist sehr aufwendig. Bei Bildern über 6 MP kann die Verarbeitung 30-60 Sekunden dauern.'; IT: 'Avviso: questo effetto richiede molte risorse. Per immagini superiori a 6 MP l''elaborazione può richiedere da 30 a 60 secondi.';
     ES: 'Advertencia: este efecto requiere muchos recursos. En imágenes de más de 6 MP el procesamiento puede tardar entre 30 y 60 segundos.'; PT: 'Aviso: este efeito exige muitos recursos. Para imagens com mais de 6 MP, o processamento pode demorar entre 30 e 60 segundos.'; AF: 'Waarskuwing: hierdie effek is baie veeleisend. Vir beelde bo 6 MP kan verwerking 30-60 sekondes neem.'),
    (EN: 'Continue'; PL: 'Kontynuuj'; CS: 'Pokračovat';
     FR: 'Continuer'; DE: 'Fortsetzen'; IT: 'Continua';
     ES: 'Continuar'; PT: 'Continuar'; AF: 'Gaan voort'),
    (EN: 'Glow...'; PL: 'Blask...'; CS: 'Záře...';
     FR: 'Lueur…'; DE: 'Glühen...'; IT: 'Bagliore...';
     ES: 'Resplandor...'; PT: 'Brilho difuso...'; AF: 'Gloed...'),
    (EN: 'Glow radius:'; PL: 'Promień poświaty:'; CS: 'Poloměr záře:';
     FR: 'Rayon de la lueur :'; DE: 'Glühradius:'; IT: 'Raggio del bagliore:';
     ES: 'Radio del resplandor:'; PT: 'Raio do brilho difuso:'; AF: 'Gloedradius:'),
    (EN: 'Amiga gradient...'; PL: 'Gradient Amiga...'; CS: 'Amiga přechod...';
     FR: 'Dégradé Amiga…'; DE: 'Amiga-Verlauf...'; IT: 'Gradiente Amiga...';
     ES: 'Degradado Amiga...'; PT: 'Gradiente Amiga...'; AF: 'Amiga-gradiënt...'),
    (EN: 'Amiga-style copper gradient overlay'; PL: 'Nakładka gradientu copper w stylu Amiga'; CS: 'Překrytí přechodem ve stylu Amiga copper';
     FR: 'Superposition d’un dégradé copper de style Amiga'; DE: 'Amiga-Coppergradienten-Überlagerung'; IT: 'Sovrapposizione di gradiente copper in stile Amiga';
     ES: 'Superposición de degradado copper al estilo Amiga'; PT: 'Sobreposição de gradiente copper ao estilo Amiga'; AF: 'Amiga-styl koper gradiënt oorleg'),
    (EN: 'Amiga gradient (Agony)...'; PL: 'Amiga gradient (Agony)...'; CS: 'Amiga přechod (Agony)...';
     FR: 'Dégradé Amiga (Agony)…'; DE: 'Amiga-Verlauf (Agony)...'; IT: 'Gradiente Amiga (Agony)...';
     ES: 'Degradado Amiga (Agony)...'; PT: 'Gradiente Amiga (Agony)...'; AF: 'Amiga-gradiënt (Agony)...'),
    (EN: 'Agony-style copper gradient'; PL: 'Gradient copper w stylu Agony'; CS: 'Přechod ve stylu Agony copper';
     FR: 'Dégradé copper de style Agony'; DE: 'Agony-Stil Copper-Gradient'; IT: 'Gradiente copper in stile Agony';
     ES: 'Degradado copper al estilo Agony'; PT: 'Gradiente copper ao estilo Agony'; AF: 'Agony-styl koper gradiënt'),
    (EN: 'Save as Windows icon...'; PL: 'Zapisz jako ikonę Windows...'; CS: 'Uložit jako ikonu Windows...';
     FR: 'Enregistrer comme icône Windows…'; DE: 'Als Windows-Symbol speichern...'; IT: 'Salva come icona di Windows...';
     ES: 'Guardar como icono de Windows...'; PT: 'Guardar como ícone do Windows...'; AF: 'Stoor as Windows-ikoon...'),
    (EN: 'JPEG 2000 quality (0-100, 100=lossless):'; PL: 'Jakość zapisu JPEG 2000 (0–100, 100=bezstratny):'; CS: 'Kvalita JPEG 2000 (0-100, 100=bezeztrátové):';
     FR: 'Qualité JPEG 2000 (0-100, 100 = sans perte) :'; DE: 'JPEG-2000-Qualität (0-100, 100=verlustfrei):'; IT: 'Qualità JPEG 2000 (0-100, 100 = senza perdita):';
     ES: 'Calidad JPEG 2000 (0-100, 100 = sin pérdidas):'; PT: 'Qualidade JPEG 2000 (0-100, 100 = sem perdas):'; AF: 'JPEG 2000-gehalte (0-100, 100=verliesloos):'),
    (EN: 'Incorrect development...'; PL: 'Błędne wywołanie...'; CS: 'Nesprávné vyvolání...';
     FR: 'Développement incorrect…'; DE: 'Fehlentwicklung...'; IT: 'Sviluppo errato...';
     ES: 'Revelado incorrecto...'; PT: 'Revelação incorreta...'; AF: 'Verkeerde ontwikkeling...'),
    (EN: 'Incorrect development — E-6/C-41 simulation'; PL: 'Nieprawidłowe wywołanie — symulacja E-6/C-41'; CS: 'Nesprávné vyvolání — simulace E-6/C-41';
     FR: 'Développement incorrect — simulation E-6/C-41'; DE: 'Fehlentwicklung — E-6/C-41-Simulation'; IT: 'Sviluppo errato — simulazione E-6/C-41';
     ES: 'Revelado incorrecto — simulación E-6/C-41'; PT: 'Revelação incorreta — simulação E-6/C-41'; AF: 'Verkeerde ontwikkeling - E-6/C-41-simulasie'),
    (EN: 'Save icon package (ZIP)...'; PL: 'Zapisz pakiet ikon (ZIP)...'; CS: 'Uložit balíček ikon (ZIP)...';
     FR: 'Enregistrer le pack d’icônes (ZIP)…'; DE: 'Symbolpaket (ZIP) speichern...'; IT: 'Salva pacchetto di icone (ZIP)...';
     ES: 'Guardar paquete de iconos (ZIP)...'; PT: 'Guardar pacote de ícones (ZIP)...'; AF: 'Stoor ikoonpakket (ZIP)...'),
    (EN: 'Rename'; PL: 'Zmień nazwę'; CS: 'Přejmenovat';
     FR: 'Renommer'; DE: 'Umbenennen'; IT: 'Rinomina';
     ES: 'Renombrar'; PT: 'Mudar nome'; AF: 'Hernoem'),
    (EN: 'Language...'; PL: 'Język...'; CS: 'Jazyk...';
     FR: 'Langue…'; DE: 'Sprache...'; IT: 'Lingua...';
     ES: 'Idioma...'; PT: 'Idioma...'; AF: 'Taal...'),
    (EN: 'Settings'; PL: 'Ustawienia'; CS: 'Nastavení';
     FR: 'Paramètres'; DE: 'Einstellungen'; IT: 'Impostazioni';
     ES: 'Configuración'; PT: 'Definições'; AF: 'Instellings'),
    (EN: 'Export quality...'; PL: 'Jakość zapisu...'; CS: 'Kvalita exportu...';
     FR: 'Qualité d’exportation…'; DE: 'Exportqualität...'; IT: 'Qualità di esportazione...';
     ES: 'Calidad de exportación...'; PT: 'Qualidade de exportação...'; AF: 'Uitvoergehalte...'),
    (EN: 'Icon package'; PL: 'Pakiet ikon'; CS: 'Balíček ikon';
     FR: 'Pack d’icônes'; DE: 'Symbolpaket'; IT: 'Pacchetto di icone';
     ES: 'Paquete de iconos'; PT: 'Pacote de ícones'; AF: 'Ikoonpakket'),
    (EN: 'No size selected.'; PL: 'Nie wybrano rozmiaru.'; CS: 'Není vybrána velikost.';
     FR: 'Aucune taille sélectionnée.'; DE: 'Keine Größe ausgewählt.'; IT: 'Nessuna dimensione selezionata.';
     ES: 'No se ha seleccionado ningún tamaño.'; PT: 'Nenhum tamanho selecionado.'; AF: 'Geen grootte gekies nie.'),
    (EN: 'Icon package saved to:'; PL: 'Pakiet ikon zapisano do:'; CS: 'Balíček ikon uložen do:';
     FR: 'Pack d’icônes enregistré dans :'; DE: 'Symbolpaket gespeichert unter:'; IT: 'Pacchetto di icone salvato in:';
     ES: 'Paquete de iconos guardado en:'; PT: 'Pacote de ícones guardado em:'; AF: 'Ikoonpakket gestoor na:'),
    (EN: 'TIFF compression:'; PL: 'Kompresja TIFF:'; CS: 'Komprese TIFF:';
     FR: 'Compression TIFF :'; DE: 'TIFF-Komprimierung:'; IT: 'Compressione TIFF:';
     ES: 'Compresión TIFF:'; PT: 'Compressão TIFF:'; AF: 'TIFF-kompressie:'),
    (EN: 'Select platform:'; PL: 'Wybierz platformę:'; CS: 'Vyberte platformu:';
     FR: 'Choisir la plateforme :'; DE: 'Plattform auswählen:'; IT: 'Seleziona piattaforma:';
     ES: 'Seleccionar plataforma:'; PT: 'Selecionar plataforma:'; AF: 'Kies platform:'),
    (EN: 'Select format:'; PL: 'Wybierz format:'; CS: 'Vyberte formát:';
     FR: 'Choisir le format :'; DE: 'Format auswählen:'; IT: 'Seleziona formato:';
     ES: 'Seleccionar formato:'; PT: 'Selecionar formato:'; AF: 'Kies formaat:'),
    (EN: 'Reset'; PL: 'Resetuj'; CS: 'Resetovat';
     FR: 'Réinitialiser'; DE: 'Zurücksetzen'; IT: 'Ripristina';
     ES: 'Restablecer'; PT: 'Repor'; AF: 'Stel terug'),
    (EN: 'Save current image as an icon'; PL: 'Zapisz bieżący obraz jako ikonę'; CS: 'Uložit aktuální obrázek jako ikonu';
     FR: 'Enregistrer l’image actuelle comme icône'; DE: 'Aktuelles Bild als Symbol speichern'; IT: 'Salva l''immagine corrente come icona';
     ES: 'Guardar la imagen actual como icono'; PT: 'Guardar a imagem atual como ícone'; AF: 'Stoor huidige beeld as ''n ikoon'),
    (EN: 'Save icons in multiple sizes as a ZIP archive'; PL: 'Zapisz ikony w wielu rozmiarach jako archiwum ZIP'; CS: 'Uložit ikony ve více velikostech jako ZIP archiv';
     FR: 'Enregistrer des icônes de plusieurs tailles dans une archive ZIP'; DE: 'Symbole in mehreren Größen als ZIP-Archiv speichern'; IT: 'Salva icone di più dimensioni in un archivio ZIP';
     ES: 'Guardar iconos de varios tamanos en un archivo ZIP'; PT: 'Guardar ícones em vários tamanhos num arquivo ZIP'; AF: 'Stoor ikone in verskeie groottes as ''n ZIP-argief'),
    (EN: 'Start recording a macro'; PL: 'Rozpocznij nagrywanie makra'; CS: 'Spustit nahrávání makra';
     FR: 'Démarrer l’enregistrement d’une macro'; DE: 'Makroaufnahme starten'; IT: 'Avvia la registrazione di una macro';
     ES: 'Iniciar la grabación de una macro'; PT: 'Iniciar gravação de uma macro'; AF: 'Begin opname van makro'),
    (EN: 'Stop recording and save the macro'; PL: 'Zatrzymaj nagrywanie i zapisz makro'; CS: 'Zastavit nahrávání a uložit makro';
     FR: 'Arrêter l’enregistrement et enregistrer la macro'; DE: 'Aufnahme stoppen und Makro speichern'; IT: 'Arresta la registrazione e salva la macro';
     ES: 'Detener la grabación y guardar la macro'; PT: 'Parar a gravação e guardar a macro'; AF: 'Stop opname en stoor die makro'),
    (EN: 'Cancel recording without saving'; PL: 'Anuluj nagrywanie bez zapisywania'; CS: 'Zrušit nahrávání bez uložení';
     FR: 'Annuler l’enregistrement sans enregistrer'; DE: 'Aufnahme abbrechen ohne zu speichern'; IT: 'Annulla la registrazione senza salvare';
     ES: 'Cancelar la grabación sin guardar'; PT: 'Cancelar a gravação sem guardar'; AF: 'Kanselleer opname sonder om te stoor'),
    (EN: 'Play, rename or delete macros'; PL: 'Odtwórz, zmień nazwę lub usuń makra'; CS: 'Spustit, přejmenovat nebo smazat makra';
     FR: 'Lire, renommer ou supprimer des macros'; DE: 'Makros abspielen, umbenennen oder löschen'; IT: 'Riproduci, rinomina o elimina macro';
     ES: 'Reproducir, renombrar o eliminar macros'; PT: 'Reproduzir, mudar nome ou eliminar macros'; AF: 'Speel, hernoem of vee makro''s uit'),
    (EN: 'Change application language'; PL: 'Zmiana języka programu'; CS: 'Změnit jazyk aplikace';
     FR: 'Changer la langue de l’application'; DE: 'Anwendungssprache ändern'; IT: 'Cambia la lingua dell''applicazione';
     ES: 'Cambiar el idioma de la aplicación'; PT: 'Alterar o idioma da aplicação'; AF: 'Verander programtaal'),
    (EN: 'Set JPEG, JPEG 2000 and TIFF export quality'; PL: 'Ustawienie jakości zapisu JPEG, JPEG 2000 a TIFF'; CS: 'Nastavit kvalitu exportu JPEG, JPEG 2000 a TIFF';
     FR: 'Définir la qualité d’exportation JPEG, JPEG 2000 et TIFF'; DE: 'JPEG-, JPEG-2000- und TIFF-Exportqualität festlegen'; IT: 'Imposta la qualità di esportazione di JPEG, JPEG 2000 e TIFF';
     ES: 'Configurar la calidad de exportación de JPEG, JPEG 2000 y TIFF'; PT: 'Definir a qualidade de exportação de JPEG, JPEG 2000 e TIFF'; AF: 'Stel JPEG-, JPEG 2000- en TIFF-uitvoergehalte'),
    (EN: 'About Fotografista'; PL: 'O programie Fotografista'; CS: 'O programu Fotografista';
     FR: 'À propos de Fotografista'; DE: 'Über Fotografista'; IT: 'Informazioni su Fotografista';
     ES: 'Acerca de Fotografista'; PT: 'Acerca do Fotografista'; AF: 'Oor Fotografista'),
    (EN: 'Show keyboard shortcuts'; PL: 'Pokazanie listy skrótów klawiaturowych'; CS: 'Zobrazit klávesové zkratky';
     FR: 'Afficher les raccourcis clavier'; DE: 'Tastenkombinationen anzeigen'; IT: 'Mostra scorciatoie da tastiera';
     ES: 'Mostrar atajos de teclado'; PT: 'Mostrar atalhos de teclado'; AF: 'Wys sleutelbordkortpaaie'),
    (EN: 'Interface...'; PL: 'Interfejs...'; CS: 'Rozhraní...';
     FR: 'Interface…'; DE: 'Oberfläche...'; IT: 'Interfaccia...';
     ES: 'Interfaz...'; PT: 'Interface...'; AF: 'Koppelvlak...'),
    (EN: 'Interface settings'; PL: 'Ustawienia interfejsu'; CS: 'Nastavení rozhraní';
     FR: 'Paramètres de l’interface'; DE: 'Oberflächeneinstellungen'; IT: 'Impostazioni dell''interfaccia';
     ES: 'Configuración de la interfaz'; PT: 'Definições da interface'; AF: 'Koppelvlakinstellings'),
    (EN: 'Interface'; PL: 'Interfejs'; CS: 'Rozhraní';
     FR: 'Interface'; DE: 'Oberfläche'; IT: 'Interfaccia';
     ES: 'Interfaz'; PT: 'Interface'; AF: 'Koppelvlak'),
    (EN: 'Canvas background color (only with standard Windows theme):'; PL: 'Kolor tła kanwy (tylko ze standardowym motywem Windows):'; CS: 'Barva pozadí plátna (pouze se standardním motivem Windows):';
     FR: 'Couleur de fond de la zone de travail (uniquement avec le thème Windows standard) :'; DE: 'Hintergrundfarbe der Leinwand (nur mit dem standardmäßigen Windows-Design):'; IT: 'Colore di sfondo dell''area di lavoro (solo con il tema standard di Windows):';
     ES: 'Color de fondo del lienzo (solo con el tema estándar de Windows):'; PT: 'Cor de fundo da área de trabalho (apenas com o tema padrão do Windows):'; AF: 'Doek agtergrondkleur (slegs met die standaard Windows-tema):'),
    (EN: 'Open image'; PL: 'Otwórz obraz'; CS: 'Otevřít obrázek';
     FR: 'Ouvrir une image'; DE: 'Bild öffnen'; IT: 'Apri immagine';
     ES: 'Abrir imagen'; PT: 'Abrir imagem'; AF: 'Maak beeld oop'),
    (EN: 'All files'; PL: 'Wszystkie pliki'; CS: 'Všechny soubory';
     FR: 'Tous les fichiers'; DE: 'Alle Dateien'; IT: 'Tutti i file';
     ES: 'Todos los archivos'; PT: 'Todos os ficheiros'; AF: 'Alle lêers'),
    (EN: 'Clipboard'; PL: 'Schowek'; CS: 'Schránka';
     FR: 'Presse-papiers'; DE: 'Zwischenablage'; IT: 'Appunti';
     ES: 'Portapapeles'; PT: 'Área de transferência'; AF: 'Knipbord'),
    (EN: 'Pasted'; PL: 'Wklejono'; CS: 'Vloženo';
     FR: 'Collé'; DE: 'Eingefügt'; IT: 'Incollato';
     ES: 'Pegado'; PT: 'Colado'; AF: 'Geplak'),
    (EN: 'LZW'; PL: 'LZW'; CS: 'LZW';
     FR: 'LZW'; DE: 'LZW'; IT: 'LZW';
     ES: 'LZW'; PT: 'LZW'; AF: 'LZW'),
    (EN: 'Flate'; PL: 'Flate'; CS: 'Flate';
     FR: 'Flate'; DE: 'Flate'; IT: 'Flate';
     ES: 'Flate'; PT: 'Flate'; AF: 'Flate'),
    (EN: 'JPEG'; PL: 'JPEG'; CS: 'JPEG';
     FR: 'JPEG'; DE: 'JPEG'; IT: 'JPEG';
     ES: 'JPEG'; PT: 'JPEG'; AF: 'JPEG'),
    (EN: 'New name:'; PL: 'Nowa nazwa'; CS: 'Nový název:';
     FR: 'Nouveau nom :'; DE: 'Neuer Name:'; IT: 'Nuovo nome:';
     ES: 'Nombre nuevo:'; PT: 'Novo nome:'; AF: 'Nuwe naam:'),
    (EN: 'Language / Language'; PL: 'Język / Language'; CS: 'Jazyk / Language';
     FR: 'Langue / Language'; DE: 'Sprache / Language'; IT: 'Lingua / Language';
     ES: 'Idioma / Language'; PT: 'Idioma / Language'; AF: 'Taal / Language'),
    (EN: 'Polski (Polish)'; PL: 'Polski'; CS: 'Polski (Polština)';
     FR: 'Polski (Polonais)'; DE: 'Polski (Polnisch)'; IT: 'Polski (Polacco)';
     ES: 'Polski (Polaco)'; PT: 'Polski (Polonês)'; AF: 'Polski (Pools)'),
    (EN: 'English'; PL: 'English (angielski)'; CS: 'English (Angličtina)';
     FR: 'English (Anglais)'; DE: 'English (Englisch)'; IT: 'English (Inglese)';
     ES: 'English (Inglés)'; PT: 'English (Inglês)'; AF: 'English (Engels)'),
    (EN: 'Selection size'; PL: 'Rozmiar zaznaczenia'; CS: 'Velikost výběru';
     FR: 'Taille de la sélection'; DE: 'Auswahlgröße'; IT: 'Dimensione selezione';
     ES: 'Tamaño de la selección'; PT: 'Tamanho da seleção'; AF: 'Seleksiegrootte'),
    (EN: 'Selection: %d x %d'; PL: 'Zaznaczenie: %d x %d'; CS: 'Výběr: %d × %d';
     FR: 'Sélection : %d x %d'; DE: 'Auswahl: %d x %d'; IT: 'Selezione: %d x %d';
     ES: 'Selección: %d x %d'; PT: 'Seleção: %d x %d'; AF: 'Seleksie: %d x %d'),
    (EN: 'Map to OCS 32-color palette with dithering'; PL: 'Mapowanie do palety OCS 32 kolorów'; CS: 'Mapovat na OCS 32barevnou paletu s ditheringem';
     FR: 'Convertir vers la palette OCS 32 couleurs avec tramage'; DE: 'Auf OCS-32-Farben-Palette mit Dithering abbilden'; IT: 'Converti nella tavolozza OCS a 32 colori con retinatura';
     ES: 'Convertir a la paleta OCS de 32 colores con difuminado'; PT: 'Converter para a paleta OCS de 32 cores com reticulação'; AF: 'Karteer na OCS 32-kleure-palet met dither'),
    (EN: 'Map to EHB 64-color palette with dithering'; PL: 'Mapowanie do palety EHB 64 kolorów (OCS + Half-Brite)'; CS: 'Mapovat na EHB 64barevnou paletu s ditheringem';
     FR: 'Convertir vers la palette EHB 64 couleurs avec tramage'; DE: 'Auf EHB-64-Farben-Palette mit Dithering abbilden'; IT: 'Converti nella tavolozza EHB a 64 colori con retinatura';
     ES: 'Convertir a la paleta EHB de 64 colores con difuminado'; PT: 'Converter para a paleta EHB de 64 cores com reticulação'; AF: 'Karteer na EHB 64-kleure-palet met dither'),
    (EN: 'Map to AGA 256-color palette with dithering'; PL: 'Mapowanie do palety AGA 256 kolorów'; CS: 'Mapovat na AGA 256barevnou paletu s ditheringem';
     FR: 'Convertir vers la palette AGA 256 couleurs avec tramage'; DE: 'Auf AGA-256-Farben-Palette mit Dithering abbilden'; IT: 'Converti nella tavolozza AGA a 256 colori con retinatura';
     ES: 'Convertir a la paleta AGA de 256 colores con difuminado'; PT: 'Converter para a paleta AGA de 256 cores com reticulação'; AF: 'Karteer na AGA 256-kleure-palet met dither'),
    (EN: 'Map to Workbench 256-color palette with dithering'; PL: 'Mapowanie do palety Workbench 256 kolorów'; CS: 'Mapovat na Workbench 256barevnou paletu s ditheringem';
     FR: 'Convertir vers la palette Workbench 256 couleurs avec tramage'; DE: 'Auf Workbench-256-Farben-Palette mit Dithering abbilden'; IT: 'Converti nella tavolozza Workbench a 256 colori con retinatura';
     ES: 'Convertir a la paleta Workbench de 256 colores con difuminado'; PT: 'Converter para a paleta Workbench de 256 cores com reticulação'; AF: 'Karteer na Workbench 256-kleure-palet met dither'),
    (EN: 'Map to MagicWB 8-color palette with dithering'; PL: 'Mapowanie do palety MagicWB 8 kolorów'; CS: 'Mapovat na MagicWB 8barevnou paletu s ditheringem';
     FR: 'Convertir vers la palette MagicWB 8 couleurs avec tramage'; DE: 'Auf MagicWB-8-Farben-Palette mit Dithering abbilden'; IT: 'Converti nella tavolozza MagicWB a 8 colori con retinatura';
     ES: 'Convertir a la paleta MagicWB de 8 colores con difuminado'; PT: 'Converter para a paleta MagicWB de 8 cores com reticulação'; AF: 'Karteer na MagicWB 8-kleure-palet met dither'),
    (EN: 'Hue top (0-360):'; PL: 'Odcień górny (0–360):'; CS: 'Horní odstín (0-360):';
     FR: 'Teinte supérieure (0-360) :'; DE: 'Farbton oben (0-360):'; IT: 'Tonalità superiore (0-360):';
     ES: 'Tono superior (0-360):'; PT: 'Tonalidade superior (0-360):'; AF: 'Tint bo (0-360):'),
    (EN: 'Hue bottom (0-360):'; PL: 'Odcień dół (0–360):'; CS: 'Dolní odstín (0-360):';
     FR: 'Teinte inférieure (0-360) :'; DE: 'Farbton unten (0-360):'; IT: 'Tonalità inferiore (0-360):';
     ES: 'Tono inferior (0-360):'; PT: 'Tonalidade inferior (0-360):'; AF: 'Tint onder (0-360):'),
    (EN: 'Number of bands (32-256):'; PL: 'Liczba pasów (32–256):'; CS: 'Počet pásem (32-256):';
     FR: 'Nombre de bandes (32-256) :'; DE: 'Anzahl der Bänder (32-256):'; IT: 'Numero di bande (32-256):';
     ES: 'Número de bandas (32-256):'; PT: 'Número de bandas (32-256):'; AF: 'Aantal bande (32-256):'),
    (EN: 'E-6 in C-41'; PL: 'E-6 w C-41'; CS: 'E-6 v C-41';
     FR: 'E-6 dans C-41'; DE: 'E-6 in C-41'; IT: 'E-6 in C-41';
     ES: 'E-6 en C-41'; PT: 'E-6 em C-41'; AF: 'E-6 in C-41'),
    (EN: 'C-41 in E-6'; PL: 'C-41 w E-6'; CS: 'C-41 v E-6';
     FR: 'C-41 dans E-6'; DE: 'C-41 in E-6'; IT: 'C-41 in E-6';
     ES: 'C-41 en E-6'; PT: 'C-41 em E-6'; AF: 'C-41 in E-6'),
    (EN: 'Kodak in Fuji developer'; PL: 'Kodak w wywoływaczu Fuji'; CS: 'Kodak ve vývojce Fuji';
     FR: 'Kodak dans révélateur Fuji'; DE: 'Kodak in Fuji-Entwickler'; IT: 'Kodak in sviluppo Fuji';
     ES: 'Kodak en revelador Fuji'; PT: 'Kodak em revelação Fuji'; AF: 'Kodak in Fuji-ontwikkelaar'),
    (EN: 'Fuji in Kodak developer'; PL: 'Fuji w wywoływaczu Kodak'; CS: 'Fuji ve vývojce Kodak';
     FR: 'Fuji dans révélateur Kodak'; DE: 'Fuji in Kodak-Entwickler'; IT: 'Fuji in sviluppo Kodak';
     ES: 'Fuji en revelador Kodak'; PT: 'Fuji em revelação Kodak'; AF: 'Fuji in Kodak-ontwikkelaar'),
    (EN: 'ECN-2 in C-41'; PL: 'ECN-2 w C-41'; CS: 'ECN-2 v C-41';
     FR: 'ECN-2 dans C-41'; DE: 'ECN-2 in C-41'; IT: 'ECN-2 in C-41';
     ES: 'ECN-2 en C-41'; PT: 'ECN-2 em C-41'; AF: 'ECN-2 in C-41'),
    (EN: 'Font size (status bar):'; PL: 'Rozmiar czcionki (pasek statusu):'; CS: 'Velikost písma (stavový řádek):';
     FR: 'Taille de la police (barre d’état) :'; DE: 'Schriftgröße (Statusleiste):'; IT: 'Dimensione carattere (barra di stato):';
     ES: 'Tamaño de fuente (barra de estado):'; PT: 'Tamanho do tipo de letra (barra de estado):'; AF: 'Fontgrootte (statusbalk):'),
    (EN: 'Classic AmigaOS (4 colors)'; PL: 'AmigaOS klasyczny (4 kolory)'; CS: 'Klasický AmigaOS (4 barvy)';
     FR: 'AmigaOS classique (4 couleurs)'; DE: 'Klassisches AmigaOS (4 Farben)'; IT: 'AmigaOS classico (4 colori)';
     ES: 'AmigaOS clásico (4 colores)'; PT: 'AmigaOS clássico (4 cores)'; AF: 'Klassieke AmigaOS (4 kleure)'),
    (EN: 'Tiling...'; PL: 'Kafelkowanie...'; CS: 'Dlaždice...';
     FR: 'Mosaïque…'; DE: 'Kacheln...'; IT: 'Affiancamento...';
     ES: 'Mosaico...'; PT: 'Mosaico...'; AF: 'Teëling...'),
    (EN: 'Tile image to fill target dimensions'; PL: 'Powiel obraz jako kafelki do wypełnienia obszaru'; CS: 'Rozložit obrázek na dlaždice pro vyplnění cílových rozměrů';
     FR: 'Répéter l’image en mosaïque pour remplir les dimensions cibles'; DE: 'Bild kacheln, um Zielgröße zu füllen'; IT: 'Ripeti l''immagine per riempire le dimensioni di destinazione';
     ES: 'Repetir la imagen en mosaico para rellenar las dimensiones de destino'; PT: 'Repetir a imagem para preencher as dimensões de destino'; AF: 'Teël beeld om teikendimensies te vul'),
    (EN: 'Amiga Background...'; PL: 'Tło Amiga...'; CS: 'Amiga pozadí...';
     FR: 'Arrière-plan Amiga…'; DE: 'Amiga-Hintergrund...'; IT: 'Sfondo Amiga...';
     ES: 'Fondo Amiga...'; PT: 'Fundo Amiga...'; AF: 'Amiga-agtergrond...'),
    (EN: 'Target resolution:'; PL: 'Rozdzielczość docelowa:'; CS: 'Cílové rozlišení:';
     FR: 'Résolution cible :'; DE: 'Zielauflösung:'; IT: 'Risoluzione di destinazione:';
     ES: 'Resolución de destino:'; PT: 'Resolução de destino:'; AF: 'Teikenresolusie:'),
    (EN: 'Image alignment:'; PL: 'Wyrównanie obrazu:'; CS: 'Zarovnání obrázku:';
     FR: 'Alignement de l’image :'; DE: 'Bildausrichtung:'; IT: 'Allineamento immagine:';
     ES: 'Alineación de la imagen:'; PT: 'Alinhamento da imagem:'; AF: 'Beeldbelyning:'),
    (EN: 'Background color (MagicWB palette):'; PL: 'Kolor tła (paleta MagicWB):'; CS: 'Barva pozadí (paleta MagicWB):';
     FR: 'Couleur d’arrière-plan (palette MagicWB) :'; DE: 'Hintergrundfarbe (MagicWB-Palette):'; IT: 'Colore di sfondo (tavolozza MagicWB):';
     ES: 'Color de fondo (paleta MagicWB):'; PT: 'Cor de fundo (paleta MagicWB):'; AF: 'Agtergrondkleur (MagicWB-palet):'),
    (EN: 'Grey'; PL: 'Szary'; CS: 'Šedá';
     FR: 'Gris'; DE: 'Grau'; IT: 'Grigio';
     ES: 'Gris'; PT: 'Cinzento'; AF: 'Grys'),
    (EN: 'Black'; PL: 'Czarny'; CS: 'Černá';
     FR: 'Noir'; DE: 'Schwarz'; IT: 'Nero';
     ES: 'Negro'; PT: 'Preto'; AF: 'Swart'),
    (EN: 'White'; PL: 'Biały'; CS: 'Bílá';
     FR: 'Blanc'; DE: 'Weiß'; IT: 'Bianco';
     ES: 'Blanco'; PT: 'Branco'; AF: 'Wit'),
    (EN: 'Blue'; PL: 'Niebieski'; CS: 'Modrá';
     FR: 'Bleu'; DE: 'Blau'; IT: 'Blu';
     ES: 'Azul'; PT: 'Azul'; AF: 'Blou'),
    (EN: 'Dark grey'; PL: 'Ciemny szary'; CS: 'Tmavě šedá';
     FR: 'Gris foncé'; DE: 'Dunkelgrau'; IT: 'Grigio scuro';
     ES: 'Gris oscuro'; PT: 'Cinzento escuro'; AF: 'Donkergrys'),
    (EN: 'Light grey'; PL: 'Jasny szary'; CS: 'Světle šedá';
     FR: 'Gris clair'; DE: 'Hellgrau'; IT: 'Grigio chiaro';
     ES: 'Gris claro'; PT: 'Cinzento claro'; AF: 'Liggrys'),
    (EN: 'Brown'; PL: 'Brązowy'; CS: 'Hnědá';
     FR: 'Marron'; DE: 'Braun'; IT: 'Marrone';
     ES: 'Marrón'; PT: 'Castanho'; AF: 'Bruin'),
    (EN: 'Salmon'; PL: 'Łososiowy'; CS: 'Lososová';
     FR: 'Saumon'; DE: 'Lachs'; IT: 'Salmone';
     ES: 'Salmón'; PT: 'Salmão'; AF: 'Salm'),
    (EN: 'Amiga Background (stretched, MagicWB)...'; PL: 'Tło Amiga (rozciągnięte, MagicWB)...'; CS: 'Amiga pozadí (roztažené, MagicWB)...';
     FR: 'Arrière-plan Amiga (étiré, MagicWB)…'; DE: 'Amiga-Hintergrund (gestreckt, MagicWB)...'; IT: 'Sfondo Amiga (stirato, MagicWB)...';
     ES: 'Fondo Amiga (estirado, MagicWB)...'; PT: 'Fundo Amiga (esticado, MagicWB)...'; AF: 'Amiga-agtergrond (uitgerek, MagicWB)...'),
    (EN: 'Scale image to Amiga resolution with stretched edge fill'; PL: 'Skaluje obraz do rozdzielczości Amigi z rozciąganiem krawędzi'; CS: 'Přizpůsobit obrázek amigovskému rozlišení s roztažením okrajů';
     FR: 'Adapter l’image à la résolution Amiga avec remplissage des bords étiré'; DE: 'Bild auf Amiga-Auflösung mit gestrecktem Rand skalieren'; IT: 'Adatta l''immagine alla risoluzione Amiga con riempimento dei bordi esteso';
     ES: 'Escalar la imagen a la resolución Amiga con relleno de bordes estirado'; PT: 'Ajustar a imagem à resolução Amiga com preenchimento das margens esticado'; AF: 'Skaal beeld na Amiga-resolusie met uitgerekte randvulling'),
    (EN: 'Custom color...'; PL: 'Inny kolor...'; CS: 'Vlastní barva...';
     FR: 'Couleur personnalisée…'; DE: 'Benutzerdefinierte Farbe...'; IT: 'Colore personalizzato...';
     ES: 'Color personalizado...'; PT: 'Cor personalizada...'; AF: 'Aangepaste kleur...'),
    (EN: 'Export...'; PL: 'Eksportuj...'; CS: 'Exportovat...';
     FR: 'Exporter…'; DE: 'Exportieren...'; IT: 'Esporta...';
     ES: 'Exportar...'; PT: 'Exportar...'; AF: 'Voer uit...'),
    (EN: 'Import...'; PL: 'Importuj...'; CS: 'Importovat...';
     FR: 'Importer…'; DE: 'Importieren...'; IT: 'Importa...';
     ES: 'Importar...'; PT: 'Importar...'; AF: 'Voer in...'),
    (EN: 'Export macro'; PL: 'Eksportuj makro'; CS: 'Exportovat makro';
     FR: 'Exporter la macro'; DE: 'Makro exportieren'; IT: 'Esporta macro';
     ES: 'Exportar macro'; PT: 'Exportar macro'; AF: 'Voer makro uit'),
    (EN: 'Macro exported successfully.'; PL: 'Makro zostało pomyślnie wyeksportowane.'; CS: 'Makro úspěšně exportováno.';
     FR: 'Macro exportée avec succès.'; DE: 'Makro erfolgreich exportiert.'; IT: 'Macro esportata con successo.';
     ES: 'Macro exportada correctamente.'; PT: 'Macro exportada com sucesso.'; AF: 'Makro suksesvol uitgevoer.'),
    (EN: 'Import macro'; PL: 'Importuj makro'; CS: 'Importovat makro';
     FR: 'Importer une macro'; DE: 'Makro importieren'; IT: 'Importa macro';
     ES: 'Importar macro'; PT: 'Importar macro'; AF: 'Voer makro in'),
    (EN: 'Invalid macro file.'; PL: 'Nieprawidłowy plik makra.'; CS: 'Neplatný soubor makra.';
     FR: 'Fichier de macro invalide.'; DE: 'Ungültige Makrodatei.'; IT: 'File macro non valido.';
     ES: 'Archivo de macro no válido.'; PT: 'Ficheiro de macro inválido.'; AF: 'Ongeldige makrolêer.'),
    (EN: 'A macro with this name already exists. Overwrite?'; PL: 'Makro o tej nazwie już istnieje. Nadpisać?'; CS: 'Makro s tímto názvem již existuje. Přepsat?';
     FR: 'Une macro portant ce nom existe déjà. La remplacer ?'; DE: 'Ein Makro mit diesem Namen existiert bereits. Überschreiben?'; IT: 'Esiste già una macro con questo nome. Sovrascriverla?';
     ES: 'Ya existe una macro con este nombre. ¿Desea reemplazarla?'; PT: 'Já existe uma macro com este nome. Substituí-la?'; AF: '''n Makro met hierdie naam bestaan reeds. Oorskryf?'),
    (EN: 'Macro imported successfully.'; PL: 'Makro zostało pomyślnie zaimportowane.'; CS: 'Makro úspěšně importováno.';
     FR: 'Macro importée avec succès.'; DE: 'Makro erfolgreich importiert.'; IT: 'Macro importata con successo.';
     ES: 'Macro importada correctamente.'; PT: 'Macro importada com sucesso.'; AF: 'Makro suksesvol ingevoer.'),
    (EN: 'Remember window size and position'; PL: 'Zapamiętuj rozmiar i położenie okna'; CS: 'Zapamatovat velikost a pozici okna';
     FR: 'Mémoriser la taille et la position de la fenêtre'; DE: 'Fenstergröße und -position merken'; IT: 'Ricorda dimensione e posizione della finestra';
     ES: 'Recordar el tamaño y la posición de la ventana'; PT: 'Memorizar o tamanho e a posição da janela'; AF: 'Onthou venstergrootte en posisie'),
    (EN: 'Number of recent files:'; PL: 'Liczba ostatnich plików:'; CS: 'Počet nedávných souborů:';
     FR: 'Nombre de fichiers récents :'; DE: 'Anzahl der zuletzt verwendeten Dateien:'; IT: 'Numero di file recenti:';
     ES: 'Número de archivos recientes:'; PT: 'Número de ficheiros recentes:'; AF: 'Aantal onlangse lêers:'),
    (EN: 'Exit without saving changes'; PL: 'Wyjście bez zapisanych zmian'; CS: 'Ukončit bez uložení změn';
     FR: 'Quitter sans enregistrer les modifications'; DE: 'Beenden ohne Änderungen zu speichern'; IT: 'Esci senza salvare le modifiche';
     ES: 'Salir sin guardar los cambios'; PT: 'Sair sem guardar as alterações'; AF: 'Sluit sonder om veranderinge te stoor'),
    (EN: 'Relief...'; PL: 'Płaskorzeźba...'; CS: 'Reliéf...';
     FR: 'Relief…'; DE: 'Relief...'; IT: 'Rilievo...';
     ES: 'Relieve...'; PT: 'Relevo...'; AF: 'Reliëf...'),
    (EN: 'Material bas-relief from image luminance'; PL: 'Płaskorzeźba materiałowa z jasności obrazu'; CS: 'Materiálový basreliéf z jasu obrázku';
     FR: 'Relief de matériau à partir de la luminance de l’image'; DE: 'Materialrelief aus Bildluminanz'; IT: 'Rilievo del materiale dalla luminanza dell''immagine';
     ES: 'Relieve del material a partir de la luminancia de la imagen'; PT: 'Relevo do material a partir da luminância da imagem'; AF: 'Materiaal-basreliëf van beeldluminessensie'),
    (EN: 'Depth (1-100):'; PL: 'Głębokość (1–100):'; CS: 'Hloubka (1-100):';
     FR: 'Profondeur (1-100) :'; DE: 'Tiefe (1-100):'; IT: 'Profondità (1-100):';
     ES: 'Profundidad (1-100):'; PT: 'Profundidade (1-100):'; AF: 'Diepte (1-100):'),
    (EN: 'Plaster / white stone'; PL: 'Gips / biały kamień'; CS: 'Sádra / bílý kámen';
     FR: 'Plâtre / pierre blanche'; DE: 'Gips / weißer Stein'; IT: 'Gesso / pietra bianca';
     ES: 'Yeso / piedra blanca'; PT: 'Gesso / pedra branca'; AF: 'Pleister / wit klip'),
    (EN: 'White marble'; PL: 'Biały marmur'; CS: 'Bílý mramor';
     FR: 'Marbre blanc'; DE: 'Weißer Marmor'; IT: 'Marmo bianco';
     ES: 'Mármol blanco'; PT: 'Mármore branco'; AF: 'Wit marmer'),
    (EN: 'Gray stone'; PL: 'Szary kamień'; CS: 'Šedý kámen';
     FR: 'Pierre grise'; DE: 'Grauer Stein'; IT: 'Pietra grigia';
     ES: 'Piedra gris'; PT: 'Pedra cinzenta'; AF: 'Grys klip'),
    (EN: 'Bronze / medal'; PL: 'Brąz / medal'; CS: 'Bronz / medaile';
     FR: 'Bronze / médaille'; DE: 'Bronze / Medaille'; IT: 'Bronzo / medaglia';
     ES: 'Bronce / medalla'; PT: 'Bronze / medalha'; AF: 'Brons / medalje'),
    (EN: 'Sandstone'; PL: 'Piaskowiec'; CS: 'Pískovec';
     FR: 'Grès'; DE: 'Sandstein'; IT: 'Arenaria';
     ES: 'Arenisca'; PT: 'Arenito'; AF: 'Sandklip'),
    (EN: 'Scale (%):'; PL: 'Skala (%):'; CS: 'Měřítko (%):';
     FR: 'Échelle (%) :'; DE: 'Maßstab (%):'; IT: 'Scala (%):';
     ES: 'Escala (%):'; PT: 'Escala (%):'; AF: 'Skaal (%):'),
    (EN: 'Keep aspect ratio'; PL: 'Zachowaj proporcje'; CS: 'Zachovat poměr stran';
     FR: 'Conserver les proportions'; DE: 'Seitenverhältnis beibehalten'; IT: 'Mantieni proporzioni';
     ES: 'Mantener la relación de aspecto'; PT: 'Manter a proporção'; AF: 'Hou aspekverhouding'),
    (EN: 'Emergo...'; PL: 'Emergo...'; CS: 'Emergo...';
     FR: 'Emergo…'; DE: 'Emergo...'; IT: 'Emergo...';
     ES: 'Emergo...'; PT: 'Emergo...'; AF: 'Emergo...'),
    (EN: 'Français (French)'; PL: 'Français (francuski)'; CS: 'Français (Francouzština)';
     FR: 'Français'; DE: 'Français (Französisch)'; IT: 'Français (Francese)';
     ES: 'Français (Francés)'; PT: 'Français (Francês)'; AF: 'Français (Frans)'),
    (EN: 'Español (Spanish)'; PL: 'Español (hiszpański)'; CS: 'Español (Španělština)';
     FR: 'Español (Espagnol)'; DE: 'Español (Spanisch)'; IT: 'Español (Spagnolo)';
     ES: 'Español'; PT: 'Español (Espanhol)'; AF: 'Español (Spaans)'),
    (EN: 'Italiano (Italian)'; PL: 'Italiano (włoski)'; CS: 'Italiano (Italština)';
     FR: 'Italiano (Italien)'; DE: 'Italiano (Italienisch)'; IT: 'Italiano';
     ES: 'Italiano'; PT: 'Italiano'; AF: 'Italiano (Italiaans)'),
    (EN: 'Deutsch (German)'; PL: 'Deutsch (niemiecki)'; CS: 'Deutsch (Němčina)';
     FR: 'Deutsch (Allemand)'; DE: 'Deutsch'; IT: 'Deutsch (Tedesco)';
     ES: 'Deutsch (Alemán)'; PT: 'Deutsch (Alemão)'; AF: 'Deutsch (Duits)'),
    (EN: 'Edit macro'; PL: 'Edytuj makro'; CS: 'Upravit makro';
     FR: 'Modifier la macro'; DE: 'Makro bearbeiten'; IT: 'Modifica macro';
     ES: 'Editar macro'; PT: 'Editar macro'; AF: 'Wysig makro'),
    (EN: 'Remove step'; PL: 'Usuń krok'; CS: 'Odebrat krok';
     FR: 'Supprimer l’étape'; DE: 'Schritt entfernen'; IT: 'Rimuovi passaggio';
     ES: 'Eliminar paso'; PT: 'Remover passo'; AF: 'Verwyder stap'),
    (EN: 'Manual'; PL: 'Ręcznie'; CS: 'Ruční';
     FR: 'Manuel'; DE: 'Manuell'; IT: 'Manuale';
     ES: 'Manual'; PT: 'Manual'; AF: 'Handmatig'),
    (EN: 'Automatic'; PL: 'Automatycznie'; CS: 'Automatické';
     FR: 'Automatique'; DE: 'Automatisch'; IT: 'Automatico';
     ES: 'Automático'; PT: 'Automático'; AF: 'Outomaties'),
    (EN: 'Operation completed.'; PL: 'Operacja zakończona.'; CS: 'Operace dokončena.';
     FR: 'Opération terminée.'; DE: 'Vorgang abgeschlossen.'; IT: 'Operazione completata.';
     ES: 'Operación completada.'; PT: 'Operação concluída.'; AF: 'Bewerking voltooi.'),
    (EN: 'The result is ready.'; PL: 'Wynik jest gotowy.'; CS: 'Výsledek je připraven.';
     FR: 'Le résultat est prêt.'; DE: 'Das Ergebnis ist bereit.'; IT: 'Il risultato è pronto.';
     ES: 'El resultado está listo.'; PT: 'O resultado está pronto.'; AF: 'Die resultaat is gereed.'),
    (EN: 'You can return to your computer.'; PL: 'Możesz wrócić do komputera.'; CS: 'Můžete se vrátit k počítači.';
     FR: 'Vous pouvez retourner à votre ordinateur.'; DE: 'Sie können zu Ihrem Computer zurückkehren.'; IT: 'Puoi tornare al computer.';
     ES: 'Puede volver a su ordenador.'; PT: 'Pode voltar ao computador.'; AF: 'U kan na u rekenaar terugkeer.'),
    (EN: 'Your coffee has probably gone cold.'; PL: 'Kawa pewnie już wystygła.'; CS: 'Vaše káva pravděpodobně vychladla.';
     FR: 'Votre café a probablement refroidi.'; DE: 'Ihr Kaffee ist wahrscheinlich kalt geworden.'; IT: 'Probabilmente il tuo caffè si è raffreddato.';
     ES: 'Es probable que su café ya se haya enfriado.'; PT: 'Provavelmente o seu café já arrefeceu.'; AF: 'U koffie het waarskynlik koud geword.'),
    (EN: 'Congratulations. The CPU survived.'; PL: 'Gratulacje. Procesor przeżył.'; CS: 'Gratulujeme. CPU přežil.';
     FR: 'Félicitations. Le processeur a survécu.'; DE: 'Glückwunsch! Die CPU hat überlebt.'; IT: 'Congratulazioni. La CPU è sopravvissuta.';
     ES: 'Enhorabuena. La CPU ha sobrevivido.'; PT: 'Parabéns. O CPU sobreviveu.'; AF: 'Geluk. Die SVE het oorleef.'),
    (EN: 'I thought this would never end.'; PL: 'Myślałem, że to się już nigdy nie skończy.'; CS: 'Myslel jsem, že to nikdy neskončí.';
     FR: 'Je pensais que cela ne finirait jamais.'; DE: 'Ich dachte, das würde nie enden.'; IT: 'Pensavo che non sarebbe mai finita.';
     ES: 'Pensé que esto nunca terminaría.'; PT: 'Pensei que isto nunca mais acabava.'; AF: 'Ek het gedink dit sou nooit eindig nie.'),
    (EN: 'Hallelujah! At last.'; PL: 'Alleluja! Nareszcie.'; CS: 'Haleluja! Konečně.';
     FR: 'Alléluia ! Enfin.'; DE: 'Halleluja! Endlich.'; IT: 'Alleluia! Finalmente.';
     ES: '¡Aleluya! Por fin.'; PT: 'Aleluia! Finalmente.'; AF: 'Halleluja! Uiteindelik.'),
    (EN: 'It worked. Everything is ready.'; PL: 'Udało się. Wszystko gotowe.'; CS: 'Fungovalo to. Vše je připraveno.';
     FR: 'Ça a fonctionné. Tout est prêt.'; DE: 'Es hat funktioniert. Alles ist bereit.'; IT: 'Ha funzionato. È tutto pronto.';
     ES: 'Ha funcionado. Todo está listo.'; PT: 'Funcionou. Está tudo pronto.'; AF: 'Dit het gewerk. Alles is gereed.'),
    (EN: 'End of waiting.'; PL: 'Koniec oczekiwania.'; CS: 'Konec čekání.';
     FR: 'Fin de l’attente.'; DE: 'Warten beendet.'; IT: 'Fine dell''attesa.';
     ES: 'Fin de la espera.'; PT: 'Fim da espera.'; AF: 'Einde van wag.'),
    (EN: 'Thank you for your patience.'; PL: 'Dziękujemy za cierpliwość.'; CS: 'Děkujeme za trpělivost.';
     FR: 'Merci pour votre patience.'; DE: 'Vielen Dank für Ihre Geduld.'; IT: 'Grazie per la pazienza.';
     ES: 'Gracias por su paciencia.'; PT: 'Obrigado pela sua paciência.'; AF: 'Dankie vir u geduld.'),
    (EN: 'Emergo — intelligent shadow detail recovery'; PL: 'Emergo — inteligentne wydobycie szczegółów z cieni'; CS: 'Emergo — inteligentní obnova detailů stínů';
     FR: 'Emergo — récupération intelligente des détails dans les ombres'; DE: 'Emergo — intelligente Schattenaufhellung'; IT: 'Emergo — recupero intelligente dei dettagli nelle ombre';
     ES: 'Emergo — recuperación inteligente de detalles en las sombras'; PT: 'Emergo — recuperação inteligente dos detalhes nas sombras'; AF: 'Emergo — intelligente herstel van skadubesonderhede'),
    (EN: 'Preview 100%'; PL: 'Podgląd 100%'; CS: 'Náhled 100%';
     FR: 'Aperçu 100 %'; DE: 'Vorschau 100%'; IT: 'Anteprima 100%';
     ES: 'Vista previa al 100 %'; PT: 'Pré-visualização a 100%'; AF: 'Voorskou 100%'),
    (EN: 'HAM simulation'; PL: 'Symulacja HAM'; CS: 'Simulace HAM';
     FR: 'Simulation HAM'; DE: 'HAM-Simulation'; IT: 'Simulazione HAM';
     ES: 'Simulación HAM'; PT: 'Simulação HAM'; AF: 'HAM-simulasie'),
    (EN: 'This effect is extremely demanding.\nFor images above 2 MP processing may take several minutes.'; PL: 'Ten efekt jest wyjątkowo wymagający obliczeniowo.\nDla zdjęć powyżej 2 MP czas może wynieść kilka minut.'; CS: 'Tento efekt je extrémně náročný.\nU obrázků nad 2 MP může zpracování trvat několik minut.';
     FR: 'Cet effet est extrêmement exigeant.\nPour les images de plus de 2 MP, le traitement peut prendre plusieurs minutes.'; DE: 'Dieser Effekt ist extrem rechenintensiv.\nBei Bildern über 2 MP kann die Verarbeitung mehrere Minuten dauern.'; IT: 'Questo effetto richiede moltissime risorse.\nPer immagini superiori a 2 MP l''elaborazione può richiedere diversi minuti.';
     ES: 'Este efecto requiere muchísimos recursos.\nEn imágenes de más de 2 MP el procesamiento puede tardar varios minutos.'; PT: 'Este efeito exige muitos recursos.\nPara imagens com mais de 2 MP, o processamento pode demorar vários minutos.'; AF: 'Hierdie effek is uiters veeleisend.\nVir beelde groter as 2 MP kan verwerking etlike minute duur.'),
    (EN: 'Fake bokeh...'; PL: 'Sztuczne bokeh...'; CS: 'Falešný bokeh...';
     FR: 'Faux bokeh…'; DE: 'Künstlicher Bokeh...'; IT: 'Falso bokeh...';
     ES: 'Bokeh falso...'; PT: 'Bokeh falso...'; AF: 'Vals bokeh...'),
    (EN: 'Tilt-shift (miniature)...'; PL: 'Makieta...'; CS: 'Tilt-shift (miniatura)...';
     FR: 'Tilt-shift (miniature)…'; DE: 'Tilt-Shift (Miniatur)...'; IT: 'Tilt-shift (miniatura)...';
     ES: 'Tilt-shift (miniatura)...'; PT: 'Tilt-shift (miniatura)...'; AF: 'Kantel-skuif (miniatuur)...'),
    (EN: 'Graduated blur'; PL: 'Sztuczne bokeh'; CS: 'Plynulé rozmazání';
     FR: 'Flou progressif'; DE: 'Verlaufsweichzeichnung'; IT: 'Sfocatura graduata';
     ES: 'Desenfoque gradual'; PT: 'Desfocagem gradual'; AF: 'Gegradueerde vervaging'),
    (EN: 'Strength:'; PL: 'Siła:'; CS: 'Síla:';
     FR: 'Force :'; DE: 'Stärke:'; IT: 'Intensità:';
     ES: 'Intensidad:'; PT: 'Intensidade:'; AF: 'Sterkte:'),
    (EN: 'Shape:'; PL: 'Kształt:'; CS: 'Tvar:';
     FR: 'Forme :'; DE: 'Form:'; IT: 'Forma:';
     ES: 'Forma:'; PT: 'Forma:'; AF: 'Vorm:'),
    (EN: 'Radial (bokeh)'; PL: 'Radialny (bokeh)'; CS: 'Radiální (bokeh)';
     FR: 'Radial (bokeh)'; DE: 'Radial (Bokeh)'; IT: 'Radiale (bokeh)';
     ES: 'Radial (bokeh)'; PT: 'Radial (bokeh)'; AF: 'Radiaal (bokeh)'),
    (EN: 'Linear (tilt-shift)'; PL: 'Liniowy (tilt-shift)'; CS: 'Lineární (tilt-shift)';
     FR: 'Linéaire (tilt-shift)'; DE: 'Linear (Tilt-Shift)'; IT: 'Lineare (tilt-shift)';
     ES: 'Lineal (tilt-shift)'; PT: 'Linear (tilt-shift)'; AF: 'Lineêr (kantel-skuif)'),
    (EN: 'CMYK misregistration...'; PL: 'Błąd CMYK...'; CS: 'CMYK neregistrace...';
     FR: 'Décalage CMJN…'; DE: 'CMYK-Fehlregistrierung...'; IT: 'Disallineamento CMYK...';
     ES: 'Desalineación CMYK...'; PT: 'Desalinhamento CMYK...'; AF: 'CMYK-misregistrasie...'),
    (EN: 'CMYK misregistration'; PL: 'Błąd CMYK'; CS: 'CMYK neregistrace';
     FR: 'Décalage CMJN'; DE: 'CMYK-Fehlregistrierung'; IT: 'Disallineamento CMYK';
     ES: 'Desalineación CMYK'; PT: 'Desalinhamento CMYK'; AF: 'CMYK-misregistrasie'),
    (EN: 'Shift strength:'; PL: 'Siła przesunięcia:'; CS: 'Síla posunu:';
     FR: 'Intensité du décalage :'; DE: 'Versatz:'; IT: 'Intensità dello spostamento:';
     ES: 'Intensidad del desplazamiento:'; PT: 'Intensidade do desvio:'; AF: 'Verskuiwingssterkte:'),
    (EN: 'Tritone...'; PL: 'Trójkolor...'; CS: 'Tritón...';
     FR: 'Triton…'; DE: 'Triton...'; IT: 'Tritono...';
     ES: 'Tritono...'; PT: 'Tritom...'; AF: 'Driekleur...'),
    (EN: 'Tritone'; PL: 'Trójkolor'; CS: 'Tritón';
     FR: 'Triton'; DE: 'Triton'; IT: 'Tritono';
     ES: 'Tritono'; PT: 'Tritom'; AF: 'Driekleur'),
    (EN: 'Quad-tone...'; PL: 'Czterokolor...'; CS: 'Kvadrón...';
     FR: 'Quadrichromie tonale…'; DE: 'Quad-Ton...'; IT: 'Quadritono...';
     ES: 'Cuadritono...'; PT: 'Quadritom...'; AF: 'Vierkleur...'),
    (EN: 'Quad-tone'; PL: 'Czterokolor'; CS: 'Kvadrón';
     FR: 'Quadrichromie tonale'; DE: 'Quad-Ton'; IT: 'Quadritono';
     ES: 'Cuadritono'; PT: 'Quadritom'; AF: 'Vierkleur'),
    (EN: 'Color 1 (shadows):'; PL: 'Kolor 1 (cienie)'; CS: 'Barva 1 (stíny):';
     FR: 'Couleur 1 (ombres) :'; DE: 'Farbe 1 (Schatten):'; IT: 'Colore 1 (ombre):';
     ES: 'Color 1 (sombras):'; PT: 'Cor 1 (sombras):'; AF: 'Kleur 1 (skaduwees):'),
    (EN: 'Color 2 (midtones):'; PL: 'Kolor 2 (półtony)'; CS: 'Barva 2 (střední tóny):';
     FR: 'Couleur 2 (tons moyens) :'; DE: 'Farbe 2 (Mitteltöne):'; IT: 'Colore 2 (toni medi):';
     ES: 'Color 2 (tonos medios):'; PT: 'Cor 2 (tons médios):'; AF: 'Kleur 2 (middeltone):'),
    (EN: 'Color 3 (highlights):'; PL: 'Kolor 3 (światła)'; CS: 'Barva 3 (světla):';
     FR: 'Couleur 3 (hautes lumières) :'; DE: 'Farbe 3 (Lichter):'; IT: 'Colore 3 (alte luci):';
     ES: 'Color 3 (altas luces):'; PT: 'Cor 3 (altas luzes):'; AF: 'Kleur 3 (hoogtepunte):'),
    (EN: 'Color 4 (extreme highlights):'; PL: 'Kolor 4 (ekstremalne światła)'; CS: 'Barva 4 (extrémní světla):';
     FR: 'Couleur 4 (hautes lumières extrêmes) :'; DE: 'Farbe 4 (Spitzlichter):'; IT: 'Colore 4 (luci estreme):';
     ES: 'Color 4 (luces extremas):'; PT: 'Cor 4 (luzes extremas):'; AF: 'Kleur 4 (uiterste hoogtepunte):'),
    (EN: 'Chromatic aberration...'; PL: 'Aberracja chromatyczna...'; CS: 'Chromatická aberace...';
     FR: 'Aberration chromatique…'; DE: 'Chromatische Aberration...'; IT: 'Aberrazione cromatica...';
     ES: 'Aberración cromática...'; PT: 'Aberração cromática...'; AF: 'Chromatiese aberrasie...'),
    (EN: 'Chromatic aberration'; PL: 'Aberracja chromatyczna'; CS: 'Chromatická aberace';
     FR: 'Aberration chromatique'; DE: 'Chromatische Aberration'; IT: 'Aberrazione cromatica';
     ES: 'Aberración cromática'; PT: 'Aberração cromática'; AF: 'Chromatiese aberrasie'),
    (EN: 'Shift:'; PL: 'Przesunięcie'; CS: 'Posun:';
     FR: 'Décalage :'; DE: 'Versatz:'; IT: 'Spostamento:';
     ES: 'Desplazamiento:'; PT: 'Desvio:'; AF: 'Verskuiwing:'),
    (EN: 'Centrum X:'; PL: 'Centrum X:'; CS: 'Střed X:';
     FR: 'Centre X :'; DE: 'Mitte X:'; IT: 'Centro X:';
     ES: 'Centro X:'; PT: 'Centro X:'; AF: 'Sentrum X:'),
    (EN: 'Centrum Y:'; PL: 'Centrum Y:'; CS: 'Střed Y:';
     FR: 'Centre Y :'; DE: 'Mitte Y:'; IT: 'Centro Y:';
     ES: 'Centro Y:'; PT: 'Centro Y:'; AF: 'Sentrum Y:'),
    (EN: 'Radius:'; PL: 'Promień:'; CS: 'Poloměr:';
     FR: 'Rayon :'; DE: 'Radius:'; IT: 'Raggio:';
     ES: 'Radio:'; PT: 'Raio:'; AF: 'Radius:'),
    (EN: 'Falloff:'; PL: 'Zanik:'; CS: 'Útlum:';
     FR: 'Atténuation :'; DE: 'Abfall:'; IT: 'Attenuazione:';
     ES: 'Atenuación:'; PT: 'Atenuação:'; AF: 'Verval:'),
    (EN: 'Band position:'; PL: 'Pozycja pasa:'; CS: 'Pozice pásma:';
     FR: 'Position de la bande :'; DE: 'Bandposition:'; IT: 'Posizione della banda:';
     ES: 'Posición de la banda:'; PT: 'Posição da faixa:'; AF: 'Bandposisie:'),
    (EN: 'Band height:'; PL: 'Wysokość pasa:'; CS: 'Výška pásma:';
     FR: 'Hauteur de la bande :'; DE: 'Bandhöhe:'; IT: 'Altezza della banda:';
     ES: 'Altura de la banda:'; PT: 'Altura da faixa:'; AF: 'Bandhoogte:'),
    (EN: 'Other retro computers'; PL: 'Inne retrokomputery'; CS: 'Ostatní retro počítače';
     FR: 'Autres ordinateurs rétro'; DE: 'Andere Retro-Systeme'; IT: 'Altri computer retro';
     ES: 'Otros ordenadores retro'; PT: 'Outros computadores retro'; AF: 'Ander retro-rekenaars'),
    (EN: 'C64 — Pepto / Colodore...'; PL: 'C64 — Pepto / Colodore...'; CS: 'C64 — Pepto / Colodore...';
     FR: 'C64 — Pepto / Colodore…'; DE: 'Commodore 64 — Pepto / Colodore...'; IT: 'C64 — Pepto / Colodore...';
     ES: 'C64 — Pepto / Colodore...'; PT: 'C64 — Pepto / Colodore...'; AF: 'C64 — Pepto / Colodore...'),
    (EN: 'Commodore 64 palette — Pepto or Colodore'; PL: 'Paleta Commodore 64 — Pepto lub Colodore'; CS: 'Paleta Commodore 64 — Pepto nebo Colodore';
     FR: 'Palette Commodore 64 — Pepto ou Colodore'; DE: 'Commodore-64-Palette — Pepto oder Colodore'; IT: 'Tavolozza Commodore 64 — Pepto o Colodore';
     ES: 'Paleta Commodore 64 — Pepto o Colodore'; PT: 'Paleta Commodore 64 — Pepto ou Colodore'; AF: 'Commodore 64-palet — Pepto of Colodore'),
    (EN: 'Commodore 64'; PL: 'Commodore 64'; CS: 'Commodore 64';
     FR: 'Commodore 64'; DE: 'Commodore 64'; IT: 'Commodore 64';
     ES: 'Commodore 64'; PT: 'Commodore 64'; AF: 'Commodore 64'),
    (EN: 'Map to Commodore 64 palette with dithering'; PL: 'Mapowanie do palety Commodore 64'; CS: 'Mapovat na paletu Commodore 64 s ditheringem';
     FR: 'Convertir vers la palette Commodore 64 avec tramage'; DE: 'Auf Commodore-64-Palette mit Dithering abbilden'; IT: 'Converti nella tavolozza Commodore 64 con retinatura';
     ES: 'Convertir a la paleta Commodore 64 con difuminado'; PT: 'Converter para a paleta Commodore 64 com reticulação'; AF: 'Karteer na Commodore 64-palet met dither'),
    (EN: 'Pepto'; PL: 'Pepto'; CS: 'Pepto';
     FR: 'Pepto'; DE: 'Pepto'; IT: 'Pepto';
     ES: 'Pepto'; PT: 'Pepto'; AF: 'Pepto'),
    (EN: 'Colodore'; PL: 'Colodore'; CS: 'Colodore';
     FR: 'Colodore'; DE: 'Colodore'; IT: 'Colodore';
     ES: 'Colodore'; PT: 'Colodore'; AF: 'Colodore'),
    (EN: 'ZX Spectrum...'; PL: 'ZX Spectrum...'; CS: 'ZX Spectrum...';
     FR: 'ZX Spectrum…'; DE: 'ZX Spectrum...'; IT: 'ZX Spectrum...';
     ES: 'ZX Spectrum...'; PT: 'ZX Spectrum...'; AF: 'ZX Spectrum...'),
    (EN: 'ZX Spectrum palette'; PL: 'Paleta ZX Spectrum'; CS: 'Paleta ZX Spectrum';
     FR: 'Palette ZX Spectrum'; DE: 'ZX-Spectrum-Palette'; IT: 'Tavolozza ZX Spectrum';
     ES: 'Paleta ZX Spectrum'; PT: 'Paleta ZX Spectrum'; AF: 'ZX Spectrum-palet'),
    (EN: 'ZX Spectrum'; PL: 'ZX Spectrum'; CS: 'ZX Spectrum';
     FR: 'ZX Spectrum'; DE: 'ZX Spectrum'; IT: 'ZX Spectrum';
     ES: 'ZX Spectrum'; PT: 'ZX Spectrum'; AF: 'ZX Spectrum'),
    (EN: 'Map to ZX Spectrum palette with dithering'; PL: 'Mapowanie do palety ZX Spectrum'; CS: 'Mapovat na paletu ZX Spectrum s ditheringem';
     FR: 'Convertir vers la palette ZX Spectrum avec tramage'; DE: 'Auf ZX-Spectrum-Palette mit Dithering abbilden'; IT: 'Converti nella tavolozza ZX Spectrum con retinatura';
     ES: 'Convertir a la paleta ZX Spectrum con difuminado'; PT: 'Converter para a paleta ZX Spectrum com reticulação'; AF: 'Karteer na ZX Spectrum-palet met dither'),
    (EN: 'Game Boy — DMG / Pocket...'; PL: 'Game Boy — DMG / Pocket...'; CS: 'Game Boy — DMG / Pocket...';
     FR: 'Game Boy — DMG / Pocket…'; DE: 'Game Boy — DMG / Pocket...'; IT: 'Game Boy — DMG / Pocket...';
     ES: 'Game Boy — DMG / Pocket...'; PT: 'Game Boy — DMG / Pocket...'; AF: 'Game Boy — DMG / Pocket...'),
    (EN: 'Game Boy palette — DMG (green) or Pocket (gray)'; PL: 'Paleta Game Boy — DMG (zielona) albo Pocket (szara)'; CS: 'Paleta Game Boy — DMG (zelená) nebo Pocket (šedá)';
     FR: 'Palette Game Boy — DMG (verte) ou Pocket (grise)'; DE: 'Game-Boy-Palette — DMG (grün) oder Pocket (grau)'; IT: 'Tavolozza Game Boy — DMG (verde) o Pocket (grigia)';
     ES: 'Paleta Game Boy — DMG (verde) o Pocket (gris)'; PT: 'Paleta Game Boy — DMG (verde) ou Pocket (cinzenta)'; AF: 'Game Boy-palet — DMG (groen) of Pocket (grys)'),
    (EN: 'Game Boy'; PL: 'Game Boy'; CS: 'Game Boy';
     FR: 'Game Boy'; DE: 'Game Boy'; IT: 'Game Boy';
     ES: 'Game Boy'; PT: 'Game Boy'; AF: 'Game Boy'),
    (EN: 'Map to Game Boy palette with dithering'; PL: 'Mapowanie do palety Game Boy'; CS: 'Mapovat na paletu Game Boy s ditheringem';
     FR: 'Convertir vers la palette Game Boy avec tramage'; DE: 'Auf Game-Boy-Palette mit Dithering abbilden'; IT: 'Converti nella tavolozza Game Boy con retinatura';
     ES: 'Convertir a la paleta Game Boy con difuminado'; PT: 'Converter para a paleta Game Boy com reticulação'; AF: 'Karteer na Game Boy-palet met dither'),
    (EN: 'DMG (green)'; PL: 'DMG (zielony)'; CS: 'DMG (zelená)';
     FR: 'DMG (vert)'; DE: 'DMG (grün)'; IT: 'DMG (verde)';
     ES: 'DMG (verde)'; PT: 'DMG (verde)'; AF: 'DMG (groen)'),
    (EN: 'Pocket (gray)'; PL: 'Pocket (szary)'; CS: 'Pocket (šedá)';
     FR: 'Pocket (gris)'; DE: 'Pocket (grau)'; IT: 'Pocket (grigia)';
     ES: 'Pocket (gris)'; PT: 'Pocket (cinzenta)'; AF: 'Pocket (grys)'),
    (EN: 'NES (Nestopia)...'; PL: 'NES (Nestopia)...'; CS: 'NES (Nestopia)...';
     FR: 'NES (Nestopia)…'; DE: 'NES (Nestopia)...'; IT: 'NES (Nestopia)...';
     ES: 'NES (Nestopia)...'; PT: 'NES (Nestopia)...'; AF: 'NES (Nestopia)...'),
    (EN: 'NES palette (Nestopia)'; PL: 'Paleta NES (Nestopia)'; CS: 'Paleta NES (Nestopia)';
     FR: 'Palette NES (Nestopia)'; DE: 'NES-Palette (Nestopia)'; IT: 'Tavolozza NES (Nestopia)';
     ES: 'Paleta NES (Nestopia)'; PT: 'Paleta NES (Nestopia)'; AF: 'NES-palet (Nestopia)'),
    (EN: 'NES — Nestopia'; PL: 'NES — Nestopia'; CS: 'NES — Nestopia';
     FR: 'NES — Nestopia'; DE: 'NES — Nestopia'; IT: 'NES — Nestopia';
     ES: 'NES — Nestopia'; PT: 'NES — Nestopia'; AF: 'NES — Nestopia'),
    (EN: 'Map to NES Nestopia palette with dithering'; PL: 'Mapowanie do palety NES Nestopia'; CS: 'Mapovat na paletu NES Nestopia s ditheringem';
     FR: 'Convertir vers la palette NES Nestopia avec tramage'; DE: 'Auf NES-Nestopia-Palette mit Dithering abbilden'; IT: 'Converti nella tavolozza NES Nestopia con retinatura';
     ES: 'Convertir a la paleta NES Nestopia con difuminado'; PT: 'Converter para a paleta NES Nestopia com reticulação'; AF: 'Karteer na NES Nestopia-palet met dither'),
    (EN: 'Pattern (retro)'; PL: 'Wzór (retro)'; CS: 'Vzor (retro)';
     FR: 'Motif (rétro)'; DE: 'Muster (Retro)'; IT: 'Motivo (retro)';
     ES: 'Patrón (retro)'; PT: 'Padrão (retro)'; AF: 'Patroon (retro)'),
    (EN: 'Floyd–Steinberg (smooth)'; PL: 'Floyd-Steinberg (wygładzony)'; CS: 'Floyd–Steinberg (hladký)';
     FR: 'Floyd–Steinberg (lissé)'; DE: 'Floyd–Steinberg (weich)'; IT: 'Floyd–Steinberg (uniforme)';
     ES: 'Floyd–Steinberg (suave)'; PT: 'Floyd–Steinberg (suave)'; AF: 'Floyd–Steinberg (glad)'),
    (EN: 'The selected mode is very slow for large images.\nFor images above 2 MP preview and applying the effect may take several minutes.\nOther modes are much faster.'; PL: 'Wybrany tryb jest bardzo wolny dla dużych zdjęć.\nDla zdjęć powyżej 2 MP podgląd i zastosowanie efektu mogą zająć kilka minut.\nInne tryby są znacznie szybsze.'; CS: 'Vybraný režim je velmi pomalý pro velké obrázky.\nU obrázků nad 2 MP může náhled a aplikace efektu trvat několik minut.\nJiné režimy jsou mnohem rychlejší.';
     FR: 'Le mode sélectionné est très lent pour les grandes images.\nPour les images de plus de 2 MP, l’aperçu et l’application de l’effet peuvent prendre plusieurs minutes.\nLes autres modes sont beaucoup plus rapides.'; DE: 'Der gewählte Modus ist bei großen Bildern sehr langsam.\nBei Bildern über 2 MP können Vorschau und Anwendung des Effekts mehrere Minuten dauern.\nAndere Modi sind deutlich schneller.'; IT: 'La modalità selezionata è molto lenta per immagini di grandi dimensioni.\nPer immagini superiori a 2 MP l''anteprima e l''applicazione dell''effetto possono richiedere diversi minuti.\nLe altre modalità sono molto più veloci.';
     ES: 'El modo seleccionado es muy lento para imágenes grandes.\nEn imágenes de más de 2 MP, la vista previa y la aplicación del efecto pueden tardar varios minutos.\nLos demás modos son mucho más rápidos.'; PT: 'O modo selecionado é muito lento para imagens grandes.\nPara imagens com mais de 2 MP, a pré-visualização e a aplicação do efeito podem demorar vários minutos.\nOs outros modos são muito mais rápidos.'; AF: 'Die geselekteerde modus is baie stadig vir groot beelde.\nVir beelde groter as 2 MP kan voorskou en toepassing van die effek etlike minute duur.\nAnder modusse is baie vinniger.'),
    (EN: 'Performance...'; PL: 'Wydajność...'; CS: 'Výkon...';
     FR: 'Performances…'; DE: 'Leistung...'; IT: 'Prestazioni...';
     ES: 'Rendimiento...'; PT: 'Desempenho...'; AF: 'Werkverrigting...'),
    (EN: 'Maximum working resolution:'; PL: 'Maksymalna rozdzielczość robocza:'; CS: 'Maximální pracovní rozlišení:';
     FR: 'Résolution maximale de fonctionnement :'; DE: 'Maximale Arbeitsauflösung:'; IT: 'Risoluzione massima di lavoro:';
     ES: 'Resolución máxima de trabajo:'; PT: 'Resolução máxima de trabalho:'; AF: 'Maksimum werkresolusie:'),
    (EN: 'Image'; PL: 'Obraz'; CS: 'Obrázek';
     FR: 'Image'; DE: 'Bild'; IT: 'Immagine';
     ES: 'Imagen'; PT: 'Imagem'; AF: 'Beeld'),
    (EN: 'Inverted tunnel'; PL: 'Odwrócony tunel'; CS: 'Obrácený tunel';
     FR: 'Tunnel inversé'; DE: 'Umgekehrter Tunnel'; IT: 'Tunnel invertito';
     ES: 'Túnel invertido'; PT: 'Túnel invertido'; AF: 'Omgekeerde tonnel'),
    (EN: '30° slice'; PL: 'Wycinek 30°'; CS: '30° výseč';
     FR: 'Secteur de 30°'; DE: '30°-Ausschnitt'; IT: 'Sezione di 30°';
     ES: 'Sector de 30°'; PT: 'Fatia de 30°'; AF: '30°-segment'),
    (EN: 'Full HD (1920×1080)'; PL: 'Full HD (1920×1080)'; CS: 'Full HD (1920×1080)';
     FR: 'Full HD (1920×1080)'; DE: 'Full HD (1920×1080)'; IT: 'Full HD (1920×1080)';
     ES: 'Full HD (1920×1080)'; PT: 'Full HD (1920×1080)'; AF: 'Volle HD (1920×1080)'),
    (EN: '4K (3840×2160)'; PL: '4K (3840×2160)'; CS: '4K (3840×2160)';
     FR: '4K (3840×2160)'; DE: '4K (3840×2160)'; IT: '4K (3840×2160)';
     ES: '4K (3840×2160)'; PT: '4K (3840×2160)'; AF: '4K (3840×2160)'),
    (EN: 'Performance and maximum working resolution'; PL: 'Wydajność i maksymalna rozdzielczość robocza'; CS: 'Výkon a maximální pracovní rozlišení';
     FR: 'Performances et résolution maximale de fonctionnement'; DE: 'Leistung und maximale Arbeitsauflösung'; IT: 'Prestazioni e risoluzione massima di lavoro';
     ES: 'Rendimiento y resolución máxima de trabajo'; PT: 'Desempenho e máxima resolução de trabalho'; AF: 'Werkingsverrigting en maksimum werkresolusie'),
    (EN: 'SVGA (800×600)'; PL: 'SVGA (800×600)'; CS: 'SVGA (800×600)';
     FR: 'SVGA (800×600)'; DE: 'SVGA (800×600)'; IT: 'SVGA (800×600)';
     ES: 'SVGA (800×600)'; PT: 'SVGA (800×600)'; AF: 'SVGA (800×600)'),
    (EN: 'Cyan'; PL: 'Cyan'; CS: 'Azurová';
     FR: 'Cyan'; DE: 'Cyan'; IT: 'Ciano';
     ES: 'Cian'; PT: 'Ciano'; AF: 'Siaan'),
    (EN: 'Magenta'; PL: 'Magenta'; CS: 'Purpurová';
     FR: 'Magenta'; DE: 'Magenta'; IT: 'Magenta';
     ES: 'Magenta'; PT: 'Magenta'; AF: 'Magenta'),
    (EN: 'Yellow'; PL: 'Żółta'; CS: 'Žlutá';
     FR: 'Jaune'; DE: 'Gelb'; IT: 'Giallo';
     ES: 'Amarillo'; PT: 'Amarelo'; AF: 'Geel'),
    (EN: 'Orange'; PL: 'Pomarańczowa'; CS: 'Oranžová';
     FR: 'Orange'; DE: 'Orange'; IT: 'Arancione';
     ES: 'Naranja'; PT: 'Laranja'; AF: 'Oranje'),
    (EN: 'Pink'; PL: 'Różowa'; CS: 'Růžová';
     FR: 'Rose'; DE: 'Rosa'; IT: 'Rosa';
     ES: 'Rosa'; PT: 'Rosa'; AF: 'Pienk'),
    (EN: 'Navy'; PL: 'Granatowa'; CS: 'Tmavě modrá';
     FR: 'Marine'; DE: 'Marineblau'; IT: 'Blu navy';
     ES: 'Azul marino'; PT: 'Azul-marinho'; AF: 'Vlootblou'),
    (EN: 'Purple'; PL: 'Fioletowa'; CS: 'Fialová';
     FR: 'Violet'; DE: 'Lila'; IT: 'Viola';
     ES: 'Morado'; PT: 'Roxo'; AF: 'Pers'),
    (EN: 'Turquoise'; PL: 'Turkusowa'; CS: 'Tyrkysová';
     FR: 'Turquoise'; DE: 'Türkis'; IT: 'Turchese';
     ES: 'Turquesa'; PT: 'Turquesa'; AF: 'Turkoois'),
    (EN: 'Coral'; PL: 'Koralowa'; CS: 'Korálová';
     FR: 'Corail'; DE: 'Koralle'; IT: 'Corallo';
     ES: 'Coral'; PT: 'Coral'; AF: 'Koraal'),
    (EN: 'Burgundy'; PL: 'Burgund'; CS: 'Vínová';
     FR: 'Bordeaux'; DE: 'Burgunderrot'; IT: 'Bordeaux';
     ES: 'Burdeos'; PT: 'Bordô'; AF: 'Bourgondië'),
    (EN: 'Mint'; PL: 'Miętowa'; CS: 'Mátová';
     FR: 'Menthe'; DE: 'Mint'; IT: 'Menta';
     ES: 'Menta'; PT: 'Menta'; AF: 'Munt'),
    (EN: 'Risograph v2...'; PL: 'Risografia v2...'; CS: 'Risograf v2...';
     FR: 'Risographie v2…'; DE: 'Risografie v2...'; IT: 'Risografia v2...';
     ES: 'Risografía v2...'; PT: 'Risografia v2...'; AF: 'Risografie v2...'),
    (EN: 'Risograph v3...'; PL: 'Risografia v3...'; CS: 'Risograf v3...';
     FR: 'Risographie v3…'; DE: 'Risografie v3...'; IT: 'Risografia v3...';
     ES: 'Risografía v3...'; PT: 'Risógrafo v3...'; AF: 'Risografie v3...'),
    (EN: 'Number of layers:'; PL: 'Liczba warstw:'; CS: 'Počet vrstev:';
     FR: 'Nombre de calques :'; DE: 'Anzahl der Ebenen:'; IT: 'Numero di livelli:';
     ES: 'Número de capas:'; PT: 'Número de camadas:'; AF: 'Aantal lae:'),
    (EN: 'Layer 1...'; PL: 'Warstwa 1...'; CS: 'Vrstva 1...';
     FR: 'Calque 1…'; DE: 'Ebene 1...'; IT: 'Livello 1...';
     ES: 'Capa 1...'; PT: 'Camada 1...'; AF: 'Laag 1...'),
    (EN: 'Layer 2...'; PL: 'Warstwa 2...'; CS: 'Vrstva 2...';
     FR: 'Calque 2…'; DE: 'Ebene 2...'; IT: 'Livello 2...';
     ES: 'Capa 2...'; PT: 'Camada 2...'; AF: 'Laag 2...'),
    (EN: 'Layer 3...'; PL: 'Warstwa 3...'; CS: 'Vrstva 3...';
     FR: 'Calque 3…'; DE: 'Ebene 3...'; IT: 'Livello 3...';
     ES: 'Capa 3...'; PT: 'Camada 3...'; AF: 'Laag 3...'),
    (EN: 'Layer 4...'; PL: 'Warstwa 4...'; CS: 'Vrstva 4...';
     FR: 'Calque 4…'; DE: 'Ebene 4...'; IT: 'Livello 4...';
     ES: 'Capa 4...'; PT: 'Camada 4...'; AF: 'Laag 4...'),
    (EN: 'Layer 5...'; PL: 'Warstwa 5...'; CS: 'Vrstva 5...';
     FR: 'Calque 5…'; DE: 'Ebene 5...'; IT: 'Livello 5...';
     ES: 'Capa 5...'; PT: 'Camada 5...'; AF: 'Laag 5...'),
    (EN: 'Pick'; PL: 'Wybierz'; CS: 'Výběr';
     FR: 'Sélectionner'; DE: 'Auswahl'; IT: 'Seleziona';
     ES: 'Seleccionar'; PT: 'Selecionar'; AF: 'Kies'),
    (EN: 'Prepare for screenprint (t-shirts)...'; PL: 'Przygotowanie do nadruku (koszulki)...'; CS: 'Příprava na sítotisk (trička)...';
     FR: 'Préparation pour la sérigraphie (t-shirts)…'; DE: 'Vorbereitung für Siebdruck (T-Shirts)...'; IT: 'Prepara per la serigrafia (magliette)...';
     ES: 'Preparar para serigrafía (camisetas)...'; PT: 'Preparar para serigrafia (t-shirts)...'; AF: 'Berei voor vir skermdruk (t-hemde)...'),
    (EN: 'T-Shirt Design...'; PL: 'Tworzenie nadruku...'; CS: 'Návrh trička...';
     FR: 'Conception du t-shirt…'; DE: 'T-Shirt-Design...'; IT: 'Design per magliette...';
     ES: 'Diseño de camiseta...'; PT: 'Design da t-shirt...'; AF: 'T-hempontwerp...'),
    (EN: 'Number of colors:'; PL: 'Liczba kolorow:'; CS: 'Počet barev:';
     FR: 'Nombre de couleurs :'; DE: 'Anzahl der Farben:'; IT: 'Numero di colori:';
     ES: 'Número de colores:'; PT: 'Número de cores:'; AF: 'Aantal kleure:'),
    (EN: '2. Color to ink mapping'; PL: '2. Mapowanie kolorow na farby'; CS: '2. Mapování barev na inkoust';
     FR: '2. Correspondance couleur/encre'; DE: '2. Farbzuordnung'; IT: '2. Mappatura colore-inchiostro';
     ES: '2. Mapeo de color a tinta'; PT: '2. Mapeamento de cores para tinta'; AF: '2. Kleur-na-ink-kartering'),
    (EN: '3. Detail cleanup'; PL: '3. Oczyszczenie detalu'; CS: '3. Vyčištění detailů';
     FR: '3. Nettoyage des détails'; DE: '3. Detailbereinigung'; IT: '3. Pulizia dettagli';
     ES: '3. Limpieza de detalles'; PT: '3. Limpeza de pormenores'; AF: '3. Detail-opruiming'),
    (EN: 'Min. area (px):'; PL: 'Min. obszar (px):'; CS: 'Min. plocha (px):';
     FR: 'Surface minimale (px) :'; DE: 'Mindestfläche (px):'; IT: 'Area minima (px):';
     ES: 'Área mínima (px):'; PT: 'Área mínima (px):'; AF: 'Min. area (px):'),
    (EN: 'Pick ink'; PL: 'Przypisz farbę'; CS: 'Výběr inkoustu';
     FR: 'Sélection de l’encre'; DE: 'Farbe auswählen'; IT: 'Seleziona inchiostro';
     ES: 'Seleccionar tinta'; PT: 'Selecionar tinta'; AF: 'Kies ink'),
    (EN: 'Ink:'; PL: 'Farba:'; CS: 'Inkoust:';
     FR: 'Encre :'; DE: 'Farbe:'; IT: 'Inchiostro:';
     ES: 'Tinta:'; PT: 'Tinta:'; AF: 'Ink:'),
    (EN: 'Simulate screenprint raster'; PL: 'Symuluj raster sitodruku'; CS: 'Simulace rastru sítotisku';
     FR: 'Simulation raster de la sérigraphie'; DE: 'Siebdruckraster simulieren'; IT: 'Simula raster serigrafia';
     ES: 'Simular trama de serigrafía'; PT: 'Simular raster de serigrafia'; AF: 'Simuleer skermdrukraster'),
    (EN: 'T-Shirt pipeline'; PL: 'Pipeline koszulki'; CS: 'Výroba triček';
     FR: 'Processus de fabrication des t-shirts'; DE: 'T-Shirt-Produktionsprozess'; IT: 'Produzione di magliette';
     ES: 'Proceso de producción de camisetas'; PT: 'Produção de t-shirts'; AF: 'T-hemp pyplyn'),
    (EN: '1. Posterization'; PL: '1. Posteryzacja'; CS: '1. Posterizace';
     FR: '1. Postérisation'; DE: '1. Posterisierung'; IT: '1. Posterizzazione';
     ES: '1. Posterización'; PT: '1. Posterização'; AF: '1. Posterisering'),
    (EN: 'Islands removed:'; PL: 'Usunięte wyspy:'; CS: 'Odstranění ostrůvků:';
     FR: 'Suppression des zones :'; DE: 'Inseln entfernt:'; IT: 'Isole rimosse:';
     ES: 'Islas eliminadas:'; PT: 'Ilhas removidas:'; AF: 'Eilandjies verwyder:'),
    (EN: 'T-Shirt Design'; PL: 'Tworzenie nadruku'; CS: 'Návrh trička';
     FR: 'Conception du t-shirt'; DE: 'T-Shirt-Design'; IT: 'Design per magliette';
     ES: 'Diseño de camiseta'; PT: 'Design da t-shirt'; AF: 'T-hempontwerp'),
    (EN: 'Smooth preview scaling'; PL: 'Płynne skalowanie podglądu'; CS: 'Plynulé škálování náhledu';
     FR: 'Adoucissement de l’aperçu'; DE: 'Glatte Vorschau-Skalierung'; IT: 'Scalatura fluida dell''anteprima';
     ES: 'Escalado suave de la vista previa'; PT: 'Escala suave da pré-visualização'; AF: 'Vloeiende voorskou-skaal'),
    (EN: 'Performance measurement'; PL: 'Zmierz wydajność'; CS: 'Měření výkonu';
     FR: 'Mesure des performances des effets graphiques'; DE: 'Leistungsmessung von Grafikeffekten'; IT: 'Misura le prestazioni degli effetti grafici';
     ES: 'Medición del rendimiento de los efectos gráficos'; PT: 'Medir o desempenho dos efeitos gráficos'; AF: 'Meet die werkverrigting van grafiese effekte'),
    (EN: 'This test will measure the speed of 12 image processing effects.\nDuration: from a few seconds to several minutes -\ndepends on image resolution and CPU power.'; PL: 'Test wydajności sprawdzi szybkość 12 operacji graficznych.\nCzas trwania: od kilkunastu sekund do kilku minut —\nzależy od rozdzielczości obrazka i mocy procesora.'; CS: 'Tento test změří rychlost 12 efektů zpracování obrazu.\nDoba trvání: od několika sekund do několika minut -\nzávisí na rozlišení obrazu a výkonu procesoru.';
     FR: 'Ce test mesure la vitesse de 12 effets de traitement d’image. Durée : de quelques secondes à plusieurs minutes, selon la résolution de l’image et la puissance du processeur.'; DE: 'Dieser Test misst die Geschwindigkeit von 12 Bildverarbeitungseffekten.\nDauer: von wenigen Sekunden bis zu mehreren Minuten – abhängig von Bildauflösung und CPU-Leistung.'; IT: 'Questo test misurerà la velocità di 12 effetti di elaborazione delle immagini.\nDurata: da pochi secondi a diversi minuti -\ndipende dalla risoluzione dell''immagine e dalla potenza della CPU.';
     ES: 'Esta prueba medirá la velocidad de 12 efectos de procesamiento de imágenes.\nDuración: de unos segundos a varios minutos,\ndepende de la resolución de la imagen y la potencia de la CPU.'; PT: 'Este teste irá medir a velocidade de 12 efeitos de processamento de imagem. Duração: de alguns segundos a vários minutos - depende da resolução da imagem e da capacidade da CPU.'; AF: 'Hierdie toets sal die spoed van 12 beeldverwerkingseffekte meet.\nDuur: van ''n paar sekondes tot ''n paar minute -\nhang af van beeldresolusie en SVE-krag.'),
    (EN: 'Performance test'; PL: 'Test wydajności'; CS: 'Test výkonu';
     FR: 'Test de performances'; DE: 'Leistungstest'; IT: 'Test delle prestazioni';
     ES: 'Prueba de rendimiento'; PT: 'Teste de desempenho'; AF: 'Werkverrigtingstoets'),
    (EN: 'Preparing image...'; PL: 'Przygotowanie obrazu...'; CS: 'Příprava obrazu...';
     FR: 'Préparation de l’image…'; DE: 'Bild wird vorbereitet...'; IT: 'Preparazione dell''immagine...';
     ES: 'Preparando la imagen...'; PT: 'Preparar imagem...'; AF: 'Berei beeld voor...'),
    (EN: 'Image: %s (%d×%d)'; PL: 'Obraz: %s (%d×%d)'; CS: 'Obrázek: %s (%d×%d)';
     FR: 'Image : %s (%d×%d)'; DE: 'Bild: %s (%d×%d)'; IT: 'Immagine: %s (%d×%d)';
     ES: 'Imagen: %s (%d×%d)'; PT: 'Imagem: %s (%d×%d)'; AF: 'Beeld: %s (%d×%d)'),
    (EN: '%s: %.2f ms (avg of %d)'; PL: '%s: %.2f ms (śr. z %d)'; CS: '%s: %,2f ms (průměr %d)';
     FR: '%s : %.2f ms (moyenne sur %d)'; DE: '%s: %.2f ms (Durchschnitt von %d)'; IT: '%s: %.2f ms (media di %d)';
     ES: '%s: %.2f ms (promedio de %d)'; PT: '%s: %.2f ms (média de %d)'; AF: '%s: %.2f ms (gemiddeld van %d)'),
    (EN: 'Time: %d min %d s'; PL: 'Czas testu: %d min %d s'; CS: 'Čas: %d min %d s';
     FR: 'Temps : %d min %d s'; DE: 'Zeit: %d min %d s'; IT: 'Tempo: %d min %d s';
     ES: 'Tiempo: %d min %d s'; PT: 'Tempo: %d min %d s'; AF: 'Tyd: %d min %d s'),
    (EN: '(aborted)'; PL: '(przerwane)'; CS: '(přerušeno)';
     FR: '(abandonné)'; DE: '(abgebrochen)'; IT: '(interrotto)';
     ES: '(abortada)'; PT: '(abortado)'; AF: '(gestop)'),
    (EN: 'Hardest: %s (%.2f ms).'; PL: 'Najcięższym wyzwaniem okazał się: %s (%.2f ms).'; CS: 'Nejtěžší: %s (%.2f ms).';
     FR: 'Test le plus difficile : %s (%.2f ms).'; DE: 'Maximale Belastung: %s (%.2f ms).'; IT: 'Più difficile: %s (%.2f ms).';
     ES: 'Máxima exigencia: %s (%.2f ms).'; PT: 'Mais difícil: %s (%.2f ms).'; AF: 'Moeilikste: %s (%.2f ms).'),
    (EN: 'Performance results'; PL: 'Wyniki benchmarka'; CS: 'Výsledky výkonu';
     FR: 'Résultats de performance'; DE: 'Leistungsergebnisse'; IT: 'Risultati delle prestazioni';
     ES: 'Resultados de rendimiento'; PT: 'Resultados de desempenho'; AF: 'Prestasieresultate'),
    (EN: 'Cross process'; PL: 'Błędne wywołanie'; CS: 'Křížový proces';
     FR: 'Traduction croisée'; DE: 'Cross-Prozess'; IT: 'Cross-process';
     ES: 'Proceso cruzado'; PT: 'Processamento cruzado'; AF: 'Kruisproses'),
    (EN: 'Bas-relief'; PL: 'Płaskorzeźba'; CS: 'Basreliéf';
     FR: 'Bas-relief'; DE: 'Basrelief'; IT: 'Bassorilievo';
     ES: 'Bajo relieve'; PT: 'Baixo-relevo'; AF: 'Bas-reliëf'),
    (EN: 'Language'; PL: 'Język'; CS: 'Jazyk';
     FR: 'Langue'; DE: 'Sprache'; IT: 'Lingua';
     ES: 'Idioma'; PT: 'Idioma'; AF: 'Taal'),
    (EN: 'NES (Nestopia)'; PL: 'NES (Nestopia)'; CS: 'NES (Nestopia)';
     FR: 'NES (Nestopia)'; DE: 'NES (Nestopia)'; IT: 'NES (Nestopia)';
     ES: 'NES (Nestopia)'; PT: 'NES (Nestopia)'; AF: 'NES (Nestopia)'),
    (EN: 'Risography v2'; PL: 'Risografia v2'; CS: 'Risografie v2';
     FR: 'Risographie v2'; DE: 'Risography v2'; IT: 'Risography v2';
     ES: 'Risografía v2'; PT: 'Risografia v2'; AF: 'Risografie v2'),
    (EN: 'HAM8 (64 colors)'; PL: 'HAM8 (64 kolory)'; CS: 'HAM8 (64 barev)';
     FR: 'HAM8 (64 couleurs)'; DE: 'HAM8 (64 Farben)'; IT: 'HAM8 (64 colori)';
     ES: 'HAM8 (64 colores)'; PT: 'HAM8 (64 cores)'; AF: 'HAM8 (64 kleure)'),
    (EN: 'HAM6 (16 colors)'; PL: 'HAM6 (16 kolorów)'; CS: 'HAM6 (16 barev)';
     FR: 'HAM6 (16 couleurs)'; DE: 'HAM6 (16 Farben)'; IT: 'HAM6 (16 colori)';
     ES: 'HAM6 (16 colores)'; PT: 'HAM6 (16 cores)'; AF: 'HAM6 (16 kleure)'),
    (EN: 'Emergo'; PL: 'Emergo'; CS: 'Záře';
     FR: 'Lueur'; DE: 'Glow'; IT: 'Bagliore';
     ES: 'Resplandor'; PT: 'Brilho'; AF: 'Gloed'),
    (EN: 'Measure the performance of graphic effects'; PL: 'Zmierz wydajność efektów graficznych'; CS: 'Měření výkonu grafických efektů';
     FR: 'Mesure des performances des effets graphiques'; DE: 'Leistung grafischer Effekte messen'; IT: 'Misura le prestazioni degli effetti grafici';
     ES: 'Medir el rendimiento de los efectos gráficos'; PT: 'Medir o desempenho dos efeitos gráficos'; AF: 'Meet die prestasie van grafiese effekte'),
    (EN: 'Processing'; PL: 'Przetwarzanie'; CS: 'Zpracování';
     FR: 'Traitement'; DE: 'Verarbeitung'; IT: 'Elaborazione';
     ES: 'Procesamiento'; PT: 'Processamento'; AF: 'Verwerking'),
    (EN: 'Brush radius (1-30):'; PL: 'Promień pędzla (1–30):'; CS: 'Poloměr štětce (1-30):';
     FR: 'Rayon du pinceau (1-30) :'; DE: 'Pinselradius (1–30):'; IT: 'Raggio del pennello (1-30):';
     ES: 'Radio del pincel (1-30):'; PT: 'Raio do pincel (1-30):'; AF: 'Kwasradius (1-30):'),
    (EN: 'Glitch...'; PL: 'Glitch...'; CS: 'Závada...';
     FR: 'Défauts…'; DE: 'Glitch...'; IT: 'Glitch...';
     ES: 'Fallo...'; PT: 'Falha...'; AF: 'Fout...'),
    (EN: 'Digital image distortion — RGB shift, noise, horizontal slice shift'; PL: 'Cyfrowe zakłócenia obrazu — przesunięcie RGB, szum, pasma poziome'; CS: 'Digitální zkreslení obrazu — posun RGB, šum, horizontální posun řezu';
     FR: 'Distorsion de l’image numérique — Décalage RVB, bruit, décalage horizontal'; DE: 'Digitale Bildverzerrung – RGB-Verschiebung, Rauschen, horizontale Schnittverschiebung'; IT: 'Distorsione dell''immagine digitale: spostamento RGB, rumore, spostamento orizzontale delle sezioni';
     ES: 'Distorsión de la imagen digital: desplazamiento RGB, ruido, desplazamiento de corte horizontal'; PT: 'Distorção da imagem digital — deslocamento RGB, ruído, deslocamento horizontal das fatias'; AF: 'Digitale beeldvervorming — RGB-verskuiwing, geraas, horisontale snyverskuiwing'),
    (EN: 'RGB Shift:'; PL: 'Przesunięcie kanałów RGB:'; CS: 'Posun RGB:';
     FR: 'Décalage RVB :'; DE: 'RGB-Verschiebung:'; IT: 'Spostamento RGB:';
     ES: 'Desplazamiento RGB:'; PT: 'Deslocamento RGB:'; AF: 'RGB-verskuiwing:'),
    (EN: 'Line jitter:'; PL: 'Drżenie linii:'; CS: 'Chvění řádků:';
     FR: 'Scintillement des lignes :'; DE: 'Zeilenzittern:'; IT: 'Jitter delle linee:';
     ES: 'Vibración de línea:'; PT: 'Tremor de linha:'; AF: 'Lynjitter:'),
    (EN: 'Noise:'; PL: 'Szum:'; CS: 'Šum:';
     FR: 'Bruit :'; DE: 'Rauschen:'; IT: 'Rumore:';
     ES: 'Ruido:'; PT: 'Ruído:'; AF: 'Geraas:'),
    (EN: 'CRT effect:'; PL: 'Efekt kineskopu (CRT):'; CS: 'Efekt CRT:';
     FR: 'Effet CRT :'; DE: 'CRT-Effekt:'; IT: 'Effetto CRT:';
     ES: 'Efecto CRT:'; PT: 'Efeito CRT:'; AF: 'CRT-effek:'),
    (EN: 'Block loss:'; PL: 'Utrata bloków:'; CS: 'Ztráta bloků:';
     FR: 'Perte de blocs :'; DE: 'Blockverlust:'; IT: 'Perdita di blocchi:';
     ES: 'Pérdida de bloque:'; PT: 'Perda de bloco:'; AF: 'Blokverlies:'),
    (EN: 'Horizontal slice shift:'; PL: 'Przesunięcia pasm poziomych:'; CS: 'Horizontální posun řezu:';
     FR: 'Décalage horizontal :'; DE: 'Horizontale Schnittverschiebung:'; IT: 'Spostamento orizzontale delle sezioni:';
     ES: 'Desplazamiento de corte horizontal:'; PT: 'Deslocamento horizontal das fatias:'; AF: 'Horisontale snyverskuiwing:'),
    (EN: 'Darkens every other line at PAL ratio — higher value = darker gaps'; PL: 'Przyciemnia co drugą linię w proporcji PAL — im wyżej, tym ciemniejsze przerwy'; CS: 'Ztmaví každý druhý řádek při poměru PAL — vyšší hodnota = tmavší mezery';
     FR: 'Assombrit une ligne sur deux au ratio PAL — valeur plus élevée = espaces plus sombres'; DE: 'Verdunkelt jede zweite Zeile im PAL-Verhältnis – höherer Wert = dunklere Zwischenräume'; IT: 'Scurisce una riga sì e una no al rapporto PAL: valore più alto = spazi più scuri';
     ES: 'Oscurece una línea sí y otra no en relación PAL: valor más alto = espacios más oscuros'; PT: 'Escurece uma linha sim, uma linha não na proporção PAL — valor mais elevado = intervalos mais escuros'; AF: 'Verdonker elke ander lyn teen PAL-verhouding — hoër waarde = donkerder gapings'),
    (EN: 'Online documentation'; PL: 'Dokumentacja online'; CS: 'Online dokumentace';
     FR: 'Documentation en ligne'; DE: 'Online-Dokumentation'; IT: 'Documentazione online';
     ES: 'Documentación en línea'; PT: 'Documentação online'; AF: 'Aanlyn dokumentasie'),
    (EN: 'Open the Fotografista website in your web browser'; PL: 'Otwórz dokumentację online w przeglądarce'; CS: 'Otevřete webové stránky Fotografista ve webovém prohlížeči';
     FR: 'Ouvrez le site web Fotografista dans votre navigateur'; DE: 'Öffnen Sie die Fotografista-Website in Ihrem Webbrowser.'; IT: 'Apri il sito web di Fotografista nel tuo browser';
     ES: 'Abre el sitio web de Fotografista en tu navegador'; PT: 'Abra o site do Fotografista no seu browser'; AF: 'Maak die Fotografista-webwerf in jou webblaaier oop'),
    (EN: 'Mimeograph...'; PL: 'Powielacz...'; CS: 'Rastříkovače...';
     FR: 'Miméographe…'; DE: 'Mimeograph...'; IT: 'Cimeografo...';
     ES: 'Mimeógrafo...'; PT: 'Mimeógrafo...'; AF: 'Mimeograaf...'),
    (EN: 'Mimeograph — ink edges on white background'; PL: 'Powielacz — tuszowe krawędzie na białym tle'; CS: 'Rastříkovače — inkoustové okraje na bílém pozadí';
     FR: 'Miméographe — bords à l’encre sur fond blanc'; DE: 'Mimeograph – Tintenränder auf weißem Hintergrund'; IT: 'Cimeografo: bordi a inchiostro su sfondo bianco';
     ES: 'Mimeógrafo: bordes de tinta sobre fondo blanco'; PT: 'Mimeógrafo — bordas de tinta sobre fundo branco'; AF: 'Mimeograaf — inkrande op wit agtergrond'),
    (EN: 'Mimeograph'; PL: 'Powielacz'; CS: 'Rastříkovače';
     FR: 'Miméographe'; DE: 'Mimeograph'; IT: 'Cimeografo';
     ES: 'Mimeógrafo'; PT: 'Mimeógrafo'; AF: 'Mimeograaf'),
    (EN: 'Granularity:'; PL: 'Ziarnistość:'; CS: 'Zrnitost:';
     FR: 'Granularité :'; DE: 'Körnigkeit:'; IT: 'Granularità:';
     ES: 'Granularidad:'; PT: 'Granularidade:'; AF: 'Korrelrigheid:'),
    (EN: 'Edge sensitivity:'; PL: 'Czułość krawędzi:'; CS: 'Citlivost okrajů:';
     FR: 'Sensibilité des bords :'; DE: 'Randempfindlichkeit:'; IT: 'Sensibilità dei bordi:';
     ES: 'Sensibilidad de borde:'; PT: 'Sensibilidade à borda:'; AF: 'Randgevoeligheid:'),
    (EN: 'Toner intensity:'; PL: 'Intensywność tonera:'; CS: 'Intenzita toneru:';
     FR: 'Intensité du toner :'; DE: 'Tonerintensität:'; IT: 'Intensità del toner:';
     ES: 'Intensidad del tóner:'; PT: 'Intensidade do toner:'; AF: 'Tonerintensiteit:'),
    (EN: 'Game Boy — DMG / Pocket'; PL: 'Game Boy — DMG / Pocket'; CS: 'Game Boy — DMG / Pocket';
     FR: 'Game Boy — DMG / Pocket'; DE: 'Game Boy — DMG / Pocket'; IT: 'Game Boy — DMG / Pocket';
     ES: 'Game Boy — DMG / Pocket'; PT: 'Game Boy — DMG / Pocket'; AF: 'Game Boy — DMG / Pocket'),
    (EN: 'Export PDF...'; PL: 'Eksportuj PDF...'; CS: 'Exportovat PDF...';
     FR: 'Exporter au format PDF…'; DE: 'PDF exportieren...'; IT: 'Esporta PDF...';
     ES: 'Exportar PDF...'; PT: 'Exportar PDF...'; AF: 'Voer PDF uit...'),
    (EN: 'Export image to PDF file'; PL: 'Eksportuj obraz dopliku PDF'; CS: 'Exportovat obrázek do souboru PDF';
     FR: 'Exporter l’image au format PDF'; DE: 'Bild als PDF-Datei exportieren'; IT: 'Esporta l''immagine in un file PDF';
     ES: 'Exportar imagen a archivo PDF'; PT: 'Exportar imagem para ficheiro PDF'; AF: 'Voer beeld na PDF-lêer uit'),
    (EN: 'Export PDF'; PL: 'Eksportuj PDF'; CS: 'Exportovat PDF';
     FR: 'Exporter au format PDF'; DE: 'PDF exportieren'; IT: 'Esporta PDF';
     ES: 'Exportar PDF'; PT: 'Exportar PDF'; AF: 'Voer PDF uit'),
    (EN: 'Done.'; PL: 'Gotowe'; CS: 'Hotovo.';
     FR: 'Terminé.'; DE: 'Fertig.'; IT: 'Fatto.';
     ES: 'Listo.'; PT: 'Concluído.'; AF: 'Klaar.'),
    (EN: 'PDF saved successfully.'; PL: 'Plik PDF został pomyślnie zapisany.'; CS: 'PDF úspěšně uloženo.';
     FR: 'PDF enregistré avec succès.'; DE: 'PDF erfolgreich gespeichert.'; IT: 'PDF salvato correttamente.';
     ES: 'PDF guardado correctamente.'; PT: 'PDF guardado com sucesso.'; AF: 'PDF suksesvol gestoor.'),
    (EN: 'Error saving PDF.'; PL: 'Błąd podczas zapisywania pliku PDF.'; CS: 'Chyba při ukládání PDF.';
     FR: 'Erreur lors de l’enregistrement du PDF.'; DE: 'Fehler beim Speichern der PDF-Datei.'; IT: 'Errore durante il salvataggio del PDF.';
     ES: 'Error al guardar el PDF.'; PT: 'Erro ao guardar o PDF.'; AF: 'Fout tydens stoering van PDF.'),
    (EN: 'Export comparison...'; PL: 'Eksportuj porównanie...'; CS: 'Exportovat porovnání...';
     FR: 'Comparaison d’exportation…'; DE: 'Vergleich exportieren...'; IT: 'Esporta confronto...';
     ES: 'Exportar comparación...'; PT: 'Exportar comparação...'; AF: 'Voer vergelyking uit...'),
    (EN: 'Export image comparison — side-by-side with original'; PL: 'Eksportuj porównanie obrazów — obok oryginału'; CS: 'Exportovat porovnání obrázků — vedle sebe s originálem';
     FR: 'Comparaison d’images — côte à côte avec l’original'; DE: 'Bildvergleich exportieren – neben dem Original'; IT: 'Esporta confronto immagini: affiancate all''originale';
     ES: 'Exportar comparación de imágenes: lado a lado con el original'; PT: 'Exportar comparação de imagens — lado a lado com o original'; AF: 'Voer beeldvergelyking uit — langs mekaar met oorspronklike'),
    (EN: 'Comparison'; PL: 'Porównanie'; CS: 'Porovnání';
     FR: 'Comparaison'; DE: 'Vergleich'; IT: 'Confronto';
     ES: 'Comparación'; PT: 'Comparação'; AF: 'Vergelyking'),
    (EN: 'No file to compare — the image was not opened from a file.'; PL: 'Brak pliku do porównania — obraz nie został otwarty z pliku.'; CS: 'Žádný soubor k porovnání — obrázek nebyl otevřen ze souboru.';
     FR: 'Aucun fichier à comparer — l’image n’a pas été ouverte à partir d’un fichier.'; DE: 'Keine Vergleichsdatei vorhanden – das Bild wurde nicht aus einer Datei geöffnet.'; IT: 'Nessun file da confrontare: l''immagine non è stata aperta da un file.';
     ES: 'No hay archivo para comparar: la imagen no se abrió desde un archivo.'; PT: 'Sem ficheiro para comparar — a imagem não foi aberta a partir de um ficheiro.'; AF: 'Geen lêer om te vergelyk nie — die beeld is nie vanaf ''n lêer oopgemaak nie.'),
    (EN: 'Comparison saved successfully.'; PL: 'Porównanie zostało pomyślnie zapisane.'; CS: 'Porovnání úspěšně uloženo.';
     FR: 'Comparaison enregistrée avec succès.'; DE: 'Vergleich erfolgreich gespeichert.'; IT: 'Confronto salvato correttamente.';
     ES: 'Comparación guardada correctamente.'; PT: 'Comparação guardada com sucesso.'; AF: 'Vergelyking suksesvol gestoor.'),
    (EN: 'Error saving comparison.'; PL: 'Błąd podczas zapisywania porównania.'; CS: 'Chyba při ukládání porovnání.';
     FR: 'Erreur lors de l’enregistrement de la comparaison.'; DE: 'Fehler beim Speichern des Vergleichs.'; IT: 'Errore durante il salvataggio del confronto.';
     ES: 'Error al guardar la comparación.'; PT: 'Erro ao guardar a comparação.'; AF: 'Fout tydens stoering van vergelyking.'),
    (EN: 'Current image'; PL: 'aktualny obraz'; CS: 'Aktuální obrázek';
     FR: 'Image actuelle'; DE: 'Aktuelles Bild'; IT: 'Immagine corrente';
     ES: 'Imagen actual'; PT: 'Imagem atual'; AF: 'Huidige beeld'),
    (EN: 'Fit to size with crop...'; PL: 'Dopasuj do rozmiaru z przycięciem...'; CS: 'Přizpůsobit velikosti s oříznutím...';
     FR: 'Ajuster à la taille avec recadrage…'; DE: 'An Größe anpassen mit Zuschneiden...'; IT: 'Adatta alle dimensioni con ritaglio...';
     ES: 'Ajustar al tamaño con recorte...'; PT: 'Ajustar ao tamanho com recorte...'; AF: 'Pas by grootte met snoei...'),
    (EN: 'Scale image to target size, cropping excess'; PL: 'Dopasuj obraz do rozmiaru docelowego, przytnij nadmiar treści'; CS: 'Přizpůsobit obrázek cílové velikosti, oříznout přebytečný obsah';
     FR: 'Redimensionner l’image à la taille cible en recadrant l’excédent'; DE: 'Bild auf Zielgröße skalieren und Überschüssiges abschneiden'; IT: 'Ridimensiona l''immagine alle dimensioni desiderate, ritagliando l''eccesso';
     ES: 'Escalar la imagen al tamaño deseado, recortando el exceso'; PT: 'Redimensionar imagem para o tamanho pretendido, recortando o excesso'; AF: 'Skaal beeld na teikengrootte, oortollige snoei'),
    (EN: 'Full HD 1920×1080'; PL: 'Full HD 1920×1080'; CS: 'Full HD 1920×1080';
     FR: 'Full HD 1920×1080'; DE: 'Full HD 1920×1080'; IT: 'Full HD 1920×1080';
     ES: 'Full HD 1920×1080'; PT: 'Full HD 1920×1080'; AF: 'Volle HD 1920×1080'),
    (EN: 'Fit to size with crop'; PL: 'Dopasuj do rozmiaru z przycięciem'; CS: 'Přizpůsobit velikosti s oříznutím';
     FR: 'Ajuster à la taille avec recadrage'; DE: 'An Größe anpassen mit Zuschneiden'; IT: 'Adatta alle dimensioni con ritaglio';
     ES: 'Ajustar al tamaño con recorte'; PT: 'Ajustar ao tamanho com recorte'; AF: 'Pas by grootte met snoei'),
    (EN: 'Performance'; PL: 'Wydajność'; CS: 'Výkon';
     FR: 'Performances'; DE: 'Leistung'; IT: 'Prestazioni';
     ES: 'Rendimiento'; PT: 'Desempenho'; AF: 'Werkverrigting'),
    (EN: 'C64 — Pepto / Colodore'; PL: 'C64 — Pepto / Colodore'; CS: 'C64 — Pepto / Colodore';
     FR: 'C64 — Pepto / Colodore'; DE: 'Commodore 64 — Pepto / Colodore'; IT: 'C64 — Pepto / Colodore';
     ES: 'C64 — Pepto / Colodore'; PT: 'C64 — Pepto / Colodore'; AF: 'C64 — Pepto / Colodore'),
    (EN: 'Anchor:'; PL: 'Kotwiczenie:'; CS: 'Ukotvení:';
     FR: 'Point d’ancrage :'; DE: 'Anker:'; IT: 'Punto di ancoraggio:';
     ES: 'Anclaje:'; PT: 'Âncora:'; AF: 'Anker:'),
    (EN: 'Top-left'; PL: 'Góra-lewo'; CS: 'Vlevo nahoře';
     FR: 'Haut gauche'; DE: 'Oben links'; IT: 'In alto a sinistra';
     ES: 'Esquina superior izquierda'; PT: 'Canto superior esquerdo'; AF: 'Links bo'),
    (EN: 'Top-right'; PL: 'Góra-prawo'; CS: 'Vpravo nahoře';
     FR: 'Haut droit'; DE: 'Oben rechts'; IT: 'In alto a destra';
     ES: 'Esquina superior derecha'; PT: 'Canto superior direito'; AF: 'Regs bo'),
    (EN: 'Bottom-left'; PL: 'Dół-lewo'; CS: 'Vlevo dole';
     FR: 'Bas gauche'; DE: 'Unten links'; IT: 'In basso a sinistra';
     ES: 'Esquina inferior izquierda'; PT: 'Canto inferior esquerdo'; AF: 'Links onder'),
    (EN: 'Bottom-right'; PL: 'Dół-prawo'; CS: 'Vpravo dole';
     FR: 'Bas droit'; DE: 'Unten rechts'; IT: 'In basso a destra';
     ES: 'Esquina inferior derecha'; PT: 'Canto inferior direito'; AF: 'Regs onder'),
    (EN: 'Apply resize with crop'; PL: 'Zastosuj dopasowanie z przycięciem'; CS: 'Použít změnu velikosti s oříznutím';
     FR: 'Appliquer le redimensionnement avec recadrage'; DE: 'Größenänderung mit Zuschneiden anwenden'; IT: 'Applica ridimensionamento con ritaglio';
     ES: 'Aplicar redimensionamiento con recorte'; PT: 'Aplicar redimensionamento com recorte'; AF: 'Pas grootte met snoei toe'),
    (EN: 'Cancel resize with crop'; PL: 'Anuluj dopasowanie'; CS: 'Zrušit změnu velikosti s oříznutím';
     FR: 'Annuler le redimensionnement avec recadrage'; DE: 'Größenänderung mit Zuschneiden abbrechen'; IT: 'Annulla ridimensionamento con ritaglio';
     ES: 'Cancelar redimensionamiento con recorte'; PT: 'Cancelar redimensionamento com recorte'; AF: 'Kanselleer grootte met snoei'),
    (EN: 'Image was not loaded from a file.\nFit-to-size with crop will use the current image\nwhich may have lower resolution due to Performance settings.'; PL: 'Obraz nie został wczytany z pliku.\nDopasowanie do rozmiaru użyje bieżącego obrazu,\nktóry może mieć niższą rozdzielczość z powodu ustawień Wydajności.'; CS: 'Obrázek nebyl načten ze souboru.\nPřizpůsobení velikosti s oříznutím použije aktuální obrázek\nkterý může mít nižší rozlišení kvůli nastavení výkonu.';
     FR: 'L’image n’a pas été chargée à partir d’un fichier.\nL’option « Ajuster à la taille avec recadrage » utilisera l’image actuelle,\ndont la résolution peut être inférieure en raison des paramètres de performance.'; DE: 'Bild wurde nicht aus einer Datei geladen.\nBei „An Größe anpassen mit Zuschneiden“ wird das aktuelle Bild verwendet.\nDas kann aufgrund der Leistungseinstellungen eine geringere Auflösung haben.'; IT: 'L''immagine non è stata caricata da un file.\nL''opzione «Adatta alle dimensioni con ritaglio» utilizzerà l''immagine corrente\nche potrebbe avere una risoluzione inferiore a causa delle impostazioni delle prestazioni.';
     ES: 'La imagen no se cargó desde un archivo.\nEl ajuste al tamaño con recorte utilizará la imagen actual,\nque puede tener una resolución menor debido a la configuración de rendimiento.'; PT: 'A imagem não foi carregada a partir de um ficheiro. \nA opção «Ajustar ao tamanho com recorte» utilizará a imagem atual,\nque pode ter uma resolução inferior devido às definições de desempenho.'; AF: 'Beeld is nie van ''n lêer gelaai nie.\nPas by grootte met snoei sal die huidige beeld gebruik\nwat dalk ''n laer resolusie het as gevolg van Werkverrigting-instellings.'),
    (EN: 'Tools'; PL: 'Narzędzia'; CS: 'Nástroje';
     FR: 'Outils'; DE: 'Werkzeuge'; IT: 'Strumenti';
     ES: 'Herramientas'; PT: 'Ferramentas'; AF: 'Gereedskap'),
    (EN: 'Launcher'; PL: 'Wyrzutnia'; CS: 'Spouštěč';
     FR: 'Lanceur'; DE: 'Starter'; IT: 'Avviatore';
     ES: 'Iniciador'; PT: 'Inicializador'; AF: 'Lanseerder'),
    (EN: 'Color depth'; PL: 'Głębia koloru'; CS: 'Barevná hloubka';
     FR: 'Profondeur de couleur'; DE: 'Farbtiefe'; IT: 'Profondità colore';
     ES: 'Profundidad de color'; PT: 'Profundidade de cor'; AF: 'Kleurdiepte'),
    (EN: 'Loading engine'; PL: 'Silnik wczytywania'; CS: 'Načítací modul';
     FR: 'Moteur de chargement'; DE: 'Lade‑Modul'; IT: 'Motore di caricamento';
     ES: 'Motor de carga'; PT: 'Motor de carregamento'; AF: 'Laaienjin'),
    (EN: 'Quick action launcher'; PL: 'Wyrzutnia szybkich operacji'; CS: 'Spouštěč rychlých akcí';
     FR: 'Lanceur d’actions rapides'; DE: 'Schnellaktions‑Starter'; IT: 'Avviatore azioni rapide';
     ES: 'Iniciador de acciones rápidas'; PT: 'Inicializador de ações rápidas'; AF: 'Snelle‑aksie‑lanseerder'),
    (EN: 'Program registered'; PL: 'Program zarejestrowany'; CS: 'Program zaregistrován';
     FR: 'Programme enregistré'; DE: 'Programm registriert'; IT: 'Programma registrato';
     ES: 'Programa registrado'; PT: 'Programa registado'; AF: 'Program geregistreer'),
    (EN: 'Enter license key'; PL: 'Wprowadź klucz licencyjny'; CS: 'Zadejte licenční klíč';
     FR: 'Saisir la clé de licence'; DE: 'Lizenzschlüssel eingeben'; IT: 'Inserire la chiave di licenza';
     ES: 'Introducir la clave de licencia'; PT: 'Introduzir a chave de licença'; AF: 'Voer die lisensiesleutel in'),
    (EN: 'Enter the email used for purchase:'; PL: 'Podaj adres e-mail użyty przy zakupie:'; CS: 'Zadejte e‑mail použitý při nákupu:';
     FR: 'Saisissez l’e‑mail utilisé lors de l’achat :'; DE: 'E‑Mail‑Adresse der Bestellung eingeben:'; IT: 'Inserire l’e‑mail usata per l’acquisto:';
     ES: 'Introduzca el correo usado en la compra:'; PT: 'Introduza o e‑mail usado na compra:'; AF: 'Voer die e‑posadres van die aankoop in:'),
    (EN: 'Enter license key:'; PL: 'Wprowadź klucz licencyjny:'; CS: 'Zadejte licenční klíč:';
     FR: 'Saisir la clé de licence :'; DE: 'Lizenzschlüssel eingeben:'; IT: 'Inserire la chiave di licenza:';
     ES: 'Introducir la clave de licencia:'; PT: 'Introduzir a chave de licença:'; AF: 'Voer die lisensiesleutel in:'),
    (EN: 'Success'; PL: 'Sukces'; CS: 'Úspěch';
     FR: 'Succès'; DE: 'Erfolg'; IT: 'Successo';
     ES: 'Éxito'; PT: 'Sucesso'; AF: 'Sukses'),
    (EN: 'License key has been activated.'; PL: 'Klucz licencyjny został aktywowany.'; CS: 'Licenční klíč byl aktivován.';
     FR: 'La clé de licence a été activée.'; DE: 'Der Lizenzschlüssel wurde aktiviert.'; IT: 'La chiave di licenza è stata attivata.';
     ES: 'La clave de licencia ha sido activada.'; PT: 'A chave de licença foi ativada.'; AF: 'Die lisensiesleutel is geaktiveer.'),
    (EN: 'Invalid key or email!'; PL: 'Nieprawidłowy klucz lub adres e-mail!'; CS: 'Neplatný klíč nebo e‑mail!';
     FR: 'Clé ou e‑mail invalide !'; DE: 'Ungültiger Schlüssel oder E‑Mail!'; IT: 'Chiave o e‑mail non valida';
     ES: 'Clave o correo inválido'; PT: 'Chave ou e‑mail inválido!'; AF: 'Ongeldige sleutel of e‑pos!'),
    (EN: 'Trial version expired'; PL: 'Wersja testowa wygasła'; CS: 'Zkušební verze vypršela';
     FR: 'Version d’essai expirée'; DE: 'Testversion abgelaufen'; IT: 'Versione di prova scaduta';
     ES: 'Versión de prueba expirada'; PT: 'Versão de teste expirada'; AF: 'Proefweergawe het verval'),
    (EN: 'Fotografista trial version expired after 7 days.'; PL: 'Wersja testowa Fotografisty wygasła po 7 dniach.'; CS: 'Zkušební verze Fotografista vypršela po 7 dnech.';
     FR: 'La version d’essai de Fotografista a expiré après 7 jours.'; DE: 'Die Fotografista‑Testversion ist nach 7 Tagen abgelaufen.'; IT: 'La versione di prova di Fotografista è scaduta dopo 7 giorni.';
     ES: 'La versión de prueba de Fotografista expiró tras 7 días.'; PT: 'A versão de teste do Fotografista expirou após 7 dias.'; AF: 'Fotografista se proefweergawe het ná 7 dae verval.'),
    (EN: 'To continue, enter your license key:'; PL: 'Aby kontynuować, wprowadź klucz licencyjny:'; CS: 'Pro pokračování zadejte licenční klíč:';
     FR: 'Pour continuer, saisissez votre clé de licence :'; DE: 'Zum Fortfahren geben Sie Ihren Lizenzschlüssel ein:'; IT: 'Per continuare, inserire la chiave di licenza:';
     ES: 'Para continuar, introduzca su clave de licencia:'; PT: 'Para continuar, introduza a sua chave de licença:'; AF: 'Om voort te gaan, voer jou lisensiesleutel in:'),
    (EN: 'Close program'; PL: 'Zamknij program'; CS: 'Zavřít program';
     FR: 'Fermer le programme'; DE: 'Programm schließen'; IT: 'Chiudi programma';
     ES: 'Cerrar programa'; PT: 'Fechar programa'; AF: 'Sluit program'),
    (EN: 'Enter your email address.'; PL: 'Podaj swój adres e-mail.'; CS: 'Zadejte svou e‑mailovou adresu.';
     FR: 'Saisissez votre adresse e‑mail.'; DE: 'Geben Sie Ihre E‑Mail‑Adresse ein.'; IT: 'Inserire il proprio indirizzo e‑mail.';
     ES: 'Introduzca su dirección de correo.'; PT: 'Introduza o seu endereço de e‑mail.'; AF: 'Voer jou e‑posadres in.'),
    (EN: 'Enter your license key.'; PL: 'Podaj swój klucz licencyjny'; CS: 'Zadejte svůj licenční klíč.';
     FR: 'Saisissez votre clé de licence.'; DE: 'Geben Sie Ihren Lizenzschlüssel ein.'; IT: 'Inserire la chiave di licenza.';
     ES: 'Introduzca su clave de licencia.'; PT: 'Introduza a sua chave de licença.'; AF: 'Voer jou lisensiesleutel in.'),
    (EN: 'Batch processing...'; PL: 'Przetwarzanie wsadowe...'; CS: 'Dávkové zpracování...';
     FR: 'Traitement par lot…'; DE: 'Stapelverarbeitung...'; IT: 'Elaborazione batch...';
     ES: 'Procesamiento por lotes...'; PT: 'Processamento em lote...'; AF: 'Bondelverwerking...'),
    (EN: 'Apply a saved macro to all images in a folder'; PL: 'Zastosuj zapisane makro do wszystkich obrazów w folderze'; CS: 'Použít uložené makro na všechny obrázky ve složce';
     FR: 'Appliquer un macro enregistré à toutes les images d’un dossier'; DE: 'Gespeichertes Makro auf alle Bilder im Ordner anwenden'; IT: 'Applicare una macro salvata a tutte le immagini in una cartella';
     ES: 'Aplicar un macro guardado a todas las imágenes de una carpeta'; PT: 'Aplicar uma macro guardada a todas as imagens numa pasta'; AF: 'Pas ’n gestoorde makro toe op alle beelde in ’n vouer'),
    (EN: 'Source folder:'; PL: 'Folder źródłowy:'; CS: 'Zdrojová složka:';
     FR: 'Dossier source :'; DE: 'Quellordner:'; IT: 'Cartella sorgente:';
     ES: 'Carpeta de origen:'; PT: 'Pasta de origem:'; AF: 'Bronvouer:'),
    (EN: 'Output folder:'; PL: 'Folder docelowy:'; CS: 'Výstupní složka:';
     FR: 'Dossier de sortie :'; DE: 'Zielordner:'; IT: 'Cartella di destinazione:';
     ES: 'Carpeta de destino:'; PT: 'Pasta de destino:'; AF: 'Uitvoervouer:'),
    (EN: 'Macro:'; PL: 'Makro:'; CS: 'Makro:';
     FR: 'Macro :'; DE: 'Makro:'; IT: 'Macro:';
     ES: 'Macro:'; PT: 'Macro:'; AF: 'Makro:'),
    (EN: 'Browse...'; PL: 'Wybierz...'; CS: 'Procházet...';
     FR: 'Parcourir…'; DE: 'Durchsuchen...'; IT: 'Sfoglia...';
     ES: 'Examinar...'; PT: 'Procurar...'; AF: 'Blaai...'),
    (EN: 'Start'; PL: 'Rozpocznij'; CS: 'Start';
     FR: 'Démarrer'; DE: 'Start'; IT: 'Avvia';
     ES: 'Iniciar'; PT: 'Iniciar'; AF: 'Begin'),
    (EN: 'Processing...'; PL: 'Przetwarzanie...'; CS: 'Zpracovává se...';
     FR: 'Traitement…'; DE: 'Verarbeitung...'; IT: 'Elaborazione...';
     ES: 'Procesando...'; PT: 'A processar...'; AF: 'Verwerking...'),
    (EN: 'Tilt-shift (miniature)'; PL: 'Makieta'; CS: 'Tilt-shift (miniatura)';
     FR: 'Tilt-shift (miniature)'; DE: 'Tilt-Shift (Miniatur)'; IT: 'Tilt-shift (miniatura)';
     ES: 'Tilt-shift (miniatura)'; PT: 'Tilt-shift (miniatura)'; AF: 'Kantel-skuif (miniatuur)'),
    (EN: 'Export quality'; PL: 'Jakość zapisu'; CS: 'Kvalita exportu';
     FR: 'Qualité d’exportation'; DE: 'Exportqualität'; IT: 'Qualità di esportazione';
     ES: 'Calidad de exportación'; PT: 'Qualidade de exportação'; AF: 'Uitvoergehalte'),
    (EN: 'Select source folder'; PL: 'Wybierz folder źródłowy'; CS: 'Vyberte zdrojovou složku';
     FR: 'Sélectionner le dossier source'; DE: 'Quellordner auswählen'; IT: 'Seleziona cartella sorgente';
     ES: 'Seleccionar carpeta de origen'; PT: 'Selecionar pasta de origem'; AF: 'Kies bronvouer'),
    (EN: 'Select output folder'; PL: 'Wybierz folder docelowy'; CS: 'Vyberte výstupní složku';
     FR: 'Sélectionner le dossier de sortie'; DE: 'Zielordner auswählen'; IT: 'Seleziona cartella di destinazione';
     ES: 'Seleccionar carpeta de destino'; PT: 'Selecionar pasta de destino'; AF: 'Kies uitvoervouer'),
    (EN: 'No saved macros.'; PL: 'Brak zapisanych makr.'; CS: 'Žádná uložená makra.';
     FR: 'Aucun macro enregistré.'; DE: 'Keine gespeicherten Makros.'; IT: 'Nessuna macro salvata.';
     ES: 'No hay macros guardados.'; PT: 'Nenhuma macro guardada.'; AF: 'Geen gestoorde makros nie.'),
    (EN: 'Batch processing is already running.'; PL: 'Przetwarzanie wsadowe jest już uruchomione.'; CS: 'Dávkové zpracování již běží.';
     FR: 'Le traitement par lot est déjà en cours.'; DE: 'Stapelverarbeitung läuft bereits.'; IT: 'Elaborazione batch già in esecuzione.';
     ES: 'El procesamiento por lotes ya está en ejecución.'; PT: 'O processamento em lote já está em execução.'; AF: 'Bondelverwerking loop reeds.'),
    (EN: 'Folder is empty.'; PL: 'Folder jest pusty.'; CS: 'Složka je prázdná.';
     FR: 'Dossier vide.'; DE: 'Ordner ist leer.'; IT: 'Cartella vuota.';
     ES: 'La carpeta está vacía.'; PT: 'Pasta vazia.'; AF: 'Vouer is leeg.'),
    (EN: 'No images found in source folder.'; PL: 'Nie znaleziono żadnych obrazów w folderze źródłowym.'; CS: 'Ve zdrojové složce nebyly nalezeny žádné obrázky.';
     FR: 'Aucune image trouvée dans le dossier source.'; DE: 'Keine Bilder im Quellordner gefunden.'; IT: 'Nessuna immagine trovata nella cartella sorgente.';
     ES: 'No se encontraron imágenes en la carpeta de origen.'; PT: 'Nenhuma imagem encontrada na pasta de origem.'; AF: 'Geen beelde in bronvouer gevind nie.'),
    (EN: 'Fill in all fields.'; PL: 'Wypełnij wszystkie pola.'; CS: 'Vyplňte všechna pole.';
     FR: 'Remplissez tous les champs.'; DE: 'Alle Felder ausfüllen.'; IT: 'Compilare tutti i campi.';
     ES: 'Complete todos los campos.'; PT: 'Preencha todos os campos.'; AF: 'Vul alle velde in.'),
    (EN: 'Processed'; PL: 'Przetworzono'; CS: 'Zpracováno';
     FR: 'Traitées'; DE: 'Verarbeitet'; IT: 'Elaborate';
     ES: 'Procesadas'; PT: 'Processadas'; AF: 'Verwerk'),
    (EN: 'errors'; PL: 'błędów'; CS: 'chyb';
     FR: 'erreurs'; DE: 'Fehler'; IT: 'errori';
     ES: 'errores'; PT: 'erros'; AF: 'foute'),
    (EN: 'Macro contains a resize step. Combining it with batch scaling may give unexpected results.'; PL: 'Makro zawiera krok zmiany rozmiaru. Połączenie go ze skalowaniem wsadowym może dać nieoczekiwane rezultaty.'; CS: 'Makro obsahuje krok změny velikosti. Kombinace s dávkovým škálováním může vést k neočekávaným výsledkům.';
     FR: 'Le macro contient une étape de redimensionnement. Combiné avec la mise à l’échelle par lot, cela peut produire des résultats inattendus.'; DE: 'Makro enthält einen Größenänderungsschritt. Die Kombination mit Stapelskalierung kann unerwartete Ergebnisse erzeugen.'; IT: 'La macro contiene un passaggio di ridimensionamento. Combinarlo con la scalatura batch può produrre risultati imprevisti.';
     ES: 'El macro contiene un paso de cambio de tamaño. Combinarlo con el escalado por lotes puede producir resultados inesperados.'; PT: 'A macro contém um passo de redimensionamento. Combiná‑la com a escala em lote pode gerar resultados inesperados.'; AF: 'Makro bevat ’n grootteveranderingsstap. Kombinasie met bondelskalering kan onverwagte resultate gee.'),
    (EN: 'Scale to long edge'; PL: 'Skaluj do dłuższego boku'; CS: 'Škálovat na dlouhou hranu';
     FR: 'Échelle sur le bord long'; DE: 'Auf lange Kante skalieren'; IT: 'Scala al lato lungo';
     ES: 'Escalar al borde largo'; PT: 'Escalar para o lado longo'; AF: 'Skaleer na lang kant'),
    (EN: 'px:'; PL: 'px:'; CS: 'px:';
     FR: 'px :'; DE: 'px:'; IT: 'px:';
     ES: 'px:'; PT: 'px:'; AF: 'px:'),
    (EN: 'Do not run macro'; PL: 'Bez wykonywania makra'; CS: 'Makro nespouštět';
     FR: 'Ne pas exécuter le macro'; DE: 'Makro nicht ausführen'; IT: 'Non eseguire la macro';
     ES: 'No ejecutar el macro'; PT: 'Não executar a macro'; AF: 'Moenie die makro uitvoer nie'),
    (EN: 'Buy license'; PL: 'Kup licencję'; CS: 'Koupit licenci';
     FR: 'Acheter une licence'; DE: 'Lizenz kaufen'; IT: 'Acquista licenza';
     ES: 'Comprar licencia'; PT: 'Comprar licença'; AF: 'Koop lisensie'),
    (EN: 'Artificial bokeh'; PL: 'Sztuczne bokeh'; CS: 'Umělé bokeh';
     FR: 'Bokeh artificiel'; DE: 'Künstliches Bokeh'; IT: 'Bokeh artificiale';
     ES: 'Bokeh artificial'; PT: 'Bokeh artificial'; AF: 'Kunsmatige bokeh'),
    (EN: 'Artistic'; PL: 'Artystyczne'; CS: 'Umělecké';
     FR: 'Artistique'; DE: 'Künstlerisch'; IT: 'Artistico';
     ES: 'Artístico'; PT: 'Artístico'; AF: 'Artistiek'),
    (EN: 'Assign ink 1'; PL: 'Przypisz farbę 1'; CS: 'Přiřadit barvu 1';
     FR: 'Attribuer l’encre 1'; DE: 'Farbe 1 zuweisen'; IT: 'Assegna inchiostro 1';
     ES: 'Asignar tinta 1'; PT: 'Atribuir tinta 1'; AF: 'Ken ink 1 toe'),
    (EN: 'Assign ink 2'; PL: 'Przypisz farbę 2'; CS: 'Přiřadit barvu 2';
     FR: 'Attribuer l’encre 2'; DE: 'Farbe 2 zuweisen'; IT: 'Assegna inchiostro 2';
     ES: 'Asignar tinta 2'; PT: 'Atribuir tinta 2'; AF: 'Ken ink 2 toe'),
    (EN: 'Assign ink 3'; PL: 'Przypisz farbę 3'; CS: 'Přiřadit barvu 3';
     FR: 'Attribuer l’encre 3'; DE: 'Farbe 3 zuweisen'; IT: 'Assegna inchiostro 3';
     ES: 'Asignar tinta 3'; PT: 'Atribuir tinta 3'; AF: 'Ken ink 3 toe'),
    (EN: 'Assign ink 4'; PL: 'Przypisz farbę 4'; CS: 'Přiřadit barvu 4';
     FR: 'Attribuer l’encre 4'; DE: 'Farbe 4 zuweisen'; IT: 'Assegna inchiostro 4';
     ES: 'Asignar tinta 4'; PT: 'Atribuir tinta 4'; AF: 'Ken ink 4 toe'),
    (EN: 'Assign ink 5'; PL: 'Przypisz farbę 5'; CS: 'Přiřadit barvu 5';
     FR: 'Attribuer l’encre 5'; DE: 'Farbe 5 zuweisen'; IT: 'Assegna inchiostro 5';
     ES: 'Asignar tinta 5'; PT: 'Atribuir tinta 5'; AF: 'Ken ink 5 toe'),
    (EN: 'Assign ink 6'; PL: 'Przypisz farbę 6'; CS: 'Přiřadit barvu 6';
     FR: 'Attribuer l’encre 6'; DE: 'Farbe 6 zuweisen'; IT: 'Assegna inchiostro 6';
     ES: 'Asignar tinta 6'; PT: 'Atribuir tinta 6'; AF: 'Ken ink 6 toe'),
    (EN: 'Incorrect development'; PL: 'Błędne wywołanie'; CS: 'Nesprávné vyvolání';
     FR: 'Développement incorrect'; DE: 'Fehlentwicklung'; IT: 'Sviluppo errato';
     ES: 'Revelado incorrecto'; PT: 'Revelação incorreta'; AF: 'Verkeerde ontwikkeling'),
    (EN: 'Blocking'; PL: 'Blokowanie'; CS: 'Blokování';
     FR: 'Blocage'; DE: 'Blockbildung'; IT: 'Blocco';
     ES: 'Bloqueo'; PT: 'Bloqueio'; AF: 'Blokkering'),
    (EN: 'Brightness before conversion (0-200):'; PL: 'Jasność przed konwersją (0–200):'; CS: 'Jas před konverzí (0-200):';
     FR: 'Luminosité avant conversion (0-200) :'; DE: 'Helligkeit vor der Umwandlung (0-200):'; IT: 'Luminosità prima della conversione (0-200):';
     ES: 'Brillo antes de la conversión (0-200):'; PT: 'Brilho antes da conversão (0-200):'; AF: 'Helderheid voor omskakeling (0-200):'),
    (EN: 'Center X (0-100):'; PL: 'Środek X (0–100):'; CS: 'Střed X (0-100):';
     FR: 'Centre X (0-100) :'; DE: 'Mitte X (0-100):'; IT: 'Centro X (0-100):';
     ES: 'Centro X (0-100):'; PT: 'Centro X (0-100):'; AF: 'Middelpunt X (0-100):'),
    (EN: 'Center Y (0-100):'; PL: 'Środek Y (0–100):'; CS: 'Střed Y (0-100):';
     FR: 'Centre Y (0-100) :'; DE: 'Mitte Y (0-100):'; IT: 'Centro Y (0-100):';
     ES: 'Centro Y (0-100):'; PT: 'Centro Y (0-100):'; AF: 'Middelpunt Y (0-100):'),
    (EN: 'Choose color...'; PL: 'Wybierz kolor...'; CS: 'Vybrat barvu...';
     FR: 'Choisir une couleur…'; DE: 'Farbe wählen...'; IT: 'Scegli colore...';
     ES: 'Elegir color...'; PT: 'Escolher cor...'; AF: 'Kies kleur...'),
    (EN: 'Choose color:'; PL: 'Wybierz kolor:'; CS: 'Vyberte barvu:';
     FR: 'Choisir une couleur :'; DE: 'Farbe wählen:'; IT: 'Scegli colore:';
     ES: 'Elegir color:'; PT: 'Escolher cor:'; AF: 'Kies kleur:'),
    (EN: 'Choose theme:'; PL: 'Wybierz motyw:'; CS: 'Vyberte motiv:';
     FR: 'Choisir le thème :'; DE: 'Design wählen:'; IT: 'Scegli tema:';
     ES: 'Elegir tema:'; PT: 'Escolher tema:'; AF: 'Kies tema:'),
    (EN: 'Choose...'; PL: 'Wybierz...'; CS: 'Vybrat...';
     FR: 'Choisir…'; DE: 'Wählen...'; IT: 'Scegli...';
     ES: 'Elegir...'; PT: 'Escolher...'; AF: 'Kies...'),
    (EN: 'CMYK error'; PL: 'Błąd CMYK'; CS: 'Chyba CMYK';
     FR: 'Erreur CMJN'; DE: 'CMYK-Fehler'; IT: 'Errore CMYK';
     ES: 'Error CMYK'; PT: 'Erro CMYK'; AF: 'CMYK-fout'),
    (EN: 'Contrast before conversion (0-10):'; PL: 'Kontrast przed konwersją (0–10):'; CS: 'Kontrast před konverzí (0-10):';
     FR: 'Contraste avant conversion (0-10) :'; DE: 'Kontrast vor der Umwandlung (0-10):'; IT: 'Contrasto prima della conversione (0-10):';
     ES: 'Contraste antes de la conversión (0-10):'; PT: 'Contraste antes da conversão (0-10):'; AF: 'Kontras voor omskakeling (0-10):'),
    (EN: 'Creating overprint'; PL: 'Tworzenie nadruku'; CS: 'Vytváření potisku';
     FR: 'Création de l’impression'; DE: 'Druck wird erstellt'; IT: 'Creazione della stampa';
     ES: 'Creando la estampación'; PT: 'A criar a estampagem'; AF: 'Skep van opdruk'),
    (EN: 'Crosshatching'; PL: 'Kreskowanie'; CS: 'Křížové šrafování';
     FR: 'Hachures croisées'; DE: 'Kreuzschraffur'; IT: 'Tratteggio incrociato';
     ES: 'Sombreado cruzado'; PT: 'Sombreado cruzado'; AF: 'Kruisskadulyne'),
    (EN: 'Destination folder:'; PL: 'Folder docelowy:'; CS: 'Cílová složka:';
     FR: 'Dossier de destination :'; DE: 'Zielordner:'; IT: 'Cartella di destinazione:';
     ES: 'Carpeta de destino:'; PT: 'Pasta de destino:'; AF: 'Bestemmingsgids:'),
    (EN: 'Detection sensitivity (1-100):'; PL: 'Czułość detekcji (1–100):'; CS: 'Citlivost detekce (1-100):';
     FR: 'Sensibilité de détection (1-100) :'; DE: 'Erkennungsempfindlichkeit (1-100):'; IT: 'Sensibilità di rilevamento (1-100):';
     ES: 'Sensibilidad de detección (1-100):'; PT: 'Sensibilidade de deteção (1-100):'; AF: 'Opsporingsensitiwiteit (1-100):'),
    (EN: 'Dot size multiplier:'; PL: 'Mnożnik rozmiaru punktu:'; CS: 'Násobitel velikosti bodu:';
     FR: 'Multiplicateur de taille de point :'; DE: 'Punktgrößen-Multiplikator:'; IT: 'Moltiplicatore dimensione punto:';
     ES: 'Multiplicador del tamaño de punto:'; PT: 'Multiplicador do tamanho do ponto:'; AF: 'Kolgrootte-vermenigvuldiger:'),
    (EN: 'Dot sub-cell size (3-8 px):'; PL: 'Rozmiar podkomórki rastra (3–8 px):'; CS: 'Velikost podbuňky bodu (3-8 px):';
     FR: 'Taille de sous-cellule du point (3-8 px) :'; DE: 'Unterzellengröße des Punkts (3-8 px):'; IT: 'Dimensione sotto-cella del punto (3-8 px):';
     ES: 'Tamaño de subcelda del punto (3-8 px):'; PT: 'Tamanho da subcélula do ponto (3-8 px):'; AF: 'Sub-selgrootte van kol (3-8 px):'),
    (EN: 'Duplicator'; PL: 'Duplikator'; CS: 'Duplikátor';
     FR: 'Duplicateur'; DE: 'Vervielfältiger'; IT: 'Duplicatore';
     ES: 'Duplicador'; PT: 'Duplicador'; AF: 'Dupliseerder'),
    (EN: 'Effect A:'; PL: 'Efekt A:'; CS: 'Efekt A:';
     FR: 'Effet A :'; DE: 'Effekt A:'; IT: 'Effetto A:';
     ES: 'Efecto A:'; PT: 'Efeito A:'; AF: 'Effek A:'),
    (EN: 'Effect B:'; PL: 'Efekt B:'; CS: 'Efekt B:';
     FR: 'Effet B :'; DE: 'Effekt B:'; IT: 'Effetto B:';
     ES: 'Efecto B:'; PT: 'Efeito B:'; AF: 'Effek B:'),
    (EN: 'Effect blending'; PL: 'Mieszanie efektów'; CS: 'Prolínání efektů';
     FR: 'Fusion des effets'; DE: 'Effektmischung'; IT: 'Fusione degli effetti';
     ES: 'Mezcla de efectos'; PT: 'Mistura de efeitos'; AF: 'Effekvermenging'),
    (EN: 'Effect strength (0-100):'; PL: 'Siła efektu (0–100):'; CS: 'Síla efektu (0-100):';
     FR: 'Intensité de l’effet (0-100) :'; DE: 'Effektstärke (0-100):'; IT: 'Intensità dell''effetto (0-100):';
     ES: 'Intensidad del efecto (0-100):'; PT: 'Intensidade do efeito (0-100):'; AF: 'Effekssterkte (0-100):'),
    (EN: 'Embossing'; PL: 'Tłoczenie'; CS: 'Reliéf';
     FR: 'Estampage'; DE: 'Prägung'; IT: 'Rilievo';
     ES: 'Repujado'; PT: 'Relevo'; AF: 'Reliëf'),
    (EN: 'Fade (0-100):'; PL: 'Zanikanie (0–100):'; CS: 'Vyblednutí (0-100):';
     FR: 'Estompage (0-100) :'; DE: 'Ausblendung (0-100):'; IT: 'Dissolvenza (0-100):';
     ES: 'Desvanecimiento (0-100):'; PT: 'Esmaecimento (0-100):'; AF: 'Verdowwing (0-100):'),
    (EN: 'Fit to size with cropping'; PL: 'Dopasuj do rozmiaru z przycięciem'; CS: 'Přizpůsobit velikosti s oříznutím';
     FR: 'Ajuster à la taille avec recadrage'; DE: 'An Größe anpassen mit Zuschnitt'; IT: 'Adatta alle dimensioni con ritaglio';
     ES: 'Ajustar al tamaño con recorte'; PT: 'Ajustar ao tamanho com corte'; AF: 'Pas by grootte met bysnyding'),
    (EN: 'Graininess:'; PL: 'Ziarnistość:'; CS: 'Zrnitost:';
     FR: 'Granulosité :'; DE: 'Körnigkeit:'; IT: 'Granulosità:';
     ES: 'Granulosidad:'; PT: 'Granulação:'; AF: 'Korrelrigheid:'),
    (EN: 'Image information'; PL: 'Informacje o obrazie'; CS: 'Informace o obrázku';
     FR: 'Informations sur l’image'; DE: 'Bildinformationen'; IT: 'Informazioni sull''immagine';
     ES: 'Información de la imagen'; PT: 'Informação da imagem'; AF: 'Beeldinligting'),
    (EN: 'Interface font size (pt):'; PL: 'Rozmiar czcionki interfejsu (pt):'; CS: 'Velikost písma rozhraní (pt):';
     FR: 'Taille de police de l’interface (pt) :'; DE: 'Schriftgröße der Oberfläche (pt):'; IT: 'Dimensione carattere interfaccia (pt):';
     ES: 'Tamaño de fuente de la interfaz (pt):'; PT: 'Tamanho da fonte da interface (pt):'; AF: 'Lettergrootte van koppelvlak (pt):'),
    (EN: 'JPEG quality in TIFF:'; PL: 'Jakość JPEG w TIFF:'; CS: 'Kvalita JPEG v TIFF:';
     FR: 'Qualité JPEG dans le TIFF :'; DE: 'JPEG-Qualität in TIFF:'; IT: 'Qualità JPEG nel TIFF:';
     ES: 'Calidad JPEG en TIFF:'; PT: 'Qualidade JPEG no TIFF:'; AF: 'JPEG-gehalte in TIFF:'),
    (EN: 'Line angle (0-179):'; PL: 'Kąt linii (0–179):'; CS: 'Úhel čar (0-179):';
     FR: 'Angle des lignes (0-179) :'; DE: 'Linienwinkel (0-179):'; IT: 'Angolo linea (0-179):';
     ES: 'Ángulo de línea (0-179):'; PT: 'Ângulo da linha (0-179):'; AF: 'Lynhoek (0-179):'),
    (EN: 'Material:'; PL: 'Materiał:'; CS: 'Materiál:';
     FR: 'Matériau :'; DE: 'Material:'; IT: 'Materiale:';
     ES: 'Material:'; PT: 'Material:'; AF: 'Materiaal:'),
    (EN: 'Maximum line thickness (1-8):'; PL: 'Maksymalna grubość linii (1–8):'; CS: 'Maximální tloušťka čáry (1-8):';
     FR: 'Épaisseur de ligne maximale (1-8) :'; DE: 'Maximale Linienstärke (1-8):'; IT: 'Spessore massimo linea (1-8):';
     ES: 'Grosor máximo de línea (1-8):'; PT: 'Espessura máxima da linha (1-8):'; AF: 'Maksimum lyndikte (1-8):'),
    (EN: 'Mockup'; PL: 'Makieta'; CS: 'Maketa';
     FR: 'Maquette'; DE: 'Modell'; IT: 'Modello';
     ES: 'Maqueta'; PT: 'Maquete'; AF: 'Voorbeeldmodel'),
    (EN: 'No compression'; PL: 'Bez kompresji'; CS: 'Bez komprese';
     FR: 'Sans compression'; DE: 'Keine Komprimierung'; IT: 'Nessuna compressione';
     ES: 'Sin compresión'; PT: 'Sem compressão'; AF: 'Geen kompressie'),
    (EN: 'Oil painting'; PL: 'Obraz olejny'; CS: 'Olejomalba';
     FR: 'Peinture à l’huile'; DE: 'Ölgemälde'; IT: 'Pittura a olio';
     ES: 'Pintura al óleo'; PT: 'Pintura a óleo'; AF: 'Olieverfskildery'),
    (EN: 'Other color...'; PL: 'Inny kolor...'; CS: 'Jiná barva...';
     FR: 'Autre couleur…'; DE: 'Andere Farbe...'; IT: 'Altro colore...';
     ES: 'Otro color...'; PT: 'Outra cor...'; AF: 'Ander kleur...'),
    (EN: 'Outline'; PL: 'Kontur'; CS: 'Obrys';
     FR: 'Contour'; DE: 'Kontur'; IT: 'Contorno';
     ES: 'Contorno'; PT: 'Contorno'; AF: 'Buitelyn'),
    (EN: 'Outline...'; PL: 'Kontur...'; CS: 'Obrys...';
     FR: 'Contour…'; DE: 'Kontur...'; IT: 'Contorno...';
     ES: 'Contorno...'; PT: 'Contorno...'; AF: 'Buitelyn...'),
    (EN: 'Palette'; PL: 'Paleta'; CS: 'Paleta';
     FR: 'Palette'; DE: 'Palette'; IT: 'Tavolozza';
     ES: 'Paleta'; PT: 'Paleta'; AF: 'Palet'),
    (EN: 'Palette:'; PL: 'Paleta:'; CS: 'Paleta:';
     FR: 'Palette :'; DE: 'Palette:'; IT: 'Tavolozza:';
     ES: 'Paleta:'; PT: 'Paleta:'; AF: 'Palet:'),
    (EN: 'Photographic processes'; PL: 'Procesy fotograficzne'; CS: 'Fotografické procesy';
     FR: 'Procédés photographiques'; DE: 'Fotografische Verfahren'; IT: 'Processi fotografici';
     ES: 'Procesos fotográficos'; PT: 'Processos fotográficos'; AF: 'Fotografiese prosesse'),
    (EN: 'Pixelation'; PL: 'Pikselizacja'; CS: 'Pixelizace';
     FR: 'Pixellisation'; DE: 'Verpixelung'; IT: 'Pixelizzazione';
     ES: 'Pixelado'; PT: 'Pixelização'; AF: 'Verpikselering'),
    (EN: 'Preset:'; PL: 'Preset:'; CS: 'Předvolba:';
     FR: 'Préréglage :'; DE: 'Voreinstellung:'; IT: 'Preimpostazione:';
     ES: 'Preajuste:'; PT: 'Predefinição:'; AF: 'Voorinstelling:'),
    (EN: 'Raster'; PL: 'Raster'; CS: 'Raster';
     FR: 'Trame'; DE: 'Raster'; IT: 'Retino';
     ES: 'Trama'; PT: 'Trama'; AF: 'Raster'),
    (EN: 'Restore original'; PL: 'Przywróć oryginał'; CS: 'Obnovit originál';
     FR: 'Restaurer l’original'; DE: 'Original wiederherstellen'; IT: 'Ripristina originale';
     ES: 'Restaurar original'; PT: 'Restaurar original'; AF: 'Herstel oorspronklike'),
    (EN: 'Save quality'; PL: 'Jakość zapisu'; CS: 'Kvalita uložení';
     FR: 'Qualité d’enregistrement'; DE: 'Speicherqualität'; IT: 'Qualità di salvataggio';
     ES: 'Calidad de guardado'; PT: 'Qualidade de gravação'; AF: 'Stoorgehalte'),
    (EN: 'Scale to long side, px:'; PL: 'Skaluj do dłuższego boku, px:'; CS: 'Škálovat na delší stranu, px:';
     FR: 'Redimensionner selon le côté long, px :'; DE: 'Auf lange Seite skalieren, px:'; IT: 'Scala al lato lungo, px:';
     ES: 'Escalar al lado largo, px:'; PT: 'Escalar para o lado maior, px:'; AF: 'Skaleer na lang kant, px:'),
    (EN: 'Scaling method:'; PL: 'Metoda skalowania:'; CS: 'Metoda škálování:';
     FR: 'Méthode de redimensionnement :'; DE: 'Skalierungsmethode:'; IT: 'Metodo di scalatura:';
     ES: 'Método de escalado:'; PT: 'Método de escala:'; AF: 'Skaleringsmetode:'),
    (EN: 'Scan straightening'; PL: 'Prostowanie skanu'; CS: 'Narovnání skenu';
     FR: 'Redressement du scan'; DE: 'Scan begradigen'; IT: 'Raddrizzamento della scansione';
     ES: 'Enderezado del escaneo'; PT: 'Endireitamento da digitalização'; AF: 'Skandering regmaak'),
    (EN: 'Select'; PL: 'Wybierz'; CS: 'Vybrat';
     FR: 'Sélectionner'; DE: 'Auswählen'; IT: 'Seleziona';
     ES: 'Seleccionar'; PT: 'Selecionar'; AF: 'Kies'),
    (EN: 'Shadow curve (1 = gentle, 5):'; PL: 'Krzywa cieni (1 = delikatna, 5):'; CS: 'Křivka stínů (1 = jemná, 5):';
     FR: 'Courbe des ombres (1 = douce, 5) :'; DE: 'Schattenkurve (1 = sanft, 5):'; IT: 'Curva delle ombre (1 = delicata, 5):';
     ES: 'Curva de sombras (1 = suave, 5):'; PT: 'Curva de sombras (1 = suave, 5):'; AF: 'Skaduboog (1 = sag, 5):'),
    (EN: 'Solarization'; PL: 'Solarizacja'; CS: 'Solarizace';
     FR: 'Solarisation'; DE: 'Solarisation'; IT: 'Solarizzazione';
     ES: 'Solarización'; PT: 'Solarização'; AF: 'Solarisasie'),
    (EN: 'Stippling'; PL: 'Kropkowanie'; CS: 'Tečkování';
     FR: 'Pointillé'; DE: 'Punktierung'; IT: 'Puntinatura';
     ES: 'Punteado'; PT: 'Pontilhismo'; AF: 'Stippelwerk'),
    (EN: 'Straightening angle (-10 to +10 degrees):'; PL: 'Kąt prostowania (-10 do +10 stopni):'; CS: 'Úhel narovnání (-10 až +10 stupňů):';
     FR: 'Angle de redressement (-10 à +10 degrés) :'; DE: 'Begradigungswinkel (-10 bis +10 Grad):'; IT: 'Angolo di raddrizzamento (da -10 a +10 gradi):';
     ES: 'Ángulo de enderezado (-10 a +10 grados):'; PT: 'Ângulo de endireitamento (-10 a +10 graus):'; AF: 'Regmaakhoek (-10 tot +10 grade):'),
    (EN: 'Toner:'; PL: 'Toner:'; CS: 'Toner:';
     FR: 'Toner :'; DE: 'Toner:'; IT: 'Toner:';
     ES: 'Tóner:'; PT: 'Toner:'; AF: 'Toner:'),
    (EN: 'Vividness'; PL: 'Soczystość'; CS: 'Sytost';
     FR: 'Vivacité'; DE: 'Brillant'; IT: 'Vivacità';
     ES: 'Viveza'; PT: 'Vivacidade'; AF: 'Lewendigheid'),
    (EN: 'Without running the macro'; PL: 'Bez uruchamiania makra'; CS: 'Bez spuštění makra';
     FR: 'Sans exécuter la macro'; DE: 'Ohne Makro auszuführen'; IT: 'Senza eseguire la macro';
     ES: 'Sin ejecutar la macro'; PT: 'Sem executar a macro'; AF: 'Sonder om die makro uit te voer'),
    (EN: 'Zoom'; PL: 'Powiększenie'; CS: 'Přiblížení';
     FR: 'Zoom'; DE: 'Zoom'; IT: 'Zoom';
     ES: 'Zoom'; PT: 'Zoom'; AF: 'Zoem'),
    (EN: 'Strength (1-100):'; PL: 'Siła efektu (1–100):'; CS: 'Síla (1-100):';
     FR: 'Intensité (1-100) :'; DE: 'Stärke (1-100):'; IT: 'Intensità (1-100):';
     ES: 'Intensidad (1-100):'; PT: 'Intensidade (1-100):'; AF: 'Sterkte (1-100):'),
    (EN: 'Radius (1-100):'; PL: 'Promień (1–100):'; CS: 'Poloměr (1-100):';
     FR: 'Rayon (1-100) :'; DE: 'Radius (1-100):'; IT: 'Raggio (1-100):';
     ES: 'Radio (1-100):'; PT: 'Raio (1-100):'; AF: 'Radius (1-100):'),
    (EN: 'Band position (0-100):'; PL: 'Pozycja pasa (0–100):'; CS: 'Pozice pásu (0-100):';
     FR: 'Position de la bande (0-100) :'; DE: 'Bandposition (0-100):'; IT: 'Posizione della banda (0-100):';
     ES: 'Posición de la banda (0-100):'; PT: 'Posição da faixa (0-100):'; AF: 'Bandposisie (0-100):'),
    (EN: 'Band height (1-100):'; PL: 'Wysokość pasa (1–100):'; CS: 'Výška pásu (1-100):';
     FR: 'Hauteur de la bande (1-100) :'; DE: 'Bandhöhe (1-100):'; IT: 'Altezza della banda (1-100):';
     ES: 'Altura de la banda (1-100):'; PT: 'Altura da faixa (1-100):'; AF: 'Bandhoogte (1-100):'),
    (EN: 'Strength (0 = none, 100 = max):'; PL: 'Siła efektu (0 = brak, 100 = maks.):'; CS: 'Síla (0 = žádná, 100 = max):';
     FR: 'Intensité (0 = aucune, 100 = max) :'; DE: 'Stärke (0 = keine, 100 = max):'; IT: 'Intensità (0 = nessuna, 100 = max):';
     ES: 'Intensidad (0 = ninguna, 100 = máx):'; PT: 'Intensidade (0 = nenhuma, 100 = máx.):'; AF: 'Sterkte (0 = geen, 100 = maks.):'),
    (EN: 'Contrast (0 = none, 100):'; PL: 'Kontrast (0 = brak, 100):'; CS: 'Kontrast (0 = žádný, 100):';
     FR: 'Contraste (0 = aucun, 100) :'; DE: 'Kontrast (0 = keiner, 100):'; IT: 'Contrasto (0 = nessuno, 100):';
     ES: 'Contraste (0 = ninguno, 100):'; PT: 'Contraste (0 = nenhum, 100):'; AF: 'Kontras (0 = geen, 100):'),
    (EN: 'Brush radius (1-10):'; PL: 'Promień pędzla (1–10):'; CS: 'Poloměr štětce (1-10):';
     FR: 'Rayon du pinceau (1-10) :'; DE: 'Pinselradius (1-10):'; IT: 'Raggio pennello (1-10):';
     ES: 'Radio del pincel (1-10):'; PT: 'Raio do pincel (1-10):'; AF: 'Kwasradius (1-10):'),
    (EN: 'Glow radius (1-20):'; PL: 'Promień poświaty (1–20):'; CS: 'Poloměr záře (1-20):';
     FR: 'Rayon de la lueur (1-20) :'; DE: 'Leuchtradius (1-20):'; IT: 'Raggio bagliore (1-20):';
     ES: 'Radio del resplandor (1-20):'; PT: 'Raio do brilho (1-20):'; AF: 'Gloedradius (1-20):'),
    (EN: 'Line jitter (0-100):'; PL: 'Drżenie linii (0–100):'; CS: 'Chvění čar (0-100):';
     FR: 'Tremblement des lignes (0-100) :'; DE: 'Linienzittern (0-100):'; IT: 'Tremolio delle linee (0-100):';
     ES: 'Vibración de línea (0-100):'; PT: 'Tremor da linha (0-100):'; AF: 'Lynwewiging (0-100):'),
    (EN: 'Noise (0-100):'; PL: 'Szum (0–100):'; CS: 'Šum (0-100):';
     FR: 'Bruit (0-100) :'; DE: 'Rauschen (0-100):'; IT: 'Rumore (0-100):';
     ES: 'Ruido (0-100):'; PT: 'Ruído (0-100):'; AF: 'Ruis (0-100):'),
    (EN: 'CRT effect (0-100):'; PL: 'Efekt kineskopu (0–100):'; CS: 'Efekt CRT (0-100):';
     FR: 'Effet CRT (0-100) :'; DE: 'CRT-Effekt (0-100):'; IT: 'Effetto CRT (0-100):';
     ES: 'Efecto CRT (0-100):'; PT: 'Efeito CRT (0-100):'; AF: 'CRT-effek (0-100):'),
    (EN: 'Block loss (0-100):'; PL: 'Utrata bloków (0–100):'; CS: 'Blokové ztráty (0-100):';
     FR: 'Perte de blocs (0-100) :'; DE: 'Blockverlust (0-100):'; IT: 'Perdita a blocchi (0-100):';
     ES: 'Pérdida de bloques (0-100):'; PT: 'Perda de blocos (0-100):'; AF: 'Blokverlies (0-100):'),
    (EN: 'Horizontal band shifts (0-100):'; PL: 'Przesunięcia pasm poziomych (0–100):'; CS: 'Vodorovné posuny pásů (0-100):';
     FR: 'Décalages horizontaux des bandes (0-100) :'; DE: 'Horizontale Bandverschiebungen (0-100):'; IT: 'Spostamenti orizzontali delle bande (0-100):';
     ES: 'Desplazamientos horizontales de banda (0-100):'; PT: 'Deslocamentos horizontais de faixa (0-100):'; AF: 'Horisontale bandverskuiwings (0-100):'),
    (EN: 'RGB channel shift (0-30):'; PL: 'Przesunięcie kanałów RGB (0–30):'; CS: 'Posun kanálů RGB (0-30):';
     FR: 'Décalage des canaux RVB (0-30) :'; DE: 'RGB-Kanalverschiebung (0-30):'; IT: 'Spostamento canali RGB (0-30):';
     ES: 'Desplazamiento de canales RGB (0-30):'; PT: 'Deslocamento de canais RGB (0-30):'; AF: 'RGB-kanaalverskuiwing (0-30):'),
    (EN: 'WebP compression quality (0-100):'; PL: 'Jakość zapisu WebP (0–100):'; CS: 'Kvalita komprese WebP (0-100):';
     FR: 'Qualité de compression WebP (0-100) :'; DE: 'WebP-Komprimierungsqualität (0-100):'; IT: 'Qualità di compressione WebP (0-100):';
     ES: 'Calidad de compresión WebP (0-100):'; PT: 'Qualidade de compressão WebP (0-100):'; AF: 'WebP-kompressiegehalte (0-100):'),
    (EN: '4. Screen print'; PL: '4. Sitodruk'; CS: '4. Sítotisk';
     FR: '4. Sérigraphie'; DE: '4. Siebdruck'; IT: '4. Serigrafia';
     ES: '4. Serigrafía'; PT: '4. Serigrafia'; AF: '4. Skermdruk'),
    (EN: 'Professional graphics editor'; PL: 'Profesjonalny edytor grafik'; CS: 'Profesionální grafický editor';
     FR: 'Éditeur graphique professionnel'; DE: 'Professioneller Grafik-Editor'; IT: 'Editor grafico professionale';
     ES: 'Editor gráfico profesional'; PT: 'Editor gráfico profissional'; AF: 'Professionele grafiese redigeerder'),
    (EN: 'Architecture: 100% native (VCL / Object Pascal)'; PL: 'Architektura: 100% natywna (VCL / Object Pascal)'; CS: 'Architektura: 100% nativní (VCL / Object Pascal)';
     FR: 'Architecture : 100 % native (VCL / Object Pascal)'; DE: 'Architektur: 100 % nativ (VCL / Object Pascal)'; IT: 'Architettura: 100% nativa (VCL / Object Pascal)';
     ES: 'Arquitectura: 100% nativa (VCL / Object Pascal)'; PT: 'Arquitetura: 100% nativa (VCL / Object Pascal)'; AF: 'Argitektuur: 100% inheems (VCL / Object Pascal)'),
    (EN: 'Performance: direct access to the rendering pipeline'; PL: 'Wydajność: bezpośredni dostęp do potoku renderowania'; CS: 'Výkon: přímý přístup k renderovacímu řetězci';
     FR: 'Performances : accès direct au pipeline de rendu'; DE: 'Leistung: direkter Zugriff auf die Rendering-Pipeline'; IT: 'Prestazioni: accesso diretto alla pipeline di rendering';
     ES: 'Rendimiento: acceso directo a la canalización de renderizado'; PT: 'Desempenho: acesso direto ao pipeline de renderização'; AF: 'Werkverrigting: direkte toegang tot die renderpypleiding'),
    (EN: 'Environment: independent of x86/x64 runtime'; PL: 'Środowisko: niezależne od runtime x86/x64'; CS: 'Prostředí: nezávislé na běhovém prostředí x86/x64';
     FR: 'Environnement : indépendant du runtime x86/x64'; DE: 'Umgebung: unabhängig von der Laufzeit x86/x64'; IT: 'Ambiente: indipendente dal runtime x86/x64';
     ES: 'Entorno: independiente del runtime x86/x64'; PT: 'Ambiente: independente do runtime x86/x64'; AF: 'Omgewing: onafhanklik van die x86/x64-runtime'),
    (EN: 'High-performance desktop application'; PL: 'Wysokowydajna aplikacja desktopowa'; CS: 'Vysoce výkonná desktopová aplikace';
     FR: 'Application de bureau haute performance'; DE: 'Hochleistungs-Desktop-Anwendung'; IT: 'Applicazione desktop ad alte prestazioni';
     ES: 'Aplicación de escritorio de alto rendimiento'; PT: 'Aplicação de desktop de alto desempenho'; AF: 'Hoëprestasie-tafelrekenaartoepassing'),
    (EN: 'without the overhead of web frameworks.'; PL: 'bez narzutu frameworków webowych.'; CS: 'bez zatížení webovými frameworky.';
     FR: 'sans le poids des frameworks web.'; DE: 'ohne den Overhead von Web-Frameworks.'; IT: 'senza il peso dei framework web.';
     ES: 'sin la carga de los frameworks web.'; PT: 'sem o peso dos frameworks web.'; AF: 'sonder die las van webraamwerke.'),
    (EN: 'Relief'; PL: 'Płaskorzeźba'; CS: 'Reliéf';
     FR: 'Relief'; DE: 'Relief'; IT: 'Rilievo';
     ES: 'Relieve'; PT: 'Relevo'; AF: 'Reliëf'),
    (EN: 'Fake bokeh'; PL: 'Sztuczne bokeh'; CS: 'Falešný bokeh';
     FR: 'Faux bokeh'; DE: 'Künstlerischer Bokeh'; IT: 'Falso bokeh';
     ES: 'Bokeh falso'; PT: 'Bokeh falso'; AF: 'Vals bokeh'),
    (EN: 'Manage macros'; PL: 'Zarządzanie makrami'; CS: 'Spravovat makra';
     FR: 'Gérer les macros'; DE: 'Makros verwalten'; IT: 'Gestisci macro';
     ES: 'Administrar macros'; PT: 'Gerir macros'; AF: 'Bestuur makro''s'),
    (EN: 'Risograph v1'; PL: 'Risografia v1'; CS: 'Risograf v1';
     FR: 'Risographie v1'; DE: 'Risografie v1'; IT: 'Risografia v1';
     ES: 'Risografía v1'; PT: 'Risografia v1'; AF: 'Risografie v1'),
    (EN: 'Risograph v2'; PL: 'Risografia v2'; CS: 'Risograf v2';
     FR: 'Risographie v2'; DE: 'Risografie v2'; IT: 'Risografia v2';
     ES: 'Risografía v2'; PT: 'Risografia v2'; AF: 'Risografie v2'),
    (EN: 'Wave density'; PL: 'Gęstość fali'; CS: 'Hustota vlny';
     FR: 'Densité de l’onde'; DE: 'Wellendichte'; IT: 'Densità dell''onda';
     ES: 'Densidad de onda'; PT: 'Densidade da onda'; AF: 'Golfdigtheid'),
    (EN: 'The benchmark will test the speed of 12 graphics operations.'; PL: 'Test wydajności sprawdzi szybkość 12 operacji graficznych.'; CS: 'Test výkonu změří rychlost 12 grafických operací.';
     FR: 'Le test de performances mesurera la vitesse de 12 opérations graphiques.'; DE: 'Der Leistungstest prüft die Geschwindigkeit von 12 Grafikoperationen.'; IT: 'Il test delle prestazioni misurerà la velocità di 12 operazioni grafiche.';
     ES: 'La prueba de rendimiento medirá la velocidad de 12 operaciones gráficas.'; PT: 'O teste de desempenho medirá a velocidade de 12 operações gráficas.'; AF: 'Die werkverrigtingstoets sal die spoed van 12 grafiese bewerkings meet.'),
    (EN: 'Duration: from about a dozen seconds to several minutes, depending on image resolution and processor speed.'; PL: 'Czas trwania: od kilkunastu sekund do kilku minut — zależy od rozdzielczości obrazka i mocy procesora.'; CS: 'Délka trvání: od desítek sekund do několika minut — závisí na rozlišení obrázku a výkonu procesoru.';
     FR: 'Durée : d’une dizaine de secondes à plusieurs minutes — selon la résolution de l’image et la puissance du processeur.'; DE: 'Dauer: von etwa zehn Sekunden bis zu einigen Minuten — abhängig von Bildauflösung und Prozessorleistung.'; IT: 'Durata: da una decina di secondi a diversi minuti — a seconda della risoluzione dell''immagine e della potenza del processore.';
     ES: 'Duración: de unos diez segundos a varios minutos — según la resolución de la imagen y la potencia del procesador.'; PT: 'Duração: de cerca de dez segundos a vários minutos — dependendo da resolução da imagem e da potência do processador.'; AF: 'Duur: van ongeveer tien sekondes tot etlike minute — afhangende van beeldresolusie en verwerkerspoed.'),
    (EN: '(new)'; PL: '(nowy)'; CS: '(nový)';
     FR: '(nouveau)'; DE: '(neu)'; IT: '(nuovo)';
     ES: '(nuevo)'; PT: '(novo)'; AF: '(nuut)'),
    (EN: 'Name'; PL: 'Nazwa'; CS: 'Název';
     FR: 'Nom'; DE: 'Name'; IT: 'Nome';
     ES: 'Nombre'; PT: 'Nome'; AF: 'Naam'),
    (EN: 'Format'; PL: 'Format'; CS: 'Formát';
     FR: 'Format'; DE: 'Format'; IT: 'Formato';
     ES: 'Formato'; PT: 'Formato'; AF: 'Formaat'),
    (EN: 'Width'; PL: 'Szerokość'; CS: 'Šířka';
     FR: 'Largeur'; DE: 'Breite'; IT: 'Larghezza';
     ES: 'Ancho'; PT: 'Largura'; AF: 'Breedte'),
    (EN: 'Height'; PL: 'Wysokość'; CS: 'Výška';
     FR: 'Hauteur'; DE: 'Höhe'; IT: 'Altezza';
     ES: 'Alto'; PT: 'Altura'; AF: 'Hoogte'),
    (EN: 'Resolution X'; PL: 'Rozdzielczość X'; CS: 'Rozlišení X';
     FR: 'Résolution X'; DE: 'Auflösung X'; IT: 'Risoluzione X';
     ES: 'Resolución X'; PT: 'Resolução X'; AF: 'Resolusie X'),
    (EN: 'Resolution Y'; PL: 'Rozdzielczość Y'; CS: 'Rozlišení Y';
     FR: 'Résolution Y'; DE: 'Auflösung Y'; IT: 'Risoluzione Y';
     ES: 'Resolución Y'; PT: 'Resolução Y'; AF: 'Resolusie Y'),
    (EN: 'EXIF (%d properties)'; PL: 'EXIF (%d właściwości)'; CS: 'EXIF (%d vlastností)';
     FR: 'EXIF (%d propriétés)'; DE: 'EXIF (%d Eigenschaften)'; IT: 'EXIF (%d proprietà)';
     ES: 'EXIF (%d propiedades)'; PT: 'EXIF (%d propriedades)'; AF: 'EXIF (%d eienskappe)'),
    (EN: 'Could not open the file to read metadata.'; PL: 'Nie można otworzyć pliku do odczytu metadanych.'; CS: 'Nelze otevřít soubor pro čtení metadat.';
     FR: 'Impossible d’ouvrir le fichier pour lire les métadonnées.'; DE: 'Die Datei kann nicht zum Lesen der Metadaten geöffnet werden.'; IT: 'Impossibile aprire il file per leggere i metadati.';
     ES: 'No se pudo abrir el archivo para leer los metadatos.'; PT: 'Não foi possível abrir o arquivo para ler os metadados.'; AF: 'Kon nie die lêer oopmaak om metadata te lees nie.'),
    (EN: 'Color 2 (highlights):'; PL: 'Kolor 2 (światła)'; CS: 'Barva 2 (světla):';
     FR: 'Couleur 2 (hautes lumières) :'; DE: 'Farbe 2 (Lichter):'; IT: 'Colore 2 (alte luci):';
     ES: 'Color 2 (altas luces):'; PT: 'Cor 2 (altas luzes):'; AF: 'Kleur 2 (hoogtepunte):'),
    (EN: 'WB 1.x palette'; PL: 'Paleta WB 1.x'; CS: 'Paleta WB 1.x';
     FR: 'Palette WB 1.x'; DE: 'WB-1.x-Palette'; IT: 'Palette WB 1.x';
     ES: 'Paleta WB 1.x'; PT: 'Paleta WB 1.x'; AF: 'WB 1.x-palet'),
    (EN: 'WB 2.x/3.x palette'; PL: 'Paleta WB 2.x/3.x'; CS: 'Paleta WB 2.x/3.x';
     FR: 'Palette WB 2.x/3.x'; DE: 'WB-2.x/3.x-Palette'; IT: 'Palette WB 2.x/3.x';
     ES: 'Paleta WB 2.x/3.x'; PT: 'Paleta WB 2.x/3.x'; AF: 'WB 2.x/3.x-palet'),
    (EN: 'OCS 32 palette'; PL: 'Paleta OCS 32'; CS: 'Paleta OCS 32';
     FR: 'Palette OCS 32'; DE: 'OCS-32-Palette'; IT: 'Palette OCS 32';
     ES: 'Paleta OCS 32'; PT: 'Paleta OCS 32'; AF: 'OCS 32-palet'),
    (EN: 'EHB 64 palette'; PL: 'Paleta EHB 64'; CS: 'Paleta EHB 64';
     FR: 'Palette EHB 64'; DE: 'EHB-64-Palette'; IT: 'Palette EHB 64';
     ES: 'Paleta EHB 64'; PT: 'Paleta EHB 64'; AF: 'EHB 64-palet'),
    (EN: 'AGA 256 palette'; PL: 'Paleta AGA 256'; CS: 'Paleta AGA 256';
     FR: 'Palette AGA 256'; DE: 'AGA-256-Palette'; IT: 'Palette AGA 256';
     ES: 'Paleta AGA 256'; PT: 'Paleta AGA 256'; AF: 'AGA 256-palet'),
    (EN: 'Workbench 256 palette'; PL: 'Paleta Workbench 256'; CS: 'Paleta Workbench 256';
     FR: 'Palette Workbench 256'; DE: 'Workbench-256-Palette'; IT: 'Palette Workbench 256';
     ES: 'Paleta Workbench 256'; PT: 'Paleta Workbench 256'; AF: 'Workbench 256-palet'),
    (EN: 'MagicWB palette'; PL: 'Paleta MagicWB'; CS: 'Paleta MagicWB';
     FR: 'Palette MagicWB'; DE: 'MagicWB-Palette'; IT: 'Palette MagicWB';
     ES: 'Paleta MagicWB'; PT: 'Paleta MagicWB'; AF: 'MagicWB-palet'),
    (EN: 'Tiling'; PL: 'Kafelkowanie'; CS: 'Dlaždění';
     FR: 'Carrelage'; DE: 'Kacheln'; IT: 'Affiancamento';
     ES: 'Mosaico'; PT: 'Ladrilhamento'; AF: 'Teëling'),
    (EN: 'Risograph v3'; PL: 'Risografia v3'; CS: 'Risograf v3';
     FR: 'Risographie v3'; DE: 'Risographie v3'; IT: 'Risografia v3';
     ES: 'Risografía v3'; PT: 'Risografia v3'; AF: 'Risografie v3'),
    (EN: 'Amiga background'; PL: 'Tło Amiga'; CS: 'Pozadí Amiga';
     FR: 'Arrière-plan Amiga'; DE: 'Amiga-Hintergrund'; IT: 'Sfondo Amiga';
     ES: 'Fondo Amiga'; PT: 'Fundo Amiga'; AF: 'Amiga-agtergrond'),
    (EN: 'Amiga background (stretched, MagicWB)'; PL: 'Tło Amiga (rozciągnięte, MagicWB)'; CS: 'Pozadí Amiga (roztažené, MagicWB)';
     FR: 'Arrière-plan Amiga (étiré, MagicWB)'; DE: 'Amiga-Hintergrund (gestreckt, MagicWB)'; IT: 'Sfondo Amiga (allungato, MagicWB)';
     ES: 'Fondo Amiga (estirado, MagicWB)'; PT: 'Fundo Amiga (esticado, MagicWB)'; AF: 'Amiga-agtergrond (gerek, MagicWB)'),
    (EN: 'Glow'; PL: 'Blask'; CS: 'Záře';
     FR: 'Lueur'; DE: 'Glühen'; IT: 'Bagliore';
     ES: 'Resplandor'; PT: 'Brilho'; AF: 'Glans'),
    (EN: 'Glitch'; PL: 'Glitch'; CS: 'Glitch';
     FR: 'Glitch'; DE: 'Glitch'; IT: 'Glitch';
     ES: 'Glitch'; PT: 'Glitch'; AF: 'Glitch'),
    (EN: 'Amiga gradient'; PL: 'Gradient Amiga'; CS: 'Přechod Amiga';
     FR: 'Dégradé Amiga'; DE: 'Amiga-Verlauf'; IT: 'Gradiente Amiga';
     ES: 'Degradado Amiga'; PT: 'Gradiente Amiga'; AF: 'Amiga-verloop'),
    (EN: 'Amiga gradient (Agony)'; PL: 'Gradient Amiga (Agony)'; CS: 'Přechod Amiga (Agony)';
     FR: 'Dégradé Amiga (Agony)'; DE: 'Amiga-Verlauf (Agony)'; IT: 'Gradiente Amiga (Agony)';
     ES: 'Degradado Amiga (Agony)'; PT: 'Gradiente Amiga (Agony)'; AF: 'Amiga-verloop (Agony)'),
    (EN: 'NES - Nestopia'; PL: 'NES — Nestopia'; CS: 'NES - Nestopia';
     FR: 'NES - Nestopia'; DE: 'NES - Nestopia'; IT: 'NES - Nestopia';
     ES: 'NES - Nestopia'; PT: 'NES - Nestopia'; AF: 'NES - Nestopia'),
    (EN: 'Unsupported step: '; PL: 'Nieobsługiwany krok: '; CS: 'Nepodporovaný krok: ';
     FR: 'Étape non prise en charge : '; DE: 'Nicht unterstützter Schritt: '; IT: 'Passaggio non supportato: ';
     ES: 'Paso no admitido: '; PT: 'Etapa não suportada: '; AF: 'Nie-ondersteunde stap: '),
    (EN: 'Cannot compare - image was not opened from a file.'; PL: 'Nie można porównać — obraz nie został otwarty z pliku.'; CS: 'Nelze porovnat - obrázek nebyl otevřen ze souboru.';
     FR: 'Comparaison impossible - l’image n’a pas été ouverte depuis un fichier.'; DE: 'Vergleich nicht möglich - das Bild wurde nicht aus einer Datei geöffnet.'; IT: 'Confronto impossibile - l''immagine non è stata aperta da un file.';
     ES: 'No se puede comparar - la imagen no se abrió desde un archivo.'; PT: 'Não é possível comparar - a imagem não foi aberta a partir de um ficheiro.'; AF: 'Kan nie vergelyk nie - die beeld is nie vanaf ''n lêer geopen nie.'),
    (EN: 'File does not exist:'; PL: 'Plik nie istnieje:'; CS: 'Soubor neexistuje:';
     FR: 'Le fichier n’existe pas :'; DE: 'Die Datei existiert nicht:'; IT: 'Il file non esiste:';
     ES: 'El archivo no existe:'; PT: 'O ficheiro não existe:'; AF: 'Die lêer bestaan nie:'),
    (EN: 'Source file not found on disk to restore the original.'; PL: 'Brak pliku źródłowego na dysku do przywrócenia oryginału.'; CS: 'Zdrojový soubor pro obnovení originálu nebyl nalezen na disku.';
     FR: 'Fichier source introuvable sur le disque pour restaurer l’original.'; DE: 'Quelldatei zum Wiederherstellen des Originals nicht gefunden.'; IT: 'File sorgente non trovato sul disco per ripristinare l''originale.';
     ES: 'No se encontró el archivo de origen en el disco para restaurar el original.'; PT: 'Ficheiro de origem não encontrado no disco para repor o original.'; AF: 'Bronlêer nie op skyf gevind om die oorspronklike te herstel nie.'),
    (EN: 'Open an image first.'; PL: 'Najpierw otwórz obraz.'; CS: 'Nejprve otevřete obrázek.';
     FR: 'Ouvrez d’abord une image.'; DE: 'Öffnen Sie zuerst ein Bild.'; IT: 'Aprire prima un''immagine.';
     ES: 'Abra primero una imagen.'; PT: 'Abra primeiro uma imagem.'; AF: 'Maak eers ''n beeld oop.'),
    (EN: 'Macro is empty - not saved.'; PL: 'Makro jest puste — nie zapisano.'; CS: 'Makro je prázdné - neuloženo.';
     FR: 'La macro est vide - non enregistrée.'; DE: 'Makro ist leer - nicht gespeichert.'; IT: 'La macro è vuota - non salvata.';
     ES: 'La macro está vacía - no guardada.'; PT: 'A macro está vazia - não guardada.'; AF: 'Makro is leeg - nie gestoor nie.'),
    (EN: 'Macro name'; PL: 'Nazwa makra'; CS: 'Název makra';
     FR: 'Nom de la macro'; DE: 'Name des Makros'; IT: 'Nome della macro';
     ES: 'Nombre de la macro'; PT: 'Nome da macro'; AF: 'Naam van die makro'),
    (EN: 'Enter macro name:'; PL: 'Podaj nazwę makra:'; CS: 'Zadejte název makra:';
     FR: 'Entrez le nom de la macro :'; DE: 'Geben Sie den Namen des Makros ein:'; IT: 'Inserire il nome della macro:';
     ES: 'Introduzca el nombre de la macro:'; PT: 'Introduza o nome da macro:'; AF: 'Voer die naam van die makro in:'),
    (EN: 'Cancelled - macro was not saved.'; PL: 'Anulowano — makro nie zostało zapisane.'; CS: 'Zrušeno - makro nebylo uloženo.';
     FR: 'Annulé - la macro n’a pas été enregistrée.'; DE: 'Abgebrochen - Makro wurde nicht gespeichert.'; IT: 'Annullato - la macro non è stata salvata.';
     ES: 'Cancelado - la macro no se guardó.'; PT: 'Cancelado - a macro não foi guardada.'; AF: 'Gekanselleer - makro is nie gestoor nie.'),
    (EN: 'No images in the source folder.'; PL: 'Brak obrazów w folderze źródłowym.'; CS: 'Ve zdrojové složce nejsou žádné obrázky.';
     FR: 'Aucune image dans le dossier source.'; DE: 'Keine Bilder im Quellordner.'; IT: 'Nessuna immagine nella cartella di origine.';
     ES: 'No hay imágenes en la carpeta de origen.'; PT: 'Não há imagens na pasta de origem.'; AF: 'Geen beelde in die bronserver nie.'),
    (EN: 'New macro name:'; PL: 'Nowa nazwa makra:'; CS: 'Nový název makra:';
     FR: 'Nouveau nom de la macro :'; DE: 'Neuer Name des Makros:'; IT: 'Nuovo nome della macro:';
     ES: 'Nuevo nombre de la macro:'; PT: 'Novo nome da macro:'; AF: 'Nuwe naam van die makro:'),
    (EN: 'Delete macro "%s"?'; PL: 'Usunąć makro „%s“?'; CS: 'Smazat makro „%s“?';
     FR: 'Supprimer la macro « %s » ?'; DE: 'Makro „%s“ löschen?'; IT: 'Eliminare la macro «%s»?';
     ES: '¿Eliminar la macro «%s»?'; PT: 'Eliminar a macro «%s»?'; AF: 'Makro "%s" uitvee?'),
    (EN: 'Delete step "%s"?'; PL: 'Usunąć krok „%s“?'; CS: 'Smazat krok „%s“?';
     FR: 'Supprimer l’étape « %s » ?'; DE: 'Schritt „%s“ löschen?'; IT: 'Eliminare il passaggio «%s»?';
     ES: '¿Eliminar el paso «%s»?'; PT: 'Eliminar o passo «%s»?'; AF: 'Stap "%s" uitvee?'),
    (EN: 'No image to process.'; PL: 'Brak obrazu do przetworzenia.'; CS: 'Žádný obrázek ke zpracování.';
     FR: 'Aucune image à traiter.'; DE: 'Kein Bild zum Verarbeiten.'; IT: 'Nessuna immagine da elaborare.';
     ES: 'No hay ninguna imagen que procesar.'; PT: 'Não há nenhuma imagem para processar.'; AF: 'Geen beeld om te verwerk nie.'),
    (EN: 'Load an image before running the performance test.'; PL: 'Załaduj obraz przed wykonaniem testu wydajności.'; CS: 'Před spuštěním testu výkonu načtěte obrázek.';
     FR: 'Chargez une image avant de lancer le test de performance.'; DE: 'Laden Sie vor dem Leistungstest ein Bild.'; IT: 'Caricare un''immagine prima di eseguire il test delle prestazioni.';
     ES: 'Cargue una imagen antes de ejecutar la prueba de rendimiento.'; PT: 'Carregue uma imagem antes de executar o teste de desempenho.'; AF: 'Laai ''n beeld voor die prestasietoets uitgevoer word.'),
    (EN: 'Cannot load image:'; PL: 'Nie można załadować obrazu:'; CS: 'Nelze načíst obrázek:';
     FR: 'Impossible de charger l’image :'; DE: 'Bild kann nicht geladen werden:'; IT: 'Impossibile caricare l''immagine:';
     ES: 'No se puede cargar la imagen:'; PT: 'Não é possível carregar a imagem:'; AF: 'Kan nie die beeld laai nie:'),
    (EN: 'Add "%s" to macro?'; PL: 'Dodać „%s“ do makra?'; CS: 'Přidat „%s“ do makra?';
     FR: 'Ajouter « %s » à la macro ?'; DE: '„%s“ zum Makro hinzufügen?'; IT: 'Aggiungere «%s» alla macro?';
     ES: '¿Añadir «%s» a la macro?'; PT: 'Adicionar «%s» à macro?'; AF: 'Voeg "%s" by die makro?'),
    (EN: 'File "%s" already exists.'; PL: 'Plik „%s“ już istnieje.'; CS: 'Soubor „%s“ již existuje.';
     FR: 'Le fichier « %s » existe déjà.'; DE: 'Die Datei „%s“ existiert bereits.'; IT: 'Il file «%s» esiste già.';
     ES: 'El archivo «%s» ya existe.'; PT: 'O ficheiro «%s» já existe.'; AF: 'Die lêer "%s" bestaan reeds.'),
    (EN: 'Overwrite?'; PL: 'Nadpisać?'; CS: 'Přepsat?';
     FR: 'Remplacer ?'; DE: 'Überschreiben?'; IT: 'Sovrascrivere?';
     ES: '¿Sobrescribir?'; PT: 'Sobrescrever?'; AF: 'Oorskryf?'),
    (EN: 'Export comparison'; PL: 'Eksport porównania'; CS: 'Export srovnání';
     FR: 'Exporter la comparaison'; DE: 'Vergleich exportieren'; IT: 'Esporta confronto';
     ES: 'Exportar comparación'; PT: 'Exportar comparação'; AF: 'Vergelyking uitvoer'),
    (EN: 'Image: current image (%d x %d)'; PL: 'Obraz: aktualny obraz (%d x %d)'; CS: 'Obrázek: aktuální obrázek (%d x %d)';
     FR: 'Image : image actuelle (%d x %d)'; DE: 'Bild: aktuelles Bild (%d x %d)'; IT: 'Immagine: immagine corrente (%d x %d)';
     ES: 'Imagen: imagen actual (%d x %d)'; PT: 'Imagem: imagem atual (%d x %d)'; AF: 'Beeld: huidige beeld (%d x %d)'),
    (EN: '  Test time: %s'; PL: '  Czas testu: %s'; CS: '  Čas testu: %s';
     FR: '  Temps de test : %s'; DE: '  Testzeit: %s'; IT: '  Tempo del test: %s';
     ES: '  Tiempo de prueba: %s'; PT: '  Tempo do teste: %s'; AF: '  Toetstyd: %s'),
    (EN: '  The heaviest challenge was: %s'; PL: '  Najcięższym wyzwaniem okazał się: %s'; CS: '  Nejnáročnějším úkolem byl: %s';
     FR: '  Le défi le plus lourd a été : %s'; DE: '  Die größte Herausforderung war: %s'; IT: '  La sfida più pesante è stata: %s';
     ES: '  El reto más difícil fue: %s'; PT: '  O desafio mais pesado foi: %s'; AF: '  Die swaarste uitdaging was: %s'),
    (EN: 'Cyan + Magenta'; PL: 'Cyjan + Magenta'; CS: 'Azurová + Purpurová';
     FR: 'Cyan + Magenta'; DE: 'Cyan + Magenta'; IT: 'Ciano + Magenta';
     ES: 'Cian + Magenta'; PT: 'Ciano + Magenta'; AF: 'Siaan + Magenta'),
    (EN: 'Cyan + Yellow'; PL: 'Cyjan + Żółty'; CS: 'Azurová + Žlutá';
     FR: 'Cyan + Jaune'; DE: 'Cyan + Gelb'; IT: 'Ciano + Giallo';
     ES: 'Cian + Amarillo'; PT: 'Ciano + Amarelo'; AF: 'Siaan + Geel'),
    (EN: 'Cyan + Black'; PL: 'Cyjan + Czarny'; CS: 'Azurová + Černá';
     FR: 'Cyan + Noir'; DE: 'Cyan + Schwarz'; IT: 'Ciano + Nero';
     ES: 'Cian + Negro'; PT: 'Ciano + Preto'; AF: 'Siaan + Swart'),
    (EN: 'Magenta + Yellow'; PL: 'Magenta + Żółty'; CS: 'Purpurová + Žlutá';
     FR: 'Magenta + Jaune'; DE: 'Magenta + Gelb'; IT: 'Magenta + Giallo';
     ES: 'Magenta + Amarillo'; PT: 'Magenta + Amarelo'; AF: 'Magenta + Geel'),
    (EN: 'Magenta + Black'; PL: 'Magenta + Czarny'; CS: 'Purpurová + Černá';
     FR: 'Magenta + Noir'; DE: 'Magenta + Schwarz'; IT: 'Magenta + Nero';
     ES: 'Magenta + Negro'; PT: 'Magenta + Preto'; AF: 'Magenta + Swart'),
    (EN: 'Yellow + Black'; PL: 'Żółty + Czarny'; CS: 'Žlutá + Černá';
     FR: 'Jaune + Noir'; DE: 'Gelb + Schwarz'; IT: 'Giallo + Nero';
     ES: 'Amarillo + Negro'; PT: 'Amarelo + Preto'; AF: 'Geel + Swart'),
    (EN: 'Cyan + Magenta + Yellow'; PL: 'Cyjan + Magenta + Żółty'; CS: 'Azurová + Purpurová + Žlutá';
     FR: 'Cyan + Magenta + Jaune'; DE: 'Cyan + Magenta + Gelb'; IT: 'Ciano + Magenta + Giallo';
     ES: 'Cian + Magenta + Amarillo'; PT: 'Ciano + Magenta + Amarelo'; AF: 'Siaan + Magenta + Geel'),
    (EN: 'Cyan + Magenta + Black'; PL: 'Cyjan + Magenta + Czarny'; CS: 'Azurová + Purpurová + Černá';
     FR: 'Cyan + Magenta + Noir'; DE: 'Cyan + Magenta + Schwarz'; IT: 'Ciano + Magenta + Nero';
     ES: 'Cian + Magenta + Negro'; PT: 'Ciano + Magenta + Preto'; AF: 'Siaan + Magenta + Swart'),
    (EN: 'Cyan + Yellow + Black'; PL: 'Cyjan + Żółty + Czarny'; CS: 'Azurová + Žlutá + Černá';
     FR: 'Cyan + Jaune + Noir'; DE: 'Cyan + Gelb + Schwarz'; IT: 'Ciano + Giallo + Nero';
     ES: 'Cian + Amarillo + Negro'; PT: 'Ciano + Amarelo + Preto'; AF: 'Siaan + Geel + Swart'),
    (EN: 'Magenta + Yellow + Black'; PL: 'Magenta + Żółty + Czarny'; CS: 'Purpurová + Žlutá + Černá';
     FR: 'Magenta + Jaune + Noir'; DE: 'Magenta + Gelb + Schwarz'; IT: 'Magenta + Giallo + Nero';
     ES: 'Magenta + Amarillo + Negro'; PT: 'Magenta + Amarelo + Preto'; AF: 'Magenta + Geel + Swart'),
    (EN: 'Cyan + Magenta + Yellow + Black'; PL: 'Cyjan + Magenta + Żółty + Czarny'; CS: 'Azurová + Purpurová + Žlutá + Černá';
     FR: 'Cyan + Magenta + Jaune + Noir'; DE: 'Cyan + Magenta + Gelb + Schwarz'; IT: 'Ciano + Magenta + Giallo + Nero';
     ES: 'Cian + Magenta + Amarillo + Negro'; PT: 'Ciano + Magenta + Amarelo + Preto'; AF: 'Siaan + Magenta + Geel + Swart'),
    (EN: 'Green + Pink'; PL: 'Zielony + Różowy'; CS: 'Zelená + Růžová';
     FR: 'Vert + Rose'; DE: 'Grün + Rosa'; IT: 'Verde + Rosa';
     ES: 'Verde + Rosa'; PT: 'Verde + Rosa'; AF: 'Groen + Pienk'),
    (EN: 'Navy + Yellow'; PL: 'Granatowy + Żółty'; CS: 'Tmavě modrá + Žlutá';
     FR: 'Bleu marine + Jaune'; DE: 'Marineblau + Gelb'; IT: 'Blu marino + Giallo';
     ES: 'Azul marino + Amarillo'; PT: 'Azul-marinho + Amarelo'; AF: 'Vlootblou + Geel'),
    (EN: 'Purple + Yellow'; PL: 'Fioletowy + Żółty'; CS: 'Fialová + Žlutá';
     FR: 'Violet + Jaune'; DE: 'Lila + Gelb'; IT: 'Viola + Giallo';
     ES: 'Púrpura + Amarillo'; PT: 'Roxo + Amarelo'; AF: 'Pers + Geel'),
    (EN: 'Turquoise + Coral'; PL: 'Turkusowy + Koralowy'; CS: 'Tyrkysová + Korálová';
     FR: 'Turquoise + Corail'; DE: 'Türkis + Koralle'; IT: 'Turchese + Corallo';
     ES: 'Turquesa + Coral'; PT: 'Turquesa + Coral'; AF: 'Turkoois + Koraal'),
    (EN: 'Maroon + Mint'; PL: 'Bordowy + Miętowy'; CS: 'Vínová + Mátová';
     FR: 'Bordeaux + Menthe'; DE: 'Weinrot + Minze'; IT: 'Bordo + Menta';
     ES: 'Granate + Menta'; PT: 'Bordô + Menta'; AF: 'Bordo + Ment'),
    (EN: 'Navy + Pink'; PL: 'Granatowy + Różowy'; CS: 'Tmavě modrá + Růžová';
     FR: 'Bleu marine + Rose'; DE: 'Marineblau + Rosa'; IT: 'Blu marino + Rosa';
     ES: 'Azul marino + Rosa'; PT: 'Azul-marinho + Rosa'; AF: 'Vlootblou + Pienk'),
    (EN: 'Green + Orange'; PL: 'Zielony + Pomarańczowy'; CS: 'Zelená + Oranžová';
     FR: 'Vert + Orange'; DE: 'Grün + Orange'; IT: 'Verde + Arancione';
     ES: 'Verde + Naranja'; PT: 'Verde + Laranja'; AF: 'Groen + Oranje'),
    (EN: 'Purple + Coral'; PL: 'Fioletowy + Koralowy'; CS: 'Fialová + Korálová';
     FR: 'Violet + Corail'; DE: 'Lila + Koralle'; IT: 'Viola + Corallo';
     ES: 'Púrpura + Coral'; PT: 'Roxo + Coral'; AF: 'Pers + Koraal'),
    (EN: 'Turquoise + Yellow'; PL: 'Turkusowy + Żółty'; CS: 'Tyrkysová + Žlutá';
     FR: 'Turquoise + Jaune'; DE: 'Türkis + Gelb'; IT: 'Turchese + Giallo';
     ES: 'Turquesa + Amarillo'; PT: 'Turquesa + Amarelo'; AF: 'Turkoois + Geel'),
    (EN: 'Move image'; PL: 'Przesuwanie obrazu'; CS: 'Posunout obrázek';
     FR: 'Déplacer l’image'; DE: 'Bild verschieben'; IT: 'Sposta immagine';
     ES: 'Mover imagen'; PT: 'Mover imagem'; AF: 'Skuif beeld'),
    (EN: 'Space + LMB'; PL: 'Spacja + LPM'; CS: 'Mezerník + LMB';
     FR: 'Espace + LMB'; DE: 'Leertaste + LMB'; IT: 'Spazio + LMB';
     ES: 'Espacio + LMB'; PT: 'Espaço + LMB'; AF: 'Spatiebalk + LMB'),
    (EN: 'or MMB'; PL: 'lub ŚPM'; CS: 'nebo MMB';
     FR: 'ou MMB'; DE: 'oder MMB'; IT: 'o MMB';
     ES: 'o MMB'; PT: 'ou MMB'; AF: 'of MMB'),
    (EN: 'The image has not been saved.'; PL: 'Obraz nie został zapisany.'; CS: 'Obrázek nebyl uložen.';
     FR: 'L’image n’a pas été enregistrée.'; DE: 'Das Bild wurde nicht gespeichert.'; IT: 'L''immagine non è stata salvata.';
     ES: 'La imagen no se ha guardado.'; PT: 'A imagem não foi guardada.'; AF: 'Die beeld is nie gestoor nie.'),
    (EN: 'Do you want to save your changes before closing?'; PL: 'Czy chcesz zapisać zmiany przed zamknięciem?'; CS: 'Chcete uložit změny před zavřením?';
     FR: 'Voulez-vous enregistrer les modifications avant de fermer ?'; DE: 'Möchten Sie die Änderungen vor dem Schließen speichern?'; IT: 'Vuoi salvare le modifiche prima di chiudere?';
     ES: '¿Quieres guardar los cambios antes de cerrar?'; PT: 'Quer guardar as alterações antes de fechar?'; AF: 'Wil u die veranderinge stoor voordat u sluit?'),
    (EN: 'No codec to read the file.'; PL: 'Brak kodeka do odczytu pliku.'; CS: 'Žádný kodek pro čtení souboru.';
     FR: 'Aucun codec pour lire le fichier.'; DE: 'Kein Codec zum Lesen der Datei.'; IT: 'Nessun codec per leggere il file.';
     ES: 'No hay códec para leer el archivo.'; PT: 'Não há codec para ler o ficheiro.'; AF: 'Geen kodek om die lêer te lees nie.'),
    (EN: 'Install the appropriate image extension from Microsoft Store.'; PL: 'Zainstaluj odpowiednie rozszerzenie obrazów z Microsoft Store.'; CS: 'Nainstalujte příslušné rozšíření obrázků z Microsoft Store.';
     FR: 'Installez l’extension d’images appropriée à partir du Microsoft Store.'; DE: 'Installieren Sie die passende Bilderweiterung aus dem Microsoft Store.'; IT: 'Installa l''estensione immagini appropriata da Microsoft Store.';
     ES: 'Instale la extensión de imágenes adecuada desde Microsoft Store.'; PT: 'Instale a extensão de imagens adequada a partir da Microsoft Store.'; AF: 'Installeer die toepaslike beelduitbreiding vanaf die Microsoft Store.'),
    (EN: 'No TIFF encoder in the system.'; PL: 'Brak enkodera TIFF w systemie'; CS: 'V systému není enkodér TIFF.';
     FR: 'Aucun encodeur TIFF dans le système.'; DE: 'Kein TIFF-Encoder im System.'; IT: 'Nessun codificatore TIFF nel sistema.';
     ES: 'No hay codificador TIFF en el sistema.'; PT: 'Não há codificador TIFF no sistema.'; AF: 'Geen TIFF-enkodeerder in die stelsel nie.'),
    (EN: 'TIFF save error'; PL: 'Błąd zapisu TIFF'; CS: 'Chyba uložení TIFF';
     FR: 'Erreur d’enregistrement TIFF'; DE: 'Fehler beim Speichern von TIFF'; IT: 'Errore di salvataggio TIFF';
     ES: 'Error al guardar TIFF'; PT: 'Erro ao guardar TIFF'; AF: 'Fout by die stoor van TIFF'),
    (EN: 'Unsupported save format: %s'; PL: 'Nieobsługiwany format zapisu: %s'; CS: 'Nepodporovaný formát uložení: %s';
     FR: 'Format d’enregistrement non pris en charge : %s'; DE: 'Nicht unterstütztes Speicherformat: %s'; IT: 'Formato di salvataggio non supportato: %s';
     ES: 'Formato de guardado no compatible: %s'; PT: 'Formato de gravação não suportado: %s'; AF: 'Ongesteunde stoorformaat: %s'),
    (EN: 'Raster CMYK...'; PL: 'Raster CMYK...'; CS: 'Rastr CMYK...';
     FR: 'Trame CMJN…'; DE: 'CMYK-Raster...'; IT: 'Reticolo CMYK...';
     ES: 'Trama CMYK...'; PT: 'Retícula CMYK...'; AF: 'CMYK-raster...'),
    (EN: 'Timelapse...'; PL: 'Timelapse...'; CS: 'Timelapse...';
     FR: 'Timelapse…'; DE: 'Timelapse...'; IT: 'Timelapse...';
     ES: 'Timelapse...'; PT: 'Timelapse...'; AF: 'Timelapse...'),
    (EN: 'Stereogram...'; PL: 'Stereogram...'; CS: 'Stereogram...';
     FR: 'Stéréogramme…'; DE: 'Stereogramm...'; IT: 'Stereogramma...';
     ES: 'Estereograma...'; PT: 'Estereograma...'; AF: 'Stereogram...'),
    (EN: 'Remove background...'; PL: 'Usuń tło...'; CS: 'Odebrat pozadí...';
     FR: 'Supprimer l’arrière-plan…'; DE: 'Hintergrund entfernen...'; IT: 'Rimuovi sfondo...';
     ES: 'Eliminar fondo...'; PT: 'Remover fundo...'; AF: 'Verwyder agtergrond...'),
    (EN: 'Cell size (1-32 px):'; PL: 'Rozmiar siatki (1–32 px):'; CS: 'Velikost buňky (1-32 px):';
     FR: 'Taille de cellule (1-32 px) :'; DE: 'Zellgröße (1-32 px):'; IT: 'Dimensione cella (1-32 px):';
     ES: 'Tamaño de celda (1-32 px):'; PT: 'Tamanho da célula (1-32 px):'; AF: 'Selgrootte (1-32 px):'),
    (EN: 'Dot scale [%]:'; PL: 'Skala kropki [%]:'; CS: 'Škála bodu [%]:';
     FR: 'Échelle du point [%] :'; DE: 'Punktskala [%]:'; IT: 'Scala del punto [%]:';
     ES: 'Escala del punto [%]:'; PT: 'Escala do ponto [%]:'; AF: 'Puntskaal [%]:'),
    (EN: 'Stereogram'; PL: 'Stereogram'; CS: 'Stereogram';
     FR: 'Stéréogramme'; DE: 'Stereogramm'; IT: 'Stereogramma';
     ES: 'Estereograma'; PT: 'Estereograma'; AF: 'Stereogram'),
    (EN: 'Output mode:'; PL: 'Tryb wyjścia:'; CS: 'Režim výstupu:';
     FR: 'Mode de sortie :'; DE: 'Ausgabemodus:'; IT: 'Modalità di uscita:';
     ES: 'Modo de salida:'; PT: 'Modo de saída:'; AF: 'Uitsetmodus:'),
    (EN: 'Autostereogram (SIRDS)'; PL: 'Autostereogram (SIRDS)'; CS: 'Autostereogram (SIRDS)';
     FR: 'Autostéréogramme (SIRDS)'; DE: 'Autostereogramm (SIRDS)'; IT: 'Autostereogramma (SIRDS)';
     ES: 'Autoestereograma (SIRDS)'; PT: 'Autoestereograma (SIRDS)'; AF: 'Outostereogram (SIRDS)'),
    (EN: 'Anaglyph (red-cyan glasses)'; PL: 'Anaglif (okulary czerwono-cyjanowe)'; CS: 'Anaglyf (brýle červeno-tyrkysové)';
     FR: 'Anaglyphe (lunettes rouge-cyan)'; DE: 'Anaglyphe (Rot-Cyan-Brille)'; IT: 'Anaglifo (occhiali rosso-ciano)';
     ES: 'Anaglifo (gafas rojo-cian)'; PT: 'Anáglifo (óculos vermelho-ciano)'; AF: 'Anaglief (rooi-siaan bril)'),
    (EN: 'Period (px):'; PL: 'Odstęp (px):'; CS: 'Mezera (px):';
     FR: 'Intervalle (px) :'; DE: 'Abstand (px):'; IT: 'Periodo (px):';
     ES: 'Periodo (px):'; PT: 'Período (px):'; AF: 'Periode (px):'),
    (EN: 'Depth (px):'; PL: 'Głębia (px):'; CS: 'Hloubka (px):';
     FR: 'Profondeur (px) :'; DE: 'Tiefe (px):'; IT: 'Profondità (px):';
     ES: 'Profundidad (px):'; PT: 'Profundidade (px):'; AF: 'Diepte (px):'),
    (EN: 'Random seed'; PL: 'Losowy zasiew'; CS: 'Náhodný klíč';
     FR: 'Graine aléatoire'; DE: 'Zufallssamen'; IT: 'Seme casuale';
     ES: 'Semilla aleatoria'; PT: 'Semente aleatória'; AF: 'Lukrake saad'),
    (EN: '3840×2160'; PL: '3840×2160'; CS: '3840×2160';
     FR: '3840×2160'; DE: '3840×2160'; IT: '3840×2160';
     ES: '3840×2160'; PT: '3840×2160'; AF: '3840×2160'),
    (EN: '1920×1080'; PL: '1920×1080'; CS: '1920×1080';
     FR: '1920×1080'; DE: '1920×1080'; IT: '1920×1080';
     ES: '1920×1080'; PT: '1920×1080'; AF: '1920×1080'),
    (EN: '1280×720'; PL: '1280×720'; CS: '1280×720';
     FR: '1280×720'; DE: '1280×720'; IT: '1280×720';
     ES: '1280×720'; PT: '1280×720'; AF: '1280×720'),
    (EN: 'Alphabetically'; PL: 'Alfabetycznie'; CS: 'Abecedně';
     FR: 'Alphabétiquement'; DE: 'Alphabetisch'; IT: 'Alfabeticamente';
     ES: 'Alfabéticamente'; PT: 'Alfabeticamente'; AF: 'Alfabeties'),
    (EN: 'By creation date'; PL: 'Według daty utworzenia'; CS: 'Podle data vytvoření';
     FR: 'Par date de création'; DE: 'Nach Erstellungsdatum'; IT: 'Per data di creazione';
     ES: 'Por fecha de creación'; PT: 'Por data de criação'; AF: 'Volgens skeppingsdatum'),
    (EN: 'Save to file'; PL: 'Zapisz do pliku'; CS: 'Uložit do souboru';
     FR: 'Enregistrer dans un fichier'; DE: 'In Datei speichern'; IT: 'Salva su file';
     ES: 'Guardar en archivo'; PT: 'Salvar em arquivo'; AF: 'Stoor na lêer'),
    (EN: 'Show as presentation'; PL: 'Pokaż jako prezentację'; CS: 'Zobrazit jako prezentaci';
     FR: 'Afficher comme présentation'; DE: 'Als Präsentation anzeigen'; IT: 'Mostra come presentazione';
     ES: 'Mostrar como presentación'; PT: 'Mostrar como apresentação'; AF: 'Wys as aanbieding'),
    (EN: 'In window'; PL: 'W oknie'; CS: 'V okně';
     FR: 'Dans une fenêtre'; DE: 'Im Fenster'; IT: 'Nella finestra';
     ES: 'En ventana'; PT: 'Em janela'; AF: 'In ''n venster'),
    (EN: 'Full screen'; PL: 'Pełny ekran'; CS: 'Na celou obrazovku';
     FR: 'Plein écran'; DE: 'Vollbild'; IT: 'Schermo intero';
     ES: 'Pantalla completa'; PT: 'Tela cheia'; AF: 'Volskerm'),
    (EN: 'Timelapse'; PL: 'Timelapse'; CS: 'Timelapse';
     FR: 'Timelapse'; DE: 'Timelapse'; IT: 'Timelapse';
     ES: 'Timelapse'; PT: 'Timelapse'; AF: 'Timelapse'),
    (EN: 'Frames per second:'; PL: 'Klatki na sekundę:'; CS: 'Snímků za sekundu:';
     FR: 'Images par seconde :'; DE: 'Bilder pro Sekunde:'; IT: 'Fotogrammi al secondo:';
     ES: 'Fotogramas por segundo:'; PT: 'Fotogramas por segundo:'; AF: 'Raampies per sekonde:'),
    (EN: 'Hold first frame [s]:'; PL: 'Przytrzymaj pierwszą klatkę [s]:'; CS: 'Podržet první snímek [s]:';
     FR: 'Garder la premiére image [s] :'; DE: 'Erstes Bild halten [s]:'; IT: 'Mantieni primo fotogramma [s]:';
     ES: 'Mantener primer fotograma [s]:'; PT: 'Manter primeiro fotograma [s]:'; AF: 'Hou eerste raampie [s]:'),
    (EN: 'Hold last frame [s]:'; PL: 'Przytrzymaj ostatnią klatkę [s]:'; CS: 'Podržet poslední snímek [s]:';
     FR: 'Garder la derniére image [s] :'; DE: 'Letztes Bild halten [s]:'; IT: 'Mantieni ultimo fotogramma [s]:';
     ES: 'Mantener áltimo fotograma [s]:'; PT: 'Manter áltimo fotograma [s]:'; AF: 'Hou laaste raampie [s]:'),
    (EN: 'Invalid frame rate'; PL: 'Nieprawidłowa liczba klatek'; CS: 'Neplatnů počet snímků za sekundu';
     FR: 'Cadence d’images invalide'; DE: 'Ungültige Bildrate'; IT: 'Frame rate non valido';
     ES: 'Velocidad de fotogramas inválida'; PT: 'Taxa de quadros inválida'; AF: 'Ongeldige raamtempo'),
    (EN: 'Cannot initialize video encoding'; PL: 'Nie mołna zainicjalizować kodowania wideo'; CS: 'Nelze inicializovat kódování videa';
     FR: 'Impossible d’initialiser l’encodage vidéo'; DE: 'Video-Encoding kann nicht initialisiert werden'; IT: 'Impossibile inizializzare la codifica video';
     ES: 'No se puede inicializar la codificación de vídeo'; PT: 'Não é possível inicializar a codificação de vídeo'; AF: 'Kan nie video-enkodering initialiseer nie'),
    (EN: 'Cannot create output file'; PL: 'Nie mołna utworzyć pliku wynikowego'; CS: 'Nelze vytvořit výstupní soubor';
     FR: 'Impossible de créer le fichier de sortie'; DE: 'Ausgabedatei kann nicht erstellt werden'; IT: 'Impossibile creare il file di output';
     ES: 'No se puede crear el archivo de salida'; PT: 'Não é possível criar o arquivo de saída'; AF: 'Kan nie uitsetlêer skep nie'),
    (EN: 'Cannot create video stream'; PL: 'Nie mołna utworzyć strumienia wideo'; CS: 'Nelze vytvořit video stream';
     FR: 'Impossible de créer le flux vidéo'; DE: 'Videostream kann nicht erstellt werden'; IT: 'Impossibile creare lo stream video';
     ES: 'No se puede crear el flujo de vídeo'; PT: 'Não é possível criar o fluxo de vídeo'; AF: 'Kan nie videostroom skep nie'),
    (EN: 'Cannot initialize video encoder'; PL: 'Nie mołna zainicjalizować enkodera wideo'; CS: 'Nelze inicializovat video enkodér';
     FR: 'Impossible d’initialiser l’encodeur vidéo'; DE: 'Video-Encoder kann nicht initialisiert werden'; IT: 'Impossibile inizializzare il codificatore video';
     ES: 'No se puede inicializar el codificador de vídeo'; PT: 'Não é possível inicializar o codificador de vídeo'; AF: 'Kan nie video-enkodeerder initialiseer nie'),
    (EN: 'Cannot start writing video'; PL: 'Nie mołna rozpocząć zapisu wideo'; CS: 'Nelze začít zapisovat video';
     FR: 'Impossible de démarrer l’écriture de la vidéo'; DE: 'Videoaufnahme kann nicht gestartet werden'; IT: 'Impossibile avviare la scrittura del video';
     ES: 'No se puede iniciar la escritura del vídeo'; PT: 'Não é possível iniciar a gravação do vídeo'; AF: 'Kan nie begin om video te skryf nie'),
    (EN: 'Cannot write video frame'; PL: 'Nie mołna zapisać klatki wideo'; CS: 'Nelze zapsat snímek videa';
     FR: 'Impossible d’écrire la frame vidéo'; DE: 'Videoframe kann nicht geschrieben werden'; IT: 'Impossibile scrivere il frame video';
     ES: 'No se puede escribir el fotograma de vídeo'; PT: 'Não é possível gravar o quadro de vídeo'; AF: 'Kan nie videoraam skryf nie'),
    (EN: 'Cannot save video file'; PL: 'Nie mołna zapisać pliku wideo'; CS: 'Nelze uložit video soubor';
     FR: 'Impossible d’enregistrer le fichier vidéo'; DE: 'Videodatei kann nicht gespeichert werden'; IT: 'Impossibile salvare il file video';
     ES: 'No se puede guardar el archivo de vídeo'; PT: 'Não é possível salvar o arquivo de vídeo'; AF: 'Kan nie videolêer stoor nie'),
    (EN: 'No video encoder available (H.264 or WMV)'; PL: 'Brak dostępnego enkodera wideo (H.264 lub WMV)'; CS: 'Není k dispozici video enkodér (H.264 nebo WMV)';
     FR: 'Aucun encodeur vidéo disponible (H.264 ou WMV)'; DE: 'Kein Video-Encoder verfügbar (H.264 oder WMV)'; IT: 'Nessun codificatore video disponibile (H.264 o WMV)';
     ES: 'No hay codificador de vídeo disponible (H.264 o WMV)'; PT: 'Nenhum codificador de vídeo disponível (H.264 ou WMV)'; AF: 'Geen video-enkodeerder beskikbaar (H.264 of WMV)'),
    (EN: 'File name:'; PL: 'Nazwa pliku:'; CS: 'Název souboru:';
     FR: 'Nom du fichier :'; DE: 'Dateiname:'; IT: 'Nome file:';
     ES: 'Nombre del archivo:'; PT: 'Nome do arquivo:'; AF: 'Lêernaam:'),
    (EN: 'Retouch...'; PL: 'Retusz...'; CS: 'Retuš...';
     FR: 'Retouche…'; DE: 'Retusche...'; IT: 'Ritocco...';
     ES: 'Retoque...'; PT: 'Retoque...'; AF: 'Retouchering...'),
    (EN: 'Retouch'; PL: 'Retusz'; CS: 'Retuš';
     FR: 'Retouche'; DE: 'Retusche'; IT: 'Ritocco';
     ES: 'Retoque'; PT: 'Retoque'; AF: 'Retouchering'),
    (EN: 'Erase'; PL: 'Wymaż'; CS: 'Vymazat';
     FR: 'Effacer'; DE: 'Radieren'; IT: 'Cancella';
     ES: 'Borrar'; PT: 'Apagar'; AF: 'Vee uit'),
    (EN: 'Restore'; PL: 'Przywróć'; CS: 'Obnovit';
     FR: 'Restaurer'; DE: 'Wiederherstellen'; IT: 'Ripristina';
     ES: 'Restaurar'; PT: 'Restaurar'; AF: 'Herstel'),
    (EN: 'Brush size:'; PL: 'Wielkość pędzla:'; CS: 'Velikost štětce:';
     FR: 'Taille du pinceau :'; DE: 'Pinselgröße:'; IT: 'Dimensione pennello:';
     ES: 'Tamaño del pincel:'; PT: 'Tamanho do pincel:'; AF: 'Kwasgrootte:'),
    (EN: 'Remove background'; PL: 'Usuń tło'; CS: 'Odstranit pozadí';
     FR: 'Supprimer l’arrière-plan'; DE: 'Hintergrund entfernen'; IT: 'Rimuovi lo sfondo';
     ES: 'Eliminar el fondo'; PT: 'Remover o fundo'; AF: 'Verwyder agtergrond'),
    (EN: 'Corner from which to remove background:'; PL: 'Róg, od którego usunąć tło:'; CS: 'Roh, od kterého odebrat pozadí:';
     FR: 'Coin à partir duquel supprimer l’arrière-plan :'; DE: 'Ecke, von der aus der Hintergrund entfernt wird:'; IT: 'Angolo da cui rimuovere lo sfondo:';
     ES: 'Esquina desde la que eliminar el fondo:'; PT: 'Canto a partir do qual remover o fundo:'; AF: 'Hoek van waaruit agtergrond verwyder word:'),
    (EN: 'Tolerance'; PL: 'Tolerancja'; CS: 'Tolerance';
     FR: 'Tolérance'; DE: 'Toleranz'; IT: 'Tolleranza';
     ES: 'Tolerancia'; PT: 'Tolerância'; AF: 'Toleransie'),
    (EN: 'Eraser'; PL: 'Gumka'; CS: 'Guma';
     FR: 'Gomme'; DE: 'Radiergummi'; IT: 'Gomma';
     ES: 'Goma'; PT: 'Borracha'; AF: 'Uitveër'),
    (EN: 'Black (PRL)'; PL: 'Czerń (PRL)'; CS: 'Černá (PRL)';
     FR: 'Noir (PRL)'; DE: 'Schwarz (PRL)'; IT: 'Nero (PRL)';
     ES: 'Negro (PRL)'; PT: 'Preto (PRL)'; AF: 'Swart (PRL)'),
    (EN: 'Violet (West)'; PL: 'Fiolet (Zachód)'; CS: 'Fialová (Západ)';
     FR: 'Violet (Ouest)'; DE: 'Violett (West)'; IT: 'Viola (Ovest)';
     ES: 'Violeta (Occidente)'; PT: 'Violeta (Ocidente)'; AF: 'Violet (Weste)'),
    (EN: 'Navy (offset)'; PL: 'Granat (offset)'; CS: 'Tmavě modrá (offset)';
     FR: 'Bleu marine (offset)'; DE: 'Marineblau (Offset)'; IT: 'Blu navy (offset)';
     ES: 'Azul marino (offset)'; PT: 'Azul-marinho (offset)'; AF: 'Marineblou (offset)'),
    (EN: 'Red (stamps)'; PL: 'Czerwień (stemple)'; CS: 'Červená (razítka)';
     FR: 'Rouge (tampons)'; DE: 'Rot (Stempel)'; IT: 'Rosso (timbri)';
     ES: 'Rojo (sellos)'; PT: 'Vermelho (carimbos)'; AF: 'Rooi (stempels)'),
    (EN: 'PRL samizdat - white-protein duplicator, sooty ink, smeared stencil'; PL: 'Drugi obieg PRL — powielacz białkowy, okopcony tusz, rozmazana matryca'; CS: 'Samizdat v PLR — bílkovinný cyklostyl, sazovitý inkoust, rozmazaná matrice';
     FR: 'Samizdat de la RPP — duplicateur à albumine, encre fuligineuse, stencil baveux'; DE: 'PRL-Samisdat – Eiweiß-Vervielfältiger, rußige Tinte, verschmierte Schablone'; IT: 'Samizdat della RPP — duplicatore a proteine, inchiostro fuligginoso, matrice sbavata';
     ES: 'Samizdat de la RPP — multicopista de proteína, tinta hollinienta, matriz embadurnada'; PT: 'Samizdat da RPP — duplicador de proteína, tinta fuliginosa, stencil borrado'; AF: 'PRL-samizdat — proteïen-verveelvuldiger, roetige ink, uitgesmeerde stensil'),
    (EN: 'Western spirit duplicator - crystal violet dye, alcohol smell'; PL: 'Zachodni powielacz spirytusowy — fiolet krystaliczny, zapach alkoholu'; CS: 'Západní lihový cyklostyl — krystalická violeť, zápach alkoholu';
     FR: 'Duplicateur à alcool occidental — violet de méthyle, odeur d’alcool'; DE: 'Westlicher Spiritus-Umdrucker – Kristallviolett, Alkoholgeruch'; IT: 'Duplicatore ad alcol occidentale — violetto di metile, odore di alcol';
     ES: 'Multicopista de alcohol occidental — violeta cristal, olor a alcohol'; PT: 'Duplicador a álcool ocidental — violeta cristal, cheiro a álcool'; AF: 'Westerse alkohol-verveelvuldiger — kristalviolet, alkoholreuk'),
    (EN: 'Offset duplicator master - office copy'; PL: 'Matryca powielacza offsetowego — kopia biurowa'; CS: 'Matrice offsetového cyklostylu — kancelářská kopie';
     FR: 'Matrice de duplicateur offset — copie de bureau'; DE: 'Offset-Umdruckvorlage – Bürokopie'; IT: 'Matrice per duplicatore offset — copia d''ufficio';
     ES: 'Matriz de multicopista offset — copia de oficina'; PT: 'Matriz de duplicador offset — cópia de escritório'; AF: 'Offset-verveelvuldiger-matrijs — kantoorafskrif'),
    (EN: 'Stamps, headings and official forms'; PL: 'Stemple, nagłówki i formularze urzędowe'; CS: 'Razítka, nadpisy a úřední formuláře';
     FR: 'Tampons, en-têtes et formulaires officiels'; DE: 'Stempel, Überschriften und Formulare'; IT: 'Timbri, intestazioni e moduli ufficiali';
     ES: 'Sellos, encabezados y formularios oficiales'; PT: 'Carimbos, cabeçalhos e formulários oficiais'; AF: 'Stempels, opskrifte en amptelike vorms'),
    (EN: 'Western offices - less common ink'; PL: 'Zachodnie biura — rzadszy tusz'; CS: 'Západní kanceláře — méně obvyklý inkoust';
     FR: 'Bureaux occidentaux — encre moins courante'; DE: 'Westliche Büros – seltenere Tinte'; IT: 'Uffici occidentali — inchiostro meno comune';
     ES: 'Oficinas occidentales — tinta menos común'; PT: 'Escritórios ocidentais — tinta menos comum'; AF: 'Westerse kantore — minder algemene ink'),
    (EN: 'Faded, aged copy'; PL: 'Wyblakła, stara kopia'; CS: 'Vybledlá, zestárlá kopie';
     FR: 'Copie pâlie et vieillie'; DE: 'Verblasste, gealterte Kopie'; IT: 'Copia sbiadita e invecchiata';
     ES: 'Copia desvaída y envejecida'; PT: 'Cópia desbotada e envelhecida'; AF: 'Vervaagde, verouderde afskrif'),
    (EN: 'Ink wear:'; PL: 'Zużycie tuszu:'; CS: 'Opotřebení inkoustu:';
     FR: 'Usure de l’encre :'; DE: 'Tintenabnutzung:'; IT: 'Usura dell''inchiostro:';
     ES: 'Desgaste de la tinta:'; PT: 'Desgaste da tinta:'; AF: 'Inkslytasie:'),
    (EN: 'Paint brush'; PL: 'Pędzel malowania'; CS: 'Štětec malování';
     FR: 'Pinceau de peinture'; DE: 'Malpinsel'; IT: 'Pennello pittura';
     ES: 'Pincel de pintura'; PT: 'Pincel de pintura'; AF: 'Verfkwas'),
    (EN: 'Clone brush'; PL: 'Pędzel klonowania'; CS: 'Štětec klonování';
     FR: 'Pinceau de clonage'; DE: 'Klonierpinsel'; IT: 'Pennello clonazione';
     ES: 'Pincel de clonación'; PT: 'Pincel de clonagem'; AF: 'Kloonkwas'),
    (EN: 'Dodge'; PL: 'Rozjaśnianie'; CS: 'Zesvětlení';
     FR: 'Éclaircir'; DE: 'Abwedeln'; IT: 'Schiarisci';
     ES: 'Sobreexponer'; PT: 'Clarear'; AF: 'Verhelder'),
    (EN: 'Burn'; PL: 'Ściemnianie'; CS: 'Ztmavení';
     FR: 'Assombrir'; DE: 'Nachbelichten'; IT: 'Oscura';
     ES: 'Subexponer'; PT: 'Escurecer'; AF: 'Verdonker'),
    (EN: 'Brightness brush'; PL: 'Pędzel jasności'; CS: 'Štětec jasu';
     FR: 'Pinceau de luminosité'; DE: 'Helligkeitspinsel'; IT: 'Pennello luminosità';
     ES: 'Pincel de brillo'; PT: 'Pincel de brilho'; AF: 'Helderheidskwas'),
    (EN: 'Focus brush'; PL: 'Pędzel ostrości'; CS: 'Štětec ostrosti';
     FR: 'Pinceau de netteté'; DE: 'Schärfepinsel'; IT: 'Pennello nitidezza';
     ES: 'Pincel de nitidez'; PT: 'Pincel de nitidez'; AF: 'Skerptekwas'),
    (EN: 'Bucket'; PL: 'Zalewanie'; CS: 'Kbelík';
     FR: 'Seau'; DE: 'Farbeimer'; IT: 'Secchiello';
     ES: 'Bote de pintura'; PT: 'Balde'; AF: 'Emmer'),
    (EN: 'Eyedropper'; PL: 'Próbnik'; CS: 'Kapátko';
     FR: 'Pipette'; DE: 'Pipette'; IT: 'Contagocce';
     ES: 'Cuentagotas'; PT: 'Conta-gotas'; AF: 'Pipet'),
    (EN: 'Elliptical selection'; PL: 'Zaznaczenie eliptyczne'; CS: 'Eliptický výběr';
     FR: 'Sélection elliptique'; DE: 'Elliptische Auswahl'; IT: 'Selezione ellittica';
     ES: 'Selección elíptica'; PT: 'Seleção elíptica'; AF: 'Elliptiese seleksie'),
    (EN: 'Rectangular selection'; PL: 'Zaznaczenie prostokątne'; CS: 'Obdélníkový výběr';
     FR: 'Sélection rectangulaire'; DE: 'Rechteckige Auswahl'; IT: 'Selezione rettangolare';
     ES: 'Selección rectangular'; PT: 'Seleção retangular'; AF: 'Reghoekige seleksie'),
    (EN: 'Selection display'; PL: 'Podgląd zaznaczenia'; CS: 'Zobrazení výběru';
     FR: 'Affichage de la sélection'; DE: 'Auswahl-Anzeige'; IT: 'Visualizzazione selezione';
     ES: 'Visualización de selección'; PT: 'Exibição de seleção'; AF: 'Uitstalling van seleksie'),
    (EN: 'Selection outline'; PL: 'Obrys'; CS: 'Obrys výběru';
     FR: 'Contour de sélection'; DE: 'Auswahlumriss'; IT: 'Contorno selezione';
     ES: 'Contorno de selección'; PT: 'Contorno de seleção'; AF: 'Seleksie-omtrek'),
    (EN: 'Filled'; PL: 'Wypełnione'; CS: 'Vyplněno';
     FR: 'Rempli'; DE: 'Gefüllt'; IT: 'Riempito';
     ES: 'Relleno'; PT: 'Preenchido'; AF: 'Gevul'),
    (EN: 'Protection mask'; PL: 'Maska ochronna'; CS: 'Ochranná maska';
     FR: 'Masque de protection'; DE: 'Schutzmaske'; IT: 'Maschera di protezione';
     ES: 'Máscara de protección'; PT: 'Máscara de proteção'; AF: 'Beskermingsmasker'),
    (EN: 'Cover'; PL: 'Zakryj'; CS: 'Zakrýt';
     FR: 'Couvrir'; DE: 'Abdecken'; IT: 'Copri';
     ES: 'Cubrir'; PT: 'Cobrir'; AF: 'Bedek'),
    (EN: 'Uncover'; PL: 'Odkryj'; CS: 'Odkrýt';
     FR: 'Découvrir'; DE: 'Aufdecken'; IT: 'Scopri';
     ES: 'Descubrir'; PT: 'Descobrir'; AF: 'Ontbloot'),
    (EN: 'Show protection mask'; PL: 'Pokaż maskę ochronną'; CS: 'Zobrazit ochrannou masku';
     FR: 'Afficher le masque de protection'; DE: 'Schutzmaske anzeigen'; IT: 'Mostra maschera di protezione';
     ES: 'Mostrar máscara de protección'; PT: 'Mostrar máscara de proteção'; AF: 'Wys beskermingsmasker'),
    (EN: 'Clear protection mask'; PL: 'Wyczyść maskę ochronną'; CS: 'Vymazat ochrannou masku';
     FR: 'Effacer le masque de protection'; DE: 'Schutzmaske löschen'; IT: 'Cancella maschera di protezione';
     ES: 'Borrar máscara de protección'; PT: 'Limpar máscara de proteção'; AF: 'Vee beskermingsmasker uit'),
    (EN: 'Protect selection'; PL: 'Chroń zaznaczenie'; CS: 'Chránit výběr';
     FR: 'Protéger la sélection'; DE: 'Auswahl schützen'; IT: 'Proteggi selezione';
     ES: 'Proteger selección'; PT: 'Proteger seleção'; AF: 'Beskerm seleksie'),
    (EN: 'Unprotect selection'; PL: 'Odwołaj ochronę w zaznaczeniu'; CS: 'Zrušit ochranu výběru';
     FR: 'Déprotéger la sélection'; DE: 'Schutz der Auswahl aufheben'; IT: 'Rimuovi protezione selezione';
     ES: 'Desproteger selección'; PT: 'Remover proteção da seleção'; AF: 'Verwyder beskerming van seleksie'),
    (EN: 'Lasso'; PL: 'Lasso'; CS: 'Laso';
     FR: 'Lasso'; DE: 'Lasso'; IT: 'Lazo';
     ES: 'Lazo'; PT: 'Laço'; AF: 'Lasso'),
    (EN: 'Magic wand'; PL: 'Różdżka'; CS: 'Kouzelná hůlka';
     FR: 'Baguette magique'; DE: 'Zauberstab'; IT: 'Bacchetta magica';
     ES: 'Varita mágica'; PT: 'Varinha mágica'; AF: 'Towerstaf'),
    (EN: 'Selection...'; PL: 'Zaznaczenie...'; CS: 'Výběr...';
     FR: 'Sélection…'; DE: 'Auswahl...'; IT: 'Selezione...';
     ES: 'Selección...'; PT: 'Seleção...'; AF: 'Seleksie...'),
    (EN: 'Selection'; PL: 'Zaznaczenie'; CS: 'Výběr';
     FR: 'Sélection'; DE: 'Auswahl'; IT: 'Selezione';
     ES: 'Selección'; PT: 'Seleção'; AF: 'Seleksie'),
    (EN: 'Mask'; PL: 'Maska'; CS: 'Maska';
     FR: 'Masque'; DE: 'Maske'; IT: 'Maschera';
     ES: 'Máscara'; PT: 'Máscara'; AF: 'Masker'),
    (EN: 'Batch processing'; PL: 'Przetwarzanie wsadowe'; CS: 'Dávkové zpracování';
     FR: 'Traitement par lots'; DE: 'Stapelverarbeitung'; IT: 'Elaborazione batch';
     ES: 'Procesamiento por lotes'; PT: 'Processamento em lote'; AF: 'Bondelverwerking'),
    (EN: 'Distort'; PL: 'Zniekształcenia'; CS: 'Zkreslení';
     FR: 'Distorsions'; DE: 'Verzerrungen'; IT: 'Distorsioni';
     ES: 'Distorsiones'; PT: 'Distorções'; AF: 'Verdistortings'),
    (EN: 'Load preset'; PL: 'Wczytaj ustawienie'; CS: 'Načíst předvolbu';
     FR: 'Charger le préréglage'; DE: 'Voreinstellung laden'; IT: 'Carica predefinito';
     ES: 'Cargar preajuste'; PT: 'Carregar predefinição'; AF: 'Laai voorinstelling'),
    (EN: 'Save preset'; PL: 'Zapisz ustawienie'; CS: 'Uložit předvolbu';
     FR: 'Enregistrer le préréglage'; DE: 'Voreinstellung speichern'; IT: 'Salva predefinito';
     ES: 'Guardar preajuste'; PT: 'Guardar predefinição'; AF: 'Stoor voorinstelling'),
    (EN: 'Fill color'; PL: 'Kolor wypełnienia'; CS: 'Barva výplně';
     FR: 'Couleur de remplissage'; DE: 'Füllfarbe'; IT: 'Colore di riempimento';
     ES: 'Color de relleno'; PT: 'Cor de preenchimento'; AF: 'Vulkleur'),
    (EN: 'Click the preview to set the white point'; PL: 'Kliknij podgląd, aby ustawić punkt bieli'; CS: 'Klepněte na náhled pro nastavení bodu bílé';
     FR: 'Cliquez sur l’aperçu pour définir le point blanc'; DE: 'Klicken Sie auf die Vorschau, um den Weißpunkt festzulegen'; IT: 'Fare clic sull''anteprima per impostare il punto di bianco';
     ES: 'Haga clic en la vista previa para establecer el punto blanco'; PT: 'Clique na pré-visualização para definir o ponto branco'; AF: 'Klik die voorskou om die witpunt te stel'),
    (EN: 'Color replacement brush'; PL: 'Pędzel zamiany koloru'; CS: 'Štětec náhrady barvy';
     FR: 'Pinceau de remplacement de couleur'; DE: 'Farbersetzungspinsel'; IT: 'Pennello sostituzione colore';
     ES: 'Pincel de reemplazo de color'; PT: 'Pincel de substituição de cor'; AF: 'Kleurvervangkwas'),
    (EN: 'Color to replace'; PL: 'Kolor do zamiany'; CS: 'Barva k nahrazení';
     FR: 'Couleur à remplacer'; DE: 'Zu ersetzende Farbe'; IT: 'Colore da sostituire';
     ES: 'Color a reemplazar'; PT: 'Cor a substituir'; AF: 'Kleur om te vervang'),
    (EN: 'Replacement color'; PL: 'Kolor nowy'; CS: 'Náhradní barva';
     FR: 'Couleur de remplacement'; DE: 'Ersatzfarbe'; IT: 'Colore di sostituzione';
     ES: 'Color de reemplazo'; PT: 'Cor de substituição'; AF: 'Vervangende kleur'),
    (EN: 'Retain shading'; PL: 'Zachowaj cienie'; CS: 'Zachovat stíny';
     FR: 'Conserver les ombrages'; DE: 'Schattierungen beibehalten'; IT: 'Mantieni le ombreggiatura';
     ES: 'Conservar sombras'; PT: 'Manter sombras'; AF: 'Hou skaduwee'),
    (EN: 'Protect the selected area from effects'; PL: 'Chroń zaznaczenie przed efektami'; CS: 'Chránit výběr před efekty';
     FR: 'Protéger la sélection contre les effets'; DE: 'Auswahl vor Effekten schützen'; IT: 'Proteggi la selezione dagli effetti';
     ES: 'Proteger la selección de los efectos'; PT: 'Proteger a seleção dos efeitos'; AF: 'Beskerm die seleksie teen effekte'),
    (EN: 'Remove protection from the selected area'; PL: 'Usuń ochronę z zaznaczonego obszaru'; CS: 'Odebrat ochranu z výběru';
     FR: 'Retirer la protection de la sélection'; DE: 'Schutz des ausgewählten Bereichs aufheben'; IT: 'Rimuovi la protezione dalla selezione';
     ES: 'Quitar la protección del área seleccionada'; PT: 'Remover a proteção da área selecionada'; AF: 'Verwyder beskerming van die gekose gebied'),
    (EN: 'Shows protected areas with diagonal red overlay'; PL: 'Pokazuje obszary chronione czerwonym ukośnym wzorem'; CS: 'Zobrazuje chráněné oblasti červeným šikmým překryvem';
     FR: 'Affiche les zones protégées avec un calque rouge en diagonale'; DE: 'Zeigt geschützte Bereiche mit rotem Diagonalraster an'; IT: 'Mostra le aree protette con una sovrapposizione rossa diagonale';
     ES: 'Muestra las áreas protegidas con una trama roja diagonal'; PT: 'Mostra as áreas protegidas com uma sobreposição vermelha diagonal'; AF: 'Wys beskermde gebiede met ''n diagonale rooi oorlegk'),
    (EN: 'Remove all protected areas'; PL: 'Usuń wszystkie obszary chronione'; CS: 'Odebrat ochranu ze všech oblastí';
     FR: 'Supprimer toutes les zones protégées'; DE: 'Alle geschützten Bereiche entfernen'; IT: 'Rimuovi tutte le aree protette';
     ES: 'Quitar todas las áreas protegidas'; PT: 'Remover todas as áreas protegidas'; AF: 'Verwyder alle beskermde gebiede')
  );
  // END GENERATED TEXTABLE
type
  TControlTexts = record
    Caption: string;
    Hint: string;
  end;

  TI18nNotifier = class(TComponent)
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  end;
const
  // Log i18n_debug.log jest wyłączony domyślnie: per-aktywacja okna TranslateMenuItem
  // wykonywał ~140 zapisów dyskowych (jeden na item menu), co dawało opóźnienie menu
  // po zamknięciu dialogu. Włącz tylko do diagnostyki tłumaczeń.
  cI18nDebugLog = False;
var
  gLang: TLanguage = lgPolish;
  gIndex: TDictionary<string, Integer>;
  gMenuItemOriginals: TDictionary<TMenuItem, string>;
  gMenuItemHintOriginals: TDictionary<TMenuItem, string>;
  gControlOriginals: TDictionary<TControl, TControlTexts>;
  gDebugPath: string = '';
  gNotifier: TI18nNotifier;

function T(const AEnglishText: string): string;
var
  Idx: Integer;
  Key: string;
  Found: Boolean;
begin
  Result := AEnglishText;
  if gIndex = nil then Exit;
  Key := AEnglishText;
  Found := gIndex.TryGetValue(Key, Idx);
  if not Found and (Length(Key) > 1) and (Key[Length(Key)] = ':') then
  begin
    Key := Copy(Key, 1, Length(Key) - 1);
    Found := gIndex.TryGetValue(Key, Idx);
  end;
  if not Found then
  begin
    Key := AEnglishText + ':';
    Found := gIndex.TryGetValue(Key, Idx);
  end;
  if not Found then Exit;
  case gLang of
    lgPolish:
      if TextTable[Idx].PL <> '' then Exit(TextTable[Idx].PL);
    lgEnglish:
      if TextTable[Idx].EN <> '' then Exit(TextTable[Idx].EN);
    lgGerman:
      if TextTable[Idx].DE <> '' then Exit(TextTable[Idx].DE);
    lgFrench:
      if TextTable[Idx].FR <> '' then Exit(TextTable[Idx].FR);
    lgSpanish:
      if TextTable[Idx].ES <> '' then Exit(TextTable[Idx].ES);
    lgItalian:
      if TextTable[Idx].IT <> '' then Exit(TextTable[Idx].IT);
    lgCzech:
      if TextTable[Idx].CS <> '' then Exit(TextTable[Idx].CS);
    lgPortuguese:
      if TextTable[Idx].PT <> '' then Exit(TextTable[Idx].PT);
    lgAfrikaans:
      if TextTable[Idx].AF <> '' then Exit(TextTable[Idx].AF);
  end;
end;

function CurrentLanguage: TLanguage;
begin
  Result := gLang;
end;

function DetectLanguage: TLanguage;
var
  LID: Word;
  P: Word;
begin
  LID := GetUserDefaultUILanguage;
  P := LID and $3FF;
  case P of
    LANG_POLISH: Result := lgPolish;
    LANG_ENGLISH: Result := lgEnglish;
    LANG_GERMAN: Result := lgGerman;
    LANG_FRENCH: Result := lgFrench;
    LANG_SPANISH: Result := lgSpanish;
    LANG_ITALIAN: Result := lgItalian;
    LANG_CZECH: Result := lgCzech;
    LANG_PORTUGUESE: Result := lgPortuguese;
    LANG_AFRIKAANS: Result := lgAfrikaans;
  else
    Result := lgEnglish;
  end;
end;

function MenuLookupKey(const S: string): string;
var
  Stripped: string;
begin
  if gIndex.ContainsKey(S) then Exit(S);
  Stripped := StripHotkey(S);
  if gIndex.ContainsKey(Stripped) then Exit(Stripped);
  Result := S;
end;

procedure TI18nNotifier.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;
  if Operation = opRemove then
  begin
    if (gControlOriginals <> nil) and (AComponent is TControl) then
      gControlOriginals.Remove(TControl(AComponent));
    if (gMenuItemOriginals <> nil) and (AComponent is TMenuItem) then
    begin
      gMenuItemOriginals.Remove(TMenuItem(AComponent));
      if gMenuItemHintOriginals <> nil then
        gMenuItemHintOriginals.Remove(TMenuItem(AComponent));
    end;
  end;
end;

procedure TranslateMenuItem(M: TMenuItem);
var
  I: Integer;
  Key: string;
begin
  if M.Caption <> '' then
  begin
    if not gMenuItemOriginals.TryGetValue(M, Key) then
    begin
      Key := MenuLookupKey(M.Caption);
      gMenuItemOriginals.Add(M, Key);
      M.FreeNotification(gNotifier);
    end;
    if cI18nDebugLog then
      try
        TFile.AppendAllText(gDebugPath,
          FormatDateTime('hh:nn:ss.zzz', Now) +
          '  ITEM cap=[' + M.Caption + '] key=[' + Key + '] T=[' + T(Key) + '] inIdx=' +
          BoolToStr(gIndex.ContainsKey(Key), True) + ' lang=' +
          IntToStr(Ord(gLang)) + sLineBreak);
      except
      end;
    M.Caption := T(Key);
  end;
  if M.Hint <> '' then
  begin
    if not gMenuItemHintOriginals.TryGetValue(M, Key) then
    begin
      Key := M.Hint;
      gMenuItemHintOriginals.Add(M, Key);
      M.FreeNotification(gNotifier);
    end;
    M.Hint := T(Key);
  end;
  for I := 0 to M.Count - 1 do
    TranslateMenuItem(M.Items[I]);
end;

procedure TranslateControlTree(W: TWinControl);
var
  I: Integer;
  C: TControl;
  N: string;
  Cur: string;
  Texts: TControlTexts;
  HasCaption: Boolean;
begin
  for I := 0 to W.ControlCount - 1 do
  begin
    C := W.Controls[I];
    if not gControlOriginals.TryGetValue(C, Texts) then
    begin
      HasCaption := GetPropInfo(C.ClassType, 'Caption') <> nil;
      Texts.Caption := '';
      if HasCaption then
        Texts.Caption := GetPropValue(C, 'Caption', False);
      Texts.Hint := C.Hint;
      gControlOriginals.Add(C, Texts);
      C.FreeNotification(gNotifier);
    end;
    if (Texts.Caption <> '') and (GetPropInfo(C.ClassType, 'Caption') <> nil) then
    begin
      N := T(Texts.Caption);
      Cur := GetPropValue(C, 'Caption', False);
      if N <> Cur then
        SetPropValue(C, 'Caption', N);
    end;
    if Texts.Hint <> '' then
      C.Hint := T(Texts.Hint);
    if C is TWinControl then
      TranslateControlTree(TWinControl(C));
  end;
end;

procedure TranslateForm(AForm: TForm);
var
  I, J: Integer;
  C: TComponent;
  SBar: TStatusBar;
  S, N: string;
  FormTexts: TControlTexts;
begin
  if AForm = nil then Exit;
  if not gControlOriginals.TryGetValue(AForm, FormTexts) then
  begin
    FormTexts.Caption := AForm.Caption;
    FormTexts.Hint := '';
    gControlOriginals.Add(AForm, FormTexts);
    AForm.FreeNotification(gNotifier);
  end;
  if FormTexts.Caption <> '' then
    AForm.Caption := T(FormTexts.Caption);
  if AForm.Menu <> nil then
    for I := 0 to AForm.Menu.Items.Count - 1 do
      TranslateMenuItem(AForm.Menu.Items[I]);
  TranslateControlTree(AForm);
  for I := 0 to AForm.ComponentCount - 1 do
  begin
    C := AForm.Components[I];
    if C is TPopupMenu then
      for J := 0 to TPopupMenu(C).Items.Count - 1 do
        TranslateMenuItem(TPopupMenu(C).Items[J])
    else if C is TStatusBar then
    begin
      SBar := TStatusBar(C);
      for J := 0 to SBar.Panels.Count - 1 do
        if SBar.Panels[J].Text <> '' then
        begin
          S := SBar.Panels[J].Text;
          N := T(S);
          if N <> S then SBar.Panels[J].Text := N;
        end;
    end;
  end;
end;

procedure SetLanguage(ALang: TLanguage);
var
  I: Integer;
begin
  gLang := ALang;
  if cI18nDebugLog then
  begin
    gDebugPath := ExtractFilePath(ParamStr(0)) + 'i18n_debug.log';
    try
      TFile.AppendAllText(gDebugPath,
        FormatDateTime('hh:nn:ss.zzz', Now) +
        ' SetLanguage lang=' + IntToStr(Ord(ALang)) + ' forms=' +
        IntToStr(Screen.FormCount) +
        ' mainMenuAssigned=' + BoolToStr((Screen.FormCount > 0) and
          (Screen.Forms[0].Menu <> nil), True) + sLineBreak);
    except
    end;
  end;
  for I := 0 to Screen.FormCount - 1 do
  begin
    TranslateForm(Screen.Forms[I]);
    if Screen.Forms[I] is TFotoForm then
      TFotoForm(Screen.Forms[I]).RefitButtons;
  end;
end;

procedure TI18nEvents.ActiveFormChanged(Sender: TObject);
begin
  if Screen.ActiveForm <> nil then
  begin
    TranslateForm(Screen.ActiveForm);
    if Screen.ActiveForm is TFotoForm then
      TFotoForm(Screen.ActiveForm).RefitButtons;
  end;
end;

var
  I: Integer;
initialization
  gIndex := TDictionary<string, Integer>.Create;
  gMenuItemOriginals := TDictionary<TMenuItem, string>.Create;
  gMenuItemHintOriginals := TDictionary<TMenuItem, string>.Create;
  gControlOriginals := TDictionary<TControl, TControlTexts>.Create;
  gNotifier := TI18nNotifier.Create(nil);
  gI18nEvents := TI18nEvents.Create;
  Screen.OnActiveFormChange := gI18nEvents.ActiveFormChanged;
  for I := Low(TextTable) to High(TextTable) do
  begin
    if gIndex.ContainsKey(TextTable[I].EN) then
      gIndex[TextTable[I].EN] := I
    else
      gIndex.Add(TextTable[I].EN, I);
  end;

finalization
  gIndex.Free;
  gMenuItemOriginals.Free;
  gMenuItemOriginals := nil;
  gMenuItemHintOriginals.Free;
  gMenuItemHintOriginals := nil;
  gControlOriginals.Free;
  gControlOriginals := nil;
  // gNotifier celowo NIE jest zwalniany: formy (i ich kontrolki) żyją dłużej niż
  // ta sekcja finalization (Vcl.Forms kończy się później), a zniszczenie kontrolki
  // wywołuje Notification na gNotifier - zwolniony obiekt dałby AV przy wyjściu.
  // Słowniki wyzerowane na nil powyżej, więc strażnik w Notification je pominie.
  gI18nEvents.Free;

end.
