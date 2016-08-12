program skyrme
use globals
implicit none
real(8) :: s_z, j_tot
real(8),allocatable :: psi(:), &
     u_nlj_p(:,:), u_nlj_n(:,:),&
     rho_old_n(:), rho_old_p(:), rho_old(:), tau_old_n(:), tau_old_p(:), tau_old(:),&
     rho_p(:), rho_n(:), rho(:), tau_p(:), tau_n(:), tau(:), JJ_p(:), JJ_n(:), JJ(:),&
     JJ_old_n(:), JJ_old_p(:), JJ_old(:), k_sq_p(:), k_sq_n(:)
real(8),allocatable :: V_skyrme_p(:), V_skyrme_n(:),&
     M_eff_p(:), M_eff_n(:), W_p(:), W_n(:), g_p(:), g_n(:),&
     dg_p(:), dg_n(:), f_p(:), f_n(:), h_p(:), h_n(:)
complex(8),allocatable :: v_n(:), v_p(:)
real(8) :: E_left, E_right, E, E_hf, E_hf_new=0.d0, E_ke, E_sp, number, E_pot
real(8) :: x, nmfactor
integer :: i, j, rep, count, spin, l, ex
real(8),allocatable :: energy_n(:), energy_p(:), wave_func_n(:,:), wave_func_p(:,:)
integer :: orbital_l
real(8),allocatable :: E_data_n(:,:), E_data_p(:,:)

character(99) :: filename
character(99),allocatable :: filename_wave_func_n(:), filename_wave_func_p(:)

! density distribution variables
integer :: Np_tmp, Nn_tmp, Np_l, Nn_l, orbital_tmp
real(8),allocatable :: rho_BCS_p(:), rho_BCS_n(:), rho_BCS(:)
! initial setting of the system***************
integer :: N_nlj,N
integer,allocatable :: nl2j(:,:)
real(8) :: E_p, E_m,E_tot_p, lambda_p, delta_p, E_tot_n, lambda_n, delta_n
real(8) :: Vcoulomb
NAMELIST / nucleons / proton, neutron
NAMELIST / parameters / h2m, R_max, N
NAMELIST / skyrme_force / skforce
NAMELIST / max_quantum_number / n_max, l_max 
NAMELIST / effective_charge / charge
NAMELIST / bisection / E_p, E_m
NAMELIST / output / output_wave_func, epsi, corr
NAMELIST / WoodSaxon/ r0, a, e2
NAMELIST / CMcorr/ CMcorrection
NAMELIST / BCS_parameters/ BCS_cal, g

open(30,file='nucleon.txt',status='old')
read(30,NML=nucleons)
nucleon = neutron + proton
read(30,NML=parameters)
read(30,NML=skyrme_force)
read(30,NML=max_quantum_number)
read(30,NML=effective_charge)
read(30,NML=bisection)
read(30,NML=output)
read(30,NML=WoodSaxon)
read(30,NML=CMcorr)
read(30,NML=BCS_parameters)


close(30)   ! read form file
!*********************************************

! skyrme parameters
if (skforce=='t0t3') then
   t0=-1132.4d0
   t1=0d0
   t2=0d0
   t3=23610.4d0
   x0=0d0
   x1=0d0
   x2=0d0
   x3=0d0
   W0=0d0 
   alpha=1d0
else if (skforce=='SLy5') then
   t0=-2483.45d0
   t1=484.23d0
   t2=-556.69d0
   t3=13757d0
   x0=0.776d0
   x1=-0.317d0
   x2=-1d0
   x3=1.2630d0
   W0=125d0
   alpha=1/6d0
else if (skforce=='SIII') then
   t0=-1128.75d0
   t1=395d0
   t2=-95d0
   t3=14000d0
   x0=0.45d0
   x1=0d0
   x2=0d0
   x3=1d0
   W0=130d0
   alpha=1d0
else if (skforce=='test') then
   t0=-1132.4d0
   t1=1d0
   t2=-1d0
   t3=23610.4d0
   x0=0.1d0
   x1=0d0
   x2=0d0
   x3=1d0
   W0=100d0 
   alpha=1d0
end if

write(filename,'(a1,I3.3,a1,I3.3,a4)') 'p', proton, 'n', neutron, '.dat'
filename = trim(filename)

Nmesh=N 
dx = R_max/N
CMh2m =h2m
!      if (CMcorrection) h2m = h2m*(1.d0-1.d0/nucleon)

! the number of orbits
orbital = 0
do ex=0,n_max
   do l=0,l_max
      do spin=1,2
         orbital = orbital + 1
         if (l==0) exit
      end do
   end do
end do
write(*,*) orbital
! allocate array due to N and orbital
allocate(psi(0:N), &
     u_nlj_p(0:N,1:orbital), u_nlj_n(0:N,1:orbital))
allocate(rho_p(0:N), rho_n(0:N), rho(0:N), tau_p(0:N), tau_n(0:N), tau(0:N), &
     rho_old_n(0:N), rho_old_p(0:N), rho_old(0:N), tau_old_n(0:N), tau_old_p(0:N), tau_old(0:N),&
     k_sq_p(0:N), k_sq_n(0:N), JJ_p(0:N), JJ_n(0:N), JJ(0:N), JJ_old_n(0:N), JJ_old_p(0:N), JJ_old(0:N),&
     rho_BCS_p(0:N), rho_BCS_n(0:N), rho_BCS(0:N))
allocate(V_skyrme_p(0:N), V_skyrme_n(0:N), M_eff_p(0:N), M_eff_n(0:N),&
     W_p(0:N), W_n(0:N), g_p(0:N), g_n(0:N), dg_p(0:N), dg_n(0:N),&
     f_p(0:N), f_n(0:N), h_p(0:N), h_n(0:N))
allocate(energy_n(1:orbital),energy_p(1:orbital),wave_func_n(0:N,1:orbital),&
     wave_func_p(0:N,1:orbital))
allocate(filename_wave_func_n(1:orbital),filename_wave_func_p(1:orbital))
allocate(E_data_n(1:orbital,1:4),E_data_p(1:orbital,1:4))

! initial density, kinetic density
rho_p(:) = 0d0
rho_n(:) = 0d0
rho(:) = 0d0
tau_p(:) = 0d0
tau_n(:) = 0d0
tau(:) = 0d0
JJ_p(:) = 0d0
JJ_n(:) = 0d0
JJ(:) = 0d0
Nn_tmp = neutron
Np_tmp = proton
E_sp = 0d0

! initial sp_energy and wave_func from WS potential
call WoodsSaxon3D(energy_n,energy_p,E_data_n,E_data_p,u_nlj_n,u_nlj_p)

