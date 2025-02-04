      module optwf_lin_dav
      contains
      subroutine optwf_lin_d

      use contrl_file, only: ounit
      use control_vmc, only: vmc_nblk,vmc_nblk_max
      use csfs,    only: nstates
      use error,   only: fatal_error
      use m_force_analytic, only: alfgeo,iforce_analy
      use mstates_mod, only: MSTATES
      use optgeo_lib, only: compute_positions,write_geometry
      use optwf_control, only: alin_adiag,alin_eps,dparm_norm_min
      use optwf_control, only: energy_tol,ioptci,ioptjas,ioptorb,method
      use optwf_control, only: micro_iter_sr,nopt_iter,nparm,nvec,nvecx
      use optwf_corsam, only: energy,energy_err,sigma
      use optwf_func, only: ifunc_omega,n_omegaf,n_omegat,omega,omega0
      use optwf_handle_wf, only: compute_parameters,save_nparms,save_wf
      use optwf_handle_wf, only: set_nparms,set_nparms_tot
      use optwf_handle_wf, only: test_solution_parm,write_wf
      use optwf_lin_dav_more, only: lin_d
      use orbval,  only: nadorb
      use precision_kinds, only: dp
      use sr_mod,  only: mparm
      use sr_more, only: dscal
      !use contrl, only: nblk, nblk_max

      implicit none
      interface
      subroutine qmc
      end subroutine
      end interface

      integer :: iflag, iforce_analy_sav, inc_nblk, ioptci_sav, ioptjas_sav
      integer :: ioptorb_sav, iter, miter, nstates_sav,nadorb_sav
      integer, dimension(5,MSTATES) :: index_more
      real(dp) :: adiag, alin_adiag_sav, alpha_omega, denergy, denergy_err
      real(dp) :: dparm_norm, energy_err_sav, energy_sav
      real(dp) :: sigma_sav
      real(dp), dimension(mparm*MSTATES) :: grad
      real(dp), dimension(mparm*MSTATES,5) :: grad_more
      character(len=20) method_sav

      if(method .ne.'lin_d')return

      call set_nparms_tot

      if(nparm.gt.mparm)call fatal_error('OPTWF_LIN_D: nparmtot gt mparm')

      write(ounit,'(''Starting dparm_norm_min'',g12.4)') dparm_norm_min

      if(ifunc_omega.gt.0) then
       if(n_omegaf+n_omegat.gt.nopt_iter) call fatal_error('OPTWF_LIN_D: n_omegaf+n_omegat > nopt_iter')
       omega=omega0
       write(ounit,'(/,''LIN_D ifunc_omega: '',i3)') ifunc_omega
       write(ounit,'(''LIN_D omega: '',f10.5)') omega
       write(ounit,'(''LIN_D n_omegaf: '',i4)') n_omegaf
       write(ounit,'(''LIN_D n_omegat: '',i4)') n_omegat
      endif

      ! if(nvecx.gt.MVEC) call fatal_error('SR_OPTWF: nvecx > MVEC')

      write(ounit,'(/,''LIN_D adiag: '',f10.5)') alin_adiag
      write(ounit,'(''LIN_D ethr:  '',f10.5)') alin_eps
      write(ounit,'(''LIN_D nvec:  '',i4)') nvec
      write(ounit,'(''LIN_D nvecx: '',i4)') nvecx

      if(nstates.gt.1.and.nvec.lt.nstates) call fatal_error('OPTWF_LIN_D: nvec < nstates')

      inc_nblk=0

      alin_adiag_sav=alin_adiag

      nstates_sav=nstates
      iforce_analy_sav=iforce_analy

      ioptjas_sav=ioptjas
      ioptorb_sav=ioptorb
      ioptci_sav=ioptci
      call save_nparms

      call write_geometry(0)

c do iteration
      do iter=1,nopt_iter
        write(ounit,'(/,''Optimization iteration'',i5,'' of'',i5)')iter,nopt_iter

        iforce_analy=0

        if(ifunc_omega.gt.0) then
          if(iter.gt.n_omegaf) then
            alpha_omega=dble(n_omegaf+n_omegat-iter)/n_omegat
            omega=alpha_omega*omega0+(1.d0-alpha_omega)*(energy_sav-sigma_sav)
            if(ifunc_omega.eq.2) omega=alpha_omega*omega0+(1.d0-alpha_omega)*energy_sav
          endif
          if(iter.gt.n_omegaf+n_omegat) then
            omega=energy_sav-sigma_sav
            if(ifunc_omega.eq.2) omega=energy_sav
          endif
          write(ounit,'(''LIN_D omega: '',f10.5)') omega
        endif

c do micro_iteration
        do miter=1,micro_iter_sr

          if(micro_iter_sr.gt.1) write(ounit,'(/,''Micro iteration'',i5,'' of'',i5)')miter,micro_iter_sr

          if(miter.eq.micro_iter_sr) iforce_analy=iforce_analy_sav

c        efin_old = efin define efin_old as the energy before

          call qmc

          write(ounit,'(/,''Completed sampling'')')

   6      continue

          call lin_d(nparm,nvec,nvecx,grad,grad_more,index_more,alin_adiag,alin_eps)
          if(nstates.eq.1) call dscal(nparm,-1.d0,grad,1)

          if(method.eq.'lin_d'.and.ioptorb+ioptjas.gt.0) then
            adiag=alin_adiag
            call test_solution_parm(nparm,grad,dparm_norm,dparm_norm_min,adiag,iflag)
            write(ounit,'(''Norm of parm variation '',g12.5)') dparm_norm
            if(iflag.ne.0) then
              write(ounit,'(''Warning: dparm_norm>1'')')
              adiag=10*adiag
              write(ounit,'(''adiag increased to '',f10.5)') adiag

              alin_adiag=adiag
              go to 6
             else
              alin_adiag=alin_adiag_sav
            endif
          endif


c Here I should save the old parameters

          call compute_parameters(grad,iflag,1)
          call write_wf(1,iter)

          call save_wf

          if(iforce_analy.gt.0) then
            call compute_positions
            call write_geometry(iter)
          endif
        enddo
c enddo micro_iteration

        if(iter.ge.2) then
          denergy=energy(1)-energy_sav
          denergy_err=sqrt(energy_err(1)**2+energy_err_sav**2)
c         call check_length_run_sr(iter,inc_nblk,vmc_nblk,vmc_nblk_max,denergy,denergy_err,energy_err_sav,energy_tol)
          vmc_nblk=vmc_nblk*1.2
          vmc_nblk=min(vmc_nblk,vmc_nblk_max)
c         if(-denergy.gt.3*denergy_err) alfgeo=alfgeo/1.2
        endif
        write(ounit,'(''vmc_nblk = '',i6)') vmc_nblk
        write(ounit,'(''alfgeo = '',f10.4)') alfgeo

        energy_sav=energy(1)
        energy_err_sav=energy_err(1)
        sigma_sav=sigma
        ! sigma_sav=0 ! sigma is not initialized and never changed ...
      enddo
c enddo iteration

      write(ounit,'(/,''Check last iteration'')')

      ioptjas=0
      ioptorb=0
      ioptci=0
      iforce_analy=0

      call set_nparms

      call qmc

      nadorb_sav=nadorb
      call write_wf(1,-1)
      call write_geometry(-1)

      return
      end
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      end module
