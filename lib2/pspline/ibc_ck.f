      subroutine ibc_ck(ibc,slbl,xlbl,imin,imax,ier)

c  check that spline routine ibc flag is in range

      integer ibc                       ! input -- flag value
      character*(*) slbl                ! input -- subroutine name
      character*(*) xlbl                ! input -- axis label

      integer imin                      ! input -- min allowed value
      integer imax                      ! input -- max allowed value

      integer ier                       ! output -- set =1 if error detected

c----------------------

      if((ibc.lt.imin).or.(ibc.gt.imax)) then
         ier=1
         write(6,1001) slbl,xlbl,ibc,imin,imax
 1001    format(' ?',a,' -- ibc',a,' = ',i9,' out of range ',
     >      i2,' to ',i2)
      endif

      return
      end
