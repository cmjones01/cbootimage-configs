#!/bin/sh

# Copyright (c) 2013, NVIDIA CORPORATION.  All rights reserved.
#
# This software is provided 'as-is', without any express or implied
# warranty. In no event will the authors be held liable for any damages
# arising from the use of this software.
#
# Permission is granted to anyone to use this software for any purpose,
# including commercial applications, and to alter it and redistribute it
# freely, subject to the following restrictions:
#
# 1. The origin of this software must not be misrepresented; you must not
#    claim that you wrote the original software. If you use this software
#    in a product, an acknowledgment in the product documentation would be
#    appreciated but is not required.
# 2. Altered source versions must be plainly marked as such, and must not be
#    misrepresented as being the original software.
# 3. This notice may not be removed or altered from any source distribution.

set -e
set -x

cbootimage -t114 -gbct \
    E1611_Hynix_2GB_H5TC4G63AFR-RDA_792MHz_r403_v03.bct.cfg \
    E1611_Hynix_2GB_H5TC4G63AFR-RDA_792MHz_r403_v03.bct
cbootimage -t114 dalmore-t40x-1866.img.cfg dalmore-t40x-1866.img

cbootimage -t114 -gbct \
    E1611_Hynix_2GB_H5TC4G63AFR-RDA_792Mhz_r403_v2.bct.cfg \
    E1611_Hynix_2GB_H5TC4G63AFR-RDA_792Mhz_r403_v2.bct
cbootimage -t114 dalmore-t40s-1866.img.cfg dalmore-t40s-1866.img

cbootimage -t114 -gbct \
    E1611_Hynix_2GB_H5TC4G63MFR-PBA_792Mhz_r403_v05.bct.cfg \
    E1611_Hynix_2GB_H5TC4G63MFR-PBA_792Mhz_r403_v05.bct
cbootimage -t114 dalmore-t40s-1600.img.cfg dalmore-t40s-1600.img