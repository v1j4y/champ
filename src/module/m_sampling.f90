module config
    !> looks a lot like sampling stuff
    !> Arguments: delttn, enew, eold, nearestn, nearesto, pen, peo,
    !> psi2n, psi2o, psido, psijo, rminn, rminno, rmino, rminon, rvminn,
    !> rvminno, rvmino, rvminon, tjfn, tjfo, tjfoo, vnew, vold, xnew, xold,
    !> d2o, peo_dmc, psido_dmc, psijo_dmc, vold_dmc, xold_dmc

      use mstates_mod, only: MSTATES
      use multiple_geo, only: MFORCE
      use precision_kinds, only: dp

    real(dp), dimension(:), allocatable :: delttn !(MELEC)
    real(dp), dimension(:), allocatable :: enew !(MFORCE)
    real(dp), dimension(:, :), allocatable :: eold !(MSTATES, MFORCE)
    integer, dimension(:), allocatable :: nearestn !(MELEC)
    integer, dimension(:), allocatable :: nearesto !(MELEC)
    real(dp) :: pen
    real(dp), dimension(:), allocatable :: peo !(MSTATES)
    real(dp), dimension(:), allocatable :: psi2n !(MFORCE)
    real(dp), dimension(:, :), allocatable :: psi2o !(MSTATES, MFORCE)
    real(dp), dimension(:), allocatable :: psido !(MSTATES)
    real(dp), dimension(:), allocatable :: psijo !(nwftypejas)
    real(dp), dimension(:), allocatable :: rminn !(MELEC)
    real(dp), dimension(:), allocatable :: rminno !(MELEC)
    real(dp), dimension(:), allocatable :: rmino !(MELEC)
    real(dp), dimension(:), allocatable :: rminon !(MELEC)
    real(dp), dimension(:, :), allocatable :: rvminn !(3, MELEC)
    real(dp), dimension(:, :), allocatable :: rvminno !(3, MELEC)
    real(dp), dimension(:, :), allocatable :: rvmino !(3, MELEC)
    real(dp), dimension(:, :), allocatable :: rvminon !(3, MELEC)
    real(dp) :: tjfn
    real(dp), dimension(:), allocatable :: tjfo !(MSTATES)
    real(dp) :: tjfoo
    real(dp), dimension(:, :), allocatable :: vnew !(3, MELEC)
    real(dp), dimension(:, :), allocatable :: vold !(3, MELEC)
    real(dp), dimension(:, :), allocatable :: xnew !(3, MELEC)
    real(dp), dimension(:, :), allocatable :: xold !(3, MELEC)
    !> DMC variables:
    real(dp), dimension(:,:), allocatable :: d2o        ! (mwalk,MFORCE)
    real(dp), dimension(:,:), allocatable :: peo_dmc    ! (mwalk,MFORCE)
    real(dp), dimension(:,:), allocatable :: psido_dmc  ! (mwalk,MFORCE)
    real(dp), dimension(:,:), allocatable :: psijo_dmc  ! (mwalk,MFORCE)
    real(dp), dimension(:,:,:,:), allocatable :: vold_dmc ! (3,MELEC,mwalk,MFORCE)
    real(dp), dimension(:,:,:,:), allocatable :: xold_dmc ! (3,MELEC,mwalk,MFORCE)

    private
    public   :: delttn, enew, eold, nearestn, nearesto, pen, peo, psi2n
    public   :: psi2o, psido, psijo, rminn, rminno, rmino, rminon, rvminn
    public   :: rvminno, rvmino, rvminon, tjfn, tjfo, tjfoo, vnew, vold, xnew, xold
    public   :: allocate_config, deallocate_config
    !> DMC variables:
    public   :: d2o, peo_dmc, psido_dmc, psijo_dmc, vold_dmc, xold_dmc
    public   :: allocate_config_dmc, deallocate_config_dmc
    save
