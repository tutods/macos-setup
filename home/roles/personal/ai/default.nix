let
  instructions = builtins.readFile ./instructions.md;
in {
  home.ai.extraInstructions = instructions;
}
