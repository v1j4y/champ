      module optwf_matrix_corsamp_mod
      use error,   only: fatal_error
      interface ! Let linking decide between dmc/vmc
        subroutine qmc
        end subroutine
        subroutine reset_configs_start
        end subroutine
      end interface

      contains
      subroutine optwf_matrix_corsamp
c written by Claudia Filippi
      use contrl_file, only: ounit
      use control_vmc, only: vmc_idump,vmc_irstar,vmc_isite,vmc_nblk
      use control_vmc, only: vmc_nblk_ci,vmc_nblk_max
      use csfs,    only: nstates
      use gradhess_all, only: grad,h,nparmall,s
      use multiple_geo, only: iwftype,nforce,nwftype
      use numbas,  only: numr
      use optwf_control, only: dparm_norm_min,energy_tol,ilastvmc,ioptci
      use optwf_control, only: ioptjas,ioptorb,multiple_adiag,nopt_iter
      use optwf_control, only: nparm
      use optwf_corsam, only: add_diag,energy,energy_err,force,force_err
      use optwf_handle_wf, only: compute_parameters,copy_zex,restore_wf
      use optwf_handle_wf, only: save_nparms,save_wf,save_wf_best
      use optwf_handle_wf, only: set_nparms,setup_wf,test_solution_parm
      use optwf_handle_wf, only: write_wf,write_wf_best
      use optwf_lin_matrix, only: compute_dparm,setup_optimization
      use orbval,  only: nadorb
      use precision_kinds, only: dp
      use read_bas_num_mod, only: read_bas_num
      use set_input_data, only: set_displace_zero

!     use contrl, only: idump, irstar, isite, nblk, nblk_max, nblk_ci

      ! I think that's needed
      implicit none

      integer :: i, iadd_diag_loop1, iadiag, iflag, increase_nblk
      integer :: ioptci_sav, ioptjas_sav, ioptorb_sav, nadorb_sav, iter
      integer :: iwft, k, k_demax, k_demin
      integer :: lwork, lwork_all_save, lwork_ci_save, nblk_sav
      real(dp) :: add_diag_sav, de_worse1, de_worse2
      real(dp) :: de_worse3, de_worse_err1, de_worse_err2, de_worse_err3
      real(dp) :: denergy, denergy_err, denergy_max, denergy_min
      real(dp) :: dparm_norm, energy_err_sav, energy_plus_err, energy_plus_err_best
      real(dp) :: energy_sav


      ! parameter(nparmall2=nparmall*(nparmall+1)/2)
      ! parameter(MWORK=50*nparmall)
      ! dimension grad_sav(nparmall),h_sav(nparmall,nparmall),s_sav(nparmall2)
      ! dimension work(MWORK),work2(nparmall,nparmall)

      integer :: nparmall2
      integer :: MWORK
      real(dp), DIMENSION(:), allocatable :: grad_sav
      real(dp), DIMENSION(:,:), allocatable :: h_sav
      real(dp), DIMENSION(:), allocatable :: s_sav
      real(dp), DIMENSION(:), allocatable :: work
      real(dp), DIMENSION(:, :), allocatable :: work2

      nparmall2 = nparmall*(nparmall+1)/2
      MWORK=50*nparmall

      allocate(grad_sav(nparmall))
      allocate(h_sav(nparmall,nparmall))
      allocate(s_sav(nparmall2))
      allocate(work(MWORK))
      allocate(work2(nparmall,nparmall))

c No dump/restart if optimizing wave function
      vmc_irstar=0
      vmc_idump=0

c Set up basis functions for test run
      do iwft=2,3
        iwftype(iwft)=iwft
      enddo
      if(numr.gt.0) then
        do iwft=2,3
          call read_bas_num(iwft)
        enddo
       else
        do iwft=2,3
          call copy_zex(iwft)
        enddo
      endif
      call set_displace_zero(3)

c Number of iterations
      write(ounit,'(/,''Number of iterations'',i3)') nopt_iter
      if(ioptci.eq.1.and.ioptjas.eq.0.and.ioptorb.eq.0) then
        nopt_iter=1
        write(ounit,'(''Reset number of iterations to 1'')')
      endif
c Max number of blocks
      write(ounit,'(/,''Maximum number of blocks'',i4)') vmc_nblk_max
c Compute multiple adiag
      write(ounit,'(/,''Perform test run with multiple adiag'',i2)') multiple_adiag