!-------------------------------------------------------------------------------
   do orbital_l=1,orbital
      Nn_l = Nn_tmp
      j_tot = E_data_n(orbital_l,3) + E_data_n(orbital_l,4)
      l = nint(E_data_n(orbital_l,3))
      Nn_tmp = Nn_tmp - nint(2d0*j_tot+1)
      if (Nn_tmp<=0) then
         orbital_tmp = orbital_l-1
         exit
      end if
      do i=1,N
         x = i*dx
         rho_n(i) = rho_n(i) + (2d0*j_tot+1)*abs(u_nlj_n(i,orbital_l))**2/(4d0*pi*x**2)
      end do
      do i=1,N-2
         x = i*dx
         tau_n(i) = tau_n(i) + (2d0*j_tot+1)*( ((4d0*u_nlj_n(i+1,orbital_l)&
              -3d0*u_nlj_n(i,orbital_l)-u_nlj_n(i+2,orbital_l))/(2d0*dx)&
              - u_nlj_n(i,orbital_l)/x)**2 +E_data_n(orbital_l,3)*(E_data_n(orbital_l,3)+1d0)*u_nlj_n(i,orbital_l)**2/x**2&
              )/(4d0*pi*x**2)
!         write(*,*) tau_n(i)
      end do
      do i=1,N
         x = i*dx
         JJ_n(i) = JJ_n(i) + (2d0*j_tot+1)*(j_tot*(j_tot+1d0)-l*(l+1d0)-0.75d0)*&
              u_nlj_n(i,orbital_l)**2/(4d0*pi*x**3)
      end do
      E_sp = E_sp + (2d0*j_tot+1)*energy_n(orbital_l)
   end do
   do i=1,N
      x = i*dx
      rho_n(i) = rho_n(i) + Nn_l*abs(u_nlj_n(i,orbital_tmp+1))**2/(4d0*pi*x**2)
   end do
   do i=1,N-2
      x = i*dx
      tau_n(i) = tau_n(i) + Nn_l*( ((4d0*u_nlj_n(i+1,orbital_tmp+1)&
           -3d0*u_nlj_n(i,orbital_tmp+1)-u_nlj_n(i+2,orbital_tmp+1))/(2d0*dx)&
           - u_nlj_n(i,orbital_tmp+1)/x)**2 + E_data_n(orbital_tmp+1,3)*(E_data_n(orbital_tmp+1,3) &
            +1d0)*u_nlj_n(i,orbital_tmp+1)**2/x**2&
           )/(4d0*pi*x**2)
   end do
   j_tot = E_data_n(orbital_tmp+1,3) + E_data_n(orbital_tmp+1,4)
   l = nint(E_data_n(orbital_tmp+1,3))
   do i=1,N
      x = i*dx
      JJ_n(i) = JJ_n(i) + Nn_l*(j_tot*(j_tot+1d0)-l*(l+1d0)-0.75d0)*&
           u_nlj_n(i,orbital_tmp+1)**2/(4d0*pi*x**3)
   end do

   rho_n(0) = 2d0*rho_n(1)-rho_n(2)
   tau_n(0) = 2d0*tau_n(1)-tau_n(2)
   tau_n(N-1) = 0d0
   tau_n(N) = 0d0
   JJ_n(0) = 2d0*JJ_n(1)-JJ_n(2)
   E_sp = E_sp + Nn_l*energy_n(orbital_tmp+1)

   do orbital_l=1,orbital
      Np_l = Np_tmp
      j_tot = E_data_p(orbital_l,3) + E_data_p(orbital_l,4)
      l = nint(E_data_p(orbital_l,3))
      Np_tmp = Np_tmp - nint(2d0*j_tot+1)
      if (Np_tmp<=0) then
         orbital_tmp = orbital_l-1
         exit
      end if
      do i=1,N
         x = i*dx
         rho_p(i) = rho_p(i) + (2d0*j_tot+1)*abs(u_nlj_p(i,orbital_l))**2/(4d0*pi*x**2)
      end do
      do i=1,N-2
         x = i*dx
         tau_p(i) = tau_p(i) + (2d0*j_tot+1)*( ((4d0*u_nlj_p(i+1,orbital_l)&
              -3d0*u_nlj_p(i,orbital_l)-u_nlj_p(i+2,orbital_l))/(2d0*dx)&
              - u_nlj_p(i,orbital_l)/x)**2 + E_data_p(orbital_l,3)*(E_data_p(orbital_l,3)+1d0)*u_nlj_p(i,orbital_l)**2/x**2&
              )/(4d0*pi*x**2)
      end do
      do i=1,N
         x = i*dx
         JJ_p(i) = JJ_p(i) + (2d0*j_tot+1)*(j_tot*(j_tot+1d0)-l*(l+1d0)-0.75d0)*&
              u_nlj_p(i,orbital_l)**2/(4d0*pi*x**3)
      end do
      E_sp = E_sp + (2d0*j_tot+1)*energy_p(orbital_l)
   end do
   
   do i=1,N
      x = i*dx
      rho_p(i) = rho_p(i) + Np_l*abs(u_nlj_p(i,orbital_tmp+1))**2/(4d0*pi*x**2)
   end do
   do i=1,N-2
      x = i*dx
      tau_p(i) = tau_p(i) + Np_l*( ((4d0*u_nlj_p(i+1,orbital_tmp+1)&
           -3d0*u_nlj_p(i,orbital_tmp+1)-u_nlj_p(i+2,orbital_tmp+1))/(2d0*dx)&
           - u_nlj_p(i,orbital_tmp+1)/x)**2 + E_data_p(orbital_tmp+1,3)*&
            (E_data_p(orbital_tmp+1,3)+1d0)*u_nlj_p(i,orbital_tmp+1)**2/x**2&
           )/(4d0*pi*x**2)
   end do
   j_tot = E_data_p(orbital_tmp+1,3) + E_data_p(orbital_tmp+1,4)
   l = nint(E_data_p(orbital_tmp+1,3))
   do i=1,N
      x = i*dx
      JJ_p(i) = JJ_p(i) + Np_l*(j_tot*(j_tot+1d0)-l*(l+1d0)-0.75d0)*&
           u_nlj_p(i,orbital_tmp+1)**2/(4d0*pi*x**3)
   end do
   rho_p(0) = 2d0*rho_p(1)-rho_p(2)
   tau_p(0) = 2d0*tau_p(1)-tau_p(2)
   tau_p(N-1) = 0d0
   tau_p(N) = 0d0
   JJ_p(0) = 2d0*JJ_p(1)-JJ_p(2)
   E_sp = E_sp + Np_l*energy_p(orbital_tmp+1)

!****************************************************


rho(:) = rho_p(:)+rho_n(:)
tau(:) = tau_p(:)+tau_n(:)
JJ(:) = JJ_p(:)+JJ_n(:)

