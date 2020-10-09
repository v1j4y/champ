subroutine inputzex
    ! Set the exponents to one when using a numerical basis
    use force_mod, only: MWF
    use numbas, only: numr
    use coefs, only: nbasis
    use basis, only: zex

    ! are they needed ??!!
    use contrl_per, only: iperiodic
    use wfsec, only: nwftype

    implicit real*8(a - h, o - z)

    allocate (zex(nbasis, nwftype))

    call p2gtid('general:nwftype', nwftype, 1, 1)
    call p2gtid('general:iperiodic', iperiodic, 0, 1)
    if (nwftype .gt. MWF) call fatal_error('WF: nwftype gt MWF')

    if (numr .eq. 0 .and. iperiodic .eq. 0) &
        call fatal_error('ZEX: numr=0 and iperiodic=0 but no zex are inputed')
    do iwft = 1, nwftype
        do i = 1, nbasis
            zex(i, iwft) = 1
        enddo
    enddo

end subroutine inputzex

subroutine inputcsf
    ! Check that the required blocks are there in the input

    use csfs, only: ncsf, nstates
    use inputflags, only: ici_def

    use ci000, only: nciprim, nciterm

    ! are they needed ??!!
    use optwf_contrl, only: ioptci
    implicit real*8(a - h, o - z)

    nstates = 1
    ncsf = 0

    call p2gtid('optwf:ioptci', ioptci, 0, 1)
    if (ioptci .ne. 0 .and. ici_def .eq. 1) nciterm = nciprim
    return
end

subroutine multideterminants_define(iflag, icheck)

    use force_mod, only: MFORCE, MFORCE_WT_PRD, MWF
    use vmc_mod, only: MELEC, MORB, MBASIS, MDET, MCENT, MCTYPE, MCTYP3X
    use vmc_mod, only: NSPLIN, nrad, MORDJ, MORDJ1, MMAT_DIM, MMAT_DIM2, MMAT_DIM20
    use vmc_mod, only: radmax, delri
    use vmc_mod, only: NEQSX, MTERMS
    use vmc_mod, only: MCENT3, NCOEF, MEXCIT
    use const, only: nelec
    use csfs, only: cxdet, iadet, ibdet, icxdet, ncsf, nstates
    use dets, only: cdet, ndet
    use elec, only: ndn, nup
    use multidet, only: iactv, irepcol_det, ireporb_det, ivirt, iwundet, kref, numrep_det
    use coefs, only: norb
    use dorb_m, only: iworbd

    ! not sure about that one either ....
    use wfsec, only: nwftype

    implicit real*8(a - h, o - z)

    dimension iswapped(nelec), itotphase(ndet)

    save kref_old

    call p2gti('electrons:nelec', nelec, 1)
    if (nelec .gt. MELEC) call fatal_error('INPUT: nelec exceeds MELEC')

    call p2gti('electrons:nup', nup, 1)
    if (nup .gt. MELEC/2) call fatal_error('INPUT: nup exceeds MELEC/2')
    ndn = nelec - nup

    call p2gtid('general:nwftype', nwftype, 1, 1)
    if (nwftype .gt. MWF) call fatal_error('INPUT: nwftype exceeds MWF')

    if (iflag .eq. 0) then
        kref = 1
    else
        if (kref .gt. 1 .and. icheck .eq. 1) then
            kref = 1
            goto 2
        endif
1       kref = kref + 1
        if (kref .gt. ndet) call fatal_error('MULTIDET_DEFINE: kref > ndet')