c Tolerance on energy
      write(ounit,'(/,''Energy tolerance'',d12.2)') energy_tol

      if(ioptjas.eq.0.and.ioptorb.eq.0) add_diag(1)=-1

c Set dparm_norm_min
      write(ounit,'(''Starting dparm_norm_min'',g12.4)') dparm_norm_min

      ioptjas_sav=ioptjas
      ioptorb_sav=ioptorb
      ioptci_sav=ioptci
      nadorb_sav=nadorb
      call save_nparms

      increase_nblk=0
      energy_plus_err_best=1.d99

c CI step for state average of multiple states (optimal CI for input Jastrow and LCAO)
      if(ioptci.ne.0.and.nstates.gt.1.and.(ioptorb+ioptjas.gt.0)) then
        write(ounit,'(/,''Perform CI run for SA calculation'')')
        ioptjas=0
        ioptorb=0
        add_diag_sav=add_diag(1)
        add_diag(1)=-1

        call set_nparms

        nblk_sav=vmc_nblk
        vmc_nblk=vmc_nblk_ci
        call qmc
        vmc_nblk=nblk_sav

        call combine_derivatives

        call save_wf

        call setup_optimization(nparm,nparmall,MWORK,lwork,h,h_sav,s,s_sav,work,work2,add_diag(1),iter)

        write(ounit,'(/,''Compute CI parameters'',/)')
        call compute_dparm(nparm,nparmall,lwork_ci_save,grad,h,h_sav,s,s_sav,work,work2,
     &                     add_diag(1),energy(1),energy_err(1))

        call compute_parameters(grad,iflag,1)

        call write_wf(1,0)

        add_diag(1)=add_diag_sav
      endif

c Iterate optimization
      do iter=1,nopt_iter


      write(ounit,'(/,''Optimization iteration'',i2)') iter
      iadd_diag_loop1=0

 100  ioptjas=ioptjas_sav
      ioptorb=ioptorb_sav
      ioptci=ioptci_sav

      if(ioptci.ne.0.and.nstates.gt.1.and.(ioptorb+ioptjas.gt.0)) ioptci=0
      call set_nparms

      nforce=1
      nwftype=1
c Generate gradient, hessian
 200  call qmc
      call combine_derivatives

      if(iter.ge.2) then
       denergy=energy(1)-energy_sav
       denergy_err=sqrt(energy_err(1)**2+energy_err_sav**2)

c For multiple states, this should never happen as you have checked the energy in the CI step and
c the CI step is unlikely to go wrong (unless the CI run is too short)
       if(denergy.gt.3*denergy_err) then
         iadd_diag_loop1=iadd_diag_loop1+1
         if(iadd_diag_loop1.gt.5) call fatal_error('OPTWF: energy went up a lot and iadd_diag_loop1 > 5')

         add_diag(1)=200*add_diag(1)
         write(ounit,'(/,''Iteration '',i4,'' sampling run to generate new parms '')') iter
         write(ounit,'(''old energy'',2f12.5)') energy_sav,energy_err_sav
         write(ounit,'(''new energy'',2f12.5)') energy(1),energy_err(1)
         write(ounit,'(/,''Energy is worse, increase adiag to'',1pd11.4)') add_diag(1)
         call restore_wf(1)
         call compute_dparm(nparm,nparmall,lwork_all_save,grad,h,h_sav,s,s_sav,work,work2,
     &                     add_diag(1),energy_sav,energy_err_sav)
         call compute_parameters(grad,iflag,1)
c In case starting config is very bad, reset configuration by calling sites
         vmc_isite=1
         call reset_configs_start
         if(ioptci_sav.ne.0.and.nstates.gt.1.and.(ioptorb.ne.0.or.ioptjas.ne.0)) then
c This case should never happen
           call fatal_error('OPTWF: Multiple state - Energy already checked: CI run too short?')
          else
           goto 200
         endif
       endif
      endif

