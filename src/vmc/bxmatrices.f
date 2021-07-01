      subroutine bxmatrix(kref,xmatu,xmatd,b)

      use vmc_mod, only: MORB
      use elec, only: ndn, nup
      use dorb_m, only: iworbd
      use slater, only: slmi
      use const, only: nelec

      use precision_kinds, only: dp
      implicit none

      integer :: i, iab, iel, ish, j
      integer :: kref, nel

      real(dp), dimension(MORB, nelec) :: b
      real(dp), dimension(nelec**2, 2) :: btemp
      real(dp), dimension(nelec**2) :: xmatu
      real(dp), dimension(nelec**2) :: xmatd
      real(dp), dimension(nelec) :: work





      do 110 iab=1,2
        if(iab.eq.1) then
          iel=0
          nel=nup
         else
          iel=nup
          nel=ndn
        endif
        ish=-nel
        do 110 i=1,nel
          ish=ish+nel
          do 110 j=1,nel
  110       btemp(j+ish,iab)=b(iworbd(j+iel,kref),i+iel)

      call multiply_slmi_mderiv_simple(nup,btemp(1,1),work,slmi(1,1),xmatu)
      call multiply_slmi_mderiv_simple(ndn,btemp(1,2),work,slmi(1,2),xmatd)

      return
      end
c-----------------------------------------------------------------------
