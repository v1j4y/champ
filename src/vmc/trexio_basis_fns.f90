module trexio_basis_fns_mod
    private :: n0_inc
    public :: trexio_basis_fns
    public :: trexio_phi_combine

    contains
      subroutine trexio_basis_fns(ie1,ie2,rvec_en,r_en,ider)
!     calculate the values of the basis functions and their derivatives
!     ider = 0 -> value
!     ider = 1 -> value, gradient
!     ider = 2 -> value, gradient, laplacian
!     ider = 3 -> value, gradient, laplacian, forces

      use numbas_mod, only: MRWF
      use system, only: iwctype, ncent, ncent_tot
      use system, only: nghostcent
      use numbas, only: iwrwf, nrbas!, rmax
      use numbas1, only: iwlbas, nbastyp
      use phifun, only: phin, dphin, d2phin, d2phin_all, d3phin, n0_nbasis
      use multiple_geo, only: iwf
      use force_analy, only: iforce_analy
      use splfit_mod, only: splfit
      use slm_mod, only: slm
#if defined(TREXIO_FOUND)
      use m_trexio_basis, only: slm_per_l, index_slm, num_rad_per_cent, num_ao_per_cent
#endif

      use precision_kinds, only: dp
      use system, only: nelec
      implicit none

      integer :: it, ic, ider, irb
      integer :: iwlbas0, j, k, nrbasit, nbastypit, nlmbasit
      integer :: ie1, ie2, k0, l, l0, ll, ilm

      real(dp), allocatable         :: y(:)
      real(dp), allocatable         :: dy(:,:)
      real(dp), allocatable         :: ddy(:,:,:)
      real(dp), allocatable         :: ddy_lap(:)
      real(dp), allocatable         :: dlapy(:,:)

      integer                       :: nlmbas(ncent_tot)

      real(dp)                      :: r, r2, ri, ri2
      real(dp)                      :: rvec_en(3, nelec, ncent_tot)
      real(dp)                      :: r_en(nelec, ncent_tot)

      real(dp)                      :: wfv(4, MRWF)
      real(dp)                      :: xc(3)
      real(dp), parameter           :: one = 1.d0

      do j=ie1,ie2
        n0_nbasis(j)=0
      enddo

!     debug
      nlmbas = 0

#if defined(TREXIO_FOUND)
      l=0
!     loop through centers
      do ic=1,ncent+nghostcent

        it=iwctype(ic)
        nrbasit=num_rad_per_cent(it)
        nbastypit=num_ao_per_cent(it)
        nlmbasit = nlmbas(it)

        print*, 'trexio_basis_fns: ic=', ic, ' it=', it, ' nrbasit=', nrbasit, ' nbastypit=', nbastypit, ' nlmbasit=', nlmbasit

        allocate (y(nbastypit))
        allocate (dy(3,nbastypit))
        allocate (ddy(3,3,nbastypit))
        allocate (ddy_lap(nbastypit))
        allocate (dlapy(3,nbastypit))


        l0=l

!     numerical atomic orbitals
        do k=ie1,ie2

!       get distance to center

          xc(1)=rvec_en(1,k,ic)
          xc(2)=rvec_en(2,k,ic)
          xc(3)=rvec_en(3,k,ic)

          r=r_en(k,ic)
          r2=r*r
          ri=one/r
          ri2=ri*ri

          do irb=1,nrbasit
          ! only evaluate for r <= rmax
          ! if (r <= rmax(irb,it)) then
            call splfit(r,irb,it,iwf,wfv(1,irb),ider)
          ! else
          !   wfv(1:4,irb)=0.d0
          ! endif
            ! write(200,*) ic, k, irb, r, r2, ri, ri2, wfv(1,irb)
          enddo

          do ilm=1,nbastypit
              print*, "ilm, iwlbas0", ilm, index_slm(ilm)
              call slm(index_slm(ilm),xc,r2,y(ilm),dy(1,ilm),ddy(1,1,ilm),ddy_lap(ilm),dlapy(1,ilm),ider)
          enddo

          ! do ilm=1,nlmbasit
          !   call slm(iwlbas0,xc,r2,y(ilm),dy(1,ilm),ddy(1,1,ilm),ddy_lap(ilm),dlapy(1,ilm),ider)
          ! enddo

