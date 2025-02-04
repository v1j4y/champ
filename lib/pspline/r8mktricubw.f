      subroutine r8mktricubw(x,nx,y,ny,z,nz,f,nf2,nf3,
     >                    ibcxmin,bcxmin,ibcxmax,bcxmax,inb1x,
     >                    ibcymin,bcymin,ibcymax,bcymax,inb1y,
     >                    ibczmin,bczmin,ibczmax,bczmax,inb1z,
     >                    wk,nwk,ilinx,iliny,ilinz,ier)

c  setup a tricubic spline; store coefficients in compatct form
c  (as per suggestion of L. Zakharov, PPPL, Feb. 1999)
C  8 coeffs per (x,y,z) grid point:
C          f,fxx,fyy,fzz,fxxyy,fxxzz,fyyzz,fxxyyzz

C  input:
!============
! idecl:  explicitize implicit INTEGER declarations:
      IMPLICIT NONE
c     INTEGER, PARAMETER :: R8=SELECTED_REAL_KIND(12,100)
      INTEGER itest,iadfp,isiz1,iadfw,inwk
!============
! idecl:  explicitize implicit REAL declarations:
      REAL*8 hxlast,hylast,hzlast
!============
      integer nx                        ! length of x vector
      integer ny                        ! length of y vector
      integer nz                        ! length of z vector
      REAL*8 x(nx)                        ! x vector, strict ascending
      REAL*8 y(ny)                        ! y vector, strict ascending
      REAL*8 z(nz)                        ! z vector, strict ascending

      integer nf2                       ! 2nd dim. of f array, nf2.ge.nx
      integer nf3                       ! 3rd dim. of f array, nf3.ge.ny

c  input/output:

      REAL*8 f(8,nf2,nf3,nz)              ! data and spline coefficients

C  on input:  f(1,i,j,k) = f(x(i),y(j),z(k))
C  on output:  f(1,i,j,k) unchanged
C              f(2,i,j,k) = d2f/dx2(x(i),y(j),z(k))
C              f(3,i,j,k) = d2f/dy2(x(i),y(j),z(k))
C              f(4,i,j,k) = d2f/dz2(x(i),y(j),z(k))
C              f(5,i,j,k) = d4f/dx2dy2(x(i),y(j),z(k))
C              f(6,i,j,k) = d4f/dx2dz2(x(i),y(j),z(k))
C              f(7,i,j,k) = d4f/dy2dz2(x(i),y(j),z(k))
C              f(8,i,j,k) = d6f/dx2dy2dz2(x(i),y(j),z(k))

C  there is a rather Hermite like interpolation formula to go with
C  this-- see evtricub.for.  Also the bicubic formula is given in
C  mkbicubw.for; the tricubic formula is precisely analogous.

C  boundary condition data
C  inputs:
      integer inb1x                     ! 1st dim of xmin & xmax bc arrays
      integer inb1y                     ! 1st dim of ymin & ymax bc arrays
      integer inb1z                     ! 1st dim of zmin & zmax bc arrays

      integer ibcxmin,ibcxmax           ! BC type flag @xmin, xmax
      integer ibcymin,ibcymax           ! BC type flag @ymin, ymax
      integer ibczmin,ibczmax           ! BC type flag @zmin, zmax

      REAL*8 bcxmin(inb1x,nz),bcxmax(inb1x,nz) ! xmin & xmax BC data, ny x nz
      REAL*8 bcymin(inb1y,nz),bcymax(inb1y,nz) ! ymin & ymax BC data, nx x nz
      REAL*8 bczmin(inb1z,ny),bczmax(inb1z,ny) ! zmin & zmax BC data, nx x ny

c  where BC data is not required, dummy scalars may be passed.
C  the ibc* flags determine whether BC data isneeded.

c  BC data:  bcxmin & bcxmax:  BC vs. y,z @xmin,xmax
C            bcymin & bcymax:  BC vs. x,z @ymin,ymax
C            bczmin & bczmax:  BC vs. x,y @zmin,zmax

