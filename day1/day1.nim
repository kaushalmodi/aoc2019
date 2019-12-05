import std/[strutils, strformat]

const
  fileName = "input.txt"
let
  masses = readFile(fileName).strip().splitLines()

var
  totalFuel = 0

for mass in masses:
  let
    fuel = (mass.parseInt() / 3).int - 2
  echo &"mass = {mass}, fuel = {fuel}"
  totalFuel.inc(fuel)
echo &"totalFuel = {totalFuel}"
