;;-----------------------------------------------------------------------------
;; ASE6104 Capstone Project
;; Rural Medical Support System [RMSS] - Simpilifed Demonstration Model
;;
;;
;; Author: J.K. DeHart
;; Date: 7/20/21
;;-----------------------------------------------------------------------------
;; Description:
;; This model builds upon the version V2.2. The idea is to step back and
;; model the exisitng structure per Gary's email
;; D-model drones only with eDrones for emergency only testing



;;-----------------------------------
;; declarations
;;-----------------------------------
extensions [rnd csv]
;; for random distributions see --> http://ccl.northwestern.edu/netlogo/docs/dict/random-reporters.html

__includes ;; Moved to end of code since includes do not work with commons
[ "utils/messaging.nls"     ; handles agent messaging
  "utils/sxl-utils.nls"     ; small set of NetLogo utilities
]

globals
[
  ;; set separate queuse based on need
  emergencyQueue

  ;; performance metrics
  avgResponseTimeStandard
  avgReponseTimeUrgent
  avgResponseTimeEmergency
  avgResponseTime
  ;; outputs for avg resposne at incriments for studies
  arte_out
  arts_out

  ;; drone attributes
  droneAttrs
  chargeConstant

  ;; payload mean weight
  payload-mean
  payload-max

  ;; temps testing
  tmpVar
  tmpList

  ;; Costing
  totalUpfrontCosts
  totalOperatingCosts
  estimatedSystemCostsPerYear
  startUpCosts
  minutesPerYear
  maintenaceCostPerMinute

  ;; Event counts
  emergencyEventCount
  standardEventCount
  totalEventCount
  emergencyEventPerHour
  standardEventPerHour
  totalTimeInDays

  ;;
  modelFitness
  scaled_avgert
  scaled_avgsrt

  ;; Build the drone list
  ;;numberOfDrones
  ;;chance_of_typeA
  ;;chance_of_typeB
  ;;chance_of_typeC
  dronesWord
  dronesCount
  droneList
]


;;-----------------------------------
;; breed data - for now lets use 4 breeds [couriers, drones, hubs, subhubs, hospitals, payloads]
;;-----------------------------------
breed [couriers courier]
couriers-own
[
  name
  payload_id
  payload_pickup_target
  payload_delivery_target
  reqType
  speed
  status
]

breed [drones drone]
drones-own
[
  chargeLevel
  forEmergencyOnly
  name
  payload_id
  payload_pickup_target
  payload_delivery_target
  reqType
  maxSpeed
  maxPayload
  maxBattery
  rechargeRate
  dischargeConstant
  dischargeRate
  status
  droneType
  target
  maxcharge
  dryWeight
  reqPower
  opVoltage
  allUpWeight
  avgAmpDraw
  flightTime
  maxDistance
  upFrontCost
  costPerKm
  eDrone
]

breed [hubs hub]
hubs-own
[
  name
  status
]

breed [subhubs subhub]
subhubs-own
[
  distanceToMainHub
  eventStart
  eventType
  forEmergencyOnly
  hasChargeStation
  inServiceRange
  medicalEvent
  name
  responseTime
  reqType
  speed
  status
  payloadWeight
]

breed [hospitals hospital]
hospitals-own
[
  distanceToMainHub
  eventType
  eventStart
  forEmergencyOnly
  hasChargeStation
  inServiceRange
  medicalEvent
  name
  responseTime
  reqType
  speed
  status
  payloadWeight
]

breed [payloads payload] ;; not gonna use these for now
payloads-own
[
  name
  origin
  target
  weight
  class
]

;;-----------------------------------
;; globals data - define performance metrics here
;;-----------------------------------

