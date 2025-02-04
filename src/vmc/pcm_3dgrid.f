      module pcm_3dgrid_mod
      use error,   only: fatal_error
      interface !interface to pspline
      subroutine r8fvtricub(ict,ivec,ivecd,
     >  fval,ii,jj,kk,xparam,yparam,zparam,
     >  hx,hxi,hy,hyi,hz,hzi,
     >  fin,inf2,inf3,nz)
        IMPLICIT NONE
        INTEGER inf3,nz,inf2
        integer ict(10)                   ! requested output control
        integer ivec                      ! vector length
        integer ivecd                     ! vector dimension (1st dim of fval)
        integer ii,jj,kk ! target cells (i,j,k)
        real(8) xparam,yparam,zparam ! normalized displacements from (i,j,k) corners
        real(8) hx,hy,hz   ! grid spacing, and
        real(8) hxi,hyi,hzi ! inverse grid spacing
                           ! 1/(x(i+1)-x(i)) & 1/(y(j+1)-y(j)) & 1/(z(k+1)-z(i))
        real(8) fin(0:7,inf2,inf3,nz)        ! interpolant data (cf "evtricub")
        real(8) fval(10)               ! output returned
      end subroutine

      subroutine r8mktricubw(x,nx,y,ny,z,nz,f,nf2,nf3,
     >                    ibcxmin,bcxmin,ibcxmax,bcxmax,inb1x,
     >                    ibcymin,bcymin,ibcymax,bcymax,inb1y,
     >                    ibczmin,bczmin,ibczmax,bczmax,inb1z,
     >                    wk,nwk,ilinx,iliny,ilinz,ier)

      IMPLICIT NONE
      integer nx                        ! length of x vector
      integer ny                        ! length of y vector
      integer nz                        ! length of z vector
      real(8) x(nx)                        ! x vector, strict ascending
      real(8) y(ny)                        ! y vector, strict ascending
      real(8) z(nz)                        ! z vector, strict ascending
      integer nf2                       ! 2nd dim. of f array, nf2.ge.nx
      integer nf3                       ! 3rd dim. of f array, nf3.ge.ny
      real(8) f(8,nf2,nf3,nz)              ! data and spline coefficients
      integer inb1x                     ! 1st dim of xmin & xmax bc arrays
      integer inb1y                     ! 1st dim of ymin & ymax bc arrays
      integer inb1z                     ! 1st dim of zmin & zmax bc arrays
      integer ibcxmin,ibcxmax           ! BC type flag @xmin, xmax
      integer ibcymin,ibcymax           ! BC type flag @ymin, ymax
      integer ibczmin,ibczmax           ! BC type flag @zmin, zmax
      real(8) bcxmin(inb1x,nz),bcxmax(inb1x,nz) ! xmin & xmax BC data, ny x nz
      real(8) bcymin(inb1y,nz),bcymax(inb1y,nz) ! ymin & ymax BC data, nx x nz
      real(8) bczmin(inb1z,ny),bczmax(inb1z,ny) ! zmin & zmax BC data, nx x ny
      integer nwk                       ! size of workspace
      real(8) wk(nwk)                      ! workspace array
      integer ilinx                     ! x vector equal spacing flag
      integer iliny                     ! y vector equal spacing flag
      integer ilinz                     ! z vector equal spacing flag
      integer ier                       ! exit code
      end subroutine
      end interface
      contains
c 3d grid module
c Created by Amovilli/Floris following subroutines by Scemama
c Example of input:
c
c &pcm nx_pcm 30 ny_pcm 30 nz_pcm 30
c &pcm dx_pcm .1 dy_pcm .1 dz_pcm .1
c
c The following are computed if they are not present in the input.
c &pcm x0_pcm 0. y0_pcm 0. z0_pcm 0.
c &pcm xn_pcm 1. yn_pcm 1. zn_pcm 1.
c----------------------------------------------------------------------
      subroutine pcm_setup_grid

      use contrl_file, only: ounit
      use grid3d_param, only: origin
      use pcm_3dgrid, only: IUNDEFINED,MGRID_PCM,PCM_SHIFT,UNDEFINED
      use pcm_grid3d_array, only: pcm_cart_from_int
      use pcm_grid3d_param, only: ipcm_nstep3d,pcm_endpt,pcm_origin
      use pcm_grid3d_param, only: pcm_step3d
      use precision_kinds, only: dp
      use system,  only: cent,ncent
      implicit none

      integer :: i, iaxis, ibcxmax, ibcxmin, ibcymax
      integer :: ibcymin, ibczmax, ibczmin, ilinx
      integer :: iliny, ilinz, input_ok, iok
      integer :: ipcm_grid, ipcm_int_from_cart, iu, iy
      integer :: iz, j, memory, nwk
      real(dp) :: pepol_s, pepol_v, value
      real(dp), dimension(3) :: r

