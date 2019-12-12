task profile, "profile day12 code":
  selfExec "c -d:danger -r day12"
  exec "hyperfine --warmup 2 --runs 10 ./day12"
