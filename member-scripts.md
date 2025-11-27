# Individual Member Scripts
Scripts and their contents to help make operations more understandable to less-technical users

## Committee Setup Keys (cc_cold)
### create_committee_keys.sh
This script will generate an individual members cc_cold key pair for use in the cc_cold script used in the update_committee GA. Run using `./create_committee_keys.sh`

```
MEMBER="name"

cardano-cli conway governance committee key-gen-cold \
    --verification-key-file ${MEMBER}_cold.vkey \
    --signing-key-file ${MEMBER}_cold.skey
```

### get_committee_hash.sh
This script will generate and display the cc_hot key hash for an individual. This must be passed on to whoever is constructing the consortium multi-sig script. Run using `./get_committee_hash.sh`

```
MEMBER="name"

cardano-cli conway governance committee key-hash \
  --verification-key-file ${MEMBER}_cold.vkey > ${MEMBER}_cold_key.hash

cat ${MEMBER}_cold_key.hash
```

## Voter Keys and Actions (cc_hot)
### create_member_keys.sh
This script will generate an individual members cc_hot key pair for use in the consortium multi-sig script later. Run using `./create_member_keys.sh`

```
MEMBER="name"

cardano-cli conway governance committee key-gen-hot \
    --verification-key-file ${MEMBER}_hot.vkey \
    --signing-key-file ${MEMBER}_hot.skey
```

### get_member_hash.sh
This script will generate and display the cc_hot key hash for an individual. This must be passed on to whoever is constructing the consortium multi-sig script. Run using `./get_member_hash.sh`

```
MEMBER="name"

cardano-cli conway governance committee key-hash \
  --verification-key-file ${MEMBER}_hot.vkey > ${MEMBER}_hot_key.hash

cat ${MEMBER}_hot_key.hash
```

### member_sign.sh
This script will sign a vote transaction using a members signing key. The witness file must then be passed on to whoever is constructing the final vote file for submission. Run using `./member_sign.sh`

```
MEMBER="name"

cardano-cli conway transaction witness \
  --testnet-magic 4 \
  --tx-body-file vote.raw \
  --signing-key-file ${MEMBER}_hot.skey \




  --out-file ${MEMBER}.witness
```