c Save current energy and sigma
      energy_sav=energy(1)
      energy_err_sav=energy_err(1)

      write(ounit,'(/,''Current energy = '',f12.7,'' +- '',f11.7)') energy_sav,energy_err_sav
      energy_plus_err=energy(1)+2*energy_err(1)
      if(energy_plus_err.lt.energy_plus_err_best) then
        write(ounit,'(/,''Current best energy + 2*error = '',f11.4)') energy_plus_err
        energy_plus_err_best=energy_plus_err
        call save_wf_best(ioptjas_sav,ioptorb_sav,ioptci_sav)
      endif

      call save_wf

      call setup_optimization(nparm,nparmall,MWORK,lwork,h,h_sav,s,s_sav,work,work2,add_diag(1),iter)
      if(iter.eq.1) lwork_all_save=lwork

c Compute corrections to parameters
    6 write(ounit,'(/,''Compute parameters 1'',/)')
      call compute_dparm(nparm,nparmall,lwork_all_save,grad,h,h_sav,s,s_sav,work,work2,
     &                     add_diag(1),energy_sav,energy_err_sav)

      call test_solution_parm(nparm,grad,dparm_norm,dparm_norm_min,add_diag(1),iflag)
      if(iflag.ne.0) then
       write(ounit,'(''Warning: add_diag_1 has dparm_norm>1'')')
       add_diag(1)=10*add_diag(1)
       write(ounit,'(''adiag_1 increased to '',g12.5)') add_diag(1)
       go to 6
      endif

c     write(ounit,'(/,''change in parameters 1'')')
c     write(ounit,'(''-x='',9f15.9)') (-grad(i),i=1,nparm)

c Compute new parameters
      call compute_parameters(grad,iflag,1)
      if(iflag.ne.0) then
        write(ounit,'(''Warning: add_diag_1 has problems with a2 and/or b2'')')
        call restore_wf(1)
        add_diag(1)=10*add_diag(1)
        write(ounit,'(''adiag_1 increased to '',g12.5)') add_diag(1)
        go to 6
      endif

      if(multiple_adiag.ne.0) then

       nforce=3
       nwftype=3
       call setup_wf

       do iadiag=2,3

c add_diag=add_diag*10
        add_diag(iadiag)=10**(iadiag-1)*add_diag(1)

        call restore_wf(iadiag)
        write(ounit,'(/,''Compute parameters '',i1,/)') iadiag
   10   call compute_dparm(nparm,nparmall,lwork_all_save,grad,h,h_sav,s,s_sav,work,work2,
     &                     add_diag(iadiag),energy_sav,energy_err_sav)

        call test_solution_parm(nparm,grad,dparm_norm,dparm_norm_min,add_diag(iadiag),iflag)
        if(iflag.ne.0) then
          write(ounit,'(''Warning: adiag_'',i1,'' has dparm_norm>1'')') iadiag
          add_diag(1)=2*10**(iadiag-1)*add_diag(1)
          write(ounit,'(''adiag_1 increased to '',g12.5)') add_diag(1)
          go to 6
        endif
c       write(ounit,'(/,''change in parameters '',i1)') iadiag
c       write(ounit,'(''-x='',9f15.9)') (-grad(i),i=1,nparm)
        call compute_parameters(grad,iflag,iadiag)
        if(iflag.ne.0) call fatal_error('OPTWF: adiag_1 or 2 still has problems')
       enddo

       write(ounit,'(/,''adiag1,adiag2,adiag3'',1p3g15.8,/)') (add_diag(i),i=1,3)
       write(ounit,'(/,''Correlated sampling test run for adiag'',/)')

       ioptjas=0
       ioptorb=0
       ioptci=0

c Test run for adiag_1,2,3 with correlated sampling
       nblk_sav=vmc_nblk
       vmc_nblk=max(2,vmc_nblk/2)
c      vmc_nblk=max(2,vmc_nblk/10)

       call qmc

       ioptjas=ioptjas_sav
       ioptorb=ioptorb_sav
       ioptci=ioptci_sav
       if(ioptci.ne.0.and.nstates.gt.1.and.(ioptorb.ne.0.or.ioptjas.ne.0)) ioptci=0

       vmc_nblk=nblk_sav

c Check if something is very wrong in correlated sampling run
       denergy_min=1.d+99
       denergy_max=0
       do k=1,3
         if(energy_err(k).gt.denergy_max) then
           denergy_max=energy_err(k)
           k_demax=k
         endif
         if(energy_err(k).lt.denergy_min) then
           denergy_min=energy_err(k)
           k_demin=k
         endif
       enddo
       if(denergy_max/denergy_min.gt.10) then
         write(ounit,'(/,''Problem with correlated sampling run'')')
         write(ounit,'(''e,demin,e,demax'',2(f12.5,'' +- '',f12.5))')
     &   energy(k_demin),denergy_min,energy(k_demax),denergy_max

         if(k_demax.eq.1) then
           add_diag(1)=add_diag(1)*20
          else
           add_diag(1)=add_diag(1)*200
         endif
         write(ounit,'(''adiag_1 increased to '',g12.5)') add_diag(1)
         write(ounit,'(''generate again parameters for correlated sampling'')')

         call restore_wf(1)
