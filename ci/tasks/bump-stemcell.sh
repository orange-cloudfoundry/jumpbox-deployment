#!/usr/bin/env bash

set -euo pipefail

function bump_stemcell() {
  local iaas=${1}
  local task_dir="${2}"
  local stemcell_sha
  local stemcell_url

  echo "Bumping ${iaas} stemcell..."

  stemcell_sha="$(cat "${task_dir}/stemcell-${iaas}/sha1")"
  stemcell_url="$(cat "${task_dir}/stemcell-${iaas}/url")"

  cat > /tmp/bump-stemcell-ops.yml <<EOF
---
- type: replace
  path: /path=~1resource_pools~1name=vms~1stemcell??/value
  value:
    url: ${stemcell_url}
    sha1: ${stemcell_sha}
EOF

  bosh interpolate -o /tmp/bump-stemcell-ops.yml \
    "${iaas}/cpi.yml" > /tmp/cpi.yml

  mv /tmp/cpi.yml "${iaas}/cpi.yml"
  git diff "${iaas}/cpi.yml"
}

function main() {
  local iaas_list=(aws azure gcp openstack vsphere)
  local task_dir="${1}"

  pushd jumpbox-deployment
    for iaas in "${iaas_list[@]}"; do
      bump_stemcell "${iaas}" "${task_dir}"
      echo
    done

    git config user.email "cf-infrastructure@pivotal.io"
    git config user.name "cf-infra-bot"

    git add .
    git commit -m "Bump stemcells to $(cat "${task_dir}/stemcell-aws/version")"
  popd

  cp -R jumpbox-deployment/. updated-jumpbox-deployment
}

main "${PWD}"
