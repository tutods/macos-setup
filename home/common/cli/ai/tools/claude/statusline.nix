{...}: {
  home.file.".claude/statusline.sh" = {
    source = ./statusline.sh;
    force = true;
  };
}
