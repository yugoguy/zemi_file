extensions [py csv]

; Version Explanation:
;; Main Components of this version's approach:
;;; 1. simulation of only one asset (stock) ... only agents who decided to enter this market is simulated, and decision until entering this market is not incorporated.
;;; 2. investor/trader bid-ask decision determined based on the assumptions on the decision distribution and change in distribution
;;; 3. price fluctuation based on continuous orderbook
;;; 4. high heterogeniety in agents configuration
;;; 5. high randomness in price determination process, rather than deterministic
;;; 6. financial theories as a emergent result of agent decision logics, not directly implementing financail theories

; Possible Developments: (will implement if I have time)
;; ⭐1. addition of new agents
;;; a. company ... buybacks, stock issue, reporting performance that affects investor's valuation, etc.
;;; b. brokers ... for short position & etc.
;;; c. multiple intermediaries ... to dynamically dertermine transaction cost
;; 2. adaptive agents
;;; a. investors/traders learn best strategy based on the past results (close to reinforcement learning)
;;; b. investor/traders use more sophisticated analysis and change in belief based on it (require more computation ...)
;;; c. leaving market based on percieved risk-return and risk-preference
;;; d. decision based on the bid-ask spread information
;; 3. more types of order expressed explicitly
;;; a. stop-limit order
;;; b. loss-stop order
;; 4. decision-process-based transaction frequency, rather than stochastic
;;; a. transaction decision based on the price and current position
;;; b. decision based on past trading result (e.g. net profit)
;; 5. multiple stocks as agents
;;;　⭐a. give agents choice to invest in which stock by what degree
;;; b. calculation of market porfolio ... can now consider systematic risk
;;; c. portfolio manager & hedge fund can be created
;; 6. financial derivatives
;;; a. exchange traded futures, options, etc.
;;; b. OTC forwards, swaps, options, etc.
;; 7. developments on initial price
;;; a. initial price as IPO
;;; b. initial price as a actual latest price of real stock, and agents' belief configured based on past performance of the stock
;; 8. agents' decision based on cognitive biases and irrationality/limited rationality in behavioral economics
;;; a. loss chasing
;;; b. gambler's fallacy
;;; c. loss aversion
;; 9. various types of orderbooks
;;; a. AMM
;;; b. Price Pro-rata matching (and other possible order prioritization and matching algorithms)
;; 10. other forms of return. income.
;;; a. dividends
;;; b. interests
;;; c. income as periodical increase in the budget.
;; 11. about bid ask amount
;;; a. bid-ask amount depending on the risk perception and risk preference
;;; ⭐ b. risk preference expressed as convex/concave mapping function from risk measure to bid-ask amount
;;; c. degree of risk preference expressed as degree of concavity/convexity
;;; d. many risk measures are relative measure, so difficult to implement in 1 stock market simulation...
;;; e. maybe value at risk may serve as a absolute risk measure, although it may require some computaitonal cost
;;; ⭐f. or risk factor as a observer intervention/stohcastic event and risk preference as agent heterogeniey
;; 12 other foundations of agent decision
;;; a. utility maximization based
;;; b. MPT based
;; 13 agent-agent (direct) interaction
;;; a. agent influencing others to buy/sell depending on agent's influencial power
;;; b. direct trading, lending/borrowing
;; 14. modelling seasonality
;;; a. market close
;;; b. final tax return
;;; c. seasonal external events that affect supply/demand


;_______________________________________________________________________________________________
;environment

;global variables
globals [
  bid-list ;ordered list of bid prices, where each price is present {bid quantity} times. For finding equilibrium
  ask-list ;ordered list of ask prices, where each price is present {ask quantity} times. For finding equilibrium
  stock-supply
  transaction-volume
  equilibrium-price-quantity
  historical-price

  filename

  records
  world-filename

  agents-filename
  agents-records

  seed
]

;make turtle class
breed [investors investor]
breed [intermediaries intermediary]

;set class local variables
investors-own [
  ask_
  ask-amount
  bid
  bid-amount
  init-position
  current-position
  init-budget
  budget
  value-belief
  decision-std
  past-bought-price
  discount-rate
  external-shock-effect
  permanent-shock
  last-sold
  profit-loss-balance
  window
  activeness
  active?
  long-term?
  trend-belief
  trend-belief-confidence
  mean-revert-speed-belief
  mean-revert-belief
  history
]
intermediaries-own [
  intermediate-type
  ask-orders
  bid-orders
]

;________________________________________________________________________________________________
;commands

