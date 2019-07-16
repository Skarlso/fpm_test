#!/bin/bash
set -euo pipefail

main() {
  local name='fpm-test'

  local root_dir
  root_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"

  bundle install --quiet --path vendor/bundle

  cd "$( dirname "${BASH_SOURCE[0]}" )"

  local src_dir="${root_dir}/build"

  rm -fr "${src_dir}"
  mkdir -p "${src_dir}/opt/fpm-test"

  cp -a -L "${root_dir}/bin" "${src_dir}/opt/fpm-test/"
  cp -a -L "${root_dir}/lib" "${src_dir}/opt/fpm-test/"
  # cp -a "${root_dir}/debian/etc" "${src_dir}/"
  # cp -a "${root_dir}/debian/lib" "${src_dir}/"
  # cp -a "${root_dir}/debian/usr" "${src_dir}/"

  version="1.0.0"
  echo "${version}" > "${src_dir}/opt/fpm-test/lib/version"

  mkdir -p "${src_dir}/usr/bin"

  local chmod=chmod
  if command -v gchmod >/dev/null ; then
    chmod=gchmod
  fi

  build_ruby "$src_dir"

  # Remove permissions from other by default.
  ${chmod} -R o-Xrw "${src_dir}/opt/fpm-test"
  ${chmod} o+X "${src_dir}/opt/fpm-test" "${src_dir}/opt/fpm-test/bin"

  # Remove the previous build
  rm -fr "fpm-test_${version}_amd64.deb"

  bundle exec fpm \
    --name "${name}" \
    --input-type dir \
    --output-type deb \
    --version "1.0.1" \
    --chdir "${src_dir}" \
    --after-install "${root_dir}/debian/after-install.sh" \
    --after-upgrade "${root_dir}/debian/after-upgrade.sh" \
    --after-remove "${root_dir}/debian/after-remove.sh" \
    --no-deb-systemd-restart-after-upgrade \
    --license 'Proprietary' \
    --vendor 'Me.' \
    --maintainer 'me@me.com' \
    --architecture 'amd64' \
    --description 'To Test OSX bulids.'
}

build_ruby() {
  local src_dir="$1"
  (
    cd ..
    rm -rf fpm-test.dir
    mkdir -p fpm-test.dir/opt/fpm-test/bin
    (
      cd fpm-test.dir/opt/fpm-test/bin
      ln -s ../../../../lib/* .
    )
    rsync -a fpm-test.dir/ "$src_dir/"
  )
}

main
