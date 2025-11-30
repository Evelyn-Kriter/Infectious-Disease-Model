;; CITATION : Yang, C. and Wilensky, U. (2011). NetLogo epiDEM Basic model. http://ccl.northwestern.edu/netlogo/models/epiDEMBasic. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
;; CONTRIBUTORS : Smith Gakuya, Evey Kriter

globals
[ ;~~~~~~~ epiDEM MODEL GLOBALS ~~~~~~~
  nb-infected-previous  ;; Number of infected people at the previous tick
  beta-n                ;; The average number of new secondary
                        ;; infections per infected this tick
  gamma                 ;; The average number of new recoveries
                        ;; per infected this tick
  r0                    ;; The number of secondary infections that arise
                        ;; due to a single infected introduced in a wholly
                        ;; susceptible population
  ;~~~~~~~ NEW GLOBALS ~~~~~~~~~
  libraries             ;; set of patches that represent the libraries
  classes               ;; set of patches that are student classes
  dorms                 ;; set of patches representing student dorms
  d-halls               ;; set of patches representing student dining halls
  total-infected        ;; total number of infected individuals
  days                  ;; days since start of simulation
  deaths                ;; deaths since start of simulation
]

turtles-own
[ ;~~~~~~~ epiDEM MODEL VARIABLES ~~~~~
  infected?           ;; If true, the person is infected
  cured?              ;; If true, the person has lived through an infection.
                      ;; They cannot be re-infected.
  susceptible?        ;; Tracks how much exposure the person has had to covid
  ;infection-length    ;; How long the person has been infected
  ;recovery-time       ;; Time (in hours) it takes before the person has a chance to recover from the infection
  nb-infected         ;; Number of secondary infections caused by an
                      ;; infected person at the end of the tick
  nb-recovered        ;; Number of recovered people at the end of the tick

  ;~~~~~~~ NEW VARIABLES ~~~~~~~
  masked?             ;; If true, the person wears a mask
  vaccinated?         ;; If true, the person is fully vaccinated
  latency             ;; How many days until symptoms will appear after being exposed to covid
  days-since-exposure ;; Days since exposure to covid
  severity            ;; If -1, they are not infected, if 0 they are asymptomatic, if 1 = mild, if 2 = normal, if 3 = critical
  immunocompromised?  ;; If true, the person is immunocompromised

  hunger              ;; Contains hunger level of student, they go to dining hall if > 10

  ;; each students assigned dining hall, class, dorm and library
  my-dhall
  my-class
  my-dorm
  my-lib

  school-work          ;; amount of work student has, if more than a certain threshold they go to the library instead of class
]

patches-own
[
  dorm?
  class?
  d-hall?
  library?
  isolation?
]

;======================= SETUP BUTTON PROCEDURES ======================

; observer context
to setup
  clear-all
  init-globals
  setup-buildings
  setup-people
  reset-ticks
end

; observer context
; initializes the arrays of building set
to init-globals
  set dorms []
  set d-halls []
  set libraries []
  set classes []
  set total-infected 0
  set days 0
  set deaths 0
end

; observer context
; creates individualistic students with various properties that affect their behaviour
to setup-people
  create-turtles initial-people [
    ;determine agent's history
    setxy random-xcor random-ycor
    set cured? false
    set infected? false
    set susceptible? 0
    set latency -1
    set days-since-exposure -1
    set severity -1
    ifelse random-float 100 <= mask-rate [ set masked? true ] [ set masked? false ]
    ifelse random-float 100 <= vaccination-rate [set vaccinated? true ] [ set vaccinated? false ]
    ifelse random-float 100 <= 3 [ set immunocompromised? true ] [ set immunocompromised? false ]

    ;determine agent's physical traits
    ifelse masked? [
      ifelse vaccinated? [ ; masked and vaccinated
        set shape "masked vaccinated person"
      ][ ; only masked
        set shape "masked person"
      ]
    ][
      ifelse vaccinated? [ ; only vaccinated
        set shape "vaccinated person"
      ][ ;neither masked nor vaccinated
        set shape "person"
      ]
    ]
    set color white
    set size 0.5

    ; individual properties that determine movement patterns
    set hunger random 10
    set school-work random 10
    set my-dhall one-of d-halls
    set my-class one-of classes
    set my-dorm one-of dorms
    set my-lib one-of libraries

    assign-color

    ;VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
    ;; Set the recovery time for each agent to fall on a
    ;;; normal distribution around average recovery time
    ;set recovery-time random-normal average-recovery-time average-recovery-time / 4

    ;; make sure it lies between 0 and 2x average-recovery-time
    ;if recovery-time > average-recovery-time * 2 [
      ;set recovery-time average-recovery-time * 2
    ;]
    ;if recovery-time < 0 [ set recovery-time 0 ]
    ;VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
  ]

  ; randomly select n number individuals set by the user to be infected
  ask n-of initial-infected turtles [
    set infected? true
    set days-since-exposure 0
    assign-color
    ;calculate whether this person is asymptomatic
    ifelse vaccinated? [
      ifelse random-float 100 < 35.9 [ set severity 0 ] [ set latency random-normal 5.6 2 set severity random-normal 2 0.5]
    ][
      ifelse random-float 100 < 32.4 [ set severity 0 ] [ set latency random-normal 5.6 2 set severity random-normal 2 0.5]
    ]
    set susceptible? 7
    ;set infection-length random recovery-time
  ]


