package jdehart_partsModel {
    
    import ScalarValues::*;

    part def Automobile;
    
    part def Aeroplane;
    
    part Bicycle{
        
        part Wheel{
            
            part Hub;
            
            part Tire;
            
        }
        
        part Seat;
        
        part Frame;
        
    }
    
}