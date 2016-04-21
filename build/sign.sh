#!/bin/bash
#
# Copyright (c) 2015, Alban Bedel <alban.bedel@avionic-design.de>
#
# This program is free software; you can redistribute it and/or modify it
# under the terms and conditions of the GNU General Public License,
# version 2, as published by the Free Software Foundation.
#
# This program is distributed in the hope it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# See file CREDITS for list of people who contributed to this
# project.
#
set -e

CBOOTIMAGE=cbootimage
BCT_DUMP=bct_dump
OBJCOPY=objcopy
OPENSSL=openssl
DD=dd
RM=rm
MV=mv
XXD=xxd
CUT=cut

TMPDIR=

cleanup() {
    [ -n "$TMPDIR" ] && rm -rf "$TMPDIR"
}

bct_param() {
    $BCT_DUMP $IMAGE_FILE | grep -e "^\(# \)\?$1 *=" | sed 's,.*= *,,; s, *;$,,'
}

trap cleanup EXIT TERM INT QUIT

TMPDIR=`mktemp -d`

SOC=$1
IMAGE_FILE=$2
KEY_FILE=$3
TARGET_IMAGE=$4

if [ -z "$SOC" -o ! -f "$IMAGE_FILE" -o ! -f "$KEY_FILE" ] ; then
    echo "Usage: $0 SOC IMAGE KEY [OUTPUT]"
    exit 1
fi

[ -z "$TARGET_IMAGE" ] && TARGET_IMAGE=$IMAGE_FILE.signed

CONFIG_FILE=$TMPDIR/$IMAGE_FILE.cfg
TMP_IMAGE=$TMPDIR/$IMAGE_FILE

echo "Get BCT parameters"

BLOCK_SIZE=$(bct_param BlockSize)
PAGE_SIZE=$(bct_param PageSize)
CRYPTO_OFFSET=$(bct_param 'Crypto offset')
CRYPTO_LENGTH=$(bct_param 'Crypto length')
BL_COUNT=$(bct_param 'Bootloader used')

# Sign the bootloader

BL_START_BLOCK=$(bct_param "Bootloader\[0\]\.Start block")
BL_START_PAGE=$(bct_param "Bootloader\[0\]\.Start page")
BL_LENGTH=$(bct_param "Bootloader\[0\]\.Length")
BL_OFFSET=$((BLOCK_SIZE * BL_START_BLOCK + PAGE_SIZE * BL_START_PAGE))

echo "Extract bootloader to $IMAGE_FILE.bl.tosig, offset $BL_OFFSET, length $BL_LENGTH"
$DD bs=1 skip=$BL_OFFSET count=$BL_LENGTH \
    if=$IMAGE_FILE of=$TMP_IMAGE.bl.tosig 2> /dev/null

echo "Calculate rsa signature for bootloader and save to $IMAGE_FILE.bl.sig"
$OPENSSL dgst -sha256 -sigopt rsa_padding_mode:pss -sigopt rsa_pss_saltlen:-1 \
    -sign $KEY_FILE -out $TMP_IMAGE.bl.sig $TMP_IMAGE.bl.tosig

echo "Update bootloader's rsa signature, aes hash and bct's aes hash"
echo "RsaPssSigBlFile = $TMP_IMAGE.bl.sig;" > $CONFIG_FILE
echo "RehashBl;" >> $CONFIG_FILE
$CBOOTIMAGE -$SOC -u $CONFIG_FILE $IMAGE_FILE $TMP_IMAGE

# Sign the BCT

echo "Extract the part of bct which needs to be rsa signed"
$DD bs=1 skip=$CRYPTO_OFFSET count=$CRYPTO_LENGTH \
    if=$TMP_IMAGE of=$TMP_IMAGE.bct.tosig 2> /dev/null

echo "Calculate rsa signature for BCT and save to $IMAGE_FILE.bct.sig"
$OPENSSL dgst -sha256 -sigopt rsa_padding_mode:pss -sigopt rsa_pss_saltlen:-1 \
    -sign $KEY_FILE -out $TMP_IMAGE.bct.sig $TMP_IMAGE.bct.tosig

echo "Create public key modulus from key file $KEY_FILE and save to $KEY_FILE.mod"
$OPENSSL rsa -in $KEY_FILE -noout -modulus | $CUT -d= -f2 | \
    $XXD -r -p -l 256 > $TMPDIR/$(basename $KEY_FILE).mod

echo "Update bct's rsa signature and modulus"
echo "RsaPssSigBctFile = $TMP_IMAGE.bct.sig;" > $CONFIG_FILE
echo "RsaKeyModulusFile = $TMPDIR/$(basename $KEY_FILE).mod;" >> $CONFIG_FILE
$CBOOTIMAGE -$SOC -u $CONFIG_FILE $TMP_IMAGE $TARGET_IMAGE
