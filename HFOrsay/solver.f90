
!>This routine solves the Hartree-Fock Equations in a spherical basis.
!>We are here using a Block Diagonalisation method.
!>The block are labeled by the quantum numbers (l,j) in the reduced basis.
subroutine solver(pr)
use basis
use maths
use constants
use pot
use bcs
implicit none
logical::pr
integer::i,l,j,k,jf,q
integer::sizebloc
integer::info,lwork
integer::it
double precision,parameter::eps=1.d-11 
double precision,allocatable::rho(:,:,:,:),eigvec(:,:,:,:),gama(:,:,:,:)
double precision,allocatable::t(:,:,:),h(:,:,:,:),eigval(:,:,:),work(:)
double precision,allocatable::conv(:,:,:),v2(:),esp(:),qesp(:)
double precision::diff,hfenergy,partnum,kinenergy,hfenergybcs
double precision,allocatable::rhobcs(:,:,:,:)

sizebloc=maxval(n_red) + 1
allocate(rho(lmin:lmax,jmin:jmax,sizebloc,sizebloc))
allocate(rhobcs(lmin:lmax,jmin:jmax,sizebloc,sizebloc))
allocate(gama(lmin:lmax,jmin:jmax,sizebloc,sizebloc))
allocate(eigvec(lmin:lmax,jmin:jmax,sizebloc,sizebloc))
allocate(h(lmin:lmax,jmin:jmax,sizebloc,sizebloc))
allocate(t(lmin:lmax,sizebloc,sizebloc))
allocate(work(26*sizebloc))
allocate(conv(lmin:lmax,jmin:jmax,maxit))
allocate(eigval(lmin:lmax,jmin:jmax,sizebloc))
allocate(v2(red_size),esp(red_size),qesp(red_size))


lwork = 26*sizebloc
conv = 0.d0
do it = 1,maxit !Hartree-Fock Iteration (Self-Consistent algorithm)
 do l = lmin,lmax !Construction of the density matrix for all the possible blocks
  if (l == 0) then
     jf = 0
  else
     jf = 1
  endif
  do k=0,jf
  if (l == 0) then 
    j = 1
   elseif (k==0) then
    j = 2*l - 1
   else
    j = 2*l+1
  endif
  ! Computation of the Density matrix for a given (l,j) block
  call compute_rho(rho(l,j,:,:),eigvec(l,j,:,:),sizebloc,l,j,it)
    if (it .eq. 1) then  ! Initialisation Kinetic Matrix
      call t_bloc(sizebloc,l,t(l,:,:))
    endif !it
  enddo !j
 enddo !l

 do l = lmin,lmax !Second loop over the block in order to compute the Hamiltonian to diagonalize
  if (l == 0) then
     jf = 0
  else
     jf = 1
  endif
  do k=0,jf
  if (l == 0) then 
    j = 1
   elseif (k==0) then
    j = 2*l - 1
   else
    j = 2*l+1
  endif
  ! Computation of the interaction part of the Hamiltonina
  call compute_gamma(gama(l,j,:,:),rho,sizebloc,l,j)
  ! Construction of the Hamiltonina
  h(l,j,:,:) = t(l,:,:) + gama(l,j,:,:)
  eigvec(l,j,:,:) = h(l,j,:,:)
  info = 0
  !Diagonalization Routine
  call dsyev('V','U',sizebloc,eigvec(l,j,:,:),sizebloc,eigval(l,j,:),work,lwork,info)
  if (info .ne. 0) stop "Diagonalization Failed"
  !The criterion of convergency is taken to be the sum of the eigenvalues for each block
  do q = 1,sizebloc
  conv(l,j,it) = conv(l,j,it) + eigval(l,j,q)
  enddo
  conv(l,j,it) = conv(l,j,it)/sizebloc
  enddo !j
 enddo !l

hfenergy = 0.d0
kinenergy = 0.d0
partnum = 0.d0
diff = 0.d0
 do l = lmin,lmax
  if (l == 0) then
     jf = 0
  else
     jf = 1
  endif
  do k=0,jf
  if (l == 0) then 
    j = 1
   elseif (k==0) then
    j = 2*l - 1
   else
    j = 2*l+1
  endif
  if (it .gt. 1) then
  diff = diff + abs(conv(l,j,it) - conv(l,j,it-1))
endif
! Computation at each iteration of the Kinetic and Hartree-Fock energy and of the total particles number
  kinenergy = kinenergy + trace(matmul(t(l,:,:),rho(l,j,:,:)),sizebloc)
  hfenergy = hfenergy + trace(matmul(t(l,:,:),rho(l,j,:,:)),sizebloc) + half*trace(matmul(gama(l,j,:,:),rho(l,j,:,:)),sizebloc)
  partnum = partnum + trace(rho(l,j,:,:),sizebloc)
  do q = 1,sizebloc
        esp(tag_hf(q-1,l,j)) = eigval(l,j,q)
        if (nocc(tag_hf(q-1,l,j)) .ne. 0.d0) then
        v2(tag_hf(q-1,l,j)) = 1.d0
        else
        v2(tag_hf(q-1,l,j)) = 0.d0
        endif
  enddo !q
  enddo !k
 enddo !l
diff = diff/(lmax*2)
write(*,*) "Iteration. ",it,"diff= ",diff
!Final Convergence Check of the Self-Consistent procedure
 if (it .gt. 1 .and. diff .lt. eps) exit
enddo !it
write(*,*) "Hartree-Fock Energy",hfenergy

!Pairing part
if (flagbcs .eq. 1) then
write(*,*) "BCS Computation"
call pairing(red_size,esp,v2,rhobcs,.false.)
rho = rhobcs
partnum = two*sum(v2,red_size)
hfenergybcs = 0.d0
do k=1,red_size
 qesp(k) = esp(k) - x2 
 hfenergybcs = hfenergybcs + (two*qesp(k)*v2(k))
enddo
 hfenergybcs = hfenergybcs - gap**2/g_pair
endif
write(*,*) "Particles Number",partnum
!Printing out in a file
call printer(red_size,hfenergy,hfenergybcs,v2,esp,partnum,pr)
if (iplot .eq. 1) call spatial_rho(rho)


! Memory deallocation -------------------------
deallocate(rho,h,t,gama,work,conv,rhobcs)
deallocate(esp,qesp)
end subroutine