c In case starting config is very bad, reset configuration by calling sites
         vmc_isite=1
         call reset_configs_start

         energy(1)=energy_sav
         go to 6
       endif

       de_worse1=energy(1)-energy_sav
       de_worse2=energy(2)-energy_sav
       de_worse3=energy(3)-energy_sav
       de_worse_err1=sqrt(energy_err(1)**2+energy_err_sav**2)
       de_worse_err2=sqrt(energy_err(2)**2+energy_err_sav**2)
       de_worse_err3=sqrt(energy_err(3)**2+energy_err_sav**2)
       write(ounit,'(/,''adiag, correlated energies, forces'')')
       do k=1,3
         if(k.eq.1) then
           write(ounit,'(g15.5,f12.5,'' +- '',f12.5)') add_diag(k),energy(k),energy_err(k)
          else
           write(ounit,'(g15.5,f12.5,'' +- '',f12.5,e12.5,'' +- '',e12.5)')
     &      add_diag(k), energy(k),energy_err(k),force(k),force_err(k)
         endif
       enddo
       write(ounit,'(''old energy'',2f12.5)') energy_sav,energy_err_sav
       write(ounit,'(''energy_adiag1-energy_old'',3f12.5)') de_worse1,de_worse_err1,3*de_worse_err1
       write(ounit,'(''energy_adiag2-energy_old'',3f12.5)') de_worse2,de_worse_err2,3*de_worse_err2
       write(ounit,'(''energy_adiag3-energy_old'',3f12.5)') de_worse3,de_worse_err3,3*de_worse_err3

c      if(de_worse2.gt.3*de_worse_err2.or.de_worse3.gt.3*de_worse_err3) then
       if(de_worse3.gt.3*de_worse_err3) then
c        write(ounit,'(/,''energy_adiag2_3 is much worse than old energy'')')
         write(ounit,'(/,''energy_adiag3 is much worse than old energy'')')

         add_diag(1)=add_diag(1)*200
         write(ounit,'(''adiag_1 increased to '',g12.5)') add_diag(1)
         write(ounit,'(''generate again parameters for correlated sampling'')')

         call restore_wf(1)
c In case starting config is very bad, reset configuration by calling sites
         vmc_isite=1
         call reset_configs_start

         energy(1)=energy_sav
         go to 6
       endif

       write(ounit,'(/,''find optimal adiag'')')
c Find optimal a_diag
       call quad_min

       call restore_wf(1)

   7   call compute_dparm(nparm,nparmall,lwork_all_save,grad,h,h_sav,s,s_sav,work,work2,
     &                     add_diag(1),energy_sav,energy_err_sav)

       call test_solution_parm(nparm,grad,dparm_norm,dparm_norm_min,add_diag(1),iflag)
       if(iflag.ne.0) then
        write(ounit,'(''Warning: adiag_optimal has dparm_norm>1'')')
        add_diag(1)=200*add_diag(1)
        write(ounit,'(''adiag_1 increased to '',g12.5)') add_diag(1)
        call restore_wf(1)
        go to 7
       endif

c      write(ounit,'(/,''Optimal change in parameters'')')
c      write(ounit,'(''-x='',9f15.9)') (-grad(i),i=1,nparm)

c Compute new parameters
       write(ounit,'(/,''Compute parameters for optimal adiag'')')
       call compute_parameters(grad,iflag,1)
       if(iflag.ne.0) then
         write(ounit,'(''Warning: adiag_optimal has problems'')')
         add_diag(1)=200*add_diag(1)
         write(ounit,'(''adiag_1 increased to '',g12.5)') add_diag(1)
         call restore_wf(1)
         go to 7
       endif

       call write_wf(1,iter)

       call check_length_run(iter,increase_nblk,vmc_nblk,vmc_nblk_max,denergy,denergy_err,energy_err_sav,energy_tol)

       add_diag(1)=0.1d0*add_diag(1)
      else
       call write_wf(1,iter)
