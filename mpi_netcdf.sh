#!/bin/bash

# Install NetCDF4 (along with zlib and HDF5 it needs) from the source code
# Originally written by Seb Eastham

curl_version="7.67.0"
zlib_version="1.2.11"
szip_version="2.1.1"
hdf_version="1.10.6"
ncc_version="4.7.3"
ncf_version="4.5.2"
openmpi_version="4.0.4"
cmake_version="3.16.5"
mvapich2_version="2.3.4"

# Initialize our own variables:
install_curl=true
install_zlib=true
install_szip=true
install_hdf5=true
install_ncc=true
install_ncf=true
install_cmake=false
dry_run=false
force_install=false
while getopts "cds:f" opt; do
    case "$opt" in
        d)
            dry_run=true
            ;;
        c)
            install_cmake=true
            ;;
        f)
            force_install=true
            ;;
        s)  skip_list=$OPTARG
            for skip_lib in $(echo $skip_list | sed "s/,/ /g")
            do
               if [[ "$skip_lib" == "curl" ]]; then
                   install_curl=false
               elif [[ "$skip_lib" == "zlib" ]]; then
                   install_zlib=false
               elif [[ "$skip_lib" == "szip" ]]; then
                   install_szip=false
               elif [[ "$skip_lib" == "hdf5" ]]; then
                   install_hdf5=false
               elif [[ "$skip_lib" == "netcdf-c" ]]; then
                   install_ncc=false
               elif [[ "$skip_lib" == "netcdf-fortran" ]]; then
                   install_ncf=false
               elif [[ "$skip_lib" == "cmake" ]]; then
                   install_cmake=false
               else
                   echo "Invalid argument given: $skip_lib"
                   exit 94
               fi
            done
            ;;
    esac
done

if [[ "$force_install" == "false" ]]; then
    ldc=ldconfig
    which $ldc &> /dev/null
    if [[ $? -ne 0 ]]; then
        ls /usr/sbin/ldconfig &> /dev/null
        if [[ $? -ne 0 ]]; then
            echo "Cannot find ldconfig; cannot check for existence of libraries"
            echo "Reverting to user selections"
        else
            ldc=/usr/sbin/ldconfig
        fi
    fi
    # curl
    wc_check=$( $ldc -p | grep "libcurl.so " | wc -l )
    if [[ $wc_check -eq 0 ]]; then
        so4_check=$( ldc -p | grep "libcurl.so.4" )
        if [[ $? -eq 0 ]]; then
            # libcurl exists, but need a softlink to the specific library
            lc_loc=$( echo $so4_check | rev | cut -d" " -f 1 | rev )
            if [[ ! -d $installDir/lib ]]; then
                mkdir $installDir/lib
            fi
            ln -s $lc_loc $installDir/lib
            echo "Found and linked existing curl distribution"
            install_curl=false
        else
            install_curl=true
        fi
    else
        echo "Found existing curl distribution; no link required"
        install_curl=false
    fi
fi

echo "Install curl           :  $install_curl"
echo "Install zlib           :  $install_zlib"
echo "Install szip           :  $install_szip"
echo "Install HDF-5          :  $install_hdf5"
echo "Install NetCDF-C       :  $install_ncc"
echo "Install NetCDF-Fortran :  $install_ncf"
echo "Install CMake          :  $install_cmake"

if [[ "$dry_run" == "true" || ! -d src_all ]]; then
   echo "Setting up source code directory (one-time operation)"
   ./dl_files.sh $curl_version $zlib_version $szip_version $hdf_version $ncc_version $ncf_version $openmpi_version $cmake_version $mvapich2_version
   if [[ $? -ne 0 ]]; then
      echo "Failed to download source files"
      exit 90
   fi
fi

if [[ "$dry_run" == "true" ]]; then
   echo "Source files checked and acquired."
   exit 0
fi

# Check environment variables
if [[ "z$NETCDF_HOME" == "z" ]]; then
   echo "Variable NETCDF_HOME must be defined"
   exit 80
elif [[ "z$NETCDF_FORTRAN_HOME" == "z" ]]; then
   echo "Variable NETCDF_FORTRAN_HOME must be defined"
   exit 80
elif [[ "$NETCDF_HOME" != "$NETCDF_FORTRAN_HOME" ]]; then
   echo "NETCDF_HOME must match NETCDF_FORTRAN_HOME"
   exit 81
fi

if [[ "z$TMPDIR" == "z" ]]; then
    change_dir=y
else
    read -p "Temporary directory will be created in $TMPDIR; would you like to change this? [y/n] " change_dir