to setup-globals

  ;; performance metrics
  set avgResponseTimeStandard []
  set avgReponseTimeUrgent []
  set avgResponseTimeEmergency []
  set avgResponseTime []

  ;; emergencyQueue
  set emergencyQueue []

  ;; payload mean
  set payload-mean meanPayloadWeight ;; kg
  set payload-max maxPayloadWeight ;; kg

  ;; setup tmps
  set tmpVar 0
  set tmpList []

  ;;
  set chargeConstant .15

  ;;
  set totalUpfrontCosts 0
  set totalOperatingCosts 0
  set estimatedSystemCostsPerYear 0
  set startUpCosts startup-Costs ;; starup Costs
  set minutesPerYear 525960
  set maintenaceCostPerMinute maintenace-cost-per-hour / 60

  ;; counts
  set emergencyEventCount 0
  set standardEventCount 0
  set totalEventCount 0
  set emergencyEventPerHour 0
  set standardEventPerHour 0

  ;;
  set totalTimeInDays 0

  ;;
  set modelFitness 0
  set scaled_avgert 0
  set scaled_avgsrt 0

  ;; Let build the drone-types word here
  ;; Set the selected drone type to the maximum value of type A, B, or C
  ;; this is a bit inefficent but will work well with the SOBOL sampling method
  set dronesCount 0
  set dronesWord ""
  ;;set droneList [chance_of_typeA chance_of_typeB chance_of_typeC]
  while [dronesCount < number_of_drones]
  [
    let dtype droneSelection
    set dronesWord (word dronesWord dtype)
    set dronesCount dronesCount + 1
  ]

 set drone-types dronesWord

  ;; set these to current value of  avg respnses in go loop
  set arte_out 0
  set arts_out 0

end

;;-----------------------------------
;; setup breeds
;;-----------------------------------

to setup-patches
  ask patches [set pcolor green]
end

to setup-subHubs
  file-close-all ; close all open files
  if not file-exists? "data/emory_main_xy_locs.csv" [
    user-message "No file 'emory_main_xy_locs.csv' exists!"
    stop
  ]

  file-open "data/emory_main_xy_locs.csv" ; open the file with the turtle data

  ; We'll read all the data in a single loop
  while [ not file-at-end? ] [
    ; here the CSV extension grabs a single line and puts the read data in a list
    let data csv:from-row file-read-line
    ; now we can use that list to create a turtle with the saved properties
    if item 1 data != 0 ;; dont create the main hub at 0,0
    [
      create-subhubs 1 [
      ;;set name    item 0 data
      set breed subhubs
      ;;set name (word "subHub_" who)
      set name item 0 data
      set xcor    item 1 data
      set ycor    item 2 data
      set shape "square"
      set color 87
      set size 3
      set status "idle"
      if charger-network = True
        [
          set hasChargeStation probability-float(has-charge-station)
          if hasChargeStation[set shape "circle"]
        ]
      ]
    ]

  ]
  file-close ; make sure to close the file

end

to setup-hospitals
  if activate-hospitals
  [
    file-close-all ; close all open files
    if not file-exists? "data/hospital_xy_locs.csv" [
      user-message "No file 'hospital_xy_locs.csv' exists!"
      stop
    ]

    file-open "data/hospital_xy_locs.csv" ; open the file with the turtle data

    ; We'll read all the data in a single loop
    while [ not file-at-end? ] [
      ; here the CSV extension grabs a single line and puts the read data in a list
      let data csv:from-row file-read-line
      ; now we can use that list to create a turtle with the saved properties
      if item 1 data != 0 ;; dont create the main hub at 0,0
      [
        let rad (item 1 data ^ 2 + item 2 data ^ 2) ^ .5 ;; calulate the distance from 0,0
        if rad < service-range [
          create-hospitals 1 [
            ;;set name    item 0 data
            set breed hospitals
            ;;set name (word "hospitals_" who)
            set name item 0 data
            set xcor    item 1 data
            set ycor    item 2 data
            set shape "square"
            set color blue
            set size 3
            set status "idle"
            if charger-network = True
            [
              set hasChargeStation probability-float(has-charge-station)
              if hasChargeStation[set shape "circle"]
            ]
          ]
        ]
      ]

    ]
    file-close ; make sure to close the file
  ]
end