! initial HF energy
number = 0d0
E_ke = 0d0
E_pot=0d0
do i=0,N
   x = i*dx
   number = number + 4d0*pi*rho(i)*x**2*dx
   E_ke = E_ke + 4d0*pi*h2m*tau(i)*x**2*dx
end do

E_hf = 0.5d0*(E_ke+E_sp)
write(*,'(4f15.8)') number, E_hf, E_sp, E_ke

! iteration start
do rep=1,iter

   rho_old_p(:) = rho_p(:)
   rho_old_n(:) = rho_n(:)
   rho_old(:) = rho(:)
   tau_old_p(:) = tau_p(:)
   tau_old_n(:) = tau_n(:)
   tau_old(:) = tau(:)
   JJ_old_p(:) = JJ_p(:)
   JJ_old_n(:) = JJ_n(:)
   JJ_old(:) = JJ(:)

   E_sp = 0d0

! skyrme potential    
   do i=1,N-4
      x = i*dx
      V_skyrme_p(i) = rho(i)*(0.5d0*t0*(2d0+x0)+(2d0+alpha)*t3*(2d0+x3)*rho(i)**alpha/24d0)&
           + rho_p(i)*(-0.5d0*t0*(2d0*x0+1d0)-t3*(2d0*x3+1d0)*rho(i)**alpha/12d0)&
           + alpha*rho(i)**(alpha-1)*(-t3*(2d0*x3+1d0)/24d0)*(rho_p(i)**2+rho_n(i)**2)&
           + 0.125d0*tau(i)*(t1*(2d0+x1)+t2*(2d0+x2)) - (3d0*t1*(2d0+x1)-t2*(2d0+x2))/16d0*(&
           (rho(i+4)-8d0*rho(i+3)+22d0*rho(i+2)-24d0*rho(i+1)+9d0*rho(i))/(4d0*dx**2)&
           +2d0*(4d0*rho(i+1)-3d0*rho(i)-rho(i+2))/(2d0*dx*x) )&
           - 0.125d0*(t1*(2d0*x1+1d0)-t2*(2d0*x2+1d0))*tau_p(i) - 0.125d0*(t1*x1+t2*x2)*(&
           (rho_p(i+4)-8d0*rho_p(i+3)+22d0*rho_p(i+2)-24d0*rho_p(i+1)+9d0*rho_p(i))/(4d0*dx**2)&
           +2d0*(4d0*rho_p(i+1)-3d0*rho_p(i)-rho_p(i+2))/(2d0*dx*x) )&
           - 0.5d0*W0*(4d0*(JJ(i+1)+JJ_n(i+1))-3d0*(JJ(i)+JJ_n(i))-(JJ(i+2)+JJ_n(i+2)))/(2d0*dx)
      V_skyrme_n(i) = rho(i)*(0.5d0*t0*(2d0+x0)+(2d0+alpha)*t3*(2d0+x3)*rho(i)**alpha/24d0)&
           + rho_n(i)*(-0.5d0*t0*(2d0*x0+1d0)-t3*(2d0*x3+1d0)*rho(i)**alpha/12d0)&
           + alpha*rho(i)**(alpha-1)*(-t3*(2d0*x3+1d0)/24d0)*(rho_p(i)**2+rho_n(i)**2)&
           + 0.125d0*tau(i)*(t1*(2d0+x1)+t2*(2d0+x2)) - (3d0*t1*(2d0+x1)-t2*(2d0+x2))/16d0*(&
           (rho(i+4)-8d0*rho(i+3)+22d0*rho(i+2)-24d0*rho(i+1)+9d0*rho(i))/(4d0*dx**2)&
           +2d0*(4d0*rho(i+1)-3d0*rho(i)-rho(i+2))/(2d0*dx*x) )&
           - 0.125d0*(t1*(2d0*x1+1d0)-t2*(2d0*x2+1d0))*tau_n(i) - 0.125d0*(t1*x1+t2*x2)*(&
           (rho_n(i+4)-8d0*rho_n(i+3)+22d0*rho_n(i+2)-24d0*rho_n(i+1)+9d0*rho_n(i))/(4d0*dx**2)&
           +2d0*(4d0*rho_n(i+1)-3d0*rho_n(i)-rho_n(i+2))/(2d0*dx*x) )&
           - 0.5d0*W0*(4d0*(JJ(i+1)+JJ_p(i+1))-3d0*(JJ(i)+JJ_p(i))-(JJ(i+2)+JJ_p(i+2)))/(2d0*dx)
   end do
   V_skyrme_p(0) = V_skyrme_p(1)
   V_skyrme_n(0) = V_skyrme_n(1)
   V_skyrme_p(N-3:N) = 0d0
   V_skyrme_n(N-3:N) = 0d0
   open(10,file='err.dat')
   do i=0,N
      x = i*dx
      write(10,'(3f15.8)') x, V_skyrme_n(i), V_skyrme_p(i)
   end do
   close(10)
   open(10,file='pot_skyrme_n.dat')
   do i=0,N
      x = i*dx
      write(10,'(2f15.8)') x, V_skyrme_n(i)
   end do
   close(10)

