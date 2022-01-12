# Generate the pref pane patch. Follows the logic in source/scripts/librewolf-patches.py.
# It would be nice if upstream generated this patch.
{ stdenvNoCC, git, cacert }:
let
  base_hash = "1fee314adc81000294fc0cf3196a758e4b64dace";
  final_hash = "bcacbf712d576e934e4e3a3f0110f38c8293df4a";
in
stdenvNoCC.mkDerivation {
  name = "librewolf-pref-pane";
  nativeBuildInputs = [ git cacert ];
  unpackPhase = "true";
  buildPhase = ''
    git clone https://gitlab.com/librewolf-community/browser/librewolf-pref-pane.git
    cd librewolf-pref-pane
    git diff ${base_hash}..${final_hash} > patch
  '';
  installPhase = ''
    mv patch $out
  '';
  outputHashAlgo = "sha256";
  outputHash = "1rjvd4rqsq91k1pa1blkvsiqzh8z0lv098vwxx3nqcpqpizf4bwq";
}
