      subroutine finwrt_more
c written by Claudia Filippi

      use csfs, only: nstates
      use estcum, only: iblk
      use estpsi, only: apsi, aref, detref
      use mpiconf, only: nproc
      use optwf_corsam, only: energy, energy_err, force, force_err
      use contrl, only: nstep
      use sa_check, only: energy_all, energy_err_all
      use mpi
      use precision_kinds, only: dp

      implicit none

      integer :: iab, ierr, istate
      real(dp) :: passes, sigma


c     dimension istatus(MPI_STATUS_SIZE)

      passes=dfloat(iblk*nstep)
      write(6,'(''average psid, det_ref '',2d12.5)') (apsi(istate)*nproc/passes,istate=1,nstates),aref*nproc/passes
      write(6,'(''log detref '',2d12.5)') (detref(iab)*nproc/passes,iab=1,2)

c     if(wid) then
c       do 20 id=1,nproc-1
c         call mpi_send(energy,3,mpi_double_precision,id
c    &    ,1,MPI_COMM_WORLD,ierr)
c         call mpi_send(energy_err,3,mpi_double_precision,id
c    &    ,2,MPI_COMM_WORLD,ierr)
c         call mpi_send(force,3,mpi_double_precision,id
c    &    ,3,MPI_COMM_WORLD,ierr)
c         call mpi_send(force_err,3,mpi_double_precision,id
c    &    ,4,MPI_COMM_WORLD,ierr)
c         call mpi_send(sigma,1,mpi_double_precision,id
c    &    ,5,MPI_COMM_WORLD,ierr)
c         call mpi_send(energy_all,nstates,mpi_double_precision,id
c    &    ,6,MPI_COMM_WORLD,ierr)
c 20      call mpi_send(energy_err_all,nstates,mpi_double_precision,id
c    &    ,7,MPI_COMM_WORLD,ierr)
c      else
c       call mpi_recv(energy,3,mpi_double_precision,0
c    &  ,1,MPI_COMM_WORLD,istatus,ierr)
c       call mpi_recv(energy_err,3,mpi_double_precision,0
c    &  ,2,MPI_COMM_WORLD,istatus,ierr)
c       call mpi_recv(force,3,mpi_double_precision,0
c    &  ,3,MPI_COMM_WORLD,istatus,ierr)
c       call mpi_recv(force_err,3,mpi_double_precision,0
c    &  ,4,MPI_COMM_WORLD,istatus,ierr)
c       call mpi_recv(sigma,1,mpi_double_precision,0
c    &  ,5,MPI_COMM_WORLD,istatus,ierr)
c       call mpi_recv(energy_all,nstates,mpi_double_precision,0
c    &  ,6,MPI_COMM_WORLD,istatus,ierr)
c       call mpi_recv(energy_err_all,nstates,mpi_double_precision,0
c    &  ,7,MPI_COMM_WORLD,istatus,ierr)
c     endif

      call mpi_bcast(energy,3,mpi_double_precision,0,MPI_COMM_WORLD,ierr)
      call mpi_bcast(energy_err,3,mpi_double_precision,0,MPI_COMM_WORLD,ierr)
      call mpi_bcast(force,3,mpi_double_precision,0,MPI_COMM_WORLD,ierr)
      call mpi_bcast(force_err,3,mpi_double_precision,0,MPI_COMM_WORLD,ierr)
      call mpi_bcast(sigma,1,mpi_double_precision,0,MPI_COMM_WORLD,ierr)
      call mpi_bcast(energy_all,nstates,mpi_double_precision,0,MPI_COMM_WORLD,ierr)
      call mpi_bcast(energy_err_all,nstates,mpi_double_precision,0,MPI_COMM_WORLD,ierr)

      return
      end

