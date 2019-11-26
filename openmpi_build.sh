#!/bin/bash

if [[ "x$MPI_ROOT" == "x" ]]; then
   echo "MPI_ROOT not defined"
   exit 70
fi

if [[ -e $MPI_ROOT/bin/mpicc ]]; then
   echo "MPI compilers already exist"
   exit 71
fi

which ucx_info &> /dev/null
if [[ $? -ne 0 ]]; then
    echo "UCX not found. OpenMPI will be installed without it!"
    ucx_opt=""
else
    UCX_DIR=$( readlink -f $( dirname $( which ucx_info ) )/.. )
    ucx_opt="--with-ucx=$UCX_DIR"
fi

srcDir=$(mktemp -d -t ci-XXXXXXXXXX --tmpdir=/home/seastham/tmp)
if [[ ! -d $srcDir ]]; then
   echo "Source dir $srcDir does not exist"
   exit 90
fi

echo "Using temporary directory $srcDir"
cp -a src_all/* $srcDir/.

for sub_dir in $MPI_ROOT; do
   mkdir $sub_dir
   rc=$?
   if [[ $rc -ne 0 ]]; then
      echo "Return code $rc given when making $sub_dir"
      exit 90
   fi
done

OMPI_DIR=openmpi-4.0.2
cd $srcDir
tar -xzf ${OMPI_DIR}.tar.gz
cd $OMPI_DIR
#./configure --prefix=$MPI_ROOT --with-verbs
./configure --prefix=$MPI_ROOT --without-verbs $ucx_opt
rc=$?
if [[ $rc -ne 0 ]]; then
   echo "Configure failed"
   exit $rc
fi
for mk_cmd in "make" "make install" "make check"; do
   $mk_cmd
   if [[ $rc -ne 0 ]]; then
      echo "Make command failed: $mk_cmd"
      exit $rc
   fi
done

echo "Install complete"
exit 0
