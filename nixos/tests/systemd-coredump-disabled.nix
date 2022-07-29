import ./make-test-python.nix ({ pkgs, ... }:

let

  crasher = pkgs.writeCBin "crasher" "int main;";

in

{
  name = "systemd-coredump-disabled";
  meta = with pkgs.lib.maintainers; {
    maintainers = [ squalus ];
  };

  nodes.machine = { pkgs, lib, ... }: {
    systemd.coredump.enable = false;
    systemd.package = pkgs.systemd.override {
      withCoredump = false;
    };
    systemd.services.crasher.serviceConfig = {
      ExecStart = "${crasher}/bin/crasher";
      StateDirectory = "crasher";
      WorkingDirectory = "%S/crasher";
      Restart = "no";
    };
  };

  testScript = ''
    machine.wait_for_unit("multi-user.target")
    machine.systemctl("start crasher");
    machine.wait_until_succeeds("stat /var/lib/crasher/core", timeout=10)
  '';
})
