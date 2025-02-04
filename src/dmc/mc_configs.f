      module mc_configs_mod
      use branch,  only: eold,nwalk
      use config,  only: psido_dmc,psijo_dmc,xold_dmc
      use control, only: ipr
      use control_dmc, only: dmc_irstar,dmc_nblk,dmc_nblkeq,dmc_nconf
      use control_dmc, only: dmc_nconf_new,dmc_nstep
      use error,   only: fatal_error
      use general, only: write_walkalize
      use mpi
      use mpiconf, only: idtask,nproc
      use precision_kinds, only: dp
      use random_mod, only: random_dp,savern,setrn
      use restart, only: startr
      use system,  only: nelec
      implicit none
      integer, save :: ngfmc
      contains
      subroutine mc_configs

!      use contrl, only: irstar, nblk, nblkeq, nconf, nconf_new, nstep


      implicit none

      integer :: i, iblk, ic, id, ii
      integer :: index, ipass, iwalk, j
      integer :: jj
      integer, dimension(8) :: irn
      real(dp) :: rnd

      character(len=25) fmt
      character(len=20) filename


      if(write_walkalize) then
        if(idtask.le.9) then
          write(filename,'(''walkalize.'',i1)') idtask
         elseif(idtask.le.99) then
          write(filename,'(''walkalize.'',i2)') idtask
         elseif(idtask.le.999) then
          write(filename,'(''walkalize.'',i3)') idtask
         else
          call fatal_error('DMC: idtask > 999')
        endif
      endif

c set the random number seed, setrn already called in read_input

c Victor: 2023 In the parser the seed is now set differently on each processor
c         thus doing it here again should not be necessary

c     if(dmc_irstar.ne.1) then
c       if(nproc.gt.1) then
c         do id=1,(3*nelec)*idtask
c           rnd=random_dp()
c         enddo
c         call savern(irn)
c         do i=1,8
c           irn(i)=mod(irn(i)+int(random_dp()*idtask*9999),9999)
c         enddo
c         call setrn(irn)
c       endif
c     endif

      if (dmc_irstar.eq.1) then
        open(unit=10,status='old',form='unformatted',file='restart_dmc')
        rewind 10
        call startr
        close (unit=10)
       else
        open(unit=1,status='old',form='formatted',file='mc_configs')
        rewind 1
        do id=0,idtask
          do i=1,dmc_nconf
            read(1,fmt=*,end=340) ((xold_dmc(ic,j,i,1),ic=1,3),j=1,nelec)
          enddo
        enddo
        goto 345
  340   call fatal_error('DMC: error reading mc_configs')
  345   close (1)
        if(write_walkalize) then
          open(11,file=filename)
          rewind 11
          write(11,'(i3,'' nblkeq to be added to nblock at file end'')')
     &    dmc_nblkeq
        endif
      endif

c If nconf_new > 0, dump configurations for a future optimization or dmc calculation.
c Figure out frequency of configuration writing to produce nconf_new configurations.
c If nconf_new = 0, then no configurations are written.
      if (dmc_nconf_new.eq.0) then
        ngfmc=2*dmc_nstep*dmc_nblk
       else
        ngfmc=(dmc_nstep*dmc_nblk+dmc_nconf_new-1)*dmc_nconf/dmc_nconf_new
        if(idtask.lt.10) then
          write(filename,'(i1)') idtask
         elseif(idtask.lt.100) then
          write(filename,'(i2)') idtask
         elseif(idtask.lt.1000) then
          write(filename,'(i3)') idtask
         else
          write(filename,'(i4)') idtask
        endif
        filename='mc_configs_new'//filename(1:index(filename,' ')-1)
        open(unit=7,form='formatted',file=filename)
        rewind 7
      endif

      end subroutine

c-----------------------------------------------------------------------
      subroutine mc_configs_write(iblk,ipass)
      implicit none
      integer :: i, iblk, ic, id, ii
      integer :: index, ipass, iwalk, j
      integer :: jj
      integer, dimension(8) :: irn
      real(dp) :: rnd

      character(len=25) fmt
      character(len=20) filename

c Write out configuration for optimization/dmc/gfmc here
          if (iblk.gt.2*dmc_nblkeq .and. (mod(ipass,ngfmc).eq.1 .or.  ngfmc.eq.1)) then
            if(3*nelec.lt.100) then
              write(fmt,'(a1,i2,a21)')'(',3*nelec,'f14.8,i3,d12.4,f12.5)'
             else
              write(fmt,'(a1,i3,a21)')'(',3*nelec,'f14.8,i3,d12.4,f12.5)'
            endif
            do iwalk=1,nwalk
              write(7,fmt) ((xold_dmc(ii,jj,iwalk,1),ii=1,3),jj=1,nelec),
     &        int(sign(1.d0,psido_dmc(iwalk,1))),log(dabs(psido_dmc(iwalk,1)))+psijo_dmc(iwalk,1),eold(iwalk,1)
            enddo
          endif

      return
      end
      end module
