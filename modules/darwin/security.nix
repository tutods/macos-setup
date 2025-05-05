{ ... }:

{
  # Security changes
  security.pam = {
    services = {
      sudo_local = {
        touchIdAuth = true;
      };
    };
  };
}