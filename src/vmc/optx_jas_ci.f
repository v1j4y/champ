      module optx_jas_ci
      contains
      subroutine optx_jas_ci_sum(p,q,enew,eold)

      use derivjas, only: gvalue
      use gradhessjo, only: denergy_old, gvalue_old
      use mix_jas_ci, only: de_o_ci, dj_de_ci, dj_o_ci, dj_oe_ci
      use optwf_control, only: ioptci, ioptjas
      use optwf_parms, only: nparmj
      use deloc_dj_m, only: denergy
      use ci000, only: nciterm
      use ci001_blk, only: ci_o
      use ci002_blk, only: ci_o_old
      use ci004_blk, only: ci_de, ci_de_old
      use precision_kinds, only: dp

      implicit none

      integer :: i, j
      real(dp) :: enew, eold, p, q

      if(ioptjas.eq.0.or.ioptci.eq.0) return

      do j=1,nciterm
         do i=1,nparmj
            dj_o_ci(i,j)=dj_o_ci(i,j)  +p*gvalue(i)*ci_o(j)+q*gvalue_old(i)*ci_o_old(j)
            dj_oe_ci(i,j)=dj_oe_ci(i,j)+p*gvalue(i)*ci_o(j)*enew+q*gvalue_old(i)*ci_o_old(j)*eold
            de_o_ci(i,j)=de_o_ci(i,j)  +p*denergy(i,1)*ci_o(j)+q*denergy_old(i,1)*ci_o_old(j)
            dj_de_ci(i,j)=dj_de_ci(i,j)+p*gvalue(i)*ci_de(j)+q*gvalue_old(i)*ci_de_old(j)
         enddo
      enddo

      return
      end
c-----------------------------------------------------------------------
      subroutine optx_jas_ci_init

      use mix_jas_ci, only: de_o_ci, dj_de_ci, dj_o_ci, dj_oe_ci
      use optwf_control, only: ioptci, ioptjas
      use optwf_parms, only: nparmj
      use ci000, only: nciterm

      implicit none

      integer :: i, j

      if(ioptjas.eq.0.or.ioptci.eq.0) return

      do i=1,nparmj
        do j=1,nciterm
          dj_o_ci(i,j)=0
          dj_oe_ci(i,j)=0
          de_o_ci(i,j)=0
          dj_de_ci(i,j)=0
        enddo
      enddo

      return
      end
c-----------------------------------------------------------------------
      subroutine optx_jas_ci_dump(iu)

      use mix_jas_ci, only: de_o_ci, dj_de_ci, dj_o_ci, dj_oe_ci
      use optwf_control, only: ioptci, ioptjas
      use optwf_parms, only: nparmj
      use ci000, only: nciterm

      implicit none

      integer :: i, iu, j

      if(ioptjas.eq.0.or.ioptci.eq.0) return
      write(iu) ((dj_o_ci(i,j),dj_oe_ci(i,j),dj_de_ci(i,j),de_o_ci(i,j),i=1,nparmj),j=1,nciterm)

      return
      end
c-----------------------------------------------------------------------
      subroutine optx_jas_ci_rstrt(iu)

      use mix_jas_ci, only: de_o_ci, dj_de_ci, dj_o_ci, dj_oe_ci
      use optwf_control, only: ioptci, ioptjas
      use optwf_parms, only: nparmj
      use ci000, only: nciterm

      implicit none

      integer :: i, iu, j

      if(ioptjas.eq.0.or.ioptci.eq.0) return
      read(iu) ((dj_o_ci(i,j),dj_oe_ci(i,j),dj_de_ci(i,j),de_o_ci(i,j),i=1,nparmj),j=1,nciterm)

      return
      end
c-----------------------------------------------------------------------
      subroutine optx_jas_ci_fin(passes,eave)

      use optci, only: mxciterm
      use csfs, only: ccsf, ncsf
      use dets, only: cdet
      use gradhess_ci, only: grad_ci
      use gradhess_jas, only: grad_jas
      use gradhess_mix_jas_ci, only: h_mix_jas_ci, s_mix_jas_ci
      use mix_jas_ci, only: de_o_ci, dj_de_ci, dj_o_ci, dj_oe_ci
      use optwf_control, only: ioptci, ioptjas
      use optwf_parms, only: nparmj
      use gradhessj, only: de, dj, dj_e
      use ci000, only: nciterm
      use ci005_blk, only: ci_o_cum
      use ci006_blk, only: ci_de_cum
      use ci008_blk, only: ci_oe_cum
      use precision_kinds, only: dp
      use optwf_control, only: method

      implicit none

      integer :: i, j
      real(dp) :: eave, h1, h2, passes
      real(dp), dimension(mxciterm) :: oelocav
      real(dp), dimension(mxciterm) :: eav

      if(ioptjas.eq.0.or.ioptci.eq.0.or.method.eq.'sr_n'.or.method.eq.'lin_d') return

      if(method.eq.'hessian') then

c Compute mix Hessian
      do i=1,nparmj
        do j=1,nciterm
          h1=2*(2*(dj_oe_ci(i,j)-eave*dj_o_ci(i,j))-dj(i,1)*grad_ci(j)-grad_jas(i)*ci_o_cum(j))
          h2=de_o_ci(i,j)-de(i,1)*ci_o_cum(j)/passes
     &         +dj_de_ci(i,j)-dj(i,1)*ci_de_cum(j)/passes
          h_mix_jas_ci(i,j)=(h1+h2)/passes
        enddo
      enddo

      write(21,*) nciterm
      write(21,*) ((h_mix_jas_ci(i,j),j=1,nciterm),i=1,nparmj)

      elseif(method.eq.'linear') then

      if(ncsf.eq.0) then
        do i=1,nciterm
          oelocav(i)=0
          eav(i)=0
          do j=1,nciterm
            oelocav(i)=oelocav(i)+ci_oe_cum(i,j)*cdet(j,1,1)/passes
            eav(i)=eav(i)+ci_oe_cum(j,i)*cdet(j,1,1)/passes
          enddo
        enddo
       else
        do i=1,ncsf
          oelocav(i)=0
          eav(i)=0
          do j=1,ncsf
            oelocav(i)=oelocav(i)+ci_oe_cum(i,j)*ccsf(j,1,1)/passes
            eav(i)=eav(i)+ci_oe_cum(j,i)*ccsf(j,1,1)/passes
          enddo
        enddo
      endif

      do i=1,nparmj
        do j=1,nciterm
c Overlap s_jas_ci
          s_mix_jas_ci(i,j)=(dj_o_ci(i,j)-dj(i,1)*ci_o_cum(j)/passes)/passes
c H matrix h_jas_ci
          h_mix_jas_ci(i,j)=(dj_de_ci(i,j)+dj_oe_ci(i,j)
     &    +eave*dj(i,1)*ci_o_cum(j)/passes-dj(i,1)*eav(j)-ci_o_cum(j)*dj_e(i,1)/passes)/passes
c H matrix h_ci_jas
          h_mix_jas_ci(i+nparmj,j)=(de_o_ci(i,j)+dj_oe_ci(i,j)
     &    +eave*dj(i,1)*ci_o_cum(j)/passes-dj(i,1)*oelocav(j)-ci_o_cum(j)*(de(i,1)+dj_e(i,1))/passes)/passes
        enddo
      enddo

      endif

      return
      end
      end module