fi
if [[ "$change_dir" == "y" ]]; then
   read -p "Please enter target directory for temporary files: " new_tmpdir
   export TMPDIR=$new_tmpdir
   if [[ ! -d $TMPDIR ]]; then
      mkdir $TMPDIR
      if [[ $? -ne 0 ]]; then
         echo "Creation of temporary directory $TMPDIR failed. Aborting"
         exit 95
      fi
   fi
fi

read -p "Force compilers to be MPI wrappers? [y/n] " force_mpi
if [[ "$force_mpi" == "y" ]]; then
   echo "Changing compilers to match standard choices"
   if [[ "$ESMF_COMM" == "intelmpi" ]]; then
      export CC=mpiicc
      export CXX=mpiicpc
      export FC=mpiifort
   else
      export CC=mpicc
      export CXX=mpicxx
      export FC=mpif90
   fi
   export F90=$FC
   export F77=$FC
elif [[ "$force_mpi" == "n" ]]; then
   echo "Compilers will be left as given"
else
   echo "Must give y/n answer"
   exit 70
fi

echo "CC  => " $CC
echo "CXX => " $CXX
echo "FC  => " $FC
echo "F77 => " $F77
echo "F90 => " $F90

if [[ "$CC" != "mpi"* ]]; then
   echo "Need MPI wrappers to compile"
   exit 80
fi

# Set up the compilers
if [[ "x$F90" == "x" ]]; then
    echo "Fortran compilers not fully set up"
    exit 90
fi

if [[ "$MPI_ROOT/bin/mpicc" != $( which mpicc ) ]]; then
   echo "WARNING: which mpicc gives $( which mpicc ) and your MPI root is $MPI_ROOT"
   read -p "Are you sure you wish to proceed? [y/n] " keep_going
   if [[ "$keep_going" != "y" ]]; then
      echo "Aborting"
      exit 95
   fi
fi

# Set up an installation directory
installDir=$NETCDF_HOME
srcDir=$(mktemp -d -t ci-XXXXXXXXXX )
if [[ $? -ne 0 ]]; then
   echo "Failed to generate temporary directory"
   exit 99
fi
echo "Using temporary directory $srcDir"

clobberDir=0
if [[ -d $installDir ]]; then
   echo "WARNING: Installation directory $installDir already exists"
   if [[ $clobberDir -eq 0 ]]; then
      echo "Clobbering disabled. To proceed with the installation, either delete the current installation directory or (UNSAFE) set clobberDir in the installation script to a non-zero value"
      exit 91
   fi
else
   mkdir $installDir
   if [[ $? -ne 0 ]]; then
      echo "Could not make installation directory. Aborting"
      exit 92
   fi
fi

