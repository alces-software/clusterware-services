#!/bin/bash
#==============================================================================
# Copyright (C) 2015 Stephen F. Norledge and Alces Software Ltd.
#
# This file/package is part of Alces Clusterware.
#
# Alces Clusterware is free software: you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# Alces Clusterware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this package.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Clusterware, please visit:
# https://github.com/alces-software/clusterware
#==============================================================================
curl -L "http://downloads.sourceforge.net/project/samtools/samtools/0.1.19/samtools-0.1.19.tar.bz2" -o /tmp/samtools-0.1.19.tar.bz2
tar -C /tmp -xjf /tmp/samtools-0.1.19.tar.bz2

SAMTOOLSDIR="${SERVICEDIR}/samtools"

pushd /tmp/samtools-0.1.19
sed -i -e 's|^CFLAGS=.*|CFLAGS= -g -Wall -O2 -fPIC|g' Makefile
make
mkdir -p "${SAMTOOLSDIR}"/doc "${SAMTOOLSDIR}"/bin
cp -v AUTHORS COPYING NEWS "${SAMTOOLSDIR}"/doc
chmod a+r "${SAMTOOLSDIR}"/doc/*
cp -v samtools bcftools/bcftools "${SAMTOOLSDIR}"/bin
chmod a+rx "${SAMTOOLSDIR}"/bin/*
popd

rm -rf /tmp/samtools-0.1.19 /tmp/samtools-0.1.19.tar.bz2