c Test if the input is consistent
       input_ok=1
       do i=1,3
        if(ipcm_nstep3d(i).eq.IUNDEFINED.and.pcm_step3d(i).eq.UNDEFINED) then
          write(ounit,*) 'ipcm_nstep3d(',i,') and pcm_step3d(',i,') are undefined'
          input_ok=0
        endif
        if(pcm_origin(i).gt.pcm_endpt(i)) then
         write(ounit,*) 'The pcm_origin coordinates have to be smaller than the end points'
         input_ok=0
        endif
       enddo

       if(input_ok.ne.1) call fatal_error('PCM_3DGRID: 3D Grid input inconsistent')

c Origin and end of the grid. If not in input, compute it from the atomic coordinates.
       do i=1,3
        if(pcm_origin(i).eq.UNDEFINED) then
          pcm_origin(i)=cent(i,1)
          do j=2,ncent
            if(cent(i,j).lt.pcm_origin(i)) pcm_origin(i) = cent(i,j)
          enddo
          pcm_origin(i)=pcm_origin(i)-PCM_SHIFT
        endif

        if(pcm_endpt(i).eq.UNDEFINED) then
          pcm_endpt(i)=cent(i,1)
          do j=2,ncent
            if(cent(i,j).gt.pcm_endpt(i)) pcm_endpt(i)=cent(i,j)
          enddo
          pcm_endpt(i)=pcm_endpt(i)+PCM_SHIFT
        endif
       enddo

c If the step is undefined, use the value in ipcm_nstep3d to compute it.
c Else, compute the value of ipcm_nstep3d
       do i=1, 3
        if(pcm_step3d(i).eq.UNDEFINED) then
         pcm_step3d(i)=(pcm_endpt(i)-pcm_origin(i))/(ipcm_nstep3d(i)-1)
        else
         ipcm_nstep3d(i)=int((pcm_endpt(i)-pcm_origin(i))/pcm_step3d(i))+1
        endif

        if (ipcm_nstep3d(i).gt.MGRID_PCM) then
         write(ounit,*) 'Warning: using ipcm_nstep3d(',i,') = ',MGRID_PCM
         ipcm_nstep3d(i)=MGRID_PCM
         pcm_endpt(i)=MGRID_PCM*pcm_step3d(i)+pcm_origin(i)
        endif
       enddo

c Prepare the integer->cartesian array
       do i=1,3
        do j=1,ipcm_nstep3d(i)
         pcm_cart_from_int(j,i)=pcm_origin(i)+(j-1)*pcm_step3d(i)
        enddo
       enddo

c Update the end point
       do i=1,3
         pcm_endpt(i)=pcm_cart_from_int(ipcm_nstep3d(i),i)
       enddo

CACTIVATE
c     endif

c     Print the parameters to the output file

      write(ounit,*)
      write(ounit,'(''pcm 3D grid parameters'')')
      write(ounit,*)
      write(ounit,'(''pcm origin and end points'')')
      write(ounit,'(3(F10.6, 3X))') ( pcm_origin(i), i=1,3 )
      write(ounit,'(3(F10.6, 3X))') ( pcm_endpt (i), i=1,3 )
      write(ounit,'(''pcm number of steps'')')
      write(ounit,'(3(I5, 3X))') ( ipcm_nstep3d(i), i=1,3 )
      write(ounit,'(''pcm step sizes'')')
      write(ounit,'(3(F10.6, 3X))') ( pcm_step3d (i), i=1,3 )
      write(ounit,*)

      end ! subroutine pcm_setup_grid
