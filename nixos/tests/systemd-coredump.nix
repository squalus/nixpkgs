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
      Restart = "no";
    };
  };

  testScript = ''
    machine.wait_for_unit("multi-user.target")
    machine.wait_for_unit("systemd-coredump.socket")
    machine.systemctl("start crasher");
    machine.wait_until_succeeds("coredumpctl list | grep crasher", timeout=10)
  '';
})
