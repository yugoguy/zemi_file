;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; creating variables accessible from any function
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
globals [
  ; add global variables freely here↓
  ; WRITE ME0

  ;---------------------↓default global variables available↓----------------------
  token-price ; update ... latest price of token
  token-supply ; update ... latest supply of tokens
  potential-token-supply ; fixed ... maximum amount of tokens to be supplied during scheduled simulation time horizon (schedule-horizon)
  unlocked-token-supply ; update ... amount of tokens unlocked = can be traded
  round-supply-amount ; update ... amount of tokens to be supplied in the latest round
  token-trade-volume ; update ... amount of tokens traded in the latest round
  tokens-placed ; update ... amount of token placed in order
  user-base ; update ... number of agents holding positive amount of tokens
  serviceable-available-market ; update ... number of agents in the model, which can potentially be a user
  potential-market-size ; fixed ... maximum number of agents to be created during scheduled simulation time horizon (schedule-horizon)
  observer-governance-value ; update ... latest goveranance value of token from observer's perspective
  governance-value ; update ... latest goveranance value of token from agents' perspectives
  num-stakers ; update ... number of agents staking the token
  price-record ; update ... record of the past token price
  return-record ; update ... record of the past token investment returns
  seed ; random fixed ... random seed for result replication
]


;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; creating agent class to base on & create agent attributes
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
breed [users user]
breed [bid-orders bid-order]
breed [ask-orders ask-order]

users-own [
  ; add agent attributes freely here↓
  ; WRITE ME1

  ;---------------------↓default agent attributes (agent local variables) available↓----------------------
  agent-type ; fixed ... type of agent, used to differentiate agents.
  agent-color ; fixed ... color of agents, if using the display (not in use by default).
  window ; fixed ... time horizon that the agent considers when making inference from the past record e.g. when getting expectation of future token investment return by taking average of past returns.
  activeness ; fixed ... probability of agent placing trade orders in a round
  bid-price ; reset ... placeholder for agent's decision on at what price to buy the token(s).
  ask-price ; reset ... placeholder for agent's decision on at what price to sell the token(s).
  bid-amount ; reset ... placeholder for agent's decision on how much tokens to buy.
  ask-amount ; reset ... placeholder for agent's decision on how much tokens to sell.
  token-holdings ; update ... amount of tokens that the agent is holding.
  locked-holdings ; update ... amount of tokens that the agent is holding, which is locked.
  participating? ; update ... indicates whether the agent is holding positive amount of token. True if yes False otherwise.
  staking? ; update ... indicates whether the agent is staking positive amount of token. True if yes False otherwise.
  voting ; update ... indicates whether the agent is willing to participate in voting next round. 1 if yes 0 otherwise.
]

bid-orders-own[
  order-amount
  order-price
]

ask-orders-own[
  order-amount
  order-price
]

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; main operations: setup and go
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
to setup ; out
  ;------------simulation initialization (modification not recommended)------------
  no-display
  clear-all
  reset-ticks

  ;------------setting random seed (modification not recommended)------------
  set seed -2147483648 + (random 2147483647)
  random-seed seed

  ;------------variable initialization------------
  initialize-variables

  ;------------initialize agents------------
  set serviceable-available-market initial-serviceable-available-market
  create-market serviceable-available-market

  ;------------initialize exchange (modification not recommended)------------
  create-users 1 [define-exchange]

  ;------------initialize token distribution (modification not recommended)------------
  distribute-initial-tokens

  ;------------show scheduled token supply and market growth (modification not recommended)------------
  show-supply-schedule
  show-market-growth-curve

  ;------------free space------------
  ;; for initialization of new variables, it is recommend it to add a code in side initialize-variables function rather than adding code here
  ;; to change agent creation, modify create-market function rather than adding code here
  ;; other necessary modifications for simulation setup can go here↓
  ; WRITE ME2


end

to go ; out
  ;------------compute how much token to supply each trading round in this period (modification not recommended)------------
  set round-supply-amount scheduled-token-issue-amount / intra-period-trading-rounds

  ; WRITE ME3

  ;------------running loop for trading rounds------------
  foreach range intra-period-trading-rounds [
    ;------------reset variables to use per trading round (modification not recommended)------------
    reset-variables

    ; WRITE ME4

    ;------------supplying token with various methods------------
    supply-via-reward (round-supply-amount * supplied-via-reward)
    supply-via-exchange (round-supply-amount * supplied-via-exchange)

    ;------------agent staking decision (modification not recommended)------------
    stake-token

    ;------------count total token supplied until now (modification not recommended)------------
    set token-supply sum [token-holdings] of users
    set unlocked-token-supply (sum [token-holdings] of users) - (sum [locked-holdings] of users)

    ;------------burn over-supplied tokens (modification not recommended)------------
    burn-token

    ;------------agent decide on governance participation (modification not recommended)------------
    vote-or-not

    ;------------agent token trading decisions------------
    agent-trade-decision

    ;------------token sales from exchange (modification not recommended)------------
    exchange-decision

    ;------------token transaction (modification not recommended)------------
    find-equilibrium
    trade-tokens

    ;------------record price and return (modification not recommended)------------
    if token-trade-volume > 0 [
      record-price&return
    ]

    ;------------update the agent engagement level idenifier (modification not recommended)------------
    assess-participation
    ;assess-staking

    ;------------update governance value from agents' perspective (modification not recommended)------------
    update-governance-value

    ;------------add additional agents (modification not recommended)------------
    grow-market


    ; WRITE ME5

    ;------------to next trading round (modification not recommended)------------
    tick
  ] ; end the trading round loop for this period


  ; WRITE ME6

  ;------------update governance value from observer's perspective (modification not recommended)------------
  update-observer-governance-value

  ;------------unlock some tokens (modification not recommended)------------
  unlock-tokens
end


;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; initializing and resetting the variables
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
to initialize-variables ; out
  ;------------list initialization------------
  ;; list variables won't be treated as list unless it is initialized as empty list
  set price-record []
  set return-record []

  ;------------scaler value initialization------------
  ;; for scaler variables that needs to be initialized before the simulation starts

  ;------------token metrics initialization (modification not recommended)------------
  set token-price initial-token-price
  set token-supply initial-token-supply
  set price-record lput token-price price-record
  set return-record lput initial-return-belief return-record ; 0 return-record
  if any? bid-orders [ ask bid-orders [ die ] ]
  if any? ask-orders [ ask ask-orders [ die ] ]
  if any? users [ ask users [ die ] ]

  ;------------free space------------
  ; WRITE ME7

end

to reset-variables ; out
  ;------------orderbook initialization (modification not recommended)------------
  ask bid-orders [ die ]
  ask ask-orders [ die ]

  ;------------user decision placeholder initialization-------------
  ask users [
    set bid-price 0
    set ask-price 0
    set bid-amount 0
    set ask-amount 0

    ; WRITE ME8
  ]

  ;------------free space------------
  ; WRITE ME9

end


;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; user agent definition & creation
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
to create-market [increased-market-size]; out
  create-users increased-market-size [ ; replace increased-market-size with number of agents of corresponding type, by mutiplying a ratio for example ... floor (increased-market-size * agent-type-ratio)
    ;------------put corresponding agent definition function here------------
    define-agents
  ]

  ;------------repeat same code snippet per agent types you created------------
  ;------------there should be different define-[type]-agent functions for each type of agents you created------------
  ; WRITE ME10

end

to define-agents ; in
  ;------------set agent type as identifier if necessary------------
  set agent-type "default" ; any type name except for "exchange" is appropriate, and will be used for transaction.

  ;------------initialize default agent attributes------------
  set participating? false
  set staking? false
  set voting 0
  set activeness random-float 0.5
  set window floor ((min-window-length + random (max-window-length - min-window-length)) * intra-period-trading-rounds / 31)
  if window = 0 [show "something is wrong"]
  set agent-color blue

  ;------------free space------------
  ; WRITE ME11

end

; WRITE ME12 (if there is another agent type that should be distinguished)

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; agent utility function and optimal token holding amount
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

to-report utility-function [amount] ; in
  ;------------write comutation of optimal token holdings here that you derived from the utility function------------
  ;************ you may use following default variables ************
  ; amount ... amount of token to be valuated by this function
  ; user-base ... number of token holders
  ; voting ... 1 if the agent valuating the token is participating in governance, 0 otherwise
  ; governance-value ... governance value per token
  ; moving-average-return window ... expected token investment return per token
  ; token-price ... latest price of token
  ; token-supply ... latest suppy of tokens
  ; participation-cost ... cost of participation to the platform
  ; risk-free-rate ... risk free rate
  ; (last price-record) * amount ... value of th current token holdings
  ; (governance-value) * amount / token-supply * voting ... governance value of th holdings
  ;************ you may use your original variables you defined as global variable or agent-local attribute ************
  ;************ if you want to define different utility function for each agent types you created, use if statement ... if agent-type = "type" [computation] ************


  ; WRITE ME13
  ; let valuation ...
  ; report valuation
end

to-report optimal-token-holdings ; in
  ;------------write comutation of optimal token holdings here that you derived from the utility function------------

  ; WRITE ME15
  ; let optimal-amount ...
  ; report max list 0 optimal-amount
end


;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; computation helpers ... could be useful in computing the utility and decisions
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;; Outputs an arithmetic past average return (scaler) by inputting the time horizon (window_length). Usually used to compute it using the "window" attribute of an agent to obtain the expected return from that agent
to-report moving-average-return [window_length] ; either
  ifelse (length return-record) = 0 [
    report initial-return-belief
  ][
    let record_length (length return-record)
    set window_length min list record_length window_length
    report mean ( sublist return-record (record_length - window_length) record_length)
  ]
end

;; Outputs an amount of token rewards (scaler) that an agent can expect.
to-report expected-token-reward-amount ; in
  let amount 0
  set amount amount + (round-supply-amount * supplied-via-reward / (count users))
  report amount
end






;=================================================================

; Free Space for New Code Lines (for new helper functions)

;=================================================================

; WRITE ME16 ~












;=================================================================================================================

; Modification of Below Code is not Recommended Unless You:
;; - want to modify the condition for governance participation (completely random by default)
;; - want to change/add a condition for token reward (only participation or staking reward)

;=================================================================================================================


;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; agent decision on governance participation this round (modification not recommended in general)
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

;-----------↓default↓-----------
to vote-or-not ; out
  ask users with [agent-type != "exchange"] [
    ;set voting random-float 1
    ifelse (random-float 1) < voting-rate [set voting 1][set voting 0]
  ]
end


;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; token distribution through reward  (modification not recommended in general)
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

;-----------↓default↓-----------
to distribute-initial-tokens ; out
  let real-init-user-base min list initial-user-base serviceable-available-market;initial-user-base * serviceable-available-market
  let token-pool initial-token-supply
  ask n-of real-init-user-base users with [agent-type != "exchange"][
    set participating? true
    set token-holdings token-pool / real-init-user-base
  ]
  set token-supply sum [token-holdings] of users
  set user-base real-init-user-base
  set unlocked-token-supply sum [locked-holdings] of users
end

to-report scheduled-token-issue-amount ; out
  let additional-amount 0
  ifelse token-supply < supply-cap [
    ifelse ticks < supply-inflection-ticks [
      set additional-amount (ceiling (pre-token-issue-rate * (2 ^ (ticks / pre-supply_doubling_tick_length))))
      report min list additional-amount (supply-cap - token-supply)
    ][
      set additional-amount (ceiling (post-token-issue-rate * (0.5 ^ (ticks / post-supply_halving_tick_length))))
      report min list additional-amount (supply-cap - token-supply)
    ]
  ][
    report 0
  ]
end

to supply-via-reward [amount] ; out
  let token-pool amount
  let reward-recipients-count count users with [(participating? = true) and (agent-type != "exchange")]
  ask users with [(participating? = true) and (agent-type != "exchange")] [
    set token-holdings token-holdings + (token-pool / reward-recipients-count)
  ]
end


;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; assessing user engagement level (modification not recommended in general)
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

;-----------↓default↓-----------
to assess-participation ; out
  ask users with [(token-holdings > 0) and (agent-type != "exchange")] [
    set participating? true
  ]
  ask users with [(token-holdings <= 0) and (agent-type != "exchange")] [
    set participating? false
  ]
  set user-base (count users with [(token-holdings > 0) and (agent-type != "exchange")]); / (count users)
end

to assess-staking ; out
  ask users with [(locked-holdings > 0) and (agent-type != "exchange")] [
    set staking? true
  ]

  set num-stakers count users with [staking? = true]
end




;=================================================================

; Below Parts Should not be Modified in General

;=================================================================


;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; token transaction with orderbook (modification not recommended)
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
to find-equilibrium  ; out
  ;; CASE 1: If neither order type is present, keep the previous price.
  if (not any? bid-orders) and (not any? ask-orders) [
    set token-price last price-record
    set token-trade-volume 0
    stop
  ]
  ;; CASE 2: If only one type is present, use the reservation price.
  if (not any? bid-orders) [
    set token-price min [order-price] of ask-orders
    set token-trade-volume 0
    stop
  ]
  if (not any? ask-orders) [
    set token-price max [order-price] of bid-orders
    set token-trade-volume 0
    stop
  ]

  ;; Otherwise, both bid and ask orders exist.
  let sortedBids reverse sort-on [order-price] bid-orders
  let sortedAsks sort-on [order-price] ask-orders

  set token-trade-volume 0

  ; A flag to signal that we should stop matching early.
  let done? false

  ; We'll keep track of the last considered bid order’s price.
  let equilibriumPrice 0

  ; Process each bid order (from highest price downward).
  let bidIndex 0
  while [bidIndex < length sortedBids and not done?] [
    let currentBidOrder item bidIndex sortedBids
    let bidPrice [order-price] of currentBidOrder
    ; For this bid order, process ask orders as long as it still has amount left
    ; and there is at least one ask order.
    while [([order-amount] of currentBidOrder > 0) and (length sortedAsks > 0) and (not done?)] [
      let currentAskOrder first sortedAsks
      let askPrice [order-price] of currentAskOrder

      ifelse bidPrice >= askPrice [
        ; A match is made. Determine how much can be traded.
        let tradeAmount min (list ([order-amount] of currentBidOrder) ([order-amount] of currentAskOrder))
        set token-trade-volume token-trade-volume + tradeAmount
        ; Decrease the order amounts accordingly.
        ask currentBidOrder [ set order-amount order-amount - tradeAmount ]
        ask currentAskOrder [ set order-amount order-amount - tradeAmount ]
        ; If the ask order is completely filled, kill it and remove it from the sorted list.
        if [order-amount] of currentAskOrder <= 0 [
          set sortedAsks but-first sortedAsks
          ask currentAskOrder [ die ]
        ]
      ]
      [
        ; The current ask order’s price is higher than the bid’s price.
        ; According to your instructions, in that case the equilibrium price is the current bid order’s price.
        set equilibriumPrice bidPrice
        set done? true
      ]
    ]  ; end inner while

    ; If there are no more ask orders, then the current bid order’s price is the equilibrium price.
    if (length sortedAsks = 0) and ([order-amount] of currentBidOrder > 0) [
      set equilibriumPrice bidPrice
      set done? true
    ]
    ; Record the price of the last bid order processed.
    set equilibriumPrice bidPrice
    set bidIndex bidIndex + 1
  ]

  ; If we ran out of bid orders, then use the last considered bid order’s price.
  if not done? [
    ifelse (length sortedBids > 0) [
      set equilibriumPrice [order-price] of last sortedBids
    ]
    [
      set equilibriumPrice last price-record
    ]
  ]

  set token-price equilibriumPrice
end

to trade-tokens ; out
  let sell-volume token-trade-volume
  let buy-volume token-trade-volume
  if token-trade-volume > 0 [
    let amount 0
    let sold-amount 0 ; for debug
    let bought-amount 0 ; for debug

    foreach (list users with [(ask-price <= token-price) and (ask-amount > 0)]) [ x ->
      if sell-volume > 0 [
        ask x [

          set amount (min (list sell-volume ask-amount))

          set token-holdings token-holdings - amount
          set sell-volume (sell-volume - amount)
          set sold-amount sold-amount + amount ; for debug
        ]
      ]
    ]

    foreach (list users with [(bid-price >= token-price) and (bid-amount > 0)]) [ x ->
      if buy-volume > 0 [
        ask x [

          set amount (min (list buy-volume bid-amount))

          set token-holdings token-holdings + amount
          set buy-volume (buy-volume - amount)
          set bought-amount bought-amount + amount ; for debug
        ]
      ]
    ]
    ;if (buy-volume > 0) or (sell-volume > 0) [ ; for debug
      ;show "tokens"
      ;show token-trade-volume
      ;show sold-amount
      ;show bought-amount
      ;show buy-volume
      ;show sell-volume
    ;]
  ]
end


;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; agent token transaction decision (modification may be required)
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
to agent-trade-decision ; out
  ask users with [agent-type != "exchange"] [
    place-orders
  ]
end

to place-orders ; in
  if (random-float 1) < activeness [
    let optimal-amount optimal-token-holdings
    let reward expected-token-reward-amount
    let wishing-amount optimal-amount - token-holdings - reward

    ifelse wishing-amount > 0 [
      set bid-amount min list maximum-optimization-step-size wishing-amount

      if (token-holdings + reward) < 0 [
      ]

      let valuation ((utility-function ((token-holdings + reward + bid-amount))) - (utility-function ((token-holdings + reward))))
      let per-token-valuation valuation / (bid-amount) ; naive approach ... linear approximation of valuation per token
      set bid-price max list 1e-5 per-token-valuation ; pure valuation approach

      send-bid-order bid-amount bid-price

    ][
      if wishing-amount < 0 [
        if (token-holdings - locked-holdings) > 0 [
          set ask-amount min list (min list maximum-optimization-step-size (token-holdings - locked-holdings)) (-1 * wishing-amount)

          if (token-holdings + reward - ask-amount) < 0 [
            show optimal-token-holdings
            show ask-amount
          ]
          let valuation ((utility-function ((token-holdings + reward - ask-amount))) - (utility-function ((token-holdings + reward))))
          let per-token-valuation valuation / ask-amount
          set ask-price max list 1e-5 per-token-valuation ; pure valuation approach

          send-ask-order ask-amount ask-price

        ]
      ]
    ]
  ]
end

to send-bid-order [amount price] ; in
  hatch-bid-orders 1 [
    set order-amount amount
    set order-price price
  ]
end

to send-ask-order  [amount price] ; in
  hatch-ask-orders 1 [
    set order-amount amount
    set order-price price
  ]
end


;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Token Exchange related (modification not recommended)
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
to define-exchange ; in
  set participating? false
  set agent-type "exchange"
end

to supply-via-exchange [amount]; out
  ask users with [agent-type = "exchange"] [
    set token-holdings (ceiling amount)
  ]
end

to exchange-decision ;out
  ask users with [agent-type = "exchange"] [
    set ask-price 0

    ;let remaining-rounds-today intra-period-trading-rounds - (ticks mod intra-period-trading-rounds)
    set ask-amount token-holdings ;random ((ceiling (token-holdings / remaining-rounds-today)) + 1)

    if any? bid-orders [send-ask-order ask-amount ask-price]
  ]
end


;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; computing token valuation for final output (modification not recommended)
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
to-report token-utility-valuation ; out
  report (last price-record) * token-supply / ((1 + annual-discount-rate) ^ (ticks / intra-period-trading-rounds / 12)) ; in present value
end

to update-governance-value ; out
  let cashflow user-base * (annual-per-user-revenue / 12 / intra-period-trading-rounds)
  set governance-value cashflow + (cashflow / (((1 + annual-discount-rate) ^ (1 / 12 / intra-period-trading-rounds)) - 1) / ((1 + annual-discount-rate) ^ 100))
end

to update-observer-governance-value ; out
  let present-value-cashflow user-base * (annual-per-user-revenue / 12) / ((1 + annual-discount-rate) ^ (ticks / intra-period-trading-rounds / 12))
  set observer-governance-value observer-governance-value + present-value-cashflow
end

to-report observer-terminal-value ; out
  let final-day-cashflow user-base * (annual-per-user-revenue / 12)
  let perpeptual-terminal-value final-day-cashflow / (((1 + annual-discount-rate) ^ (1 / 12)) - 1)
  let present-terminal-value perpeptual-terminal-value / ((1 + annual-discount-rate) ^ (ticks / intra-period-trading-rounds / 12)) ;(ticks / intra-period-trading-rounds / 12) gives how many years simulated
  report present-terminal-value
end


;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; recording the price and returns (modification not recommended)
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
to record-price&return ; out
  set return-record lput (ln ((max list 1e-10 token-price) / (max list 1e-10 (last price-record)))) return-record ; ( ( token-price - (last price-record) ) / (max list 0.0001 (last price-record))) return-record
  set price-record lput token-price price-record
end


