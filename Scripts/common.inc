SWIFTLINT_VERSION="0.10.0"

SCRIPTS_DIR=$( dirname $0 )
PROJECT_DIR=$( cd "${SCRIPTS_DIR}/../"; pwd )
SWIFTLINT_PREFIX="${PROJECT_DIR}/build-tools/swiftlint"
SWIFTLINT="${SWIFTLINT_PREFIX}/bin/swiftlint"

function swiftlint_installed() {
  if [ -f "$SWIFTLINT" ];then
    return 0
  else
    return 1
  fi
}

function swiftlint_is_current() {
  if [ `$SWIFTLINT version` == $SWIFTLINT_VERSION ];then
    return 0
  else
    return 1
  fi
}

function swiftlint_needs_install() {
  if $(swiftlint_installed && swiftlint_is_current);then
    return 1
  else
    return 0
  fi
}
