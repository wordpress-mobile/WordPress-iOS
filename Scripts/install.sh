#!/bin/sh

#set -x

function step() {
  msg=$1
  shift
  [ -z $TRAVIS ] || echo "travis_fold:start:${msg}"
  $@
  [ -z $TRAVIS ] || echo "travis_fold:end:${msg}"
}

function bundle_install() {
  echo "Install bundler dependencies"

  # Check if we need to run bundle install
  if [[ -f Gemfile.lock && -f vendor/bundle/Manifest.lock ]] && cmp --silent Gemfile.lock vendor/bundle/Manifest.lock; then
    echo "Gems seem up to date, skipping bundle install"
  else
    bundle install --jobs=3 --retry=3 --path=${BUNDLE_PATH:-vendor/bundle}
    cp Gemfile.lock vendor/bundle/Manifest.lock
  fi
}

function pod_install() {
  echo "Install Cocoapods dependencies"
  POD="bundle exec pod"

  # Output Cocoapods version
  echo "pod --version"
  $POD --version

  # Check if we need to run pod install
  if [[ -f Podfile.lock && -f Pods/Manifest.lock ]] && cmp --silent Podfile.lock Pods/Manifest.lock; then
    echo "Pods seem up to date, skipping pod install"
  else
    echo "pod repo update"
    $POD repo update

    echo "pod install"
    $POD install
  fi
}

step "install.bundler" bundle_install
step "install.cocoapods" pod_install