contains
    subroutine allocate_config()
      use mstates_mod, only: MSTATES
      use system, only: nelec
      use multiple_geo, only: MFORCE
      use vmc_mod, only: nwftypejas
        implicit none
        if (.not. allocated(delttn)) allocate (delttn(nelec))
        if (.not. allocated(enew)) allocate (enew(MFORCE))
        if (.not. allocated(eold)) allocate (eold(MSTATES, MFORCE))
        if (.not. allocated(nearestn)) allocate (nearestn(nelec), source=0)
        if (.not. allocated(nearesto)) allocate (nearesto(nelec), source=0)
        if (.not. allocated(peo)) allocate (peo(MSTATES))
        peo = 0. ! Necessary since it is used in metrop_mov1_slat in vmc, but never set
        if (.not. allocated(psi2n)) allocate (psi2n(MFORCE))
        if (.not. allocated(psi2o)) allocate (psi2o(MSTATES, MFORCE))
        if (.not. allocated(psido)) allocate (psido(MSTATES))
        if (.not. allocated(psijo)) allocate (psijo(nwftypejas))
        if (.not. allocated(rminn)) allocate (rminn(nelec))
        if (.not. allocated(rminno)) allocate (rminno(nelec))
        if (.not. allocated(rmino)) allocate (rmino(nelec))
        if (.not. allocated(rminon)) allocate (rminon(nelec))
        if (.not. allocated(rvminn)) allocate (rvminn(3, nelec))
        if (.not. allocated(rvminno)) allocate (rvminno(3, nelec))
        if (.not. allocated(rvmino)) allocate (rvmino(3, nelec))
        if (.not. allocated(rvminon)) allocate (rvminon(3, nelec))
        if (.not. allocated(tjfo)) allocate (tjfo(MSTATES))
        if (.not. allocated(vnew)) allocate (vnew(3, nelec))
        if (.not. allocated(vold)) allocate (vold(3, nelec))
        if (.not. allocated(xnew)) allocate (xnew(3, nelec))
        if (.not. allocated(xold)) allocate (xold(3, nelec))
    end subroutine allocate_config

    subroutine deallocate_config()
        if (allocated(xold)) deallocate (xold)
        if (allocated(xnew)) deallocate (xnew)
        if (allocated(vold)) deallocate (vold)
        if (allocated(vnew)) deallocate (vnew)
        if (allocated(tjfo)) deallocate (tjfo)
        if (allocated(rvminon)) deallocate (rvminon)
        if (allocated(rvmino)) deallocate (rvmino)
        if (allocated(rvminno)) deallocate (rvminno)
        if (allocated(rvminn)) deallocate (rvminn)
        if (allocated(rminon)) deallocate (rminon)
        if (allocated(rmino)) deallocate (rmino)
        if (allocated(rminno)) deallocate (rminno)
        if (allocated(rminn)) deallocate (rminn)
        if (allocated(psido)) deallocate (psido)
        if (allocated(psi2o)) deallocate (psi2o)
        if (allocated(psi2n)) deallocate (psi2n)
        if (allocated(peo)) deallocate (peo)
        if (allocated(nearesto)) deallocate (nearesto)
        if (allocated(nearestn)) deallocate (nearestn)
        if (allocated(eold)) deallocate (eold)
        if (allocated(enew)) deallocate (enew)
        if (allocated(delttn)) deallocate (delttn)
    end subroutine deallocate_config

    subroutine allocate_config_dmc()
      use dmc_mod, only: mwalk
      use multiple_geo, only: MFORCE
      use system, only: nelec

      implicit none

      if (.not. allocated(d2o)) allocate(d2o(mwalk,MFORCE))
      if (.not. allocated(peo_dmc)) allocate(peo_dmc(mwalk,MFORCE))
      if (.not. allocated(psido_dmc)) allocate(psido_dmc(mwalk,MFORCE))
      if (.not. allocated(psijo_dmc)) allocate(psijo_dmc(mwalk,MFORCE))
      if (.not. allocated(vold_dmc)) allocate(vold_dmc(3,nelec,mwalk,MFORCE))
      if (.not. allocated(xold_dmc)) allocate(xold_dmc(3,nelec,mwalk,MFORCE))
    end subroutine allocate_config_dmc

    subroutine deallocate_config_dmc()
      if (allocated(d2o)) deallocate(d2o)
      if (allocated(peo_dmc)) deallocate(peo_dmc)
      if (allocated(psido_dmc)) deallocate(psido_dmc)
      if (allocated(psijo_dmc)) deallocate(psijo_dmc)
      if (allocated(vold_dmc)) deallocate(vold_dmc)
      if (allocated(xold_dmc)) deallocate(xold_dmc)
    end subroutine deallocate_config_dmc
end module config

