extensions [table]
globals [
  ; hyper
  seed ; fixed
  round-per-price-update ; fixed

  ; results
  total-donation ; reset
  donation-record ; auto-update
  platform-revenue ; auto-update
  revenue-record ; auto-update
  previous-revenue-record ; auto-update
  previous-platform-revenue ; auto-update
  fungible-token-price ; auto-update
  fungible-token-return ; auto-update
  produced-public-goods ; auto-update
  produced-public-goods-per-capita ; auto-update
  risk-neutral-sponsor-action-preferences ; auto-update
  risk-loving-sponsor-action-preferences ; auto-update
  risk-averse-sponsor-action-preferences ; auto-update
  donation-multiplier ; semi-fixed
  state ; auto-update
  prev-total-donation ; auto-update
  endowment ; fixed
  actions ; fixed
]

breed [sponsors sponsor]

sponsors-own [
  ; characteristics
  risk-preference ; fixed
  altruism ; fixed

  ; decisions
  donation ; auto-update
  action ; auto-update
  action-preference ; auto-update

  ; attributes
  Q-table ; auto-update
  previous-reward-table ; auto-update
  previous-state ; auto-update
  previous-action ; auto-update
]

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~buttons~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

to setup ; out
  no-display
  clear-all
  reset-ticks

  set seed -2147483648 + (random 2147483647)
  random-seed seed

  initialize-variables
  create-market
end

to go ; out
  set state compute-state
  reset-variables
  ask sponsors [
    donate
  ]
  public-goods-production
  record-donation
  record-revenue
  update-fungible-token-price
  ask sponsors [
    update-Q-table
  ]
  aggregate-action-preferences
  set prev-total-donation total-donation
  tick
end

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~basic functions~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

to initialize-variables
  set endowment 100
  set round-per-price-update 1000
  set actions []
  foreach range (action-resolution + 1) [x ->
    set actions lput (x / action-resolution) actions
  ]
  set fungible-token-price initial-fungible-token-price
  set prev-total-donation 0
  set donation-record []
  set revenue-record []
end

to reset-variables
  set total-donation 0
  set donation-multiplier num-sponsors * marginal-per-capita-return
end

to-report compute-state
  ifelse ticks = 0 [
    report 0
  ][
    let total_possible_contribution endowment * num-sponsors
    let percentage prev-total-donation / total_possible_contribution
    let discretized_percentage (floor (percentage * 10)) / 10
    report discretized_percentage
  ]
end

to public-goods-production ; out
  set produced-public-goods total-donation * donation-multiplier * (1 - commission-rate)
  set produced-public-goods-per-capita produced-public-goods / num-sponsors
  set platform-revenue (total-donation * commission-rate)
end

to update-fungible-token-price
  let prev-fungible-token-price fungible-token-price
  let dt 1 / (round-per-price-update)
  let donation-uncertainty 0
  if (length revenue-record) > 1 [
    let descaled-revenue-record  vector/scaler revenue-record (mean revenue-record)
    set donation-uncertainty standard-deviation descaled-revenue-record
  ]
  let previous-revenue-level 0
  if (length previous-revenue-record) > 0 [
    set previous-revenue-level (mean previous-revenue-record)
  ]
  set fungible-token-price max list 0 (prev-fungible-token-price + ((fundamentals-reversion * ((mean revenue-record) - prev-fungible-token-price)) * dt + (fungible-token-price-diffusion + donation-uncertainty) * prev-fungible-token-price * (random-normal 0 1) * (sqrt dt)))
  set previous-platform-revenue platform-revenue
  ifelse prev-fungible-token-price < 1e-4 [set fungible-token-return 0][set fungible-token-return fungible-token-price / prev-fungible-token-price]
end

to record-donation ; outside
  set donation-record fput total-donation donation-record
  if (length donation-record) > round-per-price-update [
    set donation-record remove-item round-per-price-update donation-record
  ]
end

to record-revenue ; outside
  set previous-revenue-record revenue-record
  set revenue-record fput platform-revenue revenue-record
  if (length revenue-record) > round-per-price-update [
    set revenue-record remove-item round-per-price-update revenue-record
  ]
end

