#!/usr/bin/env bash
# ============ BEGIN BUILD SCRIPT =======================================
# Script created by Rich Cook at LLNl
set -xv
OPENMPI_PKG=openmpi-gnu-1.4.3
MPI_PATH=/usr/local/tools/$OPENMPI_PKG

LINKER_FLAGS="  -Wl,-rpath,"'$ORIGIN:$ORIGIN/../lib'":${MPI_PATH}/lib"

CMAKE_SPECIAL_ARGS=" -DCMAKE_VERBOSE_MAKEFILE:BOOL=TRUE  -DCMAKE_CXX_COMPILER:FILEPATH=${MPI_PATH}/bin/mpiCC  -DCMAKE_C_COMPILER:FILEPATH=${MPI_PATH}/bin/mpicc   -DPARAVIEW_USE_MPI:BOOL=ON  -DMPI_LIBRARY:FILEPATH=${MPI_PATH}/lib/libmpi.so;${MPI_PATH}/lib/libmpi_cxx.so;${MPI_PATH}/lib/libopen-rte.so;${MPI_PATH}/lib/libopen-pal.so   -DPARAVIEW_USE_MPI_SSEND:BOOL=ON  -DMPIEXEC:FILEPATH=${MPI_PATH}/bin/mpirun  -DCMAKE_Fortran_COMPILER:FILEPATH=${MPI_PATH}/bin/mpif90 -DMPI_Fortran_COMPILER:FILEPATH=${MPI_PATH}/bin/mpif90 -DMPI_Fortran_LIBRARIES:FILEPATH=${MPI_PATH}/lib/libmpi_f90.so -DMPI_Fortran_INCLUDE_PATH:FILEPATH=${MPI_PATH}/include -DMPI_COMPILER:FILEPATH=${MPI_PATH}/bin/mpiCC -DCMAKE_CXX_FLAGS:STRING=\"-I${MPI_PATH}/include\" -DCMAKE_C_FLAGS:STRING=\"-I${MPI_PATH}/include\""

if [ ! -d ParaViewCatalystExampleCode ]; then 
    git clone https://github.com/Kitware/ParaViewCatalystExampleCode.git
fi
builddir=CatalystExample-build
rm -rf $builddir
mkdir $builddir
pushd $builddir
cmake $CMAKE_SPECIAL_ARGS\
    -DCMAKE_PREFIX_PATH=/usr/local/tools/paraview-osmesa-mpi-4.3.1/src/ParaView-v4.3.1-Build/ \
     ../ParaViewCatalystExampleCode/ 
 

make -j
popd

echo "Build completed successfully!"
echo "To run, you might need to prepend ${MPI_PATH}/lib to your LD_LIBRARY_PATH"

# ============ END BUILD SCRIPT =======================================