! spin_orbit potential
   do i=1,N-2
      x = i*dx
      W_p(i) = -0.125d0*(t1*x1+t2*x2)*JJ(i) + 0.125d0*(t1-t2)*JJ_p(i) &
           + W0*(4d0*(rho(i+1)+rho_p(i+1))-3d0*(rho(i)+rho_p(i))-(rho(i+2)+rho_p(i+2)))/(2d0*dx)
      W_n(i) = -0.125d0*(t1*x1+t2*x2)*JJ(i) + 0.125d0*(t1-t2)*JJ_n(i) &
           + W0*(4d0*(rho(i+1)+rho_n(i+1))-3d0*(rho(i)+rho_n(i))-(rho(i+2)+rho_n(i+2)))/(2d0*dx)
   end do
   W_p(0) = W_p(1)
   W_n(0) = W_n(1)
   W_p(N-1:N) = -0.125d0*(t1*x1+t2*x2)*JJ(N-1:N) + 0.125d0*(t1-t2)*JJ_p(N-1:N)
   W_n(N-1:N) = -0.125d0*(t1*x1+t2*x2)*JJ(N-1:N) + 0.125d0*(t1-t2)*JJ_n(N-1:N)

  ! other part
   do i=0,N
      M_eff_p(i) = h2m + 0.25d0*t1*((1d0+0.5d0*x1)*rho(i)-(x1+0.5d0)*rho_p(i))&
           + 0.25d0*t2*((1d0+0.5d0*x2)*rho(i)-(x2+0.5d0)*rho_p(i))
      M_eff_n(i) = h2m + 0.25d0*t1*((1d0+0.5d0*x1)*rho(i)-(x1+0.5d0)*rho_n(i))&
           + 0.25d0*t2*((1d0+0.5d0*x2)*rho(i)-(x2+0.5d0)*rho_n(i))
   end do
   do i=0,N-2
      g_p(i) = (4d0*M_eff_p(i+1)-3d0*M_eff_p(i)-M_eff_p(i+2))/(2d0*dx*M_eff_p(i))
      g_n(i) = (4d0*M_eff_n(i+1)-3d0*M_eff_n(i)-M_eff_n(i+2))/(2d0*dx*M_eff_n(i))
   end do
   g_p(N-1:N) = 0d0
   g_n(N-1:N) = 0d0
   do i=1,N-4
      dg_p(i) = (M_eff_p(i)*(M_eff_p(i+4)-8d0*M_eff_p(i+3)+22d0*M_eff_p(i+2)&
           -24d0*M_eff_p(i+1)+9d0*M_eff_p(i))/(4d0*dx**2) - ((4d0*M_eff_p(i+1)&
           -3d0*M_eff_p(i)-M_eff_p(i+2))/(2d0*dx*M_eff_p(i)))**2)/M_eff_p(i)**2
      dg_n(i) = (M_eff_n(i)*(M_eff_n(i+4)-8d0*M_eff_n(i+3)+22d0*M_eff_n(i+2)&
           -24d0*M_eff_n(i+1)+9d0*M_eff_n(i))/(4d0*dx**2) - ((4d0*M_eff_n(i+1)&
           -3d0*M_eff_n(i)-M_eff_n(i+2))/(2d0*dx*M_eff_n(i)))**2)/M_eff_n(i)**2
   end do
   dg_p(0) = dg_p(1)
   dg_n(0) = dg_n(1)
   dg_p(N-3:N) = 0d0
   dg_n(N-3:N) = 0d0
!*******************neutron****************************
   E_data_n = 0d0
   orbital_l = 0
! calculate proton's eigenvalue and eigenstates
   do ex=0,n_max-1   !select the number of excited state (n)
      do l=0,l_max    !select angular momentum (l)
         do spin=1,2 !select spin (j=l+1/2 and j=l-1/2)
            orbital_l = orbital_l + 1
            if (spin==1) then
               s_z = 0.5
            else if (spin==2) then
               s_z = -0.5
            end if

! initialization
            E_left = E_m
            E_right = E_p
            
            psi(0) = 0d0
            psi(1) = 0.1d0

! h(r)
            do i=1,N-2
               x = i*dx
               h_n(i) = V_skyrme_n(i) + (4d0*M_eff_n(i+1)-3d0*M_eff_n(i)&
                    -M_eff_n(i+2))/(2d0*dx*x) + ((l+s_z)*(l+s_z+1d0)&
                    -l*(l+1d0)-0.75d0)*W_n(i)/(2d0*x)
            end do
            h_n(0) = h_n(1)
            h_n(N-1:N) = 0d0
! bisection start
            do while(bisloop)
               count = 0
               E = E_left + 0.5d0*(E_right-E_left)
               if (E_right-E_left<epsi) exit
            
! f(r) and k_sq
               do i=1,N
                  x = i*dx
                  f_n(i) = -(h_n(i)+M_eff_n(i)*l*(l+1d0)/x**2-E)/M_eff_n(i)
                  k_sq_n(i) = -0.25d0*g_n(i)**2 + f_n(i)-0.5d0*dg_n(i)
               end do
               k_sq_n(0) = 2d0*k_sq_n(1)-k_sq_n(2)
! numerov
               do i=1,N-1
                  x = i*dx
!               psi(i+1) = 2d0*(1-dx**2*k_sq_n(i)/2d0)*psi(i) - psi(i-1)
                  psi(i+1) = (2d0*(1-5d0*dx**2*k_sq_n(i)/12d0)*psi(i)&
                       -(1+dx**2*k_sq_n(i-1)/12d0)*psi(i-1))/(1+dx**2*k_sq_n(i+1)/12d0) 
                  if (psi(i+1)*psi(i)<0) then
                     count = count + 1
                  end if
               end do
               if (count>ex) then
                  E_right = E
               else 
                  E_left = E
               end if

            end do

! wave func & eigenvalue
            E = E_right
!            write(*,*) E
! unbound or spurious states
            if (E-E_m<1e-5.or.E_p-E<1e-5) then
               orbital_l = orbital_l - 1
               exit
            end if
            energy_n(orbital_l) = E
            count = 0
            do i=1,N
               x = i*dx
               f_n(i) = -(h_n(i)+M_eff_n(i)*l*(l+1d0)/x**2-E)/M_eff_n(i)
               k_sq_n(i) = -0.25d0*g_n(i)**2 + f_n(i)-0.5d0*dg_n(i)
            end do
            k_sq_n(0) = 2d0*k_sq_n(1)-k_sq_n(2)
            do i=1,N-1
               x = i*dx
!            psi(i+1) = 2d0*(1-dx**2*k_sq_n(i)/2d0)*psi(i) - psi(i-1)
               psi(i+1) = (2d0*(1-5d0*dx**2*k_sq_n(i)/12d0)*psi(i)&
                    -(1+dx**2*k_sq_n(i-1)/12d0)*psi(i-1))/(1+dx**2*k_sq_n(i+1)/12d0)
               if (psi(i+1)*psi(i)<0) then
                  count = count + 1
               end if
               if (psi(i+1)*psi(i)<=0d0.and.count>ex) then
                  psi(i+1) = 0d0
                  exit
               end if
            end do
            psi(i+1:N) = 0d0
! normalization
            nmfactor = 0d0
            do i=0,N
               nmfactor = nmfactor + abs(psi(i))**2*dx/M_eff_n(i)
            end do
            nmfactor = sqrt(nmfactor)
            do i=0,N
               psi(i) = psi(i)/nmfactor/sqrt(M_eff_n(i))
            end do
            u_nlj_n(:,orbital_l) = psi(:)
            E_data_n(orbital_l,1) = E
            E_data_n(orbital_l,2) = ex+1
            E_data_n(orbital_l,3) = l
            E_data_n(orbital_l,4) = s_z
!            write(*,*) (E_data_n(orbital_l,i),i=1,4)
            if (l==0) exit
         end do
      end do
   end do

! arrange data 
   call arrange(E_data_n,orbital,u_nlj_n,N)
!   do orbital_l=1,orbital
!      write(*,'(f15.6,f5.0,f5.0,f5.1)') (E_data_n(orbital_l,i),i=1,4)
!   end do

