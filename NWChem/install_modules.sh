#!/bin/bash
set -eo pipefail

export INSTALL_LOC="${INSTALL_LOC:-/home/q/Documents/Computations/modules}"
export INSTALL_NWCHEM="${INSTALL_NWCHEM:-/home/q/Documents/notes/IGCAR/DTDS/AbInitio}"

##############################################
# Helper — Append PATH and LD paths safely
# will not append duplicates
##############################################
append_to_bashrc () {
    local name="$1"
    local prefix="$2"
    local marker="# ===== $name ====="

    # create .bashrc if missing
    [ ! -f "$HOME/.bashrc" ] && touch "$HOME/.bashrc"

    if grep -Fq "$marker" "$HOME/.bashrc"; then
        echo "~/.bashrc already contains entry for $name — skipping append."
        return 0
    fi

    echo "Updating ~/.bashrc for $name ..."
    {
        echo ""
        echo "$marker"
        echo "export PATH=\"$prefix/bin:\$PATH\""
        echo "export LD_LIBRARY_PATH=\"$prefix/lib:\$LD_LIBRARY_PATH\""
        echo "export CPATH=\"$prefix/include:\$CPATH\""
        echo "export LIBRARY_PATH=\"$prefix/lib:\$LIBRARY_PATH\""
    } >> "$HOME/.bashrc"
}

##############################################
# safe_install helper
# Usage:
#   safe_install "Human Name" "$PREFIX" "cd somedir && ./configure ... && make && make install"
# On success -> append_to_bashrc is executed.
# On failure -> prints error and returns non-zero; script continues to next package.
##############################################
safe_install () {
    local name="$1"; shift
    local prefix="$1"; shift
    local cmd="$*"

    echo "================ Installing: $name ================"
    echo "Install prefix: $prefix"
    echo "Running: $cmd"

    # run the command in a subshell so we can ensure working directory cleanup inside the command string
    if bash -c "$cmd"; then
        echo "$name: build/install succeeded."
        append_to_bashrc "$name" "$prefix" || {
            echo "Warning: failed to append $name to ~/.bashrc (non-fatal)."
        }
        return 0
    else
        echo "ERROR: $name installation FAILED — not modifying ~/.bashrc"
        return 1
    fi
}

##############################################
# Package installation functions
# These prepare the source dir, set PREFIX, then call safe_install with the
# exact build steps as a single command string.
##############################################

install_openmpi () {
    FILE="openmpi-5.0.9.tar.gz"
    PREFIX="$INSTALL_LOC/openmpi/5.0.9"

    [ ! -f "$FILE" ] && { echo "$FILE not found! Skipping OpenMPI."; return 1; }

    tar -xf "$FILE"
    cd openmpi-5.0.9 || return 1

    # build+install in one line for safe_install
    safe_install "OpenMPI 5.0.9" "$PREFIX" \
" \
./configure FC=gfortran-10 F77=gfortran-10 CC=gcc-10 CXX=g++ --prefix='$PREFIX' --enable-mpirun-prefix-by-default \
&& make -j'$(nproc)' \
&& make install -j'$(nproc)' \
"

    cd .. || true
    rm -rf openmpi-5.0.9
}

install_boost () {
    VERSION="1_89_0"
    FOLDER="boost_${VERSION//./_}"
    FILENAME="${FOLDER}.tar.gz"
    PREFIX="$INSTALL_LOC/Boost/$VERSION"

    [ ! -f "$FILENAME" ] && { echo "$FILENAME not found! Skipping Boost."; return 1; }

    tar -xf "$FILENAME"
    cd "$FOLDER" || return 1

    # create user-config.jam and use mpicxx/mpicc via environment
    safe_install "Boost $VERSION (MPI)" "$PREFIX" \
" \
export CC=mpicc && export CXX=mpicxx && echo 'using mpi ;' > tools/build/src/user-config.jam \
&& ./bootstrap.sh --prefix='$PREFIX' --with-toolset=gcc \
&& ./b2 install -j'$(nproc)' --prefix='$PREFIX' --with-mpi --with-serialization toolset=gcc \
"

    cd .. || true
    rm -rf "$FOLDER"
}

