import std/[strutils, strformat, sequtils]

const
  pswdLength = 6

proc isValidPassword(pswd: int): bool =
  result = false
  let
    pswdStr = $pswd

  # length check
  if pswdStr.len != pswdLength:
    return

  # digits same or incr
  var
    prevDigit = 0
    doublesCount: array[pswdLength, int]
  for idx, digit in pswdStr:
    let
      currentDigit = parseInt($digit)
    if currentDigit < prevDigit:
      return
    if currentDigit == prevDigit:
      doublesCount[idx] = 1
      when not defined(part1):
        if idx >= 1 and doublesCount[idx-1] > 0:
          # If the previous digit was a double count too, increment the
          # double count counter for both current and previous
          # indices. That way we can ensure that legal double counts
          # always have a value of 1.
          doublesCount[idx].inc
          doublesCount[idx-1].inc
    when defined(debug):
      echo doublesCount
    prevDigit = currentDigit

  when defined(debug):
    echo ""
  # at least one set of double digits
  return doublesCount.anyIt(it == 1)

proc numValidPasswords(bounds: Slice[int]): int =
  for p in bounds:
    if p.isValidPassword():
      result.inc

when isMainModule:
  import std/[unittest]

  when defined(part1):
    suite "part 1 only password validity checks":
      test &"length == {pswdLength}, digits same or incr, at least one double checks":
        check:
          isValidPassword(111111) == true

  suite "part 1 + part 2 password validity checks":
    test &"length == {pswdLength} checks":
      check:
        isValidPassword(11111) == false
        isValidPassword(112233) == true

    test "digits same or incr":
      check:
        isValidPassword(111122) == true
        isValidPassword(112233) == true
        isValidPassword(223450) == false

    test "at least one double":
      check:
        isValidPassword(111122) == true
        isValidPassword(123789) == false

  when not defined(part1):
    suite "part 2 only extra password validity check":
      test "a double is not part of a larger group of matching digits":
        check:
          isValidPassword(111111) == false
          isValidPassword(123444) == false
          isValidPassword(124445) == false
          isValidPassword(111123) == false
          isValidPassword(112233) == true
          isValidPassword(111122) == true

  when defined(part1):
    suite "day4 part1 challenge":
      test "check":
        check:
          numValidPasswords(246515 .. 739105) == 1048
  else:
    suite "day4 part2 challenge":
      test "check":
        check:
          numValidPasswords(246515 .. 739105) == 677