to reset
  ; reset variables, ticks, plot. initialize price, agents, and stock supply
  clear-all
  reset-ticks
  initialize-agents
  set seed new-seed
  random-seed seed

  ; initial plot
  set-current-plot "equilibrium price"
  set-current-plot-pen "price"
  plot latest-price
  set historical-price []
  set historical-price lput latest-price historical-price

  if record-whole-world? [
    ; create world csv
    set world-filename "-world-data"
    py:setup py:python
    py:run "from datetime import datetime"
    py:set "world_filename" world-filename
    py:set "seed" seed
    set world-filename py:runresult "f'{datetime.now()}'+ f'{seed}' + world_filename + '.csv'"
    ;set records (list ticks seed latest-price ask-list bid-list stock-supply transaction-volume num-investor valuation-mean valuation-std decision-std-mean rate-of-investing rate-of-holding mean-revert-speed-belief budget-gamma-alpha budget-mean position-mean position-gamma-alpha current-permanent-shock-mean mean-shock-size shock-size-std shock-effect-depreciation new-investors long-term-ratio long-term-degree mean-window-length discount-rate-max num-active current-temporal-shock-mean value-belief-mean trend-belief-mean mean-revert-belief-mean num-long-term)
    csv:to-file world-filename [["ticks" "seed" "historical-price" "ask-list" "bid-list" "stock-supply" "transaction-volume" "num-investor" "valuation-mean" "valuation-std" "decision-std-mean" "rate-of-investing" "rate-of-holding" "mean-revert-speed-belief" "budget-gamma-alpha" "budget-mean" "position-mean" "position-gamma-alpha" "current-permanent-shock-mean" "mean-shock-size" "shock-size-std" "shock-effect-depreciation" "new-investors" "long-term-ratio" "long-term-degree" "mean-window-length" "discount-rate-max" "num-active" "current-temporal-shock-mean" "value-belief-mean" "trend-belief-mean" "mean-revert-belief-mean" "num-long-term"]]
    ; all global variables and ticks
    ; all investor-owned variables
  ]

  if record-agents? [
    ; create world csv
    set agents-filename "-agents-panel-data"
    py:setup py:python
    py:run "from datetime import datetime"
    py:set "agents_filename" agents-filename
    py:set "seed" seed
    set agents-filename py:runresult "f'{datetime.now()}'+ f'{seed}' + agents_filename + '.csv'"
    set agents-records []
    foreach sort investors [ x ->
      ask x [
        set history agent-config
        foreach history [ y ->
          set agents-records lput y agents-records
        ]
        ; need to create column name list too using python extension
      ]
    ]
    csv:to-file agents-filename [["who" "ticks" "ask_" "ask-amount" "bid" "bid-amount" "init-position" "current-position" "init-budget" "budget" "value-belief" "decision-std" "past-bought-price" "discount-rate" "external-shock-effect" "permanent-shock" "last-sold" "profit-loss-balance" "window" "activeness" "active?" "long-term?" "trend-belief" "mean-revert-belief"]]
    file-open agents-filename
    file-print csv:to-row agents-records
    file-close
  ]

end

to run-price
  ; update agent state
  update-agents

  ; compute orders, price, transaction volume, stock supply
  set ask-list ask-orderlists
  set bid-list bid-orderlists
  set equilibrium-price-quantity equilibrium
  set latest-price item 0 equilibrium-price-quantity
  set transaction-volume item 1 equilibrium-price-quantity
  set stock-supply latest-stock-supply
  set historical-price lput latest-price historical-price

  ; update agent position & budget
  make-transactions

  ; update plot
  plot-price
  if not plot-price-only [
    set-current-plot "bid-ask"
    clear-plot
    plot-supply-demand
    plot-share-hist
    plot-bid-ask-hist
    plot-budget-hist
    plot-position-hist
    plot-num-investors
    plot-netprofit-hist
  ]

  if record-whole-world? and ((remainder ticks world-record-per) = 0) [
    set records (list ticks seed latest-price ask-list bid-list stock-supply transaction-volume num-investor valuation-mean valuation-std decision-std-mean rate-of-investing rate-of-holding mean-revert-speed-belief-max budget-gamma-alpha budget-mean position-mean position-gamma-alpha current-permanent-shock-mean mean-shock-size shock-size-std shock-effect-depreciation new-investors long-term-ratio long-term-degree mean-window-length discount-rate-max num-active current-temporal-shock-mean value-belief-mean trend-belief-mean mean-revert-belief-mean num-long-term)
    file-open world-filename
    file-print csv:to-row records
    file-close
  ]

  if record-agents? and ((remainder ticks agents-record-per) = 0) [
    set agents-records []
    foreach sort investors [ x ->
      ask x [
        set history agent-config
        foreach history [ y ->
          set agents-records lput y agents-records
        ]
        ; need to create column name list too using python extension
      ]
    ]
    file-open agents-filename
    file-print csv:to-row agents-records
    file-close
  ]

  tick

