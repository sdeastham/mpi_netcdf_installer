# mpi_netcdf_installer
Scripts to download and install all the libraries needed for NetCDF

You will need the following environment variables:
* `NETCDF_HOME`: This is where the bin, include, and lib folders will be installed. It must NOT already exist
* `NETCDF_FORTRAN_HOME`: This must be the same as `$NETCDF_HOME`
* `CC`: A working C compiler
* `FC`: A working Fortran compiler
* `CXX`: A working C++ compiler

If you already have a working MPI simulation, then you can skip Step 2, but you must also have the following
environment variables set:

* `MPI_ROOT`: The root directory for your MPI installation (i.e. `$MPI_ROOT/bin/mpicc` should exist)

## Installation:

There are three steps. Steps 2a and 2b are for systems where you do not yet have a working MPI installation.
Step 3 then handles the actual installation of NetCDF. If you already have a working MPI installation, you can
skip straight to Step 3.

### Step 1: Downloading the source files

If you do not already have the directory "src_all" in this directory, run

`./mpi_netcdf.sh -d`

This will download the necessary source files into the directory "src_all".
Use this if you need to run the installer on a node which does not have
access to the internet.

### Step 2: Installing an MPI implementation

If the user does NOT have a working MPI installation, this package comes with some (albeit only lightly-tested) scripts
which can attempt to do so for them. This comes in two steps. The first is to install the OpenUCX communication framework,
which replaced the "openib" transport layer in OpenMPI v4+.

#### Step 2a: Installing OpenUCX v1.6.1

As long as your compilers are correctly set up in the environment (ie "`CC=gcc`" or "`CC=icc`" and so on), you can start the
OpenUCX build process by running

`./ucx_build.sh /path/to/target/dir`

with your desired target directory inserted as required. Note that this will download and install OpenUCX v1.6.1; at time
of writing (2019-11-25), there was a bug preventing OpenMPI v4.x.x from compiling with OpenUCX v1.7. This is however
expected to be fixed soon.

Once OpenUCX is installed, be sure to modify you `PATH` and `LD_LIBRARY_PATH` variables as suggested (and to do so in the
bashrc file you will be using to build and run your MPI applications).

#### Step 2b: Installing OpenMPI v4.x.x

At this point, you must have the following additional environment variables set up:

* `MPI_ROOT`: This is equivalent to your MPI "prefix" and must point to where you want your bin, include, and lib directories

You should also check that the command "`ucx_info`" works from anywhere. Otherwise, you only need your compiler environment
variables defined (`CC`, `FC`, `CXX`). Now, run

`./openmpi_build.sh`

This should automatically install OpenMPI v4.x.x to the `MPI_ROOT` directory.

### Step 3: Installing NetCDF

#### Standard installation

In theory, NetCDF can be installed immediately, simply by running:

`./mpi_netcdf.sh`

Select "`y`" for "Force MPI compilers", and provide a workable temporary directory (e.g. `$HOME/tmp`) when requested.
Otherwise just follow the on-screen prompts. The installer will take the following steps:

 * Check which libraries are already installed (currently only curl is checked)
 * Install each of the following in order, if not found:
    * curl
    * zlib
    * szip
    * HDF-5
    * NetCDF-C
    * NetCDF-Fortran

Note: this process can take a while! If successful, this will end with a message recommending changes to your
`PATH` and `LD_LIBRARY_PATH`, as well as a message about how to remove the temporary directory which was used to
build the source code.

#### Advanced options

The user can choose to avoid installing one or more of the libraries above with the argument "`-s`" ("skip"). For
example, if the user has a functioning copy of the curl and zlib libraries on their `LD_LIBRARY_PATH`, they can
invoke the build process with

`./mpi_netcdf -s curl,zlib`

The argument to "-s" must be a comma-seperated list, made up of the values below:

* curl            : curl
* zlib            : zlib
* szip            : szip
* hdf             : HDF-5
* netcdf-c        : NetCDF-C
* netcdf-fortran  : NetCDF-Fortran

Note that, for curl, this should not be necessary - presence of the curl library should be automatically detected.
The user can also choose to skip automatic library detection by providing the "`-f`" ("force") argument. Combining
these two arguments enables the user to force the installation of any combination of arguments.
