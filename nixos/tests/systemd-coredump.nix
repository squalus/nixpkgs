import ./make-test-python.nix ({ pkgs, ... }:

let

  crasher = pkgs.writeCBin "crasher" "int main;";

in

{
  name = "systemd-coredump";
  meta = with pkgs.lib.maintainers; {
    maintainers = [ squalus ];
  };

  nodes.machine = { pkgs, lib, ... }: {
    systemd.services.crasher.serviceConfig = {
      ExecStart = "${crasher}/bin/crasher";
      StateDirectory = "crasher";
      WorkingDirectory = "%S/crasher";
      Restart = "no";
    };

    specialisation.disabled.configuration.systemd = {
      coredump.enable = false;
      package = pkgs.systemd.override {
        withCoredump = false;
      };
    };

  };

  testScript = ''
    with subtest("systemd-coredump enabled"):
      machine.wait_for_unit("multi-user.target")
      machine.wait_for_unit("systemd-coredump.socket")
      machine.systemctl("start crasher");
      machine.wait_until_succeeds("coredumpctl list | grep crasher", timeout=10)
      machine.fail("stat /var/lib/crasher/core")

    with subtest("systemd-coredump disabled"):
      machine.succeed("/run/current-system/specialisation/disabled/bin/switch-to-configuration test")
      machine.systemctl("start crasher");
      machine.wait_until_succeeds("stat /var/lib/crasher/core", timeout=10)
  '';
})