end

to initialize-agents
  clear-turtles
  create-investors num-investor [

    ifelse (random-float 1) < long-term-ratio [
      set long-term? true
      set activeness 1 / long-term-degree
      set discount-rate 0
      ]
      [
      set long-term? false
      set window (random mean-window-length) + 1
      set activeness (1 / window)
      set discount-rate (random-float discount-rate-max) / window
    ]


    set value-belief random-normal valuation-mean valuation-std

    set mean-revert-speed-belief random-float mean-revert-speed-belief-max
    if mean-revert-speed-belief < mean-revert-speed-belief-min [
      set mean-revert-speed-belief mean-revert-speed-belief-min
    ]

    set trend-belief-confidence random-float trend-belief-confidence-max
    if trend-belief-confidence < trend-belief-confidence-min [
      set trend-belief-confidence trend-belief-confidence-min
    ]

    set external-shock-effect 0
    set permanent-shock 0

    set last-sold 0

    if initial-position-type = "equal"[
      set current-position position-mean
      set init-position current-position
    ]
    if initial-position-type = "random (uniform)"[
      set current-position random position-mean
      set init-position current-position
    ]
    if initial-position-type = "random (gamma)"[
      set current-position random-gamma position-gamma-alpha (position-gamma-alpha / position-mean)
      set init-position current-position
    ]

    set past-bought-price []
    foreach range current-position [
      set past-bought-price lput latest-price past-bought-price
    ]

    set budget random-gamma budget-gamma-alpha (budget-gamma-alpha / budget-mean)
    set init-budget budget

    set decision-std random-normal decision-std-mean 3
    if decision-std < 0 [
      set decision-std 0
    ]

    ifelse (random-float 1) < activeness [
      set active? true
      ]
      [
      set active? false
    ]
    ifelse active? [
      set ask_ random-normal latest-price decision-std
      if ask_ > latest-price + value-belief + external-shock-effect + trend-belief-confidence * window * trend-belief + mean-revert-speed-belief * mean-revert-belief [
        set ask_ latest-price + value-belief + external-shock-effect + trend-belief-confidence * window * trend-belief + mean-revert-speed-belief * mean-revert-belief
      ]
      if ask_ < 0 [
        set ask_ 0
      ]

      ifelse current-position > 0 [
        set bid random-normal ((mean past-bought-price) + value-belief) decision-std
        if bid < ask_ [
          set bid ask_ + 1
        ]
        set bid-amount random current-position
      ]
      [
        set bid-amount 0
      ]
      set ask-amount random floor (budget * rate-of-investing / latest-price)
      ]
      [
      set ask-amount 0
      set bid-amount 0
    ]
  ]
end

to update-agents

  ask investors [

    ifelse (random-float 1) < activeness [
      set active? true
      ]
      [
      set active? false
    ]

    ifelse active? [
      set value-belief mean (list value-belief (random-normal valuation-mean valuation-std))
      if long-term? [
        set window ticks
      ]

      if (budget <= 0) and (current-position <= 0) [
        set num-investor (num-investor - 1)
        die
      ]

      ifelse ticks > 1 [
        set trend-belief window-trend window
        if not long-term? [
          set mean-revert-belief mean-revert window
        ]
        ]
        [
        set trend-belief 0
        set mean-revert-belief 0
      ]

      set mean-revert-speed-belief (mean-revert-speed-belief + (max list (random-float mean-revert-speed-belief-max) mean-revert-speed-belief-min)) / 2

      set trend-belief-confidence (trend-belief-confidence + (max list (random-float trend-belief-confidence-max) trend-belief-confidence-min)) / 2

      set external-shock-effect (external-shock-effect * (1 - shock-effect-depreciation)) + permanent-shock

      set ask_ random-normal latest-price decision-std
      if ask_ > latest-price + value-belief + external-shock-effect + trend-belief-confidence * window * trend-belief + mean-revert-speed-belief * mean-revert-belief [
        set ask_ latest-price + value-belief + external-shock-effect + trend-belief-confidence * window * trend-belief + mean-revert-speed-belief * mean-revert-belief
      ]
      if ask_ < 0 [
        set ask_ 0
      ]

      let discount-exponent (ticks - last-sold)

      ifelse current-position > 0 [
        let reference-price (last past-bought-price)
        set bid random-normal (reference-price / ((1 + discount-rate) ^ discount-exponent)) decision-std
        if bid < ((latest-price + value-belief + external-shock-effect + trend-belief + mean-revert-speed-belief * mean-revert-belief) / ((1 + discount-rate) ^ discount-exponent)) [
          set bid ((latest-price + value-belief + external-shock-effect + trend-belief + mean-revert-speed-belief * mean-revert-belief) / ((1 + discount-rate) ^ discount-exponent))
        ]
        if bid < ask_ [
          set bid ask_ + 1
        ]
        set bid-amount random floor (current-position *  (1 - rate-of-holding))
      ]
      [
        set bid-amount 0
        set bid 0
      ]

      ifelse budget > 0 [
        set ask-amount random floor (((budget * rate-of-investing) / (latest-price + 1)))
      ]
      [
        set ask-amount 0
      ]
      ]
      [
      set ask-amount 0
      set bid-amount 0
    ]

  ]
