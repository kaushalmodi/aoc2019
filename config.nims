import std/[os, strutils, strformat]

switch("path", "./utils/")
switch("path", "./day02/") # IntCode

task days, "Run code for a specified day, or all days":
  let
    numParams = system.paramCount()
  if numParams > 1: # "nim days 1" will have a count of 2.
    for i in 2 .. numParams:
      var
        day = system.paramStr(i)
      if day.len == 1:
        day = "0" & day
      let
        nimFile = &"./day{day}/day{day}.nim"
      echo &"Running {nimFile} .."
      selfExec &"c -r -d:release {nimFile}"
      echo ""
  else:
    for file in walkDirRec(".", {pcFile}):
      let
        (dir, fileName, ext) = file.splitFile()
      if dir.contains("day") and fileName.startsWith("day") and ext == ".nim":
        echo &"Running {file} .."
        selfExec &"c -r -d:release {file}"
        echo ""
