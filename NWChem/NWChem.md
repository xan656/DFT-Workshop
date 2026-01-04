
# File structure of input file for **NWChem**

```bash
start calculation_name
title "Short description of the calculation"

################################
# Memory specification
################################
memory total 2 gb

################################
# Geometry block
################################
geometry units angstrom
  atom1   x1   y1   z1
  atom2   x2   y2   z2
  ...
end

################################
# Basis set definition
################################
basis
  * library cc-pvdz
end

################################
# DFT / HF / MP2 / CCSD block
################################
dft
  xc b3lyp
  mult 1
end

################################
# Task specification
################################
task dft energy
```

## Method Block

### (`DFT / HF / MP2 / CCSD block`)

This block **defines the electronic structure method** used to solve the many-electron Schrödinger equation.  
It tells NWChem **how** to compute the electronic energy and wavefunction.

Only **one method block is active per task**, but **multiple blocks may exist** in the input file.

---

### (a) Hartree–Fock (HF / SCF)

```bash
scf   
	rhf 
end
```


**Purpose**
- Mean-field approximation
- Each electron moves in the average field of all others
- No explicit electron correlation

**Key points**
- `rhf` → closed-shell systems
- `uhf` → open-shell systems
---

### (b) Density Functional Theory (DFT)

```bash
dft   
	xc b3lyp   
	mult 1 
end
```


**Purpose**
- Uses **electron density** instead of wavefunction    
- Includes electron correlation via an **exchange–correlation functional**

**Key options**
- `xc` → exchange–correlation functional (e.g., PBE, B3LYP)
- `mult` → spin multiplicity

---

### (c) MP2 (Møller–Plesset Perturbation Theory)

```bash
mp2 
end
```


**Purpose**
- Adds **electron correlation** perturbatively to HF
- Second-order correction
- 
**Key points**
- More accurate than HF
- More expensive than DFT
- Requires a preceding HF reference

---

### (d) CCSD (Coupled Cluster)

```bash
 za1 ccsd 
end
```


**Purpose**
- Highly accurate correlated wavefunction method
- Includes single and double excitations

**Key points**
- Gold standard for small molecules
- Computationally very expensive
- Used mainly for benchmarking

---

## Task Specification Block

The **task block tells NWChem what to do** using the chosen method.

> Method block = _How to calculate_  
> Task block = _What calculation to perform_