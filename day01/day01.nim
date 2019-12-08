import std/[strutils, strformat]
import days_utils

proc calcFuel(mass: int; totalFuel: var int) =
  let
    fuel = (mass / 3).int - 2
  if fuel > 0:
    when defined(debug):
      echo &"mass = {mass}, fuel = {fuel}"
    totalFuel.inc(fuel)
    calcFuel(fuel, totalFuel)

when isMainModule:
  var
    totalFuel = 0
  for mass in "input.txt".readFileToIntSeq():
    calcFuel(mass, totalFuel)
  echo &"totalFuel = {totalFuel}"
  doAssert totalFuel == 5146132
