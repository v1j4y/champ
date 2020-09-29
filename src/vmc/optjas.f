      subroutine optjas_deloc(psid,energy,dvpsp_dj,vj)

      use optjas, only: MPARMJ
      use vmc_mod, only: MELEC, MORB, MDET
      use vmc_mod, only: MMAT_DIM
      use const, only: hb, nelec, ipr
      use csfs, only: nstates
      use derivjas, only: d2g, g
      use dets, only: cdet, ndet
      use elec, only: ndn, nup
      use multidet, only: irepcol_det, ireporb_det, ivirt, iwundet, kref, numrep_det
      use optwf_contrl, only: ioptjas
      use optwf_parms, only: nparmj
      use scratch, only: denergy_det, dtildem
      use Bloc, only: xmat
      use Bloc, only: b_dj
      use coefs, only: norb
      use deloc_dj_m, only: denergy
      use multimat, only: wfmat


      use orbval, only: ddorb, dorb, nadorb, ndetorb, orb
      use slater, only: d2dx2, ddx, fp, fpp, slmi

      use multislater, only: detiab
      implicit real*8(a-h,o-z)






      dimension psid(*),dvpsp_dj(*),energy(*),vj(3,*)
      dimension deloc_dj(MPARMJ)

      if(ioptjas.eq.0) return

      do 200 iparm=1,nparmj

        deloc_dj(iparm)=dvpsp_dj(iparm)
        do i=1,nelec
          deloc_dj(iparm)=deloc_dj(iparm)
     &     -2.d0*hb*(g(1,i,iparm)*ddx(1,i)+g(2,i,iparm)*ddx(2,i)+g(3,i,iparm)*ddx(3,i))
        enddo

        deloc_dj_kref=deloc_dj(iparm)
        do 100 istate=1,nstates
 100      denergy(iparm,istate)=cdet(kref,istate,1)*deloc_dj_kref*detiab(kref,1)*detiab(kref,2)

C       test=0
C       do j=1,nup
C         do i=1,nup
C           test=test+slmi(j+(i-1)*nup,1)*b_dj(j,i,iparm)
C           test=test+slmi(j+(i-1)*ndn,2)*b_dj(j,i+nup,iparm)
C         enddo
C       enddo

        if(ndet.gt.1) then

        call bxmatrix(kref,xmat(1,1),xmat(1,2),b_dj(1,1,iparm))

        do iab=1,2
          if(iab.eq.1) then
            ish=0
            nel=nup
           else
            ish=nup
            nel=ndn
          endif
          do jrep=ivirt(iab),norb
              do irep=1,nel
  
                dum2=0.d0
                dum3=0.d0
                do i=1,nel
                 dum2=dum2+slmi(irep+(i-1)*nel,iab)*b_dj(jrep,i+ish,iparm)
                 dum3=dum3+xmat(i+(irep-1)*nel,iab)*orb(i+ish,jrep)
                enddo
                dtildem(irep,jrep,iab)=dum2-dum3

              enddo
          enddo
        enddo

        denergy_det(kref,1)=0.d0
        denergy_det(kref,2)=0.d0
        do k=1,ndet

          if(k.ne.kref) then

          do iab=1,2

          if(iwundet(k,iab).eq.k) then

            iel=0
            nel=nup
            if(iab.eq.2) then
              iel=nup
              nel=ndn
            endif
            ndim=numrep_det(k,iab)

            denergy_det(k,iab)=0
            do irep=1,ndim
              iorb=irepcol_det(irep,k,iab)
              do jrep=1,ndim
                jorb=ireporb_det(jrep,k,iab)
                denergy_det(k,iab)=denergy_det(k,iab)+wfmat(jrep+(irep-1)*ndim,k,iab)*dtildem(iorb,jorb,iab)
              enddo
            enddo

          else
            index_det=iwundet(k,iab)

            denergy_det(k,iab)=denergy_det(index_det,iab)
          endif
          
          enddo

          deloc_dj_k=denergy_det(k,1)+denergy_det(k,2)+deloc_dj_kref

          do istate=1,nstates
             denergy(iparm,istate)=denergy(iparm,istate)+cdet(k,istate,1)*deloc_dj_k*detiab(k,1)*detiab(k,2)
          enddo

          endif
