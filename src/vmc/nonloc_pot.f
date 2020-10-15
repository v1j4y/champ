      subroutine nonloc_pot(x,rshift,rvec_en,r_en,pe,vpsp_det,dvpsp_dj,t_vpsp,i_vpsp,ifr)
c Written by Claudia Filippi; modified by Cyrus Umrigar
c Calculates the local and nonlocal components of the pseudopotential
c Calculates non-local potential derivatives
c pe_en(loc) is computed in distances and pe_en(nonloc) here in nonloc_pot if nloc !=0 and iperiodic!=0.
      use pseudo_mod, only: MPS_QUAD
      use vmc_mod, only: MELEC, MCENT
      use atom, only: iwctype, ncent, ncent_tot
      use const, only: nelec
      use contrl_per, only: iperiodic

      use pseudo, only: lpot, nloc, vps

      implicit real*8(a-h,o-z)


      dimension x(3,*),rshift(3,nelec,ncent_tot),rvec_en(3,nelec,ncent_tot),r_en(nelec,ncent_tot)
     &,vpsp_det(*),dvpsp_dj(*),t_vpsp(ncent_tot,MPS_QUAD,*)

      if(i_vpsp.gt.0)then
        i1=i_vpsp
        i2=i_vpsp
       else
        i1=1
        i2=nelec
      endif
      do 20 i=i1,i2
        if(nloc.eq.1) then
          call getvps(r_en,i)
         elseif(nloc.eq.2.or.nloc.eq.3) then
          call getvps_tm(r_en,i)
         elseif(nloc.eq.4) then
          call getvps_gauss(rvec_en,r_en,i)
         elseif(nloc.eq.5) then
          call getvps_champ(r_en,i)
        endif
   20 continue

c local component (highest angular momentum)
      if(iperiodic.eq.0) then
        do 30 ic=1,ncent
          do 30 i=i1,i2
   30       pe=pe+vps(i,ic,lpot(iwctype(ic)))
      endif

c non-local component (division by the Jastrow already in nonloc)
      call nonloc(x,rshift,rvec_en,r_en,vpsp_det,dvpsp_dj,t_vpsp,i_vpsp)

      return
      end
