echo "TREXIO formaldehyde ground state energy"

input="trexio_vmc_COH2_gs.inp"
output="trexio_vmc_COH2_gs"

# Multicore test
N=8
ReferenceEnergy=-22.577964
ReferenceError=0.0045168
mpirun -np $N ../../../bin/vmc.mov1 -i ${input} -o ${output}_core_${N}.out -e error
echo "Comparing energy with reference Core=${N}           (total E = $ReferenceEnergy +-  $ReferenceError ) "
../../../tools/compare_value.py ${output}_core_${N}.out     "total E"  $ReferenceEnergy     $ReferenceError