to setup-hubs
  create-hubs 1
  ask hubs [
    set name (word "hub_" who)
    make-msgQ (word "hub_" who) ;; stnadard queue
    setxy  0 0
    set color black
    set size 3
    set shape "square"
    set status "waiting"
  ]

  ;; lets kill hubs outside of the service range of hubs (emory)
  if service-range > 0
  [
    ask one-of hubs
    [
      ask subhubs in-radius service-range
      [
          set inServiceRange true
      ]
      ask subhubs with [inServiceRange != true]
      [
        die
      ]
    ]
  ]

  ask subHubs[
    set distanceToMainHub (distancexy 0 0)
  ]

  ask hospitals[
    set distanceToMainHub (distancexy 0 0)
  ]

end

to setup-drones
  ;; set up an empty list and read each drone type attributes into a list of list
  set droneAttrs []
  file-open "data/drone_data.csv" ; open the file with the turtle data
  while [ not file-at-end? ] [
    let data csv:from-row file-read-line
    set droneAttrs lput data droneAttrs
    ;;show droneAttrs
  ]
  file-close ; make sure to close the file

  ;; now create the drones using the drone-types list
  ;; discharge costant is used in an equation with speed and load
  let i 0
  while [i <= length drone-types - 1] [
    ;;show read-from-string item i drone-types
    if read-from-string item i drone-types != 0
    [
      create-drones 1 [
        if read-from-string item i drone-types = 1[
          set droneType sublist item 1 droneAttrs 0 1
          set droneType item 0 droneType
          set maxSpeed sublist item 1 droneAttrs 1 2
          set maxSpeed item 0 maxSpeed
          set maxPayload sublist item 1 droneAttrs 2 3
          set maxPayload item 0 maxPayload
          set maxBattery sublist item 1 droneAttrs 3 4
          set maxBattery item 0 maxBattery
          set rechargeRate sublist item 1 droneAttrs 4 5
          set rechargeRate item 0 rechargeRate
          set dischargeConstant sublist item 1 droneAttrs 5 6
          set dischargeConstant item 0 dischargeConstant
          set dryWeight sublist item 1 droneAttrs 6 7
          set dryWeight item 0 dryWeight
          set reqPower sublist item 1 droneAttrs 7 8
          set reqPower item 0 reqPower
          set opVoltage sublist item 1 droneAttrs 8 9
          set opVoltage item 0 opVoltage
          set upFrontCost sublist item 1 droneAttrs 9 10
          set upFrontCost item 0 upFrontCost
          set costPerKm sublist item 1 droneAttrs 10 11
          set costPerKm item 0 costPerKm
          set status "waiting"
          set chargeLevel 100
          set maxcharge 100
          ;;set dischargerate 0
          set dischargerate (chargeConstant * dischargeConstant)
          set size 4
          set totalupfrontcosts  upFrontCost + totalupfrontcosts
        ]

        if read-from-string item i drone-types = 2[
          set droneType sublist item 2 droneAttrs 0 1
          set droneType item 0 droneType
          set maxSpeed sublist item 2 droneAttrs 1 2
          set maxSpeed item 0 maxSpeed
          set maxPayload sublist item 2 droneAttrs 2 3
          set maxPayload item 0 maxPayload
          set maxBattery sublist item 2 droneAttrs 3 4
          set maxBattery item 0 maxBattery
          set rechargeRate sublist item 2 droneAttrs 4 5
          set rechargeRate item 0 rechargeRate
          set dischargeConstant sublist item 2 droneAttrs 5 6
          set dischargeConstant item 0 dischargeConstant
          set dryWeight sublist item 2 droneAttrs 6 7
          set dryWeight item 0 dryWeight
          set reqPower sublist item 2 droneAttrs 7 8
          set reqPower item 0 reqPower
          set opVoltage sublist item 2 droneAttrs 8 9
          set opVoltage item 0 opVoltage
          set upFrontCost sublist item 2 droneAttrs 9 10
          set upFrontCost item 0 upFrontCost
          set costPerKm sublist item 2 droneAttrs 10 11
          set costPerKm item 0 costPerKm
          set status "waiting"
          set chargeLevel 100
          set maxcharge 100
          ;;set dischargerate 0
          set dischargerate (chargeConstant * dischargeConstant)
          set size 6
          set totalupfrontcosts  upFrontCost + totalupfrontcosts
        ]

        if read-from-string item i drone-types = 3[
          set droneType sublist item 3 droneAttrs 0 1
          set droneType item 0 droneType
          set maxSpeed sublist item 3 droneAttrs 1 2
          set maxSpeed item 0 maxSpeed
          set maxPayload sublist item 3 droneAttrs 2 3
          set maxPayload item 0 maxPayload
          set maxBattery sublist item 3 droneAttrs 3 4
          set maxBattery item 0 maxBattery
          set rechargeRate sublist item 3 droneAttrs 4 5
          set rechargeRate item 0 rechargeRate
          set dischargeConstant sublist item 3 droneAttrs 5 6
          set dischargeConstant item 0 dischargeConstant
          set dryWeight sublist item 3 droneAttrs 6 7
          set dryWeight item 0 dryWeight
          set reqPower sublist item 3 droneAttrs 7 8
          set reqPower item 0 reqPower
          set opVoltage sublist item 3 droneAttrs 8 9
          set opVoltage item 0 opVoltage
          set upFrontCost sublist item 3 droneAttrs 9 10
          set upFrontCost item 0 upFrontCost
          set costPerKm sublist item 3 droneAttrs 10 11
          set costPerKm item 0 costPerKm
          set status "waiting"
          set chargeLevel 100
          set maxcharge 100
          ;;set dischargerate 0
          set dischargerate (chargeConstant * dischargeConstant)
          set size 7
          set totalupfrontcosts  upFrontCost + totalupfrontcosts
        ]
      ]
    ]
    set i i + 1
  ]

  set totalupfrontcosts startUpCosts + totalupfrontcosts
  set totalOperatingCosts totalupfrontcosts ;; initialise total costs

  ;; set as eDrone
  ask n-of number-of-eDrones drones [set eDrone True]

