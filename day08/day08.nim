import std/[strutils, tables]
when defined(debug):
  import std/[strformat]
import days_utils
import dot_matrix

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

proc render(image: Image): seq[int] =
  var
    finalImageStr = image.layers[0]
  for layer in image.layers[1 .. ^1]:
    for i, digit in finalImageStr:
      if digit.Pixel == pTrans:
        finalImageStr[i] = layer[i]

  # Display the image
  for row in 0 ..< image.height:
    let
      line = finalImageStr[row*image.width ..< (row+1)*image.width]
    for digit in line:
      doAssert digit.Pixel in {pBlack, pWhite}
      result.add(digit.ord - '0'.ord)
      if digit.Pixel == pBlack: stdout.write("  ")
      else: stdout.write("██")
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
        layers.render().transpose().parseLetters() == "GJYEA"