end

to make-transactions
  ; ask investors with ask above equilibrium to buy to increase the position by ask-amount
  ; ask investors with bid below equilibrium to decrease the position by bid-amount
  ;let sell-transacted 0
  ;let buy-transacted 0
  let sell-volume transaction-volume
  let buy-volume transaction-volume
  if transaction-volume > 0 [

    let amount 0
    foreach (list investors with [ask_ > latest-price]) [ x ->
      if buy-volume > 0 [
        ask x [
          set amount (min (list buy-volume ask-amount)) ; remaining volume or asked amount
          set current-position (current-position + amount)
          set buy-volume (buy-volume - amount)
          set budget (budget - latest-price * amount)

          set profit-loss-balance (profit-loss-balance - latest-price * amount)

          foreach range amount [
            set past-bought-price lput latest-price past-bought-price
          ]
          ;set buy-transacted buy-transacted + amount
        ]
      ]
    ]

    foreach (list investors with [bid < latest-price]) [ x ->
      if sell-volume > 0 [
        ask x [
          set amount (min (list sell-volume bid-amount))
          set current-position (current-position - amount)
          set sell-volume (sell-volume - amount)
          set budget (budget + latest-price * amount)

          set profit-loss-balance (profit-loss-balance + latest-price * amount)

          set last-sold ticks

          foreach range amount [
            set past-bought-price remove-item 0 past-bought-price
          ]
          ;set sell-transacted sell-transacted + amount
        ]
      ]
    ]

    foreach (list investors with [ask_ = latest-price]) [ x ->
      if buy-volume > 0 [
        ask x [
          set amount (min (list buy-volume ask-amount)) ; remaining volume or asked amount
          set current-position (current-position + amount)
          set buy-volume (buy-volume - amount)
          set budget (budget - latest-price * amount)

          set profit-loss-balance (profit-loss-balance - latest-price * amount)

          foreach range amount [
            set past-bought-price lput latest-price past-bought-price
          ]
          ;set buy-transacted buy-transacted + amount
        ]
      ]
    ]

    foreach (list investors with [bid = latest-price]) [ x ->
      if sell-volume > 0 [
        ask x [
          set amount (min (list sell-volume bid-amount))
          set current-position (current-position - amount)
          set sell-volume (sell-volume - amount)
          set budget (budget + latest-price * amount)

          set profit-loss-balance (profit-loss-balance + latest-price * amount)

          set last-sold ticks

          foreach range amount [
            set past-bought-price remove-item 0 past-bought-price
          ]
          ;set sell-transacted sell-transacted + amount
        ]
      ]
    ]
  ]
  ;show transaction-volume
  ;show buy-transacted
  ;show sell-transacted
  ;show buy-volume
  ;show sell-volume
  ;show stock-supply
end

to send-shock
  ask investors [
    if shock-time = "permanent" [
      set permanent-shock (permanent-shock + shock-sign * (random-normal mean-shock-size shock-size-std))
    ]
    if shock-time = "temporary" [
      set external-shock-effect (shock-sign * (random-normal mean-shock-size shock-size-std))
    ]
  ]
end