c----------------------------------------------------------------------
      function ipcm_int_from_cart(value,iaxis)

      use pcm_3dgrid, only: IUNDEFINED
      use pcm_grid3d_param, only: pcm_endpt,pcm_origin,pcm_step3d
      use precision_kinds, only: dp

      implicit none

      integer :: i, iaxis, ibcxmax, ibcxmin, ibcymax
      integer :: ibcymin, ibczmax, ibczmin, ilinx
      integer :: iliny, ilinz, iok, ipcm_grid
      integer :: ipcm_int_from_cart, irstar, iu, iy
      integer :: iz, j, memory, nwk
      real(dp) :: pepol_s, pepol_v, value
      real(dp), dimension(3) :: r


      if (value.lt.pcm_origin(iaxis).or.value.ge.pcm_endpt(iaxis)) then
        ipcm_int_from_cart = IUNDEFINED
       else
        ipcm_int_from_cart=int((value-pcm_origin(iaxis))/pcm_step3d(iaxis)+1.0)
      endif

      end ! subroutine ipcm_int_from_cart
c----------------------------------------------------------------------
c PCM on a 3d grid with spline fit
      subroutine pcm_setup_3dspl

      use m_pcm_num_spl, only: pcm_num_spl
      use pcm_3dgrid, only: MGRID_PCM,MGRID_PCM3
      use pcm_grid3d_array, only: pcm_cart_from_int
      use pcm_grid3d_param, only: ipcm_nstep3d
      use precision_kinds, only: dp

      implicit none

      integer :: i, ibcxmax, ibcxmin, ibcymax, ibcymin
      integer :: ibczmax, ibczmin, ilinx, iliny
      integer :: ilinz, iok, ipcm_grid, ipcm_int_from_cart
      integer :: irstar, iu, iy, iz
      integer :: j, k, l, memory
      integer :: nwk, ier, ix
      real(dp) :: pepol_s, pepol_v
      real(dp), dimension(3) :: r


c     Note:
c     The boundary condition array ranges from 3 to 8. This way, if we code
c     x=1, y=2 and z=3, the 3rd dimension is the sum of the values
c     corresponding to the axes defining the plane.
c     For the maximum boundary, add 3 :
c     xy_min = 1+2 = 3
c     xz_min = 1+3 = 4
c     yz_min = 2+3 = 5
c     xy_max = 1+2+3 = 6
c     xz_max = 1+3+3 = 7
c     yz_max = 2+3+3 = 8
      real(8)  bc(MGRID_PCM,MGRID_PCM,3:8), wk(80*MGRID_PCM3)


      iok=1
c We have no info on the derivatives, so use "not a knot" in the creation of the fit
      ibcxmin=0
      ibcxmax=0
      ibcymin=0
      ibcymax=0
      ibczmin=0
      ibczmax=0

c Evaluate the energy needed for the calculation
      memory=dble(8)
      memory=memory*dble(ipcm_nstep3d(1)*ipcm_nstep3d(2)*ipcm_nstep3d(3))
      memory=memory*8.d-6
      write(45,*) 'Allocated memory for the 3D spline fit of PCM:', memory, 'Mb'

      if(irstar.ne.1) then
       write(45,*) 'Computation of the grid points...'
       do ix=1,ipcm_nstep3d(1)
          r(1)=pcm_cart_from_int(ix,1)

          do iy=1,ipcm_nstep3d(2)
            r(2)=pcm_cart_from_int(iy,2)

            do iz=1,ipcm_nstep3d(3)
              r(3) =pcm_cart_from_int(iz,3)

