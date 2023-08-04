package Requirements {
    
    import ScalarValues::*;
    
    requirement def id '1' Payload{
        doc /* UAV shall be able to carry a minimum of 10 pounds. */
            
            attribute mass: Real;
            
            requirement def id '1.1' PayloadCapacity{
            doc /* UAV shall be capable of carrying multiple packages in its paylaod */
                
                attribute quantity: Real;
        }
    }
    requirement def id '2' NumberOfHospitals{
        doc /* The UAVs shall be abel to serve a minimum of 3 rural hospitals */
            
            requirement def id '2.1' SystemCapacity{
            doc /* Delivery system shall include a minimum of 3 UAVs */
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
        doc /* The UAV shall be able to travel a minimum of 100 miles round trip */
            
            requirement def id '4.1' BatteryRuntimeDuration{
            doc /* The UAV shall be capable of running on battery long enough to meet the distance requirement. */
                
                requirement def id '4.1.1' BatteryCapacity{
                doc /* UAV shall only initiate delivery when battery level is sufficient for delivery route plus 10% reserve */
            }
        }
    }
    requirement def id '5' ResponseTime{
        doc /* The UAV shall deliver payloads within 45min, 90% of the time */
            
            requirement def id '5.1' ResponseTimeLogging{
            doc /* System shall include a data logging system for delivery time tracking */
            }
        
            requirement def id '5.2' UnmannedControl{
            doc /* UAS shall allow for autonomous deliveries on prescribed routes */
            }
        
            requirement def id '5.3' Speed{
            doc /* The UAV shall be able to maintain a speed high enough to meet the response time requirement. */
                
                requirement def id '5.3.1' UAVRouting{
                doc /* UAV delivery routes shall be as efficient and direct as allowable */
            }
                requirement def id '5.3.2' SpeedAdjustment{
                    doc /* UAV shall allow for adjusting of speed depending on environment */
                }
                 requirement def id '5.3.4' SpeedPriority{
                    doc /* System shall allow for prioritizing speed for urgent deliveries */
                     }
            
        }

    }
}