c   ibcxmin -- indicator for boundary condition at xmin=x(1):
c    bcxmin(...) -- boundary condition data
c     =-1 -- use periodic boundary condition
c     =0 -- use "not a knot"
c     =1 -- match slope, specified at x(1),y(iy),z(iz) by bcxmin(iy,iz)
c     =2 -- match 2nd derivative, specified at x(1),y(iy),z(iz)
c           by bcxmin(iy,iz
c     =3 -- boundary condition is slope=0 (df/dx=0) at x(1), all y(j)
c     =4 -- boundary condition is d2f/dx2=0 at x(1), all y(j)
c     =5 -- match 1st derivative to 1st divided difference
c     =6 -- match 2nd derivative to 2nd divided difference
c     =7 -- match 3rd derivative to 3rd divided difference
c           (for more detailed definition of BCs 5-7, see the
c           comments of subroutine mkspline)
c   ***NOTE bcxmin(...) referenced ONLY if ibcxmin=1 or ibcxmin=2

c   ibcxmax -- indicator for boundary condition at x(nx):
c    bcxmax(...) -- boundary condition data
c     (interpretation as with ibcxmin, bcxmin)
c     NOTE:  if ibcxmin=-1 then the periodic BC applies on both sides
c            and ibcxmax, bcxmax are ignored.
c   inb1x -- 1st dimension of bcxmin, bcxmax: if ibcxmin or ibcxmax .gt. 0
c            this must be .ge. ny.

c   interpretation of ibcymin,bcymin,ibcymax,bcymax,inb1y
c     is same as with ibcxmin,...

c   interpretation of ibczmin,bczmin,ibczmax,bczmax,inb1z
c     is same as with ibcxmin,...

c   the explicit bdy condition arrays are referenced only if the
c     corresponding "ibc" flag values are set to 1 or 2.

c  workspace:
      integer nwk                       ! size of workspace
      REAL*8 wk(nwk)                      ! workspace array

c  this version requires a very large workspace, nwk.ge.80*nx*ny*nz
c  so as to be able to use tcspline to calculate the spline coefficients.

c  output:
      integer ilinx                     ! x vector equal spacing flag
      integer iliny                     ! y vector equal spacing flag
      integer ilinz                     ! z vector equal spacing flag

c   ilinx -- =1 on output if x(nx) pts are nearly evenly spaced (tol=1e-3)
c   iliny -- =1 on output if y(ny) evenly spaced (tol=1e-3)
c   ilinz -- =1 on output if z(nz) evenly spaced (tol=1e-3)

      integer ier                       ! exit code
c   ier -- completion code, 0 for normal

C-----------------------------------------------------

      itest=80*nx*ny*nz
      if(nwk.lt.itest) then
         write(6,9901) nwk,itest
 9901    format(' ?mktricubw:  workspace too small:'/
     >          '  user supplied:  nwk=',i7,'; need at least:  ',i7/
     >      '  nwk = at least 21*nx*ny is required.')
         ier=1
         return
      endif

      iadfp=1
      isiz1=64*nx*ny*nz
      iadfw=iadfp+isiz1
      inwk = nwk-isiz1

      call r8mktricop(f,nf2,nf3,wk(iadfp),nx,ny,nz)

C  evaluate 4x4x4 continuous tricubic spline

      call r8tcspline(x,nx,y,ny,z,nz,wk(iadfp),nx,ny,
     >   ibcxmin,bcxmin,ibcxmax,bcxmax,inb1x,
     >   ibcymin,bcymin,ibcymax,bcymax,inb1y,
     >   ibczmin,bczmin,ibczmax,bczmax,inb1z,
     >   wk(iadfw),inwk,ilinx,iliny,ilinz,ier)

C  convert to 8-coefficient form

      hxlast=x(nx)-x(nx-1)
      hylast=y(ny)-y(ny-1)
      hzlast=z(nz)-z(nz-1)
      call r8mktricon(f,nf2,nf3,wk(iadfp),nx,ny,nz,hxlast,hylast,hzlast)

      return
      end
C----------------------------------------------------------------
C  mktricop -- copy spline function input data

      subroutine r8mktricop(fin,nf2,nf3,fwk,nx,ny,nz)

!============
! idecl:  explicitize implicit INTEGER declarations:
      IMPLICIT NONE
c     INTEGER, PARAMETER :: R8=SELECTED_REAL_KIND(12,100)
      INTEGER nf3,nx,ny,nz,nf2,iz,iy,ix
!============
      REAL*8 fin(8,nf2,nf3,nz)
      REAL*8 fwk(4,4,4,nx,ny,nz)

      do iz=1,nz
         do iy=1,ny
            do ix=1,nx
               fwk(1,1,1,ix,iy,iz)=fin(1,ix,iy,iz)
            enddo
         enddo
      enddo

      return
      end
C----------------------------------------------------------------
C  mktricon -- create compact spline representation from 4x4
C             (bcspline) representation

      subroutine r8mktricon(fin,nf2,nf3,fwk,nx,ny,nz,
     >   hxlast,hylast,hzlast)

!============
! idecl:  explicitize implicit INTEGER declarations:
      IMPLICIT NONE
c     INTEGER, PARAMETER :: R8=SELECTED_REAL_KIND(12,100)
      INTEGER nf3,nx,ny,nz,nf2,iz,iy,ix,iflag,ixuse,iyuse,izuse,j
!============
! idecl:  explicitize implicit REAL declarations:
      REAL*8 hxlast,hylast,hzlast,dxuse,dyuse,dzuse
!============
      REAL*8 fin(8,nf2,nf3,nz)
      REAL*8 fwk(4,4,4,nx,ny,nz)
C-----------------------------------------------------
C  local arrays

      integer iselect(10)
      REAL*8 zvalues(10)

      data iselect/-1,0,0,0,0,0,0,0,0,0/

C-----------------------------------------------------

      do iz=1,nz
         do iy=1,ny
            do ix=1,nx

C  copy derivatives from result.  Special treatment needed for end zones

               iflag=0
               dxuse=0.0d0
               dyuse=0.0d0
               dzuse=0.0d0
               ixuse=ix
               iyuse=iy
               izuse=iz

               if(ix.eq.nx) then
                  iflag=1
                  dxuse=hxlast
                  ixuse=ix-1
               endif
               if(iy.eq.ny) then
                  iflag=1
                  dyuse=hylast
                  iyuse=iy-1
               endif
               if(iz.eq.nz) then
                  iflag=1
                  dzuse=hzlast
                  izuse=iz-1
               endif

               if(iflag.eq.1) then
                  call r8tcspevfn(iselect,1,1,zvalues,
     >               ixuse,iyuse,izuse,dxuse,dyuse,dzuse,
     >               fwk,nx,ny,nz)
                  do j=2,8
                     fin(j,ix,iy,iz)=zvalues(j)
                  enddo
               else
                  fin(2,ix,iy,iz)=2.0d0*fwk(3,1,1,ix,iy,iz)
                  fin(3,ix,iy,iz)=2.0d0*fwk(1,3,1,ix,iy,iz)
                  fin(4,ix,iy,iz)=2.0d0*fwk(1,1,3,ix,iy,iz)
                  fin(5,ix,iy,iz)=4.0d0*fwk(3,3,1,ix,iy,iz)
                  fin(6,ix,iy,iz)=4.0d0*fwk(3,1,3,ix,iy,iz)
                  fin(7,ix,iy,iz)=4.0d0*fwk(1,3,3,ix,iy,iz)
                  fin(8,ix,iy,iz)=8.0d0*fwk(3,3,3,ix,iy,iz)
               endif

            enddo
         enddo
      enddo

      return
      end
