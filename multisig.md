## Multi-sig Committee Setup

### 1. Steps to create cc_cold_script
a) Generate cc_cold key pairs
Here we will generate cc_cold key pairs for 3 members which will form a simple script that will require 2/3 minimum signers

Alice
```
cardano-cli conway governance committee key-gen-cold \
    --cold-verification-key-file alice_cold.vkey \
    --cold-signing-key-file alice_cold.skey
```
Bob
```
cardano-cli conway governance committee key-gen-cold \
    --cold-verification-key-file bob_cold.vkey \
    --cold-signing-key-file bob_cold.skey
```
Carol
```
cardano-cli conway governance committee key-gen-cold \
    --cold-verification-key-file carol_cold.vkey \
    --cold-signing-key-file carol_cold.skey
```

b) Get hashes to be used for cc_cold_script

Alice
```
cardano-cli conway governance committee key-hash \
    --verification-key-file alice_cold.vkey > alice_cold_key.hash

cat alice_cold_key.hash
8e717ee24b47e6415c737ee0f23efa29c109bb2732703d33f50a987f
```
Bob
```
cardano-cli conway governance committee key-hash \
    --verification-key-file bob_cold.vkey > bob_cold_key.hash

cat bob_cold_key.hash
1b9e69c1548f87d390e3969371ecc65c8a4538a9b982d2a6d907ef5b
```
Carol
```
cardano-cli conway governance committee key-hash \
    --verification-key-file carol_cold.vkey > carol_cold_key.hash

cat carol_cold_key.hash
a3860d4fbeb52380d0495f4481adddb2cd0fc131df025fa564931d07
```

c) Create cc_cold_script using `nano cc_cold_script.json`
```
{
  "type": "atLeast",
  "required": 2,
  "scripts": [
    {
      "type": "sig",
      "keyHash": "8e717ee24b47e6415c737ee0f23efa29c109bb2732703d33f50a987f"
    },
    {
      "type": "sig",
      "keyHash": "1b9e69c1548f87d390e3969371ecc65c8a4538a9b982d2a6d907ef5b"
    },
    {
      "type": "sig",
      "keyHash": "a3860d4fbeb52380d0495f4481adddb2cd0fc131df025fa564931d07"
    }
  ]
}
```

d) Get cc_cold_script hash needed for update_committee action

```
cardano-cli hash script \
  --script-file cc_cold_script.json \
  --out-file cc_cold_script.hash

cat cc_cold_script.hash
6ccdad60157bcd3bc86dc7912dc9cf2ebc906a3f10471c02c310c418
```

### 2. Steps to create cc_hot_script
a) Generate hot key pairs for authorization certificate
Here we will generate 5 cc_hot key pairs for 5 members which will form a simple script that will require 3/5 minimum signers

Alice
```
cardano-cli conway governance committee key-gen-hot \
    --verification-key-file alice_hot.vkey \
    --signing-key-file alice_hot.skey
```
Bob
```
cardano-cli conway governance committee key-gen-hot \
    --verification-key-file bob_hot.vkey \
    --signing-key-file bob_hot.skey
```
Carol
```
cardano-cli conway governance committee key-gen-hot \
    --verification-key-file carol_hot.vkey \
    --signing-key-file carol_hot.skey
```
Dave
```
cardano-cli conway governance committee key-gen-hot \
    --verification-key-file dave_hot.vkey \
    --signing-key-file dave_hot.skey
```
Enid
```
cardano-cli conway governance committee key-gen-hot \
    --verification-key-file enid_hot.vkey \
    --signing-key-file enid_hot.skey
```

b) Get cc_hot key hashes to be used in the cc_hot_script

