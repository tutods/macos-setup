{
  aiLib,
  lib,
  ...
}: {
  imports = [
    (aiLib.mkLocalSkills {
      inherit lib;
      label = "work";
      dir = ./skills/local;
      names = ["acli" "babysit-prs" "deep-review-prs" "implement-ticket" "work-stack"];
    })
  ];

  home.ai.extraInstructions = builtins.readFile ./instructions.md;
}
