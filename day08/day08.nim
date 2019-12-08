import std/[strutils, tables]
import days_utils
when defined(debug):
  import std/[strformat]

type
  Pixel = enum
    pBlack = '0'
    pWhite = '1'
    pTrans = '2'
  Layer = object
    content: string
    pixelCounts: Table[Pixel, int]
  Image = object
    layers: seq[string]
    width: int
    height: int

proc layerize(pixels: string; width, height: int): Image =
  result.width = width
  result.height = height
  let
    numPixels = pixels.len
    layerSize = width * height
    numLayers = numPixels div layerSize

  for i in 0 ..< numLayers:
    result.layers.add(pixels[i*layerSize ..< (i+1)*layerSize])

proc getLeastZeroesLayer(image: Image): Layer =
  for i, layer in image.layers:
    var
      pixelCounts: Table[Pixel, int]
    for pixel in {pBlack, pWhite, pTrans}:
      pixelCounts[pixel] = layer.count(pixel.char)
    when defined(debug):
      echo &"layer {i}: {pixelCounts}"
    if i == 0 or
       not pixelCounts.hasKey(pBlack) or
       pixelCounts[pBlack] < result.pixelCounts[pBlack]:
      result = Layer(content: layer, pixelCounts: pixelCounts)

proc render(image: Image): string =
  result = image.layers[0]
  for layer in image.layers[1 .. ^1]:
    for i, digit in result:
      if digit.Pixel == pTrans:
        result[i] = layer[i]

  # Display the image
  for row in 0 ..< image.height:
    let
      line = result[row*image.width ..< (row+1)*image.width]
    for digit in line:
      if digit == '0': stdout.write("  ")
      else: stdout.write("\u2591\u2591")
    echo ""

when isMainModule:
  import std/[unittest]

  suite "day8 challenge":
    setup:
      let
        layers = "input.txt".prjDir().readFile().strip().layerize(25, 6)

    test "part1":
      check:
        layers.getLeastZeroesLayer().pixelCounts[pWhite] *
        layers.getLeastZeroesLayer().pixelCounts[pTrans] == 1742

    test "part2":
      check:
        layers.render() ==
        "0110000110100011111001100" &
          "1001000010100011000010010" &
          "1000000010010101110010010" &
          "1011000010001001000011110" &
          "1001010010001001000010010" &
          "0111001100001001111010010"
