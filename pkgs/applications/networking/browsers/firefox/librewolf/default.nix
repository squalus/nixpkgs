{ callPackage, git }:
let
  src = callPackage ./src.nix { };
  prefPane = callPackage ./pref-pane.nix { };
  readLinesToList = file:
    builtins.filter (s: builtins.isString s && builtins.stringLength s > 0)
    (builtins.split "\n" (builtins.readFile file));
in rec {

  inherit (src) packageVersion firefox source settings;

  skippedPatches = [
    "patches/xmas.patch" # adds the config customizations to the build. we do this in the wrapper instead
  ];

  upstreamPatchNames = readLinesToList "${source}/assets/patches.txt";

  patchNames = builtins.filter (name: !(builtins.elem name skippedPatches))
    upstreamPatchNames;

  patches = (map (name: "${source}/${name}") patchNames)
    ++ [ prefPane ./verify-telemetry-macros.patch ];

  extraConfigureFlags = [
    "--with-app-name=librewolf"
    "--with-app-basename=LibreWolf"
    "--with-branding=browser/branding/librewolf"
    "--with-distribution-id=io.gitlab.librewolf-community"
    "--with-unsigned-addon-scopes=app,system"
    "--allow-addon-sideload"
  ];

  extraPostPatch = ''
    cp -r ${source}/themes/browser .
    cp ${source}/assets/search-config.json services/settings/dumps/main/search-config.json
    sed -i '/MOZ_SERVICES_HEALTHREPORT/ s/True/False/' browser/moz.configure
    sed -i '/MOZ_NORMANDY/ s/True/False/' browser/moz.configure
  '';

  extraPrefsFiles = [ "${settings}/librewolf.cfg" ];

  extraPoliciesFiles = [ "${settings}/distribution/policies.json" ];

  extraPassthru = {
    librewolf = { inherit src patches patchNames prefPane; };
    inherit extraPrefsFiles extraPoliciesFiles patches;
  };
}

