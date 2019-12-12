task profile, "profile day12 code":
  selfExec "c -d:danger -d:profile -r day12"
  exec "hyperfine --warmup 2 --runs 3 ./day12"
