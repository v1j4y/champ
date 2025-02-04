      module multideterminant_tmove_mod
      contains
      subroutine multideterminant_tmove(psid,iel_move)

      use b_tmove, only: b_t,iskip
      use casula,  only: icasula,t_vpsp
      use dorb_m,  only: iworbd
      use multidet, only: iactv,ivirt
      use multimat, only: aa
      use multislater, only: detiab
      use precision_kinds, only: dp
      use qua,     only: nquad
      use slater,  only: kref,norb,slmi
      use system,  only: ncent,ndn,nelec,nup
      use vmc_mod, only: norb_tot
      use ycompact, only: ymat

      implicit none

      integer :: i1, i2, iab, ic, iel
      integer :: iel_move, iq, irep, ish
      integer :: j, jel, jrep, nel
      real(dp) :: detratio, dum, psid
      real(dp), dimension(nelec, norb_tot) :: gmat
      real(dp), parameter :: one = 1.d0
      real(dp), parameter :: half = 0.5d0



      if(icasula.gt.0)then
        i1=iel_move
        i2=iel_move
       else
        i1=1
        i2=nelec
      endif

      do iel=i1,i2

      do ic=1,ncent

      if(iskip(iel,ic).eq.0) then

      if(iel.le.nup) then
        iab=1
        nel=nup
        ish=0
       else
        iab=2
        nel=ndn
        ish=nup
      endif

      detratio=detiab(kref,1,1)*detiab(kref,2,1)/psid

      jel=iel-ish

      do iq=1,nquad

        do jrep=ivirt(iab),norb
          dum=0
          do j=1,nel
            dum=dum+b_t(iworbd(j+ish,kref),iq,ic,iel)*aa(j,jrep,iab,1)
          enddo
          dum=b_t(jrep,iq,ic,iel)-dum

          do irep=iactv(iab),nel
            gmat(irep,jrep)=dum*slmi(irep+(jel-1)*nel,iab,1)
          enddo
        enddo

c     t_vpsp(ic,iq,iel)=t_vpsp_ref

      dum=0
      do jrep=ivirt(iab),norb
        do irep=iactv(iab),nel
          dum=dum+ymat(jrep,irep,iab,1)*gmat(irep,jrep)
        enddo
      enddo
      t_vpsp(ic,iq,iel)=t_vpsp(ic,iq,iel)+dum*detratio

      enddo

      endif

      enddo
      enddo

      return
      end
      end module
