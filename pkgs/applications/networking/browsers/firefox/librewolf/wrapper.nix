{ wrapFirefox, librewolf-unwrapped }:
let
  settings = librewolf-unwrapped.librewolf-src.settings;
  policies = builtins.fromJSON
    (builtins.readFile "${settings}/distribution/policies.json");
in wrapFirefox librewolf-unwrapped {
  libName = "librewolf";
  extraPolicies = policies.policies;
  extraPrefs = builtins.readFile "${settings}/librewolf.cfg";
}
