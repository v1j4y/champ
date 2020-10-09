C ---------- predefined namlist check -------
C this file is auto generated, do not edit   
      subroutine p2nmcheck(p,v,ierr)
      character p*(*),v*(*)
      character lists(21)*(12)
      character vars(153)*(16)
      dimension iaptr(21),ieptr(21)
      data lists/'startend','strech','optwf','ci','blocking_dmc',
     $ 'atoms','jastrow','blocking_vmc','properties','qmmm','optgeo',
     $ 'dmc','vmc','3dgrid','electrons','forces','mstates','pseudo',
     $ 'periodic','general','gradients'/
      data vars/'idump','irstar','isite','icharged_atom','alfstr',
     $ 'ioptwf','idl_flag','ilbfgs_flag','ilbfgs_m','method',
     $ 'nopt_iter','ioptjas','ioptorb','ioptci','multiple_adiag',
     $ 'add_diag','ngrad_jas_blocks','nblk_max','nblk_ci','dl_alg',
     $ 'iorbprt','isample_cmat','istddev','limit_cmat','e_shift',
     $ 'save_blocks','force_blocks','iorbsample','iuse_trafo',
     $ 'iuse_orbeigv','ncore','nextorb','no_active','approx',
     $ 'approx_mix','energy_tol','sr_tau','sr_eps','sr_adiag',
     $ 'micro_iter_sr','dl_mom','lin_eps','lin_adiag','lin_nvec',
     $ 'lin_nvecx','lin_jdav','func_omega','omega','n_omegaf',
     $ 'n_omegat','sr_rescale','iciprt','nstep','nblk','nblkeq',
     $ 'nconf_new','nconf','nctype','natom','addghostype',
     $ 'nghostcent','ianalyt_lap','ijas','isc','nspin1','nspin2',
     $ 'ifock','nstep','nblk','nblkeq','nconf_new','nconf','sample',
     $ 'print','iqmmm','iforce_analy','iuse_zmat','alfgeo','izvzb',
     $ 'iroot_geo','idmc','tau','etrial','nfprod','ipq','itau_eff',
     $ 'iacc_rej','icross','icuspg','idiv_v','icut_br','icut_e',
     $ 'icasula','node_cutoff','enode_cutoff','ibranch_elec',
     $ 'icircular','idrifdifgfunc','mode_dmc','imetro','deltar',
     $ 'deltat','delta','fbias','node_cutoff','enode_cutoff','stepx',
     $ 'stepy','stepz','x0','y0','z0','xn','yn','zn','nelec','nup',
     $ 'istrech','alfstr','nwprod','itausec','iguiding','iefficiency',
     $ 'nloc','nquad','norb','npoly','np','cutg','cutg_sim',
     $ 'cutg_big','cutg_sim_big','title','unit','mass','iperiodic',
     $ 'ibasis','nforce','nwftype','seed','ipr','pool','basis',
     $ 'pseudopot','i3dsplorb','i3dlagorb','scalecoef','ngradnts',
     $ 'igrdtype','delgrdxyz','delgrdbl','delgrdba','delgrdda'/
      data iaptr/1,5,6,52,53,58,62,68,73,75,76,81,100,107,116,118,122,
     $ 124,126,133,148/
      data ieptr/4,5,51,52,57,61,67,72,74,75,80,99,106,115,117,121,
     $ 123,125,132,147,153/
      nlist=21
      ierr=0
      do i=1,nlist
       if(lists(i).eq.p) then
        do iv=iaptr(i),ieptr(i)
         if(vars(iv).eq.v) then
          return
         endif
        enddo
        ierr=1
        return
       endif
      enddo
      return
      end
