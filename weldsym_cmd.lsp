;;; WELDSYM - AutoLISP weld symbol command with visual DCL toolbox.
;;; Load with APPLOAD, then run WELDSYM.

(vl-load-com)

(setq *weldsym-symbols* '("Fillet" "Groove Bevel Welds" "Groove V Weld" "U-Groove Weld" "Square Groove Weld" "Flare V Groove Weld" "Flare Bevel Weld"))
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
(setq *weldsym-current-line-layer* nil)
(setq *weldsym-line-layer* nil)
(setq *weldsym-block-ents* nil)
(setq *weldsym-collect-block* nil)
(setq *weldsym-block-counter* 0)
(setq *weldsym-block-prefix* "WELDSYM")
(setq *weldsym-attr-counter* 0)
(setq *weldsym-block-attr-values* nil)

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

(defun weldsym:alist-get-nonblank (key data fallback / value)
  (setq value (weldsym:alist-get key data fallback))
  (if (or (not value) (= value "")) fallback value))

(defun weldsym:add (p q)
  (mapcar '+ p q))

(defun weldsym:mul (p n)
  (mapcar '(lambda (v) (* v n)) p))

(defun weldsym:s (value)
  (* value *weldsym-scale*))

(defun weldsym:text-height ()
  18.0)

(defun weldsym:record-entity (ename)
  (if (and ename *weldsym-collect-block*)
    (setq *weldsym-block-ents* (cons ename *weldsym-block-ents*)))
  ename)

(defun weldsym:arrow-size ()
  28.0)

(defun weldsym:leader-dimasz (/ dimscale)
  (setq dimscale (getvar "DIMSCALE"))
  (if (or (not dimscale) (<= dimscale 0.0))
    (weldsym:arrow-size)
    (/ (weldsym:arrow-size) dimscale)))

(defun weldsym:line-layer (/ layer)
  (setq layer *weldsym-line-layer*)
  (if (and layer (/= layer ""))
    layer
    (getvar "CLAYER")))

(defun weldsym:entity-bylayer-props (/)
  (list
    (cons 8 (weldsym:line-layer))
    '(62 . 256)
    '(6 . "BYLAYER")
    '(370 . -1)))

(defun weldsym:solid-triangle (p1 p2 p3)
  (weldsym:record-entity
    (entmakex
      (append
        (list '(0 . "SOLID"))
        (weldsym:entity-bylayer-props)
        (list
          (cons 10 p1)
          (cons 11 p2)
          (cons 12 p3)
          (cons 13 p3))))))
(defun weldsym:line (p q)
  (weldsym:record-entity
    (entmakex
      (append
        (list '(0 . "LINE"))
        (weldsym:entity-bylayer-props)
        (list (cons 10 p) (cons 11 q))))))

(defun weldsym:circle (center radius)
  (weldsym:record-entity
    (entmakex
      (append
        (list '(0 . "CIRCLE"))
        (weldsym:entity-bylayer-props)
        (list (cons 10 center) (cons 40 radius))))))

(defun weldsym:arc (center radius start end)
  (weldsym:record-entity
    (entmakex
      (append
        (list '(0 . "ARC"))
        (weldsym:entity-bylayer-props)
        (list (cons 10 center) (cons 40 radius) (cons 50 start) (cons 51 end))))))

(defun weldsym:text-entity (pt value height hjust vjust tagbase / tag)
  (if (and value (/= value ""))
    (if *weldsym-collect-block*
      (progn
        (setq *weldsym-attr-counter* (+ *weldsym-attr-counter* 1))
        (setq tag (strcat tagbase (itoa *weldsym-attr-counter*)))
        (weldsym:record-entity
          (entmakex
            (list
              '(0 . "ATTDEF")
              '(100 . "AcDbEntity")
              '(8 . "1")
              '(62 . 256)
              '(6 . "BYLAYER")
              '(370 . -1)
              '(100 . "AcDbText")
              (cons 10 pt)
              (cons 11 pt)
              (cons 40 height)
              (cons 1 value)
              '(7 . "4")
              '(41 . 1.0)
              '(50 . 0.0)
              '(51 . 0.0)
              (cons 72 hjust)
              '(100 . "AcDbAttributeDefinition")
              '(70 . 0)
              '(280 . 0)
              (cons 3 tag)
              (cons 2 tag)
              (cons 74 vjust)))))
      (weldsym:record-entity
        (entmakex
          (list
            '(0 . "TEXT")
            '(8 . "1")
            '(62 . 256)
            '(6 . "BYLAYER")
            '(370 . -1)
            (cons 10 pt)
            (cons 11 pt)
            (cons 40 height)
            (cons 1 value)
            '(7 . "4")
            '(41 . 1.0)
            '(50 . 0.0)
            '(51 . 0.0)
            (cons 72 hjust)
            (cons 73 vjust)))))))

(defun weldsym:text (pt value height /)
  (weldsym:text-entity pt value height 0 0 "WELD"))

(defun weldsym:text-center (pt value height /)
  (weldsym:text-entity pt value height 1 0 "ROOT"))

(defun weldsym:text-right (pt value height /)
  (weldsym:text-entity pt value height 2 0 "SIZE"))

(defun weldsym:text-middle-left (pt value height /)
  (weldsym:text-entity pt value height 0 2 "TAIL"))
(defun weldsym:text-middle-right (pt value height /)
  (weldsym:text-entity pt value height 2 2 "TAIL"))

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

(defun weldsym:arrow (tip tail / dir back left right length half-width)
  (setq dir (angle tail tip))
  (setq length 15.0)
  (setq half-width 5.5)
  (setq back (polar tip (+ dir pi) length))
  (setq left (polar back (+ dir (/ pi 2.0)) half-width))
  (setq right (polar back (- dir (/ pi 2.0)) half-width))
  (weldsym:line tip left)
  (weldsym:line tip right))

(defun weldsym:leader (arrow landing / oldcmd oldortho olddimasz olddimclrd olddimclre olddimclrt olddimlwd olddimlwe oldclayer oldcecolor oldceltype oldcelweight result)
  (setq oldcmd (getvar "CMDECHO"))
  (setq oldortho (getvar "ORTHOMODE"))
  (setq olddimasz (getvar "DIMASZ"))
  (setq olddimclrd (getvar "DIMCLRD"))
  (setq olddimclre (getvar "DIMCLRE"))
  (setq olddimclrt (getvar "DIMCLRT"))
  (setq olddimlwd (getvar "DIMLWD"))
  (setq olddimlwe (getvar "DIMLWE"))
  (setq oldclayer (getvar "CLAYER"))
  (setq oldcecolor (getvar "CECOLOR"))
  (setq oldceltype (getvar "CELTYPE"))
  (setq oldcelweight (getvar "CELWEIGHT"))
  (setvar "CMDECHO" 0)
  (setvar "ORTHOMODE" 0)
  (setvar "DIMASZ" (weldsym:leader-dimasz))
  (setvar "DIMCLRD" 256)
  (setvar "DIMCLRE" 256)
  (setvar "DIMCLRT" 256)
  (setvar "DIMLWD" -1)
  (setvar "DIMLWE" -1)
  (setvar "CLAYER" (weldsym:line-layer))
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
  (setvar "DIMCLRT" olddimclrt)
  (setvar "DIMCLRE" olddimclre)
  (setvar "DIMCLRD" olddimclrd)
  (setvar "DIMLWE" olddimlwe)
  (setvar "DIMLWD" olddimlwd)
  (setvar "DIMASZ" olddimasz)
  (setvar "CMDECHO" oldcmd)
  (if (vl-catch-all-error-p result)
    (progn
      (weldsym:line arrow landing)
      (weldsym:arrow arrow landing)))
  result)

(defun weldsym:leader-path (points / oldcmd oldortho olddimclrd olddimclre olddimclrt olddimlwd olddimlwe oldclayer oldcecolor oldceltype oldcelweight args result p q)
  (if (and points (cadr points))
    (progn
      (setq oldcmd (getvar "CMDECHO"))
      (setq oldortho (getvar "ORTHOMODE"))
      (setq olddimclrd (getvar "DIMCLRD"))
      (setq olddimclre (getvar "DIMCLRE"))
      (setq olddimclrt (getvar "DIMCLRT"))
      (setq olddimlwd (getvar "DIMLWD"))
      (setq olddimlwe (getvar "DIMLWE"))
      (setq oldclayer (getvar "CLAYER"))
      (setq oldcecolor (getvar "CECOLOR"))
      (setq oldceltype (getvar "CELTYPE"))
      (setq oldcelweight (getvar "CELWEIGHT"))
      (setvar "CMDECHO" 0)
      (setvar "ORTHOMODE" 0)
      (setvar "DIMCLRD" 256)
      (setvar "DIMCLRE" 256)
      (setvar "DIMCLRT" 256)
      (setvar "DIMLWD" -1)
      (setvar "DIMLWE" -1)
      (setvar "CLAYER" (weldsym:line-layer))
      (setvar "CECOLOR" "BYLAYER")
      (setvar "CELTYPE" "BYLAYER")
      (setvar "CELWEIGHT" -1)
      (setq args (append (list "_.LEADER") points (list "" "" "N")))
      (setq result (vl-catch-all-apply 'command-s args))
      (setvar "CELWEIGHT" oldcelweight)
      (setvar "CELTYPE" oldceltype)
      (setvar "CECOLOR" oldcecolor)
      (setvar "CLAYER" oldclayer)
      (setvar "ORTHOMODE" oldortho)
      (setvar "DIMCLRT" olddimclrt)
      (setvar "DIMCLRE" olddimclre)
      (setvar "DIMCLRD" olddimclrd)
      (setvar "DIMLWE" olddimlwe)
      (setvar "DIMLWD" olddimlwd)
      (setvar "CMDECHO" oldcmd)
      (if (vl-catch-all-error-p result)
        (progn
          (setq p (car points))
          (foreach q (cdr points)
          (weldsym:line p q)
          (setq p q))
          (weldsym:arrow (car points) (cadr points)))))))

(defun weldsym:block-collected (base / oldcmd oldattreq oldattdia oldcmddia ss name result insert-result e)
  (if *weldsym-block-ents*
    (progn
      (setq ss (ssadd))
      (foreach e (reverse *weldsym-block-ents*)
        (if (and e (entget e)) (ssadd e ss)))
      (if (> (sslength ss) 0)
        (progn
          (setq *weldsym-block-counter* (+ *weldsym-block-counter* 1))
          (setq name (strcat *weldsym-block-prefix* "_" (rtos (getvar "CDATE") 2 8) "_" (itoa *weldsym-block-counter*)))
          (setq oldcmd (getvar "CMDECHO"))
          (setq oldattreq (getvar "ATTREQ"))
          (setq oldattdia (getvar "ATTDIA"))
          (setq oldcmddia (getvar "CMDDIA"))
          (setvar "CMDECHO" 0)
          (setvar "ATTREQ" 0)
          (setvar "ATTDIA" 0)
          (setvar "CMDDIA" 0)
          (setq result (vl-catch-all-apply 'command-s (list "_.-BLOCK" name base ss "")))
          (if (not (vl-catch-all-error-p result))
            (setq insert-result (vl-catch-all-apply 'command-s (list "_.-INSERT" name base 1.0 1.0 0.0))))
          (setvar "CMDDIA" oldcmddia)
          (setvar "ATTDIA" oldattdia)
          (setvar "ATTREQ" oldattreq)
          (setvar "CMDECHO" oldcmd)
          (setq *weldsym-block-attr-values* nil)
          insert-result)))))
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
      (weldsym:circle c (/ h 2.0)))
    ((= symbol "6")
      (setq h (weldsym:s 5.833333))
      (setq p1 (weldsym:add base (weldsym:mul u h)))
      (setq p3 (weldsym:add base (weldsym:mul n h)))
      (weldsym:line base p3)
      (weldsym:line base (weldsym:add p1 (weldsym:mul n h))))
    ((= symbol "7")
      (setq h (weldsym:s 5.833333))
      (weldsym:line
        (weldsym:add base (weldsym:add (weldsym:mul u (- h)) (weldsym:mul n (- h))))
        (weldsym:add base (weldsym:add (weldsym:mul u h) (weldsym:mul n h))))
      (weldsym:line
        (weldsym:add base (weldsym:add (weldsym:mul u (- h)) (weldsym:mul n h)))
        (weldsym:add base (weldsym:add (weldsym:mul u h) (weldsym:mul n (- h))))))))

(defun weldsym:draw-groove-symbol (base u n side / h)
  (setq h (weldsym:s 5.833333))
  (cond
    ((= side "0")
      (weldsym:line base (weldsym:add base (weldsym:add (weldsym:mul u (- h)) (weldsym:mul n (- h)))))
      (weldsym:line base (weldsym:add base (weldsym:add (weldsym:mul u h) (weldsym:mul n (- h))))))
    ((= side "1")
      (weldsym:line base (weldsym:add base (weldsym:add (weldsym:mul u (- h)) (weldsym:mul n h))))
      (weldsym:line base (weldsym:add base (weldsym:add (weldsym:mul u h) (weldsym:mul n h)))))
    (T
      (weldsym:draw-symbol base u n "7"))))

(defun weldsym:draw-u-groove-symbol (base u n side / h r stem c arc-mid)
  (setq h (weldsym:s 5.833333))
  (setq r (* h 0.55))
  (setq stem (* h 0.45))
  (cond
    ((= side "0")
      (setq c (weldsym:add base (weldsym:mul n (- (+ stem r)))))
      (setq arc-mid (weldsym:add c (weldsym:mul n r)))
      (weldsym:line base arc-mid)
      (weldsym:arc c r 0.0 pi))
    ((= side "1")
      (setq c (weldsym:add base (weldsym:mul n (+ stem r))))
      (setq arc-mid (weldsym:add c (weldsym:mul n (- r))))
      (weldsym:line base arc-mid)
      (weldsym:arc c r pi (* 2.0 pi)))
    (T
      (weldsym:draw-u-groove-symbol base u n "0")
      (weldsym:draw-u-groove-symbol base u n "1"))))

(defun weldsym:draw-square-groove-symbol (base u n side / h gap p2)
  (setq h (weldsym:s 8.333333))
  (setq gap (weldsym:s 5.0))
  (setq p2 (weldsym:add base (weldsym:mul u gap)))
  (cond
    ((= side "0")
      (weldsym:line base (weldsym:add base (weldsym:mul n (- h))))
      (weldsym:line p2 (weldsym:add p2 (weldsym:mul n (- h)))))
    ((= side "1")
      (weldsym:line base (weldsym:add base (weldsym:mul n h)))
      (weldsym:line p2 (weldsym:add p2 (weldsym:mul n h))))
    (T
      (weldsym:line (weldsym:add base (weldsym:mul n (- h))) (weldsym:add base (weldsym:mul n h)))
      (weldsym:line (weldsym:add p2 (weldsym:mul n (- h))) (weldsym:add p2 (weldsym:mul n h))))))

(defun weldsym:draw-flare-v-groove-side (base u n side-dir / r half-gap left-center right-center)
  (setq r (weldsym:s 8.166667))
  (setq half-gap (weldsym:s 2.5))
  (setq left-center (weldsym:add base (weldsym:mul u (- (+ r half-gap)))))
  (setq right-center (weldsym:add base (weldsym:mul u (+ r half-gap))))
  (if (> side-dir 0.0)
    (progn
      (weldsym:arc left-center r 0.0 (/ pi 2.0))
      (weldsym:arc right-center r (/ pi 2.0) pi))
    (progn
      (weldsym:arc left-center r (* 1.5 pi) (* 2.0 pi))
      (weldsym:arc right-center r pi (* 1.5 pi)))))

(defun weldsym:draw-flare-v-groove-symbol (base u n side /)
  (cond
    ((= side "0") (weldsym:draw-flare-v-groove-side base u n -1.0))
    ((= side "1") (weldsym:draw-flare-v-groove-side base u n 1.0))
    (T
      (weldsym:draw-flare-v-groove-side base u n -1.0)
      (weldsym:draw-flare-v-groove-side base u n 1.0))))

(defun weldsym:draw-flare-bevel-groove-side (base u n side-dir / r gap c)
  (setq r (weldsym:s 8.166667))
  (setq gap (weldsym:s 2.5))
  (if (> side-dir 0.0)
    (progn
      (weldsym:line base (weldsym:add base (weldsym:mul n r)))
      (setq c (weldsym:add base (weldsym:mul u (+ gap r))))
      (weldsym:arc c r (/ pi 2.0) pi))
    (progn
      (weldsym:line base (weldsym:add base (weldsym:mul n (- r))))
      (setq c (weldsym:add base (weldsym:mul u (+ gap r))))
      (weldsym:arc c r pi (* 1.5 pi)))))

(defun weldsym:draw-flare-bevel-groove-symbol (base u n side /)
  (cond
    ((= side "0") (weldsym:draw-flare-bevel-groove-side base u n -1.0))
    ((= side "1") (weldsym:draw-flare-bevel-groove-side base u n 1.0))
    (T
      (weldsym:draw-flare-bevel-groove-side base u n -1.0)
      (weldsym:draw-flare-bevel-groove-side base u n 1.0))))

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

(defun weldsym:img-char (x y ch s color / x1 x2 x3 x4 y1 y2 y3 y4 y5)
  (setq x1 x)
  (setq x2 (+ x (* 2 s)))
  (setq x3 (+ x (* 4 s)))
  (setq x4 (+ x (* 6 s)))
  (setq y1 y)
  (setq y2 (+ y (* 2 s)))
  (setq y3 (+ y (* 4 s)))
  (setq y4 (+ y (* 6 s)))
  (setq y5 (+ y (* 8 s)))
  (cond
    ((= ch "w")
      (weldsym:img-line x1 y1 x2 y5 color)
      (weldsym:img-line x2 y5 x3 y3 color)
      (weldsym:img-line x3 y3 x4 y5 color)
      (weldsym:img-line x4 y5 (+ x4 (* 2 s)) y1 color))
    ((= ch "L")
      (weldsym:img-line x1 y1 x1 y5 color)
      (weldsym:img-line x1 y5 x4 y5 color))
    ((= ch "P")
      (weldsym:img-line x1 y1 x1 y5 color)
      (weldsym:img-line x1 y1 x4 y1 color)
      (weldsym:img-line x4 y1 x4 y3 color)
      (weldsym:img-line x4 y3 x1 y3 color))
    ((= ch "S")
      (weldsym:img-line x4 y1 x1 y1 color)
      (weldsym:img-line x1 y1 x1 y3 color)
      (weldsym:img-line x1 y3 x4 y3 color)
      (weldsym:img-line x4 y3 x4 y5 color)
      (weldsym:img-line x4 y5 x1 y5 color))
    ((= ch "E")
      (weldsym:img-line x1 y1 x1 y5 color)
      (weldsym:img-line x1 y1 x4 y1 color)
      (weldsym:img-line x1 y3 x3 y3 color)
      (weldsym:img-line x1 y5 x4 y5 color))
    ((= ch "R")
      (weldsym:img-line x1 y1 x1 y5 color)
      (weldsym:img-line x1 y1 x4 y1 color)
      (weldsym:img-line x4 y1 x4 y3 color)
      (weldsym:img-line x4 y3 x1 y3 color)
      (weldsym:img-line x1 y3 x4 y5 color))
    ((= ch "A")
      (weldsym:img-line x1 y5 x3 y1 color)
      (weldsym:img-line x3 y1 x4 y5 color)
      (weldsym:img-line x2 y3 x4 y3 color))
    ((= ch "1")
      (weldsym:img-line x2 y2 x3 y1 color)
      (weldsym:img-line x3 y1 x3 y5 color)
      (weldsym:img-line x1 y5 x4 y5 color))
    ((= ch "2")
      (weldsym:img-line x1 y1 x4 y1 color)
      (weldsym:img-line x4 y1 x4 y3 color)
      (weldsym:img-line x4 y3 x1 y5 color)
      (weldsym:img-line x1 y5 x4 y5 color))
    ((= ch "-")
      (weldsym:img-line x1 y3 x4 y3 color))
    ((= ch "(")
      (weldsym:img-line x3 y1 x1 y3 color)
      (weldsym:img-line x1 y3 x3 y5 color))
    ((= ch ")")
      (weldsym:img-line x1 y1 x3 y3 color)
      (weldsym:img-line x3 y3 x1 y5 color))
    ((= ch "*")
      (weldsym:img-circle x2 y1 (* 1.2 s) color))))

(defun weldsym:img-label (x y text size color / i ch)
  (setq i 1)
  (while (<= i (strlen text))
    (setq ch (substr text i 1))
    (if (/= ch " ")
      (weldsym:img-char x y ch size color))
    (setq x (+ x (* 7 size)))
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
(defun weldsym:draw-fillet-preset-tile (key side has-length / w h y xleg xtip ytop ybot lenx)
  (start_image key)
  (setq w (dimx_tile key))
  (setq h (dimy_tile key))
  (fill_image 0 0 w h 0)
  (weldsym:img-box w h 8)
  (setq y (/ h 2))
  (setq xleg (max 28 (/ w 3)))
  (setq ytop (max 5 (- y 20)))
  (setq ybot (min (- h 7) (+ y 20)))
  (setq xtip (+ xleg 18))
  (weldsym:img-line 5 y (- w 5) y 2)
  (if (or (= side "1") (= side "2"))
    (progn
      (weldsym:img-line xleg y xleg ytop 2)
      (weldsym:img-line xleg ytop xtip y 2)
      (weldsym:img-label (max 5 (- xleg 28)) (- ytop 10) "w2" 1.0 1)))
  (if (or (= side "0") (= side "2"))
    (progn
      (weldsym:img-line xleg y xleg ybot 2)
      (weldsym:img-line xleg ybot xtip y 2)
      (weldsym:img-label (max 5 (- xleg 28)) (+ ybot 4) "w1" 1.0 1)))
  (if (= has-length "1")
    (progn
      (setq lenx (+ xtip 18))
      (weldsym:img-line lenx (- y 10) lenx (+ y 10) 3)
      (if (or (= side "1") (= side "2"))
        (weldsym:img-label (+ xtip 8) (- y 18) "L2-P2" 0.8 1))
      (if (or (= side "0") (= side "2"))
        (weldsym:img-label (+ xtip 8) (+ y 8) "L1-P1" 0.8 1))))
  (end_image))

(defun weldsym:draw-staggered-preset-tile (key has-length / w h y xleg1 xleg2 xtip1 xtip2 ytop ybot lenx)
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
  (weldsym:img-label (max 5 (- xleg1 28)) (- ytop 10) "w2" 1.0 1)
  (weldsym:img-label (max 5 (- xleg2 28)) (+ ybot 4) "w1" 1.0 1)
  (if (= has-length "1")
    (progn
      (setq lenx (- w 24))
      (weldsym:img-line lenx (- y 11) lenx (+ y 11) 3)
      (weldsym:img-label (+ xleg2 20) (- y 18) "L2-P2" 0.75 1)
      (weldsym:img-label (+ xleg2 20) (+ y 8) "L1-P1" 0.75 1)
      (weldsym:img-label (- xleg1 4) (- h 13) "A2*" 0.8 1)))
  (end_image))

(defun weldsym:draw-bevel-preset-tile (key side / w h y x0 x1 ytop ybot)
  (start_image key)
  (setq w (dimx_tile key))
  (setq h (dimy_tile key))
  (fill_image 0 0 w h 0)
  (weldsym:img-box w h 8)
  (setq y (/ h 2))
  (setq x0 (max 32 (/ w 2)))
  (setq x1 (+ x0 18))
  (setq ytop (max 4 (- y 18)))
  (setq ybot (min (- h 4) (+ y 18)))
  (weldsym:img-line 2 y (- w 2) y 2)
  (if (or (= side "0") (= side "2"))
    (progn
      (weldsym:img-line x0 y x0 ybot 2)
      (weldsym:img-line x0 y x1 ybot 2)))
  (if (or (= side "1") (= side "2"))
    (progn
      (weldsym:img-line x0 y x0 ytop 2)
      (weldsym:img-line x0 y x1 ytop 2)))
  (if (or (= side "0") (= side "2"))
    (progn
      (weldsym:img-label (max 4 (- x0 44)) (+ y 8) "S1(E1)" 0.7 1)
      (weldsym:img-label (+ x1 4) (+ y 8) "R1" 0.8 1)
      (weldsym:img-label (max 5 (- x0 3)) (- h 13) "A1*" 0.8 1)))
  (if (or (= side "1") (= side "2"))
    (progn
      (weldsym:img-label (max 4 (- x0 44)) (- y 18) "S2(E2)" 0.7 1)
      (weldsym:img-label (+ x1 4) (- y 18) "R2" 0.8 1)
      (if (= side "1")
        (weldsym:img-label (max 5 (- x0 3)) (+ y 8) "A2*" 0.8 1))))
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
  (weldsym:draw-side-tile "side2" "2" (= *weldsym-dialog-side* "2")))

(defun weldsym:draw-contour-toolbox (/)
  (weldsym:draw-contour-tile "contour0" "0" (= *weldsym-dialog-contour* "0"))
  (weldsym:draw-contour-tile "contour1" "1" (= *weldsym-dialog-contour* "1"))
  (weldsym:draw-contour-tile "contour2" "2" (= *weldsym-dialog-contour* "2"))
  (weldsym:draw-contour-tile "contour3" "3" (= *weldsym-dialog-contour* "3")))

(defun weldsym:set-symbol (value)
  (setq *weldsym-dialog-symbol* value)
  (weldsym:draw-toolbox))

(defun weldsym:set-side (value)
  (setq *weldsym-dialog-side* value)
  (weldsym:draw-toolbox))

(defun weldsym:set-type-preset (side has-length staggered symbol)
  (setq *weldsym-dialog-symbol* symbol)
  (setq *weldsym-type-preset-side* side)
  (setq *weldsym-type-preset-length* has-length)
  (setq *weldsym-type-preset-staggered* staggered)
  (setq *weldsym-dialog-side* side)
  (done_dialog 1))
(defun weldsym:set-contour (value)
  (setq *weldsym-dialog-contour* value)
  (weldsym:draw-toolbox))

(defun weldsym:set-bevel-contour (value)
  (setq *weldsym-dialog-contour* value)
  (weldsym:draw-contour-toolbox))

(defun weldsym:apply-bevel-side-modes (/ side arrow-mode other-mode)
  (setq side (if *weldsym-type-preset-side* *weldsym-type-preset-side* *weldsym-dialog-side*))
  (setq arrow-mode (if (or (= side "0") (= side "2")) 0 1))
  (setq other-mode (if (or (= side "1") (= side "2")) 0 1))
  (mode_tile "beveldepth" arrow-mode)
  (mode_tile "bevelsize" arrow-mode)
  (mode_tile "bevelroot" arrow-mode)
  (mode_tile "bevelangle" arrow-mode)
  (mode_tile "otherbeveldepth" other-mode)
  (mode_tile "otherbevelsize" other-mode)
  (mode_tile "otherbevelroot" other-mode)
  (mode_tile "otherbevelangle" other-mode))

(defun weldsym:apply-groove-side-modes (/ side arrow-mode other-mode)
  (setq side (if *weldsym-type-preset-side* *weldsym-type-preset-side* *weldsym-dialog-side*))
  (setq arrow-mode (if (or (= side "0") (= side "2")) 0 1))
  (setq other-mode (if (or (= side "1") (= side "2")) 0 1))
  (mode_tile "groovedepth" arrow-mode)
  (mode_tile "groovesize" arrow-mode)
  (mode_tile "grooveroot" arrow-mode)
  (mode_tile "grooveangle" arrow-mode)
  (mode_tile "othergroovedepth" other-mode)
  (mode_tile "othergroovesize" other-mode)
  (mode_tile "othergrooveroot" other-mode)
  (mode_tile "othergrooveangle" other-mode)
  (if (or (= *weldsym-dialog-symbol* "9") (= *weldsym-dialog-symbol* "10") (= *weldsym-dialog-symbol* "11"))
    (progn
      (if (or (= *weldsym-dialog-symbol* "10") (= *weldsym-dialog-symbol* "11"))
        (progn
          (set_tile "grooveroot" "")
          (set_tile "othergrooveroot" "")
          (mode_tile "grooveroot" 1)
          (mode_tile "othergrooveroot" 1)))
      (set_tile "grooveangle" "")
      (set_tile "othergrooveangle" "")
      (mode_tile "grooveangle" 1)
      (mode_tile "othergrooveangle" 1))))

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

(defun weldsym:show-type-dcl (/ dcl file result)
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
          (weldsym:draw-bevel-preset-tile "type_bevel_arrow" "0")
          (weldsym:draw-bevel-preset-tile "type_bevel_other" "1")
          (weldsym:draw-bevel-preset-tile "type_bevel_both" "2")
          (weldsym:draw-bevel-preset-tile "type_ugroove_arrow" "0")
          (weldsym:draw-bevel-preset-tile "type_ugroove_other" "1")
          (weldsym:draw-bevel-preset-tile "type_ugroove_both" "2")
          (weldsym:draw-bevel-preset-tile "type_square_groove_arrow" "0")
          (weldsym:draw-bevel-preset-tile "type_square_groove_other" "1")
          (weldsym:draw-bevel-preset-tile "type_square_groove_both" "2")
          (weldsym:draw-bevel-preset-tile "type_flare_v_groove_arrow" "0")
          (weldsym:draw-bevel-preset-tile "type_flare_v_groove_other" "1")
          (weldsym:draw-bevel-preset-tile "type_flare_bevel_groove_arrow" "0")
          (weldsym:draw-bevel-preset-tile "type_flare_bevel_groove_other" "1")
          (weldsym:draw-bevel-preset-tile "type_flare_bevel_groove_both" "2")
          (action_tile "type_arrow" "(weldsym:set-type-preset \"0\" \"0\" \"0\" \"0\")")
          (action_tile "type_other" "(weldsym:set-type-preset \"1\" \"0\" \"0\" \"0\")")
          (action_tile "type_both" "(weldsym:set-type-preset \"2\" \"0\" \"0\" \"0\")")
          (action_tile "type_arrow_len" "(weldsym:set-type-preset \"0\" \"1\" \"0\" \"0\")")
          (action_tile "type_other_len" "(weldsym:set-type-preset \"1\" \"1\" \"0\" \"0\")")
          (action_tile "type_both_len" "(weldsym:set-type-preset \"2\" \"1\" \"0\" \"0\")")
          (action_tile "type_stagger_len" "(weldsym:set-type-preset \"2\" \"1\" \"1\" \"0\")")
          (action_tile "type_bevel_arrow" "(weldsym:set-type-preset \"0\" \"0\" \"0\" \"6\")")
          (action_tile "type_bevel_other" "(weldsym:set-type-preset \"1\" \"0\" \"0\" \"6\")")
          (action_tile "type_bevel_both" "(weldsym:set-type-preset \"2\" \"0\" \"0\" \"6\")")
          (action_tile "type_ugroove_arrow" "(weldsym:set-type-preset \"0\" \"0\" \"0\" \"8\")")
          (action_tile "type_ugroove_other" "(weldsym:set-type-preset \"1\" \"0\" \"0\" \"8\")")
          (action_tile "type_ugroove_both" "(weldsym:set-type-preset \"2\" \"0\" \"0\" \"8\")")
          (action_tile "type_square_groove_arrow" "(weldsym:set-type-preset \"0\" \"0\" \"0\" \"9\")")
          (action_tile "type_square_groove_other" "(weldsym:set-type-preset \"1\" \"0\" \"0\" \"9\")")
          (action_tile "type_square_groove_both" "(weldsym:set-type-preset \"2\" \"0\" \"0\" \"9\")")
          (action_tile "type_flare_v_groove_arrow" "(weldsym:set-type-preset \"0\" \"0\" \"0\" \"10\")")
          (action_tile "type_flare_v_groove_other" "(weldsym:set-type-preset \"1\" \"0\" \"0\" \"10\")")
          (action_tile "type_flare_bevel_groove_arrow" "(weldsym:set-type-preset \"0\" \"0\" \"0\" \"11\")")
          (action_tile "type_flare_bevel_groove_other" "(weldsym:set-type-preset \"1\" \"0\" \"0\" \"11\")")
          (action_tile "type_flare_bevel_groove_both" "(weldsym:set-type-preset \"2\" \"0\" \"0\" \"11\")")
          (action_tile "cancel" "(done_dialog 0)")
          (setq result (start_dialog))
          (unload_dialog dcl)
          (if (= result 1) *weldsym-dialog-symbol* nil))))))

(defun weldsym:split-pipes (value / pos parts)
  (setq parts nil)
  (while (setq pos (vl-string-search "|" value))
    (setq parts (cons (substr value 1 pos) parts))
    (setq value (substr value (+ pos 2))))
  (reverse (cons value parts)))

(defun weldsym:quote-arg (value)
  (strcat "\"" value "\""))

(defun weldsym:type-picker-temp (name)
  (strcat (getvar "TEMPPREFIX") name))

(defun weldsym:start-type-picker-server (/ script image-dir request ready stop shell cmd rc start)
  (setq script (findfile "weldsym_type_picker_server.ps1"))
  (if script
    (progn
      (setq image-dir (strcat (vl-filename-directory script) "\\type_images"))
      (setq request (weldsym:type-picker-temp "weldsym_type_request.txt"))
      (setq ready (weldsym:type-picker-temp "weldsym_type_ready.txt"))
      (setq stop (weldsym:type-picker-temp "weldsym_type_stop.txt"))
      (if (findfile ready)
        (progn
          (setq shell (open stop "w"))
          (write-line "STOP" shell)
          (close shell)
          (vl-cmdf "_.DELAY" 400)
          (if (findfile ready) (vl-file-delete ready))))
      (if (findfile stop) (vl-file-delete stop))
      (setq cmd
        (strcat
          "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -STA -File "
          (weldsym:quote-arg script)
          " "
          (weldsym:quote-arg request)
          " "
          (weldsym:quote-arg image-dir)
          " "
          (weldsym:quote-arg ready)
          " "
          (weldsym:quote-arg stop)))
      (setq shell (vlax-create-object "WScript.Shell"))
      (setq rc (vl-catch-all-apply 'vlax-invoke-method (list shell 'Run cmd 0 :vlax-false)))
      (vlax-release-object shell)
      (setq start (getvar "DATE"))
      (while (and (not (findfile ready)) (< (* 86400.0 (- (getvar "DATE") start)) 15.0))
        (vl-cmdf "_.DELAY" 100))
      (not (vl-catch-all-error-p rc)))))

(defun weldsym:ensure-type-picker-server (/ ready)
  (setq ready (weldsym:type-picker-temp "weldsym_type_ready.txt"))
  (if (not (findfile ready))
    (weldsym:start-type-picker-server)
    T))

(defun weldsym:show-type-image-picker (/ request out f value parts start)
  (if (weldsym:ensure-type-picker-server)
    (progn
      (setq request (weldsym:type-picker-temp "weldsym_type_request.txt"))
      (setq out (weldsym:type-picker-temp "weldsym_type_choice.txt"))
      (if (findfile out) (vl-file-delete out))
      (if (findfile request) (vl-file-delete request))
      (setq f (open request "w"))
      (write-line out f)
      (close f)
      (setq start (getvar "DATE"))
      (while (and (not (findfile out)) (< (* 86400.0 (- (getvar "DATE") start)) 300.0))
        (vl-cmdf "_.DELAY" 100))
      (if (findfile out)
        (progn
          (setq f (open out "r"))
          (setq value (read-line f))
          (close f)
          (vl-file-delete out)
          (if value
            (if (= value "CANCEL")
              "__CANCEL__"
              (progn
                (setq parts (weldsym:split-pipes value))
                (if (= (length parts) 4)
                  (progn
                    (setq *weldsym-type-preset-side* (nth 0 parts))
                    (setq *weldsym-type-preset-length* (nth 1 parts))
                    (setq *weldsym-type-preset-staggered* (nth 2 parts))
                    (setq *weldsym-dialog-symbol* (nth 3 parts))
                    (setq *weldsym-dialog-side* *weldsym-type-preset-side*)
                    *weldsym-dialog-symbol*))))))))))

(defun weldsym:show-type-image-picker-old (/ script image-dir out shell cmd rc f value parts start)
  (setq script (findfile "weldsym_type_picker.ps1"))
  (if script
    (progn
      (setq image-dir (strcat (vl-filename-directory script) "\\type_images"))
      (setq out (strcat (getvar "TEMPPREFIX") "weldsym_type_choice.txt"))
      (if (findfile out) (vl-file-delete out))
      (setq cmd
        (strcat
          "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -STA -File "
          (weldsym:quote-arg script)
          " "
          (weldsym:quote-arg out)
          " "
          (weldsym:quote-arg image-dir)))
      (setq shell (vlax-create-object "WScript.Shell"))
      (setq rc (vl-catch-all-apply 'vlax-invoke-method (list shell 'Run cmd 1 :vlax-false)))
      (vlax-release-object shell)
      (setq start (getvar "DATE"))
      (while (and (not (findfile out)) (< (* 86400.0 (- (getvar "DATE") start)) 300.0))
        (vl-cmdf "_.DELAY" 250))
      (if (and (not (vl-catch-all-error-p rc)) (findfile out))
        (progn
          (setq f (open out "r"))
          (setq value (read-line f))
          (close f)
          (vl-file-delete out)
          (if value
            (if (= value "CANCEL")
              "__CANCEL__"
              (progn
              (setq parts (weldsym:split-pipes value))
              (if (= (length parts) 4)
                (progn
                  (setq *weldsym-type-preset-side* (nth 0 parts))
                  (setq *weldsym-type-preset-length* (nth 1 parts))
                  (setq *weldsym-type-preset-staggered* (nth 2 parts))
                  (setq *weldsym-dialog-symbol* (nth 3 parts))
                  (setq *weldsym-dialog-side* *weldsym-type-preset-side*)
                  *weldsym-dialog-symbol*))))))))))

(defun weldsym:show-type (/ result)
  (setq *weldsym-dialog-symbol* "0")
  (setq *weldsym-type-preset-side* nil)
  (setq *weldsym-type-preset-length* nil)
  (setq *weldsym-type-preset-staggered* "0")
  (setq result (weldsym:show-type-image-picker))
  (cond
    ((= result "__CANCEL__") nil)
    (result result)
    (T (weldsym:show-type-dcl))))
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

(defun weldsym:apply-option-defaults ()
  (if (or (= *weldsym-dialog-side* "0") (= *weldsym-dialog-side* "2"))
    (set_tile "size" "6"))
  (if (or (= *weldsym-dialog-side* "1") (= *weldsym-dialog-side* "2"))
    (set_tile "othersize" "6"))
  (if (= *weldsym-type-preset-length* "1")
    (progn
      (if (or (= *weldsym-dialog-side* "0") (= *weldsym-dialog-side* "2"))
        (progn
          (set_tile "length" "75")
          (set_tile "pitch" "150")))
      (if (or (= *weldsym-dialog-side* "1") (= *weldsym-dialog-side* "2"))
        (progn
          (set_tile "otherlength" "75")
          (set_tile "otherpitch" "150"))))))

(defun weldsym:set-tail-toggle ()
  (if (= (get_tile "tailon") "1")
    (progn
      (if (= (get_tile "tailtext") "") (set_tile "tailtext" "3SIDES"))
      (if (= (get_tile "tailtext2") "") (set_tile "tailtext2" "TYP.")))))

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
          (setq *weldsym-dialog-contour* "0")
          (set_tile "size" (weldsym:alist-get 'size *weldsym-last* ""))
          (set_tile "othersize" (weldsym:alist-get 'othersize *weldsym-last* ""))
          (set_tile "length" (weldsym:alist-get 'length *weldsym-last* ""))
          (set_tile "pitch" (weldsym:alist-get 'pitch *weldsym-last* ""))
          (set_tile "otherlength" (weldsym:alist-get 'otherlength *weldsym-last* ""))
          (set_tile "otherpitch" (weldsym:alist-get 'otherpitch *weldsym-last* ""))
          (set_tile "field" (weldsym:alist-get 'field *weldsym-last* "0"))
          (set_tile "allaround" (weldsym:alist-get 'allaround *weldsym-last* "0"))
          (set_tile "tailon" (weldsym:alist-get 'tailon *weldsym-last* "0"))
          (set_tile "tailtext" (weldsym:alist-get 'tailtext *weldsym-last* ""))
          (set_tile "tailtext2" (weldsym:alist-get 'tailtext2 *weldsym-last* ""))
          (weldsym:draw-side-tile "side0" "0" (= *weldsym-dialog-side* "0"))
          (weldsym:draw-side-tile "side1" "1" (= *weldsym-dialog-side* "1"))
          (weldsym:draw-side-tile "side2" "2" (= *weldsym-dialog-side* "2"))
          (weldsym:apply-type-preset-modes)
          (weldsym:apply-option-defaults)
          (weldsym:set-tail-toggle)
          (action_tile "side0" "(weldsym:set-side \"0\")")
          (action_tile "side1" "(weldsym:set-side \"1\")")
          (action_tile "side2" "(weldsym:set-side \"2\")")
          (action_tile "tailon" "(weldsym:set-tail-toggle)")
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
                (cons 'process \"\")
                (cons 'tailtext (get_tile \"tailtext\"))
                (cons 'tailtext2 (get_tile \"tailtext2\"))
                (cons 'contour \"0\")
                (cons 'staggered *weldsym-type-preset-staggered*)
                (cons 'dir *weldsym-dialog-dir*)))
             (done_dialog 1)")
          (action_tile "cancel" "(done_dialog 0)")
          (setq result (start_dialog))
          (unload_dialog dcl)
          (if (= result 1) *weldsym-last* nil))))))

(defun weldsym:show-bevel-options (/ dcl file result)
  (setq file (findfile "weldsym.dcl"))
  (if (not file)
    (progn (alert "Cannot find weldsym.dcl. Keep weldsym.lsp and weldsym.dcl together.") nil)
    (progn
      (setq dcl (load_dialog file))
      (if (not (new_dialog "weldsym_bevel_opts" dcl))
        (progn (unload_dialog dcl) nil)
        (progn
          (setq *weldsym-dialog-side* (if *weldsym-type-preset-side* *weldsym-type-preset-side* (weldsym:alist-get 'side *weldsym-last* "0")))
          (setq *weldsym-dialog-contour* "0")
          (set_tile "beveldepth" (weldsym:alist-get 'beveldepth *weldsym-last* "12"))
          (set_tile "bevelsize" (weldsym:alist-get 'bevelsize *weldsym-last* "9"))
          (set_tile "bevelroot" (weldsym:alist-get 'bevelroot *weldsym-last* "2"))
          (set_tile "bevelangle" (weldsym:alist-get 'bevelangle *weldsym-last* "45"))
          (set_tile "otherbeveldepth" (weldsym:alist-get-nonblank 'otherbeveldepth *weldsym-last* (weldsym:alist-get-nonblank 'beveldepth *weldsym-last* "12")))
          (set_tile "otherbevelsize" (weldsym:alist-get-nonblank 'otherbevelsize *weldsym-last* (weldsym:alist-get-nonblank 'bevelsize *weldsym-last* "9")))
          (set_tile "otherbevelroot" (weldsym:alist-get-nonblank 'otherbevelroot *weldsym-last* (weldsym:alist-get-nonblank 'bevelroot *weldsym-last* "2")))
          (set_tile "otherbevelangle" (weldsym:alist-get-nonblank 'otherbevelangle *weldsym-last* (weldsym:alist-get-nonblank 'bevelangle *weldsym-last* "45")))
          (set_tile "field" (weldsym:alist-get 'field *weldsym-last* "0"))
          (set_tile "allaround" (weldsym:alist-get 'allaround *weldsym-last* "0"))
          (set_tile "tailon" (weldsym:alist-get 'tailon *weldsym-last* "0"))
          (set_tile "tailtext" (weldsym:alist-get 'tailtext *weldsym-last* ""))
          (set_tile "tailtext2" (weldsym:alist-get 'tailtext2 *weldsym-last* ""))
          (weldsym:apply-bevel-side-modes)
          (weldsym:set-tail-toggle)
          (action_tile "tailon" "(weldsym:set-tail-toggle)")
          (action_tile "accept"
            "(setq *weldsym-last*
              (list
                (cons 'symbol \"6\")
                (cons 'side (if *weldsym-type-preset-side* *weldsym-type-preset-side* \"0\"))
                (cons 'size \"\")
                (cons 'othersize \"\")
                (cons 'length \"\")
                (cons 'pitch \"\")
                (cons 'otherlength \"\")
                (cons 'otherpitch \"\")
                (cons 'field (get_tile \"field\"))
                (cons 'allaround (get_tile \"allaround\"))
                (cons 'tailon (get_tile \"tailon\"))
                (cons 'process \"\")
                (cons 'tailtext (get_tile \"tailtext\"))
                (cons 'tailtext2 (get_tile \"tailtext2\"))
                (cons 'beveldepth (get_tile \"beveldepth\"))
                (cons 'bevelsize (get_tile \"bevelsize\"))
                (cons 'bevelroot (get_tile \"bevelroot\"))
                (cons 'bevelangle (get_tile \"bevelangle\"))
                (cons 'otherbeveldepth (get_tile \"otherbeveldepth\"))
                (cons 'otherbevelsize (get_tile \"otherbevelsize\"))
                (cons 'otherbevelroot (get_tile \"otherbevelroot\"))
                (cons 'otherbevelangle (get_tile \"otherbevelangle\"))
                (cons 'contour \"0\")
                (cons 'staggered \"0\")
                (cons 'dir *weldsym-dialog-dir*)))
             (done_dialog 1)")
          (action_tile "cancel" "(done_dialog 0)")
          (setq result (start_dialog))
          (unload_dialog dcl)
          (if (= result 1) *weldsym-last* nil))))))

(defun weldsym:show-groove-options (/ dcl file result)
  (setq file (findfile "weldsym.dcl"))
  (if (not file)
    (progn (alert "Cannot find weldsym.dcl. Keep weldsym.lsp and weldsym.dcl together.") nil)
    (progn
      (setq dcl (load_dialog file))
      (if (not (new_dialog "weldsym_groove_opts" dcl))
        (progn (unload_dialog dcl) nil)
        (progn
          (setq *weldsym-dialog-side* (if *weldsym-type-preset-side* *weldsym-type-preset-side* (weldsym:alist-get 'side *weldsym-last* "2")))
          (setq *weldsym-dialog-contour* "0")
          (set_tile "groovedepth" (weldsym:alist-get-nonblank 'groovedepth *weldsym-last* "S1"))
          (set_tile "groovesize" (weldsym:alist-get-nonblank 'groovesize *weldsym-last* "E1"))
          (set_tile "grooveroot" (weldsym:alist-get-nonblank 'grooveroot *weldsym-last* "R1"))
          (set_tile "grooveangle" (weldsym:alist-get-nonblank 'grooveangle *weldsym-last* "A1"))
          (set_tile "othergroovedepth" (weldsym:alist-get-nonblank 'othergroovedepth *weldsym-last* "S2"))
          (set_tile "othergroovesize" (weldsym:alist-get-nonblank 'othergroovesize *weldsym-last* "E2"))
          (set_tile "othergrooveroot" (weldsym:alist-get-nonblank 'othergrooveroot *weldsym-last* "R2"))
          (set_tile "othergrooveangle" (weldsym:alist-get-nonblank 'othergrooveangle *weldsym-last* "A2"))
          (set_tile "field" (weldsym:alist-get 'field *weldsym-last* "0"))
          (set_tile "allaround" (weldsym:alist-get 'allaround *weldsym-last* "0"))
          (set_tile "tailon" (weldsym:alist-get 'tailon *weldsym-last* "0"))
          (set_tile "tailtext" (weldsym:alist-get 'tailtext *weldsym-last* ""))
          (set_tile "tailtext2" (weldsym:alist-get 'tailtext2 *weldsym-last* ""))
          (weldsym:apply-groove-side-modes)
          (weldsym:set-tail-toggle)
          (action_tile "tailon" "(weldsym:set-tail-toggle)")
          (action_tile "accept"
            "(setq *weldsym-last*
              (list
                (cons 'symbol *weldsym-dialog-symbol*)
                (cons 'side *weldsym-dialog-side*)
                (cons 'size \"\")
                (cons 'othersize \"\")
                (cons 'length \"\")
                (cons 'pitch \"\")
                (cons 'otherlength \"\")
                (cons 'otherpitch \"\")
                (cons 'field (get_tile \"field\"))
                (cons 'allaround (get_tile \"allaround\"))
                (cons 'tailon (get_tile \"tailon\"))
                (cons 'process \"\")
                (cons 'tailtext (get_tile \"tailtext\"))
                (cons 'tailtext2 (get_tile \"tailtext2\"))
                (cons 'groovedepth (get_tile \"groovedepth\"))
                (cons 'groovesize (get_tile \"groovesize\"))
                (cons 'grooveroot (if (or (= *weldsym-dialog-symbol* \"10\") (= *weldsym-dialog-symbol* \"11\")) \"\" (get_tile \"grooveroot\")))
                (cons 'grooveangle (if (or (= *weldsym-dialog-symbol* \"9\") (= *weldsym-dialog-symbol* \"10\") (= *weldsym-dialog-symbol* \"11\")) \"\" (get_tile \"grooveangle\")))
                (cons 'othergroovedepth (get_tile \"othergroovedepth\"))
                (cons 'othergroovesize (get_tile \"othergroovesize\"))
                (cons 'othergrooveroot (if (or (= *weldsym-dialog-symbol* \"10\") (= *weldsym-dialog-symbol* \"11\")) \"\" (get_tile \"othergrooveroot\")))
                (cons 'othergrooveangle (if (or (= *weldsym-dialog-symbol* \"9\") (= *weldsym-dialog-symbol* \"10\") (= *weldsym-dialog-symbol* \"11\")) \"\" (get_tile \"othergrooveangle\")))
                (cons 'contour \"0\")
                (cons 'staggered \"0\")
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
  (setq *weldsym-current-n* n)
  (setq *weldsym-current-line-layer* (weldsym:line-layer)))

(defun weldsym:current-ready (/)
  (and *weldsym-current-landing* *weldsym-current-ref-end* *weldsym-current-symbol-u* *weldsym-current-tail-u* *weldsym-current-n*))

(defun weldsym:use-current-line-layer (/)
  (if (and *weldsym-current-line-layer* (/= *weldsym-current-line-layer* ""))
    (setq *weldsym-line-layer* *weldsym-current-line-layer*)))

(defun weldsym:use-symbol-line-layer (/)
  (weldsym:ensure-layer "2" 7)
  (setq *weldsym-line-layer* "2"))

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

(defun weldsym:draw (arrow landing ref-end data leader-points / sign u pos-u draw-u n below above symbol side size othersize arrow-size other-size length pitch otherlength otherpitch arrow-length-pitch-text other-length-pitch-text length-text-offset symbol-offset arrow-text-offset other-text-offset contour dir staggered tail1 tail2 tail-text-offset tail1-y tail2-y bevel-base bevel-depth bevel-size bevel-root bevel-angle other-bevel-depth other-bevel-size other-bevel-root other-bevel-angle bevel-size-text other-bevel-size-text groove-base groove-text-base groove-root-base groove-depth groove-size groove-root groove-angle groove-size-text other-groove-depth other-groove-size other-groove-root other-groove-angle other-groove-size-text angle-text)
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
  (setq bevel-depth (weldsym:alist-get 'beveldepth data ""))
  (setq bevel-size (weldsym:alist-get 'bevelsize data ""))
  (setq bevel-root (weldsym:alist-get 'bevelroot data ""))
  (setq bevel-angle (weldsym:alist-get 'bevelangle data ""))
  (setq other-bevel-depth (weldsym:alist-get-nonblank 'otherbeveldepth data bevel-depth))
  (setq other-bevel-size (weldsym:alist-get-nonblank 'otherbevelsize data bevel-size))
  (setq other-bevel-root (weldsym:alist-get-nonblank 'otherbevelroot data bevel-root))
  (setq other-bevel-angle (weldsym:alist-get-nonblank 'otherbevelangle data bevel-angle))
  (setq groove-depth (weldsym:alist-get 'groovedepth data ""))
  (setq groove-size (weldsym:alist-get 'groovesize data ""))
  (setq groove-root (weldsym:alist-get 'grooveroot data ""))
  (setq groove-angle (weldsym:alist-get 'grooveangle data ""))
  (setq other-groove-depth (weldsym:alist-get 'othergroovedepth data ""))
  (setq other-groove-size (weldsym:alist-get 'othergroovesize data ""))
  (setq other-groove-root (weldsym:alist-get 'othergrooveroot data ""))
  (setq other-groove-angle (weldsym:alist-get 'othergrooveangle data ""))
  (if (= symbol "8")
    (progn
      (if (and (/= side "1") (= groove-angle ""))
        (setq groove-angle "A1"))
      (if (and (/= side "0") (= other-groove-angle ""))
        (setq other-groove-angle "A2"))))
  (setq dir (weldsym:alist-get 'dir data "0"))
  (setq sign (if (= dir "1") -1.0 1.0))
  (setq u (list sign 0.0 0.0))
  (setq pos-u u)
  (setq draw-u '(1.0 0.0 0.0))
  (weldsym:use-symbol-line-layer)
  (weldsym:remember-current landing ref-end u n)
  (setq tail1 (weldsym:tail-line1 data))
  (setq tail2 (weldsym:tail-line2 data))
  (setq tail-text-offset (if (and (/= tail1 "") (/= tail2 "")) (weldsym:s 6.5) (weldsym:s 4.333333)))
  (if (and (/= tail1 "") (/= tail2 ""))
    (progn
      (setq tail1-y (weldsym:s 3.0))
      (setq tail2-y (weldsym:s -3.0)))
    (progn
      (setq tail1-y 0.0)
      (setq tail2-y 0.0)))
  (if leader-points
    (weldsym:leader-path leader-points)
    (weldsym:leader arrow landing))
  (weldsym:line landing ref-end)

  (if (= (weldsym:alist-get 'allaround data "0") "1")
    (weldsym:circle landing (weldsym:s 3.0)))

  (if (= (weldsym:alist-get 'field data "0") "1")
    (weldsym:draw-field-flag landing draw-u n))

  (setq *weldsym-block-ents* nil)
  (setq *weldsym-block-attr-values* nil)
  (setq *weldsym-collect-block* T)
  (setq *weldsym-attr-counter* 0)

  (cond
    ((or (= symbol "7") (= symbol "8") (= symbol "9") (= symbol "10") (= symbol "11"))
      (setq groove-base
        (weldsym:add landing
          (weldsym:mul u
            (cond
              ((= symbol "9") (if (= dir "1") (weldsym:s 15.333333) (weldsym:s 20.5)))
              ((= symbol "11") (weldsym:s 17.833333))
              ((= symbol "10") (if (= dir "1") (weldsym:s 12.833333) (weldsym:s 25.5)))
              (T (if (= dir "1") (weldsym:s 12.833333) (weldsym:s 23.0)))))))
      (setq groove-text-base (weldsym:add landing (weldsym:mul u (weldsym:s 20.666667))))
      (setq groove-root-base
        (if (or (= symbol "7") (= symbol "8") (= symbol "9") (= symbol "10") (= symbol "11"))
          (if (= symbol "9")
            (weldsym:add groove-base (weldsym:mul draw-u (weldsym:s 2.5)))
            groove-base)
          (weldsym:add landing
            (weldsym:mul u
              (if (= dir "1") (weldsym:s 15.166667) (weldsym:s 20.666667))))))
      (cond
        ((= symbol "8") (weldsym:draw-u-groove-symbol groove-base draw-u n side))
        ((= symbol "9") (weldsym:draw-square-groove-symbol groove-base draw-u n side))
        ((= symbol "10") (weldsym:draw-flare-v-groove-symbol groove-base draw-u n side))
        ((= symbol "11") (weldsym:draw-flare-bevel-groove-symbol groove-base draw-u n side))
        (T (weldsym:draw-groove-symbol groove-base draw-u n side)))
      (setq other-groove-size-text
        (cond
          ((and (/= other-groove-depth "") (/= other-groove-size "")) (strcat other-groove-depth "(" other-groove-size ")"))
          ((/= other-groove-depth "") other-groove-depth)
          (T other-groove-size)))
      (setq groove-size-text
        (cond
          ((and (/= groove-depth "") (/= groove-size "")) (strcat groove-depth "(" groove-size ")"))
          ((/= groove-depth "") groove-depth)
          (T groove-size)))
      (if (and (/= side "0") (/= other-groove-size-text ""))
        (weldsym:text
          (if (and (= symbol "9") (= dir "1"))
            (weldsym:add ref-end (weldsym:add (weldsym:mul u (weldsym:s -5.0)) (weldsym:mul n (weldsym:s 4.0))))
            (weldsym:add landing (weldsym:add (weldsym:mul u (if (= dir "1") (weldsym:s 32.5) (weldsym:s 5.0))) (weldsym:mul n (weldsym:s 4.0)))))
          other-groove-size-text
          (weldsym:text-height)))
      (if (and (/= side "1") (/= groove-size-text ""))
        (weldsym:text
          (if (and (= symbol "9") (= dir "1"))
            (weldsym:add ref-end (weldsym:add (weldsym:mul u (weldsym:s -5.0)) (weldsym:mul n (weldsym:s -6.0))))
            (weldsym:add landing (weldsym:add (weldsym:mul u (if (= dir "1") (weldsym:s 32.5) (weldsym:s 5.0))) (weldsym:mul n (weldsym:s -6.0)))))
          groove-size-text
          (weldsym:text-height)))
      (if (and (/= symbol "10") (/= symbol "11") (/= side "0") (/= other-groove-root ""))
        (weldsym:text-center
          (weldsym:add groove-root-base (weldsym:mul n (weldsym:s 5.0)))
          other-groove-root
          (weldsym:text-height)))
      (if (and (/= symbol "10") (/= symbol "11") (/= side "1") (/= groove-root ""))
        (weldsym:text-center
          (weldsym:add groove-root-base (weldsym:mul n (weldsym:s -8.0)))
          groove-root
          (weldsym:text-height)))
      (if (and (= symbol "8") (/= side "0") (/= other-groove-angle ""))
        (progn
          (setq angle-text (if (wcmatch other-groove-angle "*%%d*") other-groove-angle (strcat other-groove-angle "%%d")))
          (weldsym:text-center
            (weldsym:add groove-root-base (weldsym:add (weldsym:mul draw-u (weldsym:s 0.75)) (weldsym:mul n (weldsym:s 13.0))))
            angle-text
            (weldsym:text-height))))
      (if (and (= symbol "8") (/= side "1") (/= groove-angle ""))
        (progn
          (setq angle-text (if (wcmatch groove-angle "*%%d*") groove-angle (strcat groove-angle "%%d")))
          (weldsym:text-center
            (weldsym:add groove-root-base (weldsym:add (weldsym:mul draw-u (weldsym:s 0.75)) (weldsym:mul n (weldsym:s -16.0))))
            angle-text
            (weldsym:text-height))))
      (if (and (/= symbol "8") (/= symbol "9") (/= symbol "10") (/= symbol "11") (/= side "0") (/= other-groove-angle ""))
        (progn
          (setq angle-text (if (wcmatch other-groove-angle "*%%d*") other-groove-angle (strcat other-groove-angle "%%d")))
          (weldsym:text-center
            (weldsym:add groove-root-base (weldsym:add (weldsym:mul draw-u (weldsym:s 0.75)) (weldsym:mul n (weldsym:s 13.0))))
            angle-text
            (weldsym:text-height))))
      (if (and (/= symbol "8") (/= symbol "9") (/= symbol "10") (/= symbol "11") (/= side "1") (/= groove-angle ""))
        (progn
          (setq angle-text (if (wcmatch groove-angle "*%%d*") groove-angle (strcat groove-angle "%%d")))
          (weldsym:text-center
            (weldsym:add groove-root-base (weldsym:add (weldsym:mul draw-u (weldsym:s 0.75)) (weldsym:mul n (weldsym:s -16.0))))
            angle-text
            (weldsym:text-height)))))
    ((= symbol "6")
    (progn
      (setq bevel-base (weldsym:add landing (weldsym:mul u (if (= dir "1") (weldsym:s 12.5) (weldsym:s 15.5)))))
      (if (or (= side "0") (= side "2"))
        (weldsym:draw-symbol bevel-base draw-u (weldsym:mul n -1.0) symbol))
      (if (or (= side "1") (= side "2"))
        (weldsym:draw-symbol bevel-base draw-u n symbol))
      (setq bevel-size-text
        (cond
          ((and (/= bevel-depth "") (/= bevel-size "")) (strcat bevel-depth "(" bevel-size ")"))
          ((/= bevel-depth "") bevel-depth)
          (T bevel-size)))
      (setq other-bevel-size-text
        (cond
          ((and (/= other-bevel-depth "") (/= other-bevel-size "")) (strcat other-bevel-depth "(" other-bevel-size ")"))
          ((/= other-bevel-depth "") other-bevel-depth)
          (T other-bevel-size)))
      (if (or (= side "0") (= side "2"))
        (progn
          (if (/= bevel-size-text "")
            (weldsym:text-right
              (weldsym:add landing (weldsym:add (weldsym:mul u (if (= dir "1") (weldsym:s 15.333333) (weldsym:s 12.666667))) (weldsym:mul n (weldsym:s -5.833333))))
              bevel-size-text
              (weldsym:text-height)))
          (if (/= bevel-root "")
            (weldsym:text-center
              (weldsym:add bevel-base (weldsym:add (weldsym:mul draw-u (weldsym:s 1.916667)) (weldsym:mul n (weldsym:s -7.0))))
              bevel-root
              (weldsym:text-height)))
          (if (/= bevel-angle "")
            (progn
              (setq angle-text (if (wcmatch bevel-angle "*%%d*") bevel-angle (strcat bevel-angle "%%d")))
              (weldsym:text
                (weldsym:add landing (weldsym:add (weldsym:mul u (if (= dir "1") (weldsym:s 11.333333) (weldsym:s 16.666667))) (weldsym:mul n (weldsym:s -14.166667))))
                angle-text
                (weldsym:text-height))))))
      (if (or (= side "1") (= side "2"))
        (progn
          (if (/= other-bevel-size-text "")
            (weldsym:text-right
              (weldsym:add landing (weldsym:add (weldsym:mul u (if (= dir "1") (weldsym:s 15.333333) (weldsym:s 12.666667))) (weldsym:mul n (weldsym:s 2.833333))))
              other-bevel-size-text
              (weldsym:text-height)))
          (if (/= other-bevel-root "")
            (weldsym:text-center
              (weldsym:add bevel-base (weldsym:add (weldsym:mul draw-u (weldsym:s 1.916667)) (weldsym:mul n (weldsym:s 4.0))))
              other-bevel-root
              (weldsym:text-height)))
          (if (/= other-bevel-angle "")
            (progn
              (setq angle-text (if (wcmatch other-bevel-angle "*%%d*") other-bevel-angle (strcat other-bevel-angle "%%d")))
              (weldsym:text
                (weldsym:add landing (weldsym:add (weldsym:mul u (if (= dir "1") (weldsym:s 11.333333) (weldsym:s 16.666667))) (weldsym:mul n (weldsym:s 11.166667))))
                angle-text
                (weldsym:text-height))))))))
    (T
     (progn
      (if (= staggered "1")
        (if (= dir "1")
          (progn
            (setq below (weldsym:add landing (weldsym:mul pos-u (weldsym:s 25.5))))
            (setq above (weldsym:add landing (weldsym:mul pos-u (weldsym:s 22.0)))))
          (progn
            (setq below (weldsym:add landing (weldsym:mul pos-u (weldsym:s 12.0))))
            (setq above (weldsym:add landing (weldsym:mul pos-u (weldsym:s 15.5))))))
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

      (setq arrow-text-offset (if (= staggered "1") (if (= dir "1") (weldsym:s 29.166667) (weldsym:s 8.333333)) nil))
      (setq other-text-offset (if (= staggered "1") (if (= dir "1") (weldsym:s 29.166667) (weldsym:s 8.333333)) nil))
      (if (or (= side "0") (= side "2"))
        (if (= staggered "1")
          (weldsym:text-right (weldsym:add landing (weldsym:add (weldsym:mul u arrow-text-offset) (weldsym:mul n (weldsym:s -7.0)))) arrow-size (weldsym:text-height))
          (weldsym:text-right (weldsym:add below (weldsym:add (weldsym:mul draw-u (weldsym:s -3.833333)) (weldsym:mul n (weldsym:s -7.0)))) arrow-size (weldsym:text-height))))
      (if (or (= side "1") (= side "2"))
        (if (= staggered "1")
          (weldsym:text-right (weldsym:add landing (weldsym:add (weldsym:mul u other-text-offset) (weldsym:mul n (weldsym:s 4.0)))) other-size (weldsym:text-height))
          (weldsym:text-right (weldsym:add above (weldsym:add (weldsym:mul draw-u (weldsym:s -3.833333)) (weldsym:mul n (weldsym:s 4.0)))) other-size (weldsym:text-height))))
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
      (setq length-text-offset (if (= staggered "1") (if (= dir "1") (weldsym:s 15.0) (weldsym:s 22.5)) (if (= dir "0") (weldsym:s 19.0) (- symbol-offset (weldsym:s 7.0)))))
      (if (and (or (= side "0") (= side "2")) (/= arrow-length-pitch-text ""))
        (weldsym:text (weldsym:add landing (weldsym:add (weldsym:mul u length-text-offset) (weldsym:mul n (weldsym:s -7.0)))) arrow-length-pitch-text (weldsym:text-height)))
      (if (and (or (= side "1") (= side "2")) (/= other-length-pitch-text ""))
        (weldsym:text (weldsym:add landing (weldsym:add (weldsym:mul u length-text-offset) (weldsym:mul n (weldsym:s 4.0)))) other-length-pitch-text (weldsym:text-height))))))

  (setq *weldsym-collect-block* nil)
  (setq *weldsym-block-prefix* "WELDSYM")
  (weldsym:block-collected landing)

  (if (or (= (weldsym:alist-get 'tailon data "0") "1") (/= tail1 "") (/= tail2 ""))
    (progn
      (setq *weldsym-block-ents* nil)
      (setq *weldsym-block-attr-values* nil)
      (setq *weldsym-block-prefix* "WELDSYM_TAIL")
      (setq *weldsym-collect-block* T)
      (setq *weldsym-attr-counter* 0)
      (weldsym:draw-tail-fork ref-end u n)
      (weldsym:tail-text-entity (weldsym:add ref-end (weldsym:add (weldsym:mul u tail-text-offset) (weldsym:mul n tail1-y))) tail1 (weldsym:text-height) u)
      (weldsym:tail-text-entity (weldsym:add ref-end (weldsym:add (weldsym:mul u tail-text-offset) (weldsym:mul n tail2-y))) tail2 (weldsym:text-height) u)
      (setq *weldsym-collect-block* nil)
      (weldsym:block-collected ref-end)
      (setq *weldsym-block-prefix* "WELDSYM"))))

(defun weldsym:run (preset-dir / arrow landing nextpt lastpt done leader-points ref-end data dist sign used-default has-length-pitch)
  (setq *weldsym-line-layer* (getvar "CLAYER"))
  (if preset-dir
    (setq *weldsym-dialog-dir* preset-dir)
    (setq *weldsym-dialog-dir* (weldsym:show-direction)))
  (if *weldsym-dialog-dir*
    (progn
      (setq arrow (getpoint "\nSpecify weld arrow point: "))
      (if arrow
        (progn
          (setq sign (if (= *weldsym-dialog-dir* "1") -1.0 1.0))
          (setq landing nil)
          (setq lastpt arrow)
          (setq leader-points (list arrow))
          (setq done nil)
          (while (not done)
            (setq nextpt
              (getpoint lastpt
                (if landing
                  "\nSpecify next leader point or press Enter for weld options: "
                  "\nSpecify leader bend / reference line start: ")))
            (if nextpt
              (progn
                (setq landing nextpt)
                (setq lastpt nextpt)
                (setq leader-points (append leader-points (list nextpt))))
              (setq done T)))
          (if landing
            (progn
              (setq used-default T)
              (setq dist (weldsym:s 28.0))
              (setq *weldsym-dialog-symbol* (weldsym:show-type))
              (if *weldsym-dialog-symbol*
                (progn
                  (setq data
                    (cond
                      ((= *weldsym-dialog-symbol* "6") (weldsym:show-bevel-options))
                      ((or (= *weldsym-dialog-symbol* "7") (= *weldsym-dialog-symbol* "8") (= *weldsym-dialog-symbol* "9") (= *weldsym-dialog-symbol* "10") (= *weldsym-dialog-symbol* "11")) (weldsym:show-groove-options))
                      (T (weldsym:show-options))))
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
                          ((or (= (weldsym:alist-get 'symbol data "0") "7") (= (weldsym:alist-get 'symbol data "0") "8") (= (weldsym:alist-get 'symbol data "0") "9") (= (weldsym:alist-get 'symbol data "0") "10") (= (weldsym:alist-get 'symbol data "0") "11"))
                            (setq dist (weldsym:s 35.833333)))
                          ((= (weldsym:alist-get 'staggered data "0") "1")
                            (setq dist (weldsym:s 37.5)))
                          (has-length-pitch
                            (setq dist (weldsym:s 33.333333)))))
                      (setq ref-end (weldsym:add landing (weldsym:mul (list sign 0.0 0.0) dist)))
                      (weldsym:draw arrow landing ref-end data leader-points)
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
      (weldsym:use-symbol-line-layer)
      (weldsym:draw-field-flag *weldsym-current-landing* *weldsym-current-symbol-u* *weldsym-current-n*)
      (princ "\nField weld symbol added to latest weld."))
    (weldsym:no-current-message))
  (princ))
(defun c:WELDALLAROUND ()
  (if (weldsym:current-ready)
    (progn
      (weldsym:use-symbol-line-layer)
      (weldsym:circle *weldsym-current-landing* (weldsym:s 3.0))
      (princ "\nAll-around symbol added to latest weld."))
    (weldsym:no-current-message))
  (princ))
(defun c:WELDTAIL ()
  (if (weldsym:current-ready)
    (progn
      (weldsym:use-symbol-line-layer)
      (setq *weldsym-block-ents* nil)
      (setq *weldsym-block-attr-values* nil)
      (setq *weldsym-block-prefix* "WELDSYM_TAIL")
      (setq *weldsym-collect-block* T)
      (setq *weldsym-attr-counter* 0)
      (weldsym:draw-tail-fork *weldsym-current-ref-end* *weldsym-current-tail-u* *weldsym-current-n*)
      (setq *weldsym-collect-block* nil)
      (weldsym:block-collected *weldsym-current-ref-end*)
      (setq *weldsym-block-prefix* "WELDSYM")
      (princ "\nTail symbol added to latest weld."))
    (weldsym:no-current-message))
  (princ))

(defun weldsym:draw-current-tail-text (line1 line2 / tail-text-offset tail1-y tail2-y)
  (weldsym:use-symbol-line-layer)
  (weldsym:ensure-layer "2" 7)
  (weldsym:ensure-layer "1" 7)
  (weldsym:ensure-text-style)
  (setq *weldsym-block-ents* nil)
  (setq *weldsym-block-attr-values* nil)
  (setq *weldsym-block-prefix* "WELDSYM_TAIL")
  (setq *weldsym-collect-block* T)
  (setq *weldsym-attr-counter* 0)
  (weldsym:draw-tail-fork *weldsym-current-ref-end* *weldsym-current-tail-u* *weldsym-current-n*)
  (setq tail-text-offset (if (and line1 (/= line1 "") line2 (/= line2 "")) (weldsym:s 6.5) (weldsym:s 4.333333)))
  (if (and line1 (/= line1 "") line2 (/= line2 ""))
    (progn
      (setq tail1-y (weldsym:s 3.0))
      (setq tail2-y (weldsym:s -3.0)))
    (progn
      (setq tail1-y 0.0)
      (setq tail2-y 0.0)))
  (weldsym:tail-text-entity
    (weldsym:add *weldsym-current-ref-end* (weldsym:add (weldsym:mul *weldsym-current-tail-u* tail-text-offset) (weldsym:mul *weldsym-current-n* tail1-y)))
    line1
    (weldsym:text-height)
    *weldsym-current-tail-u*)
  (weldsym:tail-text-entity
    (weldsym:add *weldsym-current-ref-end* (weldsym:add (weldsym:mul *weldsym-current-tail-u* tail-text-offset) (weldsym:mul *weldsym-current-n* tail2-y)))
    line2
    (weldsym:text-height)
    *weldsym-current-tail-u*)
  (setq *weldsym-collect-block* nil)
  (weldsym:block-collected *weldsym-current-ref-end*)
  (setq *weldsym-block-prefix* "WELDSYM"))

(defun c:WELDTAIL1 (/ text1)
  (if (weldsym:current-ready)
    (progn
      (setq text1 (getstring T "\nTail text <TYP.>: "))
      (if (or (not text1) (= text1 ""))
        (setq text1 "TYP."))
      (weldsym:draw-current-tail-text text1 "")
      (princ "\nOne-line tail text added to latest weld."))
    (weldsym:no-current-message))
  (princ))

(defun c:WELDTAIL2 (/ text1 text2)
  (if (weldsym:current-ready)
    (progn
      (setq text1 (getstring T "\nTail text line 1 <3 SIDES>: "))
      (if (or (not text1) (= text1 ""))
        (setq text1 "3 SIDES"))
      (setq text2 (getstring T "\nTail text line 2 <TYP.>: "))
      (if (or (not text2) (= text2 ""))
        (setq text2 "TYP."))
      (weldsym:draw-current-tail-text text1 text2)
      (princ "\nTwo-line tail text added to latest weld."))
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
(vl-catch-all-apply 'weldsym:start-type-picker-server '())
(princ "\nWELDSYM loaded. Run WELDSYM to place a weld symbol.")
(princ)













































































