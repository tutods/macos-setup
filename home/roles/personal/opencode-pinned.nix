# opencode 1.18.30, the version nixpkgs-unstable currently ships, crashes on
# every prompt: SystemPrompt.environment dereferences a missing entry and
# throws "undefined is not an object (evaluating 'a.name')" before any provider
# call. Upstream anomalyco/opencode#48645, tracked for nixpkgs in #563241, fixed
# upstream in 1.18.31. Vendor the official darwin-arm64 release build until
# nixpkgs bumps past 1.18.30, then delete this file and drop the override in
# packages.nix.
{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "opencode";
  version = "1.18.31";

  src = fetchurl {
    url = "https://github.com/anomalyco/opencode/releases/download/v${finalAttrs.version}/opencode-darwin-arm64.zip";
    hash = "sha256-yvfzH6GuwjU+qFnU75q4JMYnPZQbAW6I1RGT+jAo004=";
  };

  nativeBuildInputs = [unzip];
  sourceRoot = ".";

  # Bun compiles the CLI to a single self-extracting executable; stripping it
  # corrupts the embedded bundle.
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 opencode $out/bin/opencode
    runHook postInstall
  '';

  meta = {
    description = "AI coding agent built for the terminal";
    homepage = "https://github.com/anomalyco/opencode";
    license = lib.licenses.mit;
    mainProgram = "opencode";
    platforms = ["aarch64-darwin"];
  };
})
