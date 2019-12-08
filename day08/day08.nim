import std/[strutils, tables]
import days_utils
when defined(debug):
  import std/[strformat]

type
  DigitCounts = Table[char, int]
  Layer = object
    content: string
    num: int
    digitCounts: DigitCounts

proc analyze(layer: string; digits: set[char]): DigitCounts =
  for digit in digits:
    result[digit] = layer.count(digit)

proc getLeastZeroesLayer(pixels: string; width, height: int): Layer =
  let
    numPixels = pixels.len
    layerSize = width * height
    numLayers = numPixels div layerSize

  var
    leastZeroesLayer: Layer
  for i in 0 ..< numLayers:
    let
      layer = pixels[i*layerSize ..< (i+1)*layerSize]
      digitCounts = layer.analyze({'0', '1', '2'})
    when defined(debug):
      echo &"layer {i}: {digitCounts}"
    if i == 0 or
       not digitCounts.hasKey('0') or
       digitCounts['0'] < leastZeroesLayer.digitCounts['0']:
      leastZeroesLayer = Layer(content: layer,
                               num: i,
                               digitCounts: digitCounts)
  return leastZeroesLayer

when isMainModule:
  import std/[unittest]

  suite "day8 part1 challenge":
    setup:
      let
        layer = "input.txt".prjDir().readFile().strip().getLeastZeroesLayer(25, 6)

    test "check":
      check:
        layer.digitCounts['1'] * layer.digitCounts['2'] == 1742

  # suite "day8 part2 challenge":
  #   test "check":
  #     check:
