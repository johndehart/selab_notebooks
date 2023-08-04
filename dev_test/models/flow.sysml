package fuelFlow {
    
    item fuel;
    item fuelStation;
        
    part fuelTank (in fuel, out fuel)[1..*];
        
    part fuelPump (in fuel, out fuel)[1..*] {
        // pump action + constraint(s) here
    }
        
    action fuelFlow (in fuel, out fuel) {
        
        flow from fuelTank to fuelPump;
        
    }
    
    action fillTank (in fuel) {
        
        flow from fuelStation to fuelTank;
            
    }
    
}

