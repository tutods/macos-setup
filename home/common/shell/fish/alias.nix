{
  # Docker
  dps = "docker ps --format '{{.Names}}'";
  dvunused = "docker volume ls -q -f 'dangling=true'";

  # Navigation
  work = "cd ~/Developer";
  home = "cd ~";
  ".." = "cd ..";
  "..." = "cd ../..";
}
