      module multideterminant_mod
      contains
      subroutine multideterminant_hpsi(vj,vpsp_det,eloc_det)

      use Bloc,    only: b,tildem,xmat
      use bxmatrices, only: bxmatrix
      use coefs,   only: norb
      use constants, only: hb
      use csfs,    only: nstates
      use denergy_det_m, only: allocate_denergy_det_m,denergy_det
      use m_force_analytic, only: iforce_analy
      use matinv_mod, only: matinv
      use multidet, only: irepcol_det,ireporb_det,k_aux,k_det,k_det2
      use multidet, only: ndet_req,ndetiab,ndetiab2,ndetsingle
      use multidet, only: numrep_det
      use multimat, only: aa,wfmat
      use multislater, only: detiab
      use optwf_control, only: ioptorb,method
      use orbval,  only: nadorb,orb
      use precision_kinds, only: dp
      use slater,  only: d2dx2,ddx,iwundet,kref,ndet,slmi
      use system,  only: ndn,nelec,nup
      use ycompact, only: dymat,ymat
      use zcompact, only: aaz,dzmat,emz,zmat

      implicit none

      integer :: i, iab, iel, index_det, iorb, kun, kw
      integer :: irep, ish, istate, jorb
      integer :: jrep, k, ndim, nel, ndim2, kk
      real(dp) :: det, dum1, dum2, dum3
      real(dp), dimension(ndet, 2) :: eloc_det
      real(dp), dimension(3, nelec) :: vj
      real(dp), dimension(*) :: vpsp_det
      real(dp), dimension(nelec**2, 2) :: btemp
      real(dp), dimension(ndet_req,2) :: ddetiab
      real(dp), dimension(ndet_req,2) :: ddenergy_det


c note that the dimension of the slater matrices is assumed
c to be given by nmat_dim = (MELEC/2)**2, that is there are
c as many ups as downs. If this is not true then be careful if
c nelec is close to MELEC. The Slater matrices must be
c dimensioned at least max(nup**2,ndn**2)




      ! call resize_matrix(b, norb+nadorb, 1)
      ! call resize_matrix(orb, norb+nadorb, 2)
      ! call resize_tensor(tildem, norb+nadorb, 2)
      ! call resize_tensor(aa, norb+nadorb, 2)

      nel=nup
      ish=0
      do iab=1,2
        if(iab.eq.2) then
          nel=ndn
          ish=nup
        endif
        eloc_det(kref,iab)=vpsp_det(iab)
        do i=1,nel
          eloc_det(kref,iab)=eloc_det(kref,iab)
     &    -hb*(d2dx2(i+ish)+2.d0*(vj(1,i+ish)*ddx(1,i+ish)+vj(2,i+ish)*ddx(2,i+ish)+vj(3,i+ish)*ddx(3,i+ish)))
        enddo
      enddo

c     write(ounit,*) 'eloc_ref',eloc_det(kref,1),eloc_det(kref,2)

      if(ndet.ne.1.or.iforce_analy.ne.0.or.ioptorb.ne.0) call bxmatrix(kref,xmat(1,1),xmat(1,2),b)

      if(ndet.eq.1.and.ioptorb.eq.0) return

      nel=nup
      iel=0
      do iab=1,2
        if(iab.eq.2) then
          nel=ndn
          iel=nup
        endif

c       ish=-nel
c       do 110 i=1,nel
c         ish=ish+nel
c         do 110 j=1,nel
c 110       btemp(j+ish,iab)=b(iworbd(j+iel,kref),i+iel)

c       do jrep=ivirt(iab),norb+nadorb
        do jrep=1,norb+nadorb

          do irep=1,nel
            dum1=0.d0
            dum2=0.d0
            dum3=0.d0
            do i=1,nel
              dum1=dum1+slmi(irep+(i-1)*nel,iab)*orb(i+iel,jrep)
              dum2=dum2+slmi(irep+(i-1)*nel,iab)*b(jrep,i+iel)
              dum3=dum3+xmat(i+(irep-1)*nel,iab)*orb(i+iel,jrep)
            enddo
            aa(irep,jrep,iab)=dum1
            tildem(irep,jrep,iab)=dum2-dum3
          enddo

