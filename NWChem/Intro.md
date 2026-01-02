# Installing MPI + BLAS + LAPACK + ScaLAPACK

This workshop uses a **single installer script** to build a working
**MPI + linear algebra stack** *without sudo*.

⚠️ **Installation order matters. Follow the steps exactly.**

---
## 1. Prerequisites

Make sure the following tools are available:

```bash
gcc g++ gfortran cmake make
````

Otherwise
```bash
sudo apt install build-essential cmake
```
---

In install_modules.sh, change these paths such that it matches your suitable directory
```
export INSTALL_LOC="${INSTALL_LOC:-/home/q/Documents/Computations/modules}"
export INSTALL_NWCHEM="${INSTALL_NWCHEM:-/home/q/Documents/notes/IGCAR/DTDS/AbInitio}"
```

Download these packages and put in `$INSTALL_LOC` location

`https://download.open-mpi.org/release/open-mpi/v5.0/openmpi-5.0.9.tar.gz`
`https://www.netlib.org/lapack/lapack-3.12.1.tar.gz`
`https://sourceforge.net/projects/openblas/files/v0.3.30/OpenBLAS-0.3.30.tar.gz/download`
`https://www.cp2k.org/static/downloads/scalapack-2.2.2.tar.gz`

Use `install_modules.sh` to install the packages.

## 2. Step 1 — Install OpenMPI (FIRST)

MPI must be installed and activated before building any parallel libraries.

```bash
./install_modules.sh OPENMPI
source ~/.bashrc
```

Verify:

```bash
mpicc --version
mpirun --version
```

---

## 3. Step 2 — Install LAPACK

LAPACK provides core dense linear algebra routines.

```bash
./install_modules.sh LAPACK
source ~/.bashrc
```

---

## 4. Step 3 — Install OpenBLAS

OpenBLAS provides optimized BLAS kernels.

```bash
./install_modules.sh OpenBLAS
source ~/.bashrc
```

---

## 5. Step 4 — Install ScaLAPACK

ScaLAPACK enables distributed linear algebra using MPI.

```bash
./install_modules.sh scalapack
source ~/.bashrc
```

---
## 8. Quick Validation

```bash
which mpicc
ldd $INSTALL_LOC/scalapack/2.2.2/lib/libscalapack.so
```

You should see:

- `libmpi.so`    
- `libopenblas.so`
- `liblapack.so`
    
---

## 9. Common Issues

| Problem           | Fix                                 |
| ----------------- | ----------------------------------- |
| `mpicc not found` | `source ~/.bashrc`                  |
| `dsyev failed`    | Install LAPACK before ScaLAPACK     |
| MPI runtime error | Do not mix system MPI with user MPI |

---

# Installing NWChem

```bash
./install_modules.sh nwchem
source ~/.bashrc
```

---
## Correct Full Command Sequence

```bash
./install_modules.sh OPENMPI
source ~/.bashrc

./install_modules.sh LAPACK
./install_modules.sh OpenBLAS
./install_modules.sh scalapack

./install_modules.sh nwchem
source ~/.bashrc
```

---
**OpenMPI → LAPACK → OpenBLAS → ScaLAPACK → NWChem** 
