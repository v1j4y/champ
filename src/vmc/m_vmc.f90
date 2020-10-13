module vmc_mod
    !> Arguments:
    use precision_kinds, only: dp

    ! MELEC  >= number of electrons
    ! MORB   >= number of orbitals
    ! MBASIS >= number of basis functions
    ! MDET   >= number of determinants
    ! MCENT  >= number of centers
    ! MCTYPE >= number of center types
    ! MCTYP3X=max(3,MCTYPE)

    ! Slater matrices are dimensioned (MELEC/2)**2 assuming
    ! equal numbers of up and down spins. MELEC has to be
    ! correspondingly larger if spin polarized calculations
    ! are attempted.

    ! PLT@eScienceCenter(2020) Moved the parameter here:
    ! "For Jastrow4 NEQSX=2*(MORDJ-1) is sufficient.
    !  For Jastrow3 NEQSX=2*MORDJ should be sufficient.
    !  I am setting NEQSX=6*MORDJ simply because that is how it was for
    !  Jastrow3 for reasons I do not understand."
    !     parameter(NEQSX=2*(MORDJ-1),MTERMS=55)

    integer :: MMAT_DIM20 ! never used ??!!

    real(dp), parameter :: radmax = 10.d0
    integer, parameter :: nrad = 3001
    real(dp), parameter :: delri = (nrad - 1)/radmax

    integer, parameter :: MELEC = 32, MORB = 148, MBASIS = 148, MDET = 400, MCENT = 20
    integer, parameter :: MCTYPE = 3
    integer, parameter :: MCTYP3X = 5, NSPLIN = 1001, MORDJ = 7

    ! integer, parameter :: MMAT_DIM = (MELEC*MELEC)/4, MMAT_DIM2 = (MELEC*(MELEC - 1))/2
    integer :: MMAT_DIM, MMAT_DIM2
    integer, parameter :: MORDJ1 = MORDJ + 1

    integer, parameter :: NEQSX = 6*MORDJ, MTERMS = 55
    integer, parameter :: MCENT3 = 3*MCENT

    integer, parameter :: NCOEF = 5
    integer, parameter :: MEXCIT = 10

    ! integer :: nmat_dim, nmat_dim2

    private
    public :: MELEC, MORB, MBASIS, MDET, MCENT, MCTYPE, MCTYP3X
    public :: NSPLIN, nrad, MORDJ, MORDJ1, MMAT_DIM, MMAT_DIM2, MMAT_DIM20
    public :: radmax, delri
    public :: nmat_dim, nmat_dim2

    public :: NEQSX, MTERMS

    public :: MCENT3, NCOEF, MEXCIT

    save

contains

end module vmc_mod