cp -a src_all/* $srcDir/.

if [[ ! -d $srcDir ]]; then
   mkdir $srcDir
fi

# Easiest to install all tools to one directory
export CURLDIR=$installDir
export ZDIR=$installDir
export SZDIR=$installDir
export H5DIR=$installDir
export NCDIR=$installDir
export NFDIR=$installDir

# NOTE: The installation instructions for HDF5 and NetCDF will show only "make check" and "make install", but this can
# sometimes result in failure due to a bad build order. Running "make -> make check -> make install" is slower but safer.
echo " The following packages will be downloaded and installed:"
if [[ "$install_curl" == "true" ]]; then
   echo " curl =============> $CURLDIR"
fi
if [[ "$install_zlib" == "true" ]]; then
   echo " ZLib =============> $ZDIR"
fi
if [[ "$install_szip" == "true" ]]; then
   echo " SZip =============> $SZDIR"
fi
if [[ "$install_hdf5" == "true" ]]; then
   echo " HDF5 =============> $H5DIR"
fi
if [[ "$install_ncc" == "true" ]]; then
   echo " NetCDF-C =========> $NCDIR"
fi
if [[ "$install_ncf" == "true" ]]; then
   echo " NetCDF-Fortran ===> $NFDIR"
fi

# 0. Install curl
if [[ "$install_curl" == "true" ]]; then
   echo "Installing curl to $CURLDIR"
   cd $srcDir
   mkdir -p curl
   cd curl
   dir_name=curl-7.67.0
   cp ../${dir_name}.tar.gz .
   tar -xzf ${dir_name}.tar.gz
   cd ${dir_name}
   ./configure --prefix=${CURLDIR} --without-librtmp
   make
   make test
   make install

   if [[ $? -eq 0 ]]; then
      echo "curl successfully installed"
   else
      echo "Installation failed: curl. Aborting"
      exit 92
   fi
fi

# 1. Install ZLib
if [[ "$install_zlib" == "true" ]]; then
   echo "Installing ZLib to $ZDIR"
   cd $srcDir
   mkdir -p zlib
   cd zlib
   cp ../zlib-${zlib_version}.tar.gz .
   tar -xzf zlib-${zlib_version}.tar.gz
   cd zlib-${zlib_version}
   ./configure --prefix=${ZDIR}
   make
   make check
   make install

   if [[ -e $ZDIR/lib/libz.a ]]; then
      echo "ZLib successfully installed"
   else
      echo "Installation failed: ZLib. Aborting"
      exit 92
   fi
fi

# 1b. Install SZip
if [[ "$install_szip" == "true" ]]; then
   echo "Installing SZip to $SZDIR"
   cd $srcDir
   mkdir szip
   cd szip
   cp ../szip-${szip_version}.tar.gz .
   tar -xzf szip-${szip_version}.tar.gz
   cd szip-${szip_version}
   ./configure --prefix=$SZDIR
   make
   make install
   make check

   if [[ $? -eq 0 ]]; then
      echo "SZip successfully installed"
   else
      echo "Installation failed: SZip. Aborting"
      exit 92
   fi
fi

# 2. Install HDF5
if [[ "$install_hdf5" == "true" ]]; then
   echo "Installing HDF-5 to $H5DIR"
   cd $srcDir
   mkdir -p hdf5
   cd hdf5
   cp ../hdf5-${hdf_version}.tar.gz .
   tar -xzf hdf5-${hdf_version}.tar.gz
   cd hdf5-${hdf_version}
   ./configure --enable-parallel --with-zlib=${ZDIR} --with-szlib=${SZDIR} --prefix=${H5DIR}
   make
   # WARNING: This can sometimes take a VERY long time!
   make check
   make install

   if [[ -e $H5DIR/bin/h5copy ]]; then
      echo "HDF-5 successfully installed"
   else
      echo "Installation failed: HDF-5. Aborting"
      exit 92
   fi
fi

# Add HDF5 libraries to LD_LIBRARY_PATH
export LD_LIBRARY_PATH=${H5DIR}/lib:${LD_LIBRARY_PATH}

# 3. Install NetCDF-C
if [[ "$install_ncc" == "true" ]]; then
   echo "Installing NetCDF-C to $NCDIR"
   cd $srcDir
   mkdir -p netcdf-c
   cd netcdf-c
   if [[ -d netcdf-c-${ncc_version} ]]; then
       rm -rf netcdf-c-${ncc_version}
   fi
   cp ../netcdf-c-${ncc_version}.tar.gz .
   tar -xzf netcdf-c-${ncc_version}.tar.gz
   cd netcdf-c-${ncc_version}
   CPPFLAGS=-I${H5DIR}/include LDFLAGS=-L${H5DIR}/lib ./configure --prefix=${NCDIR}
   make
   make check
   make install

   if [[ -e $NCDIR/bin/nc-config ]]; then
      echo "NetCDF-C ${ncc_version} successfully installed"
   else
      echo "Installation failed: NetCDF-C {ncc_version}. Aborting"
      exit 92
   fi
fi

# 4. Install NetCDF-Fortran
if [[ "$install_ncf" == "true" ]]; then
   echo "Installing NetCDF-Fortran to $NFDIR"
   cd $srcDir
   mkdir -p netcdf-fortran
   cd netcdf-fortran
   cp ../netcdf-fortran-${ncf_version}.tar.gz .
   if [[ -d netcdf-fortran-${ncf_version} ]]; then
       rm -rf netcdf-fortran-${ncf_version}
   fi
   tar -xzf netcdf-fortran-${ncf_version}.tar.gz
   cd netcdf-fortran-${ncf_version}
   CPPFLAGS=-I${NCDIR}/include LDFLAGS=-L${NCDIR}/lib ./configure --prefix=${NFDIR} --disable-dap
   make
   make check
   make install

   if [[ -e $NFDIR/bin/nf-config ]]; then
      echo "NetCDF-Fortran successfully installed"
   else
      echo "Installation failed: NetCDF-Fortran. Aborting"
      exit 92
   fi
fi

# This is a bit too dangerous
#echo "Success. Removing temporary directory"
#rm -rf $srcDir
echo "Success. Left-over files are in $srcDir; suggest user removes them with the command"
echo "rm -rf $srcDir"
echo ""
echo "You have successfully installed NetCDF and all the supporting packages!"
echo "It is STRONGLY RECOMMENDED that you now modify the .bashrc file which  "
echo "you use to run your chosen application to include the following lines: "
echo ""
echo "export NETCDF_HOME=$NETCDF_HOME"
echo "export NETCDF_FORTRAN_HOME=$NETCDF_FORTRAN_HOME"
echo "export PATH=\${NETCDF_HOME}/bin:\$PATH"
echo "export LD_LIBRARY_PATH=\${NETCDF_HOME}/lib:\$LD_LIBRARY_PATH"

exit 0
