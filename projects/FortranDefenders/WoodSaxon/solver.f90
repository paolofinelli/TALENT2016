module solver
  use grid
  implicit none

  real(wp), allocatable :: vocc(:,:,:,:), energies(:,:,:,:), &
                         &  sortenergies(:,:)
  integer, allocatable :: sortstates(:,:,:)

contains

  subroutine solve_r
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! This subroutine is closely based on the notes provided by the organizers
    ! of the 2016 Density Functional Theory TALENT Course.
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    integer :: i, ir, nnodes, nnodesl, l, is, iq, n, k
    real(wp) :: Etrial, Eupper, Elower, a1, a2, a3, b1, b2, b3, norm, j,coefmin,coefmax,coef, diff, ddiff
    real(wp), allocatable :: potential(:)
    density(:,:) = 0.0

    allocate(potential(0:nbox),vocc(lmax,0:lmax,2,2),energies(lmax,0:lmax,2,2))
    wfr(:,:,:,:,:) = 0.0
    do iq =1,2
      do n =1,lmax-2
        do l =0,lmax
            do is = 1,2
                j = l + spin(is)
                if (l==0) j=1
                Eupper = 100_wp

                Elower = vpb(iq)
                density(:,iq) = 0.
                do i=1,1000000
                  Etrial = (Eupper+Elower)/2.0
                  ! Attempting to set the potential before hand, if this does not work, we
                  ! can do it "on the fly"
                  do ir=0,nbox
                    if (iq .EQ. 1) then
                       potential(ir) = (-vpb(iq)*fullwoodsaxon(ir)-23._wp*spinorbit(ir,l,is) &
                      -hbar22m*l*(l+1)/meshpoints(ir)**2+Etrial)/hbar22m
                    else
                       potential(ir) = (-vpb(iq)*fullwoodsaxon(ir)-23._wp*spinorbit(ir,l,is) &
                      -hbar22m*l*(l+1)/meshpoints(ir)**2+Etrial-coulomb(ir))/hbar22m
                    end if
                  end do


                  wfr(nbox,n,l,is,iq) = 0.
                  wfr(nbox-1,n,l,is,iq) = 1.
                  wfl(0,n,l,is,iq) = 0.
                  wfl(1,n,l,is,iq) = meshpoints(1)**(l+1)

                  nnodes = 0
                  do ir=nbox-1,1,-1
                    a1 = 2.0 * (1.0 - (5.0/12.0) * h**2 * potential(ir))
                    a2 = (1.0 + (1.0/12.0) * h**2 * potential(ir+1))
                    a3 = (1.0 + (1.0/12.0) * h**2 * potential(ir-1))

                    b1 = 2.0 * (1.0 - (5.0/12.0) * h**2 * potential(nbox-ir))
                    b2 = (1.0 + (1.0/12.0) * h**2 * potential(nbox - ir-1))
                    b3 = (1.0 + (1.0/12.0) * h**2 * potential(nbox - ir+1))

                    wfr(ir-1,n,l,is,iq) = (a1*wfr(ir,n,l,is,iq) - a2*wfr(ir+1,n,l,is,iq))/a3
                    wfl(nbox - ir+1,n,l,is,iq) = (b1*wfl(nbox - ir,n,l,is,iq) - b2*wfl(nbox - ir-1,n,l,is,iq))/b3
                    if (ir == njoin) diff = wfr(ir,n,l,is,iq) / wfl(ir,n,l,is,iq)
                    if (ir <= njoin) then
                      wfl(ir,n,l,is,iq) = diff * wfl(ir,n,l,is,iq)

                    end if

                    if((wfr(ir,n,l,is,iq)*wfr(ir-1,n,l,is,iq) < 0) .AND. (ir > 5)) nnodes = nnodes+1
                    !(abs(wfr(ir-1,n,l,is,iq)-wfr(ir,n,l,is,iq)) < 2*abs(wfr(ir,n,l,is,iq)-wfr(ir+1,n,l,is,iq)))) nnodes = nnodes + 1
                    !if(wfl(ir,n,l,is,iq)*wfl(ir+1,n,l,is,iq) < 0) nnodes = nnodes + 1
                  end do
                  wfr(0:njoin,n,l,is,iq) = wfl(0:njoin,n,l,is,iq)
                  if (nnodes > n-1) then
                    Eupper = Etrial
                  else if (nnodes <= n-1) then
                    Elower = Etrial
                  end if

                  if (abs(Eupper - Elower) < conv) then
                    if (Etrial < 0 .AND. Etrial > vpb(iq)+.01) then
                          vocc(n,l,is,iq) = 2*l+1
                          energies(n,l,is,iq) = etrial
                          norm = sqrt(sum(h*wfr(:,n,l,is,iq)*wfr(:,n,l,is,iq)))
                          wfr(:,n,l,is,iq) = wfr(:,n,l,is,iq)/norm
                       end if

                    exit
                  end if
                end do
              end do
          end do
        end do
      end do

    if (abs(Eupper - Elower) > conv) then
      write (6,*) "Program did not converge!"
      write (*,*) abs(Eupper - Elower)
    end if

    ! Printing points for plotting. I run $ xmgrace plt



  end subroutine solve_r

  subroutine solvelr
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! This subroutine is closely based on the notes provided by the organizers
    ! of the 2016 Density Functional Theory TALENT Course.
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    integer :: i, ir, nnodesr, nnodesl, l, is, iq, n, k, g
    real(wp) :: Etrial, Eupper, Elower, a1, a2, a3, b1, b2, b3, norm,&
     j,coefmin,coefmax,coef, diff, ddiff,coefmind,coefmaxd,coefd
    real(wp), allocatable :: potential(:)
    density(:,:) = 0.0

    allocate(potential(0:nbox),vocc(lmax,0:lmax,2,2),energies(lmax,0:lmax,2,2))
    wfr(:,:,:,:,:) = 0.0
    wfl(:,:,:,:,:) = 0.0
    do iq =1,2
      do n =1,lmax-2
        do l =0,lmax
            do is = 1,2
                j = l + spin(is)
                if (l==0) j=0
                Eupper = 100_wp
                Elower = vpb(iq)
                density(:,iq) = 0.
                do i=1,1000000
                  Etrial = (Eupper+Elower)/2.0
                  ! Attempting to set the potential before hand, if this does not work, we
                  ! can do it "on the fly"
                  do ir=0,nbox
                    if (iq .EQ. 1) then
                       potential(ir) = (-vpb(iq)*fullwoodsaxon(ir)-23._wp*spinorbit(ir,l,is) &
                      -hbar22m*l*(l+1)/meshpoints(ir)**2+Etrial)/hbar22m
                    else
                       potential(ir) = (-vpb(iq)*fullwoodsaxon(ir)-23._wp*spinorbit(ir,l,is) &
                      -hbar22m*l*(l+1)/meshpoints(ir)**2+Etrial-coulomb(ir))/hbar22m
                    end if
                  end do


                  wfr(nbox,n,l,is,iq) = 0.
                  wfr(nbox-1,n,l,is,iq) = 1.
                  wfl(0,n,l,is,iq) = 0.
                  wfl(1,n,l,is,iq) = 1.

                  nnodesr = 0
                  do ir=nbox-1,njoin+1,-1
                    a1 = 2.0 * (1.0 - (5.0/12.0) * h**2 * potential(ir))
                    a2 = (1.0 + (1.0/12.0) * h**2 * potential(ir+1))
                    a3 = (1.0 + (1.0/12.0) * h**2 * potential(ir-1))

                    wfr(ir-1,n,l,is,iq) = (a1*wfr(ir,n,l,is,iq) - a2*wfr(ir+1,n,l,is,iq))/a3
                    if((wfr(ir,n,l,is,iq)*wfr(ir-1,n,l,is,iq) < 0)) nnodesr = nnodesr + 1 !.AND. &
                    !(ir > 5)) nnodes = nnodes+1
                    !(abs(wfr(ir-1,n,l,is,iq)-wfr(ir,n,l,is,iq)) < 2*abs(wfr(ir,n,l,is,iq)-wfr(ir+1,n,l,is,iq)))) nnodes = nnodes + 1
                    !if(wfl(ir,n,l,is,iq)*wfl(ir+1,n,l,is,iq) < 0) nnodes = nnodes + 1
                  end do
                  nnodesl=0
                  do ir=1,njoin-1
                    a1 = 2.0 * (1.0 - (5.0/12.0) * h**2 * potential(ir))
                    a2 = (1.0 + (1.0/12.0) * h**2 * potential(ir-1))
                    a3 = (1.0 + (1.0/12.0) * h**2 * potential(ir+1))

                    wfr(ir+1,n,l,is,iq) = (a1*wfr(ir,n,l,is,iq) - a2*wfr(ir-1,n,l,is,iq))/a3
                    if(wfr(ir,n,l,is,iq)*wfr(ir+1,n,l,is,iq) < 0) nnodesl = nnodesl + 1
                  end do

                  wfr(0:njoin,n,l,is,iq) = wfl(0:njoin,n,l,is,iq)

                  if (nnodesr+nnodesl > n-1) then
                    Eupper = Etrial
                  else if (nnodesl+nnodesr <= n-1) then
                    Elower = Etrial
                  end if

                  if (abs(Eupper - Elower) < conv) then
                    if (Etrial < 0 .AND. Etrial > vpb(iq)+.01) then

                      !do ir=0,3
                        !wfr(ir,n,l,is,iq) = ir*h**(l+1)
                      !end do
                      !do ir=0,nbox
                      !  write(13,*) ir*h, wfl(ir,1,0,1,1), wfl(ir,1,0,1,1)
                      !end do
                      !if (abs(wfr(30,n,l,is,iq) - wfl(30,n,l,is,iq)) < 1.) then
                        !if (l==0) then
                        if(mod(n-1,2) /= 0) wfr(:,n,l,is,iq) = -wfr(:,n,l,is,iq)
                        coefmin = 0.
                        coefmax = 1E10
                        do k=1,10000000
                          coef = (coefmin+coefmax)/2
                          diff = wfr(njoin,n,l,is,iq)-coef*wfl(njoin,n,l,is,iq)
                          if (diff > 0) then
                            coefmin=coef
                          else
                            coefmax=coef
                          end if
                          if (abs(diff) < conv) then
                            wfl(:,n,l,is,iq) = coef*wfl(:,n,l,is,iq)
                            exit
                          end if
                        end do

                          wfr(0:njoin,n,l,is,iq) = wfl(0:njoin,n,l,is,iq)
                          vocc(n,l,is,iq) = 2*l+1
                          energies(n,l,is,iq) = etrial
                          norm = sqrt(sum(4*pi*h*wfr(:,n,l,is,iq)*wfr(:,n,l,is,iq)))
                          wfr(:,n,l,is,iq) = wfr(:,n,l,is,iq)/norm
                          write(6,*) "Norm = ", sqrt(sum(4*pi*h*wfr(:,n,l,is,iq)*wfr(:,n,l,is,iq)*meshpoints(:)**2))
                        !else if (l<=3) then
                        !  if(mod(n-2,2) /= 0) wfr(:,n,l,is,iq) = -wfr(:,n,l,is,iq)
                        !  coefmin = 0.
                        !  coefmax = 1E10
                        !  do k=1,10000000
                        !    coef = (coefmin+coefmax)/2
                        !    diff = wfr(100,n,l,is,iq)-coef*wfl(100,n-1,l,is,iq)
                        !    if (diff > 0) then
                        !      coefmin=coef
                        !    else
                        !      coefmax=coef
                        !    end if
                        !    if (abs(diff) < conv) then
                        !      wfl(:,n-1,l,is,iq) = coef*wfl(:,n-1,l,is,iq)
                        !      exit
                        !    end if
                        !  end do
                        !  wfr(0:100,n,l,is,iq) = wfl(0:100,n-1,l,is,iq)
                        !  vocc(n-1,l,is,iq) = 2*l+1
                        !  energies(n-1,l,is,iq) = etrial
                        !  norm = sqrt(sum(4*pi*h*wfr(:,n,l,is,iq)*wfr(:,n,l,is,iq)))
                        !  wfr(:,n-1,l,is,iq) = wfr(:,n,l,is,iq)/norm
                        !  write(6,*) "Norm = ", sqrt(sum(4*pi*h*wfr(:,n-1,l,is,iq)*wfr(:,n-1,l,is,iq)*meshpoints(:)**2))
                        !else
                        !  if(mod(n-3,2) /= 0) wfr(:,n,l,is,iq) = -wfr(:,n,l,is,iq)
                        !  coefmin = 0.
                        !  coefmax = 1E10
                        !  do k=1,10000000
                        !    coef = (coefmin+coefmax)/2
                        !    diff = wfr(100,n,l,is,iq)-coef*wfl(100,n-2,l,is,iq)
                        !    if (diff > 0) then
                        !      coefmin=coef
                        !    else
                        !      coefmax=coef
                        !    end if
                        !    if (abs(diff) < conv) then
                        !      wfl(:,n-2,l,is,iq) = coef*wfl(:,n-2,l,is,iq)
                        !      exit
                        !    end if
                        !  end do
                        !  wfr(0:100,n,l,is,iq) = wfl(0:100,n-2,l,is,iq)
                        !  vocc(n-2,l,is,iq) = 2*l+1
                        !  energies(n-2,l,is,iq) = etrial
                        !  norm = sqrt(sum(4*pi*h*wfr(:,n,l,is,iq)*wfr(:,n,l,is,iq)))
                        !  wfr(:,n-2,l,is,iq) = wfr(:,n,l,is,iq)/norm
                        !  write(6,*) "Norm = ", sqrt(sum(4*pi*h*wfr(:,n-2,l,is,iq)*wfr(:,n-2,l,is,iq)*meshpoints(:)**2))
                        !end if

                      !end if
                    end if

                    exit
                  end if
                end do
              end do
          end do
        end do
      end do

    if (abs(Eupper - Elower) > conv) then
      write (6,*) "Program did not converge!"
      write (*,*) abs(Eupper - Elower)
    end if

    ! Printing points for plotting. I run $ xmgrace plt



  end subroutine solvelr

  subroutine energy_sort
    integer :: n, l, iq, is, n1,k,i,nfill,nfull
    real(wp) :: temp,j
    integer, dimension(1:3) :: state

    
    allocate(sortenergies(1:nmax,2),sortstates(1:nmax,1:3,2))
    sortenergies = small
    sortstates = small
    do iq =1,2
     nfull = nn
     if (iq == 2) nfull = np
     k = 1
     nfill = 0
     do while(nfill.lt.nfull)
      temp = 0._wp
      state = 1
     do n = 1,lmax
      do l = 0,lmax
        do is=1,2
              if(temp > energies(n,l,is,iq)) then
              temp = energies(n,l,is,iq)
              state(1) = n
              state(2) = l
              state(3) = is
              end if
        end do
      end do
     end do
     sortenergies(k,iq) = energies(state(1),state(2),state(3),iq)
     do i = 1,3
     sortstates(k,i,iq) = state(i)
     end do
     energies(state(1),state(2),state(3),iq) = 0.0_wp
     if (state(2)==0) energies(state(1),state(2),:,iq) = 0.0_wp
     j = state(2) + spin(state(3))
     if (state(2)==0) j = 0.5
     nfill = nfill + 2*j+1
     k = k+1
        end do
     print *, nfill
      end do

  end subroutine energy_sort

  subroutine build_densities
  real(wp), dimension(0:nbox,4) :: rho
  integer :: npr,iq,ir,i
  real(wp) :: j
  
  do iq =1,2

      if (iq == 1) then
      npr = nn
      else
      npr = np
      end if
      rho(:,iq)=0.
      do i = 1, npr
         if (sortenergies(i,iq) < - small) then
          j = sortstates(i,2,iq) + spin(sortstates(i,3,iq))
          if (sortstates(i,2,iq) == 0) j = 0.5
           do ir=1,nbox
             rho(ir,iq) = rho(ir,iq) + (2*j+1)*wfr(ir,sortstates(i,1,iq),sortstates(i,2,iq),sortstates(i,3,iq),iq)&
             *wfr(ir,sortstates(i,1,iq),sortstates(i,2,iq),sortstates(i,3,iq),iq) / (4*pi*meshpoints(ir)**2)
            end do
          end if
      end do
   end do
   rho(:,3)=rho(:,1) + rho(:,2)
   rho(:,4)=rho(:,1) - rho(:,2)
    
   write(6,*) sum(h*4*pi*meshpoints(:)**2*rho(:,1)), &
            & sum(h*4*pi*meshpoints(:)**2*rho(:,2)), &
            & sum(h*4*pi*meshpoints(:)**2*rho(:,3)), &
            & sum(h*4*pi*meshpoints(:)**2*rho(:,4))
    do ir = 0,nbox
    write(14,*) ir*h, rho(ir,1),rho(ir,2),rho(ir,3),rho(ir,4)
    end do 
  end subroutine build_densities

  function infwell_exact() result(energy)
    real(wp) :: energy

    energy = (nodes+1)**2 *pi**2 *hbar22m/(nbox*h)**2

  end function

  function finite_exact() result(energy)
    real(wp) :: energy

    energy = (nodes+1)**2 *pi**2 *hbar22m/(nbox*h)**2 -v0

  end function

  function infwell(ir, Etrial) result(pot)
    real(wp) :: pot
    real(wp), intent(in) :: Etrial
    integer, intent(in) :: ir

    if ((ir .EQ. 0) .OR. (ir .EQ. nbox)) then
      pot = 1E20_wp
    else
      pot = Etrial/hbar22m
    end if

  end function

  function finitepot(ir, Etrial) result(pot)
    real(wp) :: pot
    real(wp), intent(in) :: Etrial
    integer, intent(in) :: ir

    if ((ir <= nbox/2 - radius/2) .OR. (ir >= nbox/2 + radius/2)) then
      pot = Etrial/hbar22m
    else
      pot = (Etrial+v0)/hbar22m
    end if

  end function


  function woodsaxon_s(ir, Etrial) result(pot)
    real(wp) :: pot
    real(wp), intent(in) :: Etrial
    integer, intent(in) :: ir

  !pot = -v0 * 1 / (1 + exp((meshpoints(ir)-300*h)/0.67))
    if (ir < nbox/2) then
      pot = (Etrial + v0 * 1 / (1 + exp((meshpoints(nbox/2-ir)-radius/2*h)/0.67)))/hbar22m
    else
      pot = (Etrial + v0 * 1 / (1 + exp((meshpoints(ir-nbox/2)-radius/2*h)/0.67)))/hbar22m
  end if


  end function

  function woodsaxon(ir, Etrial) result(pot)
    real(wp) :: pot
    integer, intent(in) :: ir
    real(wp), intent(in) :: Etrial

    if (ir < (nbox/2 - radius)) then
      pot = Etrial/hbar22m
    else
      pot = ( v0 * 1 / (1 + exp((meshpoints(ir-(nbox/2 - radius))-radius*h)/0.67)))/ hbar22m
    end if
  end function