;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; growing market (modification not recommended)
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
to-report market-size-growth ; out
  let additional-users 0
  ifelse ticks < growth-inflection-ticks [
    set additional-users floor (pre-market-growth-rate * (2 ^ (ticks / pre-inflection-market-doubling-ticks)))
  ][
    set additional-users floor (post-market-growth-rate * (0.5 ^ (ticks / post-inflection-market-halving-ticks)))
  ]
  report additional-users
end

to grow-market ; out
  let additional-users market-size-growth
  create-market additional-users
  set serviceable-available-market serviceable-available-market + additional-users
end


;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; unlocking, staking, and burning excess tokens (modification not recommended)
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
to stake-token ; out
  ask users with [agent-type != "exchange"] [
    if optimal-token-holdings > token-holdings [
      set locked-holdings token-holdings
    ]
  ]
end

to unlock-tokens ; out
  ask users with [(locked-holdings > 0) and (agent-type != "exchange")] [
    set locked-holdings locked-holdings * (1 - token-unlock-ratio)
  ]
end

to burn-token ;out
  if token-supply > potential-token-supply [
    ask users with [(token-holdings > 0) and (agent-type != "exchange")] [
      set token-holdings token-holdings - ((token-supply - potential-token-supply) / (count users with [(token-holdings > 0) and (agent-type != "exchange")]))
    ]
  ]
end


;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; showing scheduled supply and market growth (modification not recommended)
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
to show-supply-schedule ; out
  set-current-plot "token supply schedule"
  clear-plot
  create-temporary-plot-pen "pen"
  set-current-plot-pen "pen"
  let scheduled-supply-t initial-token-supply
  foreach range schedule-horizon [ t ->
    ifelse scheduled-supply-t < supply-cap [
      ifelse t < supply-inflection-ticks [
        set scheduled-supply-t scheduled-supply-t + (min list (supply-cap - scheduled-supply-t) (floor (pre-token-issue-rate * (2 ^ (t / pre-supply_doubling_tick_length)))))
        plot scheduled-supply-t
      ][
        set scheduled-supply-t scheduled-supply-t + (min list (supply-cap - scheduled-supply-t) (floor (post-token-issue-rate * (0.5 ^ (t / post-supply_halving_tick_length)))))
        plot scheduled-supply-t
      ]
    ][
      plot scheduled-supply-t
    ]
  ]
  set potential-token-supply scheduled-supply-t
end

to show-market-growth-curve ; out
  set-current-plot "market size prospect"
  clear-plot
  create-temporary-plot-pen "pen"
  set-current-plot-pen "pen"
  let num-users initial-serviceable-available-market
  foreach range schedule-horizon [ t ->
    ifelse t < growth-inflection-ticks [
      set num-users num-users + floor (pre-market-growth-rate * (2 ^ (t / pre-inflection-market-doubling-ticks)))
      plot num-users
    ][
      set num-users num-users + floor (post-market-growth-rate * (0.5 ^ (t / post-inflection-market-halving-ticks)))
      plot num-users
    ]
  ]
  set potential-market-size num-users
end



@#$#@#$#@
GRAPHICS-WINDOW
0
925
41
967
-1
-1
1.0
1
10
1
1
1
0
0
0
1
0
32
0
32
0
0
1
ticks
30.0

BUTTON
346
256
438
289
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

SLIDER
337
370
524
403
initial-token-price
initial-token-price
0.01
100
3.0
0.01
1
NIL
HORIZONTAL

SLIDER
790
577
1043
610
initial-serviceable-available-market
initial-serviceable-available-market
0
1000
100.0
1
1
NIL
HORIZONTAL

SLIDER
337
472
524
505
risk-free-rate
risk-free-rate
0
1
0.05
0.01
1
NIL
HORIZONTAL

SLIDER
525
472
712
505
participation-cost
participation-cost
0
1000
0.0
1
1
NIL
HORIZONTAL

SLIDER
337
438
524
471
token-unlock-ratio
token-unlock-ratio
0
1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
212
551
412
584
initial-token-supply
initial-token-supply
0
10000000
5201438.0
1
1
NIL
HORIZONTAL

SLIDER
337
404
524
437
initial-user-base
initial-user-base
0
1000
100.0
1
1
NIL
HORIZONTAL

SLIDER
212
653
514
686
pre-supply_doubling_tick_length
pre-supply_doubling_tick_length
1
100000
54592.74306914
0.01
1
NIL
HORIZONTAL

PLOT
0
10
438
209
token value
ticks
price
0.0
0.0
0.0
0.0
true
true
"\n" "set-plot-x-range (max list 0 (ticks - show-from)) ticks + 1\n;ifelse not full [set-plot-x-range (max list 0 (ticks - show-from)) ticks + 1][\n;  set-plot-x-range 0 (ticks + 1)\n;  set-plot-y-range (precision ((min price-record) - 1) 2) (precision (max price-record) 2)\n;]\n;if reset-scale? [set-plot-y-range (precision (token-price - 1) 2) (precision (token-price + 1) 2)]"
PENS
"last traded price" 1.0 0 -7500403 true "" ";ifelse ticks > 1 [plot last price-record][plot initial-token-price]\nif ticks > 1 [plot last price-record]"
"observer present value" 1.0 0 -2674135 true "" "if ticks > 1 [plot (observer-governance-value + observer-terminal-value + token-utility-valuation) / token-supply]"

PLOT
439
171
738
334
token supply
ticks
supply
0.0
1.0
0.0
1.0
true
true
"" ""
PENS
"total" 1.0 0 -16777216 true "" "if ticks > 0 [plot token-supply]"
"unlocked" 1.0 0 -7500403 true "" "if ticks > 0 [plot unlocked-token-supply]"

PLOT
739
171
968
334
user base
ticks
users
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"total" 1.0 0 -16777216 true "" "if ticks > 0 [plot count users with [(participating? = true)]]"

PLOT
660
10
884
170
trade volume
ticks
volume
0.0
0.0
0.0
0.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if ticks > 0 [plot token-trade-volume]"

PLOT
439
10
659
170
token return
ticks
return
0.0
0.0
0.0
0.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if return-record != 0 [\n  if (length return-record) > 0 [\n    plot (last return-record)\n  ]\n]"

BUTTON
346
290
438
323
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
1

SLIDER
804
369
991
402
initial-return-belief
initial-return-belief
-1
2
0.0
0.001
1
NIL
HORIZONTAL

TEXTBOX
12
532
194
560
token supply schedule controller
11
0.0
1

TEXTBOX
343
346
519
364
market initialization parameters
11
0.0
1

SLIDER
0
336
265
369
intra-period-trading-rounds
intra-period-trading-rounds
1
100
10.0
1
1
rounds
HORIZONTAL

SLIDER
0
302
345
335
show-from
show-from
1
10000
10000.0
1
1
periods back
HORIZONTAL

MONITOR
346
210
438
255
month
ticks / intra-period-trading-rounds
0
1
11

PLOT
11
585
211
733
token supply schedule
ticks
supply
0.0
1.0
0.0
1.0
true
false
"" ""
PENS

SLIDER
11
551
211
584
schedule-horizon
schedule-horizon
0
3600
600.0
1
1
NIL
HORIZONTAL

SLIDER
212
585
438
618
supply-inflection-ticks
supply-inflection-ticks
0
1000
239.0
1
1
if sigmoid
HORIZONTAL

BUTTON
11
733
76
767
show
show-supply-schedule
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
212
721
500
754
post-supply_halving_tick_length
post-supply_halving_tick_length
1
100000
324.0944231
0.01
1
NIL
HORIZONTAL

SLIDER
212
687
450
720
post-token-issue-rate
post-token-issue-rate
0
10000
5327.49443937
0.01
1
NIL
HORIZONTAL

SLIDER
212
619
450
652
pre-token-issue-rate
pre-token-issue-rate
0
100000
6234.13173191
0.01
1
NIL
HORIZONTAL

SLIDER
212
755
412
788
supply-cap
supply-cap
1
10000000000
1.0E10
1
1
NIL
HORIZONTAL

MONITOR
76
733
211
778
final supply
potential-token-supply
0
1
11

SLIDER
525
370
700
403
annual-discount-rate
annual-discount-rate
0
1
0.3
0.01
1
NIL
HORIZONTAL

MONITOR
0
210
172
255
total utility value
token-utility-valuation
17
1
11

MONITOR
0
256
172
301
per-token utility value
token-utility-valuation / token-supply
17
1
11

TEXTBOX
627
563
777
581
market growth controller
11
0.0
1

SLIDER
790
679
1087
712
pre-inflection-market-doubling-ticks
pre-inflection-market-doubling-ticks
1
10000
992.567141
0.01
1
NIL
HORIZONTAL

SLIDER
790
611
1028
644
growth-inflection-ticks
growth-inflection-ticks
0
1000
116.579825
1
1
NIL
HORIZONTAL

SLIDER
790
747
1095
780
post-inflection-market-halving-ticks
post-inflection-market-halving-ticks
1
10000
9999.94059
0.01
1
NIL
HORIZONTAL

SLIDER
790
645
1028
678
pre-market-growth-rate
pre-market-growth-rate
0
10000
8.31137145
0.01
1
NIL
HORIZONTAL

PLOT
589
584
789
734
market size prospect
ticks
market size
0.0
1.0
0.0
1.0
true
false
"" ""
PENS

BUTTON
589
735
653
768
show
show-market-growth-curve
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
654
735
789
780
final SAM
potential-market-size
0
1
11

PLOT
885
10
1109
170
market size
ticks
market size
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"total" 1.0 0 -16777216 true "" "if ticks > 0 [plot count users] "

SLIDER
212
789
412
822
supplied-via-reward
supplied-via-reward
0
1
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
212
823
412
856
supplied-via-exchange
supplied-via-exchange
0
1
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
525
404
745
437
annual-per-user-revenue
annual-per-user-revenue
0
10000
23.67
1
1
NIL
HORIZONTAL

MONITOR
173
210
345
255
total governance value
observer-governance-value + observer-terminal-value
17
1
11

MONITOR
173
256
345
301
per-token governance value
(observer-governance-value + observer-terminal-value)/ token-supply
17
1
11

SLIDER
790
713
1048
746
post-market-growth-rate
post-market-growth-rate
0
10000
60.3736513
0.01
1
NIL
HORIZONTAL

SLIDER
804
403
991
436
min-window-length
min-window-length
0
500
7.0
1
1
days
HORIZONTAL

SLIDER
804
437
991
470
max-window-length
max-window-length
0
500
365.0
1
1
days
HORIZONTAL

MONITOR
328
164
438
209
random seed
seed
0
1
11

SLIDER
525
438
697
471
voting-rate
voting-rate
0
1
0.05
0.01
1
NIL
HORIZONTAL

SLIDER
0
370
265
403
maximum-optimization-step-size
maximum-optimization-step-size
1
1000
20.0
1
1
tokens
HORIZONTAL

MONITOR
328
118
438
163
simulated price
last price-record
10
1
11

TEXTBOX
805
350
992
368
agent parameters
11
0.0
1

