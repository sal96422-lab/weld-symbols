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
(setq *weldsym-type-preset-side* nil)
(setq *weldsym-type-preset-length* nil)
(setq *weldsym-type-preset-staggered* "0")
(setq *weldsym-scale* 6.0)
(setq *weldsym-current-landing* nil)
(setq *weldsym-current-ref-end* nil)
(setq *weldsym-current-u* nil)
(setq *weldsym-current-symbol-u* nil)
(setq *weldsym-current-tail-u* nil)
(setq *weldsym-current-n* nil)

(setq *weldsym-last*
  '((symbol . "0")
    (side . "0")
    (size . "")
    (othersize . "")
    (length . "")
    (pitch . "")
    (otherlength . "")
    (otherpitch . "")
    (field . "0")
    (allaround . "0")
    (tailon . "0")
    (process . "")
    (tailtext . "")
    (tailtext2 . "")
    (contour . "0")
    (staggered . "0")
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

(defun weldsym:leader-dimasz (/ dimscale)
  (setq dimscale (getvar "DIMSCALE"))
  (if (or (not dimscale) (<= dimscale 0.0))
    (weldsym:arrow-size)
    (/ (weldsym:arrow-size) dimscale)))


(defun weldsym:solid-triangle (p1 p2 p3)
  (entmakex
    (list
      '(0 . "SOLID")
      '(8 . "2")
      (cons 10 p1)
      (cons 11 p2)
      (cons 12 p3)
      (cons 13 p3))))
(defun weldsym:line (p q)
  (entmakex (list '(0 . "LINE") '(8 . "2") (cons 10 p) (cons 11 q))))

(defun weldsym:circle (center radius)
  (entmakex (list '(0 . "CIRCLE") '(8 . "2") (cons 10 center) (cons 40 radius))))

(defun weldsym:arc (center radius start end)
  (entmakex (list '(0 . "ARC") '(8 . "2") (cons 10 center) (cons 40 radius) (cons 50 start) (cons 51 end))))

(defun weldsym:text (pt value height /)
  (if (and value (/= value ""))
    (entmakex
      (list
        '(0 . "TEXT")
        '(8 . "1")
        (cons 10 pt)
        (cons 40 height)
        (cons 1 value)
        '(7 . "4")
        '(41 . 1.0)
        '(50 . 0.0)
        '(51 . 0.0)
        '(72 . 0)
        '(73 . 0)))))


(defun weldsym:text-right (pt value height /)
  (if (and value (/= value ""))
    (entmakex
      (list
        '(0 . "TEXT")
        '(8 . "1")
        (cons 10 pt)
        (cons 11 pt)
        (cons 40 height)
        (cons 1 value)
        '(7 . "4")
        '(41 . 1.0)
        '(50 . 0.0)
        '(51 . 0.0)
        '(72 . 2)
        '(73 . 0)))))

(defun weldsym:text-middle-left (pt value height /)
  (if (and value (/= value ""))
    (entmakex
      (list
        '(0 . "TEXT")
        '(8 . "1")
        (cons 10 pt)
        (cons 11 pt)
        (cons 40 height)
        (cons 1 value)
        '(7 . "4")
        '(41 . 1.0)
        '(50 . 0.0)
        '(51 . 0.0)
        '(72 . 0)
        '(73 . 2)))))
(defun weldsym:text-middle-right (pt value height /)
  (if (and value (/= value ""))
    (entmakex
      (list
        '(0 . "TEXT")
        '(8 . "1")
        (cons 10 pt)
        (cons 11 pt)
        (cons 40 height)
        (cons 1 value)
        '(7 . "4")
        '(41 . 1.0)
        '(50 . 0.0)
        '(51 . 0.0)
        '(72 . 2)
        '(73 . 2)))))

(defun weldsym:tail-text-entity (pt value height u /)
  (if (< (car u) 0.0)
    (weldsym:text-middle-right pt value height)
    (weldsym:text-middle-left pt value height)))
(defun weldsym:ensure-text-style (/)
  (if (not (tblsearch "STYLE" "4"))
    (entmakex
      (list
        '(0 . "STYLE")
        '(100 . "AcDbSymbolTableRecord")
        '(100 . "AcDbTextStyleTableRecord")
        '(2 . "4")
        '(70 . 0)
        '(40 . 0.0)
        '(41 . 1.0)
        '(50 . 0.0)
        '(71 . 0)
        '(42 . 2.5)
        '(3 . "txt.shx")
        '(4 . "")))))
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

(defun weldsym:leader (arrow landing / oldcmd oldortho olddimasz oldclayer oldcecolor oldceltype oldcelweight result)
  (setq oldcmd (getvar "CMDECHO"))
  (setq oldortho (getvar "ORTHOMODE"))
  (setq olddimasz (getvar "DIMASZ"))
  (setq oldclayer (getvar "CLAYER"))
  (setq oldcecolor (getvar "CECOLOR"))
  (setq oldceltype (getvar "CELTYPE"))
  (setq oldcelweight (getvar "CELWEIGHT"))
  (setvar "CMDECHO" 0)
  (setvar "ORTHOMODE" 0)
  (setvar "DIMASZ" (weldsym:leader-dimasz))
  (setvar "CLAYER" "2")
  (setvar "CECOLOR" "BYLAYER")
  (setvar "CELTYPE" "BYLAYER")
  (setvar "CELWEIGHT" -1)
  (setq result
    (vl-catch-all-apply
      'command-s
      (list "_.LEADER" arrow landing "" "" "N")))
  (setvar "CELWEIGHT" oldcelweight)
  (setvar "CELTYPE" oldceltype)
  (setvar "CECOLOR" oldcecolor)
  (setvar "CLAYER" oldclayer)
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
      (weldsym:line p0 p3)
      (weldsym:line p3 p1))
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
      (weldsym:img-line (- x2 8) y (- x2 8) (+ y 16) 7)
      (weldsym:img-line (- x2 8) (+ y 16) (+ x2 8) y 7))
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
(defun weldsym:blank-image-tile (key / w h)
  (start_image key)
  (setq w (dimx_tile key))
  (setq h (dimy_tile key))
  (fill_image 0 0 w h 0)
  (end_image))
(defun weldsym:draw-fillet-preset-tile (key side has-length / w h y x0 x1 xleg xtip yref ytop ybot tx ty)
  (start_image key)
  (setq w (dimx_tile key))
  (setq h (dimy_tile key))
  (fill_image 0 0 w h 0)
  (weldsym:img-box w h 8)
  (if (and (= has-length "0") (member side '("0" "1" "2")))
    (progn
      (setq yref (if (= side "2") (/ h 2) (max 5 (/ h 3))))
      (setq xleg (max 32 (/ w 3)))
      (setq ytop (max 4 (- yref (/ h 4))))
      (setq ybot (min (- h 5) (+ yref (/ h 4))))
      (setq xtip (+ xleg (- ybot yref)))
      (weldsym:img-line 2 yref (- w 2) yref 2)
      (cond
        ((= side "0")
          (weldsym:img-line xleg yref xleg ybot 2)
          (weldsym:img-line xleg ybot xtip yref 2))
        ((= side "1")
          (weldsym:img-line xleg yref xleg ytop 2)
          (weldsym:img-line xleg ytop xtip yref 2))
        ((= side "2")
          (weldsym:img-line xleg yref xleg ytop 2)
          (weldsym:img-line xleg ytop xtip yref 2)
          (weldsym:img-line xleg yref xleg ybot 2)
          (weldsym:img-line xleg ybot xtip yref 2)))
      (if (or (= side "0") (= side "2"))
        (progn
          (setq tx (max 5 (- xleg 13)))
          (setq ty (if (= side "2") (+ yref 5) (- h 13)))
          (weldsym:img-line tx ty (+ tx 2) (+ ty 9) 1)
          (weldsym:img-line (+ tx 2) (+ ty 9) (+ tx 5) (+ ty 3) 1)
          (weldsym:img-line (+ tx 5) (+ ty 3) (+ tx 8) (+ ty 9) 1)
          (weldsym:img-line (+ tx 10) ty (+ tx 10) (+ ty 9) 1)
          (weldsym:img-line (+ tx 8) (+ ty 2) (+ tx 10) ty 1)))
      (if (or (= side "1") (= side "2"))
        (progn
          (setq tx (max 5 (- xleg 24)))
          (setq ty (if (= side "2") (- yref 16) (- yref 17)))
          (weldsym:img-line tx ty (+ tx 2) (+ ty 9) 1)
          (weldsym:img-line (+ tx 2) (+ ty 9) (+ tx 5) (+ ty 3) 1)
          (weldsym:img-line (+ tx 5) (+ ty 3) (+ tx 8) (+ ty 9) 1)
          (weldsym:img-line (+ tx 10) ty (+ tx 10) (+ ty 9) 1)
          (weldsym:img-line (+ tx 8) (+ ty 2) (+ tx 10) ty 1)
          (weldsym:img-line (+ tx 13) ty (+ tx 19) ty 1)
          (weldsym:img-line (+ tx 19) ty (+ tx 19) (+ ty 4) 1)
          (weldsym:img-line (+ tx 19) (+ ty 4) (+ tx 13) (+ ty 9) 1)
          (weldsym:img-line (+ tx 13) (+ ty 9) (+ tx 19) (+ ty 9) 1))))
    (progn
      (setq y (/ h 2))
      (setq x0 8)
      (setq x1 (- w 8))
      (weldsym:img-line 4 y (- w 4) y 7)
      (if (or (= side "1") (= side "2"))
        (progn
          (weldsym:img-line (- x0 2) y (+ x0 12) (- y 10) 7)
          (weldsym:img-line (+ x0 12) (- y 10) (+ x0 12) y 7)
          (weldsym:img-line (+ x0 12) y (- x0 2) y 7)))
      (if (or (= side "0") (= side "2"))
        (progn
          (weldsym:img-line (- x0 2) y (+ x0 12) (+ y 10) 7)
          (weldsym:img-line (+ x0 12) (+ y 10) (+ x0 12) y 7)
          (weldsym:img-line (+ x0 12) y (- x0 2) y 7)))
      (if (= has-length "1")
        (progn
          (weldsym:img-line (- x1 13) (- y 7) (- x1 13) (+ y 7) 3)
          (weldsym:img-line (- x1 13) (+ y 7) (- x1 3) (+ y 7) 3)))))
  (end_image))

(defun weldsym:draw-staggered-preset-tile (key has-length / w h y xleg1 xleg2 xtip1 xtip2 ytop ybot tx ty)
  (start_image key)
  (setq w (dimx_tile key))
  (setq h (dimy_tile key))
  (fill_image 0 0 w h 0)
  (weldsym:img-box w h 8)
  (setq y (/ h 2))
  (setq xleg1 (max 32 (/ w 3)))
  (setq xleg2 (+ xleg1 14))
  (setq ytop (max 4 (- y (/ h 4))))
  (setq ybot (min (- h 5) (+ y (/ h 4))))
  (setq xtip1 (+ xleg1 (- y ytop)))
  (setq xtip2 (+ xleg2 (- ybot y)))
  (weldsym:img-line 2 y (- w 2) y 2)
  (weldsym:img-line xleg1 y xleg1 ytop 2)
  (weldsym:img-line xleg1 ytop xtip1 y 2)
  (weldsym:img-line xleg2 y xleg2 ybot 2)
  (weldsym:img-line xleg2 ybot xtip2 y 2)
  (setq tx (max 5 (- xleg1 24)))
  (setq ty (- y 16))
  (weldsym:img-line tx ty (+ tx 2) (+ ty 9) 1)
  (weldsym:img-line (+ tx 2) (+ ty 9) (+ tx 5) (+ ty 3) 1)
  (weldsym:img-line (+ tx 5) (+ ty 3) (+ tx 8) (+ ty 9) 1)
  (weldsym:img-line (+ tx 10) ty (+ tx 10) (+ ty 9) 1)
  (weldsym:img-line (+ tx 8) (+ ty 2) (+ tx 10) ty 1)
  (weldsym:img-line (+ tx 13) ty (+ tx 19) ty 1)
  (weldsym:img-line (+ tx 19) ty (+ tx 19) (+ ty 4) 1)
  (weldsym:img-line (+ tx 19) (+ ty 4) (+ tx 13) (+ ty 9) 1)
  (weldsym:img-line (+ tx 13) (+ ty 9) (+ tx 19) (+ ty 9) 1)
  (setq tx (max 5 (- xleg2 13)))
  (setq ty (+ y 5))
  (weldsym:img-line tx ty (+ tx 2) (+ ty 9) 1)
  (weldsym:img-line (+ tx 2) (+ ty 9) (+ tx 5) (+ ty 3) 1)
  (weldsym:img-line (+ tx 5) (+ ty 3) (+ tx 8) (+ ty 9) 1)
  (weldsym:img-line (+ tx 10) ty (+ tx 10) (+ ty 9) 1)
  (weldsym:img-line (+ tx 8) (+ ty 2) (+ tx 10) ty 1)
  (if (= has-length "1")
    (progn
      (weldsym:img-line (- w 18) (- y 7) (- w 18) (+ y 7) 3)
      (weldsym:img-line (- w 18) (+ y 7) (- w 6) (+ y 7) 3)))
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

(defun weldsym:set-type-preset (side has-length staggered)
  (setq *weldsym-dialog-symbol* "0")
  (setq *weldsym-type-preset-side* side)
  (setq *weldsym-type-preset-length* has-length)
  (setq *weldsym-type-preset-staggered* staggered)
  (setq *weldsym-dialog-side* side)
  (done_dialog 1))
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
  (setq *weldsym-type-preset-side* nil)
  (setq *weldsym-type-preset-length* nil)
  (setq *weldsym-type-preset-staggered* "0")
  (setq file (findfile "weldsym.dcl"))
  (if (not file)
    (progn (alert "Cannot find weldsym.dcl. Keep weldsym.lsp and weldsym.dcl together.") nil)
    (progn
      (setq dcl (load_dialog file))
      (if (not (new_dialog "weldsym_type" dcl))
        (progn (unload_dialog dcl) nil)
        (progn
          (weldsym:draw-fillet-preset-tile "type_arrow" "0" "0")
          (weldsym:draw-fillet-preset-tile "type_other" "1" "0")
          (weldsym:draw-fillet-preset-tile "type_both" "2" "0")
          (weldsym:draw-fillet-preset-tile "type_arrow_len" "0" "1")
          (weldsym:draw-fillet-preset-tile "type_other_len" "1" "1")
          (weldsym:draw-fillet-preset-tile "type_both_len" "2" "1")
          (weldsym:draw-staggered-preset-tile "type_stagger_len" "1")
          (action_tile "type_arrow" "(weldsym:set-type-preset \"0\" \"0\" \"0\")")
          (action_tile "type_other" "(weldsym:set-type-preset \"1\" \"0\" \"0\")")
          (action_tile "type_both" "(weldsym:set-type-preset \"2\" \"0\" \"0\")")
          (action_tile "type_arrow_len" "(weldsym:set-type-preset \"0\" \"1\" \"0\")")
          (action_tile "type_other_len" "(weldsym:set-type-preset \"1\" \"1\" \"0\")")
          (action_tile "type_both_len" "(weldsym:set-type-preset \"2\" \"1\" \"0\")")
          (action_tile "type_stagger_len" "(weldsym:set-type-preset \"2\" \"1\" \"1\")")
          (action_tile "cancel" "(done_dialog 0)")
          (setq result (start_dialog))
          (unload_dialog dcl)
          (if (= result 1) "0" nil))))))
(defun weldsym:apply-type-preset-modes ()
  (set_tile "side_label0" "Arrow")
  (set_tile "side_label1" "Other")
  (set_tile "side_label2" "Both")
  (if *weldsym-type-preset-side*
    (progn
      (mode_tile "side0" (if (= *weldsym-type-preset-side* "0") 0 1))
      (mode_tile "side1" (if (= *weldsym-type-preset-side* "1") 0 1))
      (mode_tile "side2" (if (= *weldsym-type-preset-side* "2") 0 1))
      (if (/= *weldsym-type-preset-side* "0") (progn (weldsym:blank-image-tile "side0") (set_tile "side_label0" "")))
      (if (/= *weldsym-type-preset-side* "1") (progn (weldsym:blank-image-tile "side1") (set_tile "side_label1" "")))
      (if (/= *weldsym-type-preset-side* "2") (progn (weldsym:blank-image-tile "side2") (set_tile "side_label2" "")))
      (cond
        ((= *weldsym-type-preset-side* "0")
          (set_tile "othersize" "")
          (set_tile "otherlength" "")
          (set_tile "otherpitch" "")
          (mode_tile "othersize" 1)
          (mode_tile "otherlength" 1)
          (mode_tile "otherpitch" 1))
        ((= *weldsym-type-preset-side* "1")
          (set_tile "size" "")
          (set_tile "length" "")
          (set_tile "pitch" "")
          (mode_tile "size" 1)
          (mode_tile "length" 1)
          (mode_tile "pitch" 1)))))
  (if (= *weldsym-type-preset-length* "0")
    (progn
      (set_tile "length" "")
      (set_tile "pitch" "")
      (set_tile "otherlength" "")
      (set_tile "otherpitch" "")
      (mode_tile "length" 1)
      (mode_tile "pitch" 1)
      (mode_tile "otherlength" 1)
      (mode_tile "otherpitch" 1))))

(defun weldsym:show-options (/ dcl file result)
  (setq file (findfile "weldsym.dcl"))
  (if (not file)
    (progn (alert "Cannot find weldsym.dcl. Keep weldsym.lsp and weldsym.dcl together.") nil)
    (progn
      (setq dcl (load_dialog file))
      (if (not (new_dialog "weldsym_opts" dcl))
        (progn (unload_dialog dcl) nil)
        (progn
          (setq *weldsym-dialog-side* (if *weldsym-type-preset-side* *weldsym-type-preset-side* (weldsym:alist-get 'side *weldsym-last* "0")))
          (setq *weldsym-dialog-contour* (weldsym:alist-get 'contour *weldsym-last* "0"))
          (set_tile "size" (weldsym:alist-get 'size *weldsym-last* ""))
          (set_tile "othersize" (weldsym:alist-get 'othersize *weldsym-last* ""))
          (set_tile "length" (weldsym:alist-get 'length *weldsym-last* ""))
          (set_tile "pitch" (weldsym:alist-get 'pitch *weldsym-last* ""))
          (set_tile "otherlength" (weldsym:alist-get 'otherlength *weldsym-last* ""))
          (set_tile "otherpitch" (weldsym:alist-get 'otherpitch *weldsym-last* ""))
          (set_tile "field" (weldsym:alist-get 'field *weldsym-last* "0"))
          (set_tile "allaround" (weldsym:alist-get 'allaround *weldsym-last* "0"))
          (set_tile "tailon" (weldsym:alist-get 'tailon *weldsym-last* "0"))
          (set_tile "process" (weldsym:alist-get 'process *weldsym-last* ""))
          (set_tile "tailtext" (weldsym:alist-get 'tailtext *weldsym-last* ""))
          (set_tile "tailtext2" (weldsym:alist-get 'tailtext2 *weldsym-last* ""))
          (weldsym:draw-side-tile "side0" "0" (= *weldsym-dialog-side* "0"))
          (weldsym:draw-side-tile "side1" "1" (= *weldsym-dialog-side* "1"))
          (weldsym:draw-side-tile "side2" "2" (= *weldsym-dialog-side* "2"))
          (weldsym:apply-type-preset-modes)
          (weldsym:draw-contour-tile "contour0" "0" (= *weldsym-dialog-contour* "0"))
          (weldsym:draw-contour-tile "contour1" "1" (= *weldsym-dialog-contour* "1"))
          (weldsym:draw-contour-tile "contour2" "2" (= *weldsym-dialog-contour* "2"))
          (weldsym:draw-contour-tile "contour3" "3" (= *weldsym-dialog-contour* "3"))
          (action_tile "side0" "(weldsym:set-side \"0\")")
          (action_tile "side1" "(weldsym:set-side \"1\")")
          (action_tile "side2" "(weldsym:set-side \"2\")")
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
                (cons 'othersize (get_tile \"othersize\"))
                (cons 'length (get_tile \"length\"))
                (cons 'pitch (get_tile \"pitch\"))
                (cons 'otherlength (get_tile \"otherlength\"))
                (cons 'otherpitch (get_tile \"otherpitch\"))
                (cons 'field (get_tile \"field\"))
                (cons 'allaround (get_tile \"allaround\"))
                (cons 'tailon (get_tile \"tailon\"))
                (cons 'process (get_tile \"process\"))
                (cons 'tailtext (get_tile \"tailtext\"))
                (cons 'tailtext2 (get_tile \"tailtext2\"))
                (cons 'contour *weldsym-dialog-contour*)
                (cons 'staggered *weldsym-type-preset-staggered*)
                (cons 'dir *weldsym-dialog-dir*)))
             (done_dialog 1)")
          (action_tile "cancel" "(done_dialog 0)")
          (setq result (start_dialog))
          (unload_dialog dcl)
          (if (= result 1) *weldsym-last* nil))))))




(defun weldsym:remember-current (landing ref-end u n)
  (setq *weldsym-current-landing* landing)
  (setq *weldsym-current-ref-end* ref-end)
  (setq *weldsym-current-u* u)
  (setq *weldsym-current-symbol-u* '(1.0 0.0 0.0))
  (setq *weldsym-current-tail-u* u)
  (setq *weldsym-current-n* n))

(defun weldsym:current-ready (/)
  (and *weldsym-current-landing* *weldsym-current-ref-end* *weldsym-current-symbol-u* *weldsym-current-tail-u* *weldsym-current-n*))

(defun weldsym:no-current-message (/)
  (princ "\nPlace a weld symbol first, then click this toolbar button."))
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

(defun weldsym:draw (arrow landing ref-end data / sign u pos-u draw-u n below above symbol side size othersize arrow-size other-size length pitch otherlength otherpitch arrow-length-pitch-text other-length-pitch-text length-text-offset symbol-offset arrow-text-offset other-text-offset contour dir staggered tail1 tail2 tail-text-offset tail1-y tail2-y)
  (setq n '(0.0 1.0 0.0))
  (setq symbol (weldsym:alist-get 'symbol data "0"))
  (setq side (weldsym:alist-get 'side data "0"))
  (setq size (weldsym:alist-get 'size data ""))
  (setq othersize (weldsym:alist-get 'othersize data ""))
  (setq arrow-size size)
  (setq other-size (if (/= othersize "") othersize size))
  (setq length (weldsym:alist-get 'length data ""))
  (setq pitch (weldsym:alist-get 'pitch data ""))
  (setq otherlength (weldsym:alist-get 'otherlength data ""))
  (setq otherpitch (weldsym:alist-get 'otherpitch data ""))
  (setq contour (weldsym:alist-get 'contour data "0"))
  (setq staggered (weldsym:alist-get 'staggered data "0"))
  (setq dir (weldsym:alist-get 'dir data "0"))
  (setq sign (if (= dir "1") -1.0 1.0))
  (setq u (list sign 0.0 0.0))
  (setq pos-u u)
  (setq draw-u '(1.0 0.0 0.0))
  (weldsym:remember-current landing ref-end u n)
  (setq tail1 (weldsym:tail-line1 data))
  (setq tail2 (weldsym:tail-line2 data))
  (setq tail-text-offset (if (/= tail2 "") (weldsym:s 6.5) (weldsym:s 4.333333)))
  (if (/= tail2 "")
    (progn
      (setq tail1-y (weldsym:s 3.0))
      (setq tail2-y (weldsym:s -3.0)))
    (progn
      (setq tail1-y 0.0)
      (setq tail2-y 0.0)))
  (weldsym:leader arrow landing)
  (weldsym:line landing ref-end)

  (if (= (weldsym:alist-get 'allaround data "0") "1")
    (weldsym:circle landing (weldsym:s 3.0)))

  (if (= (weldsym:alist-get 'field data "0") "1")
    (weldsym:draw-field-flag landing draw-u n))

  (if (= staggered "1")
    (progn
      (setq below (weldsym:add landing (weldsym:mul pos-u (weldsym:s 12.0))))
      (setq above (weldsym:add landing (weldsym:mul pos-u (weldsym:s 15.5)))))
    (progn
      (setq symbol-offset (cond ((and (= dir "1") (or (/= length "") (/= pitch "") (/= otherlength "") (/= otherpitch ""))) (weldsym:s 21.333333)) ((= dir "1") (weldsym:s 16.0)) (T (weldsym:s 12.0))))
      (setq below (weldsym:add landing (weldsym:mul pos-u symbol-offset)))
      (setq above (weldsym:add landing (weldsym:mul pos-u symbol-offset)))))

  (if (or (= side "0") (= side "2"))
    (progn
      (weldsym:draw-symbol below draw-u (weldsym:mul n -1.0) symbol)
      (weldsym:draw-contour (weldsym:add below (weldsym:add (weldsym:mul draw-u (weldsym:s 17.0)) (weldsym:mul n (weldsym:s -5.5)))) draw-u (weldsym:mul n -1.0) contour)))

  (if (or (= side "1") (= side "2"))
    (progn
      (weldsym:draw-symbol above draw-u n symbol)
      (weldsym:draw-contour (weldsym:add above (weldsym:add (weldsym:mul draw-u (weldsym:s 17.0)) (weldsym:mul n (weldsym:s 5.5)))) draw-u n contour)))

  (setq arrow-text-offset (if (= staggered "1") (weldsym:s 8.333333) nil))
  (setq other-text-offset (if (= staggered "1") (weldsym:s 8.333333) nil))
  (if (or (= side "0") (= side "2"))
    (if (= staggered "1")
      (weldsym:text-right (weldsym:add landing (weldsym:add (weldsym:mul u arrow-text-offset) (weldsym:mul n (weldsym:s -7.0)))) arrow-size (weldsym:s 4.0))
      (weldsym:text-right (weldsym:add below (weldsym:add (weldsym:mul draw-u (weldsym:s -3.833333)) (weldsym:mul n (weldsym:s -7.0)))) arrow-size (weldsym:s 4.0))))
  (if (or (= side "1") (= side "2"))
    (if (= staggered "1")
      (weldsym:text-right (weldsym:add landing (weldsym:add (weldsym:mul u other-text-offset) (weldsym:mul n (weldsym:s 4.0)))) other-size (weldsym:s 4.0))
      (weldsym:text-right (weldsym:add above (weldsym:add (weldsym:mul draw-u (weldsym:s -3.833333)) (weldsym:mul n (weldsym:s 4.0)))) other-size (weldsym:s 4.0))))
  (setq arrow-length-pitch-text
    (cond
      ((and (/= length "") (/= pitch "")) (strcat length "-" pitch))
      ((/= length "") length)
      (T pitch)))
  (setq other-length-pitch-text
    (cond
      ((and (/= otherlength "") (/= otherpitch "")) (strcat otherlength "-" otherpitch))
      ((/= otherlength "") otherlength)
      (T otherpitch)))
  (setq length-text-offset (if (= staggered "1") (weldsym:s 22.5) (if (= dir "0") (weldsym:s 19.0) (- symbol-offset (weldsym:s 7.0)))))
  (if (and (or (= side "0") (= side "2")) (/= arrow-length-pitch-text ""))
    (weldsym:text (weldsym:add landing (weldsym:add (weldsym:mul u length-text-offset) (weldsym:mul n (weldsym:s -7.0)))) arrow-length-pitch-text (weldsym:s 4.0)))
  (if (and (or (= side "1") (= side "2")) (/= other-length-pitch-text ""))
    (weldsym:text (weldsym:add landing (weldsym:add (weldsym:mul u length-text-offset) (weldsym:mul n (weldsym:s 4.0)))) other-length-pitch-text (weldsym:s 4.0)))
  (if (or (= (weldsym:alist-get 'tailon data "0") "1") (/= tail1 "") (/= tail2 ""))
    (progn
      (weldsym:draw-tail-fork ref-end u n)
      (weldsym:tail-text-entity (weldsym:add ref-end (weldsym:add (weldsym:mul u tail-text-offset) (weldsym:mul n tail1-y))) tail1 (weldsym:s 4.0) u)
      (weldsym:tail-text-entity (weldsym:add ref-end (weldsym:add (weldsym:mul u tail-text-offset) (weldsym:mul n tail2-y))) tail2 (weldsym:s 4.0) u))))

(defun weldsym:run (preset-dir / arrow landing refpick ref-end data dist sign used-default has-length-pitch)
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
              (setq refpick (getpoint landing "\nSpecify reference line end point <168>: "))
              (setq sign (if (= *weldsym-dialog-dir* "1") -1.0 1.0))
              (if refpick
                (progn
                  (setq used-default nil)
                  (setq dist (abs (- (car refpick) (car landing))))
                  (if (< dist 1.0) (setq dist (distance landing refpick))))
                (progn
                  (setq used-default T)
                  (setq dist (weldsym:s 28.0))))
              (setq *weldsym-dialog-symbol* (weldsym:show-type))
              (if *weldsym-dialog-symbol*
                (progn
                  (setq data (weldsym:show-options))
                  (if data
                    (progn
                      (setq has-length-pitch
                        (or
                          (/= (weldsym:alist-get 'length data "") "")
                          (/= (weldsym:alist-get 'pitch data "") "")
                          (/= (weldsym:alist-get 'otherlength data "") "")
                          (/= (weldsym:alist-get 'otherpitch data "") "")))
                      (if used-default
                        (cond
                          ((= (weldsym:alist-get 'staggered data "0") "1")
                            (setq dist (weldsym:s 37.5)))
                          (has-length-pitch
                            (setq dist (weldsym:s 33.333333)))))
                      (setq ref-end (weldsym:add landing (weldsym:mul (list sign 0.0 0.0) dist)))
                      (weldsym:draw arrow landing ref-end data)
                      (princ "\nWeld symbol created."))
                    (princ "\nWeld options cancelled.")))
                (princ "\nWeld type cancelled.")))))))))
(defun c:WELDSYM (/ oldcmdecho)
  (setq oldcmdecho (getvar "CMDECHO"))
  (setvar "CMDECHO" 0)
  (weldsym:ensure-layer "2" 7)
  (weldsym:ensure-layer "1" 7)
  (weldsym:run nil)
  (setvar "CMDECHO" oldcmdecho)
  (princ))

(defun c:WELDRIGHT (/ oldcmdecho)
  (setq oldcmdecho (getvar "CMDECHO"))
  (setvar "CMDECHO" 0)
  (weldsym:ensure-layer "2" 7)
  (weldsym:ensure-layer "1" 7)
  (weldsym:run "0")
  (setvar "CMDECHO" oldcmdecho)
  (princ))

(defun c:WELDLEFT (/ oldcmdecho)
  (setq oldcmdecho (getvar "CMDECHO"))
  (setvar "CMDECHO" 0)
  (weldsym:ensure-layer "2" 7)
  (weldsym:ensure-layer "1" 7)
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

(defun c:WELDFIELD ()
  (if (weldsym:current-ready)
    (progn
      (weldsym:draw-field-flag *weldsym-current-landing* *weldsym-current-symbol-u* *weldsym-current-n*)
      (princ "\nField weld symbol added to latest weld."))
    (weldsym:no-current-message))
  (princ))
(defun c:WELDALLAROUND ()
  (if (weldsym:current-ready)
    (progn
      (weldsym:circle *weldsym-current-landing* (weldsym:s 3.0))
      (princ "\nAll-around symbol added to latest weld."))
    (weldsym:no-current-message))
  (princ))
(defun c:WELDTAIL ()
  (if (weldsym:current-ready)
    (progn
      (weldsym:draw-tail-fork *weldsym-current-ref-end* *weldsym-current-tail-u* *weldsym-current-n*)
      (princ "\nTail symbol added to latest weld."))
    (weldsym:no-current-message))
  (princ))

(defun weldsym:draw-current-tail-text (line1 line2 / tail-text-offset tail1-y tail2-y)
  (weldsym:ensure-layer "2" 7)
  (weldsym:ensure-layer "1" 7)
  (weldsym:ensure-text-style)
  (weldsym:draw-tail-fork *weldsym-current-ref-end* *weldsym-current-tail-u* *weldsym-current-n*)
  (setq tail-text-offset (if (and line2 (/= line2 "")) (weldsym:s 6.5) (weldsym:s 4.333333)))
  (if (and line2 (/= line2 ""))
    (progn
      (setq tail1-y (weldsym:s 3.0))
      (setq tail2-y (weldsym:s -3.0)))
    (progn
      (setq tail1-y 0.0)
      (setq tail2-y 0.0)))
  (weldsym:tail-text-entity
    (weldsym:add *weldsym-current-ref-end* (weldsym:add (weldsym:mul *weldsym-current-tail-u* tail-text-offset) (weldsym:mul *weldsym-current-n* tail1-y)))
    line1
    (weldsym:s 4.0)
    *weldsym-current-tail-u*)
  (weldsym:tail-text-entity
    (weldsym:add *weldsym-current-ref-end* (weldsym:add (weldsym:mul *weldsym-current-tail-u* tail-text-offset) (weldsym:mul *weldsym-current-n* tail2-y)))
    line2
    (weldsym:s 4.0)
    *weldsym-current-tail-u*))

(defun c:WELDTAIL1 (/ text1)
  (if (weldsym:current-ready)
    (progn
      (setq text1 (getstring T "\nTail text: "))
      (if (and text1 (/= text1 ""))
        (progn
          (weldsym:draw-current-tail-text text1 "")
          (princ "\nOne-line tail text added to latest weld."))
        (princ "\nTail text cancelled.")))
    (weldsym:no-current-message))
  (princ))

(defun c:WELDTAIL2 (/ text1 text2)
  (if (weldsym:current-ready)
    (progn
      (setq text1 (getstring T "\nTail text line 1: "))
      (if (and text1 (/= text1 ""))
        (progn
          (setq text2 (getstring T "\nTail text line 2: "))
          (if (and text2 (/= text2 ""))
            (progn
              (weldsym:draw-current-tail-text text1 text2)
              (princ "\nTwo-line tail text added to latest weld."))
            (princ "\nSecond tail line cancelled.")))
        (princ "\nTail text cancelled.")))
    (weldsym:no-current-message))
  (princ))
(defun c:WELDTAILONE ()
  (c:WELDTAIL1))

(defun c:WELDTAILTWO ()
  (c:WELDTAIL2))
(defun weldsym:support-file (name / found base appdata path)
  (setq found (findfile name))
  (if found
    (vl-string-translate "/" "\\" found)
    (progn
      (setq found (or (findfile "weldsym_safe.lsp") (findfile "weldsym_tailcenter.lsp") (findfile "weldsym_cmd.lsp") (findfile "weldsym.lsp")))
      (setq base (if found (vl-filename-directory found) nil))
      (if (not base)
        (progn
          (setq appdata (getenv "APPDATA"))
          (if appdata
            (setq base (strcat appdata "\\Autodesk\\AutoCAD 2027\\R26.0\\enu\\Support")))))
      (if base
        (vl-string-translate "/" "\\" (strcat base "\\" name))
        name))))

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

(defun weldsym:delete-toolbar (toolbars toolbar-name / tb)
  (setq tb (weldsym:get-toolbar toolbars toolbar-name))
  (if tb
    (progn
      (vl-catch-all-apply 'vla-put-Visible (list tb :vlax-false))
      (vl-catch-all-apply 'vla-Delete (list tb)))))

(defun weldsym:ensure-toolbar (/ group toolbars tb)
  (setq group (weldsym:get-menugroup "ACAD"))
  (setq toolbars (vla-get-Toolbars group))
  (weldsym:delete-toolbar toolbars "WELDSYM_FIXED")
  (weldsym:delete-toolbar toolbars "WELDSYM_TEXT")
  (weldsym:delete-toolbar toolbars "WELDSYM")
  (setq tb (vla-Add toolbars "WELDSYM"))
  (weldsym:add-toolbar-button tb 0 "Weld Right" "Start weld callout to the right" "WELDRIGHT " "weldright16.bmp" "weldright32.bmp")
  (weldsym:add-toolbar-button tb 1 "Weld Left" "Start weld callout to the left" "WELDLEFT " "weldleft16.bmp" "weldleft32.bmp")
  (weldsym:add-toolbar-button tb 2 "Field" "Add field weld flag to the latest weld" "WELDFIELD " "weldfield16.bmp" "weldfield32.bmp")
  (weldsym:add-toolbar-button tb 3 "All Around" "Add weld-all-around circle to the latest weld" "WELDALLAROUND " "weldaround16.bmp" "weldaround32.bmp")
  (weldsym:add-toolbar-button tb 4 "Tail" "Add tail fork to the latest weld" "WELDTAIL " "weldtail16.bmp" "weldtail32.bmp")
  (weldsym:add-toolbar-button tb 5 "1 LINE" "Add one line of tail text to the latest weld" "WELDTAILONE " "weldtail1-16.bmp" "weldtail1-32.bmp")
  (weldsym:add-toolbar-button tb 6 "2 LINES" "Add two lines of tail text to the latest weld" "WELDTAILTWO " "weldtail2-16.bmp" "weldtail2-32.bmp")
  (vla-put-Visible tb :vlax-true)
  (vl-catch-all-apply 'vla-Dock (list tb 3))
  tb)

(defun c:WELDTOOLBAR ()
  (weldsym:ensure-toolbar)
  (princ "\nWELDSYM toolbar reset and visible.")
  (princ))

(vl-catch-all-apply 'weldsym:ensure-toolbar '())
(princ "\nWELDSYM loaded. Run WELDSYM to place a weld symbol.")
(princ)













































