module random
    !> I guess the random number generator
    !> used to move in the MC sampling
    !> Arguments: ll, lm

    integer  :: ll(4)
    integer  :: mm(4)
    integer  :: switch_rng = 1

    data mm/502, 1521, 4071, 2107/
    data ll/0, 0, 0, 1/

    private
    public :: ll, mm, switch_rng
    save

end module random

module stats
    !> Arguments: rejmax, acc, dfus2ac, dfus2un, dr2ac, dr2un, nacc,
    !> nbrnch, nodecr, trymove
      use precision_kinds, only: dp

    real(dp) :: rejmax
    !> DMC variables
    real(dp) :: acc
    real(dp) :: dfus2ac
    real(dp) :: dfus2un
    real(dp) :: dr2ac
    real(dp) :: dr2un
    integer  :: nacc
    integer  :: nbrnch
    integer  :: nodecr
    real(dp) :: trymove

    private
    public :: rejmax
    public :: acc, dfus2ac, dfus2un, dr2ac, dr2un, nacc, nbrnch, nodecr, trymove
    save
end module stats

module step
    !> I guess has to do with the sampling
    !> Arguments: ekin, ekin2, rprob, suc, trunfb, try
      use precision_kinds, only: dp
      use vmc_mod, only: nrad

    real(dp), dimension(:), allocatable :: ekin !(nrad)
    real(dp), dimension(:), allocatable :: ekin2 !(nrad)
    real(dp), dimension(:), allocatable :: rprob !(nrad)
    real(dp), dimension(:), allocatable :: suc !(nrad)
    real(dp), dimension(:), allocatable :: trunfb !(nrad)
    real(dp), dimension(:), allocatable :: try !(nrad)

    private
    public :: ekin, ekin2, rprob, suc, trunfb, try
    public :: allocate_step, deallocate_step
    save
contains
    subroutine allocate_step()
      use vmc_mod, only: nrad
        if (.not. allocated(ekin)) allocate (ekin(nrad))
        if (.not. allocated(ekin2)) allocate (ekin2(nrad))
        if (.not. allocated(rprob)) allocate (rprob(nrad))
        if (.not. allocated(suc)) allocate (suc(nrad))
        if (.not. allocated(trunfb)) allocate (trunfb(nrad))
        if (.not. allocated(try)) allocate (try(nrad))
    end subroutine allocate_step

    subroutine deallocate_step()
        if (allocated(try)) deallocate (try)
        if (allocated(trunfb)) deallocate (trunfb)
        if (allocated(suc)) deallocate (suc)
        if (allocated(rprob)) deallocate (rprob)
        if (allocated(ekin2)) deallocate (ekin2)
        if (allocated(ekin)) deallocate (ekin)
    end subroutine deallocate_step

end module step

module tmpnode
    !> has to do with the sampling
    !> Arguments: distance_node_sum
      use precision_kinds, only: dp

    real(dp) :: distance_node_sum

    private
    public :: distance_node_sum
    save
end module tmpnode

module kinet
    !> kinetic energy ?
    !> only used in metropolis
    !> Arguments: dtdx2n, dtdx2o
      use precision_kinds, only: dp

    real(dp), dimension(:), allocatable :: dtdx2n !(MELEC)
    real(dp), dimension(:), allocatable :: dtdx2o !(MELEC)

    private
    public :: dtdx2n, dtdx2o
    public :: allocate_kinet, deallocate_kinet
    save
contains
    subroutine allocate_kinet()
        use system, only: nelec
        if (.not. allocated(dtdx2n)) allocate (dtdx2n(nelec))
        if (.not. allocated(dtdx2o)) allocate (dtdx2o(nelec))
    end subroutine allocate_kinet

    subroutine deallocate_kinet()
        if (allocated(dtdx2o)) deallocate (dtdx2o)
        if (allocated(dtdx2n)) deallocate (dtdx2n)
    end subroutine deallocate_kinet

end module kinet

module m_sampling
contains
subroutine allocate_m_sampling()
      use config, only: allocate_config
      use kinet, only: allocate_kinet
      use step, only: allocate_step
      use system, only: nelec

    call allocate_config()
    call allocate_step()
    call allocate_kinet()
end subroutine allocate_m_sampling

subroutine deallocate_m_sampling()
      use config, only: deallocate_config
      use kinet, only: deallocate_kinet
      use step, only: deallocate_step

    call deallocate_config()
    call deallocate_step()
    call deallocate_kinet()
end subroutine deallocate_m_sampling
end module 