install_fftw () {
    FILE="fftw-3.3.10.tar.gz"
    PREFIX="$INSTALL_LOC/fftw/3.3.10"

    [ ! -f "$FILE" ] && { echo "$FILE not found! Skipping FFTW."; return 1; }

    tar -xf "$FILE"
    cd fftw-3.3.10 || return 1

    safe_install "FFTW 3.3.10 (MPI)" "$PREFIX" \
" \
./configure --prefix='$PREFIX' --enable-shared --enable-mpi CC=mpicc \
&& make -j'$(nproc)' \
&& make install -j'$(nproc)' \
"

    cd .. || true
    rm -rf fftw-3.3.10
}

install_openblas () {
    FILE="OpenBLAS-0.3.30.tar.gz"
    PREFIX="$INSTALL_LOC/OpenBLAS/0.3.30"

    [ ! -f "$FILE" ] && { echo "$FILE not found! Skipping OpenBLAS."; return 1; }

    tar -xf "$FILE"
    cd OpenBLAS-0.3.30 || return 1

    safe_install "OpenBLAS 0.3.30" "$PREFIX" \
" \
make -j'$(nproc)' \
&& make PREFIX='$PREFIX' install \
"

    cd .. || true
    rm -rf OpenBLAS-0.3.30
}

install_lapack () {
    FILE="lapack-3.12.1.tar.gz"
    PREFIX="$INSTALL_LOC/LAPACK/3.12.1"

    [ ! -f "$FILE" ] && { echo "$FILE not found! Skipping LAPACK."; return 1; }

    tar -xf "$FILE"
    cd lapack-3.12.1 || return 1
    mkdir -p build && cd build || return 1

    safe_install "LAPACK 3.12.1" "$PREFIX" \
" \
cmake -DCMAKE_Fortran_COMPILER=mpif90 -DCMAKE_INSTALL_PREFIX='$PREFIX' -DCMAKE_BUILD_TYPE=Release .. \
&& make -j'$(nproc)' \
&& make install -j'$(nproc)' \
"

    cd ../.. || true
    rm -rf lapack-3.12.1
}

install_scalapack () {
    FILE="scalapack-2.2.2.tar.gz"
    PREFIX="$INSTALL_LOC/scalapack/2.2.2"

    [ ! -f "$FILE" ] && { echo "$FILE not found! Skipping Scalapack."; return 1; }

    tar -xf "$FILE"
    cd scalapack-2.2.2 || return 1
    mkdir -p build && cd build || return 1

    safe_install "Scalapack 2.2.2 (MPI)" "$PREFIX" \
" \
cmake .. -DCMAKE_Fortran_COMPILER=mpif90 -DCMAKE_INSTALL_PREFIX='$PREFIX' -DCMAKE_BUILD_TYPE=Release \
 -DBLAS_LIBRARIES='$INSTALL_LOC/OpenBLAS/0.3.30/lib/libopenblas.a' \
 -DLAPACK_LIBRARIES='$INSTALL_LOC/LAPACK/3.12.1/lib/liblapack.a' \
 -DCMAKE_Fortran_COMPILER=mpif90 -DCMAKE_C_COMPILER=mpicc \
&& make -j'$(nproc)' \
&& make install \
"

    cd ../.. || true
    rm -rf scalapack-2.2.2
}

install_hdf5 () {
    FILE="hdf5_1.14.6.tar.gz"
    PREFIX="$INSTALL_LOC/HDF5/1.14.6"

    [ ! -f "$FILE" ] && { echo "$FILE not found! Skipping HDF5."; return 1; }

    tar -xf "$FILE"
    cd hdf5-hdf5_1.14.6 || return 1

    safe_install "HDF5 1.14.6 (Parallel)" "$PREFIX" \
" \
./configure --prefix='$PREFIX' --enable-parallel --enable-fortran CC=mpicc FC=mpif90 \
&& make -j'$(nproc)' \
&& make install -j'$(nproc)' \
"

    cd .. || true
    rm -rf hdf5-hdf5_1.14.6
}

