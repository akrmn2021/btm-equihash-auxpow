# btm-equihash-auxpow

This is a bash script (mine-zec-btm.sh) for merge mining Bitmark (the child chain) with Zcash (the parent chain).

Dependencies:

jq (for json parsing in bash)

bitmarkd: https://github.com/akrmn2021/bitmark/tree/0.9.7.4 (git clone -b 0.9.7.4 https://github.com/akrmn2021/bitmark bitmark-ak). Note: You can also use the bitmark code from https://github.com/project-bitmark/bitmark, however this version (master) doesn't seem to compile on Ubuntu 22. You can try checking out the commit from May 2021.

zcashd fork: https://github.com/akrmn2021/zcash/tree/5.7.0 (git clone -b 5.7.0 https://github.com/akrmn2021/zcash zcash-auxpow)

equisolver (only if you are solo merge mining. If you want to use this script in your pool, you need to find a blockheader with the solution for the 140 byte $equihashInput with target $target0. The blockheader with the solution is 140 + 1344 (solution) + 3 (solution size encoding) = 1487 bytes. Whatever program you use for getting this blockheader (forwarding the $equihashInput to miners of the pool), you should replace equisolver with it in the code (or call it equisolver)). The source code for equisolver is available here: https://github.com/akrmn2021/cpuminer-multi. In the README there it says how to compile/setup equihash support.

# Setup

Once you have the dependencies setup, run bitmarkd and zcashd, and check that the rpcs are responsive (with e.g. getinfo). Set the correct datadirs for the $bitmarkcli and $zcashcli variables in the script.

Now you are ready to run the script. You can leave it in the background as follows:
nohup ./mine-zec-btm.sh &> mine.log &
Observe the log file (mine.log) to see how things are running. Alternatively, you can use systemd or similar systems to keep the script running. The script is set to exit on any command that it calls that returns an error. Feel free to modify the script to suit your needs.

# Copyleft

This is released to the public domain (CC0).
