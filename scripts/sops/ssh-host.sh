# Edit a private ssh host in ~/.nixos-secrets/ssh/hosts/, or add a new one.
#
# Usage: sops-ssh-host <alias> [file]
#        sops ssh-host <alias> [file]   (bash function from home/timic.nix)
#
# Opens the host file whose Host line names <alias>. If none does, creates
# ssh/hosts/<file>.yaml (default: <alias>.yaml) from a template. New ones also
# need <file> in sshHosts in modules/system/secrets.nix, which is public, so
# pass [file] to keep a sensitive alias out of it.
#
# Built with writeShellApplication, which adds the shebang and `set -euo pipefail`.

if (( $# < 1 || $# > 2 )); then
  echo "usage: sops-ssh-host <alias> [file]" >&2
  exit 1
fi
host=$1
name=${2:-$1}

# sops looks for .sops.yaml from the working directory upwards
cd ~/.nixos-secrets
hosts=ssh/hosts

# Succeeds if $host is one of the aliases on a Host line of the given file
has_host() {
  local -a words
  local alias
  # Splits each line on spaces and tabs, like ssh does
  while read -ra words; do
    # Keywords are case-insensitive, and Host can list several aliases
    if (( ${#words[@]} > 1 )) && [[ ${words[0],,} == host ]]; then
      for alias in "${words[@]:1}"; do
        if [[ $alias == "$host" ]]; then
          return 0
        fi
      done
    fi
  done < <(sops decrypt --extract '["config"]' "$1")
  return 1
}

# Edit the existing host, if there is one
shopt -s nullglob  # No host files means no iterations, not a literal '*.yaml'
for file in "$hosts"/*.yaml; do
  if has_host "$file"; then
    exec sops edit "$file"
  fi
done

# Otherwise create one from a template
file=$hosts/${name%.yaml}.yaml
if [[ -e $file ]]; then
  echo "$file already exists in ~/.nixos-secrets, but has no Host $host" >&2
  exit 1
fi
mkdir -p "$hosts"
# shellcheck disable=SC2094  # --filename-override only picks the .sops.yaml rule, $file isn't read
sops encrypt --filename-override "$file" > "$file" <<EOF
config: |
  Host $host
    HostName
    User
EOF

# sops only rewrites the file when something was saved, so an untouched template is dropped
if sops edit "$file"; then
  echo "Added ~/.nixos-secrets/$file. Add \"${name%.yaml}\" to sshHosts in modules/system/secrets.nix, then run nixos-switch"
else
  rm "$file"
fi
