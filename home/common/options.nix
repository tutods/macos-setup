{lib, ...}: {
  options.home.devDir = lib.mkOption {
    type = lib.types.str;
    default = "$HOME/Developer";
    description = "Primary development directory (used by fish shell and other tools)";
  };
}
