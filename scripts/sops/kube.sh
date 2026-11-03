# Edit a kubeconfig in ~/.nixos-secrets/kube/, or add a new one.
#
# Usage: sops-kube <name> [kubeconfig]
#        sops kube <name> [kubeconfig]   (bash function from home/timic.nix)
#
# Opens kube/<name>.yaml. If it doesn't exist, imports [kubeconfig]
# (/dev/stdin works, e.g. piped from a server over ssh), or creates one from a
# template without it. New ones also need <name> in kubeconfigs in
# modules/apps/kubernetes.nix.
#
# kubectl merges all of them, and the first file to use a name wins. So an
# import with a single context gets its context, cluster and user renamed to
# <name>. current-context is dropped too, or kubectl would try to write context
# switches into the read-only secret instead of ~/.kube/config.
#
# Built with writeShellApplication, which adds the shebang and `set -euo pipefail`.

if (( $# < 1 || $# > 2 )); then
  echo "usage: sops-kube <name> [kubeconfig]" >&2
  exit 1
fi
name=${1%.yaml}

# Read before changing directory, so relative paths still work
if (( $# == 2 )); then
  kubeconfig=$(cat -- "$2")
fi

# sops looks for .sops.yaml from the working directory upwards
cd ~/.nixos-secrets
file=kube/$name.yaml

if [[ -e $file ]]; then
  if [[ -v kubeconfig ]]; then
    echo "$file already exists in ~/.nixos-secrets, edit it with: sops kube $name" >&2
    exit 1
  fi
  exec sops edit "$file"
fi
mkdir -p kube

if [[ -v kubeconfig ]]; then
  # Several contexts keep their names, since there's no telling which cluster and user go together
  kubeconfig=$(name=$name yq '
    with(select((.clusters | length) == 1 and (.users | length) == 1 and (.contexts | length) == 1);
      .clusters[0].name = strenv(name) |
      .users[0].name = strenv(name) |
      .contexts[0].name = strenv(name) |
      .contexts[0].context.cluster = strenv(name) |
      .contexts[0].context.user = strenv(name)
    ) | del(.["current-context"])
  ' <<< "$kubeconfig")
  # shellcheck disable=SC2094  # --filename-override only picks the .sops.yaml rule, $file isn't read
  kubeconfig=$kubeconfig yq -n '.config = strenv(kubeconfig)' | sops encrypt --filename-override "$file" > "$file"
  echo "Contexts: $(yq '[.contexts[].name] | join(" ")' <<< "$kubeconfig")"
else
  # shellcheck disable=SC2094
  sops encrypt --filename-override "$file" > "$file" <<EOF
config: |
  apiVersion: v1
  kind: Config
  clusters:
    - name: $name
      cluster:
        server: https://
        certificate-authority-data:
  users:
    - name: $name
      user:
        token:
  contexts:
    - name: $name
      context:
        cluster: $name
        user: $name
EOF
  # sops only rewrites the file when something was saved, so an untouched template is dropped
  if ! sops edit "$file"; then
    rm "$file"
    exit
  fi
fi

echo "Added ~/.nixos-secrets/$file. Add \"$name\" to kubeconfigs in modules/apps/kubernetes.nix, then run nixos-switch"
