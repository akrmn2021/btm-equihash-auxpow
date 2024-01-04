#!/bin/bash

set -e

bitmarkcli="bitmark-cli -datadir=/home/coins/.bitmark"
zcashcli="zcash-cli -datadir=/home/coins/.zcash"

while true
do
    $bitmarkcli setminingalgo 6
    auxblock=`$bitmarkcli getauxblock`
    echo "auxblock = $auxblock"
    btmHashBlock=`echo "$auxblock" | jq .hash | sed 's/"//g'`
    echo "btmHashBlock = $btmHashBlock"
    btmchainid=91
    echo "btmchainid = $btmchainid"
    targetBTM=`echo "$auxblock" | jq .target | sed 's/"//g'`
    blocktemplate=`$zcashcli getblocktemplate '{"auxpowhash":"'$btmHashBlock'"}'`
    #echo "(zcash) blocktemplate = $blocktemplate"
    nVersionInt=`echo "$blocktemplate" | jq .version`
    #echo "nVersionInt = $nVersionInt"
    nVersion=`printf "%08x" "$nVersionInt" | tail -c 8 | fold -w2 | tac | tr -d '\n'`
    echo "nVersion = $nVersion"
    hashPrevBlock=`echo "$blocktemplate" | jq .previousblockhash | sed 's/"//g' | fold -w2 | tac | tr -d '\n'`
    echo "hashPrevBlock = $hashPrevBlock"
    hashMerkleRoot=`echo "$blocktemplate" | jq .defaultroots | jq .merkleroot | sed 's/"//g' | fold -w2 | tac | tr -d '\n'`
    echo "hashMerkleRoot = $hashMerkleRoot"
    hashBlockCommitments=`echo "$blocktemplate" | jq .blockcommitmentshash | sed 's/"//g' | fold -w2 | tac | tr -d '\n'`
    echo "hashBlockCommitments = $hashBlockCommitments"
    mintime=`echo "$blocktemplate" | jq .mintime`
    time=`date +%s`
    if [ "$time" -lt "$mintime" ]
    then
	time="$mintime"
    fi
    nTime=`printf "%08x" "$time" | fold -w2 | tac | tr -d '\n'`
    #echo "time = $time"
    echo "nTime = $nTime"
    nBits=`echo "$blocktemplate" | jq .bits | sed 's/"//g' | fold -w2 | tac | tr -d '\n'`
    echo "nBits = $nBits"
    nNonce="0000"`hexdump -vn28 -e'7/4 "%08x" 1 "\n"' /dev/urandom`"0000"
    echo "nNonce = $nNonce"
    equihashInput="$nVersion$hashPrevBlock$hashMerkleRoot$hashBlockCommitments$nTime$nBits$nNonce"
    equihashInputLen=${#equihashInput}
    equihashInputLenBytes="$((equihashInputLen / 2))"
    echo "equihashInput ($equihashInputLenBytes bytes) = $equihashInput"
    targetZEC=`echo "$blocktemplate" | jq .target | sed 's/"//g' | fold -w2 | tac | tr -d '\n'`
    echo "targetBTM = $targetBTM"
    echo "targetZEC = $targetZEC"
    target0="" # the easier target
    target1=""
    for (( i=62; i>=0; i-=2 ))
    do
	targetBTMi=`printf "%u" 0x"${targetBTM:$i:2}"`
	targetZECi=`printf "%u" 0x"${targetZEC:$i:2}"`
	if [ "$targetBTMi" -gt "$targetZECi" ]
	then
	    target0="$targetBTM"
	    target1="$targetZEC"
	    break
	elif [ "$targetBTMi" -lt "$targetZECi" ]
	then
	    target0="$targetZEC"
	    target1="$targetBTM"
	    break
	fi
    done
    echo "target0 = $target0"
    echo "target1 = $target1"
    coinbaseTx=`echo "$blocktemplate" | jq .coinbasetxn | jq .data | sed 's/"//g' | tr -d '\n'`
    coinbaseTxLen="${#coinbaseTx}"
    coinbaseTxLenBytes="$((coinbaseTxLen / 2))"
    echo "coinbaseTx ($coinbaseTxLenBytes bytes) = $coinbaseTx"
    vMerkleBranch=`echo "$blocktemplate" | jq .coinbasetxn | jq .vmerklebranch | sed 's/"//g' | tr -d '\n'`
    vMerkleBranchLen="${#vMerkleBranch}"
    echo "vMerkleBranch (len $vMerkleBranchLen) = $vMerkleBranch"
    transactions=`echo "$blocktemplate" | jq '.transactions'`
    transactionsLen="${#transactions}"
    transactionsHex=""
    ntx=1
    if [ "$transactionsLen" -gt 2 ]
    then
	echo "transactions = $transactions"
	let ntx=ntx+`echo $transactions | jq length`
	transactionsHex=`echo "$transactions" | jq '.[].data' | sed 's/"//g' | while read -r data; do echo -n "$data"; done`
    fi
    ntxHex=""
    if [ "$ntx" -lt 253 ]
    then
	ntxHex=`printf "%02x" "$ntx"`
    elif [ "$ntx" -lt 65536 ]
    then
	ntxHex="fd"`printf "%04x" "$ntx" | fold -w2 | tac | tr -d '\n'`
    else
	ntxHex="fe"`printf "%08x" "$ntx" | fold -w2 | tac | tr -d '\n'`
    fi
    vtx="$ntxHex$coinbaseTx$transactionsHex"
    #echo "vtx = $vtx"
    echo "run equisolver $equihashInput $target0"
    equisolverout=`equisolver "$equihashInput" "$target0" | tr -d '\n'`
    equisolveroutLen=${#equisolverout}
    echo "equisolveroutLen = $equisolveroutLen"
    if [ "$equisolveroutLen" -gt 100 ]
    then
	#echo "equisolverout = $equisolverout"
	zecHeader="${equisolverout:0:2974}"
	#echo "zecHeader = $zecHeader"
	zecHeaderHash="${equisolverout:2974:64}"
	echo "zecHeaderHash = $zecHeaderHash"
	target1Solved=0
	for (( i=62; i>=0; i-=2 ))
	do
	    zecHeaderHashi=`printf "%u" 0x"${zecHeaderHash:$i:2}"`
	    target1i=`printf "%u" 0x"${target1:$i:2}"`
	    if [ "$zecHeaderHashi" -gt "$target1i" ]
	    then
		break
	    elif [ "$zecHeaderHashi" -lt "$target1i" ]
	    then
		target1Solved=1
		break
	    fi
	done
	submitBTM=0
	submitZEC=0
	if [[ "$target0" == "$targetBTM" ]]
	then
	    submitBTM=1
	    if [[ "$target1Solved" == "1" ]]
	    then
		submitZEC=1
	    fi
	else
	    submitZEC=1
	    if [[ "$target1Solved" == "1" ]]
	    then
	       submitBTM=1
	    fi	       
	fi
	if [[ "$submitBTM" == 1 ]]
	then
	    coinbaseTxLenHex=""
	    if [ "$coinbaseTxLenBytes" -lt 253 ]
	    then
		coinbaseTxLenHex=`printf "%02x" "$coinbaseTxLenBytes"`
	    elif [ "$coinbaseTxLenBytes" -lt 1001 ]
	    then
		coinbaseTxLenHex="fd"`printf "%04x" "$coinbaseTxLen" | fold -w2 | tac | tr -d '\n'`
	    else
		echo "Zcash coinbase tx too large (not submitting auxpow to Bitmark). Ensure you are mining Zcash with a transparent address."
		submitBTM=0
	    fi
	    if [[ "$submitBTM" == 1 ]]
	    then
		nIndex=00000000
		vChainMerkleBranch=00
		nChainIndex=00000000
		auxpow="$coinbaseTxLenHex$coinbaseTx$zecHeaderHash$vMerkleBranch$nIndex$vChainMerkleBranch$nChainIndex$zecHeader"
		echo "auxpow = $auxpow"
		printf "(%s) Submitting auxpow to Bitmark\n" "`date`"
		$bitmarkcli getauxblock "$btmHashBlock" "$auxpow"
	    fi
	fi
	if [[ "$submitZEC" == 1 ]]
	then
	    zecBlock="$zecHeader$vtx"
	    printf "(%s) Submitting block to Zcash\n" "`date`"
	    $zcashcli submitblock "$zecBlock"
	fi
    fi
done
