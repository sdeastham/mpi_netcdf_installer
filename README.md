# mpi_netcdf_installer
Scripts to download and install all the libraries needed for NetCDF

You will need:
 - A working MPI installation (e.g. OpenMPI v4.0.1)
 - The following environment variables:
 -- $NETCDF_HOME: This is where the bin, include, and lib folders will be installed. It must NOT already exist
 -- $NETCDF_FORTRAN_HOME: This must be the same as $NETCDF_HOME
 -- $CC: A working C compiler
 -- $FC: A working Fortran compiler
 -- $CXX: A working C++ compiler

First-time setup:

./mpi_netcdf.sh dl_only

This will download the necessary source files into the directory "src_all".
Use this if you need to run the installer on a node which does not have
access to the internet.

Installation:

./mpi_netcdf.sh