to aggregate-action-preferences
  let num-actions length actions
  let risk-neutral-action-preference n-values num-actions [0]
  let risk-loving-action-preference n-values num-actions [0]
  let risk-averse-action-preference n-values num-actions [0]

  ask sponsors [
    set action-preference greedy-softmax
    foreach range num-actions [ index ->
      if risk-preference = "neutral" [
        set risk-neutral-action-preference replace-item index risk-neutral-action-preference ((item index risk-neutral-action-preference) + (item index action-preference))
      ]
      if risk-preference = "loving" [
        set risk-loving-action-preference replace-item index risk-loving-action-preference ((item index risk-loving-action-preference) + (item index action-preference))
      ]
      if risk-preference = "averse" [
        set risk-averse-action-preference replace-item index risk-averse-action-preference ((item index risk-averse-action-preference) + (item index action-preference))
      ]
    ]
  ]

  set risk-neutral-sponsor-action-preferences []
  set risk-loving-sponsor-action-preferences []
  set risk-averse-sponsor-action-preferences []

  let total-neutral sum risk-neutral-action-preference
  let total-loving sum risk-loving-action-preference
  let total-averse sum risk-averse-action-preference

  if total-neutral > 0 [
    set risk-neutral-sponsor-action-preferences map [ x -> x / total-neutral ] risk-neutral-action-preference
  ]
  if total-loving > 0 [
    set risk-loving-sponsor-action-preferences map [ x -> x / total-loving ] risk-loving-action-preference
  ]
  if total-averse > 0 [
    set risk-averse-sponsor-action-preferences map [ x -> x / total-averse ] risk-averse-action-preference
  ]
end

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~agent definition~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

to create-market ; out
  create-sponsors num-sponsors [
    define-sponsors
  ]
end

to define-sponsors ; in
  set risk-preference one-of ["neutral" "loving" "averse"]
  set altruism random-float 1
  initialize-Q-table
  set previous-reward-table table:make
  foreach actions [ a ->
    table:put previous-reward-table a endowment
  ]
  set previous-state 0
  set previous-action 0
end

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~agent value functions~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

to-report utility ; in
  report (endowment - donation + non-fungible-token-reward + altruism * altruistic? * produced-public-goods + produced-public-goods-per-capita)
end

to-report risk-adjusted [r a] ; in
  if risk-preference = "neutral" [
    report r
  ]
  if risk-preference = "loving" [
    set r (r + include-risk-lovingness * (standard-deviation (list (table:get previous-reward-table action) r)))
    report r
  ]
  if risk-preference = "averse" [
    set r (r - include-risk-averseness * (standard-deviation (list (table:get previous-reward-table action) r)))
    report r
  ]
end

to-report non-fungible-token-reward ; in
  ifelse non-fungible-token-reward-type = "none" [
    report 0
  ][
    ifelse non-fungible-token-reward-type = "fiat" [
      ifelse (random-float 1) < non-fungible-token-reward-probability [
        report donation * non-fungible-token-reward-multiplier
      ][
        report 0
      ]
    ][
      if non-fungible-token-reward-type = "fungible-token" [
        ifelse (random-float 1) < non-fungible-token-reward-probability [
          report donation * non-fungible-token-reward-multiplier * fungible-token-return
        ][
          report 0
        ]
      ]
    ]
  ]
  show "Invalid NFT Reward Type Error"
  report "error"
end

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~agent decision~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

to donate ; in
  ifelse (random-float 1) < explore-probability [
    random-decision
  ][
    softmax-decision
  ]
end

to random-decision ; in
  set action one-of actions
  set donation endowment * action
  set total-donation total-donation + donation
  set previous-state state
  set previous-action action
end

to softmax-decision ; in
  set action (action-selection softmax)
  set donation endowment * action
  set total-donation total-donation + donation
  set previous-state state
  set previous-action action
end

to-report action-selection [action-probabilities]; in
  let cumulative-probabilities []
  let cumulative 0
  foreach action-probabilities [ prob ->
    set cumulative cumulative + prob
    set cumulative-probabilities lput cumulative cumulative-probabilities
  ]

  let random-value random-float 1
  let a "none"
  let index 0
  while [a = "none"] [
    if random-value < (item index cumulative-probabilities) [
      set a (item index actions)
    ]
    set index index + 1
  ]

  report a
end

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~agent strategy update~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

to initialize-Q-table ; in
  set Q-table table:make
  let possible-states [0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1]
  foreach possible-states [ s ->
    foreach actions [ a ->
      table:put Q-table (list s a) endowment
    ]
  ]
end

to update-Q-table ; in
  let reward utility
  let risk-adjusted-reward (risk-adjusted reward action)

  table:put previous-reward-table action reward

  let old-value table:get Q-table (list previous-state previous-action)

  let new-value (1 - learning-rate) * old-value + learning-rate * risk-adjusted-reward
  table:put Q-table (list previous-state previous-action) new-value
end

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~helper functions~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

