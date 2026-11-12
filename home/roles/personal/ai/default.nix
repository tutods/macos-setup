{
  aiLib,
  config,
  lib,
  pkgs,
  ...
}: let
  gh = owner: repo: rev: hash: pkgs.fetchFromGitHub {inherit owner repo rev hash;};

  findSkills = pkgs.applyPatches {
    name = "find-skills-src";
    src = gh "vercel-labs" "skills" "e781cb4d07433dfe1d19e924ed45cc61738c55ec" "sha256-K4xCSpt8jnkTx8FDEa2cXrzMjpRkYOwTiFqPap6iCYU=";
    postPatch = ''
      f=skills/find-skills/SKILL.md
      substituteInPlace $f --replace-fail 'questions like "how do I do X", "find a skill for X"' 'questions like "find a skill for X"'
      substituteInPlace $f --replace-fail 'npx skills find' 'DISABLE_TELEMETRY=1 npx -y skills@1.8.1 find'
      substituteInPlace $f --replace-fail '### Step 6: Offer to Install' '### Step 6: Adopt through the dotfiles flake (see the last section)'
      substituteInPlace $f --replace-fail 'npx skills add <owner/repo@skill> -g -y' '# never run: adoption goes through Nix, see the last section'
      substituteInPlace $f --replace-fail '- `npx skills add <package>` - Install a skill from GitHub or other sources' '- Install and update go through the dotfiles flake, see the last section'
      substituteInPlace $f --replace-fail '- `npx skills update` - Update all installed skills' '- Never run any other `npx skills` subcommand'
      substituteInPlace $f --replace-fail 'npx skills add vercel-labs/agent-skills@react-best-practices' 'Adopt it through the dotfiles flake (see the last section)'
      substituteInPlace $f --replace-fail 'The `-g` flag installs globally (user-level) and `-y` skips confirmation prompts.' 'Adoption is a pinned Nix declaration, never this CLI.'
      cat ${./find-skills-adopt.md} >> $f
    '';
  };

  taskObserver =
    pkgs.runCommand "task-observer-src" {
      src = gh "rebelytics" "one-skill-to-rule-them-all" "d61bc31f7857948710a947673c0e373bef4ed3d0" "sha256-68cdEBftMgbecCr+T0k36Aey/I7+y+/HAjmEKZuXEk8=";
    } ''
      mkdir -p $out
      cp -R $src $out/task-observer
      chmod -R u+w $out
      cd $out/task-observer
      rm -rf .github .claude-plugin plugins
      test "$(grep -c '^name: task-observer$' SKILL.md)" = 1
      sed -i 's/^name: task-observer$/&\ndisable-model-invocation: true/' SKILL.md
      find . -name '*.md' -exec sed -i 's|\[ABSOLUTE PATH\]|${config.home.homeDirectory}/.claude|g' {} +
      mkdir -p agents
      printf 'policy:\n  allow_implicit_invocation: false\n' > agents/openai.yaml
      cat ${./task-observer-local.md} >> SKILL.md
    '';
in {
  imports = [
    ./codex.nix
    (aiLib.mkFetchedSkills {
      inherit lib;
      src = "${pkgs.fetchFromGitHub {
        owner = "cloudflare";
        repo = "security-audit-skill";
        rev = "c1c8a8c1471069fb0e188eeaff69b8e8db6564a8";
        hash = "sha256-oVVACjotkHvllQGxEP8yWaEt4c3GxT0d909TUM5P3NM=";
      }}/skills";
      names = ["security-audit"];
    })
    (aiLib.mkFetchedSkills {
      inherit lib;
      src = "${findSkills}/skills";
      names = ["find-skills"];
    })
    (aiLib.mkFetchedSkills {
      inherit lib;
      src = "${taskObserver}";
      names = ["task-observer"];
    })
    (aiLib.mkFetchedSkills {
      inherit lib;
      src = "${gh "addyosmani" "agent-skills" "301b02b12bff98e4688e6984af6556802322bbde" "sha256-ewVxgb5GqtUeWcGydFz3GbzUkM0p+cuRfP+tlPAg4PY="}/skills";
      names = ["source-driven-development"];
    })
    (aiLib.mkFetchedSkills {
      inherit lib;
      src = "${gh "payloadcms" "skills" "832d5bc4258ae784f08cb7f03a3a674d6b2fa5f1" "sha256-kX3WMREQpWSr3CeJVUMkyKGWJaryEeUNPHFuwakjDZc="}/skills";
      names = ["payload"];
    })
    (aiLib.mkFetchedSkills {
      inherit lib;
      src = "${gh "openai" "skills" "49f948faa9258a0c61caceaf225e179651397431" "sha256-t4oGnFg0YpxJaQiFpgTiwYhaFoZK6wPDiqvHoG0bXiU="}/skills/.curated";
      names = ["gh-fix-ci" "gh-address-comments"];
    })
    (aiLib.mkFetchedSkills {
      inherit lib;
      src = "${gh "heygen-com" "hyperframes" "83b34cbe49d5a44335875c44a2b95cef75211dc4" "sha256-APygJleGJ+JEr3EYMSPM7e64SmUNLmEohqL5vtiGePw="}/skills";
      names = ["figma" "hyperframes" "hyperframes-cli" "hyperframes-registry" "media-use" "remotion-to-hyperframes" "slideshow"];
    })
    (aiLib.mkFetchedSkills {
      inherit lib;
      src = "${gh "vercel-labs" "agent-desktop" "54855b6225aec00da4ac65e2d0362fd41cd9fcb3" "sha256-1abZukVr7TXRfGCi+2meQentLXTDJw7snT5ktKpSD4M="}/skills";
      names = ["agent-desktop"];
    })
    (aiLib.mkFetchedSkills {
      inherit lib;
      src = "${gh "getsentry" "skills" "e94f22214528d69899d09c627b3315ddc3544816" "sha256-1oCqfLcNIH/BrxEw6fE7kcsyFpRSZFi7G44VuXccbeA="}/skills";
      names = ["gha-security-review"];
    })
    (aiLib.mkLocalSkills {
      inherit lib;
      dir = ./skills;
      names = ["pt-pt-copy" "wp-live-site"];
    })
    (aiLib.mkLocalAgents {
      inherit lib;
      dir = ./agents;
      names = ["wp-site"];
    })
  ];

  home.ai.extraInstructions = builtins.readFile ./instructions.md;

  home.ai.marketplaces = {
    tokeneconomizer = "microsoft/TokenEconomizer@0566b6036749326b865e0ce073cf894f198b4886";
  };

  home.ai.plugins = [
    "tokeneconomizer@tokeneconomizer" # trial, see docs/ai-setup.md
    "context7@claude-plugins-official"
  ];

  home.ai.claudeEnv.TE_PYTHON = "${pkgs.python3}/bin/python3";

  home.sessionVariables = {
    TE_PYTHON = "${pkgs.python3}/bin/python3";
  };

  # Merges into ~/.claude.json mcpServers, which Claude Code also writes; Nix adds, never removes.
  # Dropping a server here leaves it live: claude mcp remove <name> --scope user.
  home.activation.claudeMcp = lib.hm.dag.entryAfter ["writeBoundary"] (
    aiLib.mergeJsonKey {
      file = "$HOME/.claude.json";
      key = "mcpServers";
      value = {
        shadcn = aiLib.mkServer {
          cmd = "npx";
          args = ["-y" "shadcn@latest" "mcp"];
        };
      };
      extraMerge = ''.mcpServers = (.mcpServers // {}) + $v'';
    }
  );
}
