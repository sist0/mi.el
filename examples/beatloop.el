(require 'mi)
(setq mi-use-dls-synth t)
(mi-setup)

(defun beatloop () ;)
  (mi-seq 1/16
             (crash-cymbal1 x)
             (open-hi-hat   --x- --x- --x- --x- --x- --x- --x- --x-)
             (closed-hi-hat xx-x xx-x xx-x xx-x xx-x xx-x xx-x xx-x)
             (snare-drum1   ---- x--x -x-- x--x ---- x--x -x-- xxxx)
             (bass-drum1    x-x- --x- x-x- --x- x-x- --x- x-x- --x-)
             )
   (mi-callback 8 'beatloop))

(beatloop)