c endif k.ne.kref

        enddo

        endif
c endif ndet.gt.1

c d2j = d_j lapl(ln J) = d_j (lapl(J)/J) - 2 d_j (grad(J)/J) * grad(J)/J
        term_jas=d2g(iparm)
        do i=1,nelec
          term_jas=term_jas+2.d0*(g(1,i,iparm)*vj(1,i)+g(2,i,iparm)*vj(2,i)+g(3,i,iparm)*vj(3,i))
        enddo
        term_jas=-hb*term_jas

        do 200 istate=1,nstates
          denergy(iparm,istate)=term_jas+denergy(iparm,istate)/psid(istate)
 200  continue

      if(ipr.gt.3) then
        do istate=1,nstates
          write(6,*) 'derivatives of local energy: ',(denergy(iparm,istate),iparm=1,nparmj)
        enddo
      endif

      return
      end
c-----------------------------------------------------------------------
      subroutine optjas_sum(wtg_new,wtg_old,enew,eold,iflag)
c Written by Claudia Filippi

      use atom, only: nctype

      use csfs, only: nstates

      use derivjas, only: gvalue

      use gradhessjo, only: d1d2a_old, d1d2b_old, d2d2a_old, d2d2b_old, denergy_old, gvalue_old

      use ijasnonlin, only: d1d2a, d1d2b, d2d2a, d2d2b
      use jaspointer, only: npointa
      use optwf_contrl, only: ioptjas
      use optwf_nparmj, only: nparma, nparmb
      use optwf_parms, only: nparmj
      use optwf_wjas, only: iwjasa, iwjasb
      use bparm, only: nspin2b
      use deloc_dj_m, only: denergy
      use gradhessj, only: d2j, d2j_e, de, de_de, de_e, dj, dj_de, dj_dj, dj_dj_e, dj_e, dj_e2
      use gradhessj, only: e2
      implicit real*8(a-h,o-z)



















      dimension enew(*),eold(*),wtg_new(*),wtg_old(*)

      if(ioptjas.eq.0) return

      do 100 istate=1,nstates
      p=wtg_new(istate)

      do 10 i=1,nparmj
        dj(i,istate)=dj(i,istate)      +p*gvalue(i)
        de(i,istate)=de(i,istate)      +p*denergy(i,istate)
        dj_e(i,istate)=dj_e(i,istate)  +p*gvalue(i)*enew(istate)
        de_e(i,istate)=de_e(i,istate)  +p*denergy(i,istate)*enew(istate)
        dj_e2(i,istate)=dj_e2(i,istate)+p*gvalue(i)*enew(istate)**2
        e2(i,istate)=e2(i,istate)      +p*enew(istate)**2
        do 10 j=1,i
          dj_dj(i,j,istate)=dj_dj(i,j,istate)           +p*gvalue(i)*gvalue(j)
          dj_de(i,j,istate)=dj_de(i,j,istate)           +p*gvalue(i)*denergy(j,istate)
          if(j.lt.i) dj_de(j,i,istate)=dj_de(j,i,istate)+p*gvalue(j)*denergy(i,istate)
          dj_dj_e(i,j,istate)=dj_dj_e(i,j,istate)       +p*gvalue(i)*gvalue(j)*enew(istate)
   10     de_de(i,j,istate)=de_de(i,j,istate)           +p*denergy(i,istate)*denergy(j,istate)

      do 20 it=1,nctype
        do 20 jparm=1,nparma(it)
          iparm=npointa(it)+jparm
          if(iwjasa(jparm,it).eq.2) then
            d2j(iparm,iparm,istate)=d2j(iparm,iparm,istate)+p*d2d2a(it)
            d2j_e(iparm,iparm,istate)=d2j_e(iparm,iparm,istate)+p*d2d2a(it)*enew(istate)
            do 15 kparm=1,nparma(it)
              if(iwjasa(kparm,it).eq.1) then
                lparm=npointa(it)+kparm
                sav1=p*d1d2a(it)
                sav2=p*d1d2a(it)*enew(istate)
                if(lparm.gt.iparm) then
                  d2j(lparm,iparm,istate)=d2j(lparm,iparm,istate)+sav1
                  d2j_e(lparm,iparm,istate)=d2j_e(lparm,iparm,istate)+sav2
                 else
                  d2j(iparm,lparm,istate)=d2j(iparm,lparm,istate)+sav1
                  d2j_e(iparm,lparm,istate)=d2j_e(iparm,lparm,istate)+sav2
                endif
              endif
   15       continue
          endif
   20 continue
            
      iparm0=npointa(nctype)+nparma(nctype)
      do 30 isb=1,nspin2b
        if(isb.eq.2) iparm0=iparm0+nparmb(1)
        do 30 jparm=1,nparmb(isb)
          iparm=iparm0+jparm
          if(iwjasb(jparm,isb).eq.2) then
            d2j(iparm,iparm,istate)=d2j(iparm,iparm,istate)+p*d2d2b(isb)
            d2j_e(iparm,iparm,istate)=d2j_e(iparm,iparm,istate)+p*d2d2b(isb)*enew(istate)
            do 25 kparm=1,nparmb(isb)
              if(iwjasb(kparm,isb).eq.1) then
                lparm=iparm0+kparm
                sav1=p*d1d2b(isb)
                sav2=p*d1d2b(isb)*enew(istate)
                if(lparm.gt.iparm) then
                  d2j(lparm,iparm,istate)=d2j(lparm,iparm,istate)+sav1
                  d2j_e(lparm,iparm,istate)=d2j_e(lparm,iparm,istate)+sav2
                 else
                  d2j(iparm,lparm,istate)=d2j(iparm,lparm,istate)+sav1
                  d2j_e(iparm,lparm,istate)=d2j_e(iparm,lparm,istate)+sav2
                endif
              endif
   25       continue
          endif
   30 continue

  100 continue

      if(iflag.eq.0) return

      do 200 istate=1,nstates

      q=wtg_old(istate)

      do 40 i=1,nparmj
        dj(i,istate)=dj(i,istate)      +q*gvalue_old(i)
        de(i,istate)=de(i,istate)      +q*denergy_old(i,istate)
        dj_e(i,istate)=dj_e(i,istate)  +q*gvalue_old(i)*eold(istate)
        de_e(i,istate)=de_e(i,istate)  +q*denergy_old(i,istate)*eold(istate)
        dj_e2(i,istate)=dj_e2(i,istate)+q*gvalue_old(i)*eold(istate)**2
        e2(i,istate)=e2(i,istate)      +q*eold(istate)**2
        do 40 j=1,i
          dj_dj(i,j,istate)=dj_dj(i,j,istate)           +q*gvalue_old(i)*gvalue_old(j)
          dj_de(i,j,istate)=dj_de(i,j,istate)           +q*gvalue_old(i)*denergy_old(j,istate)
          if(j.lt.i) dj_de(j,i,istate)=dj_de(j,i,istate)+q*gvalue_old(j)*denergy_old(i,istate)
          dj_dj_e(i,j,istate)=dj_dj_e(i,j,istate)       +q*gvalue_old(i)*gvalue_old(j)*eold(istate)
   40     de_de(i,j,istate)=de_de(i,j,istate)           +q*denergy_old(i,istate)*denergy_old(j,istate)

      do 50 it=1,nctype
        do 50 jparm=1,nparma(it)
          iparm=npointa(it)+jparm
          if(iwjasa(jparm,it).eq.2) then
            d2j(iparm,iparm,istate)=d2j(iparm,iparm,istate)+q*d2d2a_old(it)
            d2j_e(iparm,iparm,istate)=d2j_e(iparm,iparm,istate)+q*d2d2a_old(it)*eold(istate)
            do 45 kparm=1,nparma(it)
              if(iwjasa(kparm,it).eq.1) then
                lparm=npointa(it)+kparm
                sav1=q*d1d2a_old(it)
                sav2=q*d1d2a_old(it)*eold(istate)
                if(lparm.gt.iparm) then
                  d2j(lparm,iparm,istate)=d2j(lparm,iparm,istate)+sav1
                  d2j_e(lparm,iparm,istate)=d2j_e(lparm,iparm,istate)+sav2
                 else
                  d2j(iparm,lparm,istate)=d2j(iparm,lparm,istate)+sav1
                  d2j_e(iparm,lparm,istate)=d2j_e(iparm,lparm,istate)+sav2
                endif
              endif
   45       continue
          endif
   50 continue
            
      iparm0=npointa(nctype)+nparma(nctype)
      do 60 isb=1,nspin2b
        if(isb.eq.2) iparm0=iparm0+nparmb(1)
        do 60 jparm=1,nparmb(isb)
          iparm=iparm0+jparm
          if(iwjasb(jparm,isb).eq.2) then
            d2j(iparm,iparm,istate)=d2j(iparm,iparm,istate)+q*d2d2b_old(isb)
            d2j_e(iparm,iparm,istate)=d2j_e(iparm,iparm,istate)+q*d2d2b_old(isb)*eold(istate)
            do 55 kparm=1,nparmb(isb)
              if(iwjasb(kparm,isb).eq.1) then
                lparm=iparm0+kparm
                sav1=q*d1d2b_old(isb)
                sav2=q*d1d2b_old(isb)*eold(istate)
                if(lparm.gt.iparm) then
                  d2j(lparm,iparm,istate)=d2j(lparm,iparm,istate)+sav1
                  d2j_e(lparm,iparm,istate)=d2j_e(lparm,iparm,istate)+sav2
                 else
                  d2j(iparm,lparm,istate)=d2j(iparm,lparm,istate)+sav1
                  d2j_e(iparm,lparm,istate)=d2j_e(iparm,lparm,istate)+sav2
                endif
              endif
   55       continue
          endif
   60 continue

  200 continue

