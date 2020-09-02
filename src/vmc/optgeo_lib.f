      subroutine write_geometry(iter)

      use atom, only: cent, iwctype, nctype, ncent

      implicit real*8(a-h,o-z)
      include 'vmc.h'

      character*40 filename,itn

      if(iter.lt.0) then
        filename='geo_optimal_final'
       else
        if(iter.lt.10) then
          write(itn,'(i1)') iter
         elseif(iter.lt.100) then
          write(itn,'(i2)') iter
         elseif(iter.lt.1000) then
          write(itn,'(i3)') iter
        endif
        filename='geo_optimal.iter'//itn(1:index(itn,' ')-1)
      endif

      open(2,file=filename,status='unknown')

      write(2,'(''# geometry iter '',i5)') iter
      write(2,'(''&atoms nctype '',i5,'' natom '',i5)') nctype,ncent
      write(2,'(''geometry'')')
      do 20 i=1,ncent
  20    write(2,'(3f14.6,i5)') (cent(k,i),k=1,3),iwctype(i)
      write(2,'(''end'')')

      close(2)

      return
      end

ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      subroutine compute_positions

        use coords_int
        use atom, only: cent, ncent

        use force_fin, only: da_energy_ave
        use zmatrix, only: czint, izcmat
      use force_analy, only: iforce_analy
      implicit real*8(a-h,o-z)


      
        include 'vmc.h'
        include 'force.h'
        
          
        if (iforce_analy.eq.0) return
        
        call compute_position_bcast
        
        if(iuse_zmat.eq.1) then
          call coords_init (ncent, cent, izcmat)
          call coords_compute_wilson (cent, izcmat)
          call coords_transform_gradients (da_energy_ave)
          call coords_compute_step (alfgeo)
          call coords_transform_step (czint, cent, izcmat)

          write (6,*) 'INTERNAL'
          do ic=1,ncent
            write (6,'(x 3f10.5)') czint(1:3, ic)
          enddo

          write (6,*) 'CENT'
          do ic=1,ncent
            write(6,'(3f10.5)') (cent(k,ic),k=1,3)
          enddo

        else
          do ic=1,ncent
            do k=1,3
              cent(k,ic)=cent(k,ic)-alfgeo*da_energy_ave(k,ic)
            enddo
            write(6,*)'CENT ',(cent(k,ic),k=1,3)
          enddo
        endif
        
        return
      end

ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

      subroutine force_store(l)

      use atom, only: ncent

      use da_energy_now, only: da_energy, da_psi
      use force_mat_n, only: force_o
      implicit real*8(a-h,o-z)



      include 'vmc.h'
      include 'sr.h'



      ii=0
      do 10 i=1,ncent
        do 10 k=1,3
          ii=ii+1
  10      force_o(ii,l)=da_psi(k,i)

      do 30 i=1,ncent
        do 30 k=1,3
          ii=ii+1
  30      force_o(ii,l)=da_energy(k,i)

      return
      end

