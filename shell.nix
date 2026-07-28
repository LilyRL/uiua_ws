{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    pkg-config
    rustc
    cargo
    llvmPackages.libclang.lib
  ];

  buildInputs = with pkgs; [
    alsa-lib
    libv4l
  ];

  shellHook = ''
    # Point bindgen to libclang
    export LIBCLANG_PATH="${pkgs.llvmPackages.libclang.lib}/lib"

    # Ensure pkg-config finds both ALSA and V4L2 libraries
    export PKG_CONFIG_PATH="${pkgs.alsa-lib.dev}/lib/pkgconfig:${pkgs.libv4l.dev}/lib/pkgconfig:$PKG_CONFIG_PATH"
  '';
}