! new density, kinetic density
   open(12,file='density_n_new.dat')
   rho_n = 0d0
   tau_n = 0d0
   JJ_n = 0d0
   Nn_tmp = neutron
   do orbital_l=1,orbital
      Nn_l = Nn_tmp
      j_tot = E_data_n(orbital_l,3) + E_data_n(orbital_l,4)
      l = nint(E_data_n(orbital_l,3))
      Nn_tmp = Nn_tmp - nint(2d0*j_tot+1)
      if (Nn_tmp<=0) then
         orbital_tmp = orbital_l-1
         exit
      end if
      do i=1,N
         x = i*dx
         rho_n(i) = rho_n(i) + (2d0*j_tot+1)*abs(u_nlj_n(i,orbital_l))**2/(4d0*pi*x**2)
      end do
      do i=1,N-2
         x = i*dx
         tau_n(i) = tau_n(i) + (2d0*j_tot+1)*( ((4d0*u_nlj_n(i+1,orbital_l)&
              -3d0*u_nlj_n(i,orbital_l)-u_nlj_n(i+2,orbital_l))/(2d0*dx)&
              - u_nlj_n(i,orbital_l)/x)**2 +E_data_n(orbital_l,3)*(E_data_n(orbital_l,3)+1d0)*u_nlj_n(i,orbital_l)**2/x**2&
              )/(4d0*pi*x**2)
!         write(*,*) tau_n(i)
      end do
      do i=1,N
         x = i*dx
         JJ_n(i) = JJ_n(i) + (2d0*j_tot+1)*(j_tot*(j_tot+1d0)-l*(l+1d0)-0.75d0)*&
              u_nlj_n(i,orbital_l)**2/(4d0*pi*x**3)
      end do
      E_sp = E_sp + (2d0*j_tot+1)*energy_n(orbital_l)
   end do
   do i=1,N
      x = i*dx
      rho_n(i) = rho_n(i) + Nn_l*abs(u_nlj_n(i,orbital_tmp+1))**2/(4d0*pi*x**2)
   end do
   do i=1,N-2
      x = i*dx
      tau_n(i) = tau_n(i) + Nn_l*( ((4d0*u_nlj_n(i+1,orbital_tmp+1)&
           -3d0*u_nlj_n(i,orbital_tmp+1)-u_nlj_n(i+2,orbital_tmp+1))/(2d0*dx)&
           - u_nlj_n(i,orbital_tmp+1)/x)**2 + E_data_n(orbital_tmp+1,3)*(E_data_n(orbital_tmp+1,3) &
            +1d0)*u_nlj_n(i,orbital_tmp+1)**2/x**2&
           )/(4d0*pi*x**2)
   end do
   j_tot = E_data_n(orbital_tmp+1,3) + E_data_n(orbital_tmp+1,4)
   l = nint(E_data_n(orbital_tmp+1,3))
   do i=1,N
      x = i*dx
      JJ_n(i) = JJ_n(i) + Nn_l*(j_tot*(j_tot+1d0)-l*(l+1d0)-0.75d0)*&
           u_nlj_n(i,orbital_tmp+1)**2/(4d0*pi*x**3)
   end do

   rho_n(0) = 2d0*rho_n(1)-rho_n(2)
   tau_n(0) = 2d0*tau_n(1)-tau_n(2)
   tau_n(N-1) = 0d0
   tau_n(N) = 0d0
   JJ_n(0) = 2d0*JJ_n(1)-JJ_n(2)
   E_sp = E_sp + Nn_l*energy_n(orbital_tmp+1)
   do i=0,N
      x = i*dx
      write(12,'(4f15.8)') x, rho_n(i), tau_n(i), JJ_n(i)
   end do
   close(12)
!****************************************************

!*******************proton****************************
   E_data_p = 0d0
   orbital_l = 0
! calculate proton's eigenvalue and eigenstates
   do ex=0,n_max-1   !select the number of excited state (n)
      do l=0,l_max    !select angular momentum (l)
         do spin=1,2 !select spin (j=l+1/2 and j=l-1/2)
            orbital_l = orbital_l + 1
            if (spin==1) then
               s_z = 0.5
            else if (spin==2) then
               s_z = -0.5
            end if

! initialization
            E_left = E_m
            E_right = E_p
            
            psi(0) = 0d0
            psi(1) = 0.1d0

! h(r)
            do i=1,N-2
               x = i*dx
               h_p(i) = V_skyrme_p(i) + (4d0*M_eff_p(i+1)-3d0*M_eff_p(i)&
                    -M_eff_p(i+2))/(2d0*dx*x) + ((l+s_z)*(l+s_z+1d0)&
                    -l*(l+1d0)-0.75d0)*W_p(i)/(2d0*x)! + Vcoulomb(i, rho_p)
            end do
            h_p(0) = h_p(1)
            h_p(N-1:N) = 0d0
! bisection start
            do while(bisloop)
               count = 0
               E = E_left + 0.5d0*(E_right-E_left)
               if (E_right-E_left<epsi) exit
            
! f(r) and k_sq
               do i=1,N
                  x = i*dx
                  f_p(i) = -(h_p(i) +M_eff_p(i)*l*(l+1d0)/x**2-E)/M_eff_p(i)
                  k_sq_p(i) = -0.25d0*g_p(i)**2 + f_p(i)-0.5d0*dg_p(i)
               end do
               k_sq_p(0) = 2d0*k_sq_p(1)-k_sq_p(2)
! numerov
               do i=1,N-1
                  x = i*dx
!               psi(i+1) = 2d0*(1-dx**2*k_sq_p(i)/2d0)*psi(i) - psi(i-1)
                  psi(i+1) = (2d0*(1-5d0*dx**2*k_sq_p(i)/12d0)*psi(i)&
                       -(1+dx**2*k_sq_p(i-1)/12d0)*psi(i-1))/(1+dx**2*k_sq_p(i+1)/12d0) 
                  if (psi(i+1)*psi(i)<0) then
                     count = count + 1
                  end if
               end do
               if (count>ex) then
                  E_right = E
               else 
                  E_left = E
               end if

            end do

! wave func & eigenvalue
            E = E_right
!            write(*,*) E
! unbound or spurious states
            if (E-E_m<1e-5.or.E_p-E<1e-5) then
               orbital_l = orbital_l - 1
               exit
            end if
            energy_p(orbital_l) = E

            count = 0
            do i=1,N
               x = i*dx
               f_p(i) = -(h_p(i)+M_eff_p(i)*l*(l+1d0)/x**2-E)/M_eff_p(i)
               k_sq_p(i) = -0.25d0*g_p(i)**2 + f_p(i)-0.5d0*dg_p(i)
            end do
            k_sq_p(0) = 2d0*k_sq_p(1)-k_sq_p(2)
            do i=1,N-1
               x = i*dx