to-report softmax ; in
  let q-values []
  foreach actions [ a ->
    let q table:get Q-table (list state a)
    set q-values lput q q-values
  ]
  let max-q (max q-values)
  let adjusted-q-values vector-scaler q-values max-q
  let temperature-adjusted-q-values vector/scaler adjusted-q-values temperature
  let exp-q expvector temperature-adjusted-q-values
  let sum-exp-q sum exp-q
  let action-probabilities map [x -> x / sum-exp-q] exp-q
  report action-probabilities
end

to-report greedy-softmax ; in
  let q-values []
  foreach actions [ a ->
    let q table:get Q-table (list state a)
    set q-values lput q q-values
  ]
  let max-q max q-values
  let adjusted-q-values vector-scaler q-values max-q
  let temperature-adjusted-q-values vector/scaler adjusted-q-values 0.01
  let exp-q expvector temperature-adjusted-q-values
  let sum-exp-q sum exp-q
  let action-probabilities map [x -> x / sum-exp-q] exp-q
  report action-probabilities
end

to-report vector-scaler [vector scaler] ; either
  let output []
  foreach vector [ element ->
    set output lput (element - scaler) output
  ]
  report output
end

to-report vector/scaler [vector scaler] ; either
  let output []
  foreach vector [ element ->
    set output lput (element / scaler) output
  ]
  report output
end

to-report expvector [vector] ; either
  let output []
  foreach vector [ element ->
    set output lput (exp element) output
  ]
  report output
end




@#$#@#$#@
GRAPHICS-WINDOW
0
741
41
783
-1
-1
1.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

SLIDER
733
84
905
117
num-sponsors
num-sponsors
1
100
20.0
1
1
NIL
HORIZONTAL

SLIDER
737
490
909
523
commission-rate
commission-rate
0
1
0.1
0.01
1
NIL
HORIZONTAL

SLIDER
1032
281
1256
314
fungible-token-price-diffusion
fungible-token-price-diffusion
0
10
0.25
0.01
1
NIL
HORIZONTAL

SLIDER
1030
130
1289
163
non-fungible-token-reward-probability
non-fungible-token-reward-probability
0
1
0.5
0.01
1
NIL
HORIZONTAL

CHOOSER
1030
84
1233
129
non-fungible-token-reward-type
non-fungible-token-reward-type
"none" "fiat" "fungible-token"
0

SLIDER
1030
164
1289
197
non-fungible-token-reward-multiplier
non-fungible-token-reward-multiplier
0
10
1.0
0.01
1
NIL
HORIZONTAL

PLOT
0
10
374
196
total donation
ticks
donation
0.0
0.0
0.0
0.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if ticks > 0 [plot total-donation]"

PLOT
0
197
374
372
fungible token capitalization
ticks
price
0.0
0.0
0.0
0.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if ticks > 0 [plot fungible-token-price]"

BUTTON
0
373
66
406
NIL
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
65
373
130
406
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
131
373
223
406
go n ticks
foreach range n [\n go\n]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
224
373
374
406
n
n
1
100
31.0
1
1
NIL
HORIZONTAL

SLIDER
733
184
969
217
marginal-per-capita-return
marginal-per-capita-return
0
2
0.1
0.001
1
NIL
HORIZONTAL

SLIDER
1033
437
1205
470
explore-probability
explore-probability
0
1
0.05
0.01
1
NIL
HORIZONTAL

SLIDER
1033
403
1205
436
temperature
temperature
1e-2
10
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
1033
471
1205
504
learning-rate
learning-rate
0
1
0.5
0.01
1
NIL
HORIZONTAL

PLOT
375
10
715
130
risk neutral sponsor strategy preference
(low donation) <- strategies -> (high donation)
preference
0.0
0.0
0.0
0.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "clear-plot\nif ticks > 0 [\n  foreach risk-neutral-sponsor-action-preferences [ preference ->\n    plot preference\n  ]\n]"

PLOT
375
131
715
251
risk loving sponsor strategy preference
(low donation) <- strategies -> (high donation)
preference
0.0
0.0
0.0
0.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "clear-plot\nif ticks > 0 [\n  foreach risk-loving-sponsor-action-preferences [ preference ->\n    plot preference\n  ]\n]"

PLOT
375
252
715
372
risk averse sponsor strategy preference
(low donation) <- strategies -> (high donation)
preference
0.0
0.0
0.0
0.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "clear-plot\nif ticks > 0 [\n  foreach risk-averse-sponsor-action-preferences [ preference ->\n    plot preference\n  ]\n]"

SLIDER
734
273
906
306
altruistic?
altruistic?
0
1
0.1
0.01
1
NIL
HORIZONTAL

