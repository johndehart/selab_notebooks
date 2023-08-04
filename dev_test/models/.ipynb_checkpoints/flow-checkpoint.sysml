package fuelFlow {
    item fuel
    part fuelTank (in fuel, out fuel)
    part fuelPump (in fuel, out fuel)
    flow fuel:fuelTank to fuel:fuelPump
}
