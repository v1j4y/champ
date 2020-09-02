      subroutine jastrow(x,v,d2,value,ifr)
c Written by Cyrus Umrigar

      use const, only: nelec
      use optwf_contrl, only: ioptjas
      implicit real*8(a-h,o-z)



      include 'vmc.h'
      include 'force.h'
      include 'pseudo.h'



      dimension x(3,*),v(3,*),div_vj(MELEC)

      do 10 i=1,nelec
        div_vj(i)=0
        v(1,i)=0
        v(2,i)=0
   10   v(3,i)=0
      d2=0

      if(ifr.gt.1.or.ioptjas.eq.0) then
        call jastrow4(x,v,d2,div_vj,value)
      else
        call deriv_jastrow4(x,v,d2,value)
      endif

      return
      end
