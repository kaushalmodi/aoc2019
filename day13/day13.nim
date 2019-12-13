import std/[strformat, strutils, tables, sequtils]
import day02 # intcode

type
  Position = tuple
    x: int # Looks like the position cannot be negative
    y: int
  Tile = enum
    tEmpty = "empty"
    tWall = "wall"
    tBlock = "block"
    tPaddle = "paddle"
    tBall = "ball"

proc runArcadeCabinet(sw: seq[int]): Table[Position, Tile] =
  var
    state = sw.process() # Run IntCode
  doAssert state.outputs.len mod 3 == 0
  for i in countup(0, state.outputs.high-2, 3):
    let
      pos = (state.outputs[i], state.outputs[i+1]).Position
      tile = state.outputs[i+2].Tile
      tileStr = $tile
    doAssert pos.x >= 0 and pos.y >= 0
    doAssert not tileStr.contains("(invalid data!)")
    result[pos] = tile

when isMainModule:
  import std/[unittest]
  import days_utils

  suite "day13 part1 challenge":
    setup:
      let
        arcadeOut = "input.txt".readFileToIntSeq().runArcadeCabinet()
    test "check":
      check:
        toSeq(arcadeOut.values).count(tBlock) == 412