!!!Must be multiplied by (positive) vpb in calculations
 function fullwoodsaxon(ir) result(pot)
    real(wp) :: pot
    integer, intent(in) :: ir
      pot = 1 / (1 + exp((meshpoints(ir)-nrad)/0.67))
  end function

!!!Must be multiplied by (positive) vpb in calculations
function dfullwoodsaxon(ir) result(pot)
    real(wp) :: pot
    integer, intent(in) :: ir
      pot = -1 / (1 + exp((meshpoints(ir)-nrad)/0.67))*(1/0.67)*(1 / (1 + exp((-meshpoints(ir)+nrad)/0.67)))
  end function

  function spinorbit(ir,l,is) result(pot)
    integer, intent(in) :: ir,l, is
    real(wp) :: spin, pot
    if(is .EQ. 1) spin = -0.5
    if(is .EQ. 2) spin = 0.5
    if (ir .EQ. 0) then
      pot = 0._wp
    else
      if (l .EQ. 0) then
        pot = 0._wp
      else
        pot = r0**2 * dfullwoodsaxon(ir)/meshpoints(ir)* 0.5 *((l+spin)*(l+spin+1) - l*(l+1) - 0.75)
      end if
    end if

  end function

  function coulomb(ir) result(pot)
    integer,intent(in) :: ir
    real(wp) ::pot
        if(ir*h .lt. nrad ) pot= (np*e2/(2*nrad))*(3.0d0- (ir*h/nrad)**2)
        if(ir*h .ge. nrad ) pot= np*e2/(ir*h)

  end function

end module solver
