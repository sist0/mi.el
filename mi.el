;;;; mi - Emacs MIDI Instrument -

(require 'cl)
(require 'comint)

;;; Interface
(defconst mi-note-on               #x90)
(defconst mi-note-off              #x80)
(defconst mi-polyphonic-aftertouch #xA0)
(defconst mi-control-change        #xB0)
(defconst mi-program-change        #xC0)
(defconst mi-channel-aftertouch    #xD0)
(defconst mi-pitch-bend            #xE0)
(defconst mi-all-sound-off         #x78)
(defconst mi-all-note-off          #x7B)
(defconst mi-dummy-data            0)

(defvar mi-process-name    "mi")
(defvar mi-process-verbose nil)
(defvar mi-use-dls-synth   nil)

(defun mi-make-process ()
  (make-comint mi-process-name "ruby" nil
               "-rubygems" (if mi-process-verbose "-p" "-n") "-ae"
               (concat
                "BEGIN{"
                "require 'midiator';"
                "$MIDI = MIDIator::Interface.new;"
                (if mi-use-dls-synth
                    "$MIDI.use :dls_synth;"
                  "$MIDI.autodetect_driver;")
                "};"
                "$MIDI.message(*($F.map(&:to_i)));")))

(defun mi-get-buffer ()
  (get-buffer (concat "*" mi-process-name "*")))

(defun mi-kill-buffer ()
  (kill-buffer (mi-get-buffer)))

(defun mi-get-process ()
  (get-buffer-process (mi-get-buffer)))

(defun mi-kill-process ()
  (kill-process (mi-get-process)))

(defun mi-message (&rest args)
  (comint-send-string
   (mi-get-process)
   (concat (mapconcat 'number-to-string args " ") "\n")))

(defun mi-note-on (note channel velocity)
  (mi-message (logior mi-note-on (1- channel)) note velocity))

(defun mi-note-off (note channel velocity)
  (mi-message (logior mi-note-off (1- channel)) note velocity))

(defun mi-aftertouch (note channel velocity)
  (mi-message (logior mi-polyphonic-aftertouch (1- channel)) note velocity))

(defun mi-control-change (number channel value)
  (mi-message (logior mi-control-change (1- channel)) number value))

(defun mi-all-sound-off (channel)
  (mi-control-change mi-all-sound-off channel mi-dummy-data))

(defun mi-all-note-off (channel)
  (mi-control-change mi-all-note-off channel mi-dummy-data))

(defun mi-lsb-bank-select (channel value)
  (mi-control-change 32 channel value))

(defun mi-msb-bank-select (channel value)
  (mi-control-change 0 channel value))

(defun mi-program-change (channel program)
  (mi-message (logior mi-program-change (1- channel)) program))

(defun mi-channel-aftertouch (channel pressure)
  (mi-message (logior mi-channel-aftertouch (1- channel)) pressure))

(defun mi-pitch-bend (channel value)
  (mi-message (logior mi-pitch-bend (1- channel)) value))

;;; Time
(defvar mi-bpm 120)

(defun mi-tempo (&optional bpm)
  (if bpm (setq mi-bpm bpm))
  mi-bpm)

(defun mi-beat-to-second (n)
  (* n (/ 60.0 mi-bpm)))

(defun mi-get-timing (beat)
  (timer-relative-time (current-time) (mi-beat-to-second beat)))

(defun mi-callback (delay callback &rest args)
  (run-at-time (mi-get-timing delay) nil
               (lambda (callback args) (apply callback args)) callback args))

(defun mi-async (callback &rest args)
  (run-at-time (current-time) nil
               (lambda (callback args) (apply callback args)) callback args))

(defun mi-meter-to-beat (meter) ;; (mi-meter-to-beat '1/16) => 0.25
  (let ((x (mapcar 'string-to-number (split-string (symbol-name meter) "/"))))
    (* 4 (/ (* 1.0 (car x)) (cadr x)))))

;;; Main
(defun mi-play (notes &optional delay duration channel velocity)
  (setq notes    (if (not (listp notes)) (list notes) notes)
        delay    (or delay 0)
        duration (or duration 1)
        channel  (or channel 1)
        velocity (or velocity 50))
  (mapcar
    (lambda (note)
      (setq note (if (symbolp note) (mi-resolve-note note) note))
      (mi-callback delay 'mi-note-on  note channel velocity)
      (mi-callback (+ delay duration) 'mi-note-off note channel velocity))
    notes)
  notes)

(defun mi-setup ()
  (interactive)
  (mi-make-process))

(defun mi-destroy ()
  (interactive)
  (remove-hook 'post-command-hook 'mi-trigger t)
  (mi-kill-process)
  (mi-kill-buffer))

(defun mi-reset ()
  (interactive)
  (mi-destroy)
  (mi-setup))

;;; Util
(defun mi-random (&optional items)
  (if (listp items)
      (nth (random (length items)) items)
    items))

;;; Notes
(defvar mi-notes (make-hash-table :test 'equal))
(mapcar
 (lambda (note)
   (puthash (car note) (cdr note) mi-notes))
 '((C-1 . 0) (C^-1 . 1) (Db-1 . 1) (D-1 . 2) (D^-1 . 3) (Eb-1 . 3) (E-1 . 4) (E^-1 . 5) (Fb-1 . 4) (F-1 . 5) (F^-1 . 6) (Gb-1 . 6) (G-1 . 7) (G^-1 . 8) (Ab-1 . 8) (A-1 . 9) (A^-1 . 10) (Bb-1 . 10) (B-1 . 11) (B^-1 . 12) (Cb0 . 11) (C0 . 12) (C^0 . 13) (Db0 . 13) (D0 . 14) (D^0 . 15) (Eb0 . 15) (E0 . 16) (E^0 . 17) (Fb0 . 16) (F0 . 17) (F^0 . 18) (Gb0 . 18) (G0 . 19) (G^0 . 20) (Ab0 . 20) (A0 . 21) (A^0 . 22) (Bb0 . 22) (B0 . 23) (B^0 . 24) (Cb1 . 23) (C1 . 24) (C^1 . 25) (Db1 . 25) (D1 . 26) (D^1 . 27) (Eb1 . 27) (E1 . 28) (E^1 . 29) (Fb1 . 28) (F1 . 29) (F^1 . 30) (Gb1 . 30) (G1 . 31) (G^1 . 32) (Ab1 . 32) (A1 . 33) (A^1 . 34) (Bb1 . 34) (B1 . 35) (B^1 . 36) (Cb2 . 35) (C2 . 36) (C^2 . 37) (Db2 . 37) (D2 . 38) (D^2 . 39) (Eb2 . 39) (E2 . 40) (E^2 . 41) (Fb2 . 40) (F2 . 41) (F^2 . 42) (Gb2 . 42) (G2 . 43) (G^2 . 44) (Ab2 . 44) (A2 . 45) (A^2 . 46) (Bb2 . 46) (B2 . 47) (B^2 . 48) (Cb3 . 47) (C3 . 48) (C^3 . 49) (Db3 . 49) (D3 . 50) (D^3 . 51) (Eb3 . 51) (E3 . 52) (E^3 . 53) (Fb3 . 52) (F3 . 53) (F^3 . 54) (Gb3 . 54) (G3 . 55) (G^3 . 56) (Ab3 . 56) (A3 . 57) (A^3 . 58) (Bb3 . 58) (B3 . 59) (B^3 . 60) (Cb4 . 59) (C4 . 60) (C^4 . 61) (Db4 . 61) (D4 . 62) (D^4 . 63) (Eb4 . 63) (E4 . 64) (E^4 . 65) (Fb4 . 64) (F4 . 65) (F^4 . 66) (Gb4 . 66) (G4 . 67) (G^4 . 68) (Ab4 . 68) (A4 . 69) (A^4 . 70) (Bb4 . 70) (B4 . 71) (B^4 . 72) (Cb5 . 71) (C5 . 72) (C^5 . 73) (Db5 . 73) (D5 . 74) (D^5 . 75) (Eb5 . 75) (E5 . 76) (E^5 . 77) (Fb5 . 76) (F5 . 77) (F^5 . 78) (Gb5 . 78) (G5 . 79) (G^5 . 80) (Ab5 . 80) (A5 . 81) (A^5 . 82) (Bb5 . 82) (B5 . 83) (B^5 . 84) (Cb6 . 83) (C6 . 84) (C^6 . 85) (Db6 . 85) (D6 . 86) (D^6 . 87) (Eb6 . 87) (E6 . 88) (E^6 . 89) (Fb6 . 88) (F6 . 89) (F^6 . 90) (Gb6 . 90) (G6 . 91) (G^6 . 92) (Ab6 . 92) (A6 . 93) (A^6 . 94) (Bb6 . 94) (B6 . 95) (B^6 . 96) (Cb7 . 95) (C7 . 96) (C^7 . 97) (Db7 . 97) (D7 . 98) (D^7 . 99) (Eb7 . 99) (E7 . 100) (E^7 . 101) (Fb7 . 100) (F7 . 101) (F^7 . 102) (Gb7 . 102) (G7 . 103) (G^7 . 104) (Ab7 . 104) (A7 . 105) (A^7 . 106) (Bb7 . 106) (B7 . 107) (B^7 . 108) (Cb8 . 107) (C8 . 108) (C^8 . 109) (Db8 . 109) (D8 . 110) (D^8 . 111) (Eb8 . 111) (E8 . 112) (E^8 . 113) (Fb8 . 112) (F8 . 113) (F^8 . 114) (Gb8 . 114) (G8 . 115) (G^8 . 116) (Ab8 . 116) (A8 . 117) (A^8 . 118) (Bb8 . 118) (B8 . 119) (B^8 . 120) (Cb9 . 119)))

(defun mi-resolve-note (note)
  (if (symbolp note) (gethash note mi-notes) note))

(defun mi-oct-up (note)
  (+ note 12))

(defun mi-oct-down (note)
  (- note 12))

;;; Collection
(defun mi-resolve-collection (key symbol collection)
  (let* ((key-note (mi-resolve-note key))
         (nums (gethash symbol collection))
         (diffs (mapcar 'mi-resolve-degree nums)))
    (mapcar (lambda (diff) (+ key-note diff)) diffs)))

(defun mi-relative (note interval degrees)
  (let ((pitch (mi-resolve-note note))
        (degree-nums (mapcar  (lambda (degree) (mi-resolve-degree degree)) degrees))
        (degrees-count (length degrees)))
    (if (or (not (integerp interval))
            (= interval 0))
        pitch
        (let  ((oct (/ interval degrees-count))
               (n (% interval degrees-count)))
          (+ pitch
             (nth (if (> 0 n) (+ degrees-count n) n) degree-nums)
             (* 12 (if (and (not (= n 0))
                            (> 0 interval))
                       (- oct 1)
                     oct)))))))

;;; Degrees
(defvar mi-degrees (make-hash-table :test 'equal))
(mapcar
 (lambda (degree)
   (puthash (car degree) (cdr degree) mi-degrees))
 '((ib . -1) (i . 0) (iib . 1) (i^ . 1)
   (ii . 2) (ii^ . 3) (iiib . 3) (iii . 4)
   (ivb . 4) (iv . 5) (iv^ . 6) (vb . 6)
   (v . 7) (v^ . 8) (vib . 8) (vi . 9)
   (viibb . 9) (vi^ . 10) (viib . 10) (vii . 11) (vii^ . 12)))

(defun mi-resolve-degree (degree)
  (gethash degree mi-degrees))

;;; Scales
(defvar mi-scales (make-hash-table :test 'equal))
(mapcar
 (lambda (scale)
   (puthash (car scale) (cdr scale) mi-scales))
 '((chromatic i i^ ii ii^ iii iv iv^ v v^ vi vi^ vii)
   (pentatonic i ii iii v vi)
   (dorian i ii iiib iv v vi viib)
   (phrigian i iib iiib iv v vib)
   (lydian i ii iii iv^ v vi vii)
   (mixolydian i ii iii iiii v vi viib)
   (ionian i ii iii iv v vi vii)
   (aeolian i ii iiib iv v vib viib)
   (locrian i iib iiib iv vb vib viib)))

(defun mi-scale (key scale)
   (let ((note (mi-resolve-note key))
         (degrees (mapcar 'mi-resolve-degree (gethash scale mi-scales))))
     (mapcar
      (lambda (degree)
        (+ note degree))
      degrees)))

;;; Chords
(defun mi-chord (key symbol)
  (mi-resolve-collection key symbol mi-chords))

(defvar mi-chords (make-hash-table :test 'equal))
(mapcar
 (lambda (chord)
   (puthash (car chord) (cdr chord) mi-chords));; Triad
 '((M i iii v)
   (m i iiib v)
   (dim i iiib vb)
   (aug i iii v^)

   ;; Seventh chord (four notes chord)
   (7 i iii v viib)
   (M7 i iii v vii)
   (m7 i iiib v viib)
   (m7-5 i iiib vb viib)
   (dim7 i iiib vb viibb)
   (aug7 i iii v^ vii)
   (mM7 i iiib v vii)

   ;; Other
   (sus4 i iv v)
   (7sus4 i iv v viib)
   (6 i iii v vi)
   (m6 i iiib v vi)
   (add2 i ii iii v)
   (add4 i iii iv v)
   (-5 i iii vb)
   (7-5 i iii vb viib)))

(defconst mi-diatonic-chords
  '((major-triad (i (i . M)) (ii (ii . m)) (iii (iii . m)) (iv (iv . M)) (v (v . M)) (vi (vi . m)) (vii (vii . dim)))
    (major (i (i . M7)) (ii (ii . m7)) (iii (iii . m7)) (iv (iv . M7)) (v (v . 7)) (vi (vi . m7)) (vii (vii . m7-5)))
    (minor (i (i . m7)) (ii (ii . m7-5)) (iii (iiib . M7)) (iv (iv . m7)) (v (v . m7)) (vi (vib . M7)) (vii (viib . 7)))))

(defun mi-diatonic (key type degrees) ;; 代理コードのためにdegreeを複数とる
  (let* ((degree (mi-random degrees))
         (val (cadr (assoc degree (assoc type mi-diatonic-chords)))))
    (mi-chord (+ (mi-resolve-note key) (mi-resolve-degree (car val))) (cdr val))))

;;; Chord Progression
(defconst mi-progressions
  '((ii  v   i   iii)
    (iv  v   i   iii)
    (i   v   vi  v)
    (iii v   vi  v)
    (i   vii vi  v)
    (iii vii vi  v)
    (i   vi  ii  v)
    (iii vi  ii  v)
    (iv  v   iii vi)
    (i   vii iii i)
    (vi  iv  v   i)
    (iv  v   iii i)))

;;; General MIDI Melodic Sounds
;; Piano
(defconst mi-gm-sounds-acoustic-piano       0)
(defconst mi-gm-sounds-bright-piano         1)
(defconst mi-gm-sounds-electric-grand-piano 2)
(defconst mi-gm-sounds-honky-tonk-piano     3)
(defconst mi-gm-sounds-electric-piano       4)
(defconst mi-gm-sounds-electric-piano2      5)
(defconst mi-gm-sounds-harpsichord          6)
(defconst mi-gm-sounds-clavi                7)

;; Chromatic Percussion
(defconst mi-gm-sounds-celesta      8)
(defconst mi-gm-sounds-glockenspiel 9)
(defconst mi-gm-sounds-musical-box  10)
(defconst mi-gm-sounds-vibraphone   11)
(defconst mi-gm-sounds-marimba      12)
(defconst mi-gm-sounds-xylophone    13)
(defconst mi-gm-sounds-tubular-bell 14)
(defconst mi-gm-sounds-dulcimer     15)

;; Organ
(defconst mi-gm-sounds-drawbar-organ    16)
(defconst mi-gm-sounds-percussive-organ 17)
(defconst mi-gm-sounds-rock-organ       18)
(defconst mi-gm-sounds-church-organ     19)
(defconst mi-gm-sounds-reed-organ       20)
(defconst mi-gm-sounds-accordion        21)
(defconst mi-gm-sounds-harmonica        22)
(defconst mi-gm-sounds-tango-accordion  23)

;; Guitar
(defconst mi-gm-sounds-acoustic-guitar-nylon 24)
(defconst mi-gm-sounds-acoustic-guitar-steel 25)
(defconst mi-gm-sounds-electric-guitar-jazz  26)
(defconst mi-gm-sounds-electric-guitar-clean 27)
(defconst mi-gm-sounds-electric-guitar-muted 28)
(defconst mi-gm-sounds-overdriven-guitar     29)
(defconst mi-gm-sounds-distortion-guitar     30)
(defconst mi-gm-sounds-guitar-harmonics      31)

;; Bass
(defconst mi-gm-sounds-acoustic-bass        32)
(defconst mi-gm-sounds-electric-bass-finger 33)
(defconst mi-gm-sounds-electric-bass-pick   34)
(defconst mi-gm-sounds-fretless-bass        35)
(defconst mi-gm-sounds-slap-bass1           36)
(defconst mi-gm-sounds-slap-bass2           37)
(defconst mi-gm-sounds-synth-bass1          38)
(defconst mi-gm-sounds-synth-bass2          39)

;; Strings
(defconst mi-gm-sounds-violin            40)
(defconst mi-gm-sounds-viola             41)
(defconst mi-gm-sounds-cello             42)
(defconst mi-gm-sounds-double-bass       43)
(defconst mi-gm-sounds-tremolo-strings   44)
(defconst mi-gm-sounds-pizzicato-strings 45)
(defconst mi-gm-sounds-orchestral-harp   46)
(defconst mi-gm-sounds-timpani           47)

;; Ensemble
(defconst mi-gm-sounds-string-ensemble1 48)
(defconst mi-gm-sounds-string-ensemble2 49)
(defconst mi-gm-sounds-synth-strings1   50)
(defconst mi-gm-sounds-synth-strings2   51)
(defconst mi-gm-sounds-voice-aahs       52)
(defconst mi-gm-sounds-voice-oohs       53)
(defconst mi-gm-sounds-synth-voice      54)
(defconst mi-gm-sounds-orchestra-hit    55)

;; Brass
(defconst mi-gm-sounds-trumpet       56)
(defconst mi-gm-sounds-trombone      57)
(defconst mi-gm-sounds-tuba          58)
(defconst mi-gm-sounds-muted-trumpet 59)
(defconst mi-gm-sounds-french-horn   60)
(defconst mi-gm-sounds-brass-section 61)
(defconst mi-gm-sounds-synth-brass1  62)
(defconst mi-gm-sounds-synth-brass2  63)

;; Reed
(defconst mi-gm-sounds-soprano-sax  64)
(defconst mi-gm-sounds-alto-sax     65)
(defconst mi-gm-sounds-tenor-sax    66)
(defconst mi-gm-sounds-baritone-sax 67)
(defconst mi-gm-sounds-oboe         68)
(defconst mi-gm-sounds-english-horn 69)
(defconst mi-gm-sounds-bassoon      70)
(defconst mi-gm-sounds-clarinet     71)

;; Pipe
(defconst mi-gm-sounds-piccolo      72)
(defconst mi-gm-sounds-flute        73)
(defconst mi-gm-sounds-recorder     74)
(defconst mi-gm-sounds-pan-flute    75)
(defconst mi-gm-sounds-blown-bottle 76)
(defconst mi-gm-sounds-shakuhachi   77)
(defconst mi-gm-sounds-whistle      78)
(defconst mi-gm-sounds-ocarina      79)

;; Synth Lead
(defconst mi-gm-sounds-lead1 80) ; square
(defconst mi-gm-sounds-lead2 81) ; sawtooth
(defconst mi-gm-sounds-lead3 82) ; calliope
(defconst mi-gm-sounds-lead4 83) ; chiff
(defconst mi-gm-sounds-lead5 84) ; charang
(defconst mi-gm-sounds-lead6 85) ; voice
(defconst mi-gm-sounds-lead7 86) ; fifths
(defconst mi-gm-sounds-lead8 87) ; bass + lead

;; Synth Pad
(defconst mi-gm-sounds-pad1 88) ; fantasia
(defconst mi-gm-sounds-pad2 89) ; warm
(defconst mi-gm-sounds-pad3 90) ; polysynth
(defconst mi-gm-sounds-pad4 91) ; choir
(defconst mi-gm-sounds-pad5 92) ; bowed
(defconst mi-gm-sounds-pad6 93) ; metallic
(defconst mi-gm-sounds-pad7 94) ; halo
(defconst mi-gm-sounds-pad8 95) ; sweep

;; Synth Efmicts
(defconst mi-gm-sounds-fx1 96)  ; rain
(defconst mi-gm-sounds-fx2 97)  ; soundtrack
(defconst mi-gm-sounds-fx3 98)  ; crystal
(defconst mi-gm-sounds-fx4 99)  ; atmosphere
(defconst mi-gm-sounds-fx5 100) ; brightness
(defconst mi-gm-sounds-fx6 101) ; goblins
(defconst mi-gm-sounds-fx7 102) ; echoes
(defconst mi-gm-sounds-fx8 103) ; sci-fi

;; Ethnic
(defconst mi-gm-sounds-sitar    104)
(defconst mi-gm-sounds-banjo    105)
(defconst mi-gm-sounds-shamisen 106)
(defconst mi-gm-sounds-koto     107)
(defconst mi-gm-sounds-kalimba  108)
(defconst mi-gm-sounds-bagpipe  109)
(defconst mi-gm-sounds-fiddle   110)
(defconst mi-gm-sounds-shanai   111)

;; Percussive
(defconst mi-gm-sounds-tinkle-bell    112)
(defconst mi-gm-sounds-agogo          113)
(defconst mi-gm-sounds-steel-drums    114)
(defconst mi-gm-sounds-woodblock      115)
(defconst mi-gm-sounds-taiko-drum     116)
(defconst mi-gm-sounds-melodic-tom    117)
(defconst mi-gm-sounds-synth-drum     118)
(defconst mi-gm-sounds-reverse-cymbal 119)

;; Sound efmicts
(defconst mi-gm-sounds-guitar-fret-noise 120)
(defconst mi-gm-sounds-breath-noise      121)
(defconst mi-gm-sounds-seashore          122)
(defconst mi-gm-sounds-bird-tweet        123)
(defconst mi-gm-sounds-telephone-ring    124)
(defconst mi-gm-sounds-helicopter        125)
(defconst mi-gm-sounds-applause          126)
(defconst mi-gm-sounds-gunshot           127)

(defun mi-sound-select (channel sound)
  (let ((program (symbol-value
                  (intern (concat "mi-gm-sounds-" (symbol-name sound))))))
    (mi-lsb-bank-select channel mi-dummy-data)
    (mi-program-change channel program)
    program))

;;; Drum-set
(defconst mi-gm-drums-bass-drum2      35)
(defconst mi-gm-drums-bass-drum1      36)
(defconst mi-gm-drums-side-stick      37)
(defconst mi-gm-drums-snare-drum1     38)
(defconst mi-gm-drums-hand-clap       39)
(defconst mi-gm-drums-snare-drum2     40)
(defconst mi-gm-drums-low-tom2        41)
(defconst mi-gm-drums-closed-hi-hat   42)
(defconst mi-gm-drums-low-tom1        43)
(defconst mi-gm-drums-pedal-hi-hat    44)
(defconst mi-gm-drums-mid-tom2        45)
(defconst mi-gm-drums-open-hi-hat     46)
(defconst mi-gm-drums-mid-tom1        47)
(defconst mi-gm-drums-high-tom2       48)
(defconst mi-gm-drums-crash-cymbal1   49)
(defconst mi-gm-drums-high-tom1       50)
(defconst mi-gm-drums-ride-cymbal1    51)
(defconst mi-gm-drums-chinese-cymbal  52)
(defconst mi-gm-drums-ride-bell       53)
(defconst mi-gm-drums-tambourine      54)
(defconst mi-gm-drums-splash-cymbal   55)
(defconst mi-gm-drums-cowbell         56)
(defconst mi-gm-drums-crash-cymbal2   57)
(defconst mi-gm-drums-vibra-slap      58)
(defconst mi-gm-drums-ride-cymbal2    59)
(defconst mi-gm-drums-high-bongo      60)
(defconst mi-gm-drums-low-bongo       61)
(defconst mi-gm-drums-mute-high-conga 62)
(defconst mi-gm-drums-open-high-conga 63)
(defconst mi-gm-drums-low-conga       64)
(defconst mi-gm-drums-high-timbale    65)
(defconst mi-gm-drums-low-timbale     66)
(defconst mi-gm-drums-high-agogo      67)
(defconst mi-gm-drums-low-agogo       68)
(defconst mi-gm-drums-cabasa          69)
(defconst mi-gm-drums-maracas         70)
(defconst mi-gm-drums-short-whistle   71)
(defconst mi-gm-drums-long-whistle    72)
(defconst mi-gm-drums-short-guiro     73)
(defconst mi-gm-drums-long-guiro      74)
(defconst mi-gm-drums-claves          75)
(defconst mi-gm-drums-high-wood-block 76)
(defconst mi-gm-drums-low-wood-block  77)
(defconst mi-gm-drums-mute-cuica      78)
(defconst mi-gm-drums-open-cuica      79)
(defconst mi-gm-drums-mute-triangle   80)
(defconst mi-gm-drums-open-triangle   81)

(defconst mi-drum-channel 10)

(defun mi-drum-shot (instrument delay)
  (if delay
      (mi-play (symbol-value
                (intern (concat "mi-gm-drums-" (symbol-name instrument))))
               delay
               0.25 mi-drum-channel 80)))

(defun mi-make-beat-sequence (meter pattern)
  (let ((delay (mi-meter-to-beat meter))
        (interval 0)
        (marks (mapconcat 'symbol-name pattern nil)))
    (mapcar
     (lambda (mark)
       (let (result)
         (setq result (if (char-equal ?x mark) (* delay interval) nil)
               interval (+ interval 1))
         result))
     marks)))

(defun mi-drum-play-sequence (meter instrument pattern)
  (mapcar (lambda (timing) (mi-drum-shot instrument timing))
          (mi-make-beat-sequence meter pattern)))

(defmacro mi-seq (meter &rest body)
  `(mapcar (lambda (part)
             (mi-async 'mi-drum-play-sequence (quote ,meter) (car part) (cdr part)))
          (quote ,body)))

(defun mi-trigger-command-type (command)
  (if (symbolp command)
      (let ((command-name (symbol-name command)))
        (cond ((or (string-match "self-insert-command" command-name)
                   (string-match "electric" command-name)) 'mi-fx-insert)
              ((string-match "newline" command-name) 'mi-fx-newline)))))

(defun mi-trigger ()
  (let ((f (mi-trigger-command-type this-command)))
    (if f (funcall f))))

(defun mi-fx-insert ()
  (let ((scale mi-fx-insert-scale))
    (mi-play (mi-random scale) 0 mi-fx-insert-duration mi-fx-insert-channel mi-fx-insert-velocity)))

(defun  mi-fx-newline ()
  (let ((scale mi-fx-newline-scale))
    (mi-play (mi-random scale) 0 mi-fx-newline-duration mi-fx-newline-channel mi-fx-newline-velocity)))


(defvar mi-fx-insert-channel  1)
(defvar mi-fx-insert-note     60)
(defvar mi-fx-insert-scale    (list mi-fx-insert-note))
(defvar mi-fx-insert-duration 0.1)
(defvar mi-fx-insert-velocity 60)

(defvar mi-fx-new-line-channel  1)
(defvar mi-fx-insert-note     60)
(defvar mi-fx-insert-scale    (list mi-fx-insert-note))
(defvar mi-fx-insert-duration 0.1)
(defvar mi-fx-insert-velocity 60)

(provide 'mi)
;;; mi.el ends here