to send-new-investors
  create-investors new-investors [

    ifelse (random-float 1) < long-term-ratio [
      set long-term? true
      set activeness 1 / long-term-degree
      set discount-rate 0
      ]
      [
      set long-term? false
      set window (random mean-window-length) + 1
      set activeness (1 / window)
      set discount-rate (random-float discount-rate-max) / window
    ]

    set value-belief random-normal valuation-mean valuation-std

    set mean-revert-speed-belief random-float mean-revert-speed-belief-max
    if mean-revert-speed-belief < mean-revert-speed-belief-min [
      set mean-revert-speed-belief mean-revert-speed-belief-min
    ]

    set trend-belief-confidence random-float trend-belief-confidence-max
    if trend-belief-confidence < trend-belief-confidence-min [
      set trend-belief-confidence trend-belief-confidence-min
    ]

    set external-shock-effect 0
    set permanent-shock 0

    set last-sold 0

    set current-position 0

    set init-position current-position

    ifelse ticks > 1 [
        set trend-belief window-trend window
        if not long-term? [
          set mean-revert-belief mean-revert window
        ]
        ]
        [
        set trend-belief 0
        set mean-revert-belief 0
      ]


    set past-bought-price []
    foreach range current-position [
      set past-bought-price lput latest-price past-bought-price
    ]

    set budget random-gamma budget-gamma-alpha (budget-gamma-alpha / budget-mean)
    set init-budget budget

    set decision-std random-normal decision-std-mean 3
    if decision-std < 0 [
      set decision-std 0
    ]

    ifelse (random-float 1) < activeness [
      set active? true
      ]
      [
      set active? false
    ]
    ifelse active? [

      set ask_ random-normal latest-price decision-std
      if ask_ > latest-price + value-belief + external-shock-effect + trend-belief-confidence * window * trend-belief + mean-revert-speed-belief * mean-revert-belief [
        set ask_ latest-price + value-belief + external-shock-effect + trend-belief-confidence * window * trend-belief + mean-revert-speed-belief * mean-revert-belief
      ]
      if ask_ < 0 [
        set ask_ 0
      ]

      ifelse budget > 0 [
        set ask-amount random floor (((budget * rate-of-investing) / (latest-price + 1)))
        ]
        [
        set ask-amount 0
      ]
      ]
      [
      set ask-amount 0
      set bid-amount 0
    ]
  ]

  set num-investor (num-investor + new-investors)
end

to refresh-price-plot
  set-current-plot "equilibrium price"
  clear-plot
end

;_______________________________________________________________________________________________
;report functions

to-report ask-orderlists
  let ask-ordered-investors reverse sort-on [ask_] investors
  set ask-list []
  foreach ask-ordered-investors  [ x ->
    ask x[
      repeat ask-amount [
        set ask-list lput ask_ ask-list]
    ]
  ]
  report ask-list
end

to-report bid-orderlists
  let bid-ordered-investors sort-on [bid] investors
  set bid-list []
  foreach bid-ordered-investors  [ x ->
    ask x [
       repeat bid-amount [
       set bid-list lput bid bid-list]
    ]
  ]
  report bid-list
end

to-report equilibrium
  ; Assume lists are correctly sorted
  let ask-index 0
  let equilibrium-price 0
  let equilibrium-quantity 0
  let found? false

  ; Iterate through the lists to find the equilibrium point
  while [ask-index < length ask-list and ask-index < length bid-list and not found?] [
    ifelse (item ask-index ask-list) = (item ask-index bid-list) [
      set equilibrium-price item (ask-index) ask-list
      set found? true
      let continue true
      while [continue] [
        ifelse (item ask-index ask-list) = (item ask-index bid-list) [
          set ask-index ask-index + 1
          carefully [(let next item ask-index ask-list) (set next item ask-index bid-list)] [set continue false]
          ]
          [
          set continue false
        ]
      ]
      set equilibrium-quantity ask-index
      ; Exit the loop once the equilibrium price is found
      ]
      [
      if (item ask-index ask-list) < (item ask-index bid-list) [
        ifelse ask-index = 0 [
          set equilibrium-price latest-price;item (length bid-list - 1) bid-list ; last item in bid-list
          set equilibrium-quantity 0
          set found? true
          ]
          [
          ifelse ((item (ask-index - 1) ask-list) != (item ask-index ask-list)) and ((item (ask-index - 1) bid-list) != (item ask-index bid-list)) [
            set found? true
            set equilibrium-price ((item (ask-index - 1) ask-list) + (item (ask-index - 1) bid-list)) / 2
            set equilibrium-quantity ask-index
            ]
            [
            ifelse ((item (ask-index - 1) ask-list) = (item ask-index ask-list)) and ((item (ask-index - 1) bid-list) != (item ask-index bid-list)) [
              set found? true
              set equilibrium-price item (ask-index) ask-list
              set equilibrium-quantity ask-index
              ]
              [
              if ((item (ask-index - 1) ask-list) != (item ask-index ask-list)) and ((item (ask-index - 1) bid-list) = (item ask-index bid-list)) [
                set found? true
                set equilibrium-price item (ask-index) bid-list
                set equilibrium-quantity ask-index
              ]
            ]
          ]
        ]
      ]
    ]
    set ask-index ask-index + 1
  ]

  ; If equilibrium not found, report the lowest bid price
  if not found? [
    set equilibrium-price latest-price;item (length bid-list - 1) bid-list ; last item in bid-list
    set equilibrium-quantity 0
  ]
  report list equilibrium-price equilibrium-quantity
end