c     write(6,*) 'HELLO',enew,p,eold,q,(dj_dj_e(nparmj,i),i=1,nparmj)

      return
      end
c-----------------------------------------------------------------------
      subroutine optjas_cum(wsum,enow)
c Written by Claudia Filippi

      use csfs, only: nstates

      use gradjerr, only: dj_bsum, dj_e_bsum, dj_e_save, dj_save, e_bsum, grad_jas_bcm2, grad_jas_bcum

      use optwf_contrl, only: ioptjas
      use optwf_parms, only: nparmj
      use gradhessj, only: dj, dj_e
      use gradjerrb, only: ngrad_jas_bcum, ngrad_jas_blocks, nbj_current
      implicit real*8(a-h,o-z)






      dimension dj_e_b(83),dj_b(83)

      if(ioptjas.eq.0.or.ngrad_jas_blocks.eq.0) return

      nbj_current=nbj_current+1

      do 200 istate=1,nstates

      do 10 i=1,nparmj
        dj_e_b(i)=dj_e(i,istate)-dj_e_save(i,istate)
  10    dj_b(i)=dj(i,istate)-dj_save(i,istate)
 
      e_bsum(istate)=e_bsum(istate)+enow(istate)
      do 20 i=1,nparmj
        dj_e_bsum(i,istate)=dj_e_bsum(i,istate)+dj_e_b(i)/wsum
  20    dj_bsum(i,istate)=dj_bsum(i,istate)+dj_b(i)/wsum

      do 30 i=1,nparmj
         dj_e_save(i,istate)=dj_e(i,istate)
  30     dj_save(i,istate)=dj(i,istate)
      
      if(nbj_current.eq.ngrad_jas_blocks)then
        eb=e_bsum(istate)/dble(ngrad_jas_blocks)
        e_bsum(istate)=0
        do 40 i=1,nparmj
          gnow=2*(dj_e_bsum(i,istate)-dj_bsum(i,istate)*eb)/dble(ngrad_jas_blocks)
          grad_jas_bcum(i,istate)=grad_jas_bcum(i,istate)+gnow
          grad_jas_bcm2(i,istate)=grad_jas_bcm2(i,istate)+gnow**2
          dj_e_bsum(i,istate)=0
  40      dj_bsum(i,istate)=0
      endif

  200 continue

      if(nbj_current.eq.ngrad_jas_blocks) then
        nbj_current=0
        ngrad_jas_bcum=ngrad_jas_bcum+1
      endif

      return
      end
