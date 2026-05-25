{
  # Docker
  dps = "docker ps --format '{{.Names}}'";
  dvunused = "docker volume ls -q -f 'dangling=true'";

  # Navigation
  work = "cd $PROJECT_DIR";
  home = "cd ~";
  ".." = "cd ..";
  "..." = "cd ../..";
}
