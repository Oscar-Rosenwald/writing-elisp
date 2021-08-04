;;; Variables

;; Parts
(defcustom write-parts nil
  "A list of names of all the parts of the story, regardless how they are sorted in the directory.")

(defcustom write-parts-directories-alist nil
  "Alist of parts (same as `write-parts') and their respective directories.")

;; Others
(defcustom write-picking-format nil
  "The colour of the symbol (a-z,A-Z,1-9,...) used by `write-display-choices'. Has the form e.g. '(:foreground \"red\").")

(defcustom write-number-of-picking-lines 40
  "The number of lines `write-display-choices' will display below one another before setting another column")

;; Outline
(defcustom write-standard-file-extentions "\\(org\\)\\|\\(fountain\\)"
  "The extentions for standard text files (no pictures)")
(defcustom write-always-insert-new-scene nil
  "When calling `write-forward-outline', if this is t, don't ask to insert a new scene, just do it. If this is nill, ask first.")
(defcustom write-always-skip-non-matching-headings nil
  "When set to t, `write-forward-outline' and its variants (like `write-help--outline',...) don't ask when crossing to another chapter/section (it will skip headings of a different level than the original scene automatically).")

;; Side window configurations
(defcustom  write-side-configs-alist nil
    "An alist of actions to performe when setting a configuration.

The format is:

	(\"file-in-`write-main-directory'\" . ACTION)

ACTION assumes the point if in the side-window--1. It ends with point in main window.

NOTE: These actions only work if the file is in the
side-window--1. If it's the second, no special actions related to
it will take effect.")

;; Directories

(defcustom  write-main-directory nil
  "The directory with everything about the story in it.")
(defcustom write-family-directory nil
  "Continuation of the mirectory leading to the family trees.")
(defcustom write-outline-directory ""
  "The directory where outline files reside. This directory is further divided by parts, but the part subdirectories are not included here. To get the right directory with the desired outline files for chapters, use the `write-outline-directory' function")

;; Completion lists

(defvar write-chapters nil "Completion list of all the chapters.")
(defvar write-characters nil "Completion list of all the main characters.")

;; Current things

(defvar write-config nil "Current configuration as a list of lists.

Form:

	FILE-NAME
	(FILE-NAME DELTA)
	<FILE-NAME>

FILE-NAME is the full path to the file.

DELTA is the size by which the upper window in the VV
configuration was enlarged. Positive means the upper window is
bigger, negative means smaller. 0 means they are the same.

The order is `write-current-side--1', `write-current-side--2'. There is
no need for main-window, and the last argument may be omitted, if
there are only two windows in the current config.")
(defcustom write-current-part nil
  "Name of the current story written - O králíčkovi a jelenovi,...

Set for knowing which chapters have been loaded, so it doesn't have to happen
again.")
(defcustom write-current-chapter nil
  "The name of the current chapter I'm writing")
(defcustom write-spelling-dictionary nil
  "Private dictionary to get the special words for the story from.")

(defcustom write-map-extension nil
  "The extention (string) for all the map files, excluding the dot.")

(defcustom write-switch-to-side-when-special nil
  "Controls whether to switch to the side window when a special
  config is called (like calling the map and places at once -> it
  would jumpt to spaces")
(defcustom write-new-session t
  "When starting a session for the first time, this is t. It allows advice of write-setup to only run some code in this case.")
(defcustom write-places-heading-level 1
  "How deep to go in the headings when searching for a concrete
place.")
(defcustom write-other-directory "other/"
  "Continuation of the main directory leading to others.")
(defcustom write-terms "other/terms.org"
  "Path to file \"terms.org\", which houses all terms, names and places which must be or have been sorted out somehow. Elements are inseted as org headings with TODO, and the body of the heading contains the occurance of the term as a chapter name.")
(defcustom write-map-directory "places/map"
  "Continuation of the main directory leading to map directory.")
(defcustom write-characters-directory "characters/main/"
  "Continuation of the main directory leading to the directory with main characters and their profiles.")
(defcustom write-timeline nil
  "Continuation of the main directory of timeline.org")
(defcustom write-all-other-directories nil
  "A list of all directories not already included elsewhere with files which could ever be wanted to be viewed.

Continuations of the main directory.")
(defvar write-history-config nil
  "The last configuration before it was changed.")
(defvar write-window " *writing choice*")

(defconst write-picking-symbols
  '(?a ?b ?c ?d ?e ?f ?g ?h ?i ?j ?k ?l ?m ?n ?o ?p ?r ?s ?t ?u ?v ?w ?x ?y ?z ?A ?B ?C ?D ?E ?F ?G ?H ?I ?J ?K ?L ?M ?N ?O ?P ?R ?S ?T ?U ?V ?W ?X ?Y ?Z ?0 ?1 ?2 ?3 ?4 ?5 ?6 ?7 ?8 ?9 ?` ?- ?= ?\[ ?\] ?' ?\\ ?, ?. ?/ ?! ?@ ?# ?$ ?% ?^ ?& ?* ?\( ?\) ?+ ?{ ?} ?: ?| ?< ?> ??))

(defun write-terms ()
  "not /"
  (concat (write-main-directory) write-terms))
(defun write-main-directory ()
  "/"
  write-main-directory)
(defun write-chapters-directory ()
  "/"
  (cdr (assoc (write-part) write-parts-directories-alist)))
(defun write-characters-directory ()
  "/"
  (concat (write-main-directory) write-characters-directory))
(defun write-map-directory ()
  "/"
  (concat (write-main-directory) write-map-directory))
(defun write-part ()
  "not /"
  write-current-part)
(defun write-chapter ()
  "not /"
  write-current-chapter)
(defun write-blank ()
  "not /"
  (concat (write-chapters-directory) "blank.org"))
(defun write-other-directory ()
  "/"
  (concat (write-main-directory) write-other-directory))
(defun write-timeline ()
  "not /"
  (concat (write-main-directory) write-timeline))
(defun write-family-directory ()
  "/"
  (concat (write-main-directory) write-family-directory))
(defun write-outline-directory-by-part ()
  "/"
  (concat (write-main-directory) write-outline-directory (write-part) "/"))
(defun write-outline-directory ()
  "/"
  (concat (write-main-directory) write-outline-directory))

(defface writing-face '((default :family "Times New Roman")) "The face for writing books.")