!            psi(i+1) = 2d0*(1-dx**2*k_sq_p(i)/2d0)*psi(i) - psi(i-1)
               psi(i+1) = (2d0*(1-5d0*dx**2*k_sq_p(i)/12d0)*psi(i)&
                    -(1+dx**2*k_sq_p(i-1)/12d0)*psi(i-1))/(1+dx**2*k_sq_p(i+1)/12d0)
               if (psi(i+1)*psi(i)<0) then
                  count = count + 1
               end if
               if (psi(i+1)*psi(i)<=0d0.and.count>ex) then
                  psi(i+1) = 0d0
                  exit
               end if
            end do
            psi(i+1:N) = 0d0
! normalization
            nmfactor = 0d0
            do i=0,N
               nmfactor = nmfactor + abs(psi(i))**2*dx/M_eff_p(i)
            end do
            nmfactor = sqrt(nmfactor)
            do i=0,N
               psi(i) = psi(i)/nmfactor/sqrt(M_eff_p(i))
            end do
            u_nlj_p(:,orbital_l) = psi(:)
            E_data_p(orbital_l,1) = E
            E_data_p(orbital_l,2) = ex+1
            E_data_p(orbital_l,3) = l
            E_data_p(orbital_l,4) = s_z
!            write(*,*) (E_data_p(orbital_l,i),i=1,4)
            if (l==0) exit
         end do
      end do
   end do

! arrange data 
   call arrange(E_data_p,orbital,u_nlj_p,N)
!   do orbital_l=1,orbital
!      write(*,'(f15.6,f5.0,f5.0,f5.1)') (E_data_p(orbital_l,i),i=1,4)
!   end do

! new density and kinetic density
   open(12,file='density_p_new.dat')
   rho_p = 0d0
   tau_p = 0d0
   JJ_p = 0d0
   Np_tmp = proton
   do orbital_l=1,orbital
      Np_l = Np_tmp
      j_tot = E_data_p(orbital_l,3) + E_data_p(orbital_l,4)
      l = nint(E_data_p(orbital_l,3))
      Np_tmp = Np_tmp - nint(2d0*j_tot+1)
      if (Np_tmp<=0) then
         orbital_tmp = orbital_l-1
         exit
      end if
      do i=1,N
         x = i*dx
         rho_p(i) = rho_p(i) + (2d0*j_tot+1)*abs(u_nlj_p(i,orbital_l))**2/(4d0*pi*x**2)
      end do
      do i=1,N-2
         x = i*dx
         tau_p(i) = tau_p(i) + (2d0*j_tot+1)*( ((4d0*u_nlj_p(i+1,orbital_l)&
              -3d0*u_nlj_p(i,orbital_l)-u_nlj_p(i+2,orbital_l))/(2d0*dx)&
              - u_nlj_p(i,orbital_l)/x)**2 + E_data_p(orbital_l,3)*(E_data_p(orbital_l,3)+1d0)*u_nlj_p(i,orbital_l)**2/x**2&
              )/(4d0*pi*x**2)
      end do
      do i=1,N
         x = i*dx
         JJ_p(i) = JJ_p(i) + (2d0*j_tot+1)*(j_tot*(j_tot+1d0)-l*(l+1d0)-0.75d0)*&
              u_nlj_p(i,orbital_l)**2/(4d0*pi*x**3)
      end do
      E_sp = E_sp + (2d0*j_tot+1)*energy_p(orbital_l)
   end do

   do i=1,N
      x = i*dx
      rho_p(i) = rho_p(i) + Np_l*abs(u_nlj_p(i,orbital_tmp+1))**2/(4d0*pi*x**2)
   end do
   do i=1,N-2
      x = i*dx
      tau_p(i) = tau_p(i) + Np_l*( ((4d0*u_nlj_p(i+1,orbital_tmp+1)&
           -3d0*u_nlj_p(i,orbital_tmp+1)-u_nlj_p(i+2,orbital_tmp+1))/(2d0*dx)&
           - u_nlj_p(i,orbital_tmp+1)/x)**2 + E_data_p(orbital_tmp+1,3)*&
            (E_data_p(orbital_tmp+1,3)+1d0)*u_nlj_p(i,orbital_tmp+1)**2/x**2&
           )/(4d0*pi*x**2)
   end do
   j_tot = E_data_p(orbital_tmp+1,3) + E_data_p(orbital_tmp+1,4)
   l = nint(E_data_p(orbital_tmp+1,3))
   do i=1,N
      x = i*dx
      JJ_p(i) = JJ_p(i) + Np_l*(j_tot*(j_tot+1d0)-l*(l+1d0)-0.75d0)*&
           u_nlj_p(i,orbital_tmp+1)**2/(4d0*pi*x**3)
   end do
   rho_p(0) = 2d0*rho_p(1)-rho_p(2)
   tau_p(0) = 2d0*tau_p(1)-tau_p(2)
   tau_p(N-1) = 0d0
   tau_p(N) = 0d0
   JJ_p(0) = 2d0*JJ_p(1)-JJ_p(2)
   E_sp = E_sp + Np_l*energy_p(orbital_tmp+1)
   do i=0,N
      x = i*dx
      write(12,'(4f15.8)') x, rho_p(i), tau_p(i), JJ_p(i)
   end do
   close(12)
!****************************************************

   rho(:) = rho_p(:)+rho_n(:)
   tau(:) = tau_p(:)+tau_n(:)
   JJ(:) = JJ_p(:)+JJ_n(:)

