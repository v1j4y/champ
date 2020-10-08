ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

      subroutine pcg(n,b,x,i,imax,imod,eps)
c one-shot preconditioned conjugate gradients; convergence thr is residual.lt.initial_residual*eps**2 (after J.R.Shewchuck)

      use mpiconf, only: idtask
      implicit real*8(a-h,o-z)

      include 'mpif.h'
      integer m_parm_opt
      parameter(m_parm_opt=59000)
      integer n,imax,imod,i,j
      real*8 b(*),x(*),eps
      real*8 r(m_parm_opt),d(m_parm_opt),q(m_parm_opt),s(m_parm_opt)
      real*8 delta_0,delta_new,delta_old,alpha,beta,ddot

      if(n.gt.m_parm_opt) stop 'nparm > m_parm_opt'

      call atimes_n(n,x,r)         ! r=Ax neuscamman
      if(idtask.eq.0)then
       call daxpy(n,-1.d0,b,1,r,1)       ! r=r-b
       call dscal(n,-1.d0,r,1)           ! r=b-r
       call asolve(n,r,d)                ! d=M^{-1}r preconditioner
       delta_new=ddot(n,d,1,r,1)           ! \delta_new=r^T d
       print*,'delta0 = ',delta_new
      endif
      call MPI_BCAST(delta_new,1,MPI_REAL8,0,MPI_COMM_WORLD,j)
      delta_0=delta_new*eps**2            ! convergence thr
      do i=0,imax-1
c      write(*,*)i,idtask,'ECCO ',delta_0,delta_new 
       if(delta_new.lt.delta_0)then
        if(idtask.eq.0)print*,'CG iter ',i
c     write(*,*)'ECCO pcg esce ',idtask
        call MPI_BCAST(x,n,MPI_REAL8,0,MPI_COMM_WORLD,j)
        return
       endif
       call atimes_n(n,d,q)        ! q=Ad neuscamman
       if(idtask.eq.0)then
        alpha=delta_new/ddot(n,d,1,q,1)  ! \alpha=\delta_new/(d^T q)
        call daxpy(n,alpha,d,1,x,1)      ! x=x+\alpha d
       endif
       if(mod(i,imod).eq.0)then
        call atimes_n(n,x,r)       ! r=Ax neuscamman
        if(idtask.eq.0)then
         call daxpy(n,-1.d0,b,1,r,1)     ! r=r-b
         call dscal(n,-1.d0,r,1)         ! r=b-r
        endif
       else
        if(idtask.eq.0)call daxpy(n,-alpha,q,1,r,1)    ! r=r-\alpha q
       endif
       if(idtask.eq.0)then
        call asolve(n,r,s)               ! s=M^{-1}r preconditioner
        delta_old=delta_new              ! \delta_old=\delta_new
        delta_new=ddot(n,r,1,s,1)        ! \delta_new=r^T s
        print*,'delta_new ',delta_new
        beta=delta_new/delta_old         ! \beta=\delta_new/\delta_old
        call dscal(n,beta,d,1)           ! d=\beta d
        call daxpy(n,1.d0,s,1,d,1)       ! d=s+d
       endif
       call MPI_BCAST(delta_new,1,MPI_REAL8,0,MPI_COMM_WORLD,j)
      enddo

      if(idtask.eq.0)print*,'CG iter ',i
      call MPI_BCAST(x,n,MPI_REAL8,0,MPI_COMM_WORLD,j)
      return
      end

ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

      subroutine asolve(n,b,x)
c x(i)=b(i)/s(i,i) (preconditioning with diag(S))

      use sr_mat_n, only: s_ii_inv
      implicit real*8(a-h,o-z)



      dimension x(*),b(*)

      do i=1,n
       x(i)=b(i)*s_ii_inv(i)
      enddo

      return
      end

ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

      subroutine atimes_n(n,z,r)