to-report latest-stock-supply
  set stock-supply 0
  ask investors [
    ;show current-position
    set stock-supply stock-supply + current-position
  ]
  ;show stock-supply
  report stock-supply
end

to-report window-trend [investor-window]
  let window-start (max list (ticks - investor-window - 1) 0)
  let window-start-price item window-start historical-price
  let window-end-price item ticks historical-price

  let slope (window-start-price - window-end-price) / (window-start - ticks)

  report slope
end

to-report mean-revert [investor-window]
  let window-start (max list (ticks - investor-window - 1) 0)
  let window-price sublist historical-price window-start (ticks + 1)
  let window-mean mean window-price
  let revert-gap window-mean - latest-price

  report revert-gap
end

to-report agent-config
  report (list who ticks ask_ ask-amount bid bid-amount init-position current-position init-budget budget value-belief decision-std past-bought-price discount-rate external-shock-effect permanent-shock last-sold profit-loss-balance window activeness active? long-term? trend-belief mean-revert-belief)
end

to-report num-active
  let iamactive 0
  ask investors [
    if active? [
      set iamactive (iamactive + 1)
    ]
  ]
  report iamactive
end

to-report current-permanent-shock-mean
  let permanent-shock-list []
  ask investors [
    set permanent-shock-list lput permanent-shock permanent-shock-list
  ]
  report mean permanent-shock-list
end

to-report current-temporal-shock-mean
  let temporal-shock-list []
  ask investors [
    set temporal-shock-list lput external-shock-effect temporal-shock-list
  ]
  report mean temporal-shock-list
end

to-report value-belief-mean
  let value-belief-list []
  ask investors [
    set value-belief-list lput value-belief value-belief-list
  ]
  report mean value-belief-list
end

to-report trend-belief-mean ; multiplied by window
  let trend-belief-list []
  ask investors [
    set trend-belief-list lput (trend-belief * window) trend-belief-list
  ]
  report mean trend-belief-list
end

to-report mean-revert-belief-mean ; multiplied by revert speed belief
  let mean-revert-belief-list []
  ask investors [
    set mean-revert-belief-list lput (mean-revert-belief * mean-revert-speed-belief) mean-revert-belief-list
  ]
  report mean mean-revert-belief-list
end

to-report num-long-term
  let iamlt 0
  ask investors [
    if long-term? [
      set iamlt (iamlt + 1)
    ]
  ]
  report iamlt
end

;_______________________________________________________________________________________________
;plots

to plot-supply-demand
  set-current-plot "bid-ask"
  set-current-plot-pen "buy(ask)_orders"
  foreach ask-list  [ x ->
    plot x
  ]
  set-current-plot-pen "sell(bid)_orders"
  foreach bid-list  [ x ->
    plot x
  ]
  let all-list sentence ask-list bid-list
  if not empty? all-list [
    set-plot-y-range (round (min all-list) - 10) (round (max all-list) + 10)
  ]

  set-current-plot-pen "equilibrium"
  foreach bid-list  [
    plot latest-price
  ]

end

to plot-price
  set-current-plot "equilibrium price"
  set-current-plot-pen "price"
  plot latest-price
  ifelse (price-view = "close look") and (ticks > 10)[
    set-plot-y-range ((min sublist historical-price (max list 0 (ticks - close-look-window)) ticks) - 1) (max sublist historical-price (max list 0 (ticks - close-look-window)) ticks)
    if ticks > close-look-window [
      set-plot-x-range (max list 0 (ticks - close-look-window)) ticks
    ]
    ]
    [
    set-plot-x-range 0 ticks + 1
    set-plot-y-range min historical-price max historical-price + 100
  ]
end

to plot-num-investors
  set-current-plot "total investors alive"
  set-current-plot-pen "investors"
  plot num-investor
end

to plot-bid-ask-hist
  set-current-plot "bid-ask histogram"
  set-current-plot-pen "ask hist"
  let asks [ask_] of investors
  set asks remove 0 asks
  histogram asks
  set-current-plot-pen "bid hist"
  let bids [bid] of investors
  set bids remove 0 bids
  histogram bids
  set-plot-x-range round (min asks - ln (max list latest-price 1)) round (ln (max list latest-price 1) + max bids)
end

to plot-budget-hist
  set-current-plot "investor budget"
  set-current-plot-pen "budget histogram"
  let budgets [budget] of investors
  set-histogram-num-bars max list (length budgets / 100) 10
  histogram budgets
  set-plot-x-range 0 round (max budgets) + 1
end

to plot-share-hist
  set-current-plot "investor share"
  set-current-plot-pen "share histogram"
  let shares [current-position] of investors
  set-histogram-num-bars max list (length shares / 100) 10
  histogram shares
  set-plot-x-range 0 max shares + 1