c endif for multiple_adiag
      endif

      ioptjas=ioptjas_sav
      ioptorb=ioptorb_sav
      ioptci=ioptci_sav

c CI step for state average of multiple states
      if(ioptci.ne.0.and.nstates.gt.1.and.(ioptorb+ioptjas.gt.0)) then
  800   ioptjas=0
        ioptorb=0
        ioptci=ioptci_sav

        nforce=1
        nwftype=1

        add_diag_sav=add_diag(1)
        add_diag(1)=-1

        call set_nparms

        nblk_sav=vmc_nblk
        vmc_nblk=vmc_nblk_ci
        call qmc
        vmc_nblk=nblk_sav

        call combine_derivatives

        if(iter.ge.1) then
          denergy=energy(1)-energy_sav
          denergy_err=sqrt(energy_err(1)**2+energy_err_sav**2)

          if(denergy.gt.3*denergy_err) then
            iadd_diag_loop1=iadd_diag_loop1+1
            if(iadd_diag_loop1.gt.5) call fatal_error('OPTWF: energy went up a lot and iadd_diag_loop1 > 5')

c add_diag used to generate current Jastrow+orbitals was divided by 10 before the end of the loop 900
c           add_diag(1)=20*add_diag_sav
            add_diag(1)=200*add_diag_sav
            write(ounit,'(/,''Iteration '',i4,'' sampling run to generate new CI coefs'')') iter
            write(ounit,'(''old energy'',2f12.5)') energy_sav,energy_err_sav
            write(ounit,'(''new energy'',2f12.5)') energy(1),energy_err(1)
            write(ounit,'(/,''Energy is worse, increase adiag to '',1pd11.4)') add_diag(1)

c Jastrow and orbital parameters give worse energy
            ioptjas=ioptjas_sav
            ioptorb=ioptorb_sav
            ioptci=0

            call set_nparms

            call restore_wf(1)
            call compute_dparm(nparm,nparmall,lwork_all_save,grad,h,h_sav,s,s_sav,work,work2,
     &                     add_diag(1),energy_sav,energy_err_sav)
            call compute_parameters(grad,iflag,1)
c In case starting config is very bad, reset configuration by calling sites
            vmc_isite=1
            call reset_configs_start

            call write_wf(1,iter)
            goto 800
          endif
        endif

        call setup_optimization(nparm,nparmall,MWORK,lwork,h,h_sav,s,s_sav,work,work2,add_diag(1),iter)
        if(iter.eq.1) lwork_ci_save=lwork

        write(ounit,'(/,''Compute CI parameters'',/)')
        call compute_dparm(nparm,nparmall,lwork_ci_save,grad,h,h_sav,s,s_sav,work,work2,
     &                     add_diag(1),energy(1),energy_err(1))

        call compute_parameters(grad,iflag,1)

c save CI coefficients
        call save_wf
        call write_wf(1,iter)

c save orb and jastrow
        ioptjas=ioptjas_sav
        ioptorb=ioptorb_sav
        ioptci=0
        call save_wf

        add_diag(1)=add_diag_sav

        call set_nparms
c endif CI step for multiple states
      endif

c end of optimization loop
      enddo

 950  nforce=1

      ioptjas=0
      ioptorb=0
      ioptci=0

      if(ilastvmc.eq.0) go to 970

      call qmc
      write(ounit,'(/,''Current energy = '',f12.7,'' +- '',f11.7)') energy(1),energy_err(1)
      energy_plus_err=energy(1)+2*energy_err(1)
      if(energy_plus_err.lt.energy_plus_err_best) then
        write(ounit,'(/,''Current best energy + 2*error = '',f11.4)') energy_plus_err
        energy_plus_err_best=energy_plus_err
        call save_wf_best(ioptjas_sav,ioptorb_sav,ioptci_sav)
      endif

 970  ioptjas=ioptjas_sav
      ioptorb=ioptorb_sav
      ioptci=ioptci_sav
      nadorb_sav=nadorb

      call write_wf_best

      deallocate(grad_sav)
      deallocate(h_sav)
      deallocate(s_sav)
      deallocate(work)
      deallocate(work2)

      return
      end
