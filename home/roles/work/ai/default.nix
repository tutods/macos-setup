{...}: {
  home.ai.extraInstructions = builtins.readFile ./instructions.md;
}