install_libint () {
    FILE="libint-2.11.2.tar.gz"
    PREFIX="$INSTALL_LOC/libint/2.11.2"

    [ ! -f "$FILE" ] && { echo "$FILE not found! Skipping Libint."; return 1; }

    tar -xf "$FILE"
    cd libint-2.11.2 || return 1
    mkdir -p build && cd build || return 1

    safe_install "Libint 2.11.2" "$PREFIX" \
" \
cmake .. -DCMAKE_INSTALL_PREFIX='$PREFIX' -DBUILD_SHARED_LIBS=ON -DENABLE_FORTRAN=ON -DENABLE_MPI=ON -DUSE_MPI=ON \
 -DCMAKE_C_COMPILER=mpicc -DCMAKE_CXX_COMPILER=mpicxx -DCMAKE_Fortran_COMPILER=mpif90 \
&& make -j'$(nproc)' \
&& make install \
"

    cd ../.. || true
    rm -rf libint-2.11.2
}

install_libxc () {
    FILE="libxc-7.0.0.tar.bz2"
    PREFIX="$INSTALL_LOC/libxc/7.0.0"

    [ ! -f "$FILE" ] && { echo "$FILE not found! Skipping libxc."; return 1; }

    tar -xf "$FILE"
    mv libxc-7.0.0 libxc-build
    cd libxc-build || return 1

    safe_install "libxc 7.0.0" "$PREFIX" \
" \
cmake -S . -B build -DCMAKE_Fortran_COMPILER=mpif90 -DCMAKE_INSTALL_PREFIX='$PREFIX' -DENABLE_FORTRAN=ON -DBUILD_SHARED_LIBS=ON \
&& cmake --build build -j'$(nproc)' \
&& cmake --install build \
"

    cd .. || true
    rm -rf libxc-build
}

install_json () {
    FILE="json-3.12.0.tar.gz"
    PREFIX="$INSTALL_LOC/json/3.12.0"

    [ ! -f "$FILE" ] && { echo "$FILE not found! Skipping nlohmann JSON."; return 1; }

    tar -xf "$FILE"
    mv json-3.12.0 json-build
    cd json-build || return 1

    safe_install "nlohmann JSON 3.12.0" "$PREFIX" \
" \
mkdir -p build && cmake -S . -B build -DCMAKE_INSTALL_PREFIX='$PREFIX' \
&& cmake --build build -j'$(nproc)' \
&& cmake --install build \
"

    cd .. || true
    rm -rf json-build
}

# -------------------------------------------------------------
# Install Wannier90
# -------------------------------------------------------------
install_wannier90() {
    NAME="wannier90"
    VERSION="3.1.0"
    PREFIX="$INSTALL_LOC/wannier90/$VERSION"
    SRC="$INSTALL_LOC/wannier90-develop"
    
    echo "=== Installing $NAME $VERSION ==="

    mkdir -p "$PREFIX"
    cd "$SRC" || return 1

    mkdir -p build
    cd build || return 1

    safe_install "$NAME" "$PREFIX" \
        cmake .. \
            -DCMAKE_INSTALL_PREFIX="$PREFIX" \
            -DCMAKE_Fortran_COMPILER=mpif90 \
            -DCMAKE_C_COMPILER=mpicc \
            -DCMAKE_BUILD_TYPE=Release \
        && make -j"$(nproc)" \
        && make install
}