2       if (idiff(kref_old, kref, iflag) .eq. 0) goto 1
        write (6, *) 'kref change', iflag, kref_old, kref
    endif
    kref_old = kref

    write (6, *) 'nelec', nelec
    write (6, *) 'ndet', ndet

    allocate (iwundet(ndet, 2))
    allocate (numrep_det(ndet, 2))
    allocate (irepcol_det(nelec, ndet, 2))
    allocate (ireporb_det(nelec, ndet, 2))

    do iab = 1, 2
        numrep_det(kref, iab) = 0
    enddo

    do k = 1, ndet
        itotphase(k) = 0
        if (k .eq. kref) goto 5
        do iab = 1, 2
            nel = nup
            ish = 0
            if (iab .eq. 2) then
                nel = ndn
                ish = nup
            endif
            numrep_det(k, iab) = 0
            do iref = 1, nel
                iwref = iworbd(iref + ish, kref)
                in = 0
                do i = 1, nel
                    iw = iworbd(i + ish, k)
                    if (iw .eq. iwref) in = 1
                enddo
                if (in .eq. 0) then
                    numrep_det(k, iab) = numrep_det(k, iab) + 1
                    irepcol_det(numrep_det(k, iab), k, iab) = iref
                endif
            enddo
            isub = 0
            do i = 1, nel
                iw = iworbd(i + ish, k)
                in = 0
                do iref = 1, nel
                    iwref = iworbd(iref + ish, kref)
                    if (iw .eq. iwref) in = 1
                enddo
                if (in .eq. 0) then
                    isub = isub + 1
                    ireporb_det(isub, k, iab) = iw
                endif
            enddo
            if (isub .ne. numrep_det(k, iab)) then
                write (6, *) isub, numrep_det(k, iab)
                stop 'silly error'
            endif
            do irep = 1, nel
                iswapped(irep) = iworbd(irep + ish, kref)
            enddo
            do irep = 1, numrep_det(k, iab)
                iswapped(irepcol_det(irep, k, iab)) = ireporb_det(irep, k, iab)
            enddo
            iphase = 0
            do i = 1, nel
                if (iworbd(i + ish, k) .ne. iswapped(i)) then
                    do l = i + 1, nel
                        if (iswapped(l) .eq. iworbd(i + ish, k)) then
                            isav = iswapped(i)
                            iswapped(i) = iswapped(l)
                            iswapped(l) = isav
                            iphase = iphase + 1
                        endif
                    enddo
                endif
            enddo

            itotphase(k) = itotphase(k) + iphase
        enddo
        do iwf = 1, nwftype
            do istate = 1, nstates
                cdet(k, istate, iwf) = cdet(k, istate, iwf)*(-1)**itotphase(k)
            enddo
        enddo
5       continue
    enddo

    do k = 1, ndet
        if (k .eq. kref) goto 6
        do i = 1, nelec
            iworbd(i, k) = iworbd(i, kref)
        enddo
        do iab = 1, 2
            ish = 0
            if (iab .eq. 2) ish = nup
            do irep = 1, numrep_det(k, iab)
                iworbd(irepcol_det(irep, k, iab) + ish, k) = ireporb_det(irep, k, iab)
            enddo
        enddo
6       continue
    enddo

    iactv(1) = nup + 1
    iactv(2) = ndn + 1
    ivirt(1) = nup + 1
    ivirt(2) = ndn + 1
    do k = 1, ndet
        if (k .eq. kref) go to 8
        do iab = 1, 2
            do irep = 1, numrep_det(k, iab)
        if (irepcol_det(irep, k, iab) .ne. 0 .and. irepcol_det(irep, k, iab) .lt. iactv(iab)) iactv(iab) = irepcol_det(irep, k, iab)
                if (ireporb_det(irep, k, iab) .lt. ivirt(iab)) ivirt(iab) = ireporb_det(irep, k, iab)
            enddo
        enddo
8       continue
    enddo

    write (6, *) 'norb  =', norb
    write (6, *) 'iactv =', (iactv(iab), iab=1, 2)
    write (6, *) 'ivirt =', (ivirt(iab), iab=1, 2)

    idist = 1
    if (idist .eq. 0) then
        do iab = 1, 2
            do i = 1, ndet
                iwundet(i, iab) = i
            enddo
        enddo
    else
        do iab = 1, 2
            do i = 1, ndet
                iwundet(i, iab) = i
                if (i .eq. kref) goto 10
                if (idiff(kref, i, iab) .eq. 0) then
                    iwundet(i, iab) = kref
                    goto 10
                endif
                do j = 1, i - 1
                    if (idiff(j, i, iab) .eq. 0) then
                        iwundet(i, iab) = j
                        go to 10
                    endif
                enddo
10              continue
            enddo
        enddo
        do iab = 1, 2
            ndet_dist = 0
            do i = 1, ndet
                if (iwundet(i, iab) .eq. i) then
                    ndet_dist = ndet_dist + 1
                endif
            enddo
            write (6, *) iab, ndet_dist, ' distinct out of ', ndet
        enddo
    endif

    do icsf = 1, ncsf
        do j = iadet(icsf), ibdet(icsf)
            k = icxdet(j)
            cxdet(j) = cxdet(j)*(-1)**itotphase(k)
        enddo
    enddo

    return
end subroutine multideterminants_define
