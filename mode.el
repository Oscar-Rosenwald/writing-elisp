;; -*-eval: (hs-minor-mode 1); eval: (hs-hide-all); eval: (auto-complete-mode -1);-*-
(require 'dash)
(require 'cl)
(defun write-vv-p ()
  "Returns t if the current configuration is 'VV. Returns nil, if it is 'HV.

In case the configuration has not been set, causes an error."
  (unless write-config (error "No configuration is set"))
  (unless (listp write-config) (error "write-config is supposed to be a list, but it is %S" write-config))
  (let ((len (length write-config)))
	(when (or (< len 2)
			  (> len 3))
	  (error "There is something TERRIBLY wrong. WRITE-config (%S) is supposed to only have 2 or 3 elements." write-config))
	(= (length write-config) 3)))

(defun write-load-completions (CHARACTERS &optional PART FORCE)
  "Load appropriate completions. Then returns the result. This
  function is not interactive.

If CHARACTERS is non-nil, load the characters from `write-characters-directory'. Otherwise loads chapters from `write-part-directory', or from PART if it is given.

When PART is not the same as `write-current-part', sets the `write-current-part' to the
value of PART. If it is the same, doesn't do anything.

If `write-characters' is already loaded, does nothing. If FORCE is non-nil, force the load."
  (unless (or (null PART)
			  (member PART write-parts))
	(error "write-load-completions was give %S as a part, but such a part doesn't exist." PART))
  (unless (or (null PART) (string= PART (write-part)))
	(setq write-current-part PART))
  (if CHARACTERS
	  (progn (setq write-characters (write-load-characters))
			 write-characters)
	(setq write-chapters (write-load-chapters))
	write-chapters))

(defun write-load-chapters ()
  (let (files)
	(dolist (file (directory-files (write-chapters-directory)) files)
	  (if (string-match "^[0-9]+ - .*\\.org" file)
		  (push ;;(substring file
				;;;		   (+ (string-match "-" file) 2) (- (length file) 4))
		   (substring file 0 (- (length file) 4))
		   files)))))
(defun write-load-characters ()
  (let (files)
	(dolist (file (directory-files (write-characters-directory)) files)
	  (unless (or (string= "template.org" file)
				  (string= "." file)
				  (string= ".." file)
				  (string-match "^\\..*" file))
		(push (substring file
						 0 (- (length file) 4))
			  files)))))

(defun write-setup (&optional NEW)
  "Setup the writing environment.

HVK - two windows side-by-side. VVk - main writing window on the left, two
windows on the right.

Sets up the environment, prepares the correct chapter by
`write-current-chapter' in the main window and opens the blank
window in the side window. `write-current-chapter' is loaded from
\"~/Documents/emacs/.write-current-chapter\"

Does not load any completions, unless it needs to. Only controls
the window configuration and the current chapter. If called
again, after having set up the environment already (`write-config'
will be set at that point), it only deals with the main window
and calls `write-set-config' to deal with the rest.

This function only sets the `write-config'. It does not find files.
That is the job of `write-set-config'.

When NEW is non-nil, changes the current chapter or part in
`write-current-chapter' and `write-current-part'.

`write-before-new-hook' is run when when a new session is created. `write-after-setup-hook' is run every time, after this function."
  (interactive "P")
  (let ((start (if write-config t
				 (y-or-n-p "Want to start a writing session?"))))
	(when start
	  (setq write-current-chapter
			(with-temp-buffer
			  (insert-file-contents (expand-file-name "~/Documents/emacs/.write-current-chapter"))
			  (buffer-string)))
	  (when (or (member "Down" (transient-args 'write-action))
				(member "Switch" (transient-args 'write-action)))
		(setq NEW t))
	  (when NEW
		(let ((chapter-p (= (write-pick nil '(("c" "Chapter") ("p" "Part"))) 0)))
		  (if chapter-p
			  ;; Changing chapter
			  (write-change-chapter)
			;; Changing the part -> requires changing the chapter
			;; TODO Will be done later.
			(write-change-part))))
	  (unless write-config 						; When `write-config' hasn't been set yet...
		;; Opening files for the first time
		;; Set `write-config' to the value of 'HV, blank.org
		(run-hooks 'write-when-new-hook)
		(setq write-config (list nil (list (write-blank) 0)))) ; `write-config' is a list of lists.
	  (define-key global-map (kbd "M-[") 'write-action)
	  (write-set-config)))
  (run-hooks 'write-after-setup-hook))

(defun write-change-part ()
  "Changes the current part.

Sets `write-current-part' to nil, so it has to be set outside."
  (setq write-current-part
		(let ((completion-ignore-case t))
		  (completing-read
		   (format "Change part to (%s): " (write-part))
		   write-parts nil t nil nil (write-part))))
  (write-change-chapter))
(defun write-change-chapter ()
  "Changes the current chapter. Only interested in the name, not the number."
  (let ((load (write-load-completions nil (write-part))))
	(setq write-current-chapter
		  (let ((completion-ignore-case t))
			(completing-read
			 (format "Change chapter to (%s): " (write-chapter))
			 load nil 'confirm nil nil (write-chapter) t)))
	(shell-command (format "echo -n \"%s\" > ~/Documents/emacs/.write-current-chapter"
						   write-current-chapter))
	(setq write-config (if write-config
						   (push nil (cdr write-config))
						 nil))
	(when (not (member write-current-chapter load))
	  (write-create-chapter))))
(defun write-create-chapter ()
  "Create a new chapter, open a new buffer and safe the file where it belongs.

Does not set `write-current-main'. It must be set outside of this function."
  (let ((number (1+ (length (write-load-completions nil))))
		file)
	(setq file (concat (number-to-string number) " - " (write-chapter) ".org"))
	;; The current chapter has been changed by `write-change-chapter'.
	;; `write-chapter' function returns this new chapter now.
	(find-file file)
	(setq-local ispell-personal-dictionary write-spelling-dictionary)
	(buffer-face-set "writing-face")
	(setq write-current-chapter (concat (number-to-string number)
  										" - "
										(write-chapter)))
	(shell-command (format "echo -n \"%s\" > ~/Documents/emacs/.write-current-chapter"
						   ;; (concat (number-to-string number)
						   ;; 		   " - "
								   (write-chapter)))
	(write-file file)))

(defun write-set-config ()
  "Sets the window configuration to what is is as indicated by `write-config'.

Does not set any of the values, unless it is the first time this
is called. Only sets the window configuration. Should never be
called by the user directly, so as to avoid the problem of
wanting to set something when there isn't anything in `write-config'.
This is because even when the main window isn't set yet, the side
one is set by `write-setup' already and this function counts on
that."
  (interactive)
  (delete-other-windows)
  (write-vv-p)								; Checks `write-config' has the right number of arguments.
  (if (car write-config)
	  (progn (find-file (car write-config))
			 (setq-local ispell-personal-dictionary write-spelling-dictionary)
			 (buffer-face-set "writing-face"))
	;; (find-file (concat (write-chapters-directory) "* - " (write-chapter) ".org") t)
	(find-file (concat (write-chapters-directory) (write-chapter) ".org") t)
	(setq-local ispell-personal-dictionary write-spelling-dictionary)
	(buffer-face-set "writing-face")
	(setq write-config (push
						(buffer-file-name (current-buffer))
						(cdr write-config))))
  (split-window-horizontally)
  (other-window 1)
  (find-file (car (nth 1 write-config)))
  (setq-local ispell-personal-dictionary write-spelling-dictionary)
  (buffer-face-set "writing-face")
  (when (write-vv-p)
	(split-window-vertically
	 (+ (/ (window-height) 2) (nth 1 (cadr write-config))))
	(other-window 1)
	(find-file (nth 2 write-config))
	(setq-local ispell-personal-dictionary write-spelling-dictionary)
	(buffer-face-set "writing-face"))
  (other-window 1))

(defun write-last-config ()
  (interactive)
  (setq write-config write-history-config)
  (write-set-config))

(defun write-change-config (WHICH TO &optional DELTA NO-LOAD SWITCH)
  "Changes `write-config' as requested.

WHICH must be an integer between 1 and 3. An error is thrown if
not. This indicates which one of the three vales of `write-config' to
change. 1 means the first, 3 the last.

TO is the new value. It is a string - a full file path to the new
file. Can be `nil` if we wish to delete the last window.

The optional DELTA only takes effect if WHICH is 2 or 3. This
sets the DELTA of the upper window in VV configuration. If it is
omitted, automatically set to 0.

The optional NO-LOAD controls whether we want to \"re-draw\" the
whole screen. If 't', we do not do it. If omitted or 'non-nil',
we redraw.

Optional SWITH control whether to stay in the new window,
influenced by `write-switch-to-side-when-special'."
  (unless (equal write-history-config write-config)
	(setq write-history-config write-config))
  (unless (and (> WHICH 0) (< WHICH 4)	; Skip if WHICH is in the right interval AND...
			   (or (stringp TO)			; ...TO is either a string OR...
				   (and (null TO)		; ...nil
						(= WHICH 3)))	; (provided we're deleting the last item), AND...
			   (or (null DELTA)			; ...DELTA is either omitted...
				   (integerp DELTA)))	; ...or an integer
	(error "Some wrong arguments. write-change-config was given %S %S %S" WHICH TO DELTA))
  (cond ((= WHICH 1) (setq write-config
						   (push TO
								 (cdr write-config))))
		((= WHICH 2) (if (write-vv-p)
						 ;; We have a VV config.
						 ;; There is a third element in `write-config'.
						 (setq write-config
							   (list (car write-config)
									 (list TO (if DELTA ; If DELTA is given...
												  DELTA ; Set it to that number (checked above)
												0))		; otherwise set to 0
									 (nth 2 write-config)))
					   ;; There is no third element in `write-config'.
					   (setq write-config
							 (list (car write-config)
								   (list TO (if DELTA ; If DELTA is given...
												DELTA ; Set it to that number (checked above)
											  0)))))) ; otherwise set to 0
		((= WHICH 3) (if TO
						 (setq write-config
							   (list (car write-config)
									 (list (car (cadr write-config))
										   (if DELTA
											   DELTA
											 (if (assoc (car (cadr write-config)) write-side-configs-alist)
												 (cadr (assoc (car (cadr write-config)) write-side-configs-alist))
											   0)))
									 TO))
					   (setq write-config
							 (list (car write-config)
								   (cadr write-config))))))
  (unless NO-LOAD
	(write-set-config)
	(when (and SWITCH write-switch-to-side-when-special)
	  (if (= WHICH 3)
		  (other-window 2)
		(other-window 1)))))

(defun write-vv-to-hv-upper ()
  "Deletes the upper window in the VV configuration. Leaves the
lower one, changes the config to HV and, of course, redisplays."
  (interactive)
  (when (write-vv-p)
	(let ((delta (cadr (cadr write-config)))
		  (new (car (last write-config))))
	  (write-change-config 2 new delta)
	  (write-change-config 3 nil))))
(defun write-vv-to-hv-lower ()
  "Deletes the lower window in the VV configuration. Leaves the
upper one, changes the config to HV and redisplays."
  (interactive)
  (when (write-vv-p)
	(write-change-config 3 nil)))

(defun write-make-paths-readable (LIST)
  "Takes a list LIST of full filenames, and returns a list of
files withouth the leading directories."
  (let (list)
	(reverse
	(dolist (elem LIST list)
	  (push (substring
			 elem
			 (string-match "\[^/\]+$" elem))
			list)))))

(defun write-headings-pick (FILE LEVEL &optional LEVEL-CHECK)
  "In the FILE, search for all headings of level LEVEL and offer
  them to be picked with `write-pick'.

Returns the string (heading), which was chosen.

When optional LEVEL-CHECK is non-nil, it must be a function. This function is used to check the heading level, to see if the heading is going to be included in the offers to pick from. This function must be of type (function (level point)), where <function> is the name, and <level> is the result of `org-outline-level', and <point> is the point the heading is at. This is to be quite general."
  (find-file-noselect FILE)
  (set-buffer (get-file-buffer FILE))
  (beginning-of-buffer)
  (save-excursion
	(let (subs list heading)
	  (while (not (= (point) (buffer-end 1)))
		(when (not (org-on-heading-p))	; This will only happen the first time.
		  (outline-next-heading))
		(when (if LEVEL-CHECK
				  (funcall LEVEL-CHECK (org-outline-level) (point-at-bol))
				(<= (org-outline-level) LEVEL))
		  (setq subs (substring
					  (buffer-substring-no-properties (point) (point-at-eol))
					  (string-match "\[^ *\]" (buffer-substring-no-properties (point) (point-at-eol)))
					  (length (buffer-substring (point) (point-at-eol)))))
		  (dotimes (time (1- (org-outline-level)))
			(setq subs (concat "-" subs)))
		  ;; (message subs)
		  (push subs list))
		(outline-next-heading))
	  ;; At this point the list is reversed.
	  (setq list (reverse list))
	  (setq heading (nth (write-pick t list) list))
	  (substring heading
				 (string-match "[^-]" heading)))))
;;;
;;;
;;; Finding
;;;
;;;

;;; Map
(defun write-find-file (UP EXTENSION DIRECTORY &optional SWITCH SPECIAL DELTA)
  "Finds the specified file in one of the side windows.

If UP is 'non-nil', opens the file in the lower side window.
Otherwise, in the upper.

EXTENTION specifies which files to look for. It only needs the letters:
	(write-find-file t \"org\" ...) -> looks for \"\\.org$\"

DIRECTORY specifies in which directory to look. It goes recursivelly.

The optional SWITCH means move to the new window if
`write-switch-to-side-when-special' is t.

SPECIAL means we want to only use UP and SWITCH and find a
complete path in EXTENSION. DELTA is the delta passed to
`write-change-config' if it is given. If not, we look for a delta in
the `write-side-configs-alist'.

Returns the name of the file we chose."
  (if SPECIAL
	  (if UP
		  (write-change-config
		   2 EXTENSION (or DELTA
						   (cadr (assoc EXTENSION write-side-configs-alist)))
		   nil SWITCH)
		(write-change-config 3 EXTENSION nil nil SWITCH))
	(let ((files (directory-files-recursively DIRECTORY (concat "^[^.][^/]+\." EXTENSION "$")))
		  new-file)
	  (cond ((= 1 (length files))
			 (setq new-file (car files)))
			((= 0 (length files))
			 (error "There are no files in the directory %s with the extension %s" DIRECTORY EXTENSION))
			(t (setq new-file (nth (write-pick t (write-make-paths-readable files))
								   files))))
	  (if UP
		  (progn
			(write-change-config 2 new-file (cadr (assoc new-file write-side-configs-alist)))
			(when (and SWITCH write-switch-to-side-when-special)
			  (other-window 1)))
		(find-file-noselect new-file)
		(write-change-config 3 new-file)
		(when (and SWITCH write-switch-to-side-when-special)
		  (other-window 2)))
	  (setq EXTENSION new-file)))
  EXTENSION)
(defun write-find-file-choose (UP DIRECTORY &optional FILE DELTA LEVEL-CHECK)
  "Finds a file using `write-find-file' in the DIRECTORY (recursive).
  UP is passed to that as well.

If FILE is t, DIRECTORY is a full filename. DELTA only takes
effect if FILE is t. It is the delta, which will be passed to
`write-find-file' and then to `write-change-config'.

LEVEL-CHECK is a function, which will be passed to `write-headings-pick'. See that for more detail.

Does not need an extention, as it must be an org file or a fountain file (for outlining scenes).

How deep into the haedings to go is controlled by
`write-places-heading-level' and whether to finish on that heading
rather than in the editing window by
`write-switch-to-side-when-special'."
  (if FILE
	  (write-find-file UP DIRECTORY nil nil t DELTA)
	(write-find-file UP write-standard-file-extentions DIRECTORY))
  (other-window 1)
  (unless UP
	(other-window 1))
  (let ((heading-line
		 (write-headings-pick (buffer-file-name (current-buffer))
							  write-places-heading-level
							  LEVEL-CHECK)))
	(while (progn (re-search-forward (format
									  "^\\** ?%s$"
									  heading-line
									  nil t))
				  (not (outline-on-heading-p t)))
	  ;; Just do it over and over
	  ))
  (beginning-of-line)
  (outline-show-children (org-outline-level))
  (recenter-top-bottom 0)
  (unless write-switch-to-side-when-special
	(other-window -1)
	(unless UP
	  (other-window -1))))

(defun write-find-couple (FILE)
  "Find two files for two side windows.

FILE is the first filename (full) of the two. The second one must
be in the `write-side-configs-alist'. If it is not, only the first
one will be found, as if normal `write-find-file' was called.

One of the two, always the second one, is editable. This one goes
on the top so it can be controled with \\[scroll-other-window].
The other one, usually a picture, will be on the lower side
window."
  (let ((delta (cadr (assoc FILE write-side-configs-alist)))
		(second (car (last (assoc FILE write-side-configs-alist)))))
	(if second
		(progn (write-change-config 3 FILE nil t nil)
			   (write-change-config 2 second (- delta) nil t))
	  (write-change-config 2 FILE nil nil t))))
(defun write-find-couple-concrete (FILE)
  "Like `write-find-couple', but asks for a heading to focuse on.
Only makes sense if there are headings to be focused on."
  (let ((delta (cadr (assoc FILE write-side-configs-alist)))
		(second (car (last (assoc FILE write-side-configs-alist)))))
	(if second
		(progn (write-change-config 3 FILE nil t nil)
			   (write-find-file-choose t second t (- delta)))
	  (write-change-config 2 FILE nil nil t))))

(defun write-find-map (UP)
  "Displays the story map and the map alone.

If UP is 't', shows it in the upper window. If it's nil, shows it
in the lower.

If displaying in the upper window, enlarge that one before
finding it, but that is taken care of by `write-set-config'.

If there are more maps (finds by looking for the
`write-map-extention' extention), asks which to display. If there is
only one, shows that one without asking."
  (interactive "P")
  (when (member "Down" (transient-args 'write-action))
	(setq UP t))
  (when (called-interactively-p 'interactive) (setq UP (not UP)))
  (write-find-file UP write-map-extension (write-map-directory)) (member "Switch" (transient-args 'write-action)))
(defun write-find-place (UP)
  "Displays the places (an org file).

If UP is 't', shows in the upper side window, otherwise in the
lower one.

If there are more place files, asks which one to display.

Depending on `write-switch-to-side-when-special' ends with the cursor
in the file or out of it."
  (interactive "P")
  (when (member "Down" (transient-args 'write-action))
	(setq UP t))
  (when (called-interactively-p 'interactive) (setq UP (not UP)))
  (write-find-file UP "org" (write-map-directory) (member "Switch" (transient-args 'write-action))))
(defun write-find-chapter (UP)
  "Displays the chapter asked for (extension is org).

If UP is 't', shows it in the upper side window, otherwise in the
lower one.

If there are more chapters, asks with `write-pick'."
  (interactive "P")
  (when (member "Down" (transient-args 'write-action))
	(setq UP t))
  (when (called-interactively-p 'interactive) (setq UP (not UP)))
  (write-find-file UP "org" (write-chapters-directory) (member "Switch" (transient-args 'write-action))))
(defun write-find-character (UP)
  "Displays the character asked for (extension is org).

If UP is 't', shows it in the upper side window, otherwise in the
lower one.

If there are more chapters, asks with `write-pick'."
  (interactive "P")
  (when (member "Down" (transient-args 'write-action))
	(setq UP t))
  (when (called-interactively-p 'interactive) (setq UP (not UP)))
  (write-find-file UP "org" (write-characters-directory) (member "Switch" (transient-args 'write-action))))
(defun write-find-family (UP)
  "Finds the family tree or any corresponding file in the
`write-family-directory'."
  (interactive "P")
  (when (member "Down" (transient-args 'write-action))
	(setq UP t))
  (when (called-interactively-p 'interactive) (setq UP (not UP)))
  (write-find-file UP "[^/]\\{3\\}+" (write-family-directory) (member "Switch" (transient-args 'write-action))))
(defun write-find-outline (UP &optional SWITCH)
  "Find the outline file. Can be an org file or a fountain file. Offers all files in the `write-outline-directory', not just the ones in the current part directory (`write-outline-directory-by-part').

Uses `write-find-file-choose'"
  (interactive "P")
  (when (member "Down" (transient-args 'write-action))
	(setq UP t))
  (when (member "Switch" (transient-args 'write-action))
	(setq SWITCH t))
  (when (called-interactively-p 'interactive) (setq UP (not UP)))
  (write-find-file UP write-standard-file-extentions (concat (write-outline-directory) (write-part)) SWITCH))
  
(defun write-find-other (UP)
  "Finds the \"other\" file and asks for a specific heading (only
  level 1!!!).

Uses `write-find-file-choose'"
  (interactive "P")
  (when (member "Down" (transient-args 'write-action))
	(setq UP t))
  (when (called-interactively-p 'interactive) (setq UP (not UP)))
  (write-find-file-choose UP (write-other-directory))) 

(defun write-find-timeline (UP &optional SWITCH)
  "Finds timeline. `write-find-file'."
  (interactive "P")
  (when (member "Down" (transient-args 'write-action))
	(setq UP t))
  (when (member "Switch" (transient-args 'write-action))
	(setq SWITCH t))
  (when (called-interactively-p 'interactive) (setq UP (not UP)))
  (write-find-file UP (write-timeline) nil SWITCH t))
(defun write-find-blank (UP &optional SWITCH)
  "Finds blank using `write-find-file'."
  (interactive "P")
  (when (member "Down" (transient-args 'write-action))
	(setq UP t))
  (when (member "Switch" (transient-args 'write-action))
	(setq SWITCH t))
  (when (called-interactively-p 'interactive) (setq UP (not UP)))
  (write-find-file UP (write-blank) nil SWITCH t))

(defun write-find-concrete-place (UP)
  "Finds places (like `write-find-place'), and specific heading in them."
  (interactive "P")
  (when (member "Down" (transient-args 'write-action))
	(setq UP t))
  (when (called-interactively-p 'interactive) (setq UP (not UP)))
  (write-find-file-choose UP (write-map-directory)))
(defun write-find-concrete-character (UP)
  "Finds character (line `write-find-character'), and specific
heading in them."
  (interactive "P")
  (when (member "Down" (transient-args 'write-action))
	(setq UP t))
  (when (called-interactively-p 'interactive) (setq UP (not UP)))
  (write-find-file-choose UP (write-characters-directory)))
(defun write-find-concrete-outline (UP &optional SWITCH)
  "Same as `write-find-outline', but offers a selection from the headlines as well."
  (interactive "P")
  (when (member "Down" (transient-args 'write-action))
	(setq UP t))
  (when (member "Switch" (transient-args 'write-action))
	(setq SWITCH t))
  (when (called-interactively-p 'interactive) (setq UP (not UP)))
  (write-find-file-choose UP (concat (write-outline-directory) (write-part))))

(defun write-find-couples ()
  "Find with `write-find-couple' two files in `write-side-configs-alist'."
  (interactive)
  (write-find-couple (car (nth
					   (write-pick t (write-make-paths-readable
								  (let (list)
									(nreverse
									 (dolist (element write-side-configs-alist list)
									   (when (not (string= (car (last element)) ""))
										 (push (car element) list)))))))
					   (delete ""
							   (mapcar (lambda (elem)
										 (if (not (string= (car (last elem)) ""))
											 elem
										   ""))
							   write-side-configs-alist))))))
(defun write-find-couples-concrete ()
  "Find with `write-find-couple-concrete' two files in `write-side-configs-alist'."
  (interactive)
  (write-find-couple-concrete
   (car (nth
		 (write-pick t (write-make-paths-readable
					(let (list)
					  (nreverse
					   (dolist (element write-side-configs-alist list)
						 (when (not (string= (car (last element)) ""))
						   (push (car element) list)))))))
		 (delete ""
				 (mapcar (lambda (elem)
						   (if (not (string= (car (last elem)) ""))
							   elem
							 ""))
						 write-side-configs-alist))))))

(defvar write-outline--Chapter-level '(0 0)
  "Holds a list with the point at beginning of line for the heading in the MASTER OUTLINE ORG FILE 'Chapters', and the point at the beginning of the next heading of the same level.")
(defun write-outline-chapter-level-check (LEVEL POINT)
  "Checks if a heading's number is greater than the heading 'Chapters'. If it is, and theit will return t, otherwise nil."
  (and (> POINT (car write-outline--Chapter-level))
	   (< POINT (cadr write-outline--Chapter-level))))
  
(defun write-outline-setup ()
  "Finds the right scene in the outline for the current part (with `write-part' - MASTER OUTLINE ORG FILE MUST HAVE SAME NAME AS THE PART, AND BE IN THE SAME DIRECTORY) and the scene in the .fountain mode which is linked under the scene heading in the master outline org file. Displays both the master file and the fountain file in VV.

It uses `write-outline-chapter-level-check' to view only the desired headings in the master outline org file."
  (interactive)
  (let ((master-file (write-find-file nil (concat (write-outline-directory) (write-part) "/" (write-part) ".org") nil nil t)))
		;; (write-switch-to-side-when-special nil))
	(set-buffer (get-file-buffer master-file))
	(beginning-of-buffer)
	(unless (re-search-forward "^\*+ Chapters$" nil t)
	  (error "There is no 'Chapters' heading in the %s file" master-file))

	;; We are now at '* Chapters'
	(setq write-outline--Chapter-level
		  (list (point-at-bol)
				(if (= (point-at-bol)
					   (progn (org-forward-heading-same-level 1)
							  (point-at-bol)))
					(buffer-end 1)
				  (point-at-bol))
				(org-outline-level)))
	(write-find-file-choose nil (concat (write-outline-directory-by-part) (write-part) ".org") t 10 #'write-outline-chapter-level-check)
	(org-show-entry)
	(if (> (org-outline-level) (1+ (car (last write-outline--Chapter-level))))
		;; The scene heading must be at least two headin leves greater than the
		;; '* Chapters' heading:
		;; * Chapters (1)
		;; ** Chapter (2)
		;; *** Scene (3)

		;; We are looking at a scene - find the appropriate scene, linked in the subtree.
		;; * Scene
		;; :PROPERTIES:
		;; ...
		;; :END:
		;; :Links:
		;; [[scene][link to .fountain heading]]
		;; :END:
		(progn
		  (re-search-forward ":Links:\n")
		  (let ((linked-file (buffer-substring-no-properties
							  (re-search-forward ":" (point-at-eol))
							  (- (re-search-forward "::" (point-at-eol)) 2)))
				(scene-heading (buffer-substring-no-properties
								(point)
								(1- (re-search-forward "\]" (point-at-eol))))))
			;; ;; Fold character list
			;; (re-search-forward ":END:")
			;; (forward-line 1)
			;; (org-cycle)					; Doesn't work all the time
			
			(write-find-file t (concat (write-outline-directory-by-part) linked-file) nil t t 9)
			(beginning-of-buffer)
			(re-search-forward scene-heading)
			(recenter-top-bottom 0)

			;; Put scene heading to top of buffer
			(other-window 1)
			(outline-previous-heading)
			(recenter 0)
			
			(other-window 1))))))

(defun write-find-weird (&optional SWITCH)
  "Finds any other file which is not included explicitly in the
other functions.

Always opens them in the upper side window.

SWITCH indicates we should switch to the window if
`write-switch-to-side-when-special' is t."
  (interactive "P")
  (when (member "Switch" (transient-args 'write-action))
	(setq SWITCH t))
  (let ((file (expand-file-name (read-file-name "File: " (write-main-directory)))))
	(write-find-file (member "Up" (transient-args 'write-action)) file
				 nil SWITCH t
				 (cadr (assoc file write-side-configs-alist)))))
;;;
;;;
;;;
;;; TODO
;;;
;;;
;;;

(defun write-pick (MAKE-CHARS &rest ARG)
  "Offers a pick of from given options \"magit\" style.

When MAKE-CHARS is 'non-nil', ARG does not provide the characters to pick from for each entry. They will start from 'a' and go on to 'b' and so on. When it is nil, the ARGs must be of the form:

	(\"character\" \"string\")

Otherwise it is just

	(\"string\")

Returns the index (starting with 0) of the chosen thing.

If given a list of lists of the above form, flattens them, so

	(write-pick '(\"a\" \"aaa\") '(\"b\" \"bbb\") '(\"c\" \"ccc\")
	and
	(write-pick '((\"a\" \"aaa\") (\"b\" \"bbb\")) '(\"c\" \"ccc\"))

have the same effect."
  ;; TODO Flatten first
  (setq ARG (write-canopy ARG (not MAKE-CHARS)))
  (print ARG)

  ;; Create chars for picking if they are not included.
  (if MAKE-CHARS
	(let ((number 0) ; (+ 96 (length ARG)))
		  list res)
	  (dolist (elem ARG list)
		(push (list (nth number write-picking-symbols)
					elem)
			  list)
		(setq number (1+ number)))
	  (setq ARG (reverse list)))
	(let (list)
	  (dolist (elem ARG list)
		(push (list (string-to-char (car elem))
					(cadr elem))
			  list))
	  (setq ARG (reverse list))))
  (print ARG)
  ;; Display the choices and read the input.
  (let ((char (write-display-choices ARG)))
	;; Return the index of the choice
	(write-find-index char ARG)))

(defun write-find-index (CHAR LIST &optional COUNT)
  "Find the index (from 0) of CHAR in LIST."
  (unless COUNT
	(setq COUNT 0))
  (if (null LIST)
	  nil
	(if (equal CHAR (caar LIST))
		COUNT
	  (write-find-index CHAR (cdr LIST) (1+ COUNT)))))

(defun write-display-choices-quit ()
  (interactive)
  (let ((buf (get-buffer-create write-window))
		write-window)
	(setq write-window
		  (display-buffer buf '(display-buffer-in-side-window (side . bottom))))
	(when (window-live-p write-window)
	  (setq buf (window-buffer write-window))
	  (with-demoted-errors "Error while exiting transient: %S"
		(delete-window write-window))
	  (kill-buffer buf))))

(defun write-display-choices (ARG)
  "Display all choices ARG of the form:

	(<character> <string>)

and return the character read. Opens a new window on the bottom,
which it then closes once the character has been chosen.

'q' will stop the whole operation."
  (let ((buf (get-buffer-create write-window))
		(count (1+ (/ (length ARG) write-number-of-picking-lines)))
		char
		max-str-lenth
		(tabs)
		(nth-element 0))
	(unless (window-live-p write-window)
	  (setq write--window
			(display-buffer buf '(display-buffer-in-side-window (side . bottom)))))
	(with-selected-window write--window
	  (erase-buffer)
	  (set-window-hscroll write--window 0)
	  (set-window-dedicated-p write--window t)
	  ;; (set-window-parameter write--window 'no-other-window t)
	  (when (bound-and-true-p tab-line-format)
		(setq tab-line-format nil))
	  (setq mode-line-format 'line)
	  (setq cursor-type nil)

	  (setq max-str-lenth (- (/ (window-body-width) count) 5)) ; 3 for the space, 1 for the leading char, 1 for the separating space
	  (print (window-body-width))
	  (print count)
	  (print max-str-lenth)
	  ;; Show the options
	  (let ((tab-stop-list
			(let ((prev-number 0))
			  (dotimes (tab count tabs)
				(setq tabs (append tabs (list (+ prev-number 3) (+ prev-number 3 (1+ max-str-lenth)))))
				(setq prev-number (car (last tabs)))))))
		(print tab-stop-list)
		(dolist (elem ARG)
		  (setq nth-element (1+ nth-element))
		  (let ((str (cadr elem))
				str-length)
			(setq str-length (if (> (length str) max-str-lenth)
								 max-str-lenth
							   (length str)))
			(when (= (% (- nth-element 1) write-number-of-picking-lines) 0)
			  (beginning-of-buffer))
			(end-of-line)
			(when (> nth-element write-number-of-picking-lines)
			  (move-to-tab-stop))
			(insert (propertize (format "%c" (car elem)) 'face write-picking-format))
			(move-to-tab-stop)
			(insert (substring str 0 str-length))
			(if (> nth-element write-number-of-picking-lines)
				(forward-line 1)
			  (insert "\n")))))
		(goto-char (point-min))

		(let ((window-resize-pixelwise t)
			  (window-size-fixed nil))
		  (fit-window-to-buffer nil nil 1))
		(while (progn (setq char (read-char-choice
								  "Press key: "
								  (cons ?q
										(-reduce-r-from
										 (lambda (a b) (cons (car a) b))
										 nil ARG))))
					  (or (= char ?)
						  (= char ?q)
						  (= char ? )))
		  (print char)
		  (cond ((= char ?)
				 (let ((other-window-scroll-buffer write-window))
				   (scroll-other-window)))
				((= char ? )
				 (let ((other-window-scroll-buffer buf))
				   (scroll-other-window-down)))
				(t ; Always ?q
				 (write-display-choices-quit)
				 (keyboard-quit))))
		(write-display-choices-quit))
	  char))

(defun write-canopy (ARG &optional COUPLE)
  (unless (listp ARG)
	(error "No list: %S" ARG))
  (let (list)
	(if COUPLE
		(nreverse
		 (progn (dolist (elem ARG list)
				  (unless (listp elem)
					(error "Not the correct format: %S" elem))
				  (if (char-or-string-p (car elem))
					  (if (and (= 2 (length elem))
							   (stringp (cadr elem)))
						  (push elem list)
						(error "Not the correct format: %S" elem))
					(unless (listp elem)
					  (error "Not the correct format: %S" elem))
					(setq list (nreverse (append list (write-canopy elem t))))))))
	  (dolist (elem ARG list)
		(unless (or (stringp elem)
					(listp elem))
		  (error "Not the correct format: %S" elem))
		(if (stringp elem)
			(setq list (append list (list elem)))
		  (setq list (append list (write-canopy elem nil))))))))

(defun write-open-again ();&optional ARG)
  (interactive)
  (setq write-config nil)
  (write-setup))

;;;
(defun write-save-term (STRING)
  (interactive (if (region-active-p)
				   (list (read-string "Description: "))
				 (error "You must activate a region first.")))
  (let ((term (buffer-substring-no-properties
			   (region-beginning)
			   (region-end)))
		(file (buffer-file-name))
		(file-name (buffer-name)))
	(find-file-noselect (write-terms))
	(set-buffer (get-file-buffer (write-terms)))
	(end-of-buffer)
	(org-insert-todo-heading-respect-content)
	(insert (concat term "\nPlace: [[file:" file "][" file-name "]]\nDescription: " STRING))))

;; (defun write-forward-outline (arg)
;;   "When outlining a scene in MASTER ORG OUTLINE FILE, the buffer may be narrowed to the subtree. This function moves forward to the next scene, notifying the user is this is the last scene of the chapter, and giving the option to go to the next scene anyway if it is.

;; Argument ARG specifies how many headings to move by. It can move backwards. If the number of scenes in the chapter is larger than the argument, moves to the last scene in said chapter."
;;   (interactive "p")
;;   (when (or (not (string= "org-mode" major-mode))
;; 			(not (buffer-narrowed-p)))
;; 	(error "Not in MASTER ORG OUTLINE FILE or not narrowing"))
;;   (let ((old-location (progn
;; 						(org-previous-visible-heading 1)
;; 						(point)))
;; 		(this-scene (buffer-substring (point-min)
;; 									  (point-max)))
;; 		(this-buffer (buffer-name))
;; 		(indirect-buffer-name "bla")
;; 		heading-level
;; 		new-heading)
;; 	(clone-indirect-buffer indirect-buffer-name nil t)
;; 	(set-buffer this-buffer)
;; 	(widen)
;; 	(when (= old-location
;; 			 (progn (org-forward-heading-same-level arg t)
;; 					(point)))
;; 	  (if (y-or-n-p (format
;; 					 "End of chapter. Go to scene in next chapter %s "
;; 					 (progn (org-next-visible-heading 1)
;; 							(org-entry-get nil "ITEM"))))
;; 		  (progn
;; 			(outline-show-branches)
;; 			(setq heading-level (outline-level))			
;; 			(org-next-visible-heading 1)
;; 			(when (= heading-level
;; 					 (outline-level))
;; 			  (org-previous-visible-heading 1)
;; 			  (setq new-heading (read-string "New heading: "))
;; 			  (org-insert-heading-respect-content t)
;; 			  (insert new-heading)
;; 			  (org-metaright)))
;; 			  ;; (error "There is no scene heading in the next chapter")))
;; 		(goto-char old-location)))

;; 	(org-narrow-to-subtree)
;; 	(outline-show-children)
;; 	(switch-to-buffer this-buffer)
;; 	(kill-buffer indirect-buffer-name)))

(defun write-help--update-argument (arg)
  "Called by `write-forward-outline'. If argument is negative, adds one, otherwise subtracts one, and returns the result. Argument thus converges to zero."
  (if (< 0 arg)
	  (1- arg)
	(1+ arg)))

(defun write-help--move-to-heading (arg)
  "Called by `write-forward-outline'. If argument possitive, calls `outline-next-heading', otherwise `outline-previous-heading'."
  (if (< 0 arg)
	  (outline-next-heading)
	(outline-previous-heading)))

(defun write-help--new-scene-in-place-maybe (expl position level arg new-scene insert-here &optional last-position)
  "Called by `write-forward-outline'. If NEW-SCENE is nill, this function asks a y-or-no question with an explanation in EXPL. If the answer is \"yes\", it sets cursor to POSITION and returns. If the answer is \"no\", it creates a new scene in place, whether it is at the beginning of the file, the end of the file, or somewhere in the middle. If NEW-SCENE is t, inserts a new scene automatically.

If cursor is at EOF, creates a new scene of level LEVEL just after it, or after the last visited scene (user is asked). If cursor is at BOF, the new heading will be on top of the file of level LEVEL, ar before the last visited scene (user is asked). The last visited scene is held in LAST-POSITION. If cursor is in the middle, this function assumes it is strategically placed:

- If ARG is <0 (which mean we're moving through scenes backwards), cursor is at the beginning of the line which should have the new scene. Usually the previously first scene:

	■** Blabla [level 3]
		lorem ipsum...
		|
		|
		v
	*** New Blabla■
	*** Blabla
		lorem ipsum...

- If ARG is >0 (we are moving forward through scenes), cursor is (anywhere) within the last heading/ content of heading:

	*** Blabla■
	    lorem ipsum...
		|
		|
		v
	*** Blabla
		lorem ipsum...
	*** New Blabla■

In the last two examples, LEVEL is not used."
  (let ((prompt (concat expl "Go back (no new scene)? "))
		scene-name)
	(if (if new-scene nil				; If new-scene is set, always insert
		  (y-or-n-p prompt))
		(goto-char position)				; We want to return to the
										; original scene

	  ;; We want to insert a new scene
	  (when (and (or (= (point) (point-max))
					 (= (point) (point-min)))
				 (if insert-here nil		; If insert-here is t
										; always insert here
				   (y-or-n-p "Make new scene at last scene (not here)? ")))
		(goto-char last-position)
		(unless (org-at-heading-p)
		  (outline-previous-heading)))
	  (setq scene-name (read-string "New scene name: "))
	  ;; Insert a newline IFF end of file AND NOT beginning of line,
	  ;; because if end of file AND beginning of line, we are on the
	  ;; last line of the file, which is empty, so we can insert there.
	  (when (and (= (point) (point-max))
				 (not (= (point) (point-at-bol))))
		(newline))
	  (if (or (= (point) (point-min))
			  (cl-minusp arg)
			  (= (point) (point-max)))
		  (progn (dotimes (time level)
				   (insert "*"))
				 (insert (concat " " scene-name "\n"))
				 (when (not (= (point) (point-max)))
				   (insert "\n")
				   (backward-char)))
		(org-insert-heading-respect-content t)
		(insert (concat scene-name "\n")))

	  (when specific-string-insertion
		(insert-specific-string t)))))

(defun write-forward-outline (arg position level)
  "Go forward ARG headings of the same level, and narrow on the last.

POSITION denotes the position to come back to in case we hit a problem - no more headings to go to or heading of another level.

LEVEL gives the current outline level. We only count headings of this level. If a heading of another level is reached, the user is asked if they wish to procede. If not, they return to POSITION. If yes, the function finds the next heading of LEVEL and counts on."
  (interactive (list (prefix-numeric-value current-prefix-arg) (progn (beginning-of-buffer) (point)) (org-outline-level)))
  ;; Check for wrong file/ not narrowed
  (when (or (not (string= "org-mode" major-mode)))
	(error "Not in MASTER ORG OUTLINE FILE"))

  (widen)
  (outline-show-branches)

  (let ((same-chapter t)
		(last-position position))
	(while (not (= arg 0))
	  (write-help--move-to-heading arg)
	  (if (or (= (point) (point-max))	; Check if end or beginning of file
			  (= (point) (point-min)))
		  (progn
			(write-help--new-scene-in-place-maybe "End of file. "position level arg write-always-insert-new-scene write-always-insert-new-scene last-position)
			
			(setq arg 0))				; Stop loop
		
		;; Not at end or beginning of file
		(if (= (org-outline-level) level)
			(progn
			  (setq last-position (point))
			  (setq same-chapter t)
			  (setq arg (write-help--update-argument arg)))
		  (when same-chapter
			(unless (or write-always-skip-non-matching-headings
						(y-or-n-p "We are changing chapters. Do you want to? "))
			  (write-help--move-to-heading (- arg)) ; Position the cursor
			  ;; Insert new scene
			  (write-help--new-scene-in-place-maybe "" position level arg nil nil)
			  (setq arg 0)))			; Stop loop
		  (setq same-chapter nil))))

	(outline-show-entry)
	(org-narrow-to-subtree)))

(defalias 'wf 'write-forward-outline)

(require 'transient)
(define-transient-command write-action ()
  ["Prefix"
   ("s" "Switch" "Switch")
   ("d" "Down" "Down")]

  ["Finding"
   ["Common"
	("[" "Find CHAPTER" write-find-chapter)
	("]" "Find CHARACTER" write-find-character)
	("m" "Find MAP" write-find-map)
	("p" "Find PLACE" write-find-place)]
   ["Other"
	("t" "Timeline" write-find-timeline)
	("b" "Blank" write-find-blank)
	("f" "Find family" write-find-family)
	("w" "Find WEIRD" write-find-weird)]]
  
  ["Couples"
   ["Outline"
	;; E for events
	("e" "Find OUTLINE" write-find-outline) 
	("E" "Find concrete OUTLINE" write-find-concrete-outline)
	("O" "Setup the outline environment" write-outline-setup)]

   ["Concrete"
	("}" "Find concrete CHARACTER" write-find-concrete-character)
	("P" "Find concrete PLACE" write-find-concrete-place)
	("o" "Find concerte OTHER" write-find-other)]
   ["Generic"
	("c" "Pick couple" write-find-couples)
	("C" "Pick couple concrete" write-find-couples-concrete)]]

  ["Manipulate"
   ("H" "Last configuration" write-last-config)
   ("S" "Set up -> new chapter" write-setup)
   ("R" "Set up again" write-open-again)
   ("r" "Re-set configuration" write-set-config)
   ("M-[" "Delete UPPER window" write-vv-to-hv-upper)
   ("M-]" "Delete LOWER window" write-vv-to-hv-lower)])

(defalias 'write 'write-setup)
(define-key global-map (kbd "C-c w") 'write-save-term)