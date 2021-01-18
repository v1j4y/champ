      subroutine finwrt
c Written by Cyrus Umrigar, modified by Claudia Filippi
c routine to print out final results

      use force_mod, only: MFORCE
      use vmc_mod, only: nrad
      use vmc_mod, only: delri
      use atom, only: ncent
      use const, only: nelec
      use csfs, only: nstates
      use denupdn, only: rprobdn, rprobup
      use est2cm, only: ecm2, ecm21, pecm2, r2cm2, tjfcm2, tpbcm2
      use estcum, only: ecum, ecum1, iblk, pecum, r2cum, tjfcum, tpbcum
      use estsig, only: ecm21s, ecum1s
      use estsum, only: acc
      use forcepar, only: deltot, nforce
      use forcest, only: fcm2, fcum
      use forcewt, only: wcum
      use grdntspar, only: igrdtype, ngradnts
      use header, only: title
      use optwf_corsam, only: energy, energy_err, force, force_err
      use sa_weights, only: weights
      use step, only: rprob, suc, try
      use tmpnode, only: distance_node_sum
      use contr3, only: mode
      use contrl, only: nblk, nstep
      use contrl_per, only: iperiodic
      use sa_check, only: energy_all, energy_err_all
      use ci000, only: iciprt

      implicit real*8(a-h,o-z)



      parameter (one=1.d0,half=.5d0)

      dimension ffin_grdnts(MFORCE),ferr_grdnts(MFORCE)

      err(x,x2,j,i)=dsqrt(abs(x2/wcum(j,i)-(x/wcum(j,i))**2)/iblk)
      err1(x,x2,j)=dsqrt(dabs(x2/wcum(j,1)-(x/wcum(j,1))**2)/passes)

      passes=dfloat(iblk*nstep)
      rtpass=dsqrt(passes)

c quantities not computed in acuest_write

      if(iperiodic.eq.0 .and. ncent.eq.1) then
        write(45,*)'  r   rprob'
        delr=one/delri
        term=one/(passes*delr)
        trysum=0
        sucsum=0
        do 100 i=1,nrad
          trysum=trysum+try(i)
          sucsum=sucsum+suc(i)
  100     write(45,'(f5.3,3f10.6)') delr*(i-half),rprob(i)*term,rprobup(i)*term,rprobdn(i)*term
      endif

c quantities also computed in acuest_write

      if(index(mode,'mov1').eq.0) then
        accept=acc/passes
       else
        accept=acc/(passes*nelec)
      endif

      do 150 ifr=1,nforce
        energy(ifr)=0
        energy_err(ifr)=0
        ffin_grdnts(ifr)=0
        ferr_grdnts(ifr)=0
        force(ifr)=0
  150   force_err(ifr)=0

      do 200 istate=1,nstates

      eerr1=err1(ecum1(istate),ecm21(istate),istate)
      eerr1s=err1(ecum1s(istate),ecm21s(istate),istate)

      efin=ecum(istate,1)/wcum(istate,1)
      pefin=pecum(istate)/wcum(istate,1)
      tpbfin=tpbcum(istate)/wcum(istate,1)
      tjffin=tjfcum(istate)/wcum(istate,1)
      r2fin=r2cum/wcum(istate,1)

      eerr=err(ecum(istate,1),ecm2(istate,1),istate,1)
      peerr=err(pecum(istate),pecm2(istate),istate,1)
      tpberr=err(tpbcum(istate),tpbcm2(istate),istate,1)
      tjferr=err(tjfcum(istate),tjfcm2(istate),istate,1)
      r2err=err(r2cum,r2cm2,1,1)

      energy(1)=energy(1)+weights(istate)*efin

c     save the enegies (of all the states) of the last run for the check in lin_d and error
      energy_all(istate)=efin
      energy_err_all(istate)=eerr

c TMP
c     energy_err(1)=energy_err(1)+(weights(istate)*eerr)**2
      energy_err(1)=energy_err(1)+weights(istate)*eerr