SLIDER
735
364
937
397
include-risk-lovingness
include-risk-lovingness
0
1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
735
398
939
431
include-risk-averseness
include-risk-averseness
0
1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
1033
505
1205
538
action-resolution
action-resolution
0
100
31.0
1
1
NIL
HORIZONTAL

SLIDER
1032
247
1256
280
initial-fungible-token-price
initial-fungible-token-price
0
100
25.0
0.01
1
NIL
HORIZONTAL

SLIDER
1032
315
1214
348
fundamentals-reversion
fundamentals-reversion
0
20
0.64
0.01
1
NIL
HORIZONTAL

TEXTBOX
1034
216
1283
243
⑦ Try controlling the chracteristics of the fungible token price process
11
0.0
1

TEXTBOX
737
455
966
497
⑤ How much commission will the platform take (%)? Recommended: 0.05~0.15
11
0.0
1

TEXTBOX
1031
50
1277
75
⑥ How would like to give the incentive rewards to the contributers? And how much?
11
0.0
1

TEXTBOX
735
51
954
79
① How many sponsors (donors) do we want to simulate? Recommended: 10~30
11
0.0
1

TEXTBOX
735
141
987
183
② Configure a public goods game (<1 will cause free-rider assuming rationality without other motives). Recommended: 0.1~0.2
11
0.0
1

TEXTBOX
735
242
968
284
③ Would you like to assume altruism (No:0, Yes:positive)? Recommended: 0.1~0.2
11
0.0
1

TEXTBOX
1036
372
1209
400
⑧ Configure the reinforcement learning parameters
11
0.0
1

TEXTBOX
734
332
991
374
④ Would you like to include risk-averse/loving preference (No:0, Yes:positive)?
11
0.0
1

MONITOR
375
373
478
418
random seed
seed
17
1
11

TEXTBOX
1292
142
1390
160
Recommended: 1
11
0.0
1

TEXTBOX
1222
325
1326
343
Recommended: 0.5
11
0.0
1

TEXTBOX
1262
291
1373
309
Recommended: 0.25
11
0.0
1

TEXTBOX
1209
413
1304
431
Recommended: 1
11
0.0
1

TEXTBOX
1209
447
1321
475
Recommended: 0.05
11
0.0
1

TEXTBOX
1210
482
1313
500
Recommended: 0.5
11
0.0
1

TEXTBOX
1210
514
1312
532
Recommended: 31
11
0.0
1

TEXTBOX
737
10
1118
42
Start Configuring in 8 Steps!
24
0.0
1

TEXTBOX
0
411
150
441
Setup & Go!
24
0.0
1

@#$#@#$#@
## WHAT IS IT?
This model is a public goods simulation model based on the game theory model proposed in the paper introduced in https://decentralizefunding.com. The model used reinforcement learning algorithm to model adaptive agents, while incorporating altruistic motivation and risk preference in the classic linear public goods game. This model can be thought of a model for ONGAESHI (https://ongaeshi.io), which utilizes web3 technology (Non-Fungible-Token) to incentitivize educational donation. 

## HOW IT WORKS
For a detailed design explanation and academic references, please see https://docs.google.com/document/d/19srS3kCm0jyV-zgT1F8FQnRlNiIriX90F-OUcGk9sWA/edit?tab=t.0#heading=h.lljtwv4lt9j1. 

## HOW TO USE IT
Please see https://docs.google.com/document/d/1iswgSyoIBg4yUVdc3IRX2lG0So7spDqOh5dJeqdxpt0/edit?tab=t.0#heading=h.4ez8m5iku9j to explore how to play with this model.

## THINGS TO NOTICE
The incentivization increases donation amount, when altruism and pther monetary return are not enough to motivate donation. Paying the incentive rewards with fiat (a legal tender) achieves a stable increase in the donaton level. Paying the incentive rewards with fungible token also increases donation level, but it is prone to the uncertainty inherent in the fungible token reward

## THINGS TO TRY
Try to see if the inclusion of the non-fungible-token incentive reward increases total donation, when the total donation is low without it. Also try to see how the strategy preference of each agent with different risk preferences are affected by the non-fungible-token incentive reward.

## CREDITS AND REFERENCES
The academic references for this model is included in the following document along with the detailed design explanation:  https://docs.google.com/document/d/19srS3kCm0jyV-zgT1F8FQnRlNiIriX90F-OUcGk9sWA/edit?tab=t.0#heading=h.lljtwv4lt9j1

## CONTACT
For any inquiries, please contact fukuhara.zemi@gmail.com.
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

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
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
