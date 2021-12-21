{ fetchurl, fetchFromGitLab }:
let src = builtins.fromJSON (builtins.readFile ./src.json);
in {
  inherit (src) packageVersion;
  common = fetchFromGitLab {
    owner = "librewolf-community";
    repo = "browser/common";
    inherit (src.common) rev sha256;
  };
  settings = fetchFromGitLab {
    owner = "librewolf-community";
    repo = "settings";
    inherit (src.settings) rev sha256;
  };
  firefox = fetchurl {
    url =
      "mirror://mozilla/firefox/releases/${src.firefox.version}/source/firefox-${src.firefox.version}.source.tar.xz";
    inherit (src.firefox) sha512;
  };
}