c-----------------------------------------------------------------------
      subroutine check_length_run(iter,increase_nblk,nblk,nblk_max,denergy,denergy_err,energy_err_sav,energy_tol)

      use contrl_file, only: ounit
      use precision_kinds, only: dp
      implicit none

      integer :: increase_nblk, iter, nblk, nblk_max, nblk_new
      real(dp) :: denergy, denergy_err, energy_err_sav, energy_tol

c Increase nblk if near convergence to value needed to get desired statistical error
      increase_nblk=increase_nblk+1

c Check if energies for 3 different values of a_diag are less than the tolerance
c     energy_min= 1.d99
c     energy_max=-1.d99
c     do 5 k=1,3
c       energy_min=min(energy_min,energy(k))
c   5   energy_max=max(energy_max,energy(k))
c     e_diff=energy_max-energy_min
c     write(ounit,'(''iter,e_diff='',i4,d12.4)') iter,e_diff
c
c     dforce2=force_err(2)-energy_tol
c     dforce3=force_err(2)-energy_tol
c     if(e_diff.lt.energy_tol.and.dforce2.lt.0.and.dforce3.lt.0) then
c       nblk_new=nblk*max(1.d0,(energy_err_sav/energy_tol)**2)
c       nblk_new=min(nblk_new,nblk_max)
c       if(nblk_new.gt.nblk) then
c         increase_nblk=0
c         nblk=nblk_new
c         write(ounit,'(''nblk reset to'',i8,9d12.4)') nblk,energy_err(1),energy_tol
c       endif
c       write(ounit,'(''energy differences for different add_diag converged to'',d12.4)') energy_tol
c       goto 950
c     endif

c Increase if subsequent energies are within errorbar
      if(iter.gt.2.and.dabs(denergy).lt.3*denergy_err) then
        nblk_new=nblk*max(1.d0,(energy_err_sav/energy_tol)**2)
        nblk_new=min(nblk_new,nblk_max)
        if(nblk_new.gt.nblk) then
          increase_nblk=0
          nblk=nblk_new
          write(ounit,'(''nblk reset to'',i8,9d12.4)') nblk,dabs(denergy),energy_tol
        endif
      endif
c Always increase nblk by a factor of 2 every other iteration
      if(increase_nblk.eq.2.and.nblk.lt.nblk_max) then
        increase_nblk=0
        nblk=min(2*nblk,nblk_max)
        write(ounit,'(''nblk reset to'',i8,9d12.4)') nblk
      endif

      return
      end
c-----------------------------------------------------------------------
      subroutine quad_min

      use contrl_file, only: ounit
      use optwf_corsam, only: add_diag,energy,force,force_err
      use optwf_lib, only: chlsky,lxb,uxb
      use precision_kinds, only: dp
      use read_bas_num_mod, only: read_bas_num
      implicit none

      integer :: i, ierr, iwadd_diag, j, k
      integer :: k_min, nfunc, npts
      integer, parameter :: MFUNC = 3
      real(dp) :: add_diag_log_min, add_diag_min, ee, energy_max
      real(dp) :: energy_min, energy_var, eopt, rms
      real(dp), dimension(MFUNC) :: add_diag_log
      real(dp), dimension(MFUNC,MFUNC) :: a
      real(dp), dimension(MFUNC) :: b

      npts=3
      nfunc=3

      do k=1,npts
        add_diag_log(k)=dlog10(add_diag(k))
      enddo

      do i=1,nfunc
        b(i)=0
        do k=1,npts
          b(i)=b(i)+energy(k)*add_diag_log(k)**(i-1)
        enddo
        do j=1,i
          a(i,j)=0
          do k=1,npts
            a(i,j)=a(i,j)+add_diag_log(k)**(i+j-2)
          enddo
          a(j,i)=a(i,j)
        enddo
      enddo

c Do cholesky decomposition
      call chlsky(a,nfunc,MFUNC,ierr)
      if(ierr.ne.0) stop 'ierr ne 0 in chlsky'

c Symmetrize decomposed matrix (needs to be done before calling uxb
c or need to modify uxb)
      do i=1,nfunc
        do j=i+1,nfunc
          a(i,j)=a(j,i)
        enddo
      enddo