@#$#@#$#@
## Contact
contact nagatakeyugo@keio.jp or fukuhara.zemi@gmail.com for questions regarding the code.
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
<experiments>
  <experiment name="ETH1" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>(ticks = 600) or ((min price-record) &lt; 1e-5) or ((max price-record) &gt; 10000)</exitCondition>
    <metric>token-price</metric>
    <metric>last price-record</metric>
    <metric>token-trade-volume</metric>
    <metric>user-base</metric>
    <metric>platform-productivity</metric>
    <metric>unlocked-token-supply</metric>
    <metric>seed</metric>
    <enumeratedValueSet variable="intra-period-trading-rounds">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-optimization-step-size">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-token-price">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-user-base">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="token-unlock-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="risk-free-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="annual-discount-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="annual-per-user-revenue">
      <value value="23.67"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="participation-cost">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-return-belief">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-window-length">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-window-length">
      <value value="365"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-token-supply">
      <value value="5201438"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="supply-inflection-ticks">
      <value value="239.20867425"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pre-token-issue-rate">
      <value value="6234.13173191"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pre-supply_doubling_tick_length">
      <value value="54592.74306914"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="post-token-issue-rate">
      <value value="5327.49443937"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="post-supply_halving_tick_length">
      <value value="324.0944231"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="supply-cap">
      <value value="100000000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="supplied-via-reward">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="supplied-via-exchange">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-serviceable-available-market">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="growth-inflection-ticks">
      <value value="116.579825"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pre-market-growth-rate">
      <value value="8.31137145"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pre-inflection-market-doubling-ticks">
      <value value="992.567141"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="post-market-growth-rate">
      <value value="60.3736513"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="post-inflection-market-halving-ticks">
      <value value="9999.94059"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-from">
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schedule-horizon">
      <value value="600"/>
    </enumeratedValueSet>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-7.247775612157024"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.0252378067370218"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.3167934596455773"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.5417135965267916"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-9.404959461782829"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.338917530258616"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.0836505976477175"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.6630311064651007"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.979256773105046"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.360609282113524"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.106972502034158"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.665695314867811"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.3837959500398878"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.1170477406668127"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.1110380647522238"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.9729026601412083"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.224293847395886"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.7355396352394035"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.12491399318343588"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.017774768261187"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.115318967098606"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.1664854102780504"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.613461201238046"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.4263603105614813"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-7.932172959471503"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.3418609132984765"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.259270084758114"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.7655846323321924"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.3758515346379214"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.4910125988180862"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.373472898154395"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.036109403714084"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.472014439590309"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.9761480509669376"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.4516166216548134"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.9440477255883656"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.9710315127186178"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.1226837505611584"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.7123693187461884"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.9054657828428214"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-7.7918583212127075"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.35814883230709427"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.9055262570872333"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.0196327995702994"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-7.455253609971735"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.4150150456929493"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.048729488298438"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.6616554059090973"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.9302025253043471"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.7495850356988703"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.7983326006020628"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.19163151059402583"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-9.531575443085872"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.6285830358304922"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.4263608344383325"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.5221927968469742"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.512620296992307"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.266620786130507"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.4837402114006237"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.1584534367025574"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-7.665411781341714"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.7938975720581665"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.5143046018733164"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.7805404009964662"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.713399152689056"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.3234697623568765"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.0061582288512345"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.472017342529049"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.7004662610625827"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.2546328802644053"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.5976797791817873"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.7589084187585904"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.3905838159564023"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.195361966056039"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.43275316743222103"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.0995357619834012"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.7712344056996754"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.0699428042216086"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.6270967026830782"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.4595779310957733"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.9146389473042067"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.2226856008807845"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.9594560539304746"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.6875259258071678"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.9821653481032886"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.5657052933507414"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.6678180638777502"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.9611036605383427"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-9.905581785314896"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.4292942241122155"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.8692764347470257"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.9326298291035301"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.549817830146047"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.9396430968556109"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.9704307950652846"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.850993493835337"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.7454728385475526"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.3869465747083467"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.153229419325114"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.169293780976097"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.684018647008234"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.5871913640115602"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.350755917142173"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.32754507067372984"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.2081134009284096"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.639594904512843"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.3465876413495232"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.5269534640895022"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-9.506531634396516"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.9300426565935096"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.177447756034727"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.1837924369968963"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.094332758197166"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.928000837495599"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.0418029088166776"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.5613141197407301"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-7.732570068966529"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.2394351800815011"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.745702720057587"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.088248827719951"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-9.158552482708053"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.2847167427548447"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.43702997447622"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.1488219576467507"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.441441681374414"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.2871293638627614"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.940723093654795"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.369047914291697"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.6507186960679014"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.4185191884517216"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.699801681351622"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.3842056448663977"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.2222485084337036"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.5043920686640906"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.7864290831765923"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.191635571959761"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.208409839877106"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.268921169710051"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.142665572010153"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.935054134773128"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-7.6024465722767065"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.6328685278984958"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.0285832884347395"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.237551264631312"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.164338935072207"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.934036343939236"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.7615291240033037"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.6730344610084318"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.8200173320806403"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.3393035431434326"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.0303694951834474"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.9795494297204055"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.7054779823376265"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.08082692889393872"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.912427986382469"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.6007168036290627"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.985168932400823"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.6956712509668836"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.533877255290017"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.2551521907572143"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.592733063608408"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.7945011554236254"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.2370999278673551"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.0366094801654144"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.0985244207389453"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.3351713361770656"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.5285631267604968"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.554745572565476"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.930971660440701"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.7774361742527525"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.8835771656905558"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.6551521279455583"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-9.586813408993718"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.16071172646126364"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.9154799186290014"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.4270386378082875"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.5496244371040078"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.6926609689439323"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.658029361290697"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.8527410708284416"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.783159562644656"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.0154613059385156"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.5997987658012011"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.7671649124230606"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.866881874228073"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.4954268641107307"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.1627672331533786"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.0795785620296896"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.308203427098965"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.6315263386349015"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.1860348297478542"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.8581492280566658"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.4196769284555941"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.3181048064973"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.770479667001066"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.4353141587015865"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.010132883070499"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.181067212115418"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.7357334530746034"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.632163373755566"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.756190043645548"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.1103096924813993"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.9819604869647103"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.8990659501893972"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-8.139813425323782"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.04834779283684387"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.2455167232887767"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.7783296967832465"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.247458708411177"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.897843612515591"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.140299282515414"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.4314674772048199"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.6310308305312082"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.3242509082958396"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.766262755475158"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.595572197357371"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.4134099899536263"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.9450047480689046"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.515454431028548"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.7202314201401503"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-7.248870029946525"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.13530126357402228"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.051751240141723"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.7725278266342356"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-9.168429803613904"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.7392947764336979"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.737567135191359"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.7681318633682945"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.7221971665139906"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.679788704692764"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.4284420020991035"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.9789621024235601"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.371906875872517"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.344001326875306"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.9473309767835718"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.352514709813099"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.9206188634216996"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.4844142096620292"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.8346009775092034"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.9829356851193065"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.575018380648257"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.7963406997664269"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.2851576471643489"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.1565976680653608"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.39536539179938"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.4653331567695194"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.8288243386549357"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.489641093519943"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-8.129530824436344"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.264941601252862"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.8118678032387603"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.015997789178283"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.7744032310105844"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.17124035965179552"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.239562302425667"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.511051550465636"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.2783686305585817"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.2911659789641687"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.401685699461134"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.3193937081469786"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.1693252935126033"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.9310508592652713"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.8377970344405633"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.312455875414416"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.8016834352735529"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.842236310698957"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.237059955757408"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.642435577532782"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.6068988226831742"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.18719615606494155"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.0152195816765404"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.877121993643419"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.2957730433623329"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.7938692760315034"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.357496015293721"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.45031430742563106"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.084562760752906"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.1051329658802107"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.3378206275727735"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.728497194088704"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.735669370206578"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.5233468641634476"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.3060983261613287"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.9059672206919016"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.182814508125055"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.810512499733246"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.682783435599759"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.958441358895131"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-9.733660870094894"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.9068318976762351"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.3137010087713152"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.955507139740661"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.0691622358061643"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.41428814429918415"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.2747798442235472"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.312444486408691"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.920244732122994"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.362476571019444"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.78580023283471"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.710115464086337"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.876988721882846"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.0940086801367528"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.1063769506941137"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.983301870761106"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.3946926701321694"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.557668667906894"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.30270066081953595"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.7249329313038317"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.878867817952532"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.6483868209654906"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.8339601254770246"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.863148090036707"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.6199842341938115"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.2912622283369899"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.335007321786264"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.583971948159503"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.1016671125591397"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.2771162137731853"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.909302137452146"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.23125753628330303"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.2465424049958411"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.353440089385523"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.1507728046266127"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.9629678909219166"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.4850427250661085"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.6426970169779729"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.5316668914442033"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.8846182471652706"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.648273303592372"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.30783490299553495"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.523395986311417"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.8332221295008138"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.4188207788809812"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.979710272865848"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.6253674665796618"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.6624913687152856"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.0462511471401292"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.845358483742709"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.7231642647877251"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.102684997911355"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.732967381315955"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.0116860859171837"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.2526346446814856"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.4879514974882826"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.119531453172401"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.0337748423703532"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.8388665496988663"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.7829929221869414"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.7729117882157297"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.6893548100607756"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.760054220262598"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.1363361771834912"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.0202910202124134"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.195256915684186"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.268910248693157"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.40865804454232"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.0051197559781366"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.1289416118133895"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.5853533289496209"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.927130220824634"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.425711353609846"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.008465197560401"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.50669565083076"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.41708157953909475"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.513726593414132"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.718421750615236"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.022052090227355"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.8170801956601834"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.95144106393846"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.1638308136230595"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.5212091111628028"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.2427159394468354"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-8.81225762962842"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.23068018532412626"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.4663920834476003"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.29863089163788"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-7.9909866577012885"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.7402024711789101"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.23160062365262912"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.803302375295443"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.9383638725310348"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.2456672899228076"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.397959150502384"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.136055257443691"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-8.925698152910808"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.4942308338380803"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.0757545810188827"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.096054666713889"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.6064476058865651"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.0861471681993127"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.7310787770286131"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.0593460099820962"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.9102323667573415"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.025349874713222142"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.0376245481321598"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.183427385183787"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.179540561600202"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.07496754144608975"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.9912085028305642"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.9167503114225695"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-8.821686312332167"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.306667220562595"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.165158623789531"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.969424621804422"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.0776733373745238"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.1759804339267372"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.6124931234636949"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.416285733775434"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-7.683002705977428"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.815308934245092"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.512753435298233"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.0202016117510007"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.0390418877523873"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.8923215589683835"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.8226074348527295"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.090902171601895"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-7.0121336737813795"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.5953848068911611"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.3129325575736583"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.562339013345674"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-8.616521434841978"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.5686922221803847"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.1644888983681323"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.3468510446457311"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-9.887918673476406"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.100123472361659"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.0264339740629636"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.2499549752012373"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.964734015358682"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.6237167173864941"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.275657225001008"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.0538883034344573"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.113699644224526"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.7092392006537684"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.49215453947914"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.9898153825444689"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.346851637315826"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.2618253019582513"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.08425574055050622"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.044005139949500616"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.5766459173554708"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.0992067858287857"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.16927602505268868"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.2952601016430467"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.183360180890192"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.742632349850739"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.9262707918037325"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.5196207015118155"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.17132889520448913"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.5976339030483402"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.6743597768073082"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.4699315839750517"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.714288033852259"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.5378199744987633"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.039294222480581"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.146752956982827"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.544192859988895"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.3972788164297736"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.0703503260949654"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.08233585244012576"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.2457350022266347"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.10537598263574388"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.3672700339486662"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.4370716034646787"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.6834770399250374"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.7332366349565227"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.178147083073387"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.8604999413139907"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.119929112220758"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.2990287596323382"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.7706518283926911"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.6258745865529272"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.7714559983265357"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.9292181429851505"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.5526685330002294"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.4330769167368762"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.034556326532769"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.5839476541966038"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.618605081376852"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.7113262457697028"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.1442291710395072"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.45778924067446436"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.0477272175197645"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.868617404842796"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.320397553327872"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.879195517036611"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.28881129868549904"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.3579176943750713"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.8212080119625629"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.2624499703058794"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.554969881589372"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.9615535349241076"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.676348495584767"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.4444595657478994"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.678934246274049"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.6817627284904182"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.1300326054362877"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.9659722674831528"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.8918532061933107"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.3071400183668538"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.893199808889209"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.5934655343222124"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.7219333382866278"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.0441225434974455"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.6180833296693216"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.0529647183534223"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.530646522665424"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.041603939140962"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.906883634062689"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.806897386529779"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.9060003411666293"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.4971709236623"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.988294184419126"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.19944265500910863"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.214083970119514"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.012131060725406"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.103557915309775"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.9683236806124196"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.3669579052987353"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.4206827225651315"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.6859224989955877"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.5548150480377814"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.121835341731316"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.57978946766502"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.548839902767005"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.1049468072771287"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.988854894337562"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.6973694196582185"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.6770996655244"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.1433937280251847"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.8692848883648407"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.27537552329568"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.06335614602963524"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.727253791880514"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.6729753100419389"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.2913715578255385"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.475331592650747"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.208314940742471"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.511541322125348"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.5432100601732546"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.10045877088112931"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.7853054251598328"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.92753016916111"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.543202948541364"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-8.460455917565627"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.37787790509290886"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.2481666369394055"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.6337028628714476"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.402678237969075"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.837858047669033"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.652545192994679"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.743560948923182"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.0343461042145954"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.38861847278270467"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.5187344630532085"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.0755131642032327"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.945305662890129"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.904391652366784"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.2123730353950213"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.235857441156686"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-7.5676990554765915"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.614154224499174"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.5907658222224081"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.6053563733838954"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.036878077004012"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.122991784352501"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.9841804741978466"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.957409316376452"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-8.60036604980567"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.0882302784826114"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.9228446739880294"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.7957017566809393"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-7.600618645392936"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.9360116827072735"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.918898321024465"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.8194052235845524"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.5960259055152335"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.837022918709252"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.140870295649483"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.2001526821832993"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.004716871021376079"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.6518778240709375"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.613522667318158"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.523690090011205"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.263639381565966"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.0216987442059962"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.462745543226249"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.19287057904659677"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-8.162980545835216"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.833575811394142"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.8867545535966643"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.9858009282124678"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.0635181437998753"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.06212663838971"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.457289325949952"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.7179709713932"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-9.46085958702903"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.4302951201509728"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.7906014221111588"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.3430370003195102"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.718056123006126"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.5649075178977414"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.9409805451656605"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.872448784977173"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.055778873561019"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.6918416637007745"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.361013795372109"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.4241917524729306"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.8084027696848235"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.2403835130940193"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.8031160218016624"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.45354984227680306"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.4358744581042178"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.4248146588406634"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.2822936652938255"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.9738223491563605"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.4221665758960036"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.4728073699407087"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.508340075071405"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.1069479293877338"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.33968709405691655"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.8467150616124401"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.6662650592608088"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.9290569103535834"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-8.066640268528516"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.0479055726357007"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.2762616400856865"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.2376445618099987"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-9.399615772139057"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.308292859319053"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.7200716237202136"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.693288166555631"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.3916159171359954"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.405863536455498"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.4067362801567405"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.708192839032437"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.716707085069145"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.3039814543672232"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.29049179714765894"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.2740426585503669"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-7.730285855000446"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.1656993945061966"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.908255890913495"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.4374977604548835"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.7216510716800126"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.93758524100054"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.600782669908797"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.0287289002406963"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.3325935750284152"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.7298480102030735"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.8268545984575046"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.7139405402602463"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-9.817022241310294"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.6855943496958865"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.5262872441934335"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.27328988882404204"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.97701535826946"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.989947672185334"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.35160626338322953"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.9121042182572783"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-7.438934588385861"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.660186543474069"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.900761085549488"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.0858933556621675"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.132508380359127"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.9475882467418604"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.803889309322083"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.0801125369805153"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.834778633202804"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.919791637610084"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.079063948920284"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.1689926547487035"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.7819929461223065"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.3552667942804817"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.383402434317752"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.2075593807178309"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.10782938932416464"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.3590759952636198"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.2647756106461276"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.34456544359305397"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.130271960884346"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.1305061164134615"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.9612811991552392"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.8359795746991736"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.748384350473551"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.480435320931857"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.2972512029020025"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.2942560805192179"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.0656570695410084"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.1700919949358246"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.698751459631715"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.404758186809495"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.646708483329715"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.835168622565268"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.3229657710139313"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.5535645479071793"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.3686496753097"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.5935891756672493"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.7694883013058157"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.7269633014258248"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-7.8743788805976855"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.6938643158084057"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.461653161992822"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.3642608458940924"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.525062037329289"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.7136264100820373"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.1384110214727055"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.501225546338297"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.6810045858568419"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.5521198400937113"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.9265833552297997"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.796593366748907"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.2079115789760575"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.1559687628509572"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.4170050746768692"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.1956774623069473"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.28932467901846337"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.5483662431401495"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.086348173123035"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.7056056498465146"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.9371642457200426"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.075176429745407"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.496031532649024"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.596955720349184"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.2837372163369682"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.381341519340519"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.014301331794234"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.2107129597429664"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-8.28019156219769"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.24377381676522258"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.623879203384503"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.241291595287545"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.120063165169926"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.3426007750114497"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.3657278305466454"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.7615055470002106"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.718432296101497"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.34678988999183"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.935882059653289"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.695624249303364"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.51118133902611"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.14007350023162"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.1413135829578778"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.747529299603624"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.239442865525575"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.281420766155871"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.0068310268651866"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.6042218914816209"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-9.051297005673952"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.504821936275217"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.369705455120372"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.297370672471264"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.518025691040907"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.5823476949383055"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.721743185372995"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.4031306938937018"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.930983515709202"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.23406589894997687"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.737415979741276"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.331575969408586"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.673118253976263"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.177289720478977"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.1309110415110175"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.5063597750216925"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.2225187616283915"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.1542148090113287"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.723049729225517"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.1391330033993334"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.299623102985084"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.1901449415197227"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.9365462460091128"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.7252699082325484"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-9.161114092776279"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.933421295612802"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.318727106648873"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.1794695954176112"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-7.088685759527143"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.4894614151505685"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.4997877421438555"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.41861305281917005"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.0523169056227015"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.41997359578272775"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.1138034569524806"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.929755525192351"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.2328559665037844"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.1326295928550802"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.9140717498731235"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.8219676781643657"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.2287933080236861"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.3010443923154726"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.006008749409022"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.833293036215709"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.2545574968563313"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.8594050015893178"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.731564894337938"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.3987237957895835"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.545954915151691"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.294844765650561"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.771676830787411"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.497979596546991"/>
      </enumeratedValueSet>
    </subExperiment>
  </experiment>
  <experiment name="ETH test" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>(ticks = 600) or ((min price-record) = 0) or ((max price-record) &gt; 10000)</exitCondition>
    <metric>token-price</metric>
    <metric>last price-record</metric>
    <metric>token-trade-volume</metric>
    <metric>user-base</metric>
    <metric>platform-productivity</metric>
    <metric>unlocked-token-supply</metric>
    <metric>seed</metric>
    <enumeratedValueSet variable="intra-period-trading-rounds">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-optimization-step-size">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-token-price">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-user-base">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="token-unlock-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="risk-free-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="annual-discount-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="annual-per-user-revenue">
      <value value="23.67"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="participation-cost">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-return-belief">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-window-length">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-window-length">
      <value value="365"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-token-supply">
      <value value="5201438"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="supply-inflection-ticks">
      <value value="239.20867425"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pre-token-issue-rate">
      <value value="6234.13173191"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pre-supply_doubling_tick_length">
      <value value="54592.74306914"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="post-token-issue-rate">
      <value value="5327.49443937"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="post-supply_halving_tick_length">
      <value value="324.0944231"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="supply-cap">
      <value value="100000000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="supplied-via-reward">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="supplied-via-exchange">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-serviceable-available-market">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="growth-inflection-ticks">
      <value value="116.579825"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pre-market-growth-rate">
      <value value="8.31137145"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pre-inflection-market-doubling-ticks">
      <value value="992.567141"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="post-market-growth-rate">
      <value value="60.3736513"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="post-inflection-market-halving-ticks">
      <value value="9999.94059"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-from">
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schedule-horizon">
      <value value="600"/>
    </enumeratedValueSet>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-7.504231107113683"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.13416845233391506"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.3093008170229856"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.740070258225377"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-9.76072409063193"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.4329592770861446"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.1826243116653934"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.614541153008374"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.11617775889508053"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.666736871936326"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.896933108348359"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.4649579874971685"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.670125542140799"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.069444884101056"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.949266063292939"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.9361275167327143"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.6493394835275677"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.054915516320551"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.3031718888450583"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.4742558025314556"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.5902258713623798"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.8257961034374848"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.273979373484485"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.7200608250028084"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.259411871069306"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.1268269858563196"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.2703870321426964"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.1475075826680818"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.216662297798327"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.300460419517515"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.29621957745111005"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.2666663078211323"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.4876148644028326"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.5238437714052564"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.167990571426386"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.787738775734197"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-8.746832311172218"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.783334881561407"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.063459548152608"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.0579093562528934"/>
      </enumeratedValueSet>
    </subExperiment>
  </experiment>
  <experiment name="ETH2" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>(ticks = 600) or ((min price-record) &lt; 1e-5) or ((max price-record) &gt; 10000)</exitCondition>
    <metric>token-price</metric>
    <metric>last price-record</metric>
    <metric>token-trade-volume</metric>
    <metric>user-base</metric>
    <metric>platform-productivity</metric>
    <metric>unlocked-token-supply</metric>
    <metric>seed</metric>
    <enumeratedValueSet variable="intra-period-trading-rounds">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-optimization-step-size">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-token-price">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-user-base">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="token-unlock-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="risk-free-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="annual-discount-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="annual-per-user-revenue">
      <value value="23.67"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="participation-cost">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-return-belief">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-window-length">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-window-length">
      <value value="365"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-token-supply">
      <value value="5201438"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="supply-inflection-ticks">
      <value value="239.20867425"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pre-token-issue-rate">
      <value value="6234.13173191"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pre-supply_doubling_tick_length">
      <value value="54592.74306914"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="post-token-issue-rate">
      <value value="5327.49443937"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="post-supply_halving_tick_length">
      <value value="324.0944231"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="supply-cap">
      <value value="100000000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="supplied-via-reward">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="supplied-via-exchange">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-serviceable-available-market">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="growth-inflection-ticks">
      <value value="116.579825"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pre-market-growth-rate">
      <value value="8.31137145"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pre-inflection-market-doubling-ticks">
      <value value="992.567141"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="post-market-growth-rate">
      <value value="60.3736513"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="post-inflection-market-halving-ticks">
      <value value="9999.94059"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-from">
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schedule-horizon">
      <value value="600"/>
    </enumeratedValueSet>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="5.592448653618576"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.37718037943871785"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.8908736646886375"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.308789987947578"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.099183479749645"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.251877834395441"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.0264146465563324"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.44839335946884906"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.5973532665932986"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.226740210990224"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.821131878605753"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.060695005757130605"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.006288735127691"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.8633333075960454"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.3341309589114534"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.5887836339328332"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.5064648013054724"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.2701675504288557"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.2049726623598978"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.162715131214077"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.22681901382213487"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.365097838070257"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.0700574913801337"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.729011626099533"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.2217078056252575"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.724787544764756"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.2701916868860845"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.7136992387864268"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.4998692743614654"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.3374088014765064"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.2033256979217235"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.0427041531372091"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.2421156603971551"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.48033350155708743"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.7837441051776883"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.6192629976006593"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.0333886501544636"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.5212010745606057"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.319879601597116"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.409070211175748"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.087365777713179"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.0681007961405005"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="-0.3663987028683571"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.113315398894563"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.71189078153748"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.2413048066326007"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.681224555204381"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.2245800769179619"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.0952663832828669"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.2819280814101033"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.3079176778906287"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.3601951680197293"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.8423909475867415"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-5.538172421508518"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.7508865849359387"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.0214051294276225"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.022907459784239914"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.2897656249346987"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.5160760791868277"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.9952665038876487"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.821249074767075"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.8998750356014362"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.9134631328350973"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.7154261505494975"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.7364281193638"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.3470318612902692"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.727447104506612"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.783023935872356"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.224570260741252"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.8045200658298541"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.9295062020376812"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.028141942265182185"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.05407605422319317"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.05924381626215647"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.7596393390628333"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.5372307635808493"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.783523449669258"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.007318025045537"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="6.395758605625234"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.483648425973964"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.33161722466792304"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.495586408650083"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.536207884664047"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.540484756041702"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.595263783222505"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.1431143699409008"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.9896821855801325"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.9375567459200107"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.9409335365839584"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.2366027371306494"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.5632788344782882"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.509740009741177"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.752539346457683"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.094732633117675"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.282399106611109"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.25089847061459425"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.05906400812915927"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.4194234060384838"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.513296098966759"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.856952299123373"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.1644806738560263"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.4373088167351833"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="-0.2664625237884666"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.8344751561914445"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.2624013690548303"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.5319715993331258"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.426333871869406"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.429875747957828"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.45778334325120396"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.616837949678696"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.527558609658112"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.0936419384668077"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.6070907040611025"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-5.157355535511678"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.8602978703394026"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.4378469498874775"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.489934501523712"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.1269790180961203"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.592337106861434"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.0714934941983505"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.19958480886555344"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.4873939422368818"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.737361062420799"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.116654546089085"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.7500418148927234"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.7578846936668826"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.529719717351967"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.444892428014209"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.3574303467426845"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.181864829376686"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.969636737818516"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.9690986679849805"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.5621156786232546"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.598852147601256"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.0595310245493383"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.46042241040256"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.7691250854723397"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.4036194573069378"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.847309092607368"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.4577349513679674"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.8494347015386405"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.9450619628756827"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.2450908619932437"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.8127057513482305"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.6664389561054982"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.1568151582807324"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.15433386674866068"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.0173209930935319"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.5513445521617018"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.6852577072081365"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.3989907881599564"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.894684546084272"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.386632578718174"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.6331375626786337"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.4205564357549605"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.0092833145123317"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.5308827958616211"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-4.549789991629633"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.3189058894087644"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.81877968898187"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.758084247792384"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.32373261054719293"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.8105462898316724"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.7723895485210344"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.8764937585161707"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.2558419787445492"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.66474501908938"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.8842654581620177"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.1064184032154043"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.479746749581475"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.567729461634758"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.1394600981957512"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.165864103404854"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.19299252466708472"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.004053246609825"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.054202187022528"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.1805124088088395"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="8.505369900746608"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.110453520149262"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.7674190610448051"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.307416573945626"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.088460634023182"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.674361284711479"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.7845463115556026"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.5318843747636077"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.169167851528398"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.238369379023662"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.8324134449335048"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.402246020138343"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.9062073401641408"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.7793258193231933"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.2586197148049916"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.6643298378552345"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.162914971572959"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.22865348354544"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.3006222959093854"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.11261689581887557"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.385376196833456"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.917271260275778"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.7405037854734084"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.6407166278601872"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.19105725976524046"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.979686772185488"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.9505706594750665"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.7671977207837606"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.4002693356233866"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.9277198661335877"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.8538590261605663"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.168645735456683"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.5876988278727435"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="6.391473047462833"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.938186533203724"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.5022681837116727"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.82333310730573"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.823958351755415"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.4073753835512184"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.304011060510133"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.292137573916703"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.262340692886267"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.1861977968614745"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.580988673984745"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.27982908658465955"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="6.517185875785523"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.1268466202854204"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.6458850449319136"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.5577517851871217"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.1892842922860485"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.5372483934771437"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.847939200963414"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.246232600163811"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="6.249399580651207"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.4657608459314626"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.47298764583741426"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.0233642443925015"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="6.979787170046274"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.5151796353653779"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.532840967055593"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.543435715775972"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.058632482475128"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.7191778634637644"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.278646421593409"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.8220804564740467"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.5432816428616807"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.3170169812683397"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.888789178812574"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.1337697874821955"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.603680482445629"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.6826591251077363"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.080064385855594"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.6609020294614825"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.4627510883468995"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.672260737089341"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.5200385045687821"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.22977332157178842"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.0106849986488164"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.6099766799001745"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.6010983648785584"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.9185778280631911"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.327736810597301"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.556514375809108"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.016012701954262187"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.8044415609251727"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.316675452121653"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.383691672947315"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.390656340330085"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.3247872002022407"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.5499457772930525"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.4067566002435394"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.6318702753284"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.354181377967337"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.339731200249076"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.556098128082766"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.5557145416762792"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.474804858655238"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.9946470309459352"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.5110007137045978"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.061650316577381"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.797555389614806"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.7922416586930767"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.9939187003259433"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.01692226937758301"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.5829403280429353"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.219945447561652"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.898515614289314"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.17941529023419478"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.2719974587963585"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.1482267502793722"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.711639498944852"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.07251428052948738"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.333144242173139"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.1218731957495964"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.890317114192955"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.3005645026292645"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.0855713180893596"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.229919173109453"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.0838997442588822"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.2681751832123331"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.6503791098405265"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.678514722193659"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.9404315806697374"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.6710895464337403"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.788370147479343"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.4915353096942234"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.056723578595535"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.10828619507393511"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.7123979325270127"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.276897301391465"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.3798484110419675"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.29786836436502484"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.36495895758461216"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.151511325883235"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.0942806811446895"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.2577610662105907"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.9439655945464862"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.120143676839546"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.782036887212275"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.708879470099756"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.7419802987230368"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.015119628644827"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.050148766904046"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.4237710870564624"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.317802913428721"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.564812848587134"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.8459387282121753"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.070638637864322"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.8944756765497157"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.6010166433158326"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.904949538914222"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.784006433488141"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.1342646431338228"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.415139885129104"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.9779928086427683"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.8138284088414425"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.6335155589741928"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.109833000429804"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.954197780971085"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.927196085044683"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.44608992373033085"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.059487577820351"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.349006071930449"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.5896127870822325"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.3851145569498255"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.7576923297354963"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.6791573618923388"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.9052098538183921"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.5055634406757397"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.1460901412735724"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.195690120502204"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.013694963191642762"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.0277875331026034"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.0610249770250135"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.804145542316065"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.6200112550642043"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.8966328373127963"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="8.442793942733983"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.108717501394727"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.5466993345887854"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.955676984983369"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.265342855724096"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.296335606657157"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.1290903167707587"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.5041245962250458"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.0855703094371005"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.5470659775626583"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.655357824673686"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.0608399683645793"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.725747402811087"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.951670577342779"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.5548463078377335"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.1412597595901306"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.204686573714354"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.6371027831727"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.319685236738565"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.0709069973244723"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.6370506079749552"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.913083185659023"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.5737826799159924"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.0988876068279367"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.239094073202114"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.420559649280054"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.552028265687742"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.8831441344255175"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.019976675566064"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.0932848600374707"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.0603171852923854"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.0113537932973253"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.342256973819762"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.248793284069155"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.14112855528925072"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.6344462128097512"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.201963409886367"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.6769158718130983"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.3272290668506326"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-4.491206629223373"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.9812502693912046"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.9354335622853234"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.665550108307672"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.9353194804260241"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.989770023116147"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.321129555445563"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.9955097432107927"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.2581751279397473"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.8641278126096568"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.214684531576413"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.11001377379843014"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.3374117795003575"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.836372989535892"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.3251805369581042"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.3674188211466225"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.300732213504105"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.324630756218443"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.0289945892103223"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.9841717227285254"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.381576381699039"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.450655125472892"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.8281012379193948"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.256297303594908"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.7067899694333344"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.733413388015517"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.3881224469311642"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.6656231480900523"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.11602174226923445"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.49064697641775"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.043095067627890726"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.1351465385935826"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.976878908627136"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.8842328526772327"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.11899166787685056"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.808949548677137"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.490617399656563"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.456630050929683"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.262049120688249"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.7994741229936393"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.4117838453272564"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.0979932289708545"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.8043977423001611"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.3671072083986582"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.2100225817736914"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.716257656712561"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.088269259041552"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.9371974875858007"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.0113407772817915"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.1794554682692113"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.3178339905063434"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.381391589504382"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.4785586813736231"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.8158084574314"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.4659794371284591"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.918295351507881"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.7505992243011352"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.934420279101067"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.5129685210061898"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.422268883694562"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.6032289724168673"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.083996925988888"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.1338195585461106"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.769054548079798"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.194451716425389"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.838402283973575"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.3531544043794741"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.6927888248943073"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.992061419741554"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.995803715567114"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.27337737902657433"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.864004957125651"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.354072641643895"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="7.428646878455494"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.932446405996801"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.4002410506378906"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.34335845294225"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="6.825307405120418"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.18150864688400647"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.6000872178101717"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="6.433704314093971"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.6406541534169286"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.978965002154872"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.9996253398149537"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.942133079204323"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.008154040231136"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.8325951856890113"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.9950227034819448"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.8938570625087628"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.717970417670908"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.1251163886190447"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.383465938393898"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.116307889812847"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.2315212867010565"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.804149994086893"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.523534883712738"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.351419872885969"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.3644878225790005"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.2181520527419893"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.891054842665448"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.2480885356383054"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.1877254316781665"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.317089636324758"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.4397256229919917"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.8891383056969662"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.124236905433699"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.430146167851455"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.02505733468853788"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.9848343278277896"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.806397888571403"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.1041431607866903"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.543807499071135"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.3797621506352396"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.59771948161033"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.790079165257393"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.723832500799161"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.18316335959062363"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.0756260168403875"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.434016765023166"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.934664558912489"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.1976984997718068"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.3807213164329166"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.8919414799998417"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.965680790485826"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.644109013288772"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.789251094093111"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.7251158770125548"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.8910416051397652"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.5621468728040654"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.9745637554811"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.028738137343438"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.08832194464786447"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.600910119598021"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.0386623017511827"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.997056525659378"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.7578948689128415"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.355917865336549"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.076253415819549"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.764658661642913"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.3852675608856115"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.668108814526418"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.23753834560246"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.4489789454142232"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.8432404608586004"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.7895755385616476"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.9432383913396347"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.6577573064309044"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.9836811224057453"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.3973279674819254"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.335469412705093"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.145783575801912"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.1695859724270683"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.5582498545071783"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.585595964997178"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.9751887808165"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.827187082368294"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.9010155111310458"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.9839285825542059"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.9043326685195598"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.1861084870490357"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.4377743222358665"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.921908159692318"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.162119071830037"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.024402877151847413"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.28731410275922337"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.670633525096418"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="7.0441688392208714"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.655838313927371"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.6825056702829753"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.8722229937269281"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.720898699014389"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.061456677248258"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.4206353614008862"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.621379978689653"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.924529291526869"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.6577966769031796"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.8626774066202638"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.186717679984177"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.014438121927445646"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.275474604168456"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.9342160588608641"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.057855069984454"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.3546667201975942"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.0560250635370556"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.966453127230591"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.6479277610149365"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.873228266949222"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.1724573117009793"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.4256115329424848"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="-0.31999997824723136"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.0922162183525694"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.6448951737238117"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.8895367348809147"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.4060453169622744"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.050203746600618"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.982300381108515"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.8082336729651132"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.1210018348494186"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.1209312961322624"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.076988581481638"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.791018944614614"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.144348108726488"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.1581490151648954"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.481346311475388"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.4418099769132553"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.2845117256450891"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.7999967131103505"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.03902580667641187"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.47254258678839"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.111815132248889"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.8307982763278317"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.5621018958961645"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.08255591202976931"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.65067866790546"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.5880341572030061"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.5836352684160979"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.1392992078535606"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.4077857102042106"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.31106508210951134"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.0757447694943159"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.9602363106203167"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.0781300847807533"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.691833242468685"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.6057678449802555"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.289318157103656"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.893517317782799"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.2214459691223698"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.4243597282524494"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.08896209714928283"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.762149661387595"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.881450556465076"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.17027162438010324"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.6214185593983643"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.441572931465618"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.9286976151343733"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.4747381162163853"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.3982344263398793"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.21057117333491027"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.169236931534705"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.078409310922619"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.8787159565877022"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.016448918760483"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.2153590470944449"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.0948340959174393"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.24996041754931508"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.232531414907124"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.3514039214211879"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.2696723909104213"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-5.686130267580232"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.826752411137755"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.31531816261323"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.439798427471123"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.4066184269344126"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.023239352200654"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.7128895215707343"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.75539010894332"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.7385341128642533"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.54586902927797"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.5832644283659856"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.8118044957320909"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.9688992839839219"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.285731255931695"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.169249644215037"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.383281266987121"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.817314685686336"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.919630735602116"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.0482227059238034"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.90419996830975"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.6899758968496021"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.351610389387179"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.7046272898981347"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.7027057189762531"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.8647991320881268"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.7338214596845662"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.5451176909333313"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.619919469090763"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.46317115288900235"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.491766656667985"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.7660782706207359"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.7011873273908082"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-4.622644511705109"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="6.182907960118595"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.5177056394103823"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.4436548256529145"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-5.979809795193606"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.7502917658338983"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.342987681283275"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.3893720249577381"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.261566413496943"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.1100734476100045"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.2863570100568307"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.0361081647943513"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.3132520664747442"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.0135815262390144"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.9333867619089333"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.6021717827530848"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.5947530319267402"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.2525142772712443"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.596528835700977"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.6725723171570777"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.4308669366022895"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.300002218351642"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.036201124118025"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="5.404142156224685"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.782660278619478"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.531757149911956"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.1515509354107465"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.5308593847676057"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-7.094820200804609"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.8555416086612404"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.4792093750662367"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.8583298507534733"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-6.592192164278476"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.261120759142242"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.3781400835881263"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="5.808900676185532"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.1887522582165246"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.564664757715492"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.8095403845276445"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.68940797312467"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.652407495698334"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.0915112463124004"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.6736692728263356"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.137828588794221"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.25974694886027994"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.5390815391816686"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.0005458017469837"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.3796580677084673"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.35854675785866275"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.6194569105353"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.0791745066562317"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.16172176275336891"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.33827405451765824"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.9552513464084802"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.7040418456029207"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.793297914238677"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.881332001344661"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="-0.26569704682468354"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.3803361520084585"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.5111459398569806"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.9922190713353519"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.3772204518558049"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.8979007511168526"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.2772486079430514"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.09419360441633096"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.8945386692364597"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.3771368648195306"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.7273172096587954"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.14693767533551"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.951692720275923"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.23158983851778114"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.29505009743314"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.26147129619181186"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.025208987466963"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.434670398071918"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.8225078256697438"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.4679024210065847"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="-0.7001610738862554"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.282482215481544"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.9440241062236452"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.686769761045298"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.666970596477867"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.8979290818330137"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.09122882314951664"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.941008228520641"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.9512918458190747"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.2314606358856284"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.34984689245490763"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.460607720537271"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.6868028489093484"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.8358093693673541"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.853584031173404"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.5093467961270277"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.1667423284541658"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.308764720769451"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.124737240655243"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.6819166468120663"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.3807028256581277"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.5687991916608834"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.8425310986667736"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.378636734455419"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.4124686058003295"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.455811303685484"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.9801951398062552"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.10724571109839132"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.9850590651455633"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.5509778431225174"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.3156191952458824"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.7613205331910349"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.1430677031067789"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.2852309060899794"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.665166451031939"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.743719133674223"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.0229661548810705"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.1577503039320467"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.280555347698741"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.5755352488274406"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.6194553941718746"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.3105547016712805"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.275389106224418"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.4664979955670234"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="-0.07180854778684598"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.3623131683389285"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.982966240793824"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.1257487129314225"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.4536868588342693"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.08127311848625207"/>
      </enumeratedValueSet>
    </subExperiment>
  </experiment>
  <experiment name="ETH3" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>(ticks = 600) or ((min price-record) &lt; 1e-5) or ((max price-record) &gt; 10000)</exitCondition>
    <metric>token-price</metric>
    <metric>last price-record</metric>
    <metric>token-trade-volume</metric>
    <metric>user-base</metric>
    <metric>platform-productivity</metric>
    <metric>unlocked-token-supply</metric>
    <metric>seed</metric>
    <enumeratedValueSet variable="intra-period-trading-rounds">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-optimization-step-size">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-token-price">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-user-base">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="token-unlock-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="risk-free-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="annual-discount-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="annual-per-user-revenue">
      <value value="23.67"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="participation-cost">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-return-belief">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-window-length">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-window-length">
      <value value="365"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-token-supply">
      <value value="5201438"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="supply-inflection-ticks">
      <value value="239.20867425"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pre-token-issue-rate">
      <value value="6234.13173191"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pre-supply_doubling_tick_length">
      <value value="54592.74306914"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="post-token-issue-rate">
      <value value="5327.49443937"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="post-supply_halving_tick_length">
      <value value="324.0944231"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="supply-cap">
      <value value="100000000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="supplied-via-reward">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="supplied-via-exchange">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-serviceable-available-market">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="growth-inflection-ticks">
      <value value="116.579825"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pre-market-growth-rate">
      <value value="8.31137145"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pre-inflection-market-doubling-ticks">
      <value value="992.567141"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="post-market-growth-rate">
      <value value="60.3736513"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="post-inflection-market-halving-ticks">
      <value value="9999.94059"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-from">
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schedule-horizon">
      <value value="600"/>
    </enumeratedValueSet>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.747652244384091"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="6.446267747414704"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.9725686488689476"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.5646339314513193"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.7036985909948477"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.36628272484369384"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.2627733687668852"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.5493772185289886"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.0067240590245587"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.44705925960147797"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.3601739095671763"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.6581744701506613"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.6330477484597792"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.5910536805529243"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.12703794448301"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.29715249756079765"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.12401179359537812"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.21052552835024496"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.6147479544390646"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.170899341583285"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.24262384320897956"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.5447881512150374"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.332027774271745"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.001196308258261225"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.1664993224872653"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.565949082038079"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.1142161470667293"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.22816426660245"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.821841921907936"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.5472204072380786"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.6554109193974083"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.0802388261694749"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.02361086696069481"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.561278875322229"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.115784360792339"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.8897693167307277"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.9476706376608486"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.018700328123688048"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.85218494487823"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.21946970050848025"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.226613243042797"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.0035673336935866384"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.41268512221337"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.09928584915596106"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.6386818799299394"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.6280829448160077"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.9531224798294453"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.07596236948868029"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.53751920624515"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-5.590820545753312"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.0745275981989035"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.5845718276091159"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.7553980925310904"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.8788169386002425"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.2789994035263943"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.0141562826598205"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.6028249957967304"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.1643633074251096"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.7975323456206405"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.8871472548603597"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.4848479209784484"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.64937192795202"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.070214361800937"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.899899634954266"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.8428865812312245"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.098405870480592"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.8105813091979328"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.8496851730926863"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.252622098130666"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.686595686578427"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.2976050584658694"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.8261357364853137"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.866334923557523"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.449854800519647"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.6746937446210186"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.0393665147074982"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.0752867848802884"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.689751966301471"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.904653097154778"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.0012391804998857"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.6660587495090406"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.165460344835155"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.5985631212888034"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.157786245333468"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.790681200503514"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.4258116522810189"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.4766072451260044"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.6831285929571043"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.884156655459791"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.8204281514426943"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.6474342810504874"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.9075972326411463"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.6206309230463996"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.09652067239090112"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.2408019789117184"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.7287491584175703"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.1281691064218355"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.976885080154927"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.344122704988818"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.706145078729936"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.9555133791141062"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.386249480678736"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.7786511806121799"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.248976429841065"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.1812973582515669"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.5120869383609463"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.715870903132152"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.441476123017686"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.686871410559388"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.239927229317277"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.2832595774545026"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.374592337841"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.8618465877140982"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.6021977297928434"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.943042054083948"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.494030783450977"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.5609445236262154"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.6813191889804591"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.4256277249017306"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.755792180447882"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.1074254819719975"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.3731204127182033"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.06528635657236"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.2795608614042688"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.996964150377591"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.334036240257973"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.473928922827279"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.151303711032174"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.423314895556853"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.3859833175099372"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.7686598956370143"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.946486601260346"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.26310293907845317"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.7116044500449483"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.094566022188384"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.3763018624145746"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-7.01207854842229"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.8352980933662897"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.3037872612570907"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.5328087425264334"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.255380027005736"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.38663439226053464"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="6.03192593397209"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.426201082267635"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.092835336697593"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.21337560967273"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.528653972781447"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.100172856331104"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.5739086008543564"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="6.52743336412188"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.569348961093924"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.601766610485754"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.9566239936432894"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="7.390549469256546"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.687093788602809"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.054188337020004"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.077169046046278"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.027237341770294"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.2207625118849406"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.2701405296122985"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="5.7578811646386185"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-6.251608930525297"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.145258549325363"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.96173272249716"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.789421432618175"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-15.503462480966096"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.1860396239561615"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.742613403183575"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.656272736767818"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-5.7553576290311526"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.925810445101557"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.4921641091623399"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.6559334166399573"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-8.755697415668308"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.1146261064316594"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.8563813048856286"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="6.317761566628975"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.592185150584077"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.781816600614869"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.41420893371748"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.3624595509135928"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-5.361475718829656"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.969303683717792"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.4414341917847038"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.47480149209570643"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-6.507505405986643"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.1259160523473666"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.847238403303235"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.5628370367792326"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-10.930267949880019"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.881463266358935"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.819322803606092"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.3545792861963846"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.8262873534602173"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.807286612928763"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.354000370345694"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.3136189465445036"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-13.141309733942883"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.9461534742303246"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.219158461734569"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.3758179196486024"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-9.29211947951239"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.231283678472707"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.636582907939422"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.0563341842571474"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.995603375438668"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.194134297504076"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.471087610350244"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.6976787943985894"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-4.121318286732858"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.8907298420905327"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.191977259374551"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.234973953261105"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-5.833370307940904"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.763480966575038"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.572863464608502"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.7316321867769497"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-6.328687043493999"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.8033905908805732"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.189382422374632"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.7217957568962365"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-6.296746175423898"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.1703238195530288"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.3576883462416895"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.9199184970837515"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-6.9753139026937365"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.9190634741110246"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.792575922207112"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.9544575645405959"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-8.630096939691123"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.3401762335325214"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.6068163900008328"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.845208502750528"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.831102325061176"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.4648803346133983"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.0810339993111375"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.027791400773823"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.162461433555491"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.487411759585703"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.257366691067523"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.1136777008666767"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.419160274489686"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.0529240645882885"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.8919480971420943"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.5340279481210533"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.714106236407334"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.32731038584489625"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.44873047493483"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.16590195637446303"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.2598722882239985"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.38870460039177"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.563647013918618"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.37462185151300953"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.4035137424011332"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.7683800455658027"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.2707806346097137"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.6649763368275665"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.7252579187624537"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.126039873010604"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.8395475355604882"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="6.356851420637785"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.270599845928109"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.7951452903187834"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.4450512937342821"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.6990531422155767"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.09626316337376029"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.6367358890101937"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.560387306614125"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.371684747574485"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.939451784338808"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.3932342521900882"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.2453291308005578"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.999380206176394"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.670671079190474"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.7367349598328845"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.6081881871725994"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.8540919204800548"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.6952914239884875"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.3046287381222452"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.8058527037824996"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.5873123233995926"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.581167925005689"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.105581744822592"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.4540618806323857"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.3133767807805408"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.065044509048649"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.412181471085238"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.8418283088617082"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.46620720030586016"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.763976918056967"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.7986650282644807"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.8486283266083607"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.04014395100193724"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.4408302569929146"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.8672745876594994"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.649045639614208"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.9929013184161137"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.6607653439881593"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.172515285506621"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.8090275897399173"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.8989162029971605"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.986926511706653"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.3635328923490713"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.5362831710362994"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.457099110005637"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.3006975472330407"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.0831127904971534"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.4294544899464157"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.8924966221412394"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.47047748644591"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.157976704738387"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.8738154348664406"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.669949465350049"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.01355012100523"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.438634487775378"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.3575087363650495"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.132489820657688"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.7525093104161201"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.103108367309315"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.0643838027011636"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.3438460070878704"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="6.006517100196312"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.259203427463926"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.767574344161811"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.2682619247848415"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.587273575150684"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.6955504090297584"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.277785246190837"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.0479496892951128"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.230764775884616"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="6.179135281420317"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.8114360698521565"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.622275054936732"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.4813216466580021"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.8462528250416113"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.044576507282186206"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.45900392498067655"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.3186052121839884"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.4498321734386943"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.0728014839034152"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.2039828322451145"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.182978578497833"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="7.639266415414951"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.8871620955486299"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.4230172076797496"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="6.196369756610055"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.118817927346031"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.377099583256666"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.1977408755119154"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="6.381490281729915"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.077471651540119"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.03344473542351"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.517856685643995"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.6222559797297693"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.61439056835589"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.1697083270926307"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.0153999671916347"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.076272607228805"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.780270305048659"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.157155836165886"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.4717909526887807"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.37228168334490785"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="7.616670904340804"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.3497769058032425"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.260968851185582"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.4544866804271983"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.682690380544355"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.455372676070137"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.2808176628945662"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.7655630009221452"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="6.438789324480843"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.309124577207134"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.983780108978683"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.5434108484646383"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.033483013645184"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.2002094340121614"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.4173522859453622"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.1819059172695607"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="6.330070614516079"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.7867660205090612"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.3711875748533595"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.266785633643966"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.053325901791285"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.543144610511509"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.49733540142634"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.6514263888624185"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="7.25695316475915"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.15260370217896302"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.474982581945281"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.6222333210672568"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.774003770258857"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.2615349588809535"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.155628493619469"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.702820544577221"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.682544958656262"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.63557297170567"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.1952566243334084"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.01140760328422"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.360488232556614"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.4137039628303003"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.312750042972039"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.33657385263083783"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.375076722339649"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.786204912237725"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.3383355842998109"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.8536461744301471"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.765048903616013"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.565187005197701"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.22559378948882503"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.5301363406008397"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="-0.16336329356798673"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.1706501817918142"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.9372410066723231"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.4530445943809669"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.048555171331723"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.9409132793442954"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.28903755947439613"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-4.24572365568302"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.026882425692428"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.126017302494722"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.44257495239447"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.254894087802652"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.001573338461972"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.2342254812706703"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.03280807253084567"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.145533164876459"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.22933683640058"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.845320476452778"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="5.153904291338409"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.6234765886102329"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.985703741998115"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.5471470251208246"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.069009834981034"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.7448917016554912"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.08981302342158992"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.1558135526013618"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.8212939400124801"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-6.09095090580943"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="-0.9109978473461839"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.6983323861207835"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.7722667500241323"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.280492745139867"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.1504823160171163"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.9245954199509578"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.2629897167260875"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.520700575150452"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.2250271847884866"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.466124590992812"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.08734315827672051"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.4068951199274577"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.0710411570282985"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.707534311715237"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.1058071302205714"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.858048745194678"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.5141156000478224"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.712295602030503"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.0619993471997837"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-4.738282806682842"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.5611240434003175"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.3772105680120825"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.5604083874818817"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.583165749632239"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.9689375812894823"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.2902285628848356"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.6086094083982647"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="7.851069684579816"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.011969424898775"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.5765009280515585"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.2617168039869433"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.307970010741847"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.8524108001568758"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.0298766881618482"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.2509810891490316"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.5844195059271861"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.2006078761594474"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.047002773674089"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="5.138352696315489"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-4.922937370625781"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.5474771218528112"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.403498273808303"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.9623438460436935"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.8690419077166781"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.07979864859221486"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.81080616172338"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.273464576641412"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.320666879682641"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.3400461449897767"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.854720117533817"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.16480840481029"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.991278350582632"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.6846990420680381"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.61594575906426"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.98466914429538"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.2686154118534079"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.21379364583424465"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.8912794945277602"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.162023747515313"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.6708762847025443"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.4437289514215632"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.558465923182611"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.575894198476087"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.6784636072361017"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.65222536818731"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.701542790928194"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.4241662594789739"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.722492862663207"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.8506840900420025"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.7629820667654292"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.782923322239336"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.233520314170438"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.1418717893389816"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.747954447989089"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.070079379034821"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.26463112620584117"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.139000918955475"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.06803768322667"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.18256022902952"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.690153066699846"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.9715661360550396"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.7245634387257638"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.035424889488555"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.7811365547388371"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.202807945756379"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.4002051863881024"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.6940175478179522"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.340025434820648"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.8755559251703766"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.658550234445063"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.076791745752152"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.435730764261011"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.5077871207767006"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.450534481271418"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.282243498882206"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.011670375244973"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.87353922793432"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.9630477884737507"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.851071656426458"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.4830580690582544"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.6512303749349204"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.0792623516762645"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.0099503394328875"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.921363499188985"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.7406925164814675"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.747280946313004"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.83672309789921"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.9902364724544364"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.5435122540172674"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.8915777094671937"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.4113915197665947"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.096008857527984"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.8464140813413847"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.20633584791018755"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.4030842644821595"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.522851195798355"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.9904106172937375"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.982380803321497"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.015605389974339"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.0620994731281734"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.31658381832848304"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.659223627969924"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.3299305402797246"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.986570828142923"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.13417329475426465"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.6753013965930743"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.4110531518217876"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-6.388272474983824"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.32263015284880736"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.184001935190577"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.40802030830141445"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-6.83830535847398"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.127184863155855"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.6475440830623693"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.37952996827660834"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="7.252132350205074"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.131406356065513"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.1992430163316208"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.5647110150861187"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.228821059526657"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.4948486869784188"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.3190743207844866"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.148413630171993"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.2631665307408566"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.7732894657417273"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.2892549838645033"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.5658951250786735"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-4.517792587148373"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.4041955965158683"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.3035869406042835"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.1922452696028367"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.0199217487324277"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.664527249361532"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.80470728276221"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.41180745189610957"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.081327272528965"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.9733066234079606"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.0738394271603293"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="5.354630764623313"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.4515882026142752"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.0445568098584197"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.491088030394668"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.1994592626082974"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.5799442106397121"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.48927539673462395"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.933620045109717"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.8236489584698363"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.7232167032016936"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.8713644954784565"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.7515916180226627"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.1388726158156657"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.240012190195188"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.600100531774526"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.4544398917609938"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.064928482955274"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.46536201188341053"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.2822044209536487"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.043579695516731"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.46882747123208757"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.1646352743534214"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.0980346970371304"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.0748260786026305"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.656568010409413"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.494778823641536"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.04374731387512121"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.6951770211105908"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.258315815113693"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.27837505214479197"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.7338646380174358"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.529287600546147"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.5641734353727652"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.116987317728346"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="-0.32420817390262346"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.858862628555938"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.2189038401816762"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.9245924171477726"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.7240208504700276"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.4605002851906672"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.4893610777474637"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.7746877838214226"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.5543522068149342"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.521091750419308"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.9334344735480893"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-4.498689274326093"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.3140101613087818"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.210207884721499"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.7983102382103677"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.160801401162823"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.1638107980398624"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.7485596790569806"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.070509414332159"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-5.060769188455006"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.496582714822166"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.228217314954623"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.69424525786072"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-4.983431794248082"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.775906523393319"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.7943874114082936"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.15334152536793555"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-4.251220640340135"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.1597191037632713"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.7926670318816633"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.8420942282124717"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-4.707252991165071"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.2172762979141085"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.187015809431405"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.6721016211872444"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.9535272386080633"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.4484336408790153"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.7403169239927956"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.609105039018339"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.4182614813207417"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.7582498624331544"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.8269099505460815"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.3258888172426879"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.8444097751847495"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.735022927476772"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.5013908867010404"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.002273383793292"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-9.725949881139972"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.5684126927789777"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.94680736774713"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.0369695435867146"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.15755662058786424"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.7989367138654275"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.1856595905761376"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.5531560391973818"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.508265612530667"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.2122865454655667"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.911955124535248"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.344320275259401"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.2288669842490143"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.471119251592684"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.281586679641514"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.1479383288819085"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-5.353608278683349"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.6217251942811126"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.122318454984845"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.3176784839623048"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-5.604946944781361"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.1274210847536965"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.552914316002504"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.7979087701483405"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.2692335631996166"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.836920305990119"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.4187382280550178"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.8014352869941304"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.445156270735879"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.6325804388469256"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.1383232069528977"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.609721975771987"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-5.596801175511534"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.4679792530660125"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.098642199587852"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.8985631464567043"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.8197512584196232"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.2195673524537989"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.394400185929314"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.5365997810229672"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-7.698016073288547"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.3112903536825105"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.796890717072553"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="5.019184452244874"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-5.863414563813069"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.845157411244104"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.750783313729292"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.744872802677595"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-4.509228882352695"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.416892312967123"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.267480377425827"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.025137898928506"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.551853819599751"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.9719098295506345"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.8097366371954395"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.2519683906577037"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.1036952995255924"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.857565503084321"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.700034602369053"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.4096749785726628"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.9456849965850824"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="7.2284669558018715"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.534812965563873"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.604178368196122"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.0450991423942173"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="6.019286067496874"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.762127224025676"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="6.833955439852057"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-8.966073706895937"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.8719538796410147"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="7.101934520620633"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="5.957393034645086"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.9494680660053634"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.3572435942087875"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.945311984276735"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="6.571147854012429"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.44803894162882374"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.440772919411321"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.58789994827433"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.20533267752598983"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-4.448603340553739"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="7.34843794694906"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.5866163528306325"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.39985068281919"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-5.011850940336348"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.808407430067847"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.223499067631301"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.746045985165345"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-6.973254828051878"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.175141201638544"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.7370505542265295"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.4406810469321463"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-5.914151921199629"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.071996435814693"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.549456002007857"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.058955476274727"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.5089702769569033"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.890002820906374"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.594529403609347"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.1058256024683397"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-5.963265638625373"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.46176528350305"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="7.12763417251191"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="5.863959812233147"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.766963999814626"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="6.134318721925998"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.90980310188753"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.406723621411875"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-5.074245563781772"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.171667941092114"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.346415503676079"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.4560141948382865"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.092429602739559"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.4848083075513943"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.638202190569371"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.1503686433290263"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-4.243715809053846"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="8.106668169749206"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.160956147198745"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.862070960526185"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.31683794719485"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="8.182263143850083"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.5792836325641515"/>
      </enumeratedValueSet>
    </subExperiment>
  </experiment>
  <experiment name="ETH4" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>(ticks = 600) or ((min price-record) &lt; 1e-5) or ((max price-record) &gt; 10000)</exitCondition>
    <metric>token-price</metric>
    <metric>last price-record</metric>
    <metric>token-trade-volume</metric>
    <metric>user-base</metric>
    <metric>platform-productivity</metric>
    <metric>unlocked-token-supply</metric>
    <metric>seed</metric>
    <enumeratedValueSet variable="intra-period-trading-rounds">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-optimization-step-size">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-token-price">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-user-base">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="token-unlock-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="risk-free-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="annual-discount-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="annual-per-user-revenue">
      <value value="23.67"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="participation-cost">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-return-belief">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-window-length">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-window-length">
      <value value="365"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-token-supply">
      <value value="5201438"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="supply-inflection-ticks">
      <value value="239.20867425"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pre-token-issue-rate">
      <value value="6234.13173191"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pre-supply_doubling_tick_length">
      <value value="54592.74306914"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="post-token-issue-rate">
      <value value="5327.49443937"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="post-supply_halving_tick_length">
      <value value="324.0944231"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="supply-cap">
      <value value="100000000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="supplied-via-reward">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="supplied-via-exchange">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-serviceable-available-market">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="growth-inflection-ticks">
      <value value="116.579825"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pre-market-growth-rate">
      <value value="8.31137145"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pre-inflection-market-doubling-ticks">
      <value value="992.567141"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="post-market-growth-rate">
      <value value="60.3736513"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="post-inflection-market-halving-ticks">
      <value value="9999.94059"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-from">
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schedule-horizon">
      <value value="600"/>
    </enumeratedValueSet>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.893342745696259"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="9.2383622770501"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.0823955744758713"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.155791802087064"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.3133488966527365"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="9.964018102536695"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.1861084775315613"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.984565394525441"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.4622401721325629"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="6.442981338599288"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.718855486570215"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.3385472581142324"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-7.605060687468707"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="9.437246576712493"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.729017153812751"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.473234031568513"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.721894349348302"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="6.085854285066727"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.006622337236626"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.827447157111947"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.3508465589276932"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.0550814536885698"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.5839895330796514"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.830131878975248"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.455729401649554"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.0781644794370577"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.2034368052554516"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.769581997696168"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-9.79131563385728"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="10.542150022171075"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.8353602990728333"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.0272500925781936"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.1069664857811303"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="7.306388922938814"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.8712229504223794"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.168997935403991"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.7211943025579437"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="8.231450657923464"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.661767112084235"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.657544229728195"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.671742523083412"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.178073330050683"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.7677424923914433"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.122795743065138"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-12.402190374185674"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.5720570657103585"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.9053084406750465"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.764946418477276"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.7332789707731506"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.7700963291749661"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.5800037211888296"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.231595244720298"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.069623565890817"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.684961305318908"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.597474348194172"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.482293354994456"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-9.391436353716855"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.9344003874089424"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.2576587412357716"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.0126107746768733"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.4537200863050743"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.1031037798133365"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.969793863472421"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.116129040016059"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-7.380478508359348"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.18363556238261"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.7380514396101545"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.324947224076581"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.597917088650734"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.742031189467523"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.207609181070018"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.565616485893514"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.516752516028804"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="12.008750731038322"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.1454738506159026"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.35537464730718"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.3213246996374202"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="6.5020405792872245"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.761257821721873"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.7326430769070353"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="6.462972823981927"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-5.1938749515083025"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.380290410180655"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.361950868497317"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.5235287474148764"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-4.267294934731735"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.9505004745071233"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.799786267903307"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.6649070782380386"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.840780939742138"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.918617666372247"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.646885810509892"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="6.124596636992845"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.14359584338987808"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.6940203804943885"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.750921796265396"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.1999728007384642"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.695236306142385"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.011369968407446"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.6452350481139133"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.619276030351905"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="7.251917244057502"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.2225723956127097"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.086766236469034"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.237944774466512"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-4.389165244337798"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.6279073727756495"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.8134041298935393"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.075298719924545"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.3455657431972727"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.254495476554773"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.6956658122943713"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.126352082983897"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.6154113767049374"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.982719474524236"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.016601389307235"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.804044174721946"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.909371318548083"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.4808024591558473"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.2433178960637576"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="6.937289738961047"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-4.006628997997357"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.261594384281651"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.644884992393943"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.0559739320574364"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.6422052545682959"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.065778612168788"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.915002619123743"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.5562729041097609"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.3241587815778457"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.0498687712027404"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.9378651364994557"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="6.552748161283029"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-5.736854336472023"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.8421642479873812"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.460462588499092"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.1437609829208113"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.8481365686962496"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.029048784636845"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.6874563775063787"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.2380544080398286"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.8821010245837453"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.510243788502307"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.529515508719687"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="5.346790408488127"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.37747245022668574"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.503058780232973"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.602856679430006"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.6033808917463896"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-4.118055577161978"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.2678364526490404"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.686601608534846"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.498357015413211"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.5957289226944753"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.008278735541412"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.400758962287095"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.3103487054992957"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.7860212715788437"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.302100175751978"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.33876924181938"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.3807426659876647"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.9515118438633419"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.262344032401366"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.026362255404272616"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.721070800175265"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.280367912443249"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.2662135387704705"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.21960685247230927"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.480742028834893"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.5816959743255994"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.880944235334978"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.809233543624915"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.608291922825097"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.522502118079533"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.3121634122520978"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.7346616656914305"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.8677465180313266"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.588119471245486"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.522789478906028"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.1721534810588263"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.350197541136075"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.5516935248933725"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.4054390564985964"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.3080203482590804"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="6.788024945035637"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.2274313860392021"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.0873012472935044"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.0311465748497963"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.6832792139087167"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.6587344745448096"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.7240279826945855"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.1982016058329914"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.790272168678164"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.2759277854448534"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.0914664320728187"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.8973846662533592"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.4220513746142691"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.2260417343923755"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.1353077756413412"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.9448543241238738"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.5545017464844664"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.19562487985348276"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.6603792481938604"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.7766275105801301"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.6352825284655026"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.427958113749158"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.3204693232684501"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.4808070773759716"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.17232869160022"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.6056840025106176"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.9797707817892432"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.4926654544975707"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.6336537373924895"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.737815499349793"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.2292956266000394"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.5443582816917696"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.15819718402043026"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.02696382808044"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.8205712332486623"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.3249821864436888"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="5.324310107786517"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.19302694517433538"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.45069729147052"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.6087132850766923"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.5873707898175478"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.4029234496671785"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.9455695856089474"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.8359291036353784"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.5806545429031211"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-5.841298048897988"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.328916350524717"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.11938514589409"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.709567293141262"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.4829458163652878"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.729020539074043"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.774090780889616"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.5366470249923623"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="8.29485116114618"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.872964523443074"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.0158030647761174"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.1328098349346964"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.9883343161339568"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.098910106086216"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.1554792859087826"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.400213416333013"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.1840649100646954"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.9160678063102705"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.9984887303282832"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.778865511753483"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.336365715513893"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.002749487293579"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.5298975774788026"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.220964134223319"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.1464051297354252"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.356075611748663"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.281739334224665"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="6.059159100764298"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.5283052531704735"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.6024637460509714"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.99619049264209"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.3168005557099445"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.2706520305954545"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.7052962492590562"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.527849448615975"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.9270546143388512"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.6209125073150354"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.6450021110524724"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.372360565240229"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.2094703679788306"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.3175999176625783"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.604592812192612"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.430021876831418"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.918167389356402"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.002641738487272"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.1055892382538293"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.826929980246826"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.608524631781848"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.9027625534722405"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.5435540803049905"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.4339599682945217"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.059387042002713"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="7.882086879065289"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.646857711176891"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.7219554923998635"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.7741076292582116"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.3243923968691655"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.670596911089092"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.0806572161747576"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.4986392350473965"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.6971977212852125"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.430480066402321"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.0196819219343425"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.4171967665211334"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.625068708428273"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.1839041745024517"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.857465671255781"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.5642143376368"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.4414419764233752"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.485253785287827"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.7120338064446647"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.15444784947760537"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.7783942697301378"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.5014994901444325"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.5638582596323003"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.025883712809036"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.0918348004683587"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.2298000338341084"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.795119260999627"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.997609285547018"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.0822199992899213"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.068243587319097"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.6163909805160386"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.7621963703095824"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="6.707557818415703"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.057016075809842"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.6071230013563023"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.065256109195241"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-4.562224486341926"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.8020278016989955"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.104163124950048"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="6.373769928012492"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-6.742852519217814"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.6369919247332305"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.183033398709718"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.196922065943624"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.1122558955544912"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.620303527276139"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.493754807580483"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.4352434771659035"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-6.248221711853052"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.727845025212956"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.8606668507618005"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.4092090225452667"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-4.418960855475941"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.539154923682495"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.3436672133674983"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="5.214257802095817"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-6.630468918089185"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.409631561438868"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.413136795167377"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="6.3211782325528905"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.358850896161482"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.150072884814765"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.298245595704056"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.6461421634204685"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-6.138175192249785"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.319312141233771"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.5276245020211747"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="8.003454296957681"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-5.181272575440911"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.292392507370138"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.166028661317013"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.515508450428208"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-7.83478129847058"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.664748354792951"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.324783980788183"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.2776210127122258"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.1662342576118636"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.884521966715396"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.10801506386044313"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.3548563238069244"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-7.16807634229142"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.6437756208026104"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.340260862100034"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="5.294761289808539"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-5.826187809573275"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.260144167327497"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.4588268120056096"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.6675924079590958"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.2482183201759236"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.1519055149494406"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.9669765231150707"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.08952300177926453"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-5.196614471809532"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.584791435290986"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.3697191532519775"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.584201455270572"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-8.519290601859119"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.1048376438159107"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.0773450129887463"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.1076864688365635"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-7.254365661048244"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.798775802070839"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.543356947256178"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="8.277760519569515"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-7.012963423467912"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.3248774030911963"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.2778252910307986"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.48351896934147076"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-7.915570543404756"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.061046728206762"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.1394968372089527"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.8590500975873847"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-7.545640168046565"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.656516919583736"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.872614623699668"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.049725060958782485"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.567645266779729"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.571628357031746"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.242007245677472"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.3429249819820104"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.077847677887883"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.4201169892225107"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.19520134825202096"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.8790240646106637"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.035199440310718"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.4814047690549275"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.6662967981282706"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="7.305000224716242"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.6567971014756666"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.331725045053808"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.873959601234954"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.255632642721013"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.7910395562265125"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.7589205520806463"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.680855129476198"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.8853396764378043"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.5139414382722691"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.7588349309774283"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.2331168834715878"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.27234704062880444"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.8091948770348005"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.084791510996234"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.8073859723273764"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.3582408232800147"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.335260858543675"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.4369413739479855"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.7430888167143823"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.691986065660942"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.151312679332046"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.7348363301804453"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.49811063638430886"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.6016389486363085"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.066019065414965"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.008692030753849"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.6276310412514667"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.7932601834576718"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.768794229407462"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.8480712016350083"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.8780654529660759"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.959297729554021"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.7257653430303299"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.5973668141990345"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.693935702383649"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.0989063905051544"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.0141446121855004"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.340133962652682"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.9749481551334727"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.5434338896870773"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.0933351198878849"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.956701414507501"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.6437447639917986"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.423492322394329"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.6210945720767942"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.639549225145931"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.9074179168199925"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.3883134396700463"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="7.607687063204075"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.8870308114044523"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.226846646948093"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.008793609549437"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.5815273363804234"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.5164938845907567"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.1749934307263397"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.9896500197165663"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.5402102372764614"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.5117692496596016"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.6601540315385765"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.1080313025980422"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.36186580109315436"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.2527626287380031"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.340643212236158"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.9337703060739555"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.0887787901794241"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.645681648674347"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.08445902787276216"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.4731367435255913"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.2380723219302383"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.2327922671438145"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.2231734469987168"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.5211970253083207"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.763262597748746"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.261779842778125"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.9284180338678802"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="6.355210373261694"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.5825616711650023"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.620476680751341"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.8784377828628716"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.3418209455081938"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="7.580817792092037"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.487912755441852"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.5276772210014755"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.697914447496272"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="6.488366721876712"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="7.046795783674977"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.1672895341138934"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.1430366113913797"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.731184306909483"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.088446404704936"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.931916373640037"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.612180729864013"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.68684844267178"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.432180629066091"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.212020813313611"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.724534978514788"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.9029440831360107"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.8497062989456468"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.277525183014815"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.0023773165501674853"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.0386578519498273"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.6144289228291315"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.8100372866573302"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.1078868108558355"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="8.515289880857186"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="6.519895627744288"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.712069432552126"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="5.923046967688262"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.797047073362763"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.120487463865732"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.0005840975054916"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="5.5145855618769115"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.9871403754223147"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.085547983187487"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.2663162567689894"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.7050099334823545"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.2896228332023165"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.344712632470028"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.011201645924459"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.7855651091067908"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="6.543916399303454"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="6.575847037331418"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.0406116239727976"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.5942209085628134"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.027604762854486"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.801808055328351"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.983055341464136"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.7144201606691041"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.3880827142295491"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.3903401250537675"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.2370436728227334"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.4876412368464074"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.3849168889990584"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.5016704215466365"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.9593765769889768"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="5.850385408054954"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="7.641736030939511"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.201260566365782"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.5345527587252574"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.6041751135056845"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.4563159463138193"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.808009187721952"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.36848369564013"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.577179349711829"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.4419731905369"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="7.344805462883107"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.881600102556721"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.2234748369591664"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.6736736203819587"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.281645729897154"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.986533215551298"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.09337157453859"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.144552654672272"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.67927473117434"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="8.052747669220974"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.360976235674512"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.6162873092098153"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.1444882701598273"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.174552316670047"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-8.776620889443603"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.6068808530059777"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.6547171537415943"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.649980415988027"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.332350016499736"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.4711388156758618"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.810362069666167"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.646174981381879"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.427678005702803"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.11742408742725674"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.5402410373049467"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="7.020184249908811"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.85570537595368"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.38165244309256563"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.7231059298396643"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="7.821563921087845"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-9.79501340832941"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.380334876361282"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="-0.3799054170631022"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.550498908324424"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.440603455551256"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.3357759607860737"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.0291206822074543"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.2697911224340945"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.679259792247623"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.12302022891918218"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.6457845550807308"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.229724754739467"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.098356978538212"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.0106870315093825"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.355264936863782"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.975718458278535"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.333160100337148"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.020199830924851"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.980859994186652"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.405927289428227"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.03745242358274"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.016616187259167692"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.7514328969493944"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="7.839464708734958"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-9.522647040747604"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="6.9885238712099"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.789426292868465"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="7.381133807068563"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.9241810570192177"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.1031706591736223"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.516450094431147"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="8.66366137628137"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-7.972483184693216"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.1929120250612524"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.7323746062636793"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.1117196416074115"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.9171994489534456"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.189363204885018"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.1637537941199407"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.986832856787159"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.6977792384340216"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.462207416200168"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.1591196304737896"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="7.051853493673269"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-11.625504700298965"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.083020615386598"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.5261025516368556"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.979348595833841"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.066415386284232"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.0642246762806016"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.7652418187802534"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.569511332333157"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.720112710498207"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.529454588450938"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.832369466580141"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.696531052563821"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.275756458528237"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.062996595422854"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.9623186709454089"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.282424927236354"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.919048279128777"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.317201889210129"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.3193567163939612"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.913301192583202"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.365882009366884"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.7830246694564815"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.39045258127027194"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.9841149250193677"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-9.58182623273591"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.1139075607794526"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.2864177993468184"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.9758910911735126"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.5017281114723335"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.8370000212726598"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.576716738742342"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.2196582071308795"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.3958437207321657"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.342610139603053"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.0506547133531736"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.7599945240833867"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.8507383687164514"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.981674469845885"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.6889662188253973"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.709548793977026"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.051676969891359"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.9168365378631547"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="-0.8892636788212993"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.9004726924417885"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.629430079496914"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.859787551271644"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.473159476020347"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.7962421280600394"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.859516184091133"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.018943442819798"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.8045643111571241"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.876802622215982"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-9.021989414569553"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.809307810121576"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.8428807992417138"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.498685306282808"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.749813847771535"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.46875389466264894"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.165590876256306"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.4347029615862024"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.839898935342936"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-4.67835195644331"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.16830981144529"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.000043348361803"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.6656358233396364"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.9041850834425302"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.4505691784840142"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.8296810974258246"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-9.45420959394526"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.821794901785487"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.0993348603498414"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.8130707374714765"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.6123313677802638"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.6900881033887496"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.8921320560518584"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.434184654127258"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.3386946151652577"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.7728148473151745"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.0122355298468686"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.478251887971852"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.09054072404247382"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.3811557412927582"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.8329511013478577"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.9374199278890183"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-7.628393811779166"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.5429707349369371"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="-0.8364949921570579"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.5628737232466445"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.6438092531818556"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-5.348220025638555"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.3165139988243886"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.544772748156135"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.5038255562352972"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.7254813554496324"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.76830818175956"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.01201581887353198"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.8852879613715388"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.8517657755269061"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.8792277850895305"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.7639212978682073"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-7.196690472703997"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-4.6029421168673235"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.5090819756707432"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.87276883128867"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.437082312202632"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.5250438808663356"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.0313384422453349"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.807456540137789"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.039128867002116"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.5740631590327379"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.9155533634378794"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.364421168257825"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.519302217964743"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-5.802966534543129"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.2307246577807969"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.5538583476029997"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="5.252228862441846"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-8.27789928508625"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.390275766945103"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.301924212889442"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.1692725364051455"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.1500826882205613"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.9607882004328847"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.4994166276685685"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="6.598700477076327"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.49321458250769"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.9862856576169663"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.9685621243323537"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.40674491013588"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.052472816055508"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.756973449393409"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.046059381299238"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.2170721254827974"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.9268984756456842"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.3622999707186083"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.752685574962011"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="7.716217767037535"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-4.23909858279017"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.972946985906624"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.396211857668533"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.2846537776180034"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.707365971410474"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.773279198038863"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.9869199236952038"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.6715178782208953"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.054778998271943"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.9342589054136303"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.420861166287967"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.4858110977952084"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.7603255651059924"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.2428995571311041"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.736540182358152"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.833035436755245"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-7.0884460117268295"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.2408090983891515"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.5704368031061726"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.88710374096962"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-5.327586956288154"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.3705346998643195"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.155755153948024"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.9377921544601895"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.9520589399721846"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.970639214756603"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.6493807496438073"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.4614028938509342"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.2075899504598462"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.569140256341606"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.0751747296674425"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.7031031291875065"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.057561439436891"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.1625760526306013"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.262611903975262"/>
      </enumeratedValueSet>
    </subExperiment>
  </experiment>
  <experiment name="ETH5" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>(ticks = 600) or ((min price-record) &lt; 1e-5) or ((max price-record) &gt; 10000)</exitCondition>
    <metric>token-price</metric>
    <metric>last price-record</metric>
    <metric>token-trade-volume</metric>
    <metric>user-base</metric>
    <metric>platform-productivity</metric>
    <metric>unlocked-token-supply</metric>
    <metric>seed</metric>
    <enumeratedValueSet variable="intra-period-trading-rounds">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-optimization-step-size">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-token-price">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-user-base">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="token-unlock-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="risk-free-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="annual-discount-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="annual-per-user-revenue">
      <value value="23.67"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="participation-cost">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-return-belief">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-window-length">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-window-length">
      <value value="365"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-token-supply">
      <value value="5201438"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="supply-inflection-ticks">
      <value value="239.20867425"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pre-token-issue-rate">
      <value value="6234.13173191"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pre-supply_doubling_tick_length">
      <value value="54592.74306914"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="post-token-issue-rate">
      <value value="5327.49443937"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="post-supply_halving_tick_length">
      <value value="324.0944231"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="supply-cap">
      <value value="100000000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="supplied-via-reward">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="supplied-via-exchange">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-serviceable-available-market">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="growth-inflection-ticks">
      <value value="116.579825"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pre-market-growth-rate">
      <value value="8.31137145"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pre-inflection-market-doubling-ticks">
      <value value="992.567141"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="post-market-growth-rate">
      <value value="60.3736513"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="post-inflection-market-halving-ticks">
      <value value="9999.94059"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-from">
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schedule-horizon">
      <value value="600"/>
    </enumeratedValueSet>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-7.967602771322008"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="7.983828631655044"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.2216651806658865"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.7948299112060306"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.9712403872781046"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.119521536013053"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.4255120663043526"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.541854082517786"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.920284521450767"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="8.201097249599957"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.1946853094630896"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.982006985527201"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.9972066059049856"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="11.947065071934599"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.5495896832182128"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.693370752138684"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.384029075044498"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.05505117050318"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.710102562450505"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="7.799865728409564"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.693667255231626"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.939383210337458"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.4842480631178985"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.811505790700401"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.759954330134751"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="11.955634349090182"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.5992212623116377"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.938684838216549"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.3890357624471283"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="9.181808091251012"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.147227149622436"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.2306360991352605"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.594610485483111"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="8.360040999510186"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.1458530971531986"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.2011572179593095"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.23332352696083625"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.4099522777063243"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.214909399934855"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="7.773577279529384"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.4718942944369129"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="8.974690629736925"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.9702000966167557"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.226401279998493"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.984348992540702"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="6.018931540904732"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.228931857753243"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.049741782138318"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-9.315364643418569"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="7.255557382403318"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.5161859048789559"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.908413755737599"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.3104653955170873"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.1853709610112597"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.069694743248646"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.330917279569926"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-13.437795250403482"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="7.951301659638148"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.5769713026889605"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.712513665643851"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.505228068249325"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="7.027845089793855"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.082922173968215"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.4136209207556996"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.9996038460945487"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="8.51007555608541"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.29411492330931"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.1484226001807385"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.818822483434953"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.9723505278090747"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.654604422967278"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.757715610879239"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.384383211237816"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="9.17800592578947"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.0507045277192923"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.90087903964866"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-8.003805779358387"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.998467899459089"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.3619893239104437"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.354516660202387"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="5.634467141797091"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.0939501361036426"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.8181976790253405"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.100241798817834"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.8357130396317762"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.2633827387705245"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.346320995061907"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.1693128638717738"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.8419584614370337"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-7.390320546758819"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.283699039327973"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.068458874441865"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.7844659945429875"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.3096106667589327"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.7215894232148568"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.698030437144831"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.865770819525631"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.1428466050144208"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.2043721953860853"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="7.347544891499959"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.2415140467252503"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-7.708496448545617"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.502350459868169"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.677320576079073"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.9946594063671723"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-4.840372066264879"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.3120300866902053"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.851939895195704"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.754379138828206"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.6264549748106587"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.5169790758189015"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.227474503615912"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.2695812285370516"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.5366008882083224"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.2485267617619105"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.1668841354431905"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.1880983675050418"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-4.384915542123868"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.070673151995772"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.897101622767632"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.3262154707386395"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.4850665586223322"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.3313011038415272"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.383198551180084"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.017272975618488173"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.797019962829388"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.2023332013646746"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.058674986622728"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.3041608140223593"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-6.688617429353114"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.309881761558318"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.437110716499744"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.2206656891869887"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.6122383786813645"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.8318389269023978"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.240208615458759"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.8411458971161654"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-9.104781945111997"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.0684859515611826"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.741477805956108"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.7739366841960917"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.3454121526877398"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.4514140312464052"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.058182270269093"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.22854434903050058"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.728104602245538"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.5035998042573757"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.904604085317865"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.9022705945167258"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.779914867140091"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.5118570831771847"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.671570522945415"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.0487609808175888"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.3007078876448865"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.242955598398037"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.309151989956733"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.9102076510289834"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.9785848367510708"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.106601989779604"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.905613752149379"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.722689468958313"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.4973441667502496"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.037487096465577"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.250899525468932"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.2489491959744752"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="12.174629286563887"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.925144711632889"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.598034097361811"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.476092013794636"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.928589955283139"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.9415845872225876"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.40856642568197"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.13201960467408713"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="10.488850878680338"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.441040900324862"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.567172013203788"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.5438128300046903"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.508150320667428"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.271637946969472"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="7.092228135031299"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.077065112026958"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.100839171387097"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.173057843799083"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.7017714323873205"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.5748593817025178"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="11.123303436481399"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.983623137139618"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.366228896930393"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.653109199398247"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.24376036974696902"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.5063061640681417"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.206765770370302"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.9640524832727015"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.9840899295223258"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.833839281325437"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.9186942224285484"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.109949745158198"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.9711691467777968"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.528959557367605"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.819129086377793"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.40961689914901167"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.054570768052081"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.06228913930798"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.9538066608279205"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.731993941991468"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.221306655217907"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.6871022780337546"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.439327226881513"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.5890624698325555"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.490569309111483"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.536636550276669"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.743359252738428"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.6055062703384742"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.4616077744957203"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.7991297702149094"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="7.194060325580625"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.19022151054243142"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.7078135740027554"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.631981881771457"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.859223291732908"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="5.231752293671008"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.3545592434464573"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.801878989629671"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.830006611581462"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.8238089234686603"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.4211776580734079"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.3355331122531395"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.809422685779144"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.3195807017818693"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.8680717264825484"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.020989059421975"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.122678225801909"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.0320743275947597"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.249910467610205"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.4714145876563256"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.683855983889622"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.32828100740506616"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.128092472282964"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.649431702317576"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.970468020845243"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.8646207718441197"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.8777510404268334"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.30167965548344"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.1276570087730127"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.081562020374069"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-6.03709968720764"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.6491230447294543"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.985365395729263"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.139099623120362"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.3567123322080157"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.108144988247984"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.029579506298651"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.287391455298155"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.1385653439866021"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.198722701021991"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.8024411539602896"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.2656554762648087"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.8233570315979342"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.3128457830147977"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.30160260927778"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.6241009582345782"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.328492773158495"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.9316701437696633"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.185642138595467"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.388079852294441"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.949140692249119"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.410514296505572"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.34126591519336"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.399028539645984"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.0015662687402904"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.3799968196314034"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.9942123719345455"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="7.445706239260284"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.6893954722629334"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.313438838066602"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.9920440992507285"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.4929128863012244"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-9.319455773075731"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.587521555881734"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.390767067656193"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="5.235808531768694"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.33719932883196"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.503894818764946"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.585144729591928"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.7291723816494211"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.2550634668568148"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.172035197897966"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.012139851080325"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.49456748848971"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.3316222992884903"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.0661836959168363"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.6520202440834733"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.175418050720899"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.048899404706697"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.3913110729001463"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.8070749657710374"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.249449216712551"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.6233044262795135"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.007718885736588"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.8987096781256523"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.788214643165544"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-4.231138616089353"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.2518354269795995"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.629677158192939"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.5997307466930315"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.9889602870098186"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.584791534330452"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.664306267250032"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.7279260197317003"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.3564908527130055"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.421752060530308"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.3444490463409076"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.9367009656578653"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-9.332557125777026"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.4623636765252286"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.1328999131387265"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.818256737890612"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.1576888170421245"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.5271319539842168"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.943349975749878"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.4732250279085997"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.20714168612083816"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.499153698877775"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.8057460810479558"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.044482076814564"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.650696996549026"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.9969939693518444"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.7386056735785789"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.7882933120449684"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.32864377899813063"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.5266232355172806"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.854910850760464"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.1575209901089636"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.3298875794005136"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.369223834560828"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.7695944542269153"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.353614132822835"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.6266681663759786"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.522900965446175"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.2124735045608204"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.0447116673841341"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.0052119043092125"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.4953209462935673"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.8617060316288375"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.308067877854562"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.675505598627981"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.017362487716791"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.5573505298901599"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.1919674797457764"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-4.267140311553189"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.691957943237878"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.5152745907714356"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.6195048701113637"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.4494904647629039"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.9513261764869092"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.137394214281207"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.5845748581225596"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.82110043342093"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.1849410865750938"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.0035112118974096607"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.228610219204779"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.0449763825881309"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.803991200032629"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.9485228319230448"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.5482921663626326"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.9496343838234296"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.860638315597723"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.6170502118055481"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.9941453991902165"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.8265860549323611"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.759073136636251"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.6976248501740274"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.5334000985327836"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.09798835363314129"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.24298418829783452"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.2388994739071721"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.37995754572176954"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.9567309850015846"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.559826509857915"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.086551110148805"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.5439731467687046"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.7943927053877609"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.159713906308925"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.8584666400271658"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.2935507044883777"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.0428174504235812"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.375708171120176"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.4376521807032604"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.216562121954569"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.9492466507734414"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.58940150759899"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.0395347858678416"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.13321644111537762"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.5630609079211881"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.470534852450375"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.6842999260907453"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.8059101192372196"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-7.221010775789871"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.274747433529085"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.4194379049379814"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.4268022578888693"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.5290167459769255"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.083502764037986"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.1105092668883625"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.613210010716678"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.3597348944255827"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.3593555190196884"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.6423153747729553"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.1621987312595428"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.849782979769769"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.743980184787079"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.0003177192992205"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.436292735836899"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.0306301325347897"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.731472798595017"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.3343578646509706"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.4376301355870815"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.0611310237739482"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.1484712888675093"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.14922206062053"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.1751782608337304"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.444958383654661"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.3991443663846541"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.101298219117407"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.8022611880677686"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="6.4031959344209115"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.5875897934978562"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.4548625815475305"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.808265470299832"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.4332577061635945"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.645679664200747"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.21259172238988"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.7744664557231304"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.8627021876282974"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.407670424830255"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.492066767203002"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.1927765315225083"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.1535869555290339"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.2814528823128197"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.0924009268758343"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.60586610698534"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="6.825155142838391"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.840938096365451"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="8.014636599599115"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.5523705079680425"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-4.1643590074236725"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.534831636927725"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.750152123938716"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.945105858626806"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="6.2256059967735755"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.2581758850732694"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.191190282266519"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.2942024369774128"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.2351861079551485"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.7668157890398528"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.35927034203612873"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.6168218769985803"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.438702523352852"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.9817840430707685"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.0951677970800375"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.5145408681183048"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="7.992815090130681"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.8804060766854325"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.915431919373865"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.2337932347921905"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="6.787727188705465"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.3723945253280005"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.2964640331013335"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-8.715845350637522"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.276425652612761"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.4412839844481367"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.67203735034089"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.4839413263227055"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.670971838090096"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.9181370147371246"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.1095310463003099"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.788232016579449"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.204304549879843"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.430193446574216"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="7.224944412297887"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.4897500242435435"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-5.883647353423908"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.2198963772167386"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.8499123221529845"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.99383585236002"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-5.84924694368614"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.1681867976999607"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.078816924597145"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.07182912950749"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.02290774809476"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.7623888285476252"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.7678615766508115"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.8894087235659858"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-4.8031331625504645"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.8908906595294472"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.975003367624211"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.2381620153134938"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-5.992371606906342"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.814787145720858"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.3991487014587287"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.1127373291002316"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-8.342316943732037"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.8543748307374224"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.5310314784315238"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.7059650281658238"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-6.383743087390284"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.556594181919162"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.736862389157039"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="9.04284818763648"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-9.32071235662514"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.072836375814718"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.6718632952334447"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.9346773017712184"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-6.1920917745189525"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.86087704134249"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.598096939240845"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="5.84017389506831"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-7.856215200145895"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.2624289468705574"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.67083043243833"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.9207051315709656"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-7.083366152416243"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.142192813477813"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.990334167707224"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="7.980631272633316"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.7087011965062437"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.7243970192627005"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.652158862934851"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.0966266578289208"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-10.478418362322952"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.088230989227148"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.9806304532635557"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.5977464421706657"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-8.921516104986466"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.542838461892282"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.490573594952282"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.3320228776552878"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.4317140592786433"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.0802212003332907"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.971431465421788"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.655671878463016"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-7.728809129889926"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.276086325071722"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.1242937575429357"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.858385673112934"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-6.123869610277017"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.0085290082226734"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.504243007376941"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.067590186810766"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-13.560027746899763"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.6010829281427865"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.7405128445635625"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.3848392747854936"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-6.5505123191662324"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.004887043155877"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.5217894610168416"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.5079346820149788"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-5.641045548804057"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.356394359977195"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.378920613130206"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.935709812304701"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.9313628451587399"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.809465304227126"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.0663469925199864"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="5.870898383322961"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.116972183544286"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.006795138828851"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.3985972069957813"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.07370348399032145"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.2500427310560696"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.5997207115709697"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.8206720526748381"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.1719899438049084"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.6026371392009953"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.640180941705677"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.3180081571937854"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.266402424343456"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.0826791364364663"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.9646495229712273"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.77992958127056"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="10.768839072923436"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="6.894060128586704"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.1377093227211783"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.222993428310066"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.07404463297924"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.0205211483502872"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.52942221876845"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.7430668566184508"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.6024235562057423"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.5276789907902848"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.0979850037527203"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.0346326620438515"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.4359717555922344"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-7.39267070727373"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.935335172446132"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.2491142047473094"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.934272507594315"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.10808234711816489"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.9998027487790444"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.5753583074013275"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.36519159082116315"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.5698972789766246"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.4423605771216796"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.8637363555765121"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.9383764815937634"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.8633322852868486"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.8278199785517524"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.1937448496498217"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.6053049166117437"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.85766127850783"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.392369374672878"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.8804010736664345"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.8089918346768257"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.951217085953602"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.1404964833850606"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.30039983971149997"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.102856068020449"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.1052112205102125"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.601742117229253"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.997275750279352"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.3623282456949306"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="6.098305671558249"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.7742471249597633"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.40035512641185367"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.1148567569872991"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.1829850084768787"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.0725056688573913"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.563267807843727"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.8695912628295265"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.8223371568973552"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.518025556673018"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.724276190607563"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.46820612981811793"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.7765974743658939"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.4052300041941046"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.3699932955984364"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="6.243232427866342"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.0861167584213165"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.307374750979704"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.8383072341510118"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="5.300043293351822"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.316410573639888"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.9638523796832774"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.081067533129895"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.27257358110772856"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.930991853020944"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.452409291574742"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.1742151662680262"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.956805266950173"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.48854190234120276"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.642796511439914"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.102785793118773"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="5.711320683027369"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.611104902760071"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.8883410969970225"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.12493672983774617"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.339076424849255"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.9033806187052305"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="6.530903082209316"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.625901618369139"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="5.946690990098594"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="10.398491354382376"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.096033682335321"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.0794509347357315"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.8918950563839054"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.2932916478094292"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="7.443421306430728"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.6933109712459817"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="11.38456362271091"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.8926141984269926"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.101627352130267"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.031971032972794"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.318219898440246"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.1003994162590804"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="6.138531263449583"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.48967613151736367"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.203018945794605"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.292698669291856"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.506600852005465"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.0585617043858082"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.9662440924035391"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.991489192477408"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.927002004895306"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.729752371946535"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.8773530361596098"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.8432062006657612"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.993277082275381"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.2509866602775586"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.3346661221979024"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.25962923350127953"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.1695223759486435"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.4946686236502571"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.206773556345759"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.3282557496794682"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="6.147807054118598"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.4685217348390118"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.128363181962809"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.08127061483428744"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.9824634223050035"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.6350101759690816"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.030679509415637"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.272847441354486"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.475852300733194"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.7461595301257296"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="5.272885007427013"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.4706218084324325"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.820359046047164"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.1967116562647175"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.5787413610716206"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.160876170820757"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.88368742440075"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.171611694153035"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.1309274641893317"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.643242494124379"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.829821680851187"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.5634387475341085"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.3182130947422659"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.2564395643205253"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.898938360261844"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.4954054703749144"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.549447497223205"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.9724586194878784"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.5098021237763812"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.407743493308621"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.011821206165813614"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.156401857777439"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.577879446034916"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="9.703295871676133"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.3444580269897095"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.060224339168086"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.4576133594835468"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.7060261175586726"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.36548166289207"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.40815666768102155"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.1120675788549046"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.891790204810204"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-9.36394558015625"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.43773970623079084"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.387290039975509"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.2262207150195295"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-11.533786390975942"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.4603132294343966"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.0241443259574123"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="7.003088130061865"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.775423603507848"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.5247520750413734"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.9878424173557532"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.6598512725541457"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.807019904349155"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.3787434471073654"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.1080441372332284"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.839975185085879"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.697557828646106"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.67096678842136"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.5073937951876992"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.8949340803409167"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-8.670515090365136"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.896311296452893"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.5745533028930219"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.476844893864554"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.1626802373566703"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.328493027731689"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.8911889370369241"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.606135851690432"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.986306205111675"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.424701942496942"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.262156932554466"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.6896825757062497"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-10.254278009034994"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.35220607420420214"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.220611740227554"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.5127578893711595"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-10.54868518051391"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.698002308360709"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.2788945495301294"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.62876665242866"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-9.654331559495628"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.22049654517381212"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.1454397549384474"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="7.355877278496458"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.0141171491598735"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.8610756283231877"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.3112049757611497"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.706473685194902"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-8.114604562126281"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="8.659850944900949"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.4261450740552473"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.308572521769367"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-8.73258463690742"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.699026210540432"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.170123958636633"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.997118654960503"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-10.320405142383906"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="9.979913591807385"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.154563514456463"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.155920483132245"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.412678066356629"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="6.862661672483956"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.669669928888151"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.011948254531038"/>
      </enumeratedValueSet>
    </subExperiment>
  </experiment>
  <experiment name="ETH6" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>(ticks = 600) or ((min price-record) &lt; 1e-5) or ((max price-record) &gt; 10000)</exitCondition>
    <metric>token-price</metric>
    <metric>last price-record</metric>
    <metric>token-trade-volume</metric>
    <metric>user-base</metric>
    <metric>platform-productivity</metric>
    <metric>unlocked-token-supply</metric>
    <metric>seed</metric>
    <enumeratedValueSet variable="intra-period-trading-rounds">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-optimization-step-size">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-token-price">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-user-base">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="token-unlock-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="risk-free-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="annual-discount-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="annual-per-user-revenue">
      <value value="23.67"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="participation-cost">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-return-belief">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-window-length">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-window-length">
      <value value="365"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-token-supply">
      <value value="5201438"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="supply-inflection-ticks">
      <value value="239.20867425"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pre-token-issue-rate">
      <value value="6234.13173191"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pre-supply_doubling_tick_length">
      <value value="54592.74306914"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="post-token-issue-rate">
      <value value="5327.49443937"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="post-supply_halving_tick_length">
      <value value="324.0944231"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="supply-cap">
      <value value="100000000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="supplied-via-reward">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="supplied-via-exchange">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-serviceable-available-market">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="growth-inflection-ticks">
      <value value="116.579825"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pre-market-growth-rate">
      <value value="8.31137145"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pre-inflection-market-doubling-ticks">
      <value value="992.567141"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="post-market-growth-rate">
      <value value="60.3736513"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="post-inflection-market-halving-ticks">
      <value value="9999.94059"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-from">
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schedule-horizon">
      <value value="600"/>
    </enumeratedValueSet>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.1586457490209767"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.404708968964419"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.017147180127978"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.229416829082255"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-7.043034687562292"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="6.41568399609477"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.4263638601447655"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.321127809263348"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.5965466470743701"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.635444949239259"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.9259589371401162"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.1527466146119547"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.384527745981407"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.966707027613951"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.8160383780917795"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="7.891026007281481"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.8912609852594784"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.8359419906693009"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.0366566109942745"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="7.435412903614325"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-7.7445702046802545"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="6.836799120778134"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.8829831321344788"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.788891828786182"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.8610947859400504"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.469061401680644"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.5924419522213453"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="7.5738265431414735"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.8881855574636455"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="6.108909741120689"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.8480543942601724"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.946172385724932"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-7.2419407296404525"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="6.216564224046346"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.051777612173554"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.370333182268065"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.0368971739453214"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.421403164149179"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.073921119451311"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.333448538252381"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.0660680044506874"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.992242782966761"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.388763738885525"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.6709203394884318"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.5792644831963605"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="8.62253419765236"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.5330098629372864"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.473190095879388"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-7.181217794163986"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.504802717014249"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.9967805550218272"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="8.170682150532919"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.1690079519607295"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.826316400143886"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="6.328130016442998"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.690165438702929"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.694051348405484"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.5680919036921965"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.427535675903444"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.6854407456930254"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.720660354009585"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.784579044124908"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.9752032779571884"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.8741176619829645"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.704660334727764"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.728572822756751"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.797193319971355"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.301401494068186"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.2902133661496356"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="7.1336679724817325"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.2824621308531166"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="8.407073147775108"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.426640198429578"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="7.8183474776579"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.1553384847656814"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.3237265457915672"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.059844733837314"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="7.539275930331808"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.101493429955598"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.648429566847647"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.8163479093290003"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.9358290712539032"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.110912176963474"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.629339780084701"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.3915590106043578"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.7011388243049341"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.8495403727411244"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.313529332308951"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-7.35696582995812"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.1548772747998415"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.7462561635548535"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.478414921704015"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.8506297739780617"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.9702101986388483"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.675518144284397"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.330643552501808"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.912697623795682"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.927491336235277"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.10177325329309"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.430335131070184"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.6961985491209202"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.0508003918757636"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.064107531818379"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="7.4778793061679725"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.8802771984270175"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.038076238051706124"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.8304602407453336"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.47681603383825"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.139323587007521"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.4489532390587043"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.42039410344443"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.2235021014293617"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.7249294711425478"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.4779245130540937"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.436587202824441"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.66554838362566"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.8867499872634761"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.8819043446139627"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.7854343860155364"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.405722933583683"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.04055689221913661"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.9003213020280576"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.250916607826367"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="8.303278664895762"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.196707990423863"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.008458075979085"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.5323841594116003"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.4053322602314076"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.5570881827096341"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.54014322226931"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.521632350643317"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.8711929316584661"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.0478247255875957"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.6550387427496864"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.7697679662584296"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="8.284627763673637"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.987059014639243"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.429463641732091"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.6983559871227425"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.7823285096342545"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.5528738279885004"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.076858187275452"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.038486793170725"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.683506817949437"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.0833209027370545"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.3989035355445978"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.413759522487064"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.30612952070803"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.4033666071203035"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.9876895284332714"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.124536688010845"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="7.4514896415819925"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.9022966877619711"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.13448963469774045"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.133602968294117"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.1731448577444716"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.10628329422958038"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.544514477220225"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.3502555677674692"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="7.097160176832814"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.072580296056335"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.41801351024586286"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.5940446546881075"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.339042412651188"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.9140812142581356"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.4881165725570562"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.4146502385925563"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.0170219737883186"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.409940321013608"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.1954088690125557"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.6146902968281545"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.037550551658864"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.3680985469421383"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.1279609122470502"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.513173909337882"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.5061860931214294"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.9613590769529847"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.859932048712277"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.06057550260101"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.972553229761101"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.104879874165426"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.282439706974064"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.4995854746913326"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.6063729432486008"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.467029801119163"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.6329375386511877"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.4506467793621285"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.2369364601037907"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.12194169770578"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.9295825531522481"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.963690495302179"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.224915816364899"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.415267462837764"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.9071173153519483"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.5389838901111588"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.20468097382674116"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.4506919082906436"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.4707730959391148"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.9661857549778716"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.776679618792981"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.5572389397700765"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.3600588110780796"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.6152540667156627"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.7442507700688665"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.401898186617431"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.35710034630797227"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.703343257095957"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.1139893582846798"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.976801515445052"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.1670209572750907"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.461026501303165"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.043646136268611"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.3400439095221603"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.4232959433670642"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.5100514031995163"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.3978253534718924"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.276410850607374"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.9684513302252253"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.227681131227351"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.639495514472897"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.495736375698682"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.2888508249240405"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.960808350270475"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.03246367756724211"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.0544648409659223"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.694988994681423"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.06018991970116"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.5391379703012724"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.412237543169885"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.0040171309039971"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.689519596886102"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.1982960259885234"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.555421689147803"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.2179102908433204"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.305476261708211"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.12558154435913738"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.09975117394933464"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.6697708600004715"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.444856235956438"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.11024039422214305"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.9101835502548843"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.5018161926634326"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.776777130753671"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.9353542313585783"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.1516768446683203"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.1313302325011403"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.3643745778851613"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.3733044475987"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.03596070412250585"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.6455600459973232"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.238552340811776"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.0598135850599704"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.6490027953219464"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.2566237919911023"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="-0.114858140492756"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.2211079817702863"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="5.569131780506041"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.09780100317949592"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.8491811837472145"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.2909001476266324"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.2353908070661976"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.749913575487677"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.228886630798125"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.6949775368869693"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.696384901493154"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.6354796460647401"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.6683055169189367"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.4034179715905166"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.9875725858182631"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.253428001223008"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.0936107145184586"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.299060778060242"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.31537522725166056"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.5651220453966705"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.082805604916891"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.9207088702515893"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.48841829318865493"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.9632234154722877"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.8116977644174588"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.1496954165015711"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.45878784405144646"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.1140018790046682"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.6917791463384813"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.2447428918042505"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.734405721797336"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.8608735771661966"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.5285117256238028"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.469206348847629"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.6391950637040487"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.733149410503957"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.505062869271125"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.4820466853900096"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.888194639528583"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.0831570369041463"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.9965506450865012"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.20392572902739"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.3564031744605143"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.839700138337342"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.8081064993040075"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.5858272012867163"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.4622017466845163"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.603158499753299"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.4624307434724226"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.764299609802339"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="6.908600304290109"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.6490945669711592"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.0396293411832547"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.9334249931288623"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.6965382667984445"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.0582486548121257"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.5987753319405997"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.4379082086843322"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.0445525976299186"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.8178987064183163"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.8480264190011424"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.6889460985113094"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.1639833010524863"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.8421838158139354"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.849530637488121"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.4366912674126415"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.6447643822154667"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.5669323203205372"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.2486389065512125"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.30293112934351574"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.457613799850901"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.9109855096237189"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.6496237173252295"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.278459617632612"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.459430043667618"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.657867340942973"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.66938178662007"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.5867514573200507"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.029998242851275"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.5128426580385836"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.5228727773406516"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.5836633313976005"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.1715515865081445"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.325564433282136"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.086317896387513"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.186235422836556"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.767550781510831"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.10764632214998315"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.3752731033478387"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.3127340498968407"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.4744522871584962"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.439963342581167"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.1871589384000965"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.0542962677945193"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.28858119807779026"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.0920474247358007"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.718925901305979"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.6154556927842038"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.807764641692292"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.6401989850306041"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.8266482715433097"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.7810757700530013"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.3934046551357568"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.10914960371330429"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.4032268414853384"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.10475135937609081"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.5637926356355447"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.4793704868365971"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.4052386423394638"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.1316383155155216"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.81872145770384"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.0439125470627726"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.003570378781102"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.3349493955020505"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.3923433515409086"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.3986000509469548"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.8124828851697647"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.1146226237872183"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.07484754107897673"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.8838829909632249"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.5421644173363143"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.15923197880848317"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.6146417308874218"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.3858278722426065"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.041436914460504"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.326786260782558"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.8046608860402795"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.9190102541362897"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.0401031520622692"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.8180893297656726"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.030544422082781075"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.0072405638131858"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.5193324539168"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.0882987000348439"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.8525198871505"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.45876728529180566"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.022144257397011202"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.5227885211936463"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.6383482660722462"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.502059138844862"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.2793719904189826"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.7489668450302092"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.218656933633429"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.1760666727246263"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.629644080236305"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.8531322213591005"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.5532944103277626"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.269405825327743"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.8653244816332437"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.835412305948716"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.4699623650646205"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.6369004523021058"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.4897459439681113"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.17754480036856"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.120482639244975"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.957543714153906"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.6915163749882132"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.5351401772956095"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.84650367854062"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.3008930796674045"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.7462403975154053"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.090388217471424"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.19722524492799"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.3523350753735435"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.634356378342288"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.017207828029889"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.9540577813549276"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.372202687012912"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.6886191506880612"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.155124584183532"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.9653770039065757"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.7452098007960135"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.224799099583335"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.9570604258355857"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.326156329052801"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.8404305482534355"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.5954599219821786"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.718301967642965"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.5196162092489454"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="6.248738339999397"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.5760457364237035"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.7196868123149227"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.3064677989602926"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.0928204774729995"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.7165480374450226"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.6282490443168265"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.516339652320832"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.301327519335588"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.707395820522385"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.7324690418963384"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.669357358338123"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.985666142339397"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.916749749018662"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.871528121613095"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.455609364407261"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.6006883059239185"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.5941086836777938"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.4271909184034373"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.038803247719515"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.0551576367662805"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.223956205646268"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.41903811115858236"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.7430145598627587"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.908319110251303"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.12776952734542"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.2522555790439798"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.6531752729384146"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.9918992676840643"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.722264364078754"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.805669818428477"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.732508807547883"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.507747011001414"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.5809219719281646"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.9939569808701543"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.7158085160915926"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.3886366176818026"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.1784350756099244"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.9864868528220203"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.485762593569535"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.015506868729728"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.217414657683214"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.7086443606578743"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.9156597217681943"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.779485588977572"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.584659465713811"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="7.581002073413234"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.1062139019784263"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.6229743200266162"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.2807881518257851"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.971234561862042"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.5654081881621905"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.02894234554884423"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.2764017106859773"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.5229848946638702"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.4435949569286315"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.6983094098758249"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.018281479877404"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.6310772951816479"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.1856472602231887"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.4967484251697103"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.0195626477719106"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.4574489086430664"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.069133173745043"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.4359102378724227"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.5944739684552873"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.1401764720408365"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.5254210764910536"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.718776189294029"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.9893729685287083"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.257329317742806"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.3039865220731475"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.19165155472648032"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.9463699829759931"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.23920174975067887"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.9810609419778709"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.97273661014353"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.34245289917299815"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.999724066497365"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.3547730602563384"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.159281967968975"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.8340318774656329"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.300610704778349"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.9174779632567915"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.2657463054973664"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.1906897367786617"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.1780439641145195"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.256506295618944"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.7708438850253418"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.2186901221697022"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.750944493215658"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.246879227516376"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.9369545997521689"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="-0.04337248312985631"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.7112509364324147"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.073615026318971"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.5368295463079424"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.6550567885802394"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.247694619610823"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.9258077830355247"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.9943081158616198"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.0111382087617455"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.0067829621562687"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.9626763253091696"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.2910614373050682"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.3330769794280461"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.7395769532424543"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.7897326218338871"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.08568300986844768"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.15280140669489728"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.4587111924806484"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.235369111290991"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.6286527345001793"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.3884679293629263"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.937718761890737"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.6866654548312985"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.5561292807291988"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.7415159606347438"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.5426953875102578"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.0571116578840187"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.4870568560393194"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.9293601559246527"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.595550698916744"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.375634483566445"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.7673678089994173"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.471789577499624"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.2305486090124511"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="7.885151902573053"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.03819363643229434"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.370509815916221"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.45305162185866177"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.611074488658981"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.461282786134297"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.107573860714943"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.1798259413788648"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="6.3983222235809265"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.395336884989103"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.6430108106600567"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.11588099268079377"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.1622996080196"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.5124529111472915"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.3566798987455115"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.47692840072265397"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.479494544112524"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.4975481924231743"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.1235541628807457"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.5258458534750483"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.494157994328715"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.764838603061843"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.152411328174559"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.4491035557217287"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.1509491145879238"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.3723269858548062"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.573746749840816"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.10221959884726406"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.6595206380207643"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.2876189783580019"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.6182423716556387"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.42442222633448745"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.801534856617833"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.641310072444019"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.292389097483381"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.463748758208476"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.3449179180679913"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.4128490596777215"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.20727466331239"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.5894273424417866"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.4040103037282494"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.5663350110633839"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.47125341276884"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.437895630188148"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.841221367153364"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.41699395911954995"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.74572989104253"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.3249676142564404"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.7585868331622616"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.8216332695974025"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.9396348118508784"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.367536843701795"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.577630813769758"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.5828105655760694"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.827251586445209"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.2725743153750315"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.784458785031267"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.4036178241514015"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.66579756613555"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.9390001908812287"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.877826482852944"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.43311309563025957"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.486322422616845"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.407739923841305"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.22340893979040466"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.32779299838147613"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.232909624082353"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.604586917811126"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.2385185003882575"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.4603784029308384"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.6103201428049627"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.2786897821829653"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.26312828112475883"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.7405641007774193"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.059958115349032"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.1448642829003743"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.2227967165899083"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.248138976727023"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.888054634384161"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.8509656487503041"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.7308976382071644"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.3116592565271237"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="8.046396423836741"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.4642956861250833"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.1592363355184405"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.7529818173766696"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.15854683301705"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.7547102117992694"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.8331930661748694"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.637786640201013"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.645894599264239"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.6569324573651443"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.714923314447094"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.244832235061338"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.853041960193401"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.0494538293998423"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.2777091768852826"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.7174421984055255"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.415967902567363"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.3724972045462582"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.0727474147767633"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.4844353548424527"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.10337856581499"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.557942171679293"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.177964927823362"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.8922819889018667"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.247729499374707"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.5015047305649998"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.2800803581985836"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.609095590850012"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.684267449562146"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.9476792005657171"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.4187184695028225"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.39621053496652214"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.1676784404552105"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.1519070886802005"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.4650001743450167"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.4732096411475215"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.164248794512923"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.9868066174771646"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.665703521916186"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.739182765138596"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.131369065475991"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.2040455216921053"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.9076461318214797"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.281453498838182"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="6.788098261010803"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.2652014455572407"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.6333073505710765"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.0201531587564183"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.294787202286943"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.861853176354198"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.589384076016433"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.4112782413211695"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.682694157879746"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.4916960197726392"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.23773790378339665"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.520897498111525"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.2231759114817775"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.346990303890021"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.7022046419248316"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.8027932665223996"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.1304013618826065"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.0812127828062064"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="6.544431457853582"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.7676300483356062"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.894013371486796"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.3666421038852492"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.6756476010181514"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.159810580047873"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="6.02362339726942"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.93568507972031"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.149772914557835"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.210180530911559"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.208578002483593"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.766987142717255"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.966764944341068"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.9519634056681663"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.5607163521643614"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.5199815008253492"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-11.53187233347421"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.6538181897327604E-4"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.2436869627490723"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.078961307020946"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.9234267168283843"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.2112096767670275"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.0925823239656645"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.502726478254833"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.19953291288726"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.276844720311374"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.2428860074353927"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="7.5751620191842335"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-12.106537501837485"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.3243301318098553"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.8478878150503224"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.127217908207601"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.083926737818251"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.9268354529390883"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.469953077653617"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.386952907408752"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.888748411120027"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.848591201570675"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.724565972124435"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.798505731756608"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.234652227016215"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.2695452749274805"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.077815299392353"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.876699118570627"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.882989206155652"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.4684525904827646"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.968061448589116"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="8.405817439001408"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.637734783827352"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.867147753017986"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.528636168012401"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.067041269648371"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-9.284487286106497"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.5067837709411265"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.9790369753998971"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="7.224750470289612"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.368090540042319"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.5569070654621004"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.46021249662176933"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="7.639532151312748"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-11.879675559036876"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.6835398861133162"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.9179169574610606"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.210677043173776"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-9.013357566514747"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.8924469421401064"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.2134966024110208"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.976018105139864"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.6002313662356213"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.7126942988575817"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.7958902887552748"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.146101737799518"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.4568094128885756"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.4040408087188174"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.951101906605271"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.769730504458508"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.496226923012796"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.3033222143975296"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.899821909858381"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.675271832004914"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.445406058769558"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.384854231199475"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.7951571880531674"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.148076819955088"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.9962756958445986"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.4383612758362965"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.765896740180583"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.466278881708964"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.8750993600402666"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.37086062411036114"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.920456122928667"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="7.124899748737746"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.615635267446561"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.582672811496229"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.7893566483958305"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.40378185194665495"/>
      </enumeratedValueSet>
    </subExperiment>
  </experiment>
  <experiment name="ETH7" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>(ticks = 600) or ((min price-record) &lt; 1e-5) or ((max price-record) &gt; 10000)</exitCondition>
    <metric>token-price</metric>
    <metric>last price-record</metric>
    <metric>token-trade-volume</metric>
    <metric>user-base</metric>
    <metric>platform-productivity</metric>
    <metric>unlocked-token-supply</metric>
    <metric>seed</metric>
    <enumeratedValueSet variable="intra-period-trading-rounds">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-optimization-step-size">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-token-price">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-user-base">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="token-unlock-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="risk-free-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="annual-discount-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="annual-per-user-revenue">
      <value value="23.67"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="participation-cost">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-return-belief">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-window-length">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-window-length">
      <value value="365"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-token-supply">
      <value value="5201438"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="supply-inflection-ticks">
      <value value="239.20867425"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pre-token-issue-rate">
      <value value="6234.13173191"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pre-supply_doubling_tick_length">
      <value value="54592.74306914"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="post-token-issue-rate">
      <value value="5327.49443937"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="post-supply_halving_tick_length">
      <value value="324.0944231"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="supply-cap">
      <value value="100000000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="supplied-via-reward">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="supplied-via-exchange">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-serviceable-available-market">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="growth-inflection-ticks">
      <value value="116.579825"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pre-market-growth-rate">
      <value value="8.31137145"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pre-inflection-market-doubling-ticks">
      <value value="992.567141"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="post-market-growth-rate">
      <value value="60.3736513"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="post-inflection-market-halving-ticks">
      <value value="9999.94059"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-from">
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schedule-horizon">
      <value value="600"/>
    </enumeratedValueSet>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-7.298800073733657"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.443956332230304"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.756503169977915"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.805052785226988"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.20817282304793938"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.064089475581284"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.754390755803642"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.8764837399323895"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.2585803093074519"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.732856057858468"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.534811058162989"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="7.418222501398256"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.0915420705232455"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.439549456248445"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.406197434128856"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.348732761666172"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.4496160852155153"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.765745532638151"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.373406530880086"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="8.451207731948653"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.324722095171596"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.141869586798348"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.4650103392074234"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.787691856237518"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.187988207017215"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.755647961530419"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.9511271804289767"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.290877785462495"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.296949179124571"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.237096471541142"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.0408037762014115"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.161998723225871"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-7.665284436080519"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.9629355410654625"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.1328649033684974"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.715427533953083"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.396664455663069"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.539852288605857"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.4827658277861717"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="7.245946041124035"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.9341761624116725"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.814985402220507"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.492623395913451"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.3892939055841773"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.272792936419733"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.926984037804354"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.483510713289803"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.539187077973903"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.240624762171166"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.237618018446689"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.8587573355559672"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.097033454618127"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-7.397961479173572"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="6.359247607276637"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.503652286165581"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.590750920724594"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.5486431156461125"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="6.052853241049609"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.770126158670196"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.715770045915981"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.581734341456557"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.893984658602477"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.8795004711483547"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.4474172164382875"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.934132001425434"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.7682803224619255"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.8321231440530275"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="9.056248202709458"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-9.504023178798008"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.709056545708639"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.170683208353802"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.3197942169909833"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.2345921749932263"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.8397286712868346"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.531157145143125"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.8254607863669126"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.603893196682905"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="9.07620207991661"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.9249149875879057"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.973910463570492"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.308782585727345"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="7.252441555838896"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.859341288022549"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.123980378259455"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.5778219716863162"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.3491449806443594"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.3130124066439146"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.065819300009936"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.117831175166497"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.3026311039627914"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.1500910042473524"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.3533795522619085"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.85805917958137"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.0746735285009623"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.4208613865983253"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.112518666084789"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.5440945271015645"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.6422122019881533"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.171164972912778"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="8.36721552605399"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.8523913147288074"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.561941777402733"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.5316483802379004"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="7.929033103049869"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.7786078996647496"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.651981544189569"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.1026391722646895"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.117818686609612"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.4359254211461121"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.2568602452993285"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.6023926060120752"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.517063415292003"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-7.021559883706977"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.0609238183425083"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.533521989784445"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.70403293119921"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.2714824963676294"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.25876660860890155"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.503577935367277"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.5995809799066025"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.7354749807465522"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.6406494238072105"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.80741582666035"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.9923463278199036"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.35299433391475676"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.0822982131779386"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.869867565139019"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.214122063693557"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.7786392784787775"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.904215814735363"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.5955431133173006"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.1285426340098184"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.4848952725811733"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.505172191733286"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.081393981287298"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="9.717613221589577"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.0566822225855"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.083519912666857"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.9559704832650997"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="7.844878377722164"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.9605677205190541"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.304180097769578"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.444379346035412"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.6898576012284776"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.9776785923936213"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.102812575327354"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.8834383100649648"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.5608667720080955"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.6781121349315464"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="6.019763061535003"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.0357751594872533"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="8.146067971272478"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.372614851969997"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.072825024478694"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.6382406829080867"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.35492377760383"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.6276021890409114"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.3979587794129351"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.557559023579668"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.519776371108443"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="6.151278996565678"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.415227863922327"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.0577088622974"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.913841075828227"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.9278340738853394"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.796158604601644"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.850977880648946"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.1241676788288375"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.1319843331504487"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.858204166560316"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.87200110991996"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.9709399253221307"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.8690724003721737"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.1547199701874895"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.778762937466688"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.7868524485699002"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="7.35710506477968"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.114804989023995"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.186841627848923"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.704135138400149"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.706253436560931"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.147176265637745"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.9751891564982964"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.3669037440577956"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.058421603442486"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.3543840087219152"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.354592431446631"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.4617058326135952"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.9833318269470221"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.15750401746172527"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.446392409786677"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.9303941730155987"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.0739408795019845"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.9742189072468814"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.21388445559397"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.075252166359"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.7638561390992495"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.7882467570736802"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.78005348158088"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.3072497245332928"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.9050089257408132"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.8147497060531763"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.901690859935447"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.3191459436002866"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.321768121863345"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.908612918804758"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.54646389426454"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.8120514896840265"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.0705543486452194"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.935673700902994"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.01884768196726"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.6273186667569133"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.40582178521133416"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.530320619269474"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.442291584885838"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.38062243761855286"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.1924043848089485"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.290970953024522"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.9357819837030705"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.682272715609921"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.8518800594013776"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.1535522020103905"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.1530685699862353"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.6962342346553676"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.32365033979770086"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.432192326087043"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.1133629540541685"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.73676120782022"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="6.051688336141659"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.71982132425621"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.5109039718839274"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.398193219536212"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.5990786286874172"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.1928465272351323"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.33480853949371"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.676249676799452"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.9959130831913563"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.842513240754712"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.00730410673717"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.0282524316496895"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.220310081798692"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.0097563562694987"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.27837428965461"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.9936774212623893"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.368979723035312"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.18343492634116"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.580006944936621"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.31812338351870606"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.8678548435613016"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.5797147655424633"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.799051443238726"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.370237955196347"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="5.731305592649804"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.7343544660019908"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.634486184567755"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.18527695992260274"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.4124688383617934"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.5077428337853753"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.0809963135389093"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.846156712495401"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="5.000252445576164"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.8742962513652839"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.0531835860512713"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.2865751926327174"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.3560297340104874"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.16132577483765465"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.842686722160684"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.8032787081905646"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.3650077700577428"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.09320487672326971"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.41476405106512"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.2089678950205593"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.6038197254751316"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.3637844323237394"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.675908943735881"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.6627598683060465"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.2347175952631808"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.13222233590619392"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.409906492802482"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.2649732365287165"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.2396136664709494"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.9683964210216921"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.575368063226581"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.5712966745630266"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.599051588793511"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.038070333350507"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.7401439184223975"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.6571232472094235"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.451974057181783"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.684598547863027"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.023392519566444"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.46830880608766"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.6193317344495615"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.3713149370532083"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.3224095790745345"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.38663482780682745"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.9351590540731711"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.4849811601501606"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.552769543575591"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.7670861082175253"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.9196552311356334"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.4640006005283053"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.071609175399787"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.45471470397687397"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.8455765017568062"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.4172468125170213"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.354151496773049"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.9529612623212538"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.996722870153636"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.2608836855482749"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.9037007975700675"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.676905868756602"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="9.766210701165733"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.3324007724759297"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.501533437959597"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.7208132974967192"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.5995996434667896"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.5531945435169723"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.064294473771431"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.3485544634985192"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.247352945705896"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.578220097686881"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.0710693735228958"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.869251282199666"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.8556624899528105"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.6397688965228143"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.3317605683910063"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.6693871124010595"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.777558499839988"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.3192573365787785"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.08529253804171"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.009542401853961"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.8376641909774887"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.7033658779269913"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.255401121632429"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="7.055808985487826"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.757862730969953"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.062414396224932"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.1429125079501743"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="7.843196234471231"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.10455697119286178"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="7.69935629760213"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.7482605652895176"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="7.7710758127603565"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-10.594274831535689"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.00131596107088"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.8742216455403873"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.53971537481694"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.076970208550903"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="7.4598571713608735"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.873741979943306"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.1971040519133838"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.883544460266353"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.789169091161269"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.6045200652515827"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.395477871236585"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-10.38099286082635"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="7.249399395907923"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.223298372854016"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.1295488850671154"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-8.803164286799142"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.122578738595892"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.4619787940928184"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.155850659744976"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.997876193311961"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.258990051665071"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.953452804091587"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.896455770197214"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-7.65861724020633"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.065631898180567"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.3060337116961307"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="6.181440746968889"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.8374724503083724"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.658672028331467"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.769185044656344"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.8005927060747493"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-8.245187683089167"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.8591478910069354"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.6498877301647297"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.575048262047093"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.134773622774354"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.5642928376653589"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.7217489780096704"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.027850537391145"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-7.9827394903144935"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.711305973593706"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.1283414505631186"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.9526149423635966"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-8.610829079306242"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.847676765811032"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.180414513331407"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.919775606258985"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.829874805936889"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.587113349747898"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.1314043737673614"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.498757812429428"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.738921999784956"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.15441508731826392"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.1134263767227752"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.931544937111083"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.142012803678751"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.551042277254688"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.6529293608984974"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.9944792697946073"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.630346984179051"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.1415390447700586"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.449404233584985"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.7740088293239795"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.21147626824067783"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.31691604615717806"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.5745858204920644"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.2196662491690025"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.213443138594658"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.655681413258992"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.26015698658198"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.3811346589216"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.66291062885971"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.3129206094666928"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.1363199152304695"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.7878436154029156"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.0743645528358305"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.3148687350830452"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.4686732197609713"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.7435678603076408"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.40618757312767967"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.1413992067469763"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.165044930228674"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.011305274626797"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.296905020724642"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.6493680901494836"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.847414480670631"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.7161261726620468"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.9044506666261585"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.497821295510089"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.4357284571228086"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.7631689146803514"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.022704688131849"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.7575146067707874"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.821318618406579"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.3443909590654919"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.0457927235305524"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.373097130436386"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.6831731128756204"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.5363547501537265"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.3851686421100284"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.7448864919736994"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.8787055379934934"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.8952259125381544"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.3618670941975207"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.8137673929964289"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.2012448718970274"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.08259222225947105"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.7434566054814438"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.353486402593097"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.3833815070447986"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.097624080770877"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.183067918354567"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.1556987200383917"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.1028528795141237"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.1914424962883228"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="6.621480380535443"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.0539262388934185"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.360010268576501"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.4998549436004843"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.901773843797239"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.28438453281782605"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.0712548548629623"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.5005711319463169"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.176546545700563"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.003606324564101"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.363396298242877"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.9202784778406482"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.373720825648632"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.3022978689008742"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.1135736075020763"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.0910679742035851"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.354739630787054"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.9025764043289969"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.5552200620325705"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.9238602699209175"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.7428526582414627"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.576490878517455"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.3105094181893848"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.6178390921261405"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="6.633330150271925"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.062325267294638"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.471527337144592"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.2634111690756042"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="4.754224410143749"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.578259160683755"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.2970751180576521"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.957846985436773"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.4827925338617924"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.8562785550356103"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.45614279154792436"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.4007680211979254"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.3934735707772087"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.8872147811643887"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.4696506228250485"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.4546307491252755"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.8572766111855008"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.6172468652278966"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.1514023484400069"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.254655983448428"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.281483988621195"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.9893292010411701"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.7357595839524389"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.8874331456998292"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.8465766764545712"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.6955910691436175"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.070577761470218"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.240169425155507"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.042088842822939"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.19305879577641438"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.0892085340358983"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.33203393680437"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.5446600544711777"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.2840057267079619"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.1613909161598905"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.468305656369084"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.22396636503328615"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.6279908136863313"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.3905909259754345"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.22680950038086"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.6273518380725296"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.1576993681134835"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.8016221980801874"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.710107396321963"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.9095616988400035"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.3559276852938544"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.560287830156859"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.476103992385833"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="5.0412460229949145"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.2948372716887744"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.048478325690736"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.5354703281098763"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.1282872424595508"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.6684472303292078"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.6267101797479695"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.7571636009639984"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.536061185859076"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.5488631396185641"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.7422455189436399"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.3821728039432186"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.15913292975962978"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.320693275350864"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.9423826660384402"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.850688695536872"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.5174464324723544"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.399559985710025"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.3219028202789214"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.360022039029493"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.0892992594277815"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.2266729947740045"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.4285037341480513"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.973516381024313"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.9412292723747733"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.4945980981422067"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.3919822176293795"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.706517097234315"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.834066196712594"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.9361751317173141"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.8795645996072958"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.34782687843499893"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.3890610420298488"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.250944352185689"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.675961329318625"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.534373806626757"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.5660771670638456"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.631364709870704"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.87970341625078"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.8321064681615273"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.7180306217262351"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.471116074351318"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.157645725933848"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.4922407021236991"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.8362741279081445"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.801433636935827"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.9949242007467085"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.6588871310279122"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.2772768287230682"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.05287110110384963"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.504044314793346"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.090456249211377"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.07636436115127315"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.256072418142409"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.3551228736624"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.192198162695059"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.1208774566206596"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.9050207468000981"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.290555086827309"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.2991118815961467"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.570871982928553"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-1.022635889946344"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.2461733006379703"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.0823970883166316"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.960705167647699"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.10562201618312561"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.124512538351443"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.6218065628125521"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.6038818857439838"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.0066049386277083"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.5618326166359875"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.2905454838648046"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="3.0831201911450257"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.0266269373394343"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.308749520867051"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.552200394346067"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.379287260974153"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.155291817491215"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.6497458303486754"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.6683281382020604"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="5.902478537246037"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.5005689388279773"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.3447770717224166"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.0367236266831554"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.38954189043792997"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.7500279580339134"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.907997139493438"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.0463582569428547"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.6137603113309994"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.647058617055415"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.5037467179863826"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.011513762181064"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.1751499928858913"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.756686230345759"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.274637446000125"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.9323233493409484"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.6491149719672527"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.8651740475130091"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.1171327307356087"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.06604479035942412"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.7191725510704285"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.160076021704789"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.255721918425273"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.38679323069674926"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.5798180329532645"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.9258235934299526"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.063608431786191"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.17700877833207207"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.228042088229377"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.6053049633452368"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.427188455950179"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.7605823179668283"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.8231598465937386"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.3430907602076432"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.960672656529762"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.26086277004847513"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-7.638170291743511"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.3305820016891072"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.6647094837055163"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.4201047187702915"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.28348065830758085"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.858801116574296"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.1378261866055475"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.045700460384704"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.4757804189557904"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.2400358942466474"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.1841266730522166"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="7.16389533485523"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.3784298356556282"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.8672687490025761"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.474588687914079"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="1.6640273149777318"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.109563431758417"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.163293052964353"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="5.400098338669983"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.86290540676838"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.8404703900787895"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.36507057583782165"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.365611794790361"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.82738892898487"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.1525654964983079"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.6825879040538558"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.5689828833369037"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="8.630383961214047"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.247144995584386"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.1203854651291536"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.1179239664611385"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.0195386344417345"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.108091442687081"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.4695105424644437"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.8719312798815837"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.6036712467625267"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.888631818129461"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.779884516956756"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.8465333094791254"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.2881702366544974"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.460572942957227"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="4.268809057500056"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.3939744299801156"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.007992972785463"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.6060291451096151"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.7664462430765795"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="4.429592729128464"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.660197951898761"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.090101181998904"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="3.423746558584322"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.3795957650653534"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.10870995589605004"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-6.124998654750286"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.7185441207971306"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.6532255218192464"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.054053900058002"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.3733054200271244"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="5.319560869470549"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.5624226759423303"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.5057904839719978"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.6652905631547643"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.2902104827996115"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.7460156159995956"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.653722276521571"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.0025404041571372993"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.5715976745938178"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.1001681427528562"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.311795018052959"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-4.0722402175773285"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.3102536964369293"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="3.090206915751878"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.568883501905097"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.1617522836890768"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.629552462512668"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.4934596933122567"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.713159235701389"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.8106894703166923"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.7397853007956069"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.0133366543125533"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.406553144430873"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.9706791887567419"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.822929221467855"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.8927095834884302"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.3003750442186437"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.6283460394428224"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="2.3987922929632397"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.1597086847295861"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.7427341551141255"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.125625330202123"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.1020344177555406"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.36743053995097"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.5098534368695518"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.4734989361129351"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.5035578654525155"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.9648178126979756"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.62261405167207"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.26240928837461475"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.6123263337291749"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.0306358696361593"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.1174795191322815"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.425796141159541"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.6989317877859929"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.7724167756564203"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.0347559596639133"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.250935900323832"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-3.403677581644359"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.7041198444233535"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.382576580584255"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-5.279567995428624"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.6122682929640746"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.9534025575392069"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="5.854434473349324"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.5466690843003198"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.310585138967514"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.5394729172946864"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.3500968357948402"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-1.755988586237608"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.3675368522056606"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.5451261817356885"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.6801531435643597"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="0.16881421558426046"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-0.3516483491415925"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="-0.9972348497897625"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="0.15787274045097632"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.1465796668086257"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.19153216052224387"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.6328784299082884"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.2434169848351875"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="2.326483254169193"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="0.5942488463588464"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.9166001773345887"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.6338625448767545"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="1.2181872444989563"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.7306471678235118"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.4083256722491495"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.122257187520079"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-7.768055300061431"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.9191450315672485"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.6036274670770587"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="3.3166062787400477"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-3.0922525853485014"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.877161492452181"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="0.7684987882802724"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="2.457885679184531"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-2.237935675281874"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="-2.030825490584677"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="1.7747101129900795"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.9525805272147"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="log10initial-productivity">
        <value value="-0.9773644949710778"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-mu">
        <value value="1.9950426839166875"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="productivity-sigma">
        <value value="2.5101323099010564"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="transaction-need-std">
        <value value="4.004138504608358"/>
      </enumeratedValueSet>
    </subExperiment>
  </experiment>
  <experiment name="ETH-optim" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks = 600</exitCondition>
    <metric>token-price</metric>
    <metric>last price-record</metric>
    <metric>token-trade-volume</metric>
    <metric>user-base</metric>
    <metric>platform-productivity</metric>
    <metric>unlocked-token-supply</metric>
    <metric>seed</metric>
    <enumeratedValueSet variable="intra-period-trading-rounds">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-optimization-step-size">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scale">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-token-price">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-user-base">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="token-unlock-ratio">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="risk-free-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="annual-discount-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="annual-per-user-revenue">
      <value value="23.67"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="participation-cost">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-return-belief">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-window-length">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-window-length">
      <value value="365"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-token-supply">
      <value value="5201438"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="supply-inflection-ticks">
      <value value="239.20867425"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pre-token-issue-rate">
      <value value="6234.13173191"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pre-supply_doubling_tick_length">
      <value value="54592.74306914"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="post-token-issue-rate">
      <value value="5327.49443937"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="post-supply_halving_tick_length">
      <value value="324.0944231"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="supply-cap">
      <value value="100000000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="supplied-via-reward">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="supplied-via-exchange">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-serviceable-available-market">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="growth-inflection-ticks">
      <value value="116.579825"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pre-market-growth-rate">
      <value value="8.31137145"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pre-inflection-market-doubling-ticks">
      <value value="992.567141"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="post-market-growth-rate">
      <value value="60.3736513"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="post-inflection-market-halving-ticks">
      <value value="9999.94059"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-from">
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schedule-horizon">
      <value value="600"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="log10initial-productivity">
      <value value="-0.71008922"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="productivity-mu">
      <value value="2.61938938"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="productivity-sigma">
      <value value="2.5887754"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transaction-need-std">
      <value value="2.51246004"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