c r=a*z, i cicli doppi su n e nconf_n sono parallelizzati

      use sr_mod, only: MPARM, MCONF
      use csfs, only: nstates

      use optwf_func, only: ifunc_omega, omega, omega_hes
      use sa_weights, only: weights
      use sr_index, only: jelo, jelo2, jelohfj
      use sr_mat_n, only: jefj, jfj, jhfj, nconf_n, s_diag, sr_ho
      use sr_mat_n, only: sr_o, wtg, obs_tot
      use optorb_cblock, only: norbterm

      ! as not in master ... 
      use mpiconf, only: idtask

      implicit real*8(a-h,o-z)

      include 'mpif.h'




      dimension z(*),r(*),aux(0:MCONF),aux1(0:MCONF),rloc(MPARM),r_s(MPARM),oz_jasci(MCONF)
      dimension tmp(MPARM),tmp2(MPARM)

      call MPI_BCAST(z,n,MPI_REAL8,0,MPI_COMM_WORLD,i)

      nparm_jasci=max(n-norbterm,0)

      do i=1,n
        r(i)=0.d0
      enddo

      if(ifunc_omega.eq.0) then 

      do iconf=1,nconf_n
        oz_jasci(iconf)=ddot(nparm_jasci,z,1,sr_o(1,iconf),1)
      enddo

      do istate=1,nstates
        wts=weights(istate)

        i0=nparm_jasci+(istate-1)*norbterm+1
        do iconf=1,nconf_n
          oz_orb=ddot(norbterm,z(nparm_jasci+1),1,sr_o(i0,iconf),1)
          aux(iconf)=(oz_jasci(iconf)+oz_orb)*wtg(iconf,istate)
        enddo

        do i=1,nparm_jasci
          rloc(i)=ddot(nconf_n,aux(1),1,sr_o(i,1),MPARM)
        enddo
        do i=nparm_jasci+1,n
          i0=i+(istate-1)*norbterm
          rloc(i)=ddot(nconf_n,aux(1),1,sr_o(i0,1),MPARM)
        enddo
        call MPI_REDUCE(rloc,r_s,n,MPI_REAL8,MPI_SUM,0,MPI_COMM_WORLD,i)
        
        if(idtask.eq.0)then
         aux0=ddot(n,z,1,obs_tot(jfj,istate),1)
         do i=1,n
          r(i)=r(i)+wts*(r_s(i)/obs_tot(1,istate)-obs_tot(jfj+i-1,istate)*aux0+s_diag(i,istate)*z(i))
         enddo
        endif

      enddo

      else
c ifunc_omega.gt.0

      if(ifunc_omega.eq.1.or.ifunc_omega.eq.2) omega_hes=omega

      do iconf=1,nconf_n
        hoz=ddot(n,z,1,sr_ho(1,iconf),1)
        oz=ddot(n,z,1,sr_o(1,iconf),1)
        aux(iconf)=(hoz-omega_hes*oz)*wtg(iconf,1)
      enddo
      do i=1,n
        rloc(i)=ddot(nconf_n,aux(1),1,sr_ho(i,1),MPARM)
        rloc(i)=rloc(i)-omega_hes*ddot(nconf_n,aux(1),1,sr_o(i,1),MPARM)
      enddo
      call MPI_REDUCE(rloc,r,n,MPI_REAL8,MPI_SUM,0,MPI_COMM_WORLD,i)

      if(idtask.eq.0) then

        do i=1,n
          r(i)=r(i)/obs_tot(1,1)+s_diag(1,1)*z(i)
        enddo

        var=omega_hes*omega_hes+obs_tot(jelo2,1)-2*omega_hes*obs_tot(jelo,1)

        do k=1,n
          tmp(k)=obs_tot(jelohfj+k-1,1)-omega_hes*obs_tot(jefj+k-1,1)-omega_hes*(obs_tot(jhfj+k-1,1)-omega_hes*obs_tot(jfj+k-1,1))
        enddo

        aux0=ddot(n,z,1,tmp(1),1)
        aux2=ddot(n,z,1,obs_tot(jfj,1),1)
        do i=1,n
          r(i)=r(i)-tmp(i)*aux2-obs_tot(jfj+i-1,1)*aux0+var*obs_tot(jfj+i-1,1)*aux2
        enddo

        do k=1,n
          tmp(k)=obs_tot(jhfj+k-1,1)-obs_tot(jelo,1)*obs_tot(jfj+k-1,1)
        enddo
        aux3=ddot(n,z,1,tmp(1),1)
        do i=1,n
          r(i)=r(i)-tmp(i)*aux3
        enddo

        do k=1,n
          tmp2(k)=obs_tot(jefj+k-1,1)-obs_tot(jelo,1)*obs_tot(jfj+k-1,1)
        enddo
        aux4=ddot(n,z,1,tmp2(1),1)
        do i=1,n
          r(i)=r(i)-tmp(i)*aux4-tmp2(i)*aux3
        enddo

      endif
c endif idtask.eq.0

      endif

      return
      end

ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      subroutine sr_rescale_deltap(nparm,deltap)

      use mpiconf, only: idtask
      use sr_mat_n, only: jefj, jfj, jhfj
      use sr_mat_n, only: obs_tot

      ! again I have no idea ... 
      use sr_index, only: jelo, jelo2, jelohfj



      implicit real*8(a-h,o-z)



      include 'mpif.h'


      dimension deltap(*)

      call p2gtid('optwf:sr_rescale',i_sr_rescale,0,1)
      if(i_sr_rescale.eq.0) return

      jwtg=1
      jelo=2
      n_obs=2
      jfj=n_obs+1
      n_obs=n_obs+nparm
      jefj=n_obs+1
      n_obs=n_obs+nparm
      jfifj=n_obs+1
      n_obs=n_obs+nparm

      jhfj=n_obs+1
      n_obs=n_obs+nparm
      jfhfj=n_obs+1
      n_obs=n_obs+nparm

      jelo2=n_obs+1
      n_obs=n_obs+1
      jelohfj=n_obs+1
      n_obs=n_obs+nparm

      if(idtask.eq.0) then
        do i=1,nparm
          write(6,*) 'CIAO',obs_tot(jfhfj+i-1,1)/obs_tot(jfifj+i-1,1),obs_tot(jelo,1),
     &    obs_tot(jfhfj+i-1,1)/obs_tot(jfifj+i-1,1)-obs_tot(jelo,1)
          deltap(i)=deltap(i)/(obs_tot(jfhfj+i-1,1)/obs_tot(jfifj+i-1,1)-obs_tot(jelo,1))
        enddo
      endif

      call MPI_BCAST(deltap,nparm,MPI_REAL8,0,MPI_COMM_WORLD,j)

      return 
      end
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

      subroutine compute_position_bcast

      use atom, only: ncent
      use force_fin, only: da_energy_ave
      use force_analy, only: iforce_analy

      implicit real*8(a-h,o-z)

      include 'mpif.h'


      if(iforce_analy.eq.0)return

      call MPI_BCAST(da_energy_ave,3*ncent,MPI_REAL8,0,MPI_COMM_WORLD,i)

      return
      end
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

      subroutine forces_zvzb(nparm)

      use sr_mod, only: MPARM
      use atom, only: ncent

      use force_fin, only: da_energy_ave
      use force_mat_n, only: force_o
      use mpiconf, only: idtask
      use sr_mat_n, only: elocal, jefj, jfj, jhfj, nconf_n, obs, sr_ho
      use sr_mat_n, only: sr_o, wtg

      ! again I have no idea ... 
      use sr_index, only: jelo

      implicit real*8(a-h,o-z)


      include 'mpif.h'

      parameter (MTEST=1500)
      dimension cloc(MTEST,MTEST),c(MTEST,MTEST),oloc(MPARM),o(MPARM),p(MPARM),tmp(MPARM)
      dimension ipvt(MTEST),work(MTEST)

      if(nparm.gt.MTEST) stop 'MPARM>MTEST'

      jwtg=1
      jelo=2
      n_obs=2
      jfj=n_obs+1
      n_obs=n_obs+nparm
      jefj=n_obs+1
      n_obs=n_obs+nparm
      jfifj=n_obs+1
      n_obs=n_obs+nparm

      jhfj=n_obs+1
      n_obs=n_obs+nparm
      jfhfj=n_obs+1
      n_obs=n_obs+nparm

      do 10 i=1,nparm
        do 10 j=i,nparm
  10      cloc(i,j)=0.d0

      do l=1,nconf_n
        do i=1,nparm
          tmp(i)=(sr_ho(i,l)-elocal(l,1)*sr_o(i,l))*sqrt(wtg(l,1))
        enddo
        do k=1,nparm
          do j=k,nparm
            cloc(k,j)=cloc(k,j)+tmp(k)*tmp(j)
          enddo
        enddo
      enddo

      call MPI_REDUCE(cloc,c,MTEST*nparm,MPI_REAL8,MPI_SUM,0,MPI_COMM_WORLD,i)

      if(idtask.eq.0) then

        wtoti=1.d0/obs(1,1)
        do 20 i=1,nparm
          dum=(obs(jhfj+i-1,1)-obs(jefj+i-1,1))
          c(i,i)=c(i,i)*wtoti-dum*dum
          do 20 j=i+1,nparm
            c(i,j)=c(i,j)*wtoti-dum*(obs(jhfj+j-1,1)-obs(jefj+j-1,1))
  20        c(j,i)=c(i,j)

        call dgetrf(nparm,nparm,c,MTEST,ipvt,info)
        if(info.gt.0) then
          write(6,'(''MATINV: u(k,k)=0 with k= '',i5)') info
          call fatal_error('MATINV: info ne 0 in dgetrf')
        endif
        call dgetri(nparm,c,MTEST,ipvt,work,MTEST,info)