c Solve linear equations
      call lxb(a,nfunc,MFUNC,b)
      call uxb(a,nfunc,MFUNC,b)

      write(ounit,'(''polinomial coeffcients b1+b2*adiag+b3*adiag^2'',f12.5,1p2e12.4)') (b(i),i=1,nfunc)
      energy_min= 1.d99
      energy_max=-1.d99
      rms=0
      do k=1,npts
        ee=b(1)+b(2)*add_diag_log(k)+b(3)*add_diag_log(k)**2
        write(ounit,'(''fit log(adiag),e_fit,e '',3f12.5)') add_diag_log(k),ee,energy(k)
        if(energy(k).lt.energy_min) then
          k_min=k
          energy_min=energy(k)
        endif
        energy_max=max(energy_max,energy(k))
        rms=rms+(ee-energy(k))**2
      enddo
      rms=dsqrt(rms/npts)
      write(ounit,'(''rms error in fit of energy to get optimal add_diag is'',d12.4)') rms

      energy_var=energy_max-energy_min
      if(b(3).gt.0.and.abs(force(2)).gt.3*force_err(2).and.abs(force(3)).gt.3*force_err(3)) then
        iwadd_diag=0
        add_diag_log_min=-0.5d0*b(2)/b(3)
        add_diag_log_min=min(max(add_diag_log_min,add_diag_log(1)-1),add_diag_log(1)+3)
        write(ounit,'(/,''computed optimal adiag '',g12.4)') 10**add_diag_log_min
        eopt=b(1)+b(2)*add_diag_log_min+b(3)*add_diag_log_min**2
        write(ounit,'(/,''computed optimal energy'',f12.5)') eopt
       elseif(energy(1).lt.energy(2)+force_err(2).and.energy_var.lt.1.d-3*abs(energy_max)) then
        iwadd_diag=1
        add_diag_log_min=add_diag_log(1)
        if(energy(1).lt.energy(2).and.add_diag_log_min.ge.0.d0) add_diag_log_min=add_diag_log_min-1.d0
       elseif(energy(2).lt.energy(3)+force_err(3).and.energy_var.lt.1.d-2*abs(energy_max).and.k_min.eq.3) then
        iwadd_diag=2
        add_diag_log_min=add_diag_log(2)
       else
        iwadd_diag=k_min
        write(ounit,'(/,''b3 < 0 or error on one force too large'')')
        add_diag_log_min=add_diag_log(k_min)
        if(k_min.eq.1.and.energy(1).lt.energy(2).and.add_diag_log_min.ge.0.d0) add_diag_log_min=add_diag_log_min-1.d0
      endif
      add_diag_log_min=max(add_diag_log_min,-6*1.d0)
      add_diag_min=10**add_diag_log_min
      write(ounit,'(/,''optimal adiag '',i2,g12.4,/)') iwadd_diag,add_diag_min

      add_diag(1)=add_diag_min

      return
      end
c-----------------------------------------------------------------------
      subroutine combine_derivatives

      use ci000,   only: nciterm
      use contrl_file, only: ounit
      use gradhess_all, only: h,s
      use gradhess_ci, only: h_ci,s_ci
      use gradhess_jas, only: h_jas,s_jas
      use gradhess_mix_jas_ci, only: h_mix_jas_ci,s_mix_jas_ci
      use gradhess_mix_jas_orb, only: h_mix_jas_orb,s_mix_jas_orb
      use gradhess_mix_orb_ci, only: h_mix_ci_orb,s_mix_ci_orb
      use optorb_cblock, only: nreduced
      use optwf_control, only: ioptci,ioptjas,ioptorb,method,nparm
      use optwf_parms, only: nparmj
      implicit none

      integer :: i, i0, is, ishift, j

c     common /gradhess_orb/ grad_orb(norbterm),h_orb(MXMATDIM),s_orb(MXMATDIM)

c Note: we do not vary the first (i0) CI coefficient unless full CI

      if(method.eq.'linear') then

       is=1
       i0=0
       ishift=1
       if(ioptjas.eq.0) go to 115

c Jastrow Hamiltonian
       do j=1,nparmj+is
         do i=1,nparmj+is
           h(i,j)=h_jas(i,j)
           s(i,j)=s_jas(i,j)
         enddo
       enddo