end

; observer context
; initializes the various buildings on this campus
; currently set to create 5 dorms, 5 classes, 3 dining halls and 3 libraries for easier visualization, but could be expanded to take in user input
to setup-buildings
  ; initializing dorms
  repeat 5 [
    ask one-of patches with [not (class? = true) and not (dorm? = true) and not (d-hall? = true) and not (library? = true)][
      set dorm? true
      set dorms lput self dorms
      set pcolor blue
      set plabel "dorm    "
    ]
  ]

  ; initialize classes
  repeat 5 [
    ask one-of patches with [not (class? = true) and not (dorm? = true) and not (d-hall? = true) and not (library? = true)][
      set class? true
      set classes lput self classes
      set pcolor red
      set plabel "class    "
    ]
  ]

  ; initialize dining halls
  repeat 3 [
    ask one-of patches with [not (class? = true) and not (dorm? = true) and not (d-hall? = true) and not (library? = true)][
      set d-hall? true
      set d-halls lput self d-halls
      set pcolor yellow
      set plabel "d-hall    "
    ]
  ]

  ; initialize libraries
  repeat 3 [
    ask one-of patches with [not (class? = true) and not (dorm? = true) and not (d-hall? = true) and not (library? = true)][
      set library? true
      set libraries lput self libraries
      set pcolor green
      set plabel "library    "
    ]
  ]

  ; set up isolation zone
  ask one-of patches with [not (class? = true) and not (dorm? = true) and not (d-hall? = true) and not (library? = true)][
    set isolation? true
    set pcolor white
    set plabel "isolation    "
  ]
end

;; Different people are displayed in 3 different colors depending on health
;; White is a susceptible person (neither infected nor cured (set at beginning))
;; Green is a cured person
;; Red is an infected person
;; turtle procedure
to assign-color
  if infected?
    [ set color red ]
  if cured?
    [ set color green ]
end


;======================= GO BUTTON PROCEDURES =========================

; observer context
to go
  ; simulation stops if there are no more infected students
  ifelse any? turtles with [infected?][

    ask turtles [
      movement
      clear-count
    ]

    ask turtles with [ infected? ] [
      ;if it is daytime, infect (assume that at night everyone sleeps in singles)
      if (ticks mod 360 <= 180) [infect]
      maybe-recover
      ;if ticks mod 50 = 49 [ set days-since-exposure (days-since-exposure + 1) ]
      if ticks mod 360 = 359 [ set days-since-exposure (days-since-exposure + 1) ]
    ]

    ask turtles [
      assign-color
      calculate-r0
    ]

    tick

    ; Day counter
    ;if ticks mod 50 = 49 [ set days (days + 1) ]
    if ticks mod 360 = 359 [ set days (days + 1) ]
  ][
    user-message "No more infected individuals! Click Halt to end."
  ]
end


; turtle context
; People move about depending on various factors
; if they are in a dining hall they stop being hungry
; if they are in class, their work load increases
; if they are in a library their work load is reduced
to movement
  maybe-quarantine
  ;if [d-hall? = true] of patch-here [
    ;set hunger (hunger - 1)
  ;]
  ;if [class? = true] of patch-here [
    ;set school-work (school-work + random 10)
    ;set hunger (hunger + 2)
  ;]
  if [library? = true] of patch-here [
    set school-work (school-work - 1)
    set hunger (hunger + 0.3)
  ]