c Calculate the value of the pcm potential on the position [r(1),r(2),r(3)]
              call pcm_extpot_ene_elec(r,pepol_s,pepol_v)
              pcm_num_spl(1,ix,iy,iz)=pepol_s+pepol_v
            enddo
          enddo
       enddo

       nwk=80*ipcm_nstep3d(1)*ipcm_nstep3d(2)*ipcm_nstep3d(3)
       ier=0
       call r8mktricubw(pcm_cart_from_int(1,1),ipcm_nstep3d(1),
     &                  pcm_cart_from_int(1,2),ipcm_nstep3d(2),
     &                  pcm_cart_from_int(1,3),ipcm_nstep3d(3),
     &                  pcm_num_spl,MGRID_PCM,MGRID_PCM,
     &                  ibcxmin,bc(1,1,2+3),
     &                  ibcxmax,bc(1,1,2+3+3),MGRID_PCM,
     &                  ibcymin,bc(1,1,1+3),
     &                  ibcymax,bc(1,1,1+3+3),MGRID_PCM,
     &                  ibczmin,bc(1,1,1+2),
     &                  ibczmax,bc(1,1,1+2+3),MGRID_PCM,
     &                  wk,nwk,ilinx,iliny,ilinz,ier)
        if(ier.eq.1) call fatal_error ('Error in r8mktricubw')
      endif ! (irstar.ne.0)

c DEBUG
c      do 30 ix=1,ipcm_nstep3d(1)
c         r(1)=pcm_cart_from_int(ix,1)
c         do 30 iy=1,ipcm_nstep3d(2)
c           r(2)=pcm_cart_from_int(iy,2)
c           do 30 iz=1,ipcm_nstep3d(3)
c             r(3) =pcm_cart_from_int(iz,3)
c
c             call pcm_extpot_ene_elec(r,pepol_s,pepol_v)
c             call spline_pcm(r,value,ier)
c  30         write(ounit,*) 'DEBUG',pepol_s+pepol_v, value
c      stop
      end ! subroutine pcm_setup_3dspl

c----------------------------------------------------------------------
      subroutine spline_pcm(r,f,ier)

      use insout,  only: inout,inside
      use m_pcm_num_spl, only: pcm_num_spl
      use pcm_3dgrid, only: IUNDEFINED,MGRID_PCM
      use pcm_grid3d_array, only: pcm_cart_from_int
      use pcm_grid3d_param, only: ipcm_nstep3d,pcm_step3d

      implicit none

      integer :: i, ipcm_grid, iu, j
      integer :: k, l

c     Input:
      real(8)    r(3)    ! Cartesian coordinates
c     Output:
      integer   ier     ! error status
      real(8)    f       ! Value

c     Work:
      integer   ict(10)   ! Control of the spline subroutine
      integer   ix(3)     ! Integer coordinates
      real(8)    fval(10)  ! values returned by the spline routine
      real(8)    rscaled(3)! normalized displacement
      real(8)    inv_step3d(3) ! Inverse of step sizes


      inout=inout+1.d0
      if (ier.eq.1) then
        return
      endif

      ict(1)=1
      do i=1,3
       ix(i) = ipcm_int_from_cart(r(i),i)
      enddo

      if ((ix(1).eq.IUNDEFINED ).or.(ix(2).eq.IUNDEFINED).or.(ix(3).eq.IUNDEFINED)) then
        ier=1
      else
        inside = inside+1.d0
        do i=2,10
         ict(i)=0
        enddo

        do i=1,3
         inv_step3d(i) = 1.d0/pcm_step3d(i)
        enddo
        do i=1,3
         rscaled(i)=(r(i)-pcm_cart_from_int(ix(i),i))*inv_step3d(i)
        enddo

       call r8fvtricub(ict,1,1,fval,
     &                  ix(1),ix(2),ix(3),
     &                  rscaled(1),rscaled(2),rscaled(3),
     &                  pcm_step3d(1),inv_step3d(1),
     &                  pcm_step3d(2),inv_step3d(2),
     &                  pcm_step3d(3),inv_step3d(3),
     &                  pcm_num_spl,
     &                  MGRID_PCM,MGRID_PCM,ipcm_nstep3d(3))

        f=fval(1)
      endif
      end ! subroutine spline_pcm

c-----------------------------------------------------------------------
      subroutine pcm_3dgrid_dump(iu)

      use pcm_cntrl, only: ipcm
      use pcm_grid3d_array, only: pcm_cart_from_int
      use pcm_grid3d_param, only: ipcm_nstep3d,pcm_endpt,pcm_origin
      use pcm_grid3d_param, only: pcm_step3d

      implicit none

      integer :: iu, i, j, ipcm_grid

      if (ipcm.eq.0.or.ipcm_grid.eq.0) return

      write (iu) (pcm_origin(i), i=1,3)
      write (iu) (pcm_endpt(i), i=1,3)
      write (iu) (ipcm_nstep3d(i), i=1,3)
      write (iu) (pcm_step3d(i), i=1,3)
      write (iu) ((pcm_cart_from_int(i,j), i=1,ipcm_nstep3d(j)),j=1,3)

      call splpcm_dump(iu)

      end