! HF energy
   number = 0d0
   E_ke = 0d0
   E_pot=0d0
   do i=0,N-2
      x = i*dx
      number = number + 4d0*pi*rho(i)*x**2*dx
      E_ke = E_ke + 4d0*pi*h2m*tau(i)*x**2*dx
      E_pot= E_pot + 4d0*pi*(0.5d0*t0*((1d0+0.5d0*x0)*rho(i)**2 -(x0+0.5d0)*(rho_p(i)**2+rho_n(i)**2))&
           + 0.25*t1*((1d0+0.5d0*x1)*(rho(i)*tau(i)+0.75d0*&
           ((4d0*rho(i+1)-3d0*rho(i)-rho(i+2))/(2d0*dx))**2)-(x1+0.5d0)*(rho_n(i)*tau_n(i)+0.75d0*&
           ((4d0*rho_n(i+1)-3d0*rho_n(i)-rho_n(i+2))/(2d0*dx))**2+rho_p(i)*tau_p(i)+0.75d0*&
           ((4d0*rho_p(i+1)-3d0*rho_p(i)-rho_p(i+2))/(2d0*dx))**2) )&
           + 0.25*t2*((1d0+0.5d0*x2)*(rho(i)*tau(i)-0.25d0*&
           ((4d0*rho(i+1)-3d0*rho(i)-rho(i+2))/(2d0*dx))**2)-(x2+0.5d0)*(rho_n(i)*tau_n(i)-0.25d0*&
           ((4d0*rho_n(i+1)-3d0*rho_n(i)-rho_n(i+2))/(2d0*dx))**2+rho_p(i)*tau_p(i)-0.25d0*&
           ((4d0*rho_p(i+1)-3d0*rho_p(i)-rho_p(i+2))/(2d0*dx))**2) )&
           - (t1*x1+t2*x2)*JJ(i)**2/16d0 + (t1-t2)*(JJ_n(i)**2+JJ_p(i)**2)/16d0 &
           +t3/12.d0*rho(i)**alpha*((1d0+0.5d0*x3)*rho(i)**2 -(x3+0.5d0)*(rho_p(i)**2+rho_n(i)**2))&
           + 0.5d0*W0*(JJ(i)*(4d0*rho(i+1)-3d0*rho(i)-rho(i+2))/(2d0*dx)&
           +JJ_n(i)*(4d0*rho_n(i+1)-3d0*rho_n(i)-rho_n(i+2))/(2d0*dx)&
           +JJ_p(i)*(4d0*rho_p(i+1)-3d0*rho_p(i)-rho_p(i+2))/(2d0*dx)) )*x**2*dx 
   end do

   E_hf_new = (E_ke + E_pot)
   write(*,'(i5,5f20.8)') rep, number, E_hf_new, E_sp, E_ke, E_pot
   if(abs(E_hf_new-E_hf).lt.epsi) exit

   E_hf= E_hf_new
   rho_p(:) = (1-corr)*rho_p(:) + corr*rho_old_p(:)
   rho_n(:) = (1-corr)*rho_n(:) + corr*rho_old_n(:)
   rho(:) = (1-corr)*rho(:) + corr*rho_old(:)
   tau_p(:) = (1-corr)*tau_p(:) + corr*tau_old_p(:)
   tau_n(:) = (1-corr)*tau_n(:) + corr*tau_old_n(:)
   tau(:) = (1-corr)*tau(:) + corr*tau_old(:)
   JJ_p(:) = (1-corr)*JJ_p(:) + corr*JJ_old_p(:)
   JJ_n(:) = (1-corr)*JJ_n(:) + corr*JJ_old_n(:)
   JJ(:) = (1-corr)*JJ(:) + corr*JJ_old(:)

end do
! iteration finish

!results

! output energy
open(11,file='energy_n.dat')
Nn_tmp = 0
do orbital_l=1,orbital
   j_tot = E_data_n(orbital_l,3) + E_data_n(orbital_l,4)
   Nn_tmp = Nn_tmp + nint(2d0*j_tot+1)
   if (E_data_n(orbital_l,1)>=0d0) exit
   write(11,'(f15.8,2i5,f5.1,i5)') E_data_n(orbital_l,1), nint(E_data_n(orbital_l,2)),&
        nint(E_data_n(orbital_l,3)), E_data_n(orbital_l,4), Nn_tmp
end do
close(11)
open(11,file='energy_p.dat')
Np_tmp = 0
do orbital_l=1,orbital
   j_tot = E_data_p(orbital_l,3) + E_data_p(orbital_l,4)
   Np_tmp = Np_tmp + nint(2d0*j_tot+1)
   if (E_data_p(orbital_l,1)>=0d0) exit
   write(11,'(f15.8,2i5,f5.1,i5)') E_data_p(orbital_l,1), nint(E_data_p(orbital_l,2)),&
        nint(E_data_p(orbital_l,3)), E_data_p(orbital_l,4), Np_tmp
end do
close(11)
   

! write wave_func
if (output_wave_func) then
   do orbital_l=1,orbital
      if (E_data_n(orbital_l,1)>=0d0) exit
      write(filename_wave_func_n(orbital_l),'(a1,I3.3,a1,I3.3,a4,2i2.2,i3.3,a5)') &
           'p', proton, 'n', neutron, 'nl2j', nint(E_data_n(orbital_l,2)),&
           nint(E_data_n(orbital_l,3)), nint(2d0*(E_data_n(orbital_l,3)+E_data_n(orbital_l,4))), 'n.dat'
      write(*,*) filename_wave_func_n(orbital_l)
      write(10,'(a6,3i5)') '#nl2j=', nint(E_data_n(orbital_l,2)),&
           nint(E_data_n(orbital_l,3)), nint(2d0*(E_data_n(orbital_l,3)+E_data_n(orbital_l,4)))
      do i=0,N
         x = i*dx
         write(10,'(3f15.8)') x, u_nlj_n(i,orbital_l)
      end do
      close(10)
   end do
   do orbital_l=1,orbital
      if (E_data_p(orbital_l,1)>=0d0) exit
      write(filename_wave_func_p(orbital_l),'(a1,I3.3,a1,I3.3,a4,2i2.2,i3.3,a5)') &
           'p', proton, 'n', neutron, 'nl2j', nint(E_data_p(orbital_l,2)),&
           nint(E_data_p(orbital_l,3)), nint(2d0*(E_data_p(orbital_l,3)+E_data_p(orbital_l,4))), 'p.dat'
      open(10,file=filename_wave_func_p(orbital_l))
      write(10,'(a6,3i5)') '#nl2j=', nint(E_data_p(orbital_l,2)),&
           nint(E_data_p(orbital_l,3)), nint(2d0*(E_data_p(orbital_l,3)+E_data_p(orbital_l,4)))
      do i=0,N
         x = i*dx
         write(10,'(3f15.8)') x, u_nlj_p(i,orbital_l)
      end do
      close(10)
   end do
end if

! calculate magic number, obtain BCS configuration space, solve BCS_eq
Nn_tmp = 0
flag = .true.
write(*,*) 'magic number for neutron:'
do orbital_l=1,orbital
   j_tot = E_data_n(orbital_l,3) + E_data_n(orbital_l,4)
   Nn_tmp = Nn_tmp + nint(2d0*j_tot+1)
   if (E_data_n(orbital_l,1)>=0d0) then
      flag = .false.
      exit
   end if
   if (E_data_n(orbital_l+1,1)-E_data_n(orbital_l,1)>3.5d0) then
      magic_n = Nn_tmp
      write(*,*) magic_n
      if (magic_n<=neutron) then
         orbital_down = orbital_l + 1
         NNN = neutron - magic_n
      end if
      if (magic_n>=neutron) then
         orbital_up = orbital_l
         exit
      end if
   end if
end do
if (flag.eqv..false.) then
   orbital_up = orbital_l - 1
end if
if (orbital_up<orbital_down) then
   write(*,*) 'neutron is in magic number.'