end

to setup
  clear-all
  setup-globals
  setup-patches
  setup-subHubs
  setup-hospitals
  setup-drones
  setup-hubs
  ;;
  set chance-of-emergency 1 - chance-of-standard
  reset-ticks
end


;;-----------------------------------
;; start of model
;;-----------------------------------

;; main loop
to go
  request-payload
  comms-Hubs
  send-drone-for-pickup
  send-drone-for-delivery
  charge-waiting-Drone
  charge-drone-after-delivery
  return-Drone-to-closest-hub
  set modelFitness fitnessFunc
  set totalOperatingCosts totalOperatingCosts + maintenaceCostPerMinute
  set totalEventCount standardEventCount + emergencyEventCount

  if ticks > 0 [
    set emergencyEventPerHour emergencyEventCount / ticks * 60
    set standardEventPerHour standardEventCount / ticks * 60
    set totalTimeInDays ticks / 1440
  ]

  ;; check for dead drones
  if any? drones with [chargeLevel < 0]
  [
    set avgResponseTimeEmergency lput 1e4 avgResponseTimeEmergency
    set avgResponseTimeStandard lput 1e4 avgResponseTimeStandard
    ;; print("All Stopped")
  ]

  ;; if ticks > 20000 and the number of response samples is small the model is bad
  if ticks > 20000 and length avgResponseTimeStandard < 100
  [
    set avgResponseTimeEmergency lput 1e4 avgResponseTimeEmergency
    set avgResponseTimeStandard lput 1e4 avgResponseTimeStandard
    ;; print("All Stopped")
  ]

  ;; set current val of avg responses
  ;; if empty just add a zero... the runs a so long this will be insignificant
  ;; could back fill in python if needed
  ifelse length avgResponseTimeStandard != 0 [
    set arts_out mean avgResponseTimeStandard
  ]
  [
    set arts_out 0
  ]

  ifelse length avgResponseTimeEmergency != 0 [
    set arte_out mean avgResponseTimeEmergency
  ]
  [
    set arte_out 0
  ]
  ;;show arts_out
  ;;show arte_out


  tick

end

