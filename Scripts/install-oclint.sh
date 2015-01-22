echo "[*] installing oclint 0.8.1"
pushd .
cd $TMPDIR
curl http://archives.oclint.org/releases/0.8/oclint-0.8.1-x86_64-darwin-14.0.0.tar.gz > oclint.tar.gz
tar -zxvf oclint.tar.gz
cp oclint-0.8.1/bin/oclint* /usr/local/bin/
cp -rp oclint-0.8.1/lib/* /usr/local/lib/
popd
