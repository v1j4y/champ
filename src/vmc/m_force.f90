module force_mod

     implicit none

     integer :: MFORCE
     integer, parameter :: MFORCE_WT_PRD = 1000
     integer, parameter :: MWF = 3

     private
     public :: MFORCE, MFORCE_WT_PRD, MWF
     save
 end module force_mod

 module forcepar
    !> Arguments: deltot, istrech, nforce, alfstr
    use force_mod, only: MFORCE
    use precision_kinds, only: dp

    implicit none

    real(dp), dimension(:), allocatable :: deltot !(MFORCE)
    integer :: istrech
    integer :: nforce
    real(dp) :: alfstr

    private
    public   ::  deltot, istrech, nforce, alfstr
    public :: allocate_forcepar, deallocate_forcepar
    save
contains
    subroutine allocate_forcepar()
        use force_mod, only: MFORCE
        if (.not. allocated(deltot)) allocate (deltot(MFORCE))
    end subroutine allocate_forcepar

    subroutine deallocate_forcepar()
        if (allocated(deltot)) deallocate (deltot)
    end subroutine deallocate_forcepar

end module forcepar

 module force_analy
     !> Arguments: iforce_analy, iuse_zmat, alfgeo
     use precision_kinds, only: dp

     implicit none

     integer :: iforce_analy
     integer :: iuse_zmat
     real(dp) :: alfgeo

     private
     public   :: iforce_analy, iuse_zmat, alfgeo
     save
 end module force_analy

 module forcest
     !> Arguments: fcm2, fcum, fgcm2, fgcum
     use force_mod, only: MFORCE
     use precision_kinds, only: dp
     use mstates_mod, only: MSTATES

     real(dp), dimension(:, :), allocatable :: fcm2 !(MSTATES,MFORCE)
     real(dp), dimension(:, :), allocatable :: fcum !(MSTATES,MFORCE)
     ! DMC arrays:
     real(dp), dimension(:), allocatable :: fgcm2 !(MFORCE)
     real(dp), dimension(:), allocatable :: fgcum !(MFORCE)

     private
     public   ::  fcm2, fcum, fgcm2, fgcum
     public :: allocate_forcest, deallocate_forcest
     save
 contains
     subroutine allocate_forcest()
         use force_mod, only: MFORCE
         use mstates_mod, only: MSTATES
         if (.not. allocated(fcm2)) allocate (fcm2(MSTATES, MFORCE))
         if (.not. allocated(fcum)) allocate (fcum(MSTATES, MFORCE))
         ! DMC arrays:
         if (.not. allocated(fgcm2)) allocate (fgcm2(MFORCE))
         if (.not. allocated(fgcum)) allocate (fgcum(MFORCE))
     end subroutine allocate_forcest

     subroutine deallocate_forcest()
         if (allocated(fcum)) deallocate (fcum)
         if (allocated(fcm2)) deallocate (fcm2)
         ! DMC arrays:
         if (allocated(fcm2)) deallocate (fgcm2)
         if (allocated(fcum)) deallocate (fgcum)
     end subroutine deallocate_forcest

 end module forcest

 module forcestr
     !> Arguments: delc
     use precision_kinds, only: dp

     implicit none

     real(dp), dimension(:, :, :), allocatable :: delc !(3,MCENT,MFORCE)

     private
     public   ::  delc
!     public :: allocate_forcestr
     public :: deallocate_forcestr
     save
 contains

     subroutine deallocate_forcestr()
         if (allocated(delc)) deallocate (delc)
     end subroutine deallocate_forcestr

 end module forcestr

 module forcewt
     !> Arguments: wcum, wsum
     use force_mod, only: MFORCE
     use precision_kinds, only: dp
     use mstates_mod, only: MSTATES

     implicit none

     real(dp), dimension(:, :), allocatable :: wcum !(MSTATES,MFORCE)
     real(dp), dimension(:, :), allocatable :: wsum !(MSTATES,MFORCE)

     private
     public   ::  wcum, wsum
     public :: allocate_forcewt, deallocate_forcewt
     save
 contains
     subroutine allocate_forcewt()
         use force_mod, only: MFORCE
         use mstates_mod, only: MSTATES
         if (.not. allocated(wcum)) allocate (wcum(MSTATES, MFORCE))
         if (.not. allocated(wsum)) allocate (wsum(MSTATES, MFORCE))
     end subroutine allocate_forcewt

     subroutine deallocate_forcewt()
         if (allocated(wsum)) deallocate (wsum)
         if (allocated(wcum)) deallocate (wcum)
     end subroutine deallocate_forcewt

 end module forcewt

 module force_dmc
     !> Arguments: itausec, nwprod

     implicit none

     integer :: itausec
     integer :: nwprod

     private
     public   ::   itausec, nwprod
     save
 end module force_dmc

 module force_fin
     !> Arguments: da_energy_ave, da_energy_err
     use precision_kinds, only: dp

     implicit none

     real(dp), dimension(:, :), allocatable :: da_energy_ave !(3,MCENT)
     real(dp), dimension(:), allocatable :: da_energy_err !(3)

     private
     public   :: da_energy_ave, da_energy_err
     public :: allocate_force_fin, deallocate_force_fin
     save
 contains
     subroutine allocate_force_fin()
         use atom, only: ncent_tot
         if (.not. allocated(da_energy_ave)) allocate (da_energy_ave(3, ncent_tot))
         if (.not. allocated(da_energy_err)) allocate (da_energy_err(3))
     end subroutine allocate_force_fin

     subroutine deallocate_force_fin()
         if (allocated(da_energy_err)) deallocate (da_energy_err)
         if (allocated(da_energy_ave)) deallocate (da_energy_ave)
     end subroutine deallocate_force_fin

 end module force_fin

 module force_mat_n
     !> Arguments: force_o

     use sr_mod, only: MCONF
     use precision_kinds, only: dp

     implicit none

     real(dp), dimension(:, :), allocatable :: force_o !(6*MCENT,MCONF)

     private
     public   ::  force_o
     public :: allocate_force_mat_n, deallocate_force_mat_n
     save
 contains
     subroutine allocate_force_mat_n()
         use sr_mod, only: MCONF
         use atom, only: ncent_tot
         if (.not. allocated(force_o)) allocate (force_o(6*ncent_tot, MCONF))
     end subroutine allocate_force_mat_n

     subroutine deallocate_force_mat_n()
         if (allocated(force_o)) deallocate (force_o)
     end subroutine deallocate_force_mat_n

 end module force_mat_n

 subroutine allocate_m_force()
     use forcest, only: allocate_forcest
    !  use forcestr, only: allocate_forcestr
     use forcewt, only: allocate_forcewt
     use force_fin, only: allocate_force_fin
     use force_mat_n, only: allocate_force_mat_n
     use forcepar, only: allocate_forcepar

     implicit none

     call allocate_forcest()
    !  call allocate_forcestr()
     call allocate_forcewt()
     call allocate_force_fin()
     call allocate_force_mat_n()
     call allocate_forcepar()
 end subroutine allocate_m_force

 subroutine deallocate_m_force()
     use forcest, only: deallocate_forcest
     use forcestr, only: deallocate_forcestr
     use forcewt, only: deallocate_forcewt
     use force_fin, only: deallocate_force_fin
     use force_mat_n, only: deallocate_force_mat_n
     use forcepar, only: deallocate_forcepar

     implicit none

     call deallocate_forcest()
     call deallocate_forcestr()
     call deallocate_forcewt()
     call deallocate_force_fin()
     call deallocate_force_mat_n()
     call deallocate_forcepar()
 end subroutine deallocate_m_force