;; fuction to establish the fitness of the system
to-report fitnessFunc []
  ;; this needs some work !!!!
  let deadDrones count drones with [chargeLevel <= 0] ;; kill function
  let aert 0
  let asrt 0
  let mql 0
  let killVal 0
  if deadDrones > 0 [set killVal 1e4] ;; kill this model if drones run out of juice

  let numbDrones count drones ;; smaller is better
  let toc totalOperatingCosts / 100000 ;; smaller is better
  let sr service-range / 10 ;; smaller is  better
  let mpw meanpayloadweight ;; larger is better
  if length avgResponseTimeEmergency > 2 and length avgResponseTimeStandard > 2
  [
    set aert last avgResponseTimeEmergency
    set asrt last avgResponseTimeStandard
    if length tmpList > 3 [set mql length tmpList]

  ]
  let fitness (numbDrones + toc + sr + mpw + aert + asrt + mql + killVal)
  report fitness
end

;; create random requests for payloads
to request-payload ;; need to move to random-poisson
  ;; send request ticket from a hospital to a hub
  ;; right now its just a %chance event... we can look at other ways
  ;; need to figure out what the scale is and adjust the random nature
  ask hospitals with [status = "idle"]
  [
    set eventStart ticks
    let chanceOfMedicalEvent probability-float(chance-of-medical-event)
    let pickup_target one-of subhubs ;; pick up payload here
    let pw payload_weight(payload-mean) ;; get payload weight
    if  chanceOfMedicalEvent = True
    [
      let hospitalReqType pickRequestType
      set medicalEvent hospitalReqType

      ;; send the msg to the hubs
      broadcast hubs (list hospitalReqType pw pickup_target)

      set status "waiting"
      ifelse hospitalReqType = 1 ;;"A-Emergency"
      [
        set color red
        set eventType 1 ;;"A-Emergency"
        set payloadWeight pw
        set emergencyEventCount emergencyEventCount + 1
      ]
      [
        set color yellow
        set eventType 2 ;;"B-Standard"
        set payloadWeight pw
        set standardEventCount standardEventCount + 1
      ]
     ]
   ]

  ask subhubs with [status = "idle"]
  [
    set eventStart ticks
    let chanceOfMedicalEvent probability-float(chance-of-medical-event)
    let pickup_target one-of other subhubs ;; pick up payload here not the same as me :)
    let pw payload_weight(payload-mean) ;; get payload weight
    if  chanceOfMedicalEvent = True
    [
      let hospitalReqType pickRequestType
      set medicalEvent hospitalReqType

      ;; send the msg to the hubs
      broadcast hubs (list hospitalReqType pw pickup_target)

      set status "waiting"
      ifelse hospitalReqType = 1 ;;"A-Emergency"
      [
        set color red
        set eventType 1 ;;"A-Emergency"
        set payloadWeight pw
      ]
      [
       set color yellow
       set eventType 2 ;;"B-Urgent"
       set payloadWeight pw
      ]
     ]
   ]
end