c      do 111 i=1,nparmj+1
c 111    write(ounit,'(''h1= '',1000d12.5)') (h(i,j),j=1,nparmj+1)
c      do 112 i=1,nparmj+1
c 112    write(ounit,'(''h1= '',1000d12.5)') (s(i,j),j=1,nparmj+1)

       ishift=nparmj+is

  115  continue

       if(ioptci.eq.0) go to 135

       if(ioptjas.eq.0.and.ioptorb.eq.0) then
        is=0
        i0=0
        ishift=0
       else
        i0=1
        h(1,1)=h_ci(1,1)
        s(1,1)=s_ci(1,1)
        do i=1,nciterm-i0
          h(ishift+i,1)=h_ci(i+i0+is,1)
          h(1,ishift+i)=h_ci(1,i+i0+is)
          s(ishift+i,1)=s_ci(i+i0+is,1)
          s(1,ishift+i)=s_ci(1,i+i0+is)
        enddo
       endif

c CI Hamiltonian
       do j=1,nciterm-i0
         do i=1,nciterm-i0
           h(ishift+i,ishift+j)=h_ci(i+i0+is,j+i0+is)
           s(ishift+i,ishift+j)=s_ci(i+i0+is,j+i0+is)
         enddo
       enddo

c      write(ounit,'(''h2 shift ='',i4)') ishift
c      do 121 i=1,nciterm-i0
c 121    write(ounit,'(''h2= '',1000f12.5)') (h_ci(i+i0+is,j+i0+is),j=1,nciterm-i0)

c Jastrow-CI Hamiltonian
       do j=1,nciterm-i0
         do i=1,nparmj
           h(i+1,j+ishift)=h_mix_jas_ci(i,j+i0)
           h(j+ishift,i+1)=h_mix_jas_ci(i+nparmj,j+i0)
           s(i+1,j+ishift)=s_mix_jas_ci(i,j+i0)
           s(j+ishift,i+1)=s_mix_jas_ci(i,j+i0)
         enddo
       enddo

c      do 131 i=1,nparmj
c        write(ounit,'(''h3= '',1000f12.5)') (h_mix_jas_ci(i,j+i0),j=1,nciterm-i0)
c 131    write(ounit,'(''h3= '',1000f12.5)') (h_mix_jas_ci(i+nparmj,j+i0),j=1,nciterm-i0)

       ishift=ishift+nciterm-i0

  135  continue

       if(ioptorb.eq.0) go to 175

c      h(1,1)=h_orb(1)
c      s(1,1)=s_orb(1)
c      do 140 i=1,nreduced
c        ik=i*(nreduced+1)
c        h(ishift+i,1)=h_orb(i+1)
c        h(1,ishift+i)=h_orb(ik+1)
c        s(ishift+i,1)=s_orb(i+1)
c 140    s(1,ishift+i)=s_orb(ik+1)

c ORB Hamiltonian
c     do 150 j=1,nreduced
c       jk=j*(nreduced+1)
c        do 150 i=1,nreduced
c          h(ishift+i,ishift+j)=h_orb(i+1+jk)
c 150      s(ishift+i,ishift+j)=s_orb(i+1+jk)

c Jastrow-ORB Hamiltonian
       do j=1,nreduced
         do i=1,nparmj
           h(i+1,j+ishift)=h_mix_jas_orb(i,j)
           h(j+ishift,i+1)=h_mix_jas_orb(i+nparmj,j)
           s(i+1,j+ishift)=s_mix_jas_orb(i,j)
           s(j+ishift,i+1)=s_mix_jas_orb(i,j)
         enddo
       enddo

c ORB-CI Hamiltonian
       do j=1,nreduced
         do i=1,nciterm-i0
           h(i+nparmj+1,j+ishift)=h_mix_ci_orb(i+i0,j)
           h(j+ishift,i+nparmj+1)=h_mix_ci_orb(i+nciterm+i0,j)
           s(i+nparmj+1,j+ishift)=s_mix_ci_orb(i+i0,j)
           s(j+ishift,i+nparmj+1)=s_mix_ci_orb(i+i0,j)
         enddo
       enddo

  175  nparm=nparmj+nciterm+nreduced-i0

       write(ounit,'(/,''number of parms: total, Jastrow, CI, orbitals= '',4i5)')
     & nparm,nparmj,nciterm,nreduced

c      do 180 i=1,nparm+1
c 180    write(ounit,'(''h= '',1000d12.5)') (h(i,j),j=1,nparm+1)
c      do 185 i=1,nparm+1
c 185    write(ounit,'(''s= '',1000d12.5)') (s(i,j),j=1,nparm+1)

      endif

      return
      end
      end module
