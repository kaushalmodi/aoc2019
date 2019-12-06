import std/[strutils]

proc isValidPassword(pswd: int): bool =
  result = false
  let
    pswdStr = $pswd

  # length check
  if pswdStr.len != 6:
    return

  # digits same or incr
  var
    prevDigit = 0
    doublesCount = 0
  for digit in pswdStr:
    let
      currentDigit = parseInt($digit)
    if currentDigit < prevDigit:
      return
    if currentDigit == prevDigit:
      doublesCount.inc
    prevDigit = currentDigit

  # at least one set of double digits
  return doublesCount > 0

proc numValidPasswords(bounds: Slice[int]): int =
  for p in bounds:
    if p.isValidPassword():
      result.inc

when isMainModule:
  import std/[unittest]

  suite "password validity checks":
    test "length == 6 checks":
      check:
        isValidPassword(11111) == false
        isValidPassword(111111) == true

    test "digits same or incr":
      check:
        isValidPassword(111111) == true
        isValidPassword(223450) == false

    test "at least one double":
      check:
        isValidPassword(111111) == true
        isValidPassword(123789) == false

  suite "day4 challenge":
    test "check":
      check:
        numValidPasswords(246515 .. 739105) == 1048
