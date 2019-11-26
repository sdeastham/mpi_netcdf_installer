#!/bin/bash

# Downloads source code for all packages needed to install NetCDF
# Originally written by Seb Eastham

if [[ $# -lt 6 ]]; then
   echo "Need 6 arguments (curl version, zlib version, szip version, hdf version, NetCDF-C version, and NetCDF-Fortran version. If a 7th argument is given, that version of OpenMPI will be downloaded"
   exit 70
fi

curl_version=$1
zlib_version=$2
szip_version=$3
hdf_version=$4
ncc_version=$5
ncf_version=$6
if [[ $# -ge 7 ]]; then
   openmpi_version=$7
else
   openmpi_version=NO_MPI
fi

if [[ ! -d src_all ]]; then
   mkdir src_all
fi

cd src_all

dir_name=curl-${curl_version}
web_address="https://curl.haxx.se/download/${dir_name}.tar.gz"
wget -c -nd $web_address
if [[ $? -ne 0 ]]; then
   echo "Failed to download curl"
   exit 80
fi

dir_name=zlib-${zlib_version}
web_address="http://www.zlib.net/${dir_name}.tar.gz"
wget -c -nd $web_address
if [[ $? -ne 0 ]]; then
   echo "Failed to download zlib"
   exit 80
fi


dir_name=szip-${szip_version}
web_address="https://support.hdfgroup.org/ftp/lib-external/szip/2.1.1/src/${dir_name}.tar.gz"
wget -c -nd $web_address
if [[ $? -ne 0 ]]; then
   echo "Failed to download SZip"
   exit 80
fi

dir_name="hdf5-${hdf_version}"
web_address="https://support.hdfgroup.org/ftp/HDF5/prev-releases/hdf5-1.8/${dir_name}/src/${dir_name}.tar.gz"
wget -c -nd $web_address
if [[ $? -ne 0 ]]; then
   echo "Failed to download HDF-5"
   exit 80
fi

web_address="ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-c-${ncc_version}.tar.gz"
wget -c -nd $web_address
if [[ $? -ne 0 ]]; then
   echo "Failed to download NetCDF-C"
   exit 80
fi

web_address="ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-fortran-${ncf_version}.tar.gz"
wget -c -nd $web_address
if [[ $? -ne 0 ]]; then
   echo "Failed to download NetCDF-Fortran"
   exit 80
fi

if [[ "$openmpi_version" == "NO_MPI" ]]; then
   echo "Skipping OpenMPI (no version given)"
else
   sub_version="${openmpi_version%.*}"
   web_address="https://download.open-mpi.org/release/open-mpi/v${sub_version}/openmpi-${openmpi_version}.tar.gz"
   wget -c -nd $web_address
   if [[ $? -ne 0 ]]; then
      echo "Failed to download NetCDF-Fortran"
      exit 80
   fi
fi

exit 0
