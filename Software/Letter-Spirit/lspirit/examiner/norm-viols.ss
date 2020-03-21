;===========================================================================
; norm-viols.ss : code for computing norm violations
;===========================================================================
; was labels.ss
; JAR working on, March 1998

;===========================================================================
; GENERAL norm-violation code
;===========================================================================

(set! *nv-types* '(Height Width Weight Horizontal Roof Floor))

; the order in these lists is used to compare heights

(set! *heights-list* '(no-height very-short short medium tall very-tall))
(set! *widths-list* '(skinny half-wide wide))
(set! *weights-list* '(light normal-wt heavy huge))

; these are order-irrelevant, and the NVs are calculated in
; mode-specific ways
(set! *horizontals-list* '(left middle right))
(set! *verticals-list*
      '(ascender bottom descender top x-zone baseline--bottom
		 baseline--midline baseline--t-height baseline--top
		 baseline--x-height midline--x-height x-height--bottom
		 x-height--top))

; called by the comparer codelet which picks at random one of the types from
; *nv-types*
(define nv-type
  (lambda (part nvtype)
    (let* ([quanta (lookup 'quanta part)]
	   [pname  (lookup '**role part)]
	   [norms (mapcar car (get-norms pname))])
      (case nvtype
	[Height
	 (compare-norms
	  (height-label (height quanta))
	  (intersect *heights-list* norms)
	  *heights-list*)]
	[Width
	 (compare-norms
	  (width-label (width quanta))
	  (cons 'half-wide (intersect *widths-list* norms))
	  ; horrible kludge, but will be unneeded after Examiner is
	  ; re-written JAR 5/13/98
	  *widths-list*)]
	[Weight
	 (compare-norms
	  (weight-label (length quanta))
	  (intersect *weights-list* norms)
	  *weights-list*)]
	[Horizontal
	 (compare-horiz
	  quanta (intersect *horizontals-list* norms))]
	[Roof
	 (compare-roof
	  quanta (intersect *verticals-list* norms))]
	[Floor
	 (compare-floor
	  quanta (intersect *verticals-list* norms))]	
	[else (error 'nvtype "no such norm type ~s~%" nvtype)]))))

; makes a comparison based on the position of labels in a list
(define list-nv-compare
  (lambda (x y ls)
    (let ([x-ord (order x ls)]
	  [y-ord (order y ls)])
    (cond
     ((eq? (* x-ord y-ord) 0) 'no-comparison)
     ((eq? x-ord y-ord) 'same)
     ((> x-ord y-ord) 'more)
     (else 'less)))))

(define compare-norms
  (lambda (label ls label-ls)
    (let
	((item-compare
	  (lambda (x)
	    (list-nv-compare label x label-ls))))
      (just-discrepancy (mapcar item-compare ls)))))

; if there are multiple labels for some norms, only one can match the
; observed value -- make a note of the OTHER comparison
; e.g. same + bigger = bigger
(define just-discrepancy
  (lambda (ls)
    (if (and (> (length ls) 1) (eq? 'same (car ls))) (cadr ls) (car ls))))

(define comparative-label
  (lambda (comparative mode)
    (case mode
      [Height
       (case comparative
	 [less 'shorter]
	 [same 'same-height]
	 [more 'taller])]
       [Width
	(case comparative
	  [less 'skinnier]
	  [same 'same-width]
	  [more 'wider])]
       [Weight
	(case comparative
	  [less 'lighter]
	  [same 'same-weight]
	  [more 'heavier])]
       [Horizontal
	(case comparative
	  [less 'left-shift]
	  [same 'same-horizontal]
	  [more 'right-shift])]
       [Roof
	(case comparative
	  [less 'lower-roof]
	  [same 'same-roof]
	  [more 'raise-roof])]
       [Floor
	(case comparative
	  [less 'lower-floor]
	  [same 'same-floor]
	  [more 'raise-floor])])))

(define height-label
  (lambda (int)
    (case int
      (0 'no-height)
      (1 'very-short)
      (2 'short)
      (3 'medium)
      (4 'tall)
      (else 'very-tall))))

(define width-label
  (lambda (int)
    (case int
      (0 'skinny)
      (1 'half-wide)
      (else 'wide))))

(define weight-label
  (lambda (int)
    (cond
      ((between? int 1 2) 'light)
      ((between? int 3 5) 'normal-wt)
      ((between? int 6 8) 'heavy)
      (else 'huge))))

(define curve-label
  (lambda (qls)
    (if (real-closure? qls)
	'*closure*
	(let ([n (part-curve qls)])
	  (cond
	   ((between? n -0.05 0.05) '*straight*)
	   ((between? n 0.051 0.15) '*slight-right*)
	   ((between? n 0.151 0.251) '*square-right*)
	   ((> n 0.251) '*strong-right*)
	   ((between? n -0.151 -0.05) '*slight-left*)
	   ((between? n -0.251 -0.151) '*square-left*)
	   ((< n -0.251) '*strong-left*)
	   (else '*weird-curve*))))))

(define shape-label
  (lambda (qls)
    (let
	([closure? (real-closure? qls)]
	 [mid-q-closure? (mid-quanta-closure? qls)])
      (cond
       [(or mid-q-closure? (and (has-tips? qls) closure?))
	'*spiky-closure*]
       [closure? '*closure*]
       [(bactrian? qls) '*bactrian*] ; to keep w from being called u
       [(cupped? qls) '*cupped*]     ; to keep w from being called v
       [else '*simple*]))))     

(define floor-label
  (lambda (n)
    (case n
      [0 'floor-bottom]
      [1 'floor-middown]
      [2 'floor-baseline]
      [3 'floor-midline]
      [4 'floor-x-height]
      [5 'floor-t-height]
      [6 'floor-top]
      [else 'error])))

(define roof-label
  (lambda (n)
    (case n
      [0 'roof-bottom]
      [1 'roof-middown]
      [2 'roof-baseline]
      [3 'roof-midline]
      [4 'roof-x-height]
      [5 'roof-t-height]
      [6 'roof-top]
      [else 'error])))


;===========================================================================
; HORIZONTAL NV code
;===========================================================================

(define horiz-label-value
  (lambda (label)
    (case label
      ['left   0]
      ['middle 1]
      ['right  2]
      [else   'error])))

(set! *left-quanta*
      '(0 2 4 6 8 10 12 14 17 20 23 26 29 32 34 36 38 40 42 44 46 48 50 52 54))
(set! *middle-quanta*
      '(0 2 4 6 8 10 12 32 34 36 38 40 42 44 46 48 50 52 54 1 3 5 7 9 11 13
	  33 35 37 39 41 43 45 47 49 51 53 55 15 18 21 24 27 30))
(set! *right-quanta*
      '(1 3 5 7 9 11 13 16 19 22 25 28 31 33 35 37 39 41 43 45 47 49 51 53 55))

; given a list of a subset of (left middle right), returns the "rightness"
; 0=left, 2=right

(define horiz-labels-value
 (lambda (ls)
   (average (mapcar horiz-label-value ls))))

(define right-edge-label
  (lambda (lf? md? rt?)
    (if
	rt?
	`r-edge-rt
	(if
	    md?
	    `r-edge-md
	    `r-edge-lf))))

(define left-edge-label
  (lambda (lf? md? rt?)
    (if
	lf?
	`l-edge-lf
	(if
	    md?
	    `l-edge-md
	    `l-edge-rt))))

(define horiz-quanta-value
  (lambda (qls)
    (let* ([touchlist '()]
	   [touchlist (if (overlap*? qls *left-quanta*)
			  (cons '0 touchlist) touchlist)]
	   [touchlist (if (overlap*? qls *middle-quanta*)
			  (cons '1 touchlist) touchlist)]
	   [touchlist (if (overlap*? qls *right-quanta*)
			  (cons '2 touchlist) touchlist)])
      (average touchlist))))


(define compare-horiz
  (lambda (qls label-list)
    (let* ([filler (horiz-quanta-value qls)]
	   [norm  (horiz-labels-value label-list)])
      (cond
       ((eq? filler norm) 'same)
       ((> filler norm) 'more)
       (else 'less)))))

;===========================================================================
; VERTICAL NV code (floor, roof)
;===========================================================================

(define vert-label-value
  (lambda (label)
    (case label
      ['bottom   0]
      ['hi-desc  1]
      ['right  2]
      [else   'error])))

(set! *vertical-values*
      '((ascender            (5 6))
	(bottom              (0))
	(descender           (0 1))
	(top                 (6))
	(x-zone              (2 3 4))
	(baseline--bottom    (0 1 2))
	(baseline--midline   (2 3))
	(baseline--t-height  (2 3 4 5))
	(baseline--top       (2 3 4 5 6))
	(baseline--x-height  (2 3 4))
	(midline--x-height   (3 4))
	(x-height--bottom    (0 1 2 3 4))
	(x-height--top       (2 3 4 5 6))))

(set! *vert-quanta*
      '((0 (12 13 29 42 54 30 43 55 31))
	(1 (10 11 29 42 54 30 43 55 31 26 40 52 27 41 53 28))
	(2 (8 9 26 40 52 27 41 53 28 23 38 50 24 39 51 25))
	(3 (6 7 23 38 50 24 39 51 25 20 36 48 21 37 49 22))
	(4 (4 5 20 36 48 21 37 49 22 17 34 46 18 35 47 19))
	(5 (2 3 17 34 46 18 35 47 19 14 32 44 15 33 45 16))
	(6 (0 1 14 32 44 15 33 45 16))))

(define touches-vert
 (lambda (i qls)
   (if (> (length (intersect qls (lookup i *vert-quanta*))) 0)
       (list i) nil)))

; gives the vertical values touched by the quanta list
(define quanta-verts
  (lambda (qls)
    (append (touches-vert 0 qls) (touches-vert 1 qls)
	  (touches-vert 2 qls) (touches-vert 3 qls)
	  (touches-vert 4 qls) (touches-vert 5 qls)
	  (touches-vert 6 qls))))

(define label-verts
  (lambda (label)
    (lookup label *vertical-values*)))

; gives verts touched by a bunch of labels
(define labels-verts
  (lambda (vlabels)
    (cond
     ((null? vlabels) nil)
     (else (append (label-verts (car vlabels))
		 (labels-verts (cdr vlabels)))))))

; Now we just need to compare max and min of labels-verts and
; verts-touched by the norms and quanta of a role!

(define compare-roof
  (lambda (qls label-list)
    (let* ([filler (apply max (quanta-verts qls))]
	   [norm  (apply max (labels-verts label-list))])
      (cond
       ((eq? filler norm) 'same)
       ((> filler norm) 'more)
       (else 'less)))))

(define compare-floor
  (lambda (qls label-list)
    (let* ([filler (apply min (quanta-verts qls))]
	   [norm  (apply min (labels-verts label-list))])
      (cond
       ((eq? filler norm) 'same)
       ((> filler norm) 'more)
       (else 'less)))))