Alice
```
cardano-cli conway governance committee key-hash \
  --verification-key-file alice_hot.vkey > alice_hot_key.hash

cat alice_hot_key.hash
1caa1d77f8a8ab55fcdd32b2433526e7f33584413ee98fa117e388e0
```
Bob
```
cardano-cli conway governance committee key-hash \
  --verification-key-file bob_hot.vkey > bob_hot_key.hash

cat member2_hot_key.hash
c255f4ad9ed6df1def8257938d97be530c466aef72815e3b5790403d
```
Carol
```
cardano-cli conway governance committee key-hash \
 --verification-key-file carol_hot.vkey > carol_hot_key.hash

cat member3_hot_key.hash
4d2d93ca7448d965f453ab3c9df32cf22fbdd20d622a2ee3732c35a5
```
Dave
```
cardano-cli conway governance committee key-hash \
--verification-key-file dave_hot.vkey > dave_hot_key.hash

cat dave_hot_key.hash
4ce8eadad19309decc382b6a825ed6b782b1b60b9b42b9495c22227b
```
Enid
```
cardano-cli conway governance committee key-hash \
 --verification-key-file enid_hot.vkey > enid_hot_key.hash

cat enid_hot_key.hash
cc03821f6995cd81fb3711d847871aaa95edaff86ec40f197737227e
```

c) Create cc_hot_script `nano cc_hot_script.json`

```
{
  "type": "atLeast",
  "required": 3,
  "scripts": [
    {
      "type": "sig",
      "keyHash": "1caa1d77f8a8ab55fcdd32b2433526e7f33584413ee98fa117e388e0"
    },
    {
      "type": "sig",
      "keyHash": "c255f4ad9ed6df1def8257938d97be530c466aef72815e3b5790403d"
    },
    {
      "type": "sig",
      "keyHash": "4d2d93ca7448d965f453ab3c9df32cf22fbdd20d622a2ee3732c35a5"
    },
    {
      "type": "sig",
      "keyHash": "4ce8eadad19309decc382b6a825ed6b782b1b60b9b42b9495c22227b"
    },
    {
      "type": "sig",
      "keyHash": "cc03821f6995cd81fb3711d847871aaa95edaff86ec40f197737227e"
    }
  ]
}
```

d) Get cc_hot_script hash needed for authorization certificate

```
cardano-cli hash script \
  --script-file cc_hot_script.json \
  --out-file cc_hot_script.hash

cat cc_hot_script.hash
ea0631ffd1964bc72584566f517cb0e8035630287c53ebe6ac8a1e51
```

### 3. Steps to create and submit the authorization certificate.
a) Generate cc_hot_script_authorization certificate. This will authorize the (5) voting keys for the committee seat.

```
cardano-cli conway governance committee create-hot-key-authorization-certificate \
    --cold-script-hash 6ccdad60157bcd3bc86dc7912dc9cf2ebc906a3f10471c02c310c418 \
    --hot-script-hash ea0631ffd1964bc72584566f517cb0e8035630287c53ebe6ac8a1e51 \
    --out-file cc_hot_script_authorization.cert
```

b) Build the registration transaction

```
cardano-cli conway transaction build \
  --testnet-magic 4 \
  --tx-in "$(cardano-cli query utxo --address "$(cat payment.addr)" --testnet-magic 4 --out-file /dev/stdout | jq -r 'keys[0]')" \
  --change-address $(cat payment.addr) \
  --certificate-file cc_hot_script_authorization.cert \
  --witness-override 4 \
  --out-file tx.raw
```

c) Gather witness signatures

```
cardano-cli conway transaction witness \
  --testnet-magic 4 \
  --tx-body-file tx.raw \
  --signing-key-file payment.skey \
  --out-file payment.witness

cardano-cli conway transaction witness \
  --testnet-magic 4 \
  --tx-body-file tx.raw \
  --signing-key-file alice_cold.skey \
  --out-file alice_cold.witness

cardano-cli conway transaction witness \
  --testnet-magic 4 \
  --tx-body-file tx.raw \
  --signing-key-file bob_cold.skey \
  --out-file bob_cold.witness

cardano-cli conway transaction witness \
  --testnet-magic 4 \
  --tx-body-file tx.raw \
  --signing-key-file carol_cold.skey \
  --out-file carol_cold.witness
```

d) Assemble the transaction witnesses

```
cardano-cli conway transaction assemble \
  --tx-body-file tx.raw \
  --witness-file  payment.witness \
  --witness-file  alice_cold.witness \
  --witness-file  bob_cold.witness \
  --witness-file  carol_cold.witness \
  --out-file tx.signed
```

e) Submit the transaction

```
cardano-cli conway transaction submit \
  --testnet-magic 4 \
  --tx-file tx.signed
```