c         do irep=1,nel
c           dum1=0.d0
c           do i=1,nel
c             dum4=0.d0
c             do kk=1,nel
c               dum4=dum4+btemp(kk+nel*(i-1),iab)*aa(kk,jrep,iab)
c             enddo
c             dum1=dum1+slmi(irep+(i-1)*nel,iab)*(b(jrep,i+iel)-dum4)
c           enddo
c           tildem(irep,jrep,iab)=dum1
c         enddo

        enddo

      enddo

c     if(kref.ne.1) then
c       do irep=1,13
c         write(ounit,'(''SLM  '',15f7.2)') (slmi(irep+(i-1)*ndn,2),i=1,13)
c       enddo
c       do irep=1,13
c         write(ounit,'(''AA-2 '',15f7.2)') (aa(irep,jrep,2),jrep=1,15)
c       enddo
c     endif

      call allocate_denergy_det_m()
      denergy_det(kref,1)=0
      denergy_det(kref,2)=0
      ddenergy_det=0
      
      if(ndet.eq.1) return

      do iab=1,2
         
!     loop inequivalent determinants
! determinants with single exitations
         do k=1,ndetsingle(iab)
                     
            iorb=irepcol_det(1,k,iab)
            jorb=ireporb_det(1,k,iab)
            ddetiab(k,iab)=aa(iorb,jorb,iab)               
            wfmat(k,1,iab)=1.0d0/ddetiab(k,iab)                              
            ddenergy_det(k,iab)=wfmat(k,1,iab)*tildem(iorb,jorb,iab)
            
         enddo


! determinants multiple exitations
        do k=ndetsingle(iab)+1,ndetiab(iab)
           
           ndim=numrep_det(k,iab)
           do irep=1,ndim
              iorb=irepcol_det(irep,k,iab)
              do jrep=1,ndim
                 jorb=ireporb_det(jrep,k,iab)
                 wfmat(k,irep+(jrep-1)*ndim,iab)=aa(iorb,jorb,iab)
              enddo
           enddo
           
           ndim2=ndim*ndim
           call matinv(wfmat(k,1:ndim2,iab),ndim,det)
           ddetiab(k,iab)=det
           

           do irep=1,ndim
              iorb=irepcol_det(irep,k,iab)
              do jrep=1,ndim
                 jorb=ireporb_det(jrep,k,iab)
                 ddenergy_det(k,iab)=ddenergy_det(k,iab)+wfmat(k,jrep+(irep-1)*ndim,iab)*tildem(iorb,jorb,iab)
              enddo
           enddo
           
        enddo
        
! unrolling determinants different to kref
        detiab(:,iab)=detiab(kref,iab)
        eloc_det(:,iab)=eloc_det(kref,iab)
        denergy_det(:,iab)=0.d0
        do kk=1,ndetiab2(iab)
           k=k_det2(kk,iab)
           kw=k_aux(kk,iab)
           detiab(k,iab)=detiab(k,iab)*ddetiab(kw,iab)
           denergy_det(k,iab)=ddenergy_det(kw,iab)
           eloc_det(k,iab)=eloc_det(k,iab)+denergy_det(k,iab)

c!     print *, 'CIAO',k,eloc_det(k,iab),detiab(k,iab)
        enddo

c        detiab(k_det2(1:ndetiab2(iab),iab),iab)=detiab(k_det2(1:ndetiab2(iab),iab),iab)*ddetiab(k_aux(1:ndetiab2(iab),iab),iab)
c        denergy_det(k_det2(1:ndetiab2(iab),iab),iab)=ddenergy_det(k_aux(1:ndetiab2(iab),iab),iab)
c        eloc_det(k_det2(1:ndetiab2(iab),iab),iab)=eloc_det(k_det2(1:ndetiab2(iab),iab),iab)+
c     &       denergy_det(k_det2(1:ndetiab2(iab),iab),iab)
        
        
        
        

      enddo
      
         
         
c compute Ymat for future use
         
      do istate=1,nstates

        call compute_ymat(1,detiab(1,1),detiab(1,2),wfmat(:,:,1),ymat(1,1,1,istate),istate)
!        if(iforce_analy.gt.0.or.(ioptorb.gt.0.and.(method(1:3) == 'lin'))) call compute_dymat(1,dymat(1,1,1,istate))
        if(iforce_analy.gt.0.or.ioptorb.gt.0) call compute_dymat(1,dymat(1,1,1,istate))

        if(ndn.gt.0) then
          call compute_ymat(2,detiab(1,1),detiab(1,2),wfmat(:,:,2),ymat(1,1,2,istate),istate)
