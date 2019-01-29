# This is kind of naughty, I know,
# but we need to know what will the state be once RxSwift is deployed.

set -e

BRANCH=$(git rev-parse HEAD)
ESCAPED_SOURCE=$(pwd | sed -E "s/\//\\\\\//g")

function cleanup {
  pushd ~/.cocoapods/repos/master
  git clean -d -f
  git reset master --hard
  popd
}

trap cleanup EXIT

if [[ ! -z "${TRAVIS}" ]]; then
    gem install cocoapods --pre --no-rdoc --no-ri --no-document --quiet;
    pod repo update;
fi;

VERSION=`cat RxSwift.podspec | grep -E "s.version\s+=" | cut -d '"' -f 2`
ROOTS=(2/e/c 3/c/1 8/5/5 f/7/9 a/b/1)
ALL_TARGETS=(RxTest RxCocoa RxBlocking RxAtomic RxSwift)

SWIFT_VERSION=''

if [ ! -z "$TARGET" ]
then
    TARGETS=("$TARGET")
else
    TARGETS="${ALL_TARGETS}"
fi

if [ ! -z "$SWIFT_VERSION" ]
then
    SWIFT_VERSION="--swift-version=${SWIFT_VERSION}"
fi

pushd ~/.cocoapods/repos/master/Specs
for TARGET in ${ALL_TARGETS[@]}
do
  mkdir -p ${TARGET}/${VERSION}
done
popd

for TARGET in ${ALL_TARGETS[@]}
do
    for ROOT in ${ROOTS[@]} ; do
        mkdir -p ~/.cocoapods/repos/master/Specs/${ROOT}/${TARGET}/${VERSION}
        rm       ~/.cocoapods/repos/master/Specs/${ROOT}/${TARGET}/${VERSION}/* || echo
        cat $TARGET.podspec |
        sed -E "s/s.source [^\}]+\}/s.source           = { :git => 'file:\/\/${ESCAPED_SOURCE}' }/" > ~/.cocoapods/repos/master/Specs/${ROOT}/${TARGET}/${VERSION}/${TARGET}.podspec
    done
done

function validate() {
    local PODSPEC=$1

    pod lib lint $PODSPEC --verbose --no-clean --allow-warnings "${SWIFT_VERSION}"
}

for TARGET in ${TARGETS[@]}
do
    validate ${TARGET}.podspec
done
