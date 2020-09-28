      subroutine jastrow4e(iel,x,v,d2,value,iflag)
c Written by Cyrus Umrigar and Claudia Filippi
c Jastrow 4,5 must be used with one of isc=2,4,6,7,12,14,16,17
c Jastrow 6   must be used with one of isc=6,7
      use force_mod, only: MFORCE, MFORCE_WT_PRD, MWF
      use vmc_mod, only: MELEC, MORB, MBASIS, MDET, MCENT, MCTYPE, MCTYP3X
      use vmc_mod, only: NSPLIN, nrad, MORDJ, MORDJ1, MMAT_DIM, MMAT_DIM2, MMAT_DIM20
      use vmc_mod, only: radmax, delri
      use vmc_mod, only: NEQSX, MTERMS
      use vmc_mod, only: MCENT3, NCOEF, MEXCIT
      use atom, only: iwctype, ncent

      use jaspar, only: sspinn
      use const, only: nelec
      use elec, only: nup
      use jaso, only: d2ijo, d2o, fijo, fjo, fso, fsumo

      use jaspar3, only: a, b, c

      use jaspar4, only: a4, norda, nordb, nordc
      use jaspar6, only: asymp_jasa, asymp_jasb
      use jaspar6, only: cutjas
      use wfsec, only: iwf
      use bparm, only: nocuspb, nspin2b
      use contr2, only: ijas
      use contr2, only: isc
      use jasn, only: d2ijn, d2n, fijn, fjn, fsn, fsumn
      use distance_mod, only: rshift, r_en, rvec_en
      implicit real*8(a-h,o-z)


















      parameter (half=.5d0,eps=1.d-12)

      dimension x(3,*),v(3,*)
      ! common /distance/ rshift(3,MELEC,MCENT),rvec_en(3,MELEC,MCENT),r_en(MELEC,MCENT),rvec_ee(3,MMAT_DIM2),r_ee(MMAT_DIM2)
      ! common /distance/ rshift(3,MELEC,MCENT), rvec_ee(3,MMAT_DIM2),r_ee(MMAT_DIM2)
      ! common /distance/ rvec_en(3,MELEC,MCENT),r_en(MELEC,MCENT)
      common /distance/ rvec_ee(3, MMAT_DIM2), r_ee(MMAT_DIM2)
      dimension uu(-2:MORDJ),ss(-2:MORDJ),tt(-2:MORDJ),rri(-2:MORDJ)
     &,rrj(-2:MORDJ)

      do 5 i=-2,-1
        uu(i)=0
        ss(i)=0
        tt(i)=0
        rri(i)=0
    5   rrj(i)=0
      uu(0)=1
      ss(0)=2
      tt(0)=1
      rri(0)=1
      rrj(0)=1
      if (nelec.lt.2) goto 65

      do 10 i=1,nelec
        do 10 k=1,3
   10   fjn(k,i)=fjo(k,i)
      fsumn=fsumo
      d2n=d2o

      do 60 jj=1,nelec

      if(jj.eq.iel) goto 60
      if(jj.lt.iel) then
        i=iel
        j=jj
       else
        i=jj
        j=iel
      endif
      ij=((i-1)*(i-2))/2+j

      fijn(1,i,j)=0
      fijn(2,i,j)=0
      fijn(3,i,j)=0
      fijn(1,j,i)=0
      fijn(2,j,i)=0
      fijn(3,j,i)=0
      fsn(i,j)=0
      d2ijn(i,j)=0

      sspinn=1
      ipar=0
      isb=1
      if(i.le.nup .or. j.gt.nup) then
        if(nspin2b.eq.2) then
          isb=2
         elseif(nocuspb.eq.0) then
          sspinn=half
        endif
        ipar=1
      endif

      rij=r_ee(ij)

      if(iflag.eq.0) then
        call scale_dist1(rij,uu(1),dd1,1)
       else
        call scale_dist2(rij,uu(1),dd1,dd2,1)
      endif

      if(rij.gt.cutjas) goto 22

      top=sspinn*b(1,isb,iwf)*uu(1)
      topu=sspinn*b(1,isb,iwf)

      bot=1+b(2,isb,iwf)*uu(1)
      botu=b(2,isb,iwf)
      bot2=bot*bot

      fee=top/bot-asymp_jasb(ipar+1)
      feeu=topu/bot-botu*top/bot2

      do 20 iord=2,nordb
        uu(iord)=uu(1)*uu(iord-1)
        fee=fee+b(iord+1,isb,iwf)*uu(iord)
   20   feeu=feeu+b(iord+1,isb,iwf)*iord*uu(iord-1)

      if(iflag.gt.0) then
        topuu=0
        botuu=0
        feeuu=topuu-(botuu*top+2*botu*topu)/bot+2*botu**2*top/bot2
        feeuu=feeuu/bot
        do 21 iord=2,nordb
   21     feeuu=feeuu+b(iord+1,isb,iwf)*iord*(iord-1)*uu(iord-2)
        feeuu=feeuu*dd1*dd1+feeu*dd2
      endif

      feeu=feeu*dd1/rij

      fsn(i,j)=fsn(i,j) + fee

      fijn(1,i,j)=fijn(1,i,j) + feeu*rvec_ee(1,ij)
      fijn(2,i,j)=fijn(2,i,j) + feeu*rvec_ee(2,ij)
      fijn(3,i,j)=fijn(3,i,j) + feeu*rvec_ee(3,ij)
      fijn(1,j,i)=fijn(1,j,i) - feeu*rvec_ee(1,ij)
      fijn(2,j,i)=fijn(2,j,i) - feeu*rvec_ee(2,ij)
      fijn(3,j,i)=fijn(3,j,i) - feeu*rvec_ee(3,ij)

      if(iflag.gt.0) d2ijn(i,j)=d2ijn(i,j) + 2*(feeuu+2*feeu)

