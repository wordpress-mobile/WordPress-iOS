echo "[*] installing oclint 0.8.1"
pushd .
cd ${temp_dir}
curl http://archives.oclint.org/releases/0.8/oclint-0.8.1-x86_64-darwin-14.0.0.tar.gz > oclint.tar.gz
tar -zxvf oclint.tar.gz
OCLINT_HOME=${temp_dir}/oclint-0.8.1
export PATH=$OCLINT_HOME/bin:$PATH
popd
