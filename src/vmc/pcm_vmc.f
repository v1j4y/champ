      module pcm_vmc
      contains
      subroutine pcm_prt(wcum,iblk)

      use pcm_cntrl, only: ipcm, ipcmprt
      use pcm_averages, only: spcmcum, spcmcm2, vpcmcum, vpcmcm2
      use contrl_file,    only: ounit
      use precision_kinds, only: dp
      implicit none

      integer :: iblk, ispcmerr, ivpcmerr
      real(dp) :: err, rtpass, spcmave, spcmerr, svpcmave
      real(dp) :: svpcmerr, vpcmave, vpcmerr, wcum
      real(dp) :: x, x2


      err(x,x2)=dsqrt(abs(x2/wcum-(x/wcum)**2)/iblk)

      if(ipcm.eq.0.or.ipcmprt.eq.0) return

      spcmave=spcmcum/wcum
      vpcmave=vpcmcum/wcum

      if(iblk.eq.1) then
        spcmerr=0
        vpcmerr=0

       else
        spcmerr=err(spcmcum,spcmcm2)
        vpcmerr=err(vpcmcum,vpcmcm2)

        ispcmerr=nint(100000*spcmerr)
        ivpcmerr=nint(100000*vpcmerr)
      endif

      rtpass=dsqrt(wcum)
      if(ipcm.eq.2)then
      write(ounit,'(''pcm dG (surf.) ='',t17,f12.7,'' +-'',f11.7,f9.5)') spcmave,spcmerr,spcmerr*rtpass
      write(ounit,'(''pcm dG (vol.)  ='',t17,f12.7,'' +-'',f11.7,f9.5)') vpcmave,vpcmerr,vpcmerr*rtpass
      endif
      if(ipcm.eq.3)then
      svpcmave=spcmave+vpcmave
      svpcmerr=sqrt(spcmerr**2.0d0+vpcmerr**2.0d0)
      write(ounit,'(''pcm dG (surf.+vol) ='',t17,f12.7,'' +-'',f11.7,f9.5)') svpcmave,svpcmerr,svpcmerr*rtpass
      endif

      return
      end

c-----------------------------------------------------------------------
      subroutine pcm_fin(wcum,iblk)

      use pcm, only: MCHS
      !use contrl, only: nblk, nstep
      use control_vmc, only: vmc_nblk, vmc_nstep
      use pcm_cntrl, only: ipcm
      use pcm_parms, only: iscov, nch, nchs
      use pcm_parms, only: nscv
      use pcm_fdc, only: fs, qfree, qvol
      use pcm_averages, only: spcmcum, spcmcm2, vpcmcum, vpcmcm2
      use pcm_averages, only: qopcm_cum, qopcm_cm2
      use pcm_averages, only: enfpcm_cum, enfpcm_cm2
      use contrl_file,    only: ounit
      use precision_kinds, only: dp
      use pcm_mod, only: qpcm_charges, pcm_write_chvol
      implicit none

      integer :: i, iblk, iqopcm_err, ispcmerr, ivpcmerr
      real(dp) :: dble, dqpol, err, gpcmkcal, hatokc
      real(dp) :: qopcm_ave, qopcm_err, qpol, qtheo
      real(dp) :: qtheov, qv, rtpass, sdqpol
      real(dp) :: sepcmkcal, spcmave, spcmerr, spcmkcal
      real(dp) :: sqpol, sqpol2, sqtheo, sqtheo2
      real(dp) :: sqv, svpcmave, svpcmerr, vepcmkcal
      real(dp) :: vpcmave, vpcmerr, vpcmkcal, wcum
      real(dp) :: x, x2
      real(dp), dimension(MCHS) :: enfpcm_ave
      real(dp), dimension(MCHS) :: enfpcm_err



      data hatokc/627.509541d0/


      err(x,x2)=dsqrt(abs(x2/wcum-(x/wcum)**2)/iblk)

      if(ipcm.eq.0) return

      rtpass=dsqrt(wcum)

      spcmave=spcmcum/wcum
      vpcmave=vpcmcum/wcum
      qopcm_ave=qopcm_cum/wcum

      spcmerr=err(spcmcum,spcmcm2)
      vpcmerr=err(vpcmcum,vpcmcm2)
      qopcm_err=err(qopcm_cum,qopcm_cm2)

      ispcmerr=nint(100000*spcmerr)
      ivpcmerr=nint(100000*vpcmerr)
      iqopcm_err=nint(100000*qopcm_err)

      if(ipcm.eq.2)then
      write(ounit,*)
      write(ounit,'(''pcm dG (surf.) ='',t17,f12.7,'' +-'',f11.7,f9.5)') spcmave,spcmerr,spcmerr*rtpass
      write(ounit,'(''pcm dG (vol.)  ='',t17,f12.7,'' +-'',f11.7,f9.5)') vpcmave,vpcmerr,vpcmerr*rtpass
      endif

      if(ipcm.eq.3)then
      svpcmave=spcmave+vpcmave
      svpcmerr=sqrt(spcmerr**2.0d0+vpcmerr**2.0d0)
      write(ounit,'(''pcm dG (surf.+vol) ='',t17,f12.7,'' +-'',f11.7,f9.5)') svpcmave,svpcmerr,svpcmerr*rtpass
      endif

      if(ipcm.ne.3)then
        do i=1,nchs
          enfpcm_ave(i)=enfpcm_cum(i)/wcum
          enfpcm_err(i)=err(enfpcm_cum(i),enfpcm_cm2(i))
        enddo
 	call qpcm_charges(enfpcm_ave,enfpcm_err,qpol,sqpol2)

        qtheo=(fs-1.0d0)*(qfree+qopcm_ave)
        sqtheo2=((fs-1.0d0)*qopcm_err)**2.0d0
        sqtheo=dsqrt(sqtheo2)
        sqpol=dsqrt(sqpol2)
        dqpol=qpol-qtheo
        sdqpol=dsqrt(sqpol2+sqtheo2)
        qtheov=-(fs-1.0d0)*qopcm_ave
	qv=(nch-nchs)*qvol
        sqv=sqtheo*dsqrt(0.5d0+vmc_nblk*vmc_nstep/dble(nscv*iscov))
        write(ounit,'(''pcm        qout ='',f12.7,'' +-'',f11.7,f9.5)') qopcm_ave,qopcm_err,qopcm_err*rtpass
        write(ounit,'(''pcm        qpol ='',f12.7'' +-'',f11.7)') qpol,sqpol
        write(ounit,'(''pcm      qtheos ='',f12.7'' +-'',f11.7)') qtheo,sqtheo
        write(ounit,'(''pcm qpol-qtheos ='',f12.7'' +-'',f11.7)') dqpol,sdqpol
        write(ounit,'(''pcm       qpolv ='',f12.7'' +-'',f11.7)') qv,sqv
        write(ounit,'(''pcm      qtheov ='',f12.7'' +-'',f11.7)') qtheov,sqtheo
	spcmkcal=spcmave*hatokc
	vpcmkcal=vpcmave*hatokc
	sepcmkcal=spcmerr*hatokc
	vepcmkcal=vpcmerr*hatokc
	gpcmkcal=spcmkcal+vpcmkcal
	write(ounit,*)'    qout       qpol        qtheo      DG_surf/vol/tot +- err (kcal/mol) '
	write(ounit,1000)qopcm_ave,qpol,qtheo,spcmkcal,sepcmkcal,vpcmkcal,vepcmkcal,gpcmkcal
        write(ounit,*)
       else
        write(ounit,'(''pcm        qout ='',f12.7,'' +-'',f11.7,f9.5)') qopcm_ave,qopcm_err,qopcm_err*rtpass
      endif

      call pcm_write_chvol

 1000 format(9F12.5)

      return
      end