to comms-Hubs

  ask hubs
  ;; make sure this queue is working right... walk up the nubmers to see
  [ ;;show #msgQ
    ;;; this little bit of code sorts the message queue by item
    ;;; the queue list looks like: [[(hospital 11) ["A-Emergency"]] [(hospital 18) ["C-Standard"]] [(hospital 1) ["C-Standard"]]]
    ;;; in order to support the hospitals by request type we must sort on item 1 (item 0 = hospital agent, item 1 = requestType)
    ;;; use item 0 to sort on hospital number (working)
    ;;; use item 1 to sort on requestType (not working...)
    ;;set #msgQ (sort-with [a -> item 1 a] #msgQ)
    set #msgQ (sort-by [ [a b] -> first item 1 a < first item 1 b ] #msgQ)
    set tmpList #msgQ
    ;;show tmpList
    if msg-waiting? ;; check for a message [Message = hospital#(reqType)
    [ if count drones with [status = "waiting"] > 0
      [
          ifelse count drones with [status = "waiting"] = 0
          [
            ;; do nothing wait on someone to free up
          ]
          [
          ;;; peek into the msg queue (set this up to find an item index that fits)
          let peekatFirstMsg item 0 #msgQ
          let rtype sublist item 1 peekatFirstMsg 0 1 ;; get the request type
          set rtype item 0 rtype ;; pull the float out of the single item list
          let payLoadReq sublist item 1 peekatFirstMsg 1 2 ;; get the required drone payload capability
          set payLoadReq item 0 payLoadReq ;; pull the float out of the single item list
          ;;show rtype
          if count drones with [status = "waiting" and maxpayload > payLoadReq] > 0
          [ ;;show length #msgQ
            ifelse rtype = 1 ;; emergnecy
            [
              ifelse count drones with [status = "waiting" and maxpayload > payLoadReq and eDrone = True] > 0
              [ ;; send a eDrone if one exists
                let m get-msg ;; fetch message - clears one of queue
                let deliveryTarget item 0 m;
                let pickupTarget sublist item 1 m 2 3;
                set pickupTarget item 0 pickupTarget
                ask one-of drones with [status = "waiting" and maxpayload > payLoadReq and eDrone = True]
                [
                  set payload_pickup_target pickupTarget
                  set payload_delivery_target deliveryTarget
                  set target pickupTarget
                  set status "pickingUp"
                  set color red
                ]
              ]
              [ ;; send a regular drone... dont wait on an eDrone
                if count drones with [status = "waiting" and maxpayload > payLoadReq and reqtype = 0 and eDrone != True] > 0
                [
                  let m get-msg ;; fetch message - clears one of queue
                  let deliveryTarget item 0 m;
                  let pickupTarget sublist item 1 m 2 3;
                  set pickupTarget item 0 pickupTarget
                  ask one-of drones with [status = "waiting" and maxpayload > payLoadReq and reqtype = 0 and eDrone != True]
                  [
                    set payload_pickup_target pickupTarget
                    set payload_delivery_target deliveryTarget
                    set target pickupTarget
                    set status "pickingUp"
                  ]
                ]
              ]

            ]
            [ ;; else if type 2 send a regular drone...
              if count drones with [status = "waiting" and maxpayload > payLoadReq and reqtype = 0 and eDrone != True] > 0
              [
                let m get-msg ;; fetch message - clears one of queue
                let deliveryTarget item 0 m;
                let pickupTarget sublist item 1 m 2 3;
                set pickupTarget item 0 pickupTarget
                ask one-of drones with [status = "waiting" and maxpayload > payLoadReq and reqtype = 0 and eDrone != True]
                [
                  set payload_pickup_target pickupTarget
                  set payload_delivery_target deliveryTarget
                  set target pickupTarget
                  set status "pickingUp"
                ]
              ]
            ]
          ]
        ]
      ]
    ]
  ]

end

to send-drone-for-pickup
  ask drones with [status = "pickingUp"]
  [
    ifelse distance target > 1
    [
      if chargeLevel > 0
      [
        move-Drone
      ]
    ]
    [
      set status "delivering"
      set target payload_delivery_target
    ]
  ]
end

to send-drone-for-delivery
  ask drones with [status = "delivering"]
  [
    ifelse distance target > 1
    [
      if chargeLevel > 0
      [
        move-Drone
      ]
    ]
    [
      set status "delivered"
      ask target[
        set status "idle"
        set color 3
        set responseTime (ticks - eventStart)
        ;;show responseTime
        if medicalEvent = 1
        [
          set avgResponseTimeEmergency lput responseTime avgResponseTimeEmergency
          ;;show avgResponseTimeEmergency
        ]
        if medicalEvent = 2
        [
          set avgResponseTimeStandard lput responseTime avgResponseTimeStandard
          ;;show avgReponseTimeUrgent
        ]
      ]
    ]
  ]
end

to move-Drone ;; need a good wind model here
  ask drones with [status = "delivering" or status = "pickingUp" or status = "charged"]
  [
    if chargeLevel > 0
      [
        ;;show(target)
        face target
        fd maxspeed
        set chargeLevel (chargeLevel - (dischargeRate * (discharge_adjustment / 100)))
        set totalOperatingCosts totalOperatingCosts + costPerKm + maxspeed
        ;;show totalOperatingCosts
    ]
  ]
end

to return-Drone-to-closest-hub
  ask drones with [status = "charged"]
  [
    ;; if the target was a hospital then set the target to a hub
    ;; this check prevents the drones from twitching between multiple hubs
    if member? target hospitals [
      ;;let hubDistance min-one-of hubs [distance myself] --> selects closest agent
      ;;let subHubDistance min-one-of hubs [distance myself] --> selects closest agent
      ;;min distance to 0 0 from a subHub
      let hubDistance (distancexy 0 0) ;; find the distance between myself and the hub at 0,0
      let closetSubHub min-one-of subHubs [distance myself] ;; select the closes subHub to myself
      let closetSubHubDistance [distance closetSubHub] of self ;; get the distance to the subHub to myself
      if hubDistance > 1
      [
        ifelse hubDistance < closetSubHubDistance
        [ ;; comapre the two distances and go to the closest
          set target min-one-of hubs [distance myself] != target
        ]
        [
          set target min-one-of subHubs [distance myself]
        ]
      ]
    ]
    ifelse distance target > 1
    [
      if chargeLevel > 0
      [
        move-Drone
      ]
    ]
    [
      set status "recharging"
    ]
  ]

end

to charge-waiting-Drone ;; combine with the charge-drone
  ask drones with [status = "recharging"]
  [
    ifelse any? hubs in-radius 1 or any? subHubs in-radius 1
    [
      set chargeLevel (chargeLevel + rechargeRate)
      if chargeLevel > maxCharge [
        set chargeLevel maxCharge
        set status "waiting"
        set target ""
        ;;show chargeLevel
      ]
    ]
    [
      set status "recharging"
    ]
  ]
end

to charge-drone-after-delivery
  ask drones with [status = "delivered"]
  [
    ifelse any? hospitals in-radius 1 with [hasChargeStation = true]
    [
      set chargeLevel (chargeLevel + rechargeRate)
      if chargeLevel > maxCharge [
        set chargeLevel maxCharge
        set status "charged"
        ;;show chargeLevel
      ]
    ]
    [
      ;; otherwise just set it charged
      if replaceBattery?
      [
        set status "charged"
        set chargeLevel maxcharge
      ]
      set status "charged"
    ]
  ]
end

to timeOut

end




;;; probability fuctions ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; random selection of list items by %probability
to-report pickRequestType
  ;;let probabilities (list (chance-of-standard) (chance-of-urgent) (chance-of-emergency))
  let probabilities (list (chance-of-standard) (chance-of-emergency))
  ;;let some_list ["C-Standard" "B-Urgent" "A-Emergency"]
  let some_list [2 1]
  report first rnd:weighted-one-of-list (map list some_list probabilities) last
end

;; random selection of list items by %probability
to-report droneSelection
  let probabilities (list (chance_of_typeA) (chance_of_typeB) (chance_of_typeC))
  ;;let some_list ["light" "medium" "heavy"]
  let some_list [1 2 3]
  report first rnd:weighted-one-of-list (map list some_list probabilities) last
end

;; probability float
to-report probability-float [ p ]
  report random-float 1 < p
end

;; payload weight
to-report payload_weight [val]
  ;;; report random-exponential mean-weight
  report random-float val
end

;;; sort queue fuctions ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; sort the message queue on 1 entry (not 0) !!!!! need 2 queues !!!!!
to-report sort-with [ key lst ]
  ;;report sort-by [ [a b] -> first a < first b ] lst
  ;;report sort-by [ [a b] -> first item 1 a < first item 1 b ] tmplist ;; sort by first item in brocast sub list
  ;;report sort-by [[?0 ?1] -> (runresult key ?0) < (runresult key ?1)] lst
end

;; string to list
to-report read-from-list [ x ]
  report ifelse-value is-list? x
    [ map read-from-list x ]
    [ read-from-string x ]
end

;; get drone types from input string drone-types
to-report get-drone-type
  report reverse sort read-from-string ( word "[" drone-types "]")
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
1020
821
-1
-1
2.0
1
10
1
1
1
0
0
0
1
-200
200
-200
200
0
0
1
ticks
30.0

BUTTON
6
10
70
43
Setup
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
7
46
143
79
Go...
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
73
10
143
43
Go Once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
9
366
203
399
charger-network
charger-network
1
1
-1000

SLIDER
9
402
203
435
has-charge-station
has-charge-station
0
1
0.33
.01
1
NIL
HORIZONTAL

SLIDER
8
311
204
344
service-range
service-range
20
170
81.0
1
1
km
HORIZONTAL

SLIDER
8
88
203
121
chance-of-medical-event
chance-of-medical-event
1e-4
.01
0.0087
.0001
1
NIL
HORIZONTAL

SLIDER
8
123
203
156
chance-of-standard
chance-of-standard
.01
1
0.84
.01
1
NIL
HORIZONTAL

SLIDER
8
160
204
193
chance-of-emergency
chance-of-emergency
0
1
0.16000000000000003
.01
1
NIL
HORIZONTAL

SWITCH
7
498
201
531
activate-hospitals
activate-hospitals
0
1
-1000

INPUTBOX
9
237
204
297
drone-types
23323
1
0
String

SWITCH
9
439
202
472
replaceBattery?
replaceBattery?
0
1
-1000

SLIDER
8
545
199
578
maxPayloadWeight
maxPayloadWeight
4.0
150
100.0
1
1
kg
HORIZONTAL

SLIDER
8
583
198
616
meanPayloadWeight
meanPayloadWeight
1
150
5.0
1
1
kg
HORIZONTAL

SLIDER
8
631
199
664
startup-Costs
startup-Costs
50000
1000000
230000.0
10000
1
$
HORIZONTAL

SLIDER
8
667
200
700
maintenace-cost-per-hour
maintenace-cost-per-hour
10
50
30.0
10
1
$
HORIZONTAL

SLIDER
1029
568
1239
601
discharge_adjustment
discharge_adjustment
0
400
20.0
1
1
%
HORIZONTAL

SLIDER
1027
10
1199
43
chance_of_typeA
chance_of_typeA
.01
1
0.01
.01
1
NIL
HORIZONTAL

SLIDER
1028
46
1200
79
chance_of_typeB
chance_of_typeB
.01
1
0.5
.01
1
NIL
HORIZONTAL

SLIDER
1027
82
1199
115
chance_of_typeC
chance_of_typeC
.01
1
0.89
.01
1
NIL
HORIZONTAL

SLIDER
1027
120
1199
153
number_of_drones
number_of_drones
4
10
5.0
1
1
NIL
HORIZONTAL

MONITOR
1028
166
1236
211
NIL
mean avgResponseTimeEmergency
17
1
11

PLOT
224
21
424
171
Battery Charge
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"drone24" 1.0 0 -16777216 true "" "plot [chargeLevel] of drone 24"
"drone25" 1.0 0 -7500403 true "" "plot [chargeLevel] of drone 25"

PLOT
427
21
738
171
Mean of Response Time
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Standard" 1.0 0 -1184463 true "" "plot mean avgResponseTimeStandard"
"Emergency" 1.0 0 -2674135 true "" "plot mean avgResponseTimeEmergency"

PLOT
741
21
941
171
Queue Length
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Queue Length" 1.0 0 -16777216 true "" "plot length tmpList"

MONITOR
1028
221
1237
266
Total Operating Costs
totalOperatingCosts
2
1
11

MONITOR
1166
273
1314
318
Emergency Event Per Hour
emergencyEventPerHour
2
1
11

MONITOR
1029
274
1159
319
Emergency Event Count
emergencyEventCount
0
1
11

MONITOR
1031
325
1160
370
Standard Event Count
standardEventCount
0
1
11

MONITOR
1166
324
1317
369
Standard Event Per Hour
standardEventPerHour
2
1
11

MONITOR
1030
374
1160
419
Total Event Count
totalEventCount
0
1
11

MONITOR
1031
423
1161
468
Simulation Days
totalTimeInDays
2
1
11

PLOT
223
174
423
324
Model Fitness
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot fitnessFunc"

SLIDER
1035
490
1207
523
number-of-eDrones
number-of-eDrones
0
3
1.0
1
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
NetLogo 6.2.0
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