c There are no C terms to order 1.
   22 if(nordc.le.1) goto 55

      if(iflag.eq.0) then
        if(isc.ge.12) call scale_dist1(rij,uu(1),dd1,3)
        if(ijas.eq.4.or.ijas.eq.5) call switch_scale1(uu(1),dd1)
       else
        if(isc.ge.12) call scale_dist2(rij,uu(1),dd1,dd2,3)
        if(ijas.eq.4.or.ijas.eq.5) call switch_scale2(uu(1),dd1,dd2)
      endif
      if(ijas.eq.4.or.ijas.eq.5) then
        do 25 iord=2,nordc
   25     uu(iord)=uu(1)*uu(iord-1)
      endif

      do 50 ic=1,ncent
        it=iwctype(ic)

        ri=r_en(i,ic)
        rj=r_en(j,ic)

        if(ri.gt.cutjas .or. rj.gt.cutjas) goto 50
        do 27 k=1,3
   27     if(abs(rshift(k,i,ic)-rshift(k,j,ic)).gt.eps) goto 50

        if(iflag.eq.0) then
          call scale_dist1(ri,rri(1),dd7,2)
          call scale_dist1(rj,rrj(1),dd8,2)
          if(ijas.eq.4.or.ijas.eq.5) then
            call switch_scale1(rri(1),dd7)
            call switch_scale1(rrj(1),dd8)
          endif
         else
          call scale_dist2(ri,rri(1),dd7,dd9,2)
          call scale_dist2(rj,rrj(1),dd8,dd10,2)
          if(ijas.eq.4.or.ijas.eq.5) then
            call switch_scale2(rri(1),dd7,dd9)
            call switch_scale2(rrj(1),dd8,dd10)
          endif
        endif

        do 30 iord=1,nordc
          rri(iord)=rri(1)*rri(iord-1)
          rrj(iord)=rrj(1)*rrj(iord-1)
          ss(iord)=rri(iord)+rrj(iord)
   30     tt(iord)=rri(iord)*rrj(iord)

        fc=0
        fu=0
        fuu=0
        fi=0
        fii=0
        fj=0
        fjj=0
        fui=0
        fuj=0
        ll=0
        do 40 n=2,nordc
          do 40 k=n-1,0,-1
            if(k.eq.0) then
              l_hi=n-k-2
             else
              l_hi=n-k
            endif
            do 40 l=l_hi,0,-1
              m=(n-k-l)/2
              if(2*m.eq.n-k-l) then
                ll=ll+1
                fc=fc+c(ll,it,iwf)*uu(k)*ss(l)*tt(m)
                fu=fu+c(ll,it,iwf)*k*uu(k-1)*ss(l)*tt(m)
                fi=fi+c(ll,it,iwf)*uu(k)
     &          *((l+m)*rri(l+m-1)*rrj(m)+m*rri(m-1)*rrj(l+m))
                fj=fj+c(ll,it,iwf)*uu(k)
     &          *((l+m)*rrj(l+m-1)*rri(m)+m*rrj(m-1)*rri(l+m))

                if(iflag.gt.0) then
                  fuu=fuu+c(ll,it,iwf)*k*(k-1)*uu(k-2)*ss(l)*tt(m)
                  fii=fii+c(ll,it,iwf)*uu(k)
     &            *((l+m)*(l+m-1)*rri(l+m-2)*rrj(m)
     &            +m*(m-1)*rri(m-2)*rrj(l+m))
                  fjj=fjj+c(ll,it,iwf)*uu(k)
     &            *((l+m)*(l+m-1)*rrj(l+m-2)*rri(m)
     &            +m*(m-1)*rrj(m-2)*rri(l+m))
                  fui=fui+c(ll,it,iwf)*k*uu(k-1)
     &            *((l+m)*rri(l+m-1)*rrj(m)+m*rri(m-1)*rrj(l+m))
                  fuj=fuj+c(ll,it,iwf)*k*uu(k-1)
     &            *((l+m)*rrj(l+m-1)*rri(m)+m*rrj(m-1)*rri(l+m))
                endif

              endif
   40   continue

        if(iflag.gt.0) then
          s=ri+rj
          t=ri-rj
          u2pst=rij*rij+s*t
          u2mst=rij*rij-s*t

          fuu=fuu*dd1*dd1+fu*dd2
          fui=fui*dd1*dd7
          fuj=fuj*dd1*dd8
          fii=fii*dd7*dd7+fi*dd9
          fjj=fjj*dd8*dd8+fj*dd10

        endif

        fu=fu*dd1/rij
        fi=fi*dd7/ri
        fj=fj*dd8/rj

        fsn(i,j)=fsn(i,j) + fc

        fijn(1,i,j)=fijn(1,i,j) + fi*rvec_en(1,i,ic)+fu*rvec_ee(1,ij)
        fijn(2,i,j)=fijn(2,i,j) + fi*rvec_en(2,i,ic)+fu*rvec_ee(2,ij)
        fijn(3,i,j)=fijn(3,i,j) + fi*rvec_en(3,i,ic)+fu*rvec_ee(3,ij)
        fijn(1,j,i)=fijn(1,j,i) + fj*rvec_en(1,j,ic)-fu*rvec_ee(1,ij)
        fijn(2,j,i)=fijn(2,j,i) + fj*rvec_en(2,j,ic)-fu*rvec_ee(2,ij)
        fijn(3,j,i)=fijn(3,j,i) + fj*rvec_en(3,j,ic)-fu*rvec_ee(3,ij)

        if(iflag.gt.0) 
     &    d2ijn(i,j)=d2ijn(i,j) + 2*(fuu + 2*fu) + fui*u2pst/(ri*rij)
     &    + fuj*u2mst/(rj*rij) + fii + 2*fi + fjj + 2*fj
   50 continue

   55 fsumn=fsumn+fsn(i,j)-fso(i,j)
      fjn(1,i)=fjn(1,i)+fijn(1,i,j)-fijo(1,i,j)
      fjn(2,i)=fjn(2,i)+fijn(2,i,j)-fijo(2,i,j)
      fjn(3,i)=fjn(3,i)+fijn(3,i,j)-fijo(3,i,j)
      fjn(1,j)=fjn(1,j)+fijn(1,j,i)-fijo(1,j,i)
      fjn(2,j)=fjn(2,j)+fijn(2,j,i)-fijo(2,j,i)
      fjn(3,j)=fjn(3,j)+fijn(3,j,i)-fijo(3,j,i)
      d2n=d2n+d2ijn(i,j)-d2ijo(i,j)
   60 continue