c-----------------------------------------------------------------------
      subroutine optjas_save
c Written by Claudia Filippi

      use atom, only: nctype

      use csfs, only: nstates

      use derivjas, only: gvalue

      use gradhessjo, only: d1d2a_old, d1d2b_old, d2d2a_old, d2d2b_old, denergy_old, gvalue_old

      use ijasnonlin, only: d1d2a, d1d2b, d2d2a, d2d2b
      use optwf_contrl, only: ioptjas
      use optwf_parms, only: nparmj
      use bparm, only: nspin2b
      use deloc_dj_m, only: denergy
      implicit real*8(a-h,o-z)




      if(ioptjas.eq.0) return

      do 10 i=1,nparmj
        gvalue_old(i)=gvalue(i)
        do 10 istate=1,nstates
  10      denergy_old(i,istate)=denergy(i,istate)

      do 20 it=1,nctype
        d1d2a_old(it)=d1d2a(it)
  20    d2d2a_old(it)=d2d2a(it)

      do 30 isb=1,nspin2b
        d1d2b_old(isb)=d1d2b(isb)
  30    d2d2b_old(isb)=d2d2b(isb)

      return
      end
c-----------------------------------------------------------------------
      subroutine optjas_init
c Written by Claudia Filippi

      use csfs, only: nstates

      use gradjerr, only: dj_bsum, dj_e_bsum, dj_e_save, dj_save, e_bsum, grad_jas_bcm2, grad_jas_bcum

      use optwf_contrl, only: ioptjas
      use optwf_parms, only: nparmj
      use gradhessj, only: d2j, d2j_e, de, de_de, de_e, dj, dj_de, dj_dj, dj_dj_e, dj_e, dj_e2
      use gradhessj, only: e2
      use gradjerrb, only: ngrad_jas_bcum, nbj_current
      implicit real*8(a-h,o-z)




      if(ioptjas.eq.0) return

      do 30 istate=1,nstates
        do 10 i=1,nparmj
          dj(i,istate)=0
          de(i,istate)=0
          dj_e(i,istate)=0
          de_e(i,istate)=0
          dj_e2(i,istate)=0
          e2(i,istate)=0
          do 10 j=1,i
            dj_de(i,j,istate)=0
            dj_de(j,i,istate)=0
            dj_dj(i,j,istate)=0
            dj_dj_e(i,j,istate)=0
            d2j(i,j,istate)=0
            d2j_e(i,j,istate)=0
  10        de_de(i,j,istate)=0

      e_bsum(istate)=0
      do 20 i=1,nparmj
        grad_jas_bcum(i,istate)=0
        grad_jas_bcm2(i,istate)=0
        dj_e_bsum(i,istate)=0
        dj_bsum(i,istate)=0
        dj_e_save(i,istate)=0
  20    dj_save(i,istate)=0

  30  continue

      nbj_current=0
      ngrad_jas_bcum=0

      return
      end
