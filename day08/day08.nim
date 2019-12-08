import std/[strutils, tables]
import days_utils
when defined(debug):
  import std/[strformat]

type
  Pixel = enum
    pBlack = '0'
    pWhite = '1'
    pTrans = '2'
  PixelCounts = Table[Pixel, int]
  Layer = object
    content: string
    pixelCounts: PixelCounts
  Image = object
    layers: seq[string]
    width: int
    height: int

proc analyze(layer: string; pixels: set[Pixel]): PixelCounts =
  for pixel in pixels:
    result[pixel] = layer.count(pixel.char)

proc layerize(pixels: string; width, height: int): Image =
  result.width = width
  result.height = height
  let
    numPixels = pixels.len
    layerSize = width * height
    numLayers = numPixels div layerSize

  for i in 0 ..< numLayers:
    let
      layer = pixels[i*layerSize ..< (i+1)*layerSize]
    result.layers.add(layer)

proc getLeastZeroesLayer(image: Image): Layer =
  var
    leastZeroesLayer: Layer
  for i, layer in image.layers:
    let
      pixelCounts = layer.analyze({pBlack, pWhite, pTrans})
    when defined(debug):
      echo &"layer {i}: {pixelCounts}"
    if i == 0 or
       not pixelCounts.hasKey(pBlack) or
       pixelCounts[pBlack] < leastZeroesLayer.pixelCounts[pBlack]:
      leastZeroesLayer = Layer(content: layer,
                               pixelCounts: pixelCounts)
  return leastZeroesLayer

proc render(image: Image): Layer =
  result.content = newString(image.width*image.height)
  # assert result.content[0] == '\0'
  for layer in image.layers:
    if result.content[0] == '\0':
      result.content = layer
    else:
      for i, digit in result.content:
        case digit.Pixel
        of pTrans: result.content[i] = layer[i]
        else: discard

  # Display the image
  for i in 0 ..< image.height:
    let
      line = result.content[i*image.width ..< (i+1)*image.width]
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
        leastZeroesLayer = layers.getLeastZeroesLayer()

    test "part1":
      check:
        leastZeroesLayer.pixelCounts[pWhite] * leastZeroesLayer.pixelCounts[pTrans] == 1742

    test "part2":
      check:
        layers.render().content ==
        "0110000110100011111001100" &
          "1001000010100011000010010" &
          "1000000010010101110010010" &
          "1011000010001001000011110" &
          "1001010010001001000010010" &
          "0111001100001001111010010"
