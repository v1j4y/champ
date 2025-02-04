# Source files
file(GLOB DMC_SOURCE
  acues1_reduce.f
  averages.f
  dumper.f
  gauss.f
  main.f
  mmpol_reduce.f
  nonloc_grid.f
  pcm_reduce.f
  redistribute.f
  splitj.f
  zerest.f
  acues1.f
  acuest.f
  dmc.f
  dumper_gpop.f
  hpsiedmc.f
  mc_configs.f
  move_walker.f
  optwf_dmc.f
  prop_dmc.f
  restart.f
  walksav_det.f
  acues1_gpop.f
  acuest_gpop.f
  dmc_ps_mov1.f
  finwrt.f
  init.f
  mmpol_dmc.f
  multideterminant_tmove.f
  pcm_dmc.f
  prop_reduce.f
  restart_gpop.f
  walksav_jas.f
  )

find_package(FortranFormat)
formatFortran("${DMC_SOURCE}") # Set Fixed format property

# --------------------------------------------------------------------

# executable dependencies
add_executable(dmc.mov1
  $<TARGET_OBJECTS:shared_modules>
  $<TARGET_OBJECTS:shared_objects>
  $<TARGET_OBJECTS:rng>
  # DMC source code
  ${DMC_SOURCE})

#  Add headers
target_include_directories(dmc.mov1
  PUBLIC
  ${CMAKE_BINARY_DIR}/src/vmc
  ${CMAKE_BINARY_DIR}/src/module
  )

# compilation
target_compile_options(dmc.mov1
  PRIVATE
  ${Fortran_FLAGS}
  "$<$<CONFIG:Debug>:${Fortan_FLAGS_DEBUG}>"
  )

if (TREXIO_FOUND)
  target_link_libraries(dmc.mov1
    PRIVATE
    pspline
    parser
    ${LINEAR_ALGEBRA}
    ${TREXIO_LIBRARY}
    MPI::MPI_Fortran)
else()
  target_link_libraries(dmc.mov1
    PRIVATE
    pspline
    parser
    ${LINEAR_ALGEBRA}
    MPI::MPI_Fortran)
endif()


set(DMC_SOURCE ${DMC_SOURCE} CACHE INTERNAL "Path to the source of vmc f77")
