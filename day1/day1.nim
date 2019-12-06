import std/[strutils, strformat]
import days_utils

const
  fileName = "input.txt"

var
  totalFuel = 0

proc calcFuel(mass: int) =
  let
    fuel = (mass / 3).int - 2
  if fuel > 0:
    echo &"mass = {mass}, fuel = {fuel}"
    totalFuel.inc(fuel)
    calcFuel(fuel)

for mass in fileName.readFileToSeq():
  calcFuel(mass)

echo &"totalFuel = {totalFuel}"
