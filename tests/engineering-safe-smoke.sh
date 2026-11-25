#!/usr/bin/env bash
set -euo pipefail
installers=(6000-Sensor-Installer.sh AIO-Sensor-Installer.sh DP-Installer.sh Sensor-Installer.sh)
bash -n "${installers[@]}"
for f in "${installers[@]}"; do
  grep -q 'DRY_RUN' "$f" || { echo "missing DRY_RUN contract: $f" >&2; exit 1; }
  grep -q 'pipefail' "$f" || { echo "missing strict shell mode: $f" >&2; exit 1; }

  grep -Fq 'stellar ALL=(root) NOPASSWD: /usr/local/bin/aella_cli ""' "$f" || {
    echo "missing no-argument CLI-only sudo rule: $f" >&2; exit 1;
  }
  ! grep -Fq 'NOPASSWD: ALL' "$f" || {
    echo "broad NOPASSWD grant remains: $f" >&2; exit 1;
  }
  ! grep -Fq 'chown -R stellar:stellar /var/log/aella' "$f" || {
    echo "CLI logs remain user-writable: $f" >&2; exit 1;
  }
  grep -Fq 'ForceCommand /usr/bin/aella_cli' "$f" || {
    echo "missing SSH ForceCommand gate: $f" >&2; exit 1;
  }
  grep -Fq 'AllowTcpForwarding no' "$f" || {
    echo "SSH forwarding is not disabled: $f" >&2; exit 1;
  }
  grep -Fq 'SSH_ORIGINAL_COMMAND' "$f" || {
    echo "login wrapper does not reject remote commands: $f" >&2; exit 1;
  }
  grep -Fq 'cd / || exit 1' "$f" || {
    echo "CLI wrapper does not use a trusted working directory: $f" >&2; exit 1;
  }
  grep -Fq 'chown -R root:root "${VENV_DIR}"' "$f" || {
    echo "CLI runtime is not root-owned: $f" >&2; exit 1;
  }
  grep -Fq 'find /var/log/aella -type f -exec chown root:syslog {} +' "$f" || {
    echo "CLI log files are not root-owned: $f" >&2; exit 1;
  }
  grep -Fq 'find /var/lib/aella -type f -exec chown root:syslog {} +' "$f" || {
    echo "CLI persistent state is not root-owned: $f" >&2; exit 1;
  }
  grep -Fq 'sudo -l -U stellar' "$f" || {
    echo "missing effective sudo privilege verification: $f" >&2; exit 1;
  }
  grep -Fq 'sshd -T -C user=stellar' "$f" || {
    echo "missing effective SSH policy verification: $f" >&2; exit 1;
  }
done
echo "ENGINEERING_SAFE_SMOKE=PASS"