c eerr1*rtpass differs from sigma in that eerr1 contains p*new+q*old,
c so eerr1 is a bit smaller than eerr1s. sigma is a property of the wave
c function only, whereas eerr1*rtpass depends on how quickly one evolves
c the system.
c In the calculation of T_corr, if one uses T_corr=(eerr/eerr1)^2, then
c T_corr=1 when nstep=1, whereas if one uses T_corr=(eerr/eerr1s)^2, then
c T_corr will be a bit < 1 when nstep=1. However, it makes sense to use
c the latter definition because p*new+q*old does reduce T_corr and that
c is precisely what is being reflected when we get T_corr < 1.
      tcsq=eerr/eerr1s
      sigma=eerr1s*rtpass

      if(istate.eq.1) then
        write(6,'(a12,2x,a20)') mode,title
        write(6,'(''results after '',f12.0,'' passes,  nstep, nblk ='',3i6)')
     &  passes, nstep,iblk
      endif
      if(nstates.gt.1) write(6,'(/,''State '',i4)') istate
      write(6,'(''physical variable'',t20,''average'',t34,''rms error''
     &,t47,''rms er*rt(pass)'',t65,''sigma'',t72,''Tcor'')')

      write(6,'(''total E ='',t17,f12.7,'' +-'',f11.7,3f9.5,f8.2)')
     & efin,eerr,eerr*rtpass,eerr1*rtpass,sigma,tcsq*tcsq

      efin_p=efin
      eerr_p=eerr

      do 110 ifr=2,nforce
        efin=ecum(istate,ifr)/wcum(istate,ifr)
        eerr=err(ecum(istate,ifr),ecm2(istate,ifr),istate,ifr)
        ffin=ecum(istate,1)/wcum(istate,1)-efin
        ferr=err(fcum(istate,ifr),fcm2(istate,ifr),istate,1)/abs(deltot(ifr))

c save energy, force, and, energy and force error for optimization
        energy(ifr)=energy(ifr)+weights(istate)*efin
c TMP
c       energy_err(ifr)=energy_err(ifr)+(weights(istate)*eerr)**2
        energy_err(ifr)=energy_err(ifr)+weights(istate)*eerr

        force(ifr)=force(ifr)+weights(istate)*ffin
c TMP
c       force_err(ifr)=force_err(ifr)+(weights(istate)*ferr)**2
        force_err(ifr)=force_err(ifr)+weights(istate)*ferr

c save forces and forces errors for calculations of energy gradients.
c Done by Omar Valsson 2008-12-01
        if(ngradnts.gt.0) then
          ffin_grdnts(ifr-1)=ffin
          ferr_grdnts(ifr-1)=ferr
        endif

        write(6,'(''total E ='',t17,f12.7,'' +-'',f11.7,f9.5)') efin,eerr,eerr*rtpass
  110   write(6,'(''force   ='',t17,e19.10,'' +-'',e16.8,f9.5)') ffin/deltot(ifr),ferr,ferr*rtpass
      write(6,'(''potential E ='',t17,f12.7,'' +-'',f11.7,f9.5)') pefin,peerr,peerr*rtpass
      write(6,'(''jf kinetic E ='',t17,f12.7,'' +-'',f11.7,f9.5)') tjffin,tjferr,tjferr*rtpass
      write(6,'(''pb kinetic E ='',t17,f12.7,'' +-'',f11.7,f9.5)') tpbfin,tpberr,tpberr*rtpass

  200 continue

c TMP
c     do 250 ifr=1,nforce
c       energy_err(ifr)=sqrt(energy_err(ifr))
c 250   force_err(ifr)=sqrt(force_err(ifr))

      if(iperiodic.eq.0.and.ncent.eq.1)
     & write(6,'(''<r2> ='',t17,f12.7,'' +-'',f11.7,f9.5)') r2fin,r2err,r2err*rtpass

      if(index(mode,'mov1').ne.0.and.iperiodic.eq.0.and.ncent.eq.1) then
        write(6,'(''acceptance ='',t17,2f12.7)') accept,sucsum/trysum
       else
        write(6,'(''acceptance ='',t17,2f12.7)') accept
      endif

      call p2gtid('qmmm:iqmmm',iqmmm,0,1)
      if(iqmmm.gt.0) call qmmm_extpot_final(nelec)

      iciprt_sav=iciprt
      iciprt=-1
      call optci_prt(wcum(1,1),iblk,6)
      iciprt=iciprt_sav

      call efficiency_prt(passes)

      call prop_fin(wcum(1,1),iblk,efin_p,eerr_p)

      call finwrt_more

      write(6,'(''distance from the nodes '',f10.5)') distance_node_sum/passes

      if(ngradnts.gt.0 .and. igrdtype.eq.1) call finwrt_grdnts_cart(ffin_grdnts,ferr_grdnts)
      if(ngradnts.gt.0 .and. igrdtype.eq.2) call finwrt_grdnts_zmat(ffin_grdnts,ferr_grdnts)
      if(ngradnts.gt.0 .and. igrdtype.eq.2) call finwrt_diaghess_zmat(ffin_grdnts,ferr_grdnts)

      return
      end
