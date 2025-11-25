## Multi-sig Committee Setup

1. Generate Committee member cold key pair
```
cardano-cli conway governance committee key-gen-cold \
    --cold-verification-key-file committee-cold.vkey \
    --cold-signing-key-file committee-cold.skey
```

2. Get cold key hash
```
cardano-cli conway governance committee key-hash \
    --verification-key-file committee-cold.vkey > committee-key.hash

cat committee-key.hash
8e717ee24b47e6415c737ee0f23efa29c109bb2732703d33f50a987f
```

### Multi-sig Steps
3. Generate hot key pairs for authorization certificate
```
cardano-cli conway governance committee key-gen-hot \
    --verification-key-file member1-hot.vkey \
    --signing-key-file member1-hot.skey

cardano-cli conway governance committee key-gen-hot \
    --verification-key-file member2-hot.vkey \
    --signing-key-file member2-hot.skey

cardano-cli conway governance committee key-gen-hot \
    --verification-key-file member3-hot.vkey \
    --signing-key-file member3-hot.skey

cardano-cli conway governance committee key-gen-hot \
    --verification-key-file member4-hot.vkey \
    --signing-key-file member4-hot.skey

cardano-cli conway governance committee key-gen-hot \
    --verification-key-file member5-hot.vkey \
    --signing-key-file member5-hot.skey
```

4. Get hot key hashes for the script
```
cardano-cli conway governance committee key-hash \
  --verification-key-file member1-hot.vkey > member1-hot-key.hash

cat member1-hot-key.hash
1caa1d77f8a8ab55fcdd32b2433526e7f33584413ee98fa117e388e0

cardano-cli conway governance committee key-hash \
  --verification-key-file member2-hot.vkey > member2-hot-key.hash

cat member2-hot-key.hash
c255f4ad9ed6df1def8257938d97be530c466aef72815e3b5790403d

cardano-cli conway governance committee key-hash \
 --verification-key-file member3-hot.vkey > member3-hot-key.hash

cat member3-hot-key.hash
4d2d93ca7448d965f453ab3c9df32cf22fbdd20d622a2ee3732c35a5

cardano-cli conway governance committee key-hash \
--verification-key-file member4-hot.vkey > member4-hot-key.hash

cat member4-hot-key.hash
4ce8eadad19309decc382b6a825ed6b782b1b60b9b42b9495c22227b

cardano-cli conway governance committee key-hash \
 --verification-key-file member5-hot.vkey > member5-hot-key.hash

cat member5-hot-key.hash
cc03821f6995cd81fb3711d847871aaa95edaff86ec40f197737227e
```

5. Create native script `nano committee-multisig.json`
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

6. Get script hash
```
cardano-cli hash script \
  --script-file committee-multisig.json \
  --out-file committee-multisig.id

cat committee-multisig.id
ea0631ffd1964bc72584566f517cb0e8035630287c53ebe6ac8a1e51
```

9. Generate authorization certificate
```
cardano-cli conway governance committee create-hot-key-authorization-certificate \
    --cold-verification-key-file committee-cold.vkey \
    --hot-script-hash ea0631ffd1964bc72584566f517cb0e8035630287c53ebe6ac8a1e51 \
    --out-file committee-hot-script-authorization.cert
```

10. Build registration transaction
```
cardano-cli conway transaction build \
  --testnet-magic 4 \
  --tx-in "$(cardano-cli query utxo --address "$(cat payment.addr)" --testnet-magic 4 --out-file /dev/stdout | jq -r 'keys[0]')" \
  --change-address $(cat payment.addr) \
  --certificate-file committee-hot-script-authorization.cert \
  --witness-override 6 \
  --out-file tx.raw
```

11. Gather witness signatures
```
cardano-cli conway transaction witness \
  --testnet-magic 4 \
  --tx-body-file tx.raw \
  --signing-key-file payment.skey \
  --out-file payment.witness

cardano-cli conway transaction witness \
  --testnet-magic 4 \
  --tx-body-file tx.raw \
  --signing-key-file member1-hot.skey \
  --out-file member1.witness

cardano-cli conway transaction witness \
  --testnet-magic 4 \
  --tx-body-file tx.raw \
  --signing-key-file member2-hot.skey \
  --out-file member2.witness

cardano-cli conway transaction witness \
  --testnet-magic 4 \
  --tx-body-file tx.raw \
  --signing-key-file member3-hot.skey \
  --out-file member.witness

cardano-cli conway transaction witness \
  --testnet-magic 4 \
  --tx-body-file tx.raw \
  --signing-key-file member4-hot.skey \
  --out-file member4.witness

cardano-cli conway transaction witness \
  --testnet-magic 4 \
  --tx-body-file tx.raw \
  --signing-key-file member5-hot.skey \
  --out-file member5.witness
```

12. Assemble the transaction witnesses
```
cardano-cli conway transaction assemble \
  --tx-body-file tx.raw \
  --witness-file  payment.witness \
  --witness-file  member1.witness \
  --witness-file  member2.witness \
  --witness-file  member3.witness \
  --witness-file  member4.witness \
  --witness-file  member5.witness \
  --out-file tx.signed
```

13. Submit the transaction
```
cardano-cli conway transaction submit \
  --testnet-magic 4 \
  --tx-file tx.signed
```
