{
  # Git
  g="git";
  gst="git status -sb";
  gp="git push";
  gl="git pull";
  gco="git checkout";
  gb="git branch";
  gaa="git add .";
  ga="git add";
  grh="git reset --hard";
  gr="git reset";
  # Homebrew
  bci="brew install --cask";
  bi="brew install";
  bup="brew update";
  bug="brew upgrade";
  bcl="brew cleanup";
  br="brew remove";
  bsearch="brew search";

  # Docker
  #docker="podman" #-> Remove comment if you are using podman;
  dps="docker ps --format '{{.Names}}'";
  dvunused="docker volume ls -q -f 'dangling=true'";

  # Navigation Alias
  work="cd ~/Developer";
  home="cd ~";
  ..="cd ..";
  ...="cd ../..";

  # Eza on LS
  ls="eza";
}