end if
if (orbital_up>=orbital_down.and.BCS_cal.eqv..true.) then
   BCS_level = orbital_up - orbital_down + 1
   allocate(v_n(orbital_down:orbital_up))
   call solve_BCS_equation(BCS_level,E_data_n(orbital_down:orbital_up,1:4),&
        NNN ,E_tot_n, lambda_n, delta_n, v_n(orbital_down:orbital_up))
   open(10,file='BCS_result_n.dat')
   write(10,'(a30,2f15.8)') 'total energy in BCS system', E_tot_n
   write(10,'(a30,2f15.8)') 'chemical potential', lambda_n
   write(10,'(a30,2f15.8)') 'pairing gap', delta_n
   write(10,*)
   write(10,'(a30)') 'occupation probability'
   write(10,'(a15,3a5,a15)') 'sp_energy', 'n', 'l', 's_z', 'occ_prob'
   do orbital_l=orbital_down,orbital_up
      write(10,'(f15.8,2i5,f5.1,f15.8)') E_data_n(orbital_l,1),&
           nint(E_data_n(orbital_l,2)), nint(E_data_n(orbital_l,3)),&
           E_data_n(orbital_l,4), abs(v_n(orbital_l)**2)
   end do
   close(10)
   rho_BCS_n(:) = 0d0
   do orbital_l=1,orbital_down-1
      do i=1,N
         x = i*dx
         j_tot = E_data_n(orbital_l,3) + E_data_n(orbital_l,4)
         rho_BCS_n(i) = rho_BCS_n(i) + (2d0*j_tot+1)*abs(u_nlj_n(i,orbital_l))**2/(4d0*pi*x**2)
      end do
   end do
   do orbital_l=orbital_down,orbital_up
      do i=1,N
         x = i*dx
         j_tot = E_data_n(orbital_l,3) + E_data_n(orbital_l,4)
         rho_BCS_n(i) = rho_BCS_n(i) + abs(v_n(orbital_l)**2)*&
              (2d0*j_tot+1)*abs(u_nlj_n(i,orbital_l))**2/(4d0*pi*x**2)
      end do
   end do
   rho_BCS_n(0) = 2d0*rho_BCS_n(1)-rho_BCS_n(2)
   open(10,file='density_BCS_n.dat')
   do i=0,N
      x = i*dx
      write(10,'(3f15.8)') x, rho_BCS_n(i)
   end do
   close(10)
   deallocate(v_n)
end if

Np_tmp = 0
flag = .true.
write(*,*) 'magic number for proton:'
do orbital_l=1,orbital
   j_tot = E_data_p(orbital_l,3) + E_data_p(orbital_l,4)
   Np_tmp = Np_tmp + nint(2d0*j_tot+1)
   if (E_data_p(orbital_l,1)>=0d0) then
      flag = .false.
      exit
   end if
   if (E_data_p(orbital_l+1,1)-E_data_p(orbital_l,1)>3.5d0) then
      magic_p = Np_tmp
      write(*,*) magic_p
      if (magic_p<=proton) then
         orbital_down = orbital_l + 1
         PPP = proton - magic_p
      end if
      if (magic_p>=proton) then
         orbital_up = orbital_l
         exit
      end if
   end if
end do
if (flag.eqv..false.) then
   orbital_up = orbital_l - 1
end if
if (orbital_up<orbital_down) then
   write(*,*) 'proton is in magic number.'
end if

if (orbital_up>=orbital_down.and.BCS_cal.eqv..true.) then
   BCS_level = orbital_up - orbital_down + 1
   allocate(v_p(orbital_down:orbital_up))
   call solve_BCS_equation(BCS_level,E_data_p(orbital_down:orbital_up,1:4),&
        PPP ,E_tot_p, lambda_p, delta_p, v_p(orbital_down:orbital_up))
   open(10,file='BCS_result_p.dat')
   write(10,'(a30,2f15.8)') 'total energy in BCS system', E_tot_p
   write(10,'(a30,2f15.8)') 'chemical potential', lambda_p
   write(10,'(a30,2f15.8)') 'pairing gap', delta_p
   write(10,*)
   write(10,'(a30)') 'occupation probability'
   write(10,'(a15,3a5,a15)') 'sp_energy', 'n', 'l', 's_z', 'occ_prob'
   do orbital_l=orbital_down,orbital_up
      write(10,'(f15.8,2i5,f5.1,f15.8)') E_data_p(orbital_l,1),&
           nint(E_data_p(orbital_l,2)), nint(E_data_p(orbital_l,3)),&
           E_data_p(orbital_l,4), abs(v_p(orbital_l)**2)
   end do
   close(10)
   rho_BCS_p(:) = 0d0
   do orbital_l=1,orbital_down-1
      do i=1,N
         x = i*dx
         j_tot = E_data_p(orbital_l,3) + E_data_p(orbital_l,4)
         rho_BCS_p(i) = rho_BCS_p(i) + (2d0*j_tot+1)*abs(u_nlj_p(i,orbital_l))**2/(4d0*pi*x**2)
      end do
   end do
   do orbital_l=orbital_down,orbital_up
      do i=1,N
         x = i*dx
         j_tot = E_data_p(orbital_l,3) + E_data_p(orbital_l,4)
         rho_BCS_p(i) = rho_BCS_p(i) + abs(v_p(orbital_l)**2)*&
              (2d0*j_tot+1)*abs(u_nlj_p(i,orbital_l))**2/(4d0*pi*x**2)
      end do
   end do
   rho_BCS_p(0) = 2d0*rho_BCS_p(1)-rho_BCS_p(2)
   open(10,file='density_BCS_p.dat')
   do i=0,N
      x = i*dx
      write(10,'(3f15.8)') x, rho_BCS_p(i)
   end do
   close(10)
   deallocate(v_p)
end if


do i=1, Nmesh
x=i*dx
!write(222, *) x,Vcoulomb(i, rho_p)
enddo
deallocate(E_data_n,E_data_p)
deallocate(filename_wave_func_n,filename_wave_func_p)
deallocate(energy_n,energy_p,wave_func_n,wave_func_p)
deallocate(V_skyrme_p,V_skyrme_n,M_eff_p,M_eff_n,W_p,W_n,g_p,g_n,dg_p,dg_n,f_p,f_n,h_p,h_n)
deallocate(psi,u_nlj_p,u_nlj_n)
deallocate(rho_p,rho_n,rho,tau_p,tau_n,tau,rho_old_n,rho_old_p,rho_old,JJ_p,JJ_n,JJ,&
     tau_old_n,tau_old_p,tau_old,JJ_old_n,JJ_old_p,JJ_old,k_sq_p,k_sq_n,rho_BCS_p,rho_BCS_n,rho_BCS)



end program skyrme


      