c-----------------------------------------------------------------------
      subroutine optjas_dump(iu)
c Written by Claudia Filippi

      use csfs, only: nstates

      use gradjerr, only: grad_jas_bcm2, grad_jas_bcum

      use optwf_contrl, only: ioptjas
      use optwf_parms, only: nparmj
      use gradhessj, only: d2j, d2j_e, de, de_de, de_e, dj, dj_de, dj_dj, dj_dj_e, dj_e, dj_e2
      use gradhessj, only: e2
      use gradjerrb, only: ngrad_jas_bcum, ngrad_jas_blocks
      implicit real*8(a-h,o-z)






      if(ioptjas.eq.0) return
c to do: write out which parameters are being varied -> check for restart
c Warning: Except for dj_de the rest are sym. so we do not really need to write entire matrix
      write(iu) nparmj
      do 200 istate=1,nstates
      write(iu) (dj(i,istate),de(i,istate),dj_e(i,istate),de_e(i,istate),dj_e2(i,istate),e2(i,istate),i=1,nparmj)
      write(iu) ((dj_de(i,j,istate),j=1,nparmj),i=1,nparmj)
      write(iu) ((dj_dj(i,j,istate),dj_dj_e(i,j,istate),j=1,nparmj),i=1,nparmj)
      write(iu) ((d2j(i,j,istate),d2j_e(i,j,istate),j=1,nparmj),i=1,nparmj)
      write(iu) ((de_de(i,j,istate),j=1,nparmj),i=1,nparmj)
      if(ngrad_jas_blocks.gt.0)
     & write(iu) (grad_jas_bcum(i,istate),grad_jas_bcm2(i,istate),i=1,nparmj),ngrad_jas_bcum
  200 continue

      return
      end
