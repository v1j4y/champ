      subroutine jastrowe(iel,x,v,d2,value,iflag)
c Written by Claudia Filippi by modifying jastrow

      use const, only: pi, hb, etrial, delta, deltai, fbias, nelec, imetro, ipr
      use contr2, only: i3body, ianalyt_lap, iaver, icusp, icusp2, ifock, ijas, irewgt,
     &isc, istrch
      implicit real*8(a-h,o-z)



      include 'vmc.h'

      parameter (zero=0.d0)


      include 'pseudo.h'

      include 'force.h'


      dimension x(3,*),v(3,*)

      do 10 i=1,nelec
        v(1,i)=zero
        v(2,i)=zero
   10   v(3,i)=zero

      call jastrow4e(iel,x,v,d2,value,iflag)

      return
      end
