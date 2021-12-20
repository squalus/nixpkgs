{ writeScript, lib, coreutils, gnused, gnugrep, curl, gnupg, runtimeShell
, versionSuffix ? "", versionKey ? "version", jq, nix-prefetch-git, moreutils
, attrPath, common-updater-scripts }:

# The logic here:
# - we start from the librewolf-common repo and find the latest tag
# - we derive the firefox version from that
# - and then we grab the latest tag of the librewolf-settings repo

# When updating, default.nix should be manually reviewed against the
# changes in the upstream linux build scripts:
# - https://gitlab.com/librewolf-community/browser/linux/-/tree/master/scripts

writeScript "update-${attrPath}" ''
  #!${runtimeShell}

  PATH=${
    lib.makeBinPath [
      common-updater-scripts
      coreutils
      curl
      gnugrep
      gnupg
      gnused
      jq
      moreutils
      nix-prefetch-git
    ]
  }
  set -euo pipefail

  outJson=pkgs/applications/networking/browsers/firefox/librewolf/src.json

  commonRepoUrl=https://gitlab.com/librewolf-community/browser/common.git/
  settingsRepoUrl=https://gitlab.com/librewolf-community/settings.git/

  function updateLwRepo() {
    name=$1
    rev=$2
    url=$3
    hash=$(nix-prefetch-git $url --quiet --rev $rev | jq -r .sha256)
    jq ".$name.rev = \"$rev\"" $outJson | sponge $outJson
    jq ".$name.sha256 = \"$hash\"" $outJson | sponge $outJson
  }

  latestCommonTag=$(list-git-tags $commonRepoUrl | tail -n1)
  latestSettingsTag=$(list-git-tags $settingsRepoUrl | egrep '^[0-9\.]+$' | tail -n1)

  echo latestCommonTag=$latestCommonTag
  echo latestSettingsTag=$latestSettingsTag

  lwVersion=''${latestCommonTag:1}
  ffVersion=''${lwVersion%-*}
  echo lwVersion=$lwVersion
  echo ffVersion=$ffVersion

  HOME=$(mktemp -d)
  export GNUPGHOME=$(mktemp -d)
  gpg --receive-keys 14F26682D0916CDD81E37B6D61B7B526D98F0353

  mozillaUrl=https://archive.mozilla.org/pub/firefox/releases/

  curl --silent --show-error -o "$HOME"/shasums "$mozillaUrl$ffVersion/SHA512SUMS"
  curl --silent --show-error -o "$HOME"/shasums.asc "$mozillaUrl$ffVersion/SHA512SUMS.asc"
  gpgv --keyring="$GNUPGHOME"/pubring.kbx "$HOME"/shasums.asc "$HOME"/shasums

  ffHash=$(grep '\.source\.tar\.xz$' "$HOME"/shasums | grep '^[^ ]*' -o)
  echo ffHash=$ffHash

  updateLwRepo common $latestCommonTag $commonRepoUrl
  updateLwRepo settings $latestSettingsTag $settingsRepoUrl

  jq ".firefox.version = \"$ffVersion\"" $outJson | sponge $outJson
  jq ".firefox.sha512 = \"$ffHash\"" $outJson | sponge $outJson
  jq ".packageVersion = \"$lwVersion\"" $outJson | sponge $outJson
''
