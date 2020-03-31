#!/bin/bash

ucx_version=1.6.1

if [[ $# -ne 1 ]]; then
    echo "Need path for UCX install!"
    exit 80
fi
if [[ "$CC" == *"mpi"* ]]; then
    echo "Installers must not be MPI-wrapped"
    exit 85
fi
which ucx_info &> /dev/null
if [[ $? -eq 0 ]]; then
    echo "UCX installation already exists: $( which ucx_info )"
    exit 85
fi

echo "NOTE: The following option is thought to be required on the svante nodes. Unknown for other systems"
read -p "Install UCX with support for mlx5 hardware? This requires mlx5-dev libraries [y/n] " do_mlx5
if [[ "$do_mlx5" == "y" ]]; then
    echo "MLX5 support will be installed."
    mlx5_opt="--with-mlx5-dv"
elif [[ "$do_mlx5" == "n" ]]; then
    echo "MLX5 support not chosen."
    mlx5_opt=""
else
    echo "Invalid option. Aborting"
    exit 77
fi

if [[ "z$TMPDIR" == "z" ]]; then
    echo "TMPDIR not set"
    kp_tmp=n
else
    read -p "TMPDIR is $TMPDIR. Use this for temporary files? [y/n] " kp_tmp
fi
if [[ "$kp_tmp" == "n" ]]; then
    read -p "Please provide a new location for temporary files: " new_tmp
    export TMPDIR=$new_tmp
elif [[ "$kp_tmp" == "y" ]]; then
    echo "$TMPDIR will be used for temporary files"
else
    echo "Invalid response"
    exit 78
fi

if [[ ! -d $TMPDIR ]]; then
    mkdir $TMPDIR
    if [[ $? -ne 0 ]]; then
        echo "Could not create temporary output directory"
        exit 64
    fi
fi

srcDir=$(mktemp -d -t ci-XXXXXXXXXX)
if [[ ! -d $srcDir ]]; then
   echo "Source dir $srcDir does not exist"
   exit 90
fi

echo "Using temporary directory $srcDir"
cd $srcDir
wget -nd https://github.com/openucx/ucx/releases/download/v${ucx_version}/ucx-${ucx_version}.tar.gz
tar -xzf ucx-${ucx_version}.tar.gz
cd ucx-${ucx_version}
# NOTE: MOST USERS WILL NOT WANT THE MLX5 OPTION!

echo "CC is $CC"
echo "CXX is $CXX"
echo "FC is $FC"
./configure --prefix=$1 --enable-mt $mlx5_opt
if [[ $? -ne 0 ]]; then
    echo "Configure failed"
    exit 95
fi
for mk_cmd in make "make install"; do
    $mk_cmd
    if [[ $? -ne 0 ]]; then
        echo "Command failed: $mk_cmd"
        exit 94
    fi
done

echo "Installation succeeded"
echo "Add the following lines to your environment file:"
echo "export PATH=$1/bin:\$PATH"
echo "export LD_LIBRARY_PATH=$1/lib:\$LD_LIBRARY_PATH"
echo ""
echo "To clear temporary files, run:"
echo "rm -rf $srcDir"
exit 0
