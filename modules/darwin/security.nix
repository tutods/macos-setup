{...}: {
  security = {
    pam = {
      services = {
        sudo_local = {
          touchIdAuth = true;
        };
      };
    };
  };

  networking = {
    applicationFirewall = {
      enable = true;
      blockAllIncoming = false;
      enableStealthMode = true;
    };
  };

  system = {
    defaults = {
      loginwindow = {
        GuestEnabled = false;
      };
    };
  };
}