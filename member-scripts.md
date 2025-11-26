## Individual Member Scripts
Scripts and their contents to help make operations more understandable to less-technical users

### create-member-keys.sh
This script will generate an individual members hot key pair for use in the consortium multi-sig script later. Run using `./member-key-gen.sh`
```
MEMBER="name"

cardano-cli conway governance committee key-gen-hot \
    --verification-key-file ${MEMBER}-hot.vkey \
    --signing-key-file ${MEMBER}-hot.skey
```

### get-member-hash.sh
This script will generate and display the key hash for an individual. This must be passed on to whoever is constructing the consortium multi-sig script. Run using `./member-key-hash.sh`
```
MEMBER="name"

cardano-cli conway governance committee key-hash \
  --verification-key-file ${MEMBER}-hot.vkey > ${MEMBER}-hot-key.hash

cat ${MEMBER}-hot-key.hash
```

### member-sign.sh
This script will sign a vote transaction using a members signing key. The witness file must then be passed on to whoever is constructing the final vote file for submission. Run using `./member-sign.sh`
```
MEMBER="name"

cardano-cli conway transaction witness \
  --testnet-magic 4 \
  --tx-body-file vote.raw \
  --signing-key-file ${MEMBER}-hot.skey \
  --out-file ${MEMBER}.witness
```
