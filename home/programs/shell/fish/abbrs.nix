{
  # Common abbreviations
  cp = "cp -i";
  mv = "mv -i";
  mkdir = "mkdir -p";
  caf = "caffeinate -dim"; # prevent display, idle and disk sleep

  # Git abbreviations (jhillyerd/plugin-git)
  g = "git";

  # Add
  ga = "git add";
  gaa = "git add --all";
  gau = "git add --update";
  gapa = "git add --patch";

  # Branch
  gb = "git branch -vv";
  gba = "git branch -a -v";
  gban = "git branch -a -v --no-merged";
  gbd = "git branch -d";
  gbD = "git branch -D";
  ggsup = "git branch --set-upstream-to=origin/(__git.current_branch)";

  # Bisect
  gbs = "git bisect";
  gbsb = "git bisect bad";
  gbsg = "git bisect good";
  gbsr = "git bisect reset";
  gbss = "git bisect start";

  # Blame
  gbl = "git blame -b -w";

  # Config
  gcf = "git config --list";

  # Commit
  gc = "git commit -v";
  "gc!" = "git commit -v --amend";
  "gcn!" = "git commit -v --no-edit --amend";
  gca = "git commit -v -a";
  "gca!" = "git commit -v -a --amend";
  "gcan!" = "git commit -v -a --no-edit --amend";
  gcv = "git commit -v --no-verify";
  gcav = "git commit -a -v --no-verify";
  "gcav!" = "git commit -a -v --no-verify --amend";
  gcm = "git commit -m";
  gcam = "git commit -a -m";
  gcs = "git commit -S";
  gscam = "git commit -S -a -m";
  gcfx = "git commit --fixup";

  # Clone & Clean
  gcl = "git clone";
  gclean = "git clean -di";
  "gclean!" = "git clean -dfx";
  "gclean!!" = "git reset --hard; and git clean -dfx";

  # Cherry-pick
  gcp = "git cherry-pick";
  gcpa = "git cherry-pick --abort";
  gcpc = "git cherry-pick --continue";

  # Checkout
  gco = "git checkout";
  gcb = "git checkout -b";
  gcod = "git checkout develop";
  gcom = "git checkout (__git.default_branch)";

  # Count & Diff
  gcount = "git shortlog -sn";
  gd = "git diff";
  gdca = "git diff --cached";
  gds = "git diff --stat";
  gdsc = "git diff --stat --cached";
  gdt = "git diff-tree --no-commit-id --name-only -r";
  gdw = "git diff --word-diff";
  gdwc = "git diff --word-diff --cached";
  gdto = "git difftool";
  gdg = "git diff --no-ext-diff";

  # Fetch
  gf = "git fetch";
  gfa = "git fetch --all --prune";
  gfm = "git fetch origin (__git.default_branch) --prune; and git merge FETCH_HEAD";
  gfo = "git fetch origin";

  # Pull
  gl = "git pull";
  ggl = "git pull origin (__git.current_branch)";
  gll = "git pull origin";
  glr = "git pull --rebase";
  gup = "git pull --rebase";
  gupv = "git pull --rebase -v";
  gupa = "git pull --rebase --autostash";
  gupav = "git pull --rebase --autostash -v";

  # Log
  glg = "git log --stat";
  glgg = "git log --graph";
  glgga = "git log --graph --decorate --all";
  glo = "git log --oneline --decorate --color";
  glog = "git log --oneline --decorate --color --graph";
  gloga = "git log --oneline --decorate --color --graph --all";
  glom = "git log --oneline --decorate --color (__git.default_branch)..";
  glod = "git log --oneline --decorate --color develop..";
  gloo = "git log --pretty=format:'%C(yellow)%h %Cred%ad %Cblue%an%Cgreen%d %Creset%s' --date=short";
  gwch = "git log -p --abbrev-commit --pretty=medium --raw --no-merges";

  # Merge
  gm = "git merge";
  gma = "git merge --abort";
  gmt = "git mergetool --no-prompt";
  gmom = "git merge origin/(__git.default_branch)";

  # Push
  gp = "git push";
  "gp!" = "git push --force-with-lease";
  gpo = "git push origin";
  "gpo!" = "git push --force-with-lease origin";
  gpv = "git push --no-verify";
  "gpv!" = "git push --no-verify --force-with-lease";
  ggp = "git push origin (__git.current_branch)";
  "ggp!" = "git push origin (__git.current_branch) --force-with-lease";
  gpu = "git push origin (__git.current_branch) --set-upstream";
  gpoat = "git push origin --all; and git push origin --tags";
  ggpnp = "git pull origin (__git.current_branch); and git push origin (__git.current_branch)";

  # Rebase
  grb = "git rebase";
  grba = "git rebase --abort";
  grbc = "git rebase --continue";
  grbi = "git rebase --interactive";
  grbm = "git rebase (__git.default_branch)";
  grbmi = "git rebase (__git.default_branch) --interactive";
  grbmia = "git rebase (__git.default_branch) --interactive --autosquash";
  grbom = "git fetch origin (__git.default_branch); and git rebase FETCH_HEAD";
  grbomi = "git fetch origin (__git.default_branch); and git rebase FETCH_HEAD --interactive";
  grbomia = "git fetch origin (__git.default_branch); and git rebase FETCH_HEAD --interactive --autosquash";
  grbd = "git rebase develop";
  grbdi = "git rebase develop --interactive";
  grbdia = "git rebase develop --interactive --autosquash";
  grbs = "git rebase --skip";
  ggu = "git pull --rebase origin (__git.current_branch)";

  # Remote
  gr = "git remote -vv";
  gra = "git remote add";
  grv = "git remote -v";
  grmv = "git remote rename";
  grpo = "git remote prune origin";
  grrm = "git remote remove";
  grset = "git remote set-url";
  grup = "git remote update";

  # Reset & Restore
  grh = "git reset";
  grhh = "git reset --hard";
  grhpa = "git reset --patch";
  grs = "git restore";
  grss = "git restore --source";
  grst = "git restore --staged";

  # Revert
  grev = "git revert";

  # Show & Status
  gsh = "git show";
  gst = "git status";
  gsb = "git status -sb";
  gss = "git status -s";

  # Stash
  gsta = "git stash";
  gstd = "git stash drop";
  gstl = "git stash list";
  gstp = "git stash pop";
  gsts = "git stash show --text";

  # Submodule
  gsu = "git submodule update";
  gsur = "git submodule update --recursive";
  gsuri = "git submodule update --recursive --init";

  # Switch & Tags
  gsw = "git switch";
  gswc = "git switch --create";
  gts = "git tag -s";
  gtv = "git tag | sort -V";

  # Ignore
  gignore = "git update-index --assume-unchanged";
  gunignore = "git update-index --no-assume-unchanged";

  # Git Flow
  gfb = "git flow bugfix";
  gff = "git flow feature";
  gfr = "git flow release";
  gfh = "git flow hotfix";
  gfs = "git flow support";
  gfbs = "git flow bugfix start";
  gffs = "git flow feature start";
  gfrs = "git flow release start";
  gfhs = "git flow hotfix start";
  gfss = "git flow support start";
  gfbt = "git flow bugfix track";
  gfft = "git flow feature track";
  gfrt = "git flow release track";
  gfht = "git flow hotfix track";
  gfst = "git flow support track";
  gfp = "git flow publish";

  # Worktree
  gwt = "git worktree";
  gwta = "git worktree add";
  gwtls = "git worktree list";
  gwtlo = "git worktree lock";
  gwtmv = "git worktree move";
  gwtpr = "git worktree prune";
  gwtrm = "git worktree remove";
  gwtulo = "git worktree unlock";

  # npm abbreviations
  ni = "npm install";
  nid = "npm install --save-dev";
  nr = "npm run";
  nd = "npm run dev";
  nb = "npm run build";
  nts = "npm run test";

  # pnpm abbreviations
  pi = "pnpm install";
  pa = "pnpm add";
  pad = "pnpm add -D";
  prd = "pnpm run dev";
  pb = "pnpm run build";
  pts = "pnpm run test";

  # Homebrew abbreviations
  bi = "brew install";
  bci = "brew install --cask";
  bri = "brew reinstall";
  br = "brew remove";
  bup = "brew update";
  bug = "brew upgrade";
  bcl = "brew cleanup";
  bsearch = "brew search";
}