install_nwchem () {
    VER="7.2.0"
    FILE="nwchem-${VER}.tar.gz"
    PREFIX="$INSTALL_NWCHEM/NWChem/${VER}"
    mkdir -p ${INSTALL_NWCHEM}/NWChem/ && cd ${INSTALL_NWCHEM}/NWChem/
    
    [ ! -f $FILE ] && { wget "https://github.com/nwchemgit/nwchem/archive/refs/tags/v${VER}-release.tar.gz" -O "${FILE}";}
    [ ! -d "$INSTALL_LOC/openmpi/5.0.9" ] && { echo "OpenMPI 5.0.9 not installed! Skipping NWChem."; return 1; }
    [ ! -d "$INSTALL_LOC/OpenBLAS/0.3.30" ] && { echo "OpenBLAS 0.3.30 not installed! Skipping NWChem."; return 1; }
    [ ! -d "$INSTALL_LOC/LAPACK/3.12.1" ] && { echo "LAPACK 3.12.1 not installed! Skipping NWChem."; return 1; }
    [ ! -d "$INSTALL_LOC/scalapack/2.2.2" ] && { echo "ScaLAPACK 2.2.2 not installed! Skipping NWChem."; return 1; }
    [ ! -f "${FILE}" ] && { echo "${FILE} not found! Download failed."; return 1; }

    tar -xf "${FILE}" && mv 'nwchem-7.2.0-release' $VER
    [ ! -d "${PREFIX}/src" ] && { echo "Extraction failed - no src dir."; return 1; }
    cd "${PREFIX}" || return 1


safe_install "NWChem $VER" "$PREFIX" " \
export PATH=\$PATH:$INSTALL_LOC/openmpi/5.0.9/bin && \
export NWCHEM_TOP=\$PWD && \
export NWCHEM_TARGET=LINUX64 && \
export NWCHEM_MODULES=all && \
export USE_MPI=y && \
export USE_OPENMP=y && \
export USE_SCALAPACK=y && \
export MPIEXEC=mpirun && \
export MPICC=mpicc && \
export MPIFC=mpif90 && \
export CC=gcc && \
export FC=gfortran && \
export BLASOPT='-L$INSTALL_LOC/OpenBLAS/0.3.30/lib -lopenblas -lpthread' && \
export LAPACK_LIB='-L$INSTALL_LOC/LAPACK/3.12.1/lib -llapack' && \
export LAPACKOPT=\"\$LAPACK_LIB\" && \
export SCALAPACK='-L$INSTALL_LOC/scalapack/2.2.2/lib -lscalapack' && \
export BLAS_SIZE=4 && \
export LAPACK_SIZE=4 && \
export SCALAPACK_SIZE=4 && \
export USE_64TO32=y && \
cd src && \
make clean && \
make 64_to_32 && \
make nwchem_config && \
make -j\$(nproc) > make.log 2>&1 \
"
}