c e-n terms

   65 fijn(1,iel,iel)=0
      fijn(2,iel,iel)=0
      fijn(3,iel,iel)=0
      fsn(iel,iel)=0
      d2ijn(iel,iel)=0

      do 80 ic=1,ncent
        it=iwctype(ic)

        ri=r_en(iel,ic)
        if(ri.gt.cutjas) goto 80

        if(iflag.eq.0) then
          call scale_dist1(ri,rri(1),dd7,1)
         else
          call scale_dist2(ri,rri(1),dd7,dd9,1)
        endif

        top=a4(1,it,iwf)*rri(1)
        topi=a4(1,it,iwf)

        bot=a4(2,it,iwf)*rri(1)
        boti=a4(2,it,iwf)

        bot=1+bot
        bot2=bot*bot
        fen=top/bot-asymp_jasa(it)
        feni=topi/bot-boti*top/bot2

        do 70 iord=2,norda
          rri(iord)=rri(1)**iord
          fen=fen+a4(iord+1,it,iwf)*rri(iord)
   70     feni=feni+a4(iord+1,it,iwf)*iord*rri(iord-1)

        if(iflag.gt.0) then
          topii=0
          botii=0
          fenii=topii-(botii*top+2*boti*topi)/bot+2*boti**2*top/bot2
          fenii=fenii/bot
          do 72 iord=2,norda
   72       fenii=fenii+a4(iord+1,it,iwf)*iord*(iord-1)*rri(iord-2)
          fenii=fenii*dd7*dd7+feni*dd9
        endif

        feni=feni*dd7/ri

        fsn(iel,iel)=fsn(iel,iel)+fen

        fijn(1,iel,iel)=fijn(1,iel,iel) + feni*rvec_en(1,iel,ic)
        fijn(2,iel,iel)=fijn(2,iel,iel) + feni*rvec_en(2,iel,ic)
        fijn(3,iel,iel)=fijn(3,iel,iel) + feni*rvec_en(3,iel,ic)

        if(iflag.gt.0) d2ijn(iel,iel) = d2ijn(iel,iel) + fenii + 2*feni
   80 continue

      fsumn=fsumn+fsn(iel,iel)-fso(iel,iel)
      fjn(1,iel)=fjn(1,iel)+fijn(1,iel,iel)-fijo(1,iel,iel)
      fjn(2,iel)=fjn(2,iel)+fijn(2,iel,iel)-fijo(2,iel,iel)
      fjn(3,iel)=fjn(3,iel)+fijn(3,iel,iel)-fijo(3,iel,iel)
      d2n=d2n+d2ijn(iel,iel)-d2ijo(iel,iel)

      do 110 i=1,nelec
        v(1,i)=fjn(1,i)
        v(2,i)=fjn(2,i)
  110   v(3,i)=fjn(3,i)
      value=fsumn
      d2=d2n

      return
      end