end

; turtle context
to maybe-quarantine

  ifelse quarantine? [
    ; uninfected students avoid those who are infected and quarantining
    ifelse not infected? or cured? [ ;students are not infected or have just been cured
      move
    ][ ;students are infected

      ifelse (days-since-exposure >= latency and severity > 0) [; students will automatically go into quarantine if they have symptoms
        face one-of patches with [isolation? = true]
        fd 1
        ;set hunger (hunger + 1)
      ][
        ;if its testing day, assume you get tests back immediately and go to quarantine if infected
        if (pcr-testing > 0 and (days mod pcr-testing = 0) and days-since-exposure >= 3) [
          move-to one-of patches with [isolation? = true]
          ;fd 1
          ;set hunger (hunger + 1)
        ]
        move
      ]
    ]
  ][
    ; if quarantine? is turned off, students continue to interact
    move
  ]
end


; turtle context
; avoids isolation house
to avoid-isolation
  if any? patches in-radius 1  with [isolation? = true] [
    face one-of patches with [isolation? = true]
    rt 180
  ]
end

; turtle context
; Students movement patters
; during the day (i.e. when ticks mod 260 <= 180) they move to either a class or the library depending on their workload
; if they are hungry during the day they go to the dining hall instead of the lib or class
to move
  ;ifelse (ticks mod 50) <= 25 [
  ifelse (ticks mod 360) <= 180 [ ; time is day,

    ;if at dining hall, stay until hunger = 0
    ifelse ([d-hall?] of patch-here = true and hunger > 0) [
      set hunger (hunger - 1)
    ][
      ;if in class, stay for at least one hour (15 ticks)
      ifelse ([class?] of patch-here = true and school-work < 15) [
        set school-work (school-work + 1)
        set hunger (hunger + 0.3)
      ][
        ;else move directions

        ifelse hunger > 15 [
          face my-dhall
          avoid-isolation
          fd 1
        ][
          ifelse school-work <= 0 [
            face my-class
            avoid-isolation
            fd 1
          ][
            face my-lib
            avoid-isolation
            fd 1
          ]
        ]

      ]
      ]
  ][
    ;right before students "wake up" account for hunger built up overnight
    ;susceptibility goes down as people go longer without exposure
    ;if (ticks mod 50) = 49 [ set hunger (hunger + 2) ]
    if (ticks mod 360) = 359 [
      set hunger (hunger + random 15)
      if (not infected?) [set susceptible? (susceptible? - 3)]
    ]

    ; time is night, goes to dorm
    face my-dorm
    avoid-isolation
    fd 1
    ;set hunger (hunger + 1)

  ]


end


;======================= INFECTION PROCEDURES =======================

to clear-count
  set nb-infected 0
  set nb-recovered 0
end

; turtle context
; a number indicating exposure based on time and whether the infectee has a mask on
to infect
  ; if this person is not currently in quarantine and contagious (starts 48 hours before symptoms start) and it is daytime
  if (days-since-exposure >= (latency - 2)) [

    ;let nearby-uninfected (turtles-on neighbors) with [ not infected? and not cured? ]
    let nearby-uninfected (turtles-here) with [ not infected? and not cured? ]

    if nearby-uninfected != nobody and (not ([isolation?] of patch-here = true))[

      ask nearby-uninfected [
        ;calculate increase in susceptibility, assume infection rate is 100% for about 30 minutes within infection radius no mask
        let t calc-infec (myself) (self)
        set susceptible? (susceptible? + t)

        ;if random-float 100 <= calc-infec (myself) (self) [

        if susceptible? >= 7 [
          set infected? true
          set days-since-exposure 1

          ;calculate whether this person is asymptomatic
          ifelse vaccinated? [
            ifelse random-float 100 < 35.9 [ set severity 0 ] [ set latency random-normal 5.6 2 set severity random-normal 2 0.5]
          ][
            ifelse random-float 100 < 32.4 [ set severity 0 ] [ set latency random-normal 5.6 2 set severity random-normal 2 0.5]
          ]

          ;if this person is immunocompromised, severity should be a 3 (critical)
          if immunocompromised? [ set severity 3 ]

          ;if this person is vaccinated and not asymptomatic, -1 severity
          if (vaccinated? and severity > 0 ) [ set severity (severity  - 1) ]

          set nb-infected (nb-infected + 1)
          set total-infected (total-infected + 1)
        ]
      ]
    ]
  ]
end

; function that returns probability of infection depending on mask-wearing
to-report calc-infec [infector infectee]
  ifelse [masked?] of infector [
    ifelse [masked?] of infectee [ ;both people are wearing masks
      ;report 7.50 + (random 0.45)
      ;report random (0.075 + (random 0.0045))
      ifelse random 100 <= (7.5 + random 0.45) [report .8] [report 0]

    ][;only infector is wearing a mask, 85% less likely to recieve covid
      ;report 15.00
      ;report (random 0.15)
      ifelse random 100 <= 15 [ report .8] [report 0]
    ]
  ][
    ifelse [masked?] of infectee [ ;only infectee is wearing a mask 47-50% less likely to recieve covid
      ;report 50.00 + (random 3.00)
      ;report random (0.5 + (random 0.03))
      ifelse random 100 <= (50 + random (3)) [ report .8] [report 0]

    ][;neither person is wearing a mask
      ;report 100.00
      ifelse random 100 <= 90 [report .8] [report 0]
      ;report (random .9)
    ]
  ]
end


to maybe-recover
  ;if asymptomatic, they are cured after 14 days
  ifelse severity = 0 and (days-since-exposure >= 14) [
    set infected? false
    set cured? true
    set days-since-exposure -1
    set latency -1
    set severity -1
    set nb-recovered (nb-recovered + 1)
    set susceptible? -210
  ][
    ;if it has been 14 days since start of symptoms (13 days since exposure for asymptomatic) person is considered recovered
    if days-since-exposure >= (latency + 14) [
      ifelse severity >= 3 [ ;if patient is in a critical condition they may die
        if random 100 <= 5 [
          ask self [ die ]
          set deaths deaths + 1
        ]
      ][ ;if patient is not in critical condition
        set infected? false
        set cured? true
        set days-since-exposure -1
        set latency -1
        set severity -1
        set nb-recovered (nb-recovered + 1)
        set susceptible? -210 ;to account for immunity (7 ticks = 30 minutes unprotected exposure = 7 points = infected)
        ;(7 ticks per day x 30days) every couple days - nightime decrease in susceptibility  = 210 rough leeway)
      ]
    ]

  ]


  ;set infection-length infection-length + 1

  ;; If people have been infected for more than the recovery-time
  ;; then there is a chance for recovery
  ;if infection-length > recovery-time
  ;[
    ;if random-float 100 < recovery-chance
    ;[ ;set infected? false
      ;set cured? true
      ;set nb-recovered (nb-recovered + 1)
    ;]
  ;]
end





;============================================================

;epiDEM procedure
to calculate-r0

  let new-infected sum [ nb-infected ] of turtles
  let new-recovered sum [ nb-recovered ] of turtles

  ;; Number of infected people at the previous tick:
  set nb-infected-previous
	count turtles with [ infected? ] +
	new-recovered - new-infected

  ;; Number of susceptibles now:
  let susceptible-t
	initial-people -
	count turtles with [ infected? ] -
	count turtles with [ cured? ]

  ;; Initial number of susceptibles:
  let s0 count turtles with [ susceptible? < 7 ]


  ifelse nb-infected-previous < 10
  [ set beta-n 0 ]
  [
	;; This is beta-n, the average number of new
	;; secondary infections per infected per tick
	set beta-n (new-infected / nb-infected-previous)
  ]

  ifelse nb-infected-previous < 10
  [ set gamma 0 ]
  [
	;; This is the average number of new recoveries per infected per tick
	set gamma (new-recovered / nb-infected-previous)
  ]

  ;; Prevent division by 0:
  if initial-people - susceptible-t != 0 and susceptible-t != 0
  [
	;; This is derived from integrating dI / dS = (beta*SI - gamma*I) / (-beta*SI):
	set r0 (ln (s0 / susceptible-t) / (initial-people - susceptible-t))
	;; Assuming one infected individual introduced in the beginning,
	;; and hence counting I(0) as negligible, we get the relation:
	;; N - gamma*ln(S(0)) / beta = S(t) - gamma*ln(S(t)) / beta,
	;; where N is the initial 'susceptible' population
	;; Since N >> 1
	;; Using this, we have R_0 = beta*N / gamma = N*ln(S(0)/S(t)) / (K-S(t))
	set r0 r0 * s0 ]
end
@#$#@#$#@
GRAPHICS-WINDOW
465
42
915
493
-1
-1
26.0
1
10
1
1
1
0
0
0
1
-8
8
-8
8
1
1
1
ticks
30.0

BUTTON
60
238
143
271
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
154
238
237
271
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
50
47
246
80
initial-people
initial-people
50
400
400.0
5
1
people
HORIZONTAL

PLOT
968
14
1287
144
Populations
hours
# of people
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Infected" 1.0 0 -2674135 true "" "plot count turtles with [ infected? ]"
"Not Infected" 1.0 0 -10899396 true "" "plot count turtles with [ not infected? ]"

PLOT
966
289
1285
425
Infection and Recovery Rates
hours
rate
0.0
0.2
0.0
0.2
true
true
"" ""
PENS
"Infection Rate" 1.0 0 -2674135 true "" "plot (beta-n * nb-infected-previous)"
"Recovery Rate" 1.0 0 -10899396 true "" "plot (gamma * nb-infected-previous)"

PLOT
967
150
1285
278
Cumulative Infected and Recovered
hours
% total pop
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"% infected" 1.0 0 -2674135 true "" "plot (((count turtles with [ cured? ] + count turtles with [ infected? ]) / initial-people) * 100)"
"% recovered" 1.0 0 -10899396 true "" "plot ((count turtles with [ cured? ] / initial-people) * 100)"

SLIDER
50
87
248
120
mask-rate
mask-rate
0
100
91.0
1
1
%
HORIZONTAL

SLIDER
49
130
249
163
vaccination-rate
vaccination-rate
0
100
80.0
1
1
%
HORIZONTAL

SWITCH
54
176
186
209
quarantine?
quarantine?
0
1
-1000

TEXTBOX
62
293
272
386
KEY:\nDining Halls are yellow patches\nDorms are blue patches\nClasses are red patches\nLibraries are green patches\nIsolation houses are white patches
11
0.0
1

MONITOR
968
441
1286
486
Total Infected Individuals
total-infected + initial-infected
0
1
11

MONITOR
970
498
1285
543
Days since simulation start
days
0
1
11

SLIDER
265
48
438
81
initial-infected
initial-infected
0
initial-people
3.0
1
1
people
HORIZONTAL

MONITOR
970
560
1286
605
Deaths since simulation start
deaths
17
1
11

SLIDER
265
90
438
123
pcr-testing
pcr-testing
0
30
3.0
1
1
days
HORIZONTAL

## CITATIONS for following code

# Yang, C. and Wilensky, U. (2011).  NetLogo epiDEM Basic model.  http://ccl.northwestern.edu/netlogo/models/epiDEMBasic.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

# Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

<!-- 2011 Cite: Yang, C. -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

masked person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105
Rectangle -11221820 true false 120 45 180 75
Line -1 false 180 45 195 30
Line -1 false 120 45 105 30
Line -1 false 180 75 180 75

masked vaccinated person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105
Rectangle -11221820 true false 120 45 180 75
Line -1 false 180 45 195 30
Line -1 false 120 45 105 30
Line -1 false 180 75 180 75
Polygon -2674135 true false 150 120 165 105 180 120 150 165 120 120 135 105 150 120

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

person lefty
false
0
Circle -7500403 true true 170 5 80
Polygon -7500403 true true 165 90 180 195 150 285 165 300 195 300 210 225 225 300 255 300 270 285 240 195 255 90
Rectangle -7500403 true true 187 79 232 94
Polygon -7500403 true true 255 90 300 150 285 180 225 105
Polygon -7500403 true true 165 90 120 150 135 180 195 105

person righty
false
0
Circle -7500403 true true 50 5 80
Polygon -7500403 true true 45 90 60 195 30 285 45 300 75 300 90 225 105 300 135 300 150 285 120 195 135 90
Rectangle -7500403 true true 67 79 112 94
Polygon -7500403 true true 135 90 180 150 165 180 105 105
Polygon -7500403 true true 45 90 0 150 15 180 75 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

vaccinated person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105
Polygon -2674135 true false 150 120 165 105 180 120 150 165 120 120 135 105 150 120

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
