# Not in nixpkgs yet. Upstream's prebuilt Linux tarball, patched the way nixpkgs patches google-chrome.
# No SUID chrome-sandbox in the tarball; Chromium sandboxes itself with unprivileged user namespaces.
{
  lib, stdenvNoCC, fetchurl, cacert, gnupg, nix-update-script, makeWrapper, patchelf, bintools, addDriverRunpath, xdg-utils,
  adwaita-icon-theme, glib, gsettings-desktop-schemas,

  alsa-lib, at-spi2-core, cairo, cups, dbus, expat, gcc-unwrapped, gdk-pixbuf, gtk3, libgbm, libglvnd,
  libpulseaudio, libva, libxkbcommon, nspr, nss, pango, pciutils, pipewire, systemdLibs, vulkan-loader,
  libx11, libxcb, libxcomposite, libxcursor, libxdamage, libxext, libxfixes, libxrandr,
}:
let
  # What the binary links or dlopens. Fonts and Wayland are bundled, Kerberos is compiled out, GTK 3 is the default toolkit.
  libs = [
    alsa-lib at-spi2-core cairo cups dbus expat gcc-unwrapped.lib gdk-pixbuf glib gtk3 libgbm libglvnd
    libpulseaudio libva libxkbcommon nspr nss pango pciutils pipewire systemdLibs vulkan-loader
    libx11 libxcb libxcomposite libxcursor libxdamage libxext libxfixes libxrandr
  ];
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "helium";
  version = "0.21.1.1";

  src = fetchurl rec {
    url = "https://github.com/imputnet/helium-linux/releases/download/${finalAttrs.version}/helium-${finalAttrs.version}-x86_64_linux.tar.xz";
    hash = "sha256-bNfyQBU8ucDN+ie/GmZR3crnOomK/ESak90Q2oO0vUU=";

    # Runs whenever the hash gets computed, so a new version only gets a hash if Helium signed it.
    # pubkey.asc: BE67 7C19 89D3 5EAB 2C5F  26C9 3516 01AD 01D6 378E, the key in upstream's README that also signs their apt repo.
    nativeBuildInputs = [ gnupg ];
    postFetch = ''
      export GNUPGHOME=$(mktemp -d)
      curl -fsSL --cacert ${cacert}/etc/ssl/certs/ca-bundle.crt "${url}.asc" -o sig  # fetchurl only has certs while the hash is fake
      gpg --dearmor < ${./pubkey.asc} > key.gpg
      gpgv --keyring ./key.gpg sig "$out"
    '';
  };

  nativeBuildInputs = [ makeWrapper patchelf ];
  buildInputs = [ adwaita-icon-theme glib gtk3 gsettings-desktop-schemas ];  # Icons + schemas for GTK dialogs

  installPhase = ''
    runHook preInstall

    dir=$out/share/helium
    mkdir -p $out/bin $dir $out/share/applications $out/share/icons/hicolor/256x256/apps
    cp -a . $dir
    rm $dir/{chromedriver,helium-wrapper}

    ln -sf ${lib.getLib vulkan-loader}/lib/libvulkan.so.1 $dir/libvulkan.so.1
    mv $dir/product_logo_256.png $out/share/icons/hicolor/256x256/apps/helium.png
    mv $dir/helium.desktop $out/share/applications/helium.desktop

    rpath=${lib.makeLibraryPath libs}
    for elf in $dir/{helium,helium_crashpad_handler}; do
      patchelf --set-interpreter ${bintools.dynamicLinker} --set-rpath "$rpath" $elf
    done

    makeWrapper $dir/helium $out/bin/helium \
      --prefix LD_LIBRARY_PATH : "$rpath" \
      --suffix PATH : ${lib.makeBinPath [ xdg-utils ]} \
      --prefix XDG_DATA_DIRS : "$XDG_ICON_DIRS:$GSETTINGS_SCHEMAS_PATH:${addDriverRunpath.driverLink}/share" \
      --set CHROME_WRAPPER helium \
      --set CHROME_VERSION_EXTRA nixos \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}"

    runHook postInstall
  '';

  # The releases API marks prereleases; the default release feed doesn't, and their versions look like normal ones
  passthru.updateScript = nix-update-script { extraArgs = [ "--use-github-releases" ]; };

  meta = {
    description = "Private, fast, and honest web browser based on ungoogled-chromium";
    homepage = "https://helium.computer";
    license = lib.licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "helium";
  };
})