!     compute sml and combine to generate molecular orbitals
           l=l0

           do j=1,nbastypit
              l=l+1
              irb=iwrwf(j,it)
              ilm=iwlbas(j,it)

              call trexio_phi_combine(iwlbas0,xc,ri,ri2,wfv(:,irb), &
                                y(ilm), &
                                dy(:,ilm), &
                                ddy(:,:,ilm), &
                                ddy_lap(ilm), &
                                dlapy(:,ilm), &
                                phin(l,k), &
                                dphin(l,k,:), &
                                d2phin(l,k), &
                                d2phin_all(:,:,l,k), &
                                d3phin(:,l,k), &
                                ider)
              call n0_inc(l,k,ic)
           enddo

        enddo ! loop over electrons

        deallocate (y)
        deallocate (dy)
        deallocate (ddy)
        deallocate (ddy_lap)
        deallocate (dlapy)

      enddo ! loop over all atoms
#endif
      return
      end
!-------------------------------------------------------------------
      subroutine trexio_phi_combine(l,xc,ri,ri2,wfv,y,dy,ddy,ddy_lap,dlapy,phi,dphi,d2phi,d2phi_all,d3phi,ider)
      use precision_kinds, only: dp
      implicit none

      integer :: iforce_analy, ider, ii, jj, l
      real(dp) :: d2phi, ddy_lap, dum, dum1, phi
      real(dp) :: prod, ri, ri2, ri3
      real(dp) :: y
      real(dp), dimension(3) :: xc
      real(dp), dimension(3) :: xcri
      real(dp), dimension(4) :: wfv
      real(dp), dimension(3) :: dy
      real(dp), dimension(3, 3) :: ddy
      real(dp), dimension(3) :: dphi
      real(dp), dimension(3, 3) :: d2phi_all
      real(dp), dimension(3) :: d3phi
      real(dp), dimension(3) :: dlapy
      real(dp), parameter :: two = 2.d0
      real(dp), parameter :: three = 3.d0
      real(dp), parameter :: four = 4.d0
      real(dp), parameter :: five = 5.d0
      real(dp), parameter :: six = 6.d0

!     phi is computed for all ider values
      phi=y*wfv(1)

      if(ider.eq.1) then

        xcri(1)=xc(1)*ri
        xcri(2)=xc(2)*ri
        xcri(3)=xc(3)*ri

        do jj=1,3
          dphi(jj)=y*xcri(jj)*wfv(2)+dy(jj)*wfv(1)
        enddo

      elseif(ider.ge.2) then


        xcri(1)=xc(1)*ri
        xcri(2)=xc(2)*ri
        xcri(3)=xc(3)*ri

        d2phi=y*wfv(3)+y*two*ri*wfv(2)+ddy_lap*wfv(1)
        dum=0.d0
        do jj=1,3
          dphi(jj)=y*xcri(jj)*wfv(2)+dy(jj)*wfv(1)
          dum=dum+dy(jj)*xcri(jj)
        enddo
        d2phi=d2phi+two*dum*wfv(2)


        if(ider.eq.3) then

          do jj=1,3
            dum1=0
            do ii=1,3
              dum1=dum1+ddy(jj,ii)*xcri(ii)
            enddo
            d3phi(jj)=wfv(4)*y*xcri(jj)     &
                      +wfv(3)*(dy(jj)+two*xcri(jj)*(y*ri+dum))   &
                      +wfv(2)*(xcri(jj)*(ddy_lap-two*ri*(dum+y*ri))+two*(dum1+two*dy(jj)*ri)) &
                      +wfv(1)*dlapy(jj)
          enddo

          do jj=1,3
            do ii=jj,3
              prod=xcri(jj)*xcri(ii)
              d2phi_all(ii,jj)=ddy(ii,jj)*wfv(1)+wfv(2)*(dy(ii)*xcri(jj)+dy(jj)*xcri(ii)-y*ri*prod)+wfv(3)*y*prod
              d2phi_all(jj,ii)=d2phi_all(ii,jj)
            enddo
            d2phi_all(jj,jj)=d2phi_all(jj,jj)+y*ri*wfv(2)
          enddo

        endif

      endif

      return
      end
!-------------------------------------------------------------------
      subroutine n0_inc(l,k,ic)

      use phifun, only: phin, dphin, n0_ibasis, n0_ic, n0_nbasis
      implicit none

      integer :: ic, k, l


      if(abs(phin(l,k))+abs(dphin(l,k,1))+abs(dphin(l,k,2))+abs(dphin(l,k,3)).gt.1.d-20)then

       n0_nbasis(k)=n0_nbasis(k)+1
       n0_ibasis(n0_nbasis(k),k)=l
       n0_ic(n0_nbasis(k),k)=ic
      endif

      return
      end
end module
