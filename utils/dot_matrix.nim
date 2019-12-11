import std/[strformat, strutils, tables]

const
  dot5x6Width = 5
  dot5x6Height = 6
  patterns5x6: Table[string, array[dot5x6Height, string]] =
    {
      "A1": [" .##.",
             " #..#",
             " #..#",
             " ####",
             " #..#",
             " #..#"],

      "A2": [".##. ",
             "#..# ",
             "#..# ",
             "#### ",
             "#..# ",
             "#..# "],

      "B1": [" ###.",
             " #..#",
             " ### ",
             " #..#",
             " #..#",
             " ###."],

      "B2": ["###. ",
             "#..# ",
             "###  ",
             "#..# ",
             "#..# ",
             "###. "],

      "E1": [" ####",
             " #...",
             " ### ",
             " #...",
             " #...",
             " ####"],

      "E2": ["#### ",
             "#... ",
             "###  ",
             "#... ",
             "#... ",
             "#### "],

      "G1": ["  ## ",
             " #..#",
             " #.  ",
             " #.##",
             " #..#",
             "  ###"],

      "G2": [" ##  ",
             "#..# ",
             "#.   ",
             "#.## ",
             "#..# ",
             " ### "],

      "J1": ["   ##",
             "   .#",
             "   .#",
             "   .#",
             " #..#",
             " .##."],

      "J2": ["  ## ",
             "  .# ",
             "  .# ",
             "  .# ",
             "#..# ",
             ".##. "],

      "L1": [" #.  ",
             " #.  ",
             " #.  ",
             " #.  ",
             " #...",
             " ####"],

      "L2": ["#.   ",
             "#.   ",
             "#.   ",
             "#.   ",
             "#... ",
             "#### "],

      "P1": [" ###.",
             " #..#",
             " #..#",
             " ### ",
             " #   ",
             " #   "],

      "P2": ["###. ",
             "#..# ",
             "#..# ",
             "###  ",
             "#    ",
             "#    "],

      "Y1": ["#...#",
             "#...#",
             ".# #.",
             "..#..",
             "..#..",
             "..#.."],

      "Z1": [" ####",
             " ...#",
             "   # ",
             "  #  ",
             " #...",
             " ####"]
    }.toTable

var
  patterns5x6Flat: Table[string, string]
for key, val in patterns5x6.pairs:
  patterns5x6Flat[key] = val.join("")

proc transpose*[T](bits: seq[T]; letterWidth = dot5x6Width, letterHeight = dot5x6Height): seq[seq[T]] =
  let
    numLetters = bits.len div letterWidth div letterHeight
  result = newSeq[seq[T]](numLetters)
  for rowNum in 0 ..< letterHeight:
    let
      bitsPerRow = bits.len div letterHeight
      rowBits = bits[rowNum*bitsPerRow ..< (rowNum+1)*bitsPerRow]
    for letterId in 0 ..< bitsPerRow div letterWidth:
      result[letterId].add(rowBits[letterId*letterWidth ..< (letterId+1)*letterWidth])

proc parseLetter*[T](letter: openArray[T]; letterWidth = dot5x6Width, letterHeight = dot5x6Height): string =
  # Support only 5x6 dot matrix for now.
  doAssert letterWidth == dot5x6Width
  doAssert letterHeight == dot5x6Height
  var
    matchedLetter: char
  for l, pat in patterns5x6Flat.pairs:
    matchedLetter = l[0]
    for i in 0 ..< letterWidth*letterHeight:
      if pat[i] == '#' and letter[i] != 1:
        matchedLetter = '\0'
        break
      if pat[i] == '.' and letter[i] != 0:
        matchedLetter = '\0'
        break
    if matchedLetter != '\0':
      break
  if matchedLetter == '\0':
    echo &"[Error] Letter parsing failed for {letter}"
    result = ""
  else:
    result = $matchedLetter

proc parseLetters*[T](letters: openArray[seq[T]]; letterWidth = dot5x6Width, letterHeight = dot5x6Height): string =
  for letter in letters:
    result.add(letter.parseLetter(letterWidth, letterHeight))

when isMainModule:
  import std/[unittest]

  suite "transpose":
    setup:
      let
        bitsInt = @[0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2,
                    0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2,
                    0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2,
                    0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2,
                    0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2,
                    0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2]

    test "check":
      check:
        bitsInt.transpose(4, 6)[0] == @[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        bitsInt.transpose(4, 6)[1] == @[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
        bitsInt.transpose(4, 6)[2] == @[2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]

  suite "single letter":

    # test "B":
    #   check:
    #     @[].parseLetter() == "B"

    test "A":
      check:
        @[0, 1, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 1, 1, 1, 1, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0].parseLetter() == "A"

    test "B":
      check:
        @[0, 1, 1, 1, 0, 0, 1, 0, 0, 1, 0, 1, 1, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 1, 1, 1, 0].parseLetter() == "B"

    test "E":
      check:
        @[0, 1, 1, 1, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1].parseLetter() == "E"
        @[1, 1, 1, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0].parseLetter() == "E"

    test "G":
      check:
        @[0, 0, 1, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 1, 1, 1].parseLetter() == "G"
        @[0, 1, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 1, 1, 1, 0].parseLetter() == "G"

    test "J":
      check:
        @[0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0].parseLetter() == "J"
        @[0, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0, 0].parseLetter() == "J"

    test "L":
      check:
        @[0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1].parseLetter() == "L"

    test "P":
      check:
        @[0, 1, 1, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 1, 1, 1, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0].parseLetter() == "P"
        @[0, 1, 1, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0].parseLetter() == "P"

    test "Z":
      check:
        @[0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1].parseLetter() == "Z"

  suite "letter seq":

    test "example 1":
      check:
        @[@[0, 1, 1, 1, 0, 0, 1, 0, 0, 1, 0, 1, 1, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 1, 1, 1, 0],
          @[0, 1, 1, 1, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1],
          @[0, 0, 1, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 1, 1, 1],
          @[0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0],
          @[0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1],
          @[0, 1, 1, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 1, 1, 1, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0],
          @[0, 1, 1, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0],
          @[0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1]].parseLetters == "BEGJLPPZ"
