{lib, ...}:
# NOTE: mas install does not work on macOS 26+ (Tahome) due to Apple removing
# the private API for account/session management. Moved back to homebrew.masApps
# for declarative tracking, but installs may still need to be done manually
# from the App Store.
{
  home.activation.installMasApps = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # mas install is broken on macOS 26+ — skipping automated installs.
    # See homebrew masApps for the declarative app list.
  '';
}