c-----------------------------------------------------------------------
      subroutine optjas_rstrt(iu)
c Written by Claudia Filippi

      use csfs, only: nstates

      use gradjerr, only: dj_e_save, dj_save, grad_jas_bcm2, grad_jas_bcum

      use optwf_contrl, only: ioptjas
      use optwf_parms, only: nparmj
      use gradhessj, only: d2j, d2j_e, de, de_de, de_e, dj, dj_de, dj_dj, dj_dj_e, dj_e, dj_e2
      use gradhessj, only: e2

      use gradjerrb, only: ngrad_jas_bcum, ngrad_jas_blocks
      implicit real*8(a-h,o-z)






      if(ioptjas.eq.0) return

      read(iu) nparmj
      do 200 istate=1,nstates
      read(iu) (dj(i,istate),de(i,istate),dj_e(i,istate),de_e(i,istate),dj_e2(i,istate),e2(i,istate),i=1,nparmj)
      read(iu) ((dj_de(i,j,istate),j=1,nparmj),i=1,nparmj)
      read(iu) ((dj_dj(i,j,istate),dj_dj_e(i,j,istate),j=1,nparmj),i=1,nparmj)
      read(iu) ((d2j(i,j,istate),d2j_e(i,j,istate),j=1,nparmj),i=1,nparmj)
      read(iu) ((de_de(i,j,istate),j=1,nparmj),i=1,nparmj)
      if(ngrad_jas_blocks.gt.0)
     & read(iu) (grad_jas_bcum(i,istate),grad_jas_bcm2(i,istate),i=1,nparmj),ngrad_jas_bcum

      do 10 i=1,nparmj
        dj_e_save(i,istate)=dj_e(i,istate)
   10   dj_save(i,istate)=dj(i,istate)

  200 continue
      return
      end
c-----------------------------------------------------------------------
      subroutine optjas_fin(wcum,ecum)
c Written by Claudia Filippi


      use optjas, only: MPARMJ
      use csfs, only: nstates

      use gradhess_jas, only: grad_jas, h_jas, s_jas
      use gradjerr, only: grad_jas_bcm2, grad_jas_bcum

      use optwf_contrl, only: ioptjas
      use optwf_parms, only: nparmj
      use sa_weights, only: weights
      use gradhessj, only: d2j, d2j_e, de, dj, dj_de, dj_dj, dj_dj_e, dj_e
      use gradjerrb, only: ngrad_jas_bcum, ngrad_jas_blocks
      use method_opt, only: method

      implicit real*8(a-h,o-z)















      dimension hess1(MPARMJ,MPARMJ),hess2(MPARMJ,MPARMJ),hess3(MPARMJ,MPARMJ),grad_now(MPARMJ),gerr(MPARMJ)
      dimension ecum(*),wcum(*)

      errn(x,x2,n)=dsqrt(dabs(x2/dble(n)-(x/dble(n))**2)/dble(n))

      if(ioptjas.eq.0.or.method.eq.'sr_n'.or.method.eq.'lin_d') return

      call p2gtid('optwf:ibeta',ibeta,-1,1)

      do 10 i=1,nparmj+1
        grad_jas(i)=0
        do 10 j=1,nparmj+1
          s_jas(i,j)=0
   10     h_jas(i,j)=0

      do 200 istate=1,nstates

      passes=wcum(istate)
      eave=ecum(istate)/passes
c Compute gradient
      do 20 i=1,nparmj
        grad_now(i)=2*(dj_e(i,istate)-eave*dj(i,istate))/passes
   20   grad_jas(i)=grad_jas(i)+weights(istate)*grad_now(i)

      if(method.eq.'hessian') then

c Compute hessian (symmetrized dj_de term)

