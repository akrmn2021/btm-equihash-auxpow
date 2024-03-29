# btm-equihash-auxpow

This is a bash script (mine-zec-btm.sh) for merge mining Bitmark (the child chain) with Zcash (the parent chain).

Dependencies:

jq (for json parsing in bash)

bitmarkd: https://github.com/akrmn2021/bitmark/tree/master2024 (git clone -b master2024 https://github.com/akrmn2021/bitmark bitmark-ak). Note: You can also use the bitmark code from https://github.com/project-bitmark/bitmark, however this version (master) doesn't seem to compile. You can try checking out the commit from May 2021.

zcashd fork: https://github.com/akrmn2021/zcash/tree/5.7.0 (git clone -b 5.7.0 https://github.com/akrmn2021/zcash zcash-auxpow). This fork adds an "auxpowhash" parameter to getblocktemplate (to insert the BTM block hash into the Zcash coinbase) and makes getblocktemplate output the merkle branch for the coinbase tx (which is needed for submitting the auxpow to Bitmark).

equisolver (only if you are solo merge mining. If you want to use this script in your pool, you need to find a blockheader with the solution for the 140 byte $equihashInput with target $target0. The blockheader with the solution is 140 + 1344 (solution) + 3 (solution size encoding) = 1487 bytes. Whatever program you use for getting this blockheader (forwarding the $equihashInput to miners of the pool), you should replace equisolver with it in the code (or call it equisolver)). The return value of equisolver is the full block header in hex (1487 bytes) together with the sha256d hash of this block header in hex (32 bytes) right after the block header, and a newline character at the end. Make sure your program uses the same return value, so that it's compatible with the script. The nonce is the 32 bytes at the tail of $equihashInput. From my testing, some nonces produced solutions that were not valid according to Zcash. Nonces that have worked have the leading and ending 2 bytes set to 0. The source code for equisolver is available here: https://github.com/akrmn2021/cpuminer-multi. In the README there it says how to compile/setup equihash support.

# Setup

Once you have the dependencies installed, create a zcash.conf in the Zcash datadir and a bitmark.conf in the Bitmark datadir.

**example zcash.conf**
```
listen=1
server=1
rpcuser=zcashrpc
rpcpassword=EtHaVpUk0Djaja8X-k-Y48HR
debug=pow
allowdeprecated=getnewaddress
mineraddress=t1fZknwhPbQAjy3bG9qhWyHKHhRHsjJDPkq
```

If you don't specify the address for receiving mining rewards (mineraddress), an address will be auto generated by zcashd. The current version of zcashd auto generates transaparent addresses for mining (with getblocktemplate). Shielded addresses are not supported for Bitmark merge mining, since the Zcash coinbase transaction size for these addresses exceeds the limit (1000 bytes) set in Bitmark. If you want to create a mineraddress, set allowdeprecated=getnewaddress and use the getnewaddress rpc command of zcash-cli (not z_getnewaccount) (It may ask you to run the zcashd-wallet-tool first, so follow the steps for that). This will return a transparent address you can use for mining. Once you have funds in this address, you can transfer them to shielded address using the zcash-cli z_sendmany command. Use the transparent address as the from address and the shielded one as the to address. The transaction must produce no change, so typically this means you set the value as the block reward minus the fee (the fee is one parameter of z_sendmany). You may also need to set the privacyPolicy parameter of z_sendmany to a non default value such as 'NoPrivacy'. Use zcash-cli help z_sendmany to see the parameters and syntax for the command.

**example bitmark.conf**
```
server=1
listen=1
txindex=1
rpcuser=bitmarkrpc
rpcpassword=z950rTShsosBjFc5zkEwHFNr
```

Now run bitmarkd and zcashd (-daemon option to daemonize), and check that the rpcs are responsive (with e.g. getinfo). Set the correct datadirs for the $bitmarkcli and $zcashcli variables in the script.

Now you are ready to run the script. You can leave it in the background as follows:
nohup ./mine-zec-btm.sh &> mine.log &
Observe the log file (mine.log) to see how things are running. Alternatively, you can use systemd or similar systems to keep the script running. The script is set to exit on any command that it calls that returns an error. Feel free to modify the script to suit your needs.

# Copyleft

This is released to the public domain (CC0).