!          if(iforce_analy.gt.0.or.(ioptorb.gt.0.and.(method(1:3) == 'lin'))) call compute_dymat(2,dymat(1,1,2,istate))
          if(iforce_analy.gt.0.or.ioptorb.gt.0) call compute_dymat(2,dymat(1,1,2,istate))
        endif

!        if(iforce_analy.gt.0.or.(ioptorb.gt.0.and.(method(1:3) == 'lin'))) call compute_zmat(ymat(1,1,1,istate),dymat(1,1,1,istate)
        if(iforce_analy.gt.0.or.ioptorb.gt.0) call compute_zmat(ymat(1,1,1,istate),dymat(1,1,1,istate)
     &    ,zmat(1,1,1,istate),dzmat(1,1,1,istate),emz(1,1,1,istate),aaz(1,1,1,istate))
      enddo

      return
      end

c-----------------------------------------------------------------------
      subroutine compute_ymat(iab,detu,detd,wfmat,ymat,istate)

      use coefs,   only: norb
      use denergy_det_m, only: denergy_det
      use multidet, only: irepcol_det,ireporb_det,k_aux,k_det,k_det2
      use multidet, only: ndetiab,ndetiab2,ndetsingle,numrep_det
      use multiple_geo, only: iwf
      use precision_kinds, only: dp
      use slater,  only: cdet,cdet_equiv,dcdet_equiv,iwundet,kref,ndet
      use system,  only: nelec
      use vmc_mod, only: MEXCIT,norb_tot


      implicit none

      integer :: i, iab, iorb, irep, istate
      integer :: j, jorb, jrep, k, kun, kw
      integer :: kk, ndim, ndim2
      real(dp) :: detall, detrefi
      real(dp), dimension(ndet) :: detu
      real(dp), dimension(ndet) :: detd
      real(dp), dimension(ndet, MEXCIT**2) :: wfmat
      real(dp), dimension(norb_tot*nelec) :: ymat
      real(dp), parameter :: one = 1.d0
      real(dp), parameter :: half = 0.5d0


      real(dp), dimension(ndetiab2(iab)) :: detallv
      real(dp), dimension(ndetiab2(iab)) :: sumde
      

      detrefi=1.d0/(detu(kref)*detd(kref))

      ymat=0
     

      cdet_equiv=0
      dcdet_equiv=0
! Unroling determinants different to kref
      do kk=1,ndetiab2(iab)
         k=k_det2(kk,iab)
         kw=k_aux(kk,iab)
         detall=detrefi*detu(k)*detd(k)*cdet(k,istate,iwf)
         cdet_equiv(kw)=cdet_equiv(kw)+detall
         dcdet_equiv(kw)=dcdet_equiv(kw)+detall*(denergy_det(k,1)+denergy_det(k,2)) 
      enddo
      
c      detallv=detrefi*detu(k_det2(1:ndetiab2(iab),iab))*detd(k_det2(1:ndetiab2(iab),iab))
c     &     *cdet(k_det2(1:ndetiab2(iab),iab),istate,iwf)

c      cdet_equiv(k_aux(1:ndetiab2(iab),iab))=cdet_equiv(k_aux(1:ndetiab2(iab),iab))+detallv
      
c      sumde=denergy_det(k_det2(1:ndetiab2(iab),iab),1)+denergy_det(k_det2(1:ndetiab2(iab),iab),2)
      
c      detallv=detallv*sumde
      
c      dcdet_equiv(k_aux(1:ndetiab2(iab),iab))=dcdet_equiv(k_aux(1:ndetiab2(iab),iab))+detallv
      
      
c! loop over single exitations
      do kk=1,ndetsingle(iab)
c!     print *,'OLA',kk,cdet_equiv(kk)

         iorb=irepcol_det(1,kk,iab)
         jorb=ireporb_det(1,kk,iab)
         ymat(jorb+norb_tot*(iorb-1))=ymat(jorb+norb_tot*(iorb-1))+cdet_equiv(kk)*wfmat(kk,1)
         
      enddo
      
c      irepcol_det(1,1:ndetsingle(iab),iab)
c      ireporb_det(1,1:ndetsingle(iab),iab)
c      ireporb_det(1,1:ndetsingle(iab),iab)+(norb_tot*(irepcol_det(1,1:ndetsingle(iab),iab)-1))
 
!     loop over single exitations     
c      ymat(ireporb_det(1,1:ndetsingle(iab),iab)+(norb_tot*(irepcol_det(1,1:ndetsingle(iab),iab)-1))) =
c     &     ymat(ireporb_det(1,1:ndetsingle(iab),iab)+(norb_tot*(irepcol_det(1,1:ndetsingle(iab),iab)-1))) +
c     &     cdet_equiv(1:ndetsingle(iab))*wfmat(1:ndetsingle(iab),1)
      
      
      do kk=ndetsingle(iab)+1,ndetiab(iab)
         
         ndim=numrep_det(kk,iab)
         do irep=1,ndim
            iorb=irepcol_det(irep,kk,iab)
            do jrep=1,ndim
               jorb=ireporb_det(jrep,kk,iab)
               ymat(jorb+norb_tot*(iorb-1))=ymat(jorb+norb_tot*(iorb-1))+cdet_equiv(kk)*wfmat(kk,jrep+(irep-1)*ndim)
            enddo
            
         enddo
         
      enddo

      

      return
      end
c-----------------------------------------------------------------------
      subroutine compute_dymat(iab,dymat)

      use Bloc,    only: tildem
      use coefs,   only: norb
      use multidet, only: irepcol_det,ireporb_det,ndetiab,ndetsingle
      use multidet, only: numrep_det
      use multimat, only: wfmat
      use precision_kinds, only: dp
      use slater,  only: cdet_equiv,dcdet_equiv,iwundet,kref,ndet
      use system,  only: nelec
      use vmc_mod, only: MEXCIT,norb_tot


      implicit none

      integer :: i, iab, iorb, irep, j
      integer :: jj, jorb, jrep, kk
      integer :: ll, lorb, lrep, ndim

      real(dp), dimension(norb_tot, nelec) :: dymat
      real(dp), dimension(MEXCIT*MEXCIT) :: dmat1
      real(dp), dimension(MEXCIT*MEXCIT) :: dmat2



      dymat=0
      
! loop over single exitations      
      do kk=1,ndetsingle(iab)


         iorb=ireporb_det(1,kk,iab)
         jorb=irepcol_det(1,kk,iab)
         dmat1(1)=wfmat(kk,1,iab)*tildem(jorb,iorb,iab)
         dmat2(1)=dmat1(1)*wfmat(kk,1,iab)
         dymat(iorb,jorb)=dymat(iorb,jorb)+wfmat(kk,1,iab)*dcdet_equiv(kk)-cdet_equiv(kk)*dmat2(1)
                  
      enddo

      

!     do kk=1,ndetiab(iab)
      do kk=ndetsingle(iab)+1,ndetiab(iab)

         ndim=numrep_det(kk,iab)
            
         do irep=1,ndim
            iorb=ireporb_det(irep,kk,iab)
            do jrep=1,ndim
               jj=jrep+(irep-1)*ndim
               dmat1(jj)=0.d0
               do lrep=1,ndim
                  lorb=irepcol_det(lrep,kk,iab)
                  dmat1(jj)=dmat1(jj)+wfmat(kk,jrep+(lrep-1)*ndim,iab)*tildem(lorb,iorb,iab)
               enddo
            enddo
         enddo
         
         do irep=1,ndim
            do jrep=1,ndim
               jj=jrep+(irep-1)*ndim
               dmat2(jj)=0.d0
               do lrep=1,ndim
                  ll=jrep+(lrep-1)*ndim
                  dmat2(jj)=dmat2(jj)+dmat1(ll)*wfmat(kk,lrep+(irep-1)*ndim,iab)
               enddo
            enddo
         enddo
         
         do irep=1,ndim
            iorb=irepcol_det(irep,kk,iab)
            do jrep=1,ndim
               jorb=ireporb_det(jrep,kk,iab)                 
               jj=jrep+(irep-1)*ndim
               dymat(jorb,iorb)=dymat(jorb,iorb)+wfmat(kk,jj,iab)*dcdet_equiv(kk)-cdet_equiv(kk)*dmat2(jj)
            enddo
         enddo
         
      enddo
      
      
      return
      end
c-----------------------------------------------------------------------
      subroutine compute_zmat(ymat,dymat,zmat,dzmat,emz,aaz)

      use Bloc,    only: tildem,xmat
      use coefs,   only: norb
      use multidet, only: iactv,ivirt
      use multimat, only: aa
      use precision_kinds, only: dp
      use slater,  only: slmi
      use system,  only: ndn,nelec,nup
      use vmc_mod, only: norb_tot

      implicit none

      integer :: iab, irep, ish, jrep, krep
      integer :: nel

      real(dp), dimension(norb_tot, nelec, 2) :: ymat
      real(dp), dimension(norb_tot, nelec, 2) :: dymat
      real(dp), dimension(norb_tot, nelec, 2) :: zmat
      real(dp), dimension(norb_tot, nelec, 2) :: dzmat
      real(dp), dimension(nelec, nelec, 2) :: emz
      real(dp), dimension(nelec, nelec, 2) :: aaz


      do iab=1,2
        if(iab.eq.2.and.ndn.eq.0) goto 100

        if(iab.eq.1) then
          ish=0
          nel=nup
         else
          ish=nup
          nel=ndn
        endif

        do irep=1,nel
c         do jrep=ivirt(iab),norb+nadorb
          do jrep=ivirt(iab),norb
            zmat(jrep,irep,iab)=0
            dzmat(jrep,irep,iab)=0
            do krep=iactv(iab),nel
              zmat(jrep,irep,iab)=zmat(jrep,irep,iab)+ymat(jrep,krep,iab)*slmi(krep+(irep-1)*nel,iab)
              dzmat(jrep,irep,iab)=dzmat(jrep,irep,iab)+dymat(jrep,krep,iab)*slmi(krep+(irep-1)*nel,iab)
     &                                                 -ymat(jrep,krep,iab)*xmat(irep+(krep-1)*nel,iab)
            enddo
          enddo
        enddo

        do irep=1,nel
          do jrep=1,nel
            emz(jrep,irep,iab)=0
            aaz(jrep,irep,iab)=0
c           do krep=ivirt(iab),norb+nadorb
            do krep=ivirt(iab),norb
              emz(jrep,irep,iab)=emz(jrep,irep,iab)+tildem(jrep,krep,iab)*zmat(krep,irep,iab)
     &                           +aa(jrep,krep,iab)*dzmat(krep,irep,iab)
              aaz(jrep,irep,iab)=aaz(jrep,irep,iab)+aa(jrep,krep,iab)*zmat(krep,irep,iab)
            enddo
          enddo
        enddo

  100 continue
      enddo

      return
      end
c-----------------------------------------------------------------------
      subroutine update_ymat(iel)

      use csfs,    only: nstates
      use multimat, only: wfmat
      use multislater, only: detiab
      use system,  only: ndn,nelec,nup
      use ycompact, only: ymat

      implicit none

      integer :: iab, iel, istate





      if((iel.ne.nup.and.iel.ne.nelec).or.ndn.eq.0) return

      if(iel.eq.nup) then
        iab=2
       elseif(iel.eq.nelec) then
        iab=1
      endif

      do istate=1,nstates
 100    call compute_ymat(iab,detiab(1,1),detiab(1,2),wfmat(:,:,iab),ymat(1,1,iab,istate),istate)
      enddo

c     write(ounit,*) 'DU',(detiab(k,1),k=1,56)
c     write(ounit,*) 'DD',(detiab(k,2),k=1,56)
c     write(ounit,*) 'WF',((wfmat(k,i,iab),i=1,9),k=1,56)
c     do j=1,13
c     if(iab.eq.2) write(ounit,*) j,'YMAT 1',(ymat(i,j,iab,1),i=1,96)
c     enddo
c     do j=1,13
c     if(iab.eq.2) write(ounit,*) j,'YMAT 2',(ymat(i,j,iab,2),i=1,96)
c     enddo

      return
      end

c-----------------------------------------------------------------------

c-----------------------------------------------------------------------
      function idiff(j,i,iab)
      use multidet, only: irepcol_det,ireporb_det,numrep_det

      implicit none

      integer :: i, iab, j, k
      integer :: idiff          ! added by Ravindra


      idiff=1
      if(numrep_det(i,iab).ne.numrep_det(j,iab))return
      do k=1,numrep_det(i,iab)
        if(irepcol_det(k,j,iab).ne.irepcol_det(k,i,iab))return
        if(ireporb_det(k,j,iab).ne.ireporb_det(k,i,iab))return
      enddo
      idiff=0
      return
      end

c-----------------------------------------------------------------------
      end module