end

to plot-position-hist
  set-current-plot "investor position"
  set-current-plot-pen "position histogram"
  let positions [current-position * latest-price] of investors
  set-histogram-num-bars max list (length positions / 100) 10
  histogram positions
  set-plot-x-range 0 round (max positions) + 1
end

to plot-netprofit-hist
  set-current-plot "net trading profit"
  set-current-plot-pen "net profit"
  let nets [profit-loss-balance] of investors
  set-histogram-num-bars max list (length nets / 1000) 10
  histogram nets
  set-plot-x-range (round (min nets) - 1) (round (max nets))
end

;_________________________________________________________________________________________________
; data download

to download-price-data
  set filename ""
  py:setup py:python
  py:run "from datetime import datetime"
  py:set "filename" filename
  set filename py:runresult "f'{datetime.now()}'+ filename + '-price.csv'"
  csv:to-file filename [["historical-price"]]
  foreach historical-price [ x ->
    file-open filename
    file-print csv:to-row (list x)
    file-close
  ]
end

to download-agent-cross-section-data
  set filename ""
  py:setup py:python
  py:run "from datetime import datetime"
  py:set "filename" filename
  set filename py:runresult "f'{datetime.now()}'+ filename + '-agentcrosssection.csv'"
  csv:to-file filename [["who" "ticks" "ask_" "ask-amount" "bid" "bid-amount" "init-position" "current-position" "init-budget" "budget" "value-belief" "decision-std" "past-bought-price" "discount-rate" "external-shock-effect" "permanent-shock" "last-sold" "profit-loss-balance" "window" "activeness" "active?" "long-term?" "trend-belief" "mean-revert-belief"]]
  ask investors [
    file-open filename
    file-print csv:to-row agent-config
    file-close
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
1040
28
1081
70
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
-16
16
-16
16
1
1
0
ticks
1.0

BUTTON
0
302
80
335
NIL
reset
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
0
10
321
180
bid-ask
quantitiy
price
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"sell(bid)_orders" 1.0 0 -5298144 true "" ""
"buy(ask)_orders" 1.0 0 -7500403 true "" ""
"equilibrium" 1.0 0 -13840069 true "" ""

SLIDER
162
346
322
379
latest-price
latest-price
0
1000
593.0
1
1
NIL
HORIZONTAL

PLOT
322
10
643
180
equilibrium price
tick
price
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"price" 1.0 0 -16777216 true "" ""

BUTTON
81
302
160
335
NIL
run-price
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
322
447
482
480
valuation-mean
valuation-mean
-50
50
4.264
0.001
1
NIL
HORIZONTAL

SLIDER
322
481
482
514
valuation-std
valuation-std
0
20
5.24
0.01
1
NIL
HORIZONTAL

SLIDER
162
379
322
412
num-investor
num-investor
0
10000
6804.0
1
1
NIL
HORIZONTAL

PLOT
161
181
321
301
investor share
share
count
0.0
1.0
0.0
20.0
true
false
"" ""
PENS
"share histogram" 1.0 0 -16777216 true "" ""

PLOT
0
181
160
301
bid-ask histogram
NIL
NIL
0.0
200.0
0.0
100.0
true
true
"" ""
PENS
"ask hist" 1.0 0 -9276814 true "" ""
"bid hist" 1.0 0 -2674135 true "" ""

PLOT
483
181
643
301
investor budget
budget
count
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"budget histogram" 1.0 0 -14070903 true "" ""

SLIDER
322
549
482
582
rate-of-investing
rate-of-investing
0
1
0.5
0.01
1
NIL
HORIZONTAL

PLOT
322
181
482
301
investor position
position
count
-10.0
100.0
0.0
10.0
true
false
"" ""
PENS
"position histogram" 1.0 0 -16777216 true "" ""

SLIDER
322
515
482
548
decision-std-mean
decision-std-mean
0
100
10.08
0.01
1
NIL
HORIZONTAL

SLIDER
162
460
322
493
budget-gamma-alpha
budget-gamma-alpha
0
100
3.0
1
1
NIL
HORIZONTAL

SLIDER
162
495
322
528
budget-mean
budget-mean
0
100000
18621.0
1
1
NIL
HORIZONTAL

SLIDER
852
247
1019
280
discount-rate-max
discount-rate-max
0
0.99
6.6E-4
0.00001
1
NIL
HORIZONTAL

CHOOSER
0
336
160
381
plot-price-only
plot-price-only
true false
1

BUTTON
644
72
837
106
NIL
send-shock
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
644
106
837
151
shock-sign
shock-sign
1 -1
0

SLIDER
645
200
838
233
mean-shock-size
mean-shock-size
0
500
79.1
0.1
1
NIL
HORIZONTAL

SLIDER
645
235
838
268
shock-size-std
shock-size-std
0
100
6.96
0.01
1
NIL
HORIZONTAL

CHOOSER
645
154
838
199
shock-time
shock-time
"permanent" "temporary"
0

SLIDER
645
269
838
302
shock-effect-depreciation
shock-effect-depreciation
0
0.99
0.41
0.01
1
NIL
HORIZONTAL

BUTTON
0
382
160
415
NIL
refresh-price-plot
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
852
75
1019
109
NIL
send-new-investors
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
852
109
1019
142
new-investors
new-investors
0
10000
1206.0
1
1
NIL
HORIZONTAL

PLOT
483
302
643
422
total investors alive
tick
investor
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"investors" 1.0 0 -16777216 true "" ""

PLOT
322
302
482
422
net trading profit
net profit 
count
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"net profit" 1.0 0 -16777216 true "" ""

SLIDER
852
144
1019
177
long-term-ratio
long-term-ratio
0
1
0.22
0.01
1
NIL
HORIZONTAL

SLIDER
852
213
1019
246
mean-window-length
mean-window-length
0
10000
370.0
1
1
NIL
HORIZONTAL

CHOOSER
0
416
160
461
price-view
price-view
"wide view" "close look"
0

SLIDER
0
462
160
495
close-look-window
close-look-window
2
10000
235.0
1
1
NIL
HORIZONTAL

TEXTBOX
174
417
324
456
initial income distribution parameters (not adjustable after starting)\n
11
0.0
1

TEXTBOX
650
56
800
74
external shocks parameters
11
0.0
1

TEXTBOX
862
44
1028
69
investors parameters (not adjustable after sending)
11
0.0
1

TEXTBOX
183
301
324
341
initial market configurations (not adjustable after running)
11
0.0
1

TEXTBOX
347
425
649
443
investor parameters (adjustable as market sentiment)
11
0.0
1

CHOOSER
162
564
322
609
initial-position-type
initial-position-type
"random (uniform)" "random (gamma)" "equal"
1

TEXTBOX
156
534
323
561
initial position configuration (not adjustable after starting)
11
0.0
1

SLIDER
162
644
322
677
position-gamma-alpha
position-gamma-alpha
0
100
5.0
1
1
NIL
HORIZONTAL

SLIDER
162
609
322
642
position-mean
position-mean
0
5000
100.0
1
1
NIL
HORIZONTAL

BUTTON
1034
244
1249
277
NIL
download-agent-cross-section-data
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
1034
210
1249
243
NIL
download-price-data
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
322
583
482
616
rate-of-holding
rate-of-holding
0
1
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
483
447
704
480
mean-revert-speed-belief-max
mean-revert-speed-belief-max
0
1
0.59
0.01
1
NIL
HORIZONTAL

SLIDER
852
178
1019
211
long-term-degree
long-term-degree
100
10000
5024.0
1
1
NIL
HORIZONTAL

MONITOR
644
10
837
55
NIL
current-permanent-shock-mean
17
1
11

SWITCH
1034
74
1249
107
record-whole-world?
record-whole-world?
1
1
-1000

SWITCH
1034
142
1249
175
record-agents?
record-agents?
1
1
-1000

SLIDER
1034
108
1248
141
world-record-per
world-record-per
1
1000
1.0
1
1
NIL
HORIZONTAL

SLIDER
1034
176
1250
209
agents-record-per
agents-record-per
1
1000
567.0
1
1
NIL
HORIZONTAL

TEXTBOX
1089
52
1239
70
data downloads
11
0.0
1

TEXTBOX
1038
282
1352
349
Once you have the agents cross section data, it is recommended to reformat dataframe using pandas (pd):\n\nagents = pd.read_csv(filepath, header=1)\ncolumn_names = pd.read_csv(filepath, nrows=1, header=None).iloc[0].tolist()\ncols = []\nfor i in range(int(agents.shape[1]/len(column_names))):\n    for j in column_names:\n        cols.append(j + f\"_{i}\")\nagents.columns = cols
5
0.0
1

SLIDER
483
481
704
514
mean-revert-speed-belief-min
mean-revert-speed-belief-min
0
1
0.49
0.01
1
NIL
HORIZONTAL

SLIDER
483
515
704
548
trend-belief-confidence-max
trend-belief-confidence-max
0
1
0.374
0.001
1
NIL
HORIZONTAL

SLIDER
483
549
704
582
trend-belief-confidence-min
trend-belief-confidence-min
0
1
0.007
0.0001
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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
