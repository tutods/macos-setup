{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    imagemagick
    jpegoptim
    optipng
    ffmpeg
  ];
}
