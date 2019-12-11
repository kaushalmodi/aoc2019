import std/[strformat, strutils, tables]

const
  dot5x6Width = 5
  dot5x6Height = 6
  # pattern syntax:
  #   '#': The input seq of letter "dots" needs to have a "non-zero" value at those char locations
  #   '.': The input seq of letter "dots" needs to have a "zero" value at those char locations
  #   ' ': The input seq of letter "dots" can have *any* value at those char locations
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

      "C1": ["",
             "",
             "",
             "",
             "",
             ""],

      "D1": ["",
             "",
             "",
             "",
             "",
             ""],

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

      "F1": ["",
             "",
             "",
             "",
             "",
             ""],

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

      "H1": ["",
             "",
             "",
             "",
             "",
             ""],

      "I1": ["",
             "",
             "",
             "",
             "",
             ""],

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

      "K1": ["",
             "",
             "",
             "",
             "",
             ""],

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

      "M1": ["",
             "",
             "",
             "",
             "",
             ""],

      "N1": ["",
             "",
             "",
             "",
             "",
             ""],

      "O1": ["",
             "",
             "",
             "",
             "",
             ""],

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

      "Q1": ["",
             "",
             "",
             "",
             "",
             ""],

      "R1": ["",
             "",
             "",
             "",
             "",
             ""],

      "S1": ["",
             "",
             "",
             "",
             "",
             ""],

      "T1": ["",
             "",
             "",
             "",
             "",
             ""],

      "U1": ["",
             "",
             "",
             "",
             "",
             ""],

      "V1": ["",
             "",
             "",
             "",
             "",
             ""],

      "W1": ["",
             "",
             "",
             "",
             "",
             ""],

      "X1": ["",
             "",
             "",
             "",
             "",
             ""],

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
             " ####"],

      " ": [".....",
            ".....",
            ".....",
            ".....",
            ".....",
            "....."]
    }.toTable

proc populatePatternsFlat(): Table[string, string] {.compileTime.} =
  for key, val in patterns5x6.pairs:
    if val[0] != "":
      result[key] = val.join("")
var
  patterns5x6Flat {.compileTime.} = populatePatternsFlat()

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

proc parseLetter*[T](dots: openArray[T]; letterWidth = dot5x6Width, letterHeight = dot5x6Height): char =
  # Support only 5x6 dot matrix for now.
  doAssert letterWidth == dot5x6Width
  doAssert letterHeight == dot5x6Height
  doAssert dots.len == dot5x6Width*dot5x6Height
  for l, pat in patterns5x6Flat.pairs:
    result = l[0]
    for i, dot in dots:
      if pat[i] == '#' and dot == 0 or
         pat[i] == '.' and dot != 0:
        # Start looking at the next pattern if the input dots seq has
        # a 0 where a 1 was expected, or vice-versa.
        result.reset()
        break
    # Stop searching patterns once a match is found.
    if result.ord > 0: break
  if result.ord == 0:
    echo &"[Error] Letter parsing failed for {dots}"

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
    #     @[].parseLetter() == 'B'

    test "failed match check":
      check:
        @[2, 5, 2, 1, 6, 4, 3, 7, 0, 8, 2, 8, 3, 5, 7, 7, 4, 0, 2, 5, 3, 3, 1, 8, 1, 0, 8, 0, 4, 8].parseLetter() == '\0'

    test "space":
      check:
        @[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0].parseLetter() == ' '

    test "A":
      check:
        @[0, 1, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 1, 1, 1, 1, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0].parseLetter() == 'A'

    test "B":
      check:
        @[0, 1, 1, 1, 0, 0, 1, 0, 0, 1, 0, 1, 1, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 1, 1, 1, 0].parseLetter() == 'B'

    test "E":
      check:
        @[0, 1, 1, 1, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1].parseLetter() == 'E'
        @[1, 1, 1, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0].parseLetter() == 'E'

    test "G":
      check:
        @[0, 0, 1, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 1, 1, 1].parseLetter() == 'G'
        @[0, 1, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 1, 1, 1, 0].parseLetter() == 'G'

    test "J":
      check:
        @[0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0].parseLetter() == 'J'
        @[0, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0, 0].parseLetter() == 'J'

    test "L":
      check:
        @[0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1].parseLetter() == 'L'

    test "P":
      check:
        @[0, 1, 1, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 1, 1, 1, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0].parseLetter() == 'P'
        @[0, 1, 1, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0].parseLetter() == 'P'

    test "Z":
      check:
        @[0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1].parseLetter() == 'Z'

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
