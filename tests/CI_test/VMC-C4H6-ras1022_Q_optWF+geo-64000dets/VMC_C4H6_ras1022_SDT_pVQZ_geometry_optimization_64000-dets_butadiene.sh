echo "Butadiene optimization 65000 determinants "

input="vmc_opt_ras1022_pVQZ_65000.inp"
output="vmc_opt_ras1022_pVQZ_65000"

# Unicore test
N=1
ReferenceEnergy=-26.1029780
ReferenceError=0.0183548
mpirun -np $N ../../../bin/vmc.mov1 -i $input -o ${output}_core_${N}.out -e error
echo "Comparing energy with reference Core=$N           (total E = $ReferenceEnergy +-  $ReferenceError ) "
../../../tools/compare_value.py ${output}_core_${N}.out         "total E"  $ReferenceEnergy     $ReferenceError

# Multicore test
N=2
ReferenceEnergy=-26.1022070
ReferenceError=0.0129212
mpirun -np $N ../../../bin/vmc.mov1 -i $input -o ${output}_core_${N}.out -e error
echo "Comparing energy with reference Core=$N           (total E = $ReferenceEnergy +-  $ReferenceError ) "
../../../tools/compare_value.py ${output}_core_${N}.out         "total E"  $ReferenceEnergy     $ReferenceError
