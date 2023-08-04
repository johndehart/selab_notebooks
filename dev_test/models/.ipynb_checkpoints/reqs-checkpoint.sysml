package Requirements {
    
    import ScalarValues::*;
    
    requirement def id '1' Payload{
        doc /* System shall be capable of carrying a minimum of 10 pounds. */
            
            attribute massLoad: Real;
            attribute massCapacity: Real;
            require constraint { massLoad<=massCapacity }
            
            requirement def id '1.1' PayloadCapacity{
            doc /* UAV shall be capable of carrying multiple packages in its payload */
                
                attribute packageTotalMass: Real;
                attribute massLoad = packageTotalMass;
                assume constraint {packageTotalMass > 0 }
        }
    }
    requirement def id '2' NumberOfHospitals{
        doc /* Drone system shall be capable of serving a minimum of 4 rural hospitals */
            
            requirement def id '2.1' SystemCapacity{
            doc /* Delivery system shall include a minimum of 5 UAVs with capability to add more UAVs */
             comment /*  Rationale
        
        # Minimum number of UAVs determined by minimum number of rural hospitals min plus 1 for availability*/

        }
    }
    requirement def id '3' DistributionSetup{
        doc /* There shall be one main hospital that UAVs will leave from and return to (hub) */
            
            requirement def id '3.1' CentralControl{
            doc /* Hub facility shall allow for monitoring and manned control of all UAVs in the system */
            }
                
                requirement def id '3.2' BatteryCharging{
            doc /* UAV battery charging shall be done whenever the UAV is at the HUB */
            }
                
                requirement def id '3.3' HubCapacity{
            doc /* HUB shall be capable of docking all UAVs in the system */         
        }
                requirement def id '3.4' UAVEmergency{
            doc /* In case of emergency, UAV shall return to the hub for troubleshooting and maintenance */         
        }
        
    }
    requirement def id '4' Distance{
        doc /* The UAV shall be able to travel a minimum of 25 miles round trip */
            attribute milesActual: Real;
            attribute milesLimit: Real;
            require constraint { milesActual<=milesLimit }
        
            requirement def id '4.1' BatteryRuntimeDuration{
            doc /* The UAV shall be capable of running on battery long enough to meet the distance requirement plus reserve. */
                
                requirement def id '4.1.1' BatteryCapacity{
                doc /* UAV shall only initiate delivery when battery level is sufficient for delivery route plus 10% reserve */
                    attribute batteryLevel: Real;
                    assume constraint {batteryLevel > 0 }
            }
        }
    }
    requirement def id '5' ResponseTime{
        doc /* The UAV shall deliver payloads within 40min, 90% of the time */
            attribute minutesLimit: Real;
            attribute minutesActual: Real;
            require constraint { minutesActual<=minutesLimit }
        
            requirement def id '5.1' ResponseTimeLogging{
            doc /* Drone System shall include a data logging system for delivery time tracking */
            }
        
            requirement def id '5.2' UnmannedControl{
            doc /* Drone system shall allow for autonomous deliveries on prescribed routes */
            }
            requirement def id '5.3' ResponsePriority{
            doc /* Drone system shall allow for prioritization of urgent deliveries to be delivered within 15 minutes */
            }
            requirement def id '5.4' Speed{
            doc /* The UAV shall be able to maintain a speed high enough to meet the response time requirement. */
                
                requirement def id '5.4.1' UAVRouting{
                doc /* UAV delivery routes shall be as efficient and direct as allowable */
            }
                requirement def id '5.4.2' SpeedAdjustment{
                    doc /* UAV shall allow for adjusting of speed depending on environment */
                }
                requirement def id '5.4.3' SpeedPriority{
                    doc /* System shall allow for prioritizing speed for urgent deliveries */
                }
            }
            
    }
    requirement def id '6' Cost{
        doc /* The total system cost shall not exceed $500,000 per year */
            //attribute dollars : Real;
        
            requirement def id '6.1' PurchaseCost{
            doc /* The total system purchase cost shall not exceed XXX */
            }
        
            requirement def id '6.2' OperatingCost{
            doc /* The operatings cost per hour shall be less than $30 */
            }
    }
    
    requirement def id '7' OperatingParadigm{
        doc /* The drone system operation shall be done by third party with hospital oversight */
            requirement def id '7.1' PayloadPreparation{
            doc /* Drone system payload preparation and loading shall be done by qualified hospital personnel */
            }
    }
    
    requirement def id '8' Availability{
        doc /* The drone system shall maintain greater than 95% availability for deliveries */
        //require  BatteryCharging;
    
        requirement def id '8.1' OperatingAvailability{
            doc /* The drone system shall be available 24 hours a day, every day of the year for deliveries */
            }
    }  
    
    requirement def id '9' RouteFlightPlanning{
        doc /* The UAV flight planning shall be initially handled by the UAV pilot using waypoint planning with on board emergency mission planned in case of connection issues */
            
            requirement def id '9.1' RouteRestrictions{
            doc /* The drone system route planning will avoid restricted flight areas in accordance to FAA and local rules */
            }
    }
    
    requirement def id '10' Tracking{
        doc /* The UAV shall be trackable by both the sender and receiver */
            
            requirement def id '10.1' TrackingStats{
                doc /* The UAV tracking tool shall provide estimated time of arrival (ETA) and notify of any changes to route */
                }

    }
}