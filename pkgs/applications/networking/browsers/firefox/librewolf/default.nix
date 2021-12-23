{ callPackage }:
let src = callPackage ./src.nix { };
in rec {

  inherit (src) packageVersion firefox common settings;

  # it would be great if we could automatically extract these values from the librewolf source

  patchNames = [
    "remove_addons.patch"
    "megabar.patch"
    "mozilla-vpn-ad.patch"
    "sed-patches/disable-pocket.patch"
    "context-menu.patch"
    "browser-confvars.patch"
    "urlbarprovider-interventions.patch"
    "sed-patches/remove-internal-plugin-certs.patch"
    "sed-patches/allow-searchengines-non-esr.patch"
    "sed-patches/stop-undesired-requests.patch"
    "about-dialog.patch"
    "mozilla_dirs.patch"
    "allow-ubo-private-mode.patch"
    "ui-patches/add-language-warning.patch"
    "ui-patches/pref-naming.patch"
    "ui-patches/remove-branding-urlbar.patch"
    "ui-patches/remove-cfrprefs.patch"
    "ui-patches/remove-organization-policy-banner.patch"
    "ui-patches/remove-snippets-from-home.patch"
    "ui-patches/sanitizing-description.patch"
  ];

  extraConfigureFlags = [
    "--with-app-name=librewolf"
    "--with-app-basename=LibreWolf"
    "--with-branding=browser/branding/librewolf"
    "--with-distribution-id=io.gitlab.librewolf-community"
    "--with-unsigned-addon-scopes=app,system"
    "--allow-addon-sideload"
  ];

  extraPostPatch = ''
    cp -r ${common}/source_files/browser .
    cp ${common}/source_files/search-config.json services/settings/dumps/main/search-config.json
    sed -i '/MOZ_SERVICES_HEALTHREPORT/ s/True/False/' browser/moz.configure
    sed -i '/MOZ_NORMANDY/ s/True/False/' browser/moz.configure
  '';

  extraPrefsFiles = [ "${settings}/librewolf.cfg" ];

  extraPoliciesFiles = [ "${settings}/distribution/policies.json" ];

  extraPassthru = { inherit extraPrefsFiles extraPoliciesFiles; };

  patches = (map (name: "${common}/patches/${name}") patchNames)
    ++ [ ./verify-telemetry-macros.patch ];
}