c ZVZB
c       do 30 iparm=1,nparm
c 30      tmp(iparm)=obs(jhfj+iparm-1,1)+obs(jefj+iparm-1,1)-2*obs(2,1)*obs(jfj+iparm-1,1)

c ZV
        do 30 iparm=1,nparm
  30      tmp(iparm)=obs(jhfj+iparm-1,1)-obs(jefj+iparm-1,1)
     
      endif

      energy_tot=obs(2,1)

      call MPI_BCAST(energy_tot,1,MPI_REAL8,0,MPI_COMM_WORLD,j)

      ia=0
      ish=3*ncent
      do icent=1,ncent
        write(6,'(''FORCE before'',i4,3e15.7)') icent,(da_energy_ave(k,icent),k=1,3)
        do k=1,3
          ia=ia+1

c         test=0.d0
c         do l=1,nconf_n
c           test=test+(force_o(ia+ish,l)-2*obs(2,1)*force_o(ia,l))*wtg(l,1)*wtoti
c         enddo
c         write(6,*) 'TEST ',test
         
          do i=1,nparm
            oloc(i)=0.d0
            do l=1,nconf_n
              oloc(i)=oloc(i)+(sr_ho(i,l)-elocal(l,1)*sr_o(i,l))*
     &                        (force_o(ia+ish,l)-2*energy_tot*force_o(ia,l))*wtg(l,1)
            enddo
          enddo

          call MPI_REDUCE(oloc,o,nparm,MPI_REAL8,MPI_SUM,0,MPI_COMM_WORLD,i)

          if(idtask.eq.0) then
            do i=1,nparm
              o(i)=o(i)*wtoti-(obs(jhfj+i-1,1)-obs(jefj+i-1,1))*da_energy_ave(k,icent)
            enddo
            do iparm=1,nparm
              p(iparm)=0.d0
              do jparm=1,nparm
                p(iparm)=p(iparm)+c(iparm,jparm)*o(jparm)
              enddo
              p(iparm)=-0.5*p(iparm)
            enddo

            force_tmp=da_energy_ave(k,icent)
            do iparm=1,nparm
              force_tmp=force_tmp+p(iparm)*tmp(iparm)
            enddo
            da_energy_ave(k,icent)=force_tmp

          endif
        enddo
        write(6,'(''FORCE after '',i4,3e15.7)') icent,(da_energy_ave(k,icent),k=1,3)
      enddo
          
      return
      end