c Hessian h = hess1 + hess2 + hess3
c hess1=S_h, hess2=2*G, hess3=terms depending on d2j
      do 30 i=1,nparmj
        do 30 j=1,i
          hess1(i,j)=(dj_de(i,j,istate)+dj_de(j,i,istate)-(dj(i,istate)*de(j,istate)+dj(j,istate)*de(i,istate))/passes)/passes
          hess2(i,j)=2*(2*(dj_dj_e(i,j,istate)-eave*dj_dj(i,j,istate))-grad_now(i)*dj(j,istate)-grad_now(j)*dj(i,istate))/passes
   30     hess3(i,j)=2*(d2j_e(i,j,istate)-eave*d2j(i,j,istate))/passes

c Compute ratio for reweighted expression of the hessian
      botsum_j=0
      topsum_j=0
      do 40 i=1,nparmj
        do 40 j=1,i
          botsum_j=botsum_j+hess1(i,j)
   40     topsum_j=topsum_j+hess2(i,j)
      ratio_j=(topsum_j+botsum_j)/botsum_j

c Construct hessian 
c Hessian h = hess1 + hess2 + hess3 (ratio=1, ibeta=1)
c Reduced fluctuation hessian = ratio*hess1 + hess3 (ratio, ibeta=-1)
      call p2gtfd('optwf:ratio',ratio,ratio_j,1)
      do 45 i=1,nparmj
        do 45 j=1,i
          h_jas(i,j)=h_jas(i,j)+weights(istate)*(ratio*hess1(i,j)+0.5d0*(1+ibeta)*hess2(i,j)+hess3(i,j))
   45     h_jas(j,i)=h_jas(i,j)

      if(ngrad_jas_blocks.gt.0) then
        do 80 i=1,nparmj
  80      gerr(i)=errn(grad_jas_bcum(i,istate),grad_jas_bcm2(i,istate),ngrad_jas_bcum)
      endif

      elseif(method.eq.'linear') then

c Compute <dj H dj>/<psi|psi> and <dj dj>/<psi|psi> 

c Hamiltonian h = <dj H dj>/<psi|psi>
      h_jas(1,1)=h_jas(1,1)+weights(istate)*eave
      do 130 i=1,nparmj
        h_jas(1,i+1)=h_jas(1,i+1)+weights(istate)*(de(i,istate)+dj_e(i,istate)-eave*dj(i,istate))/passes
  130   h_jas(i+1,1)=h_jas(i+1,1)+weights(istate)*(dj_e(i,istate)-eave*dj(i,istate))/passes

      do 140 i=1,nparmj
        h_jas(i+1,i+1)=h_jas(i+1,i+1)+weights(istate)*(dj_de(i,i,istate)+dj_dj_e(i,i,istate)
     &                  +dj(i,istate)*(eave*dj(i,istate)-de(i,istate)-2*dj_e(i,istate))/passes)/passes
        do 140 j=1,i-1
          h_jas(i+1,j+1)=h_jas(i+1,j+1)+weights(istate)*(dj_de(i,j,istate)+dj_dj_e(i,j,istate)
     &                  +(eave*dj(i,istate)*dj(j,istate)
     &                  -dj(i,istate)*(de(j,istate)+dj_e(j,istate))
     &                  -dj(j,istate)*dj_e(i,istate))/passes)/passes
  140     h_jas(j+1,i+1)=h_jas(j+1,i+1)+weights(istate)*(dj_de(j,i,istate)+dj_dj_e(i,j,istate)
     &                  +(eave*dj(i,istate)*dj(j,istate)
     &                  -dj(j,istate)*(de(i,istate)+dj_e(i,istate))
     &                  -dj(i,istate)*dj_e(j,istate))/passes)/passes

c Overlap s = <dj dj>/<psi|psi>
      s_jas(1,1)=1
      do 150 i=1,nparmj
        s_jas(i+1,1)=0
  150   s_jas(1,i+1)=0

      do 160 i=1,nparmj
        do 160 j=1,i
          s_jas(i+1,j+1)=s_jas(i+1,j+1)+weights(istate)*(dj_dj(i,j,istate)-dj(i,istate)*dj(j,istate)/passes)/passes
  160     s_jas(j+1,i+1)=s_jas(i+1,j+1)

      endif

  200 continue

      return
      end