c-----------------------------------------------------------------------
      subroutine pcm_3dgrid_rstrt(iu)

      use pcm_cntrl, only: ipcm
      use pcm_grid3d_array, only: pcm_cart_from_int
      use pcm_grid3d_param, only: ipcm_nstep3d,pcm_endpt,pcm_origin
      use pcm_grid3d_param, only: pcm_step3d

      implicit none

      integer :: iu, i, j, ipcm_grid

      if (ipcm.eq.0.or.ipcm_grid.eq.0) return

      read (iu) (pcm_origin(i), i=1,3)
      read (iu) (pcm_endpt(i), i=1,3)
      read (iu) (ipcm_nstep3d(i), i=1,3)
      read (iu) (pcm_step3d(i), i=1,3)
      read (iu) ((pcm_cart_from_int(i,j), i=1,ipcm_nstep3d(j)),j=1,3)

      call splpcm_rstrt(iu)
      end
c-----------------------------------------------------------------------
      subroutine splpcm_dump(iu)

      use m_pcm_num_spl, only: pcm_num_spl
      use pcm_grid3d_param, only: ipcm_nstep3d

      implicit none

      integer :: iu, i, j, k, l

      do i=1,8
        write(iu)(((pcm_num_spl(i,j,k,l),j=1,ipcm_nstep3d(1)),k=1,ipcm_nstep3d(2)), l=1,ipcm_nstep3d(3))
      enddo

      end
c-----------------------------------------------------------------------
      subroutine splpcm_rstrt(iu)
      use m_pcm_num_spl, only: pcm_num_spl
      use pcm_grid3d_param, only: ipcm_nstep3d

      implicit none

      integer :: iu, i, j, k, l

      do i=1,8
        read(iu)(((pcm_num_spl(i,j,k,l),j=1,ipcm_nstep3d(1)),k=1,ipcm_nstep3d(2)),l=1,ipcm_nstep3d(3))
      enddo
      end
c-----------------------------------------------------------------------
      subroutine pcm_extpot_ene_elec(x,pepol_s,pepol_v)
c Written by Amovilli-Floris
c......................................................
c       Calculate e-qpol interactions (pcm)
c       and adds nuclei-qpol interactions
c......................................................

      use pcm_fdc, only: rcol,rcolv
      use pcm_parms, only: ch,nch,nchs,xpol
      use precision_kinds, only: dp

      implicit none

      integer :: j
      real(dp) :: AV, GC, PI, pepol_s, pepol_v
      real(dp) :: r2, repol, xx, yy
      real(dp) :: zz
      real(dp), dimension(3) :: x



      DATA PI/3.1415927D0/,GC/1.9872159D0/,AV/0.60228D0/

      pepol_s=0.0d0
c......................................................
c     interaction with surface point charges
c......................................................
      do j=1,nchs
        xx=(x(1)-xpol(1,j))**2.0d0
        yy=(x(2)-xpol(2,j))**2.0d0
        zz=(x(3)-xpol(3,j))**2.0d0
        r2=xx+yy+zz
        repol=dsqrt(r2)
c......................................................
c    corrections for collisions electrons-qpol
c......................................................
        if (repol.lt.rcol) repol=rcol
        pepol_s=pepol_s-0.5d0*ch(j)/repol
      enddo

c......................................................
c     interaction with volume point charges
c......................................................
      pepol_v=0.0d0
      do j=nchs+1,nch
        xx=(x(1)-xpol(1,j))**2.0d0
        yy=(x(2)-xpol(2,j))**2.0d0
        zz=(x(3)-xpol(3,j))**2.0d0
        r2=xx+yy+zz
        repol=dsqrt(r2)
c......................................................
c    corrections for collisions electrons-qpol

c......................................................
        if (repol.lt.rcolv) repol=rcolv
        pepol_v=pepol_v-0.5d0*ch(j)/repol
      enddo

      return
      end
c-----------------------------------------------------------------------
      end module