install_qe () {
    FILE="q-e-qe-7.4.1.tar.gz"
    PREFIX="$INSTALL_LOC/qe/7.4.1"
    MODULE_DIR="$INSTALL_LOC"

    [ ! -f "$FILE" ] && { echo "$FILE not found! Skipping Quantum ESPRESSO."; return 1; }

    tar -xf "$FILE"
    PKG_NAME=$(basename "$FILE" .tar.gz)
    cd "$PKG_NAME" || return 1

    # Modern Fortran flags for Wannier etc.
    export FCFLAGS="-ffree-form -fallow-argument-mismatch -O3 -march=native"
    export FFLAGS="$FCFLAGS"

    safe_install "Quantum ESPRESSO 7.4.1" "$PREFIX" \
" \
cmake -S . -B build \
  -DCMAKE_INSTALL_PREFIX='$PREFIX' \
  -DCMAKE_Fortran_COMPILER=mpif90 \
  -DCMAKE_C_COMPILER=mpicc \
  -DQE_ENABLE_MPI=ON \
  -DQE_ENABLE_OPENMP=ON \
  -DQE_ENABLE_FFTW=ON \
  -DQE_ENABLE_LIBXC=OFF \
  -DQE_FOX_INTERNAL=ON \
  -DQE_ENABLE_SCALAPACK=ON \
  -DQE_ENABLE_WANNIER90=ON \
  -DSCALAPACK_DIR='$MODULE_DIR/scalapack/2.2.2' \
  -DSCALAPACK_LIBRARY='$MODULE_DIR/scalapack/2.2.2/lib/libscalapack.so' \
  -DBLAS_LIBRARIES='$MODULE_DIR/OpenBLAS/0.3.30/lib/libopenblas.so' \
  -DLAPACK_LIBRARIES='$MODULE_DIR/OpenBLAS/0.3.30/lib/libopenblas.so' \
  -DQE_ENABLE_HDF5=ON \
  -DHDF5_ROOT='$MODULE_DIR/HDF5/1.14.6' \
  -DHDF5_INCLUDE_DIR='$MODULE_DIR/HDF5/1.14.6/include' \
  -DHDF5_LIBRARY='$MODULE_DIR/HDF5/1.14.6/lib/libhdf5.so' \
  -DHDF5_HL_LIBRARY='$MODULE_DIR/HDF5/1.14.6/lib/libhdf5_hl.so' \
  -DHDF5_Fortran_INCLUDE_DIR='$MODULE_DIR/HDF5/1.14.6/include' \
  -DHDF5_Fortran_LIBRARY='$MODULE_DIR/HDF5/1.14.6/lib/libhdf5_fortran.so' \
  -DFFTW3_INCLUDE_DIRS='$MODULE_DIR/fftw/3.3.10/include' \
  -DFFTW3_LIBRARY='$MODULE_DIR/fftw/3.3.10/lib/libfftw3.so;$MODULE_DIR/fftw/3.3.10/lib/libfftw3_mpi.so' \
  -DFFTW3_DOUBLE='$MODULE_DIR/fftw/3.3.10/lib/libfftw3.so' \
  -DFFTW3_DOUBLE_OPENMP='$MODULE_DIR/fftw/3.3.10/lib/libfftw3_omp.so' \
&& cmake --build build -j'$(nproc)' \
&& cmake --install build \
"

    cd .. || true
    rm -rf "$PKG_NAME"
}

##############################################
# Dispatcher (process command-line arguments)
# Continue on failure (as requested)
##############################################
if [ "$#" -eq 0 ]; then
    echo "Usage: $0 <PACKAGE> [PACKAGE ...]"
    echo "Example: $0 OPENMPI FFTW OpenBLAS LAPACK scalapack hdf5 qe"
    exit 1
fi

for pkg in "$@"; do
    case "$pkg" in
        OPENMPI)   install_openmpi   || echo "OPENMPI failed, continuing..." ;;
        BOOST)     install_boost     || echo "BOOST failed, continuing..." ;;
        FFTW)      install_fftw      || echo "FFTW failed, continuing..." ;;
        OpenBLAS)  install_openblas  || echo "OpenBLAS failed, continuing..." ;;
        LAPACK|lapack)    install_lapack    || echo "LAPACK failed, continuing..." ;;
        scalapack) install_scalapack || echo "scalapack failed, continuing..." ;;
        hdf5)      install_hdf5      || echo "HDF5 failed, continuing..." ;;
        libint)    install_libint    || echo "libint failed, continuing..." ;;
        libxc)     install_libxc     || echo "libxc failed, continuing..." ;;
        json)      install_json      || echo "json failed, continuing..." ;;
        wannier90) install_wannier90 || echo "wannier90 failed, continuing..." ;;
	    nwchem)    install_nwchem    || echo "NWChem failed, continuing..." ;;
	    qe)        install_qe        || echo "Quantum ESPRESSO failed, continuing..." ;;
        *)
            echo "Unknown package: $pkg"
            ;;
    esac
done

echo "All requested installations completed (some may have failed)."
echo "If you added new modules, run: source ~/.bashrc"