c-----------------------------------------------------------------------
      subroutine pcm_save

      use pcm_hpsi, only: enfpcm, qopcm
      use pcmo, only: enfpcmo, qopcmo, spcmo, vpcmo
      use pcm_cntrl, only: ipcm
      use pcm_parms, only: nchs

      use precision_kinds, only: dp
      implicit none

      integer :: i
      real(dp) :: pcms, pcmv


      if(ipcm.eq.0) return
      spcmo=pcms
      vpcmo=pcmv
      qopcmo=qopcm

      do i=1,nchs
      enfpcmo(i)=enfpcm(i)
      enddo

      return
      end
c-----------------------------------------------------------------------
      subroutine pcm_sum(p,q)
      use pcm_hpsi, only: enfpcm, qopcm
      use pcmo, only: enfpcmo, qopcmo, spcmo, vpcmo
      use pcm_cntrl, only: ipcm
      use pcm_parms, only: nchs
      use pcm_averages, only: spcmsum, vpcmsum
      use pcm_averages, only: qopcm_sum
      use pcm_averages, only: enfpcm_sum

      use precision_kinds, only: dp
      implicit none

      integer :: i
      real(dp) :: p, pcms, pcmv, q


      if(ipcm.eq.0) return
      spcmsum=spcmsum+p*pcms+q*spcmo
      vpcmsum=vpcmsum+p*pcmv+q*vpcmo
      qopcm_sum=qopcm_sum+p*qopcm+q*qopcmo

      do i=1,nchs
      enfpcm_sum(i)= enfpcm_sum(i)+p*enfpcm(i)+q*enfpcmo(i)
      enddo

      return
      end
c-----------------------------------------------------------------------
      subroutine pcm_cum(wsum)

      use pcm_cntrl, only: ipcm
      use pcm_parms, only: nchs
      use pcm_averages, only: spcmsum, spcmcum, spcmcm2, vpcmsum, vpcmcum, vpcmcm2
      use pcm_averages, only: qopcm_sum, qopcm_cum, qopcm_cm2
      use pcm_averages, only: enfpcm_sum, enfpcm_cum, enfpcm_cm2

      use precision_kinds, only: dp
      implicit none

      integer :: i
      real(dp) :: enfpcm_now, qopcm_now, spcmnow, vpcmnow, wsum


      if(ipcm.eq.0) return
      spcmnow=spcmsum/wsum
      vpcmnow=vpcmsum/wsum
      qopcm_now=qopcm_sum/wsum

      spcmcm2=spcmcm2+spcmsum*spcmnow
      vpcmcm2=vpcmcm2+vpcmsum*vpcmnow
      qopcm_cm2=qopcm_cm2+qopcm_sum*qopcm_now

      spcmcum=spcmcum+spcmsum
      vpcmcum=vpcmcum+vpcmsum
      qopcm_cum=qopcm_cum+qopcm_sum

      do i=1,nchs
      enfpcm_now=enfpcm_sum(i)/wsum
      enfpcm_cm2(i)=enfpcm_cm2(i)+enfpcm_sum(i)*enfpcm_now
      enfpcm_cum(i)=enfpcm_cum(i)+enfpcm_sum(i)
      enddo

      return
      end
      end module
