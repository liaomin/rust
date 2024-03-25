#!/usr/bin/env bash
#
# Patches the SPL crates for developing against a local solana monorepo
#

solana_dir=$1
if [[ -z $solana_dir ]]; then
  echo "Usage: $0 <path-to-solana-monorepo>"
  exit 1
fi

workspace_crates=(
  Cargo.toml
)

if [[ ! -r "$solana_dir"/scripts/read-cargo-variable.sh ]]; then
  echo "$solana_dir is not a path to the solana monorepo"
  exit 1
fi

set -e

solana_dir=$(cd "$solana_dir" && pwd)
cd "$(dirname "$0")"
project_root=$(pwd)

source "$solana_dir"/scripts/read-cargo-variable.sh

# The toolchain file only exists in version >= 1.15
toolchain_file="$solana_dir"/rust-toolchain.toml
if [[ -f "$toolchain_file" ]]; then
  cp "$toolchain_file" .
fi

# only add exclude rule when solana root is under spl root
if echo "$solana_dir" | grep "^$project_root" > /dev/null; then
  echo "Excluding $solana_dir from workspace"
  echo
  for crate in "${workspace_crates[@]}"; do
    if grep -q "exclude.*$solana_dir" "$crate"; then
      echo "$crate is already patched"
    else
      sed -i'' "$crate" -e "/exclude/a \ \ \"$solana_dir\","
    fi
  done
fi

# get version from Cargo.toml first. if it is empty, get it from other places.
solana_ver="$(readCargoVariable version "$solana_dir"/Cargo.toml)"
solana_ver=${solana_ver:-$(readCargoVariable version "$solana_dir"/sdk/Cargo.toml)}

crates_map=()
crates_map+=("solana-account-decoder account-decoder")
crates_map+=("solana-banks-client banks-client")
crates_map+=("solana-banks-interface banks-interface")
crates_map+=("solana-banks-server banks-server")
crates_map+=("solana-bloom bloom")
crates_map+=("solana-bucket-map bucket_map")
crates_map+=("solana-clap-utils clap-utils")
crates_map+=("solana-clap-v3-utils clap-v3-utils")
crates_map+=("solana-cli-config cli-config")
crates_map+=("solana-cli-output cli-output")
crates_map+=("solana-client client")
crates_map+=("solana-connection-cache connection-cache")
crates_map+=("solana-core core")
crates_map+=("solana-entry entry")
crates_map+=("solana-faucet faucet")
crates_map+=("solana-frozen-abi frozen-abi")
crates_map+=("solana-frozen-abi-macro frozen-abi/macro")
crates_map+=("solana-geyser-plugin-interface geyser-plugin-interface")
crates_map+=("solana-geyser-plugin-manager geyser-plugin-manager")
crates_map+=("solana-gossip gossip")
crates_map+=("solana-ledger ledger")
crates_map+=("solana-logger logger")
crates_map+=("solana-measure measure")
crates_map+=("solana-merkle-tree merkle-tree")
crates_map+=("solana-metrics metrics")
crates_map+=("solana-net-utils net-utils")
crates_map+=("solana-perf perf")
crates_map+=("solana-poh poh")
crates_map+=("solana-program-runtime program-runtime")
crates_map+=("solana-program-test program-test")
crates_map+=("solana-address-lookup-table-program programs/address-lookup-table")
crates_map+=("solana-bpf-loader-program programs/bpf_loader")
crates_map+=("solana-compute-budget-program programs/compute-budget")
crates_map+=("solana-config-program programs/config")
crates_map+=("solana-stake-program programs/stake")
crates_map+=("solana-vote-program programs/vote")
crates_map+=("solana-zk-token-proof-program programs/zk-token-proof")
crates_map+=("solana-pubsub-client pubsub-client")
crates_map+=("solana-quic-client quic-client")
crates_map+=("solana-rayon-threadlimit rayon-threadlimit")
crates_map+=("solana-remote-wallet remote-wallet")
crates_map+=("solana-rpc rpc")
crates_map+=("solana-rpc-client rpc-client")
crates_map+=("solana-rpc-client-api rpc-client-api")
crates_map+=("solana-rpc-client-nonce-utils rpc-client-nonce-utils")
crates_map+=("solana-runtime runtime")
crates_map+=("solana-sdk sdk")
crates_map+=("solana-sdk-macro sdk/macro")
crates_map+=("solana-program sdk/program")
crates_map+=("solana-send-transaction-service send-transaction-service")
crates_map+=("solana-storage-bigtable storage-bigtable")
crates_map+=("solana-storage-proto storage-proto")
crates_map+=("solana-streamer streamer")
crates_map+=("solana-test-validator test-validator")
crates_map+=("solana-thin-client thin-client")
crates_map+=("solana-tpu-client tpu-client")
crates_map+=("solana-transaction-status transaction-status")
crates_map+=("solana-udp-client udp-client")
crates_map+=("solana-version version")
crates_map+=("solana-zk-token-sdk zk-token-sdk")

patch_crates=()
for map_entry in "${crates_map[@]}"; do
  read -r crate_name crate_path <<<"$map_entry"
  full_path="$solana_dir/$crate_path"
  if [[ -r "$full_path/Cargo.toml" ]]; then
    patch_crates+=("$crate_name = { path = \"$full_path\" }")
  fi
done

echo "Patching in $solana_ver from $solana_dir"
echo
for crate in "${workspace_crates[@]}"; do
  if grep -q "# The following entries are auto-generated by $0" "$crate"; then
    echo "$crate is already patched"
  else
    if ! grep -q '\[patch.crates-io\]' "$crate"; then
      echo "[patch.crates-io]" >> "$crate"
    fi
    cat >> "$crate" <<PATCH
# The following entries are auto-generated by $0
$(printf "%s\n" "${patch_crates[@]}")
PATCH
  fi
done

./update-solana-dependencies.sh "$solana_ver"
