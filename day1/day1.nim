import std/[strutils, strformat]

const
  fileName = "input.txt"
let
  masses = readFile(fileName).strip().splitLines()

var
  totalFuel = 0

proc calcFuel(mass: int) =
  let
    fuel = (mass / 3).int - 2
  if fuel > 0:
    echo &"mass = {mass}, fuel = {fuel}"
    totalFuel.inc(fuel)
    calcFuel(fuel)

for mass in masses:
  calcFuel(mass.parseInt())

echo &"totalFuel = {totalFuel}"
