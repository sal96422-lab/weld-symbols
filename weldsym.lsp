;;; WELDSYM - AutoLISP weld symbol command with visual DCL toolbox.
;;; Load with APPLOAD, then run WELDSYM.

(vl-load-com)

(setq *weldsym-symbols* '("Fillet"))
(setq *weldsym-sides* '("Arrow side" "Other side" "Both sides"))
(setq *weldsym-contours* '("None" "Flush" "Convex" "Concave"))
(setq *weldsym-dialog-symbol* "0")
(setq *weldsym-dialog-side* "0")
(setq *weldsym-dialog-contour* "0")
(setq *weldsym-dialog-dir* "0")
(setq *weldsym-scale* 6.0)

(setq *weldsym-last*
  '((symbol . "0")
    (side . "0")
    (size . "")
    (length . "")
    (pitch . "")
    (field . "0")
    (allaround . "0")
    (tailon . "0")
    (process . "")
    (tailtext . "")
    (tailtext2 . "")
    (contour . "0")
    (dir . "0")))

(defun weldsym:alist-get (key data fallback / found)
  (setq found (assoc key data))
  (if found (cdr found) fallback))

(defun weldsym:add (p q)
  (mapcar '+ p q))

(defun weldsym:mul (p n)
  (mapcar '(lambda (v) (* v n)) p))

(defun weldsym:s (value)
  (* value *weldsym-scale*))

(defun weldsym:arrow-size ()
  28.0)


(defun weldsym:solid-triangle (p1 p2 p3)
  (entmakex
    (list
      '(0 . "SOLID")
      '(8 . "WELD_SYMBOL")
      (cons 10 p1)
      (cons 11 p2)
      (cons 12 p3)
      (cons 13 p3))))
(defun weldsym:line (p q)
  (entmakex (list '(0 . "LINE") '(8 . "WELD_SYMBOL") (cons 10 p) (cons 11 q))))

(defun weldsym:circle (center radius)
  (entmakex (list '(0 . "CIRCLE") '(8 . "WELD_SYMBOL") (cons 10 center) (cons 40 radius))))

(defun weldsym:arc (center radius start end)
  (entmakex (list '(0 . "ARC") '(8 . "WELD_SYMBOL") (cons 10 center) (cons 40 radius) (cons 50 start) (cons 51 end))))

(defun weldsym:text (pt value height /)
  (if (and value (/= value ""))
    (entmakex
      (list
        '(0 . "TEXT")
        '(8 . "WELD_TEXT")
        (cons 10 pt)
        (cons 40 height)
        (cons 1 value)
        '(7 . "STANDARD")
        '(50 . 0.0)
        '(72 . 0)
        '(73 . 0)))))

(defun weldsym:ensure-layer (name color /)
  (if (not (tblsearch "LAYER" name))
    (entmakex
      (list
        '(0 . "LAYER")
        '(100 . "AcDbSymbolTableRecord")
        '(100 . "AcDbLayerTableRecord")
        (cons 2 name)
        '(70 . 0)
        (cons 62 color)
        '(6 . "Continuous")))))

(defun weldsym:arrow (tip tail / dir left right size a1 a2)
  (setq dir (angle tail tip))
  (setq size (weldsym:arrow-size))
  (setq a1 (+ dir (* pi 0.86)))
  (setq a2 (- dir (* pi 0.86)))
  (setq left (polar tip a1 size))
  (setq right (polar tip a2 size))
  (weldsym:line tip left)
  (weldsym:line tip right))

(defun weldsym:leader (arrow landing / oldcmd oldortho olddimasz result)
  (setq oldcmd (getvar "CMDECHO"))
  (setq oldortho (getvar "ORTHOMODE"))
  (setq olddimasz (getvar "DIMASZ"))
  (setvar "CMDECHO" 0)
  (setvar "ORTHOMODE" 0)
  (setvar "DIMASZ" (weldsym:arrow-size))
  (setq result
    (vl-catch-all-apply
      'command-s
      (list "_.LEADER" arrow landing "" "" "N")))
  (setvar "ORTHOMODE" oldortho)
  (setvar "DIMASZ" olddimasz)
  (setvar "CMDECHO" oldcmd)
  (if (vl-catch-all-error-p result)
    (progn
      (weldsym:line arrow landing)
      (weldsym:arrow arrow landing)))
  result)

(defun weldsym:draw-symbol (base u n symbol / w h p0 p1 p2 p3 c mid)
  ;; base is on the reference line. n points toward the symbol side.
  (setq w (weldsym:s 7.0))
  (setq h (weldsym:s 7.0))
  (setq p0 base)
  (setq p1 (weldsym:add base (weldsym:mul u w)))
  (setq p2 (weldsym:add p1 (weldsym:mul n h)))
  (setq p3 (weldsym:add base (weldsym:mul n h)))
  (setq mid (weldsym:add base (weldsym:mul u (/ w 2.0))))
  (cond
    ((= symbol "0")
      (weldsym:line p0 p1)
      (weldsym:line p1 p2)
      (weldsym:line p2 p0))
    ((= symbol "1")
      ;; V-groove: apex touches the reference line; legs open away from it.
      (weldsym:line mid (weldsym:add p0 (weldsym:mul n h)))
      (weldsym:line mid (weldsym:add p1 (weldsym:mul n h))))
    ((= symbol "2")
      (weldsym:line p0 p3)
      (weldsym:line (weldsym:add p0 (weldsym:mul u 2.2)) (weldsym:add p3 (weldsym:mul u 2.2))))
    ((= symbol "3")
      (setq c (weldsym:add mid (weldsym:mul n (/ h 2.0))))
      (weldsym:circle c (/ h 2.0)))
    ((= symbol "4")
      (setq c (weldsym:add mid (weldsym:mul n (/ h 2.0))))
      (weldsym:circle c (/ h 2.0))
      (weldsym:line (weldsym:add c (weldsym:mul u (weldsym:s -3.0))) (weldsym:add c (weldsym:mul u 3.0))))
    ((= symbol "5")
      (setq c (weldsym:add mid (weldsym:mul n (/ h 2.0))))
      (weldsym:line base p1)
      (weldsym:circle c (/ h 2.0)))))

(defun weldsym:draw-contour (base u n contour / c)
  (cond
    ((= contour "1")
      (weldsym:line base (weldsym:add base (weldsym:mul u (weldsym:s 8.0)))))
    ((= contour "2")
      (setq c (weldsym:add base (weldsym:mul u (weldsym:s 4.0))))
      (weldsym:arc c (weldsym:s 4.0) 0.0 pi))
    ((= contour "3")
      (setq c (weldsym:add base (weldsym:mul u (weldsym:s 4.0))))
      (weldsym:arc c (weldsym:s 4.0) pi (* 2.0 pi)))))

(defun weldsym:img-line (x1 y1 x2 y2 color)
  (vector_image (fix x1) (fix y1) (fix x2) (fix y2) color))

(defun weldsym:img-box (w h color)
  (weldsym:img-line 0 0 (- w 1) 0 color)
  (weldsym:img-line (- w 1) 0 (- w 1) (- h 1) color)
  (weldsym:img-line (- w 1) (- h 1) 0 (- h 1) color)
  (weldsym:img-line 0 (- h 1) 0 0 color))

(defun weldsym:img-circle (cx cy r color / i a1 a2 x1 y1 x2 y2)
  (setq i 0)
  (while (< i 16)
    (setq a1 (* 2.0 pi (/ i 16.0)))
    (setq a2 (* 2.0 pi (/ (+ i 1) 16.0)))
    (setq x1 (+ cx (* r (cos a1))))
    (setq y1 (+ cy (* r (sin a1))))
    (setq x2 (+ cx (* r (cos a2))))
    (setq y2 (+ cy (* r (sin a2))))
    (weldsym:img-line x1 y1 x2 y2 color)
    (setq i (+ i 1))))

(defun weldsym:draw-symbol-tile (key symbol selected / w h y x2)
  (start_image key)
  (setq w (dimx_tile key))
  (setq h (dimy_tile key))
  (fill_image 0 0 w h 0)
  (weldsym:img-box w h (if selected 1 8))
  (setq y (/ h 2))
  (setq x2 (/ w 2))
  (weldsym:img-line 5 y (- w 5) y 7)
  (cond
    ((= symbol "0")
      (weldsym:img-line (- x2 8) y (+ x2 8) y 7)
      (weldsym:img-line (+ x2 8) y (+ x2 8) (+ y 16) 7)
      (weldsym:img-line (+ x2 8) (+ y 16) (- x2 8) y 7))
    ((= symbol "1")
      ;; V-groove preview: point on reference line, open side below.
      (weldsym:img-line x2 y (- x2 10) (+ y 12) 7)
      (weldsym:img-line x2 y (+ x2 10) (+ y 12) 7))
    ((= symbol "2")
      (weldsym:img-line (- x2 4) y (- x2 4) (+ y 12) 7)
      (weldsym:img-line (+ x2 3) y (+ x2 3) (+ y 12) 7))
    ((= symbol "3")
      (weldsym:img-circle x2 (+ y 6) 6 7))
    ((= symbol "4")
      (weldsym:img-circle x2 (+ y 6) 6 7)
      (weldsym:img-line (- x2 7) (+ y 6) (+ x2 7) (+ y 6) 7))
    ((= symbol "5")
      (weldsym:img-line (- x2 12) (+ y 6) (+ x2 12) (+ y 6) 7)
      (weldsym:img-circle x2 (+ y 6) 6 7)))
  (end_image))

(defun weldsym:draw-side-tile (key side selected / w h y)
  (start_image key)
  (setq w (dimx_tile key))
  (setq h (dimy_tile key))
  (fill_image 0 0 w h 0)
  (weldsym:img-box w h (if selected 1 8))
  (setq y (/ h 2))
  (weldsym:img-line 5 y (- w 5) y 7)
  (if (or (= side "1") (= side "2"))
    (progn
      (weldsym:img-line 14 y 27 (- y 9) 7)
      (weldsym:img-line 27 (- y 9) 27 y 7)
      (weldsym:img-line 27 y 14 y 7)))
  (if (or (= side "0") (= side "2"))
    (progn
      (weldsym:img-line 14 y 27 (+ y 9) 7)
      (weldsym:img-line 27 (+ y 9) 27 y 7)
      (weldsym:img-line 27 y 14 y 7)))
  (end_image))
(defun weldsym:draw-dir-tile (key dir selected / w h y x0 x1)
  (start_image key)
  (setq w (dimx_tile key))
  (setq h (dimy_tile key))
  (fill_image 0 0 w h 0)
  (weldsym:img-box w h (if selected 1 8))
  (setq y (/ h 2))
  (if (= dir 0)
    (progn
      ;; Weld right: tail fork on left, reference line runs right, arrow down-right.
      (setq x0 7)
      (setq x1 (- w 13))
      (weldsym:img-line 3 (- y 8) x0 y 7)
      (weldsym:img-line 3 (+ y 8) x0 y 7)
      (weldsym:img-line x0 y x1 y 7)
      (weldsym:img-line x1 y (- w 5) (+ y 8) 7)
      (weldsym:img-line (- w 5) (+ y 8) (- w 10) (+ y 6) 7)
      (weldsym:img-line (- w 5) (+ y 8) (- w 7) (+ y 3) 7))
    (progn
      ;; Weld left: tail fork on right, reference line runs left, arrow down-left.
      (setq x0 (- w 7))
      (setq x1 13)
      (weldsym:img-line (- w 3) (- y 8) x0 y 7)
      (weldsym:img-line (- w 3) (+ y 8) x0 y 7)
      (weldsym:img-line x0 y x1 y 7)
      (weldsym:img-line x1 y 5 (+ y 8) 7)
      (weldsym:img-line 5 (+ y 8) 10 (+ y 6) 7)
      (weldsym:img-line 5 (+ y 8) 7 (+ y 3) 7)))
  (end_image))

(defun weldsym:draw-contour-tile (key contour selected / w h y cx)
  (start_image key)
  (setq w (dimx_tile key))
  (setq h (dimy_tile key))
  (fill_image 0 0 w h 0)
  (weldsym:img-box w h (if selected 1 8))
  (setq y (/ h 2))
  (setq cx (/ w 2))
  (cond
    ((= contour "1")
      (weldsym:img-line 8 y (- w 8) y 7))
    ((= contour "2")
      (weldsym:img-line (- cx 9) y (- cx 5) (- y 4) 7)
      (weldsym:img-line (- cx 5) (- y 4) cx (- y 6) 7)
      (weldsym:img-line cx (- y 6) (+ cx 5) (- y 4) 7)
      (weldsym:img-line (+ cx 5) (- y 4) (+ cx 9) y 7))
    ((= contour "3")
      (weldsym:img-line (- cx 9) (- y 4) (- cx 5) y 7)
      (weldsym:img-line (- cx 5) y cx (+ y 2) 7)
      (weldsym:img-line cx (+ y 2) (+ cx 5) y 7)
      (weldsym:img-line (+ cx 5) y (+ cx 9) (- y 4) 7)))
  (end_image))

(defun weldsym:draw-toolbox (/)
  (weldsym:draw-side-tile "side0" "0" (= *weldsym-dialog-side* "0"))
  (weldsym:draw-side-tile "side1" "1" (= *weldsym-dialog-side* "1"))
  (weldsym:draw-side-tile "side2" "2" (= *weldsym-dialog-side* "2"))
  (weldsym:draw-dir-tile "dir0" "0" (= *weldsym-dialog-dir* "0"))
  (weldsym:draw-dir-tile "dir1" "1" (= *weldsym-dialog-dir* "1"))
  (weldsym:draw-contour-tile "contour0" "0" (= *weldsym-dialog-contour* "0"))
  (weldsym:draw-contour-tile "contour1" "1" (= *weldsym-dialog-contour* "1"))
  (weldsym:draw-contour-tile "contour2" "2" (= *weldsym-dialog-contour* "2"))
  (weldsym:draw-contour-tile "contour3" "3" (= *weldsym-dialog-contour* "3")))

(defun weldsym:set-symbol (value)
  (setq *weldsym-dialog-symbol* value)
  (weldsym:draw-toolbox))

(defun weldsym:set-side (value)
  (setq *weldsym-dialog-side* value)
  (if (= value "2") (set_tile "bothrefs" "1") (set_tile "bothrefs" "0"))
  (weldsym:draw-toolbox))

(defun weldsym:set-contour (value)
  (setq *weldsym-dialog-contour* value)
  (weldsym:draw-toolbox))

(defun weldsym:set-dir (value)
  (setq *weldsym-dialog-dir* value)
  (weldsym:draw-toolbox))

(defun weldsym:show-direction (/ dcl file result)
  (setq file (findfile "weldsym.dcl"))
  (if (not file)
    (progn (alert "Cannot find weldsym.dcl. Keep weldsym.lsp and weldsym.dcl together.") nil)
    (progn
      (setq dcl (load_dialog file))
      (if (not (new_dialog "weldsym_dir" dcl))
        (progn (unload_dialog dcl) nil)
        (progn
          (weldsym:draw-dir-tile "dir_pick0" "0" (= *weldsym-dialog-dir* "0"))
          (weldsym:draw-dir-tile "dir_pick1" "1" (= *weldsym-dialog-dir* "1"))
          (action_tile "dir_pick0" "(setq *weldsym-dialog-dir* \"0\") (done_dialog 1)")
          (action_tile "dir_pick1" "(setq *weldsym-dialog-dir* \"1\") (done_dialog 1)")
          (action_tile "cancel" "(done_dialog 0)")
          (setq result (start_dialog))
          (unload_dialog dcl)
          (if (= result 1) *weldsym-dialog-dir* nil))))))

(defun weldsym:show-type (/ dcl file result)
  (setq *weldsym-dialog-symbol* "0")
  (setq file (findfile "weldsym.dcl"))
  (if (not file)
    (progn (alert "Cannot find weldsym.dcl. Keep weldsym.lsp and weldsym.dcl together.") nil)
    (progn
      (setq dcl (load_dialog file))
      (if (not (new_dialog "weldsym_type" dcl))
        (progn (unload_dialog dcl) nil)
        (progn
          (weldsym:draw-symbol-tile "sym0" "0" T)
          (action_tile "sym0" "(setq *weldsym-dialog-symbol* \"0\") (done_dialog 1)")
          (action_tile "cancel" "(done_dialog 0)")
          (setq result (start_dialog))
          (unload_dialog dcl)
          (if (= result 1) "0" nil))))))

(defun weldsym:show-options (/ dcl file result)
  (setq file (findfile "weldsym.dcl"))
  (if (not file)
    (progn (alert "Cannot find weldsym.dcl. Keep weldsym.lsp and weldsym.dcl together.") nil)
    (progn
      (setq dcl (load_dialog file))
      (if (not (new_dialog "weldsym_opts" dcl))
        (progn (unload_dialog dcl) nil)
        (progn
          (setq *weldsym-dialog-side* (weldsym:alist-get 'side *weldsym-last* "0"))
          (setq *weldsym-dialog-contour* (weldsym:alist-get 'contour *weldsym-last* "0"))
          (set_tile "size" (weldsym:alist-get 'size *weldsym-last* ""))
          (set_tile "length" (weldsym:alist-get 'length *weldsym-last* ""))
          (set_tile "pitch" (weldsym:alist-get 'pitch *weldsym-last* ""))
          (set_tile "field" (weldsym:alist-get 'field *weldsym-last* "0"))
          (set_tile "allaround" (weldsym:alist-get 'allaround *weldsym-last* "0"))
          (set_tile "tailon" (weldsym:alist-get 'tailon *weldsym-last* "0"))
          (set_tile "process" (weldsym:alist-get 'process *weldsym-last* ""))
          (set_tile "tailtext" (weldsym:alist-get 'tailtext *weldsym-last* ""))
          (set_tile "tailtext2" (weldsym:alist-get 'tailtext2 *weldsym-last* ""))
          (weldsym:draw-side-tile "side0" "0" (= *weldsym-dialog-side* "0"))
          (weldsym:draw-side-tile "side1" "1" (= *weldsym-dialog-side* "1"))
          (weldsym:draw-side-tile "side2" "2" (= *weldsym-dialog-side* "2"))
          (weldsym:draw-contour-tile "contour0" "0" (= *weldsym-dialog-contour* "0"))
          (weldsym:draw-contour-tile "contour1" "1" (= *weldsym-dialog-contour* "1"))
          (weldsym:draw-contour-tile "contour2" "2" (= *weldsym-dialog-contour* "2"))
          (weldsym:draw-contour-tile "contour3" "3" (= *weldsym-dialog-contour* "3"))
          (action_tile "side0" "(setq *weldsym-dialog-side* \"0\") (weldsym:draw-side-tile \"side0\" \"0\" T) (weldsym:draw-side-tile \"side1\" \"1\" nil) (weldsym:draw-side-tile \"side2\" \"2\" nil)")
          (action_tile "side1" "(setq *weldsym-dialog-side* \"1\") (weldsym:draw-side-tile \"side0\" \"0\" nil) (weldsym:draw-side-tile \"side1\" \"1\" T) (weldsym:draw-side-tile \"side2\" \"2\" nil)")
          (action_tile "side2" "(setq *weldsym-dialog-side* \"2\") (weldsym:draw-side-tile \"side0\" \"0\" nil) (weldsym:draw-side-tile \"side1\" \"1\" nil) (weldsym:draw-side-tile \"side2\" \"2\" T)")
          (action_tile "contour0" "(weldsym:set-contour \"0\")")
          (action_tile "contour1" "(weldsym:set-contour \"1\")")
          (action_tile "contour2" "(weldsym:set-contour \"2\")")
          (action_tile "contour3" "(weldsym:set-contour \"3\")")
          (action_tile "accept"
            "(setq *weldsym-last*
              (list
                (cons 'symbol *weldsym-dialog-symbol*)
                (cons 'side *weldsym-dialog-side*)
                (cons 'size (get_tile \"size\"))
                (cons 'length (get_tile \"length\"))
                (cons 'pitch (get_tile \"pitch\"))
                (cons 'field (get_tile \"field\"))
                (cons 'allaround (get_tile \"allaround\"))
                (cons 'tailon (get_tile \"tailon\"))
                (cons 'process (get_tile \"process\"))
                (cons 'tailtext (get_tile \"tailtext\"))
                (cons 'tailtext2 (get_tile \"tailtext2\"))
                (cons 'contour *weldsym-dialog-contour*)
                (cons 'dir *weldsym-dialog-dir*)))
             (done_dialog 1)")
          (action_tile "cancel" "(done_dialog 0)")
          (setq result (start_dialog))
          (unload_dialog dcl)
          (if (= result 1) *weldsym-last* nil))))))



(defun weldsym:draw-field-flag (landing u n / mast-top tip lower)
  ;; Field weld flag: 36 wide, 96 mast height, and symmetric 18.43 degree edges.
  (setq mast-top (weldsym:add landing (weldsym:mul n (weldsym:s 16.0))))
  (setq lower (weldsym:add mast-top (weldsym:mul n (weldsym:s -4.0))))
  (setq tip (weldsym:add mast-top (weldsym:add (weldsym:mul u (weldsym:s 6.0)) (weldsym:mul n (weldsym:s -2.0)))))
  (weldsym:line landing mast-top)
  (weldsym:solid-triangle mast-top tip lower))
(defun weldsym:draw-tail-fork (ref-end u n / top bottom)
  (setq top (weldsym:add ref-end (weldsym:add (weldsym:mul u (weldsym:s 6.0)) (weldsym:mul n (weldsym:s 6.0)))))
  (setq bottom (weldsym:add ref-end (weldsym:add (weldsym:mul u (weldsym:s 6.0)) (weldsym:mul n (weldsym:s -6.0)))))
  (weldsym:line ref-end top)
  (weldsym:line ref-end bottom))
(defun weldsym:tail-line1 (data / a b)
  (setq a (weldsym:alist-get 'process data ""))
  (setq b (weldsym:alist-get 'tailtext data ""))
  (cond
    ((and (/= a "") (/= b "")) (strcat a " " b))
    ((/= a "") a)
    (T b)))

(defun weldsym:tail-line2 (data)
  (weldsym:alist-get 'tailtext2 data ""))

(defun weldsym:tail-text (data)
  (weldsym:tail-line1 data))

(defun weldsym:draw (arrow landing ref-end data / sign u n below above symbol side size length pitch contour dir tail1 tail2)
  (setq n '(0.0 1.0 0.0))
  (setq symbol (weldsym:alist-get 'symbol data "0"))
  (setq side (weldsym:alist-get 'side data "0"))
  (setq size (weldsym:alist-get 'size data ""))
  (setq length (weldsym:alist-get 'length data ""))
  (setq pitch (weldsym:alist-get 'pitch data ""))
  (setq contour (weldsym:alist-get 'contour data "0"))
  (setq dir (weldsym:alist-get 'dir data "0"))
  (setq sign (if (= dir "1") -1.0 1.0))
  (setq u (list sign 0.0 0.0))
  (setq tail1 (weldsym:tail-line1 data))
  (setq tail2 (weldsym:tail-line2 data))
  (weldsym:leader arrow landing)
  (weldsym:line landing ref-end)

  (if (= (weldsym:alist-get 'allaround data "0") "1")
    (weldsym:circle landing (weldsym:s 3.0)))

  (if (= (weldsym:alist-get 'field data "0") "1")
    (weldsym:draw-field-flag landing u n))

  (setq below (weldsym:add landing (weldsym:mul u (weldsym:s 24.0))))
  (setq above (weldsym:add landing (weldsym:mul u (weldsym:s 24.0))))

  (if (or (= side "0") (= side "2"))
    (progn
      (weldsym:draw-symbol below u (weldsym:mul n -1.0) symbol)
      (weldsym:draw-contour (weldsym:add below (weldsym:add (weldsym:mul u (weldsym:s 17.0)) (weldsym:mul n (weldsym:s -5.5)))) u (weldsym:mul n -1.0) contour)))

  (if (or (= side "1") (= side "2"))
    (progn
      (weldsym:draw-symbol above u n symbol)
      (weldsym:draw-contour (weldsym:add above (weldsym:add (weldsym:mul u (weldsym:s 17.0)) (weldsym:mul n (weldsym:s 5.5)))) u n contour)))

  (weldsym:text (weldsym:add landing (weldsym:add (weldsym:mul u (weldsym:s 18.0)) (weldsym:mul n (weldsym:s -7.0)))) size (weldsym:s 2.5))
  (if (and (/= length "") (/= pitch ""))
    (weldsym:text (weldsym:add landing (weldsym:add (weldsym:mul u (weldsym:s 36.0)) (weldsym:mul n (weldsym:s -7.0)))) (strcat length "-" pitch) (weldsym:s 2.5))
    (weldsym:text (weldsym:add landing (weldsym:add (weldsym:mul u (weldsym:s 36.0)) (weldsym:mul n (weldsym:s -7.0)))) length (weldsym:s 2.5)))

  (if (or (= (weldsym:alist-get 'tailon data "0") "1") (/= tail1 "") (/= tail2 ""))
    (progn
      (weldsym:draw-tail-fork ref-end u n)
      (weldsym:text (weldsym:add ref-end (weldsym:add (weldsym:mul u (weldsym:s 17.0)) (weldsym:mul n (weldsym:s 1.5)))) tail1 (weldsym:s 2.5))
      (weldsym:text (weldsym:add ref-end (weldsym:add (weldsym:mul u (weldsym:s 17.0)) (weldsym:mul n (weldsym:s -3.0)))) tail2 (weldsym:s 2.5)))))

(defun weldsym:run (preset-dir / arrow landing refpick ref-end data dist)
  (if preset-dir
    (setq *weldsym-dialog-dir* preset-dir)
    (setq *weldsym-dialog-dir* (weldsym:show-direction)))
  (if *weldsym-dialog-dir*
    (progn
      (setq arrow (getpoint "\nSpecify weld arrow point: "))
      (if arrow
        (progn
          (setq landing (getpoint arrow "\nSpecify leader elbow / reference line start: "))
          (if landing
            (progn
              (setq refpick (getpoint landing "\nSpecify reference line end point: "))
              (if refpick
                (progn
                  (setq dist (abs (- (car refpick) (car landing))))
                  (if (< dist 1.0) (setq dist (distance landing refpick)))
                  (setq ref-end (weldsym:add landing (weldsym:mul (list (if (= *weldsym-dialog-dir* "1") -1.0 1.0) 0.0 0.0) dist)))
                  (setq *weldsym-dialog-symbol* (weldsym:show-type))
                  (if *weldsym-dialog-symbol*
                    (progn
                      (setq data (weldsym:show-options))
                      (if data
                        (progn (weldsym:draw arrow landing ref-end data) (princ "\nWeld symbol created."))
                        (princ "\nWeld options cancelled.")))
                    (princ "\nWeld type cancelled.")))
                (princ "\nReference line end cancelled.")))))))))

(defun c:WELDSYM (/ oldcmdecho)
  (setq oldcmdecho (getvar "CMDECHO"))
  (setvar "CMDECHO" 0)
  (weldsym:ensure-layer "WELD_SYMBOL" 7)
  (weldsym:ensure-layer "WELD_TEXT" 3)
  (weldsym:run nil)
  (setvar "CMDECHO" oldcmdecho)
  (princ))

(defun c:WELDRIGHT (/ oldcmdecho)
  (setq oldcmdecho (getvar "CMDECHO"))
  (setvar "CMDECHO" 0)
  (weldsym:ensure-layer "WELD_SYMBOL" 7)
  (weldsym:ensure-layer "WELD_TEXT" 3)
  (weldsym:run "0")
  (setvar "CMDECHO" oldcmdecho)
  (princ))

(defun c:WELDLEFT (/ oldcmdecho)
  (setq oldcmdecho (getvar "CMDECHO"))
  (setvar "CMDECHO" 0)
  (weldsym:ensure-layer "WELD_SYMBOL" 7)
  (weldsym:ensure-layer "WELD_TEXT" 3)
  (weldsym:run "1")
  (setvar "CMDECHO" oldcmdecho)
  (princ))

(defun weldsym:toggle-last (key label / cur next old)
  (setq cur (weldsym:alist-get key *weldsym-last* "0"))
  (setq next (if (= cur "1") "0" "1"))
  (setq old (assoc key *weldsym-last*))
  (if old
    (setq *weldsym-last* (subst (cons key next) old *weldsym-last*))
    (setq *weldsym-last* (cons (cons key next) *weldsym-last*)))
  (princ (strcat "\n" label " default " (if (= next "1") "ON" "OFF") "."))
  (princ))

(defun c:WELDFIELD () (weldsym:toggle-last 'field "Field weld"))
(defun c:WELDALLAROUND () (weldsym:toggle-last 'allaround "All-around weld"))
(defun c:WELDTAIL () (weldsym:toggle-last 'tailon "Tail"))


(defun weldsym:support-file (name / base)
  (setq base (vl-filename-directory (findfile "weldsym.lsp")))
  (if base (strcat base "/" name) name))

(defun weldsym:get-menugroup (group-name / acad groups found)
  (setq acad (vlax-get-acad-object))
  (setq groups (vla-get-MenuGroups acad))
  (setq found nil)
  (vlax-for group groups
    (if (= (strcase (vla-get-Name group)) (strcase group-name))
      (setq found group)))
  (if found found (vla-Item groups 0)))

(defun weldsym:get-toolbar (toolbars toolbar-name / found)
  (setq found nil)
  (vlax-for tb toolbars
    (if (= (strcase (vla-get-Name tb)) (strcase toolbar-name))
      (setq found tb)))
  found)

(defun weldsym:add-toolbar-button (tb index name help macro small large / btn)
  (setq btn (vla-AddToolbarButton tb index name help macro :vlax-false))
  (if (and small large (/= small "") (/= large ""))
    (vl-catch-all-apply 'vla-SetBitmaps (list btn (weldsym:support-file small) (weldsym:support-file large))))
  btn)

(defun weldsym:ensure-toolbar (/ group toolbars tb)
  ;; AutoCAD uses this global setting for toolbar button size.
  (if (getvar "LARGEICONS") (setvar "LARGEICONS" 1))
  (setq group (weldsym:get-menugroup "ACAD"))
  (setq toolbars (vla-get-Toolbars group))
  (setq tb (weldsym:get-toolbar toolbars "WELDSYM"))
  ;; Rebuild on load so old toolbar buttons with stale macros get replaced.
  (if tb
    (progn
      (vl-catch-all-apply 'vla-Delete (list tb))
      (setq tb nil)))
  (setq tb (vla-Add toolbars "WELDSYM"))
  (weldsym:add-toolbar-button tb 0 "Weld Right" "Start weld callout to the right" "WELDRIGHT " "weldright16.bmp" "weldright32.bmp")
  (weldsym:add-toolbar-button tb 1 "Weld Left" "Start weld callout to the left" "WELDLEFT " "weldleft16.bmp" "weldleft32.bmp")
  (weldsym:add-toolbar-button tb 2 "Field" "Toggle field weld default" "WELDFIELD " "weldfield16.bmp" "weldfield32.bmp")
  (weldsym:add-toolbar-button tb 3 "All Around" "Toggle weld all around default" "WELDALLAROUND " "weldaround16.bmp" "weldaround32.bmp")
  (weldsym:add-toolbar-button tb 4 "Tail" "Toggle tail default" "WELDTAIL " "weldtail16.bmp" "weldtail32.bmp")
  (vla-put-Visible tb :vlax-true)
  (vl-catch-all-apply 'vla-Dock (list tb 3))
  tb)

(defun c:WELDTOOLBAR ()
  (weldsym:ensure-toolbar)
  (princ "\nWELDSYM toolbar is visible.")
  (princ))

(vl-catch-all-apply 'weldsym:ensure-toolbar nil)
(princ "\nWELDSYM loaded. Run WELDSYM to place a weld symbol.")
(princ)




































