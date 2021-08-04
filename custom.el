(setq write-parts
  '("O králíčkovi a jelenovi"
	"Jelen sadista a králíček Tonda"
	"Králíček ohnivák a lišky ryšky"
	"Mlčení koloušků"
	"Smrt krásných jelenů"
	"Parohy"
	"Jelénium vrací úder"
	"Kde se pasou"))

(setq write-parts-directories-alist
  '(;; Kterak jelen
	("O králíčkovi a jelenovi" . "/home/oscar/Documents/writing/Jelen Saga/chapters/Kterak jelen/O králíčkovi a jelenovi/")
	("Jelen sadista a králíček Tonda" . "/home/oscar/Documents/writing/Jelen Saga/chapters/Kterak jelen/Jelen sadista a králíček Tonda/")
	("Králíček ohnivák a lišky ryšky" . "/home/oscar/Documents/writing/Jelen Saga/chapters/Kterak jelen/Králíček ohnivák a lišky ryšky/")
	("Mlčení koloušků" . "/home/oscar/Documents/writing/Jelen Saga/chapters/Kterak jelen/Mlčení koloušků/")
	;; Jelení války
	("Smrt krásných jelenů" . "/home/oscar/Documents/writing/Jelen Saga/chapters/Jelení války/Smrt krásných jelenů/")
	("Parohy" . "/home/oscar/Documents/writing/Jelen Saga/chapters/Jelení války/Parohy/")
	("Jelénium vrací úder" . "/home/oscar/Documents/writing/Jelen Saga/chapters/Jelení války/Jelénium vrací úder/")
	("Kde se pasou" . "/home/oscar/Documents/writing/Jelen Saga/chapters/Jelení války/Kde se pasou/")))

(setq write-side-configs-alist
	  '(("/home/oscar/Documents/writing/Jelen Saga/places/map/map.png" 12 "/home/oscar/Documents/writing/Jelen Saga/places/map/map.org")
		
		("/home/oscar/Documents/writing/Jelen Saga/animals/bunny/bunny.png" -3 "/home/oscar/Documents/writing/Jelen Saga/animals/bunny/bunny.org")
		("/home/oscar/Documents/writing/Jelen Saga/animals/jelen/jelen.png" 1 "/home/oscar/Documents/writing/Jelen Saga/animals/jelen/jelen.org")
		
		("/home/oscar/Documents/writing/Jelen Saga/organisation/editing.org" 11 "")
		("/home/oscar/Documents/writing/Jelen Saga/organisation/outline.org" -16 "/home/oscar/Documents/writing/Jelen Saga/organisation/timeline.org")

		("/home/oscar/Documents/writing/Jelen Saga/places/layouts/Byskej/Hlavní zasedací místnost Králíků v Budovách Shromáždění.png" 4 "")
		("/home/oscar/Documents/writing/Jelen Saga/places/layouts/Byskej/Zasedací síň Shromáždění.png" 7 "")
		("/home/oscar/Documents/writing/Jelen Saga/places/layouts/Kalkaš/Hodovní síň.png" 8 "")
		("/home/oscar/Documents/writing/Jelen Saga/places/layouts/Kalkaš/Elisova pracovna.png" 1 "")
		("/home/oscar/Documents/writing/Jelen Saga/places/layouts/Parožnovy/Parožnovi.png" 1 "")

		("/home/oscar/Documents/writing/Jelen Saga/characters/rodokmeny/Aneta.pdf" 3 "/home/oscar/Documents/writing/Jelen Saga/characters/main/Aneta.org")
		("/home/oscar/Documents/writing/Jelen Saga/characters/rodokmeny/jeleni.org" -10 "")
		("/home/oscar/Documents/writing/Jelen Saga/characters/rodokmeny/Franta.pdf" 3 "/home/oscar/Documents/writing/Jelen Saga/characters/main/Franta.org")
		("/home/oscar/Documents/writing/Jelen Saga/characters/rodokmeny/Tonda.pdf" 3 "/home/oscar/Documents/writing/Jelen Saga/characters/main/Tonda.org")
		("/home/oscar/Documents/writing/Jelen Saga/characters/rodokmeny/lišky.pdf" 2 "")
		("/home/oscar/Documents/writing/Jelen Saga/characters/rodokmeny/vlci.pdf" 2 "/home/oscar/Documents/writing/Jelen Saga/characters/main/Hugo.org")))

(setq write-all-other-directories
	  '("animals/"
		"organisation/"
		"places/layouts/"))
(setq write-spelling-dictionary (expand-file-name "~/Documents/writing/Jelen Saga/stuff/.spelling.en.pws"))

(setq write-always-insert-new-scene t)
	  
(setq write-picking-format '(:foreground "red"))
(setq write-number-of-picking-lines 30)
(setq write-map-extension "png")
(setq write-switch-to-side-when-special t)
(setq write-places-heading-level 2)

(setq write-main-directory (expand-file-name "~/Documents/writing/Jelen Saga/"))
(setq write-current-part "Králíček ohnivák a lišky ryšky")
(setq write-family-directory "characters/rodokmeny/")
(setq write-timeline "organisation/timeline.org")
(setq write-map-directory "places/map/")
(setq write-outline-directory "outline/")