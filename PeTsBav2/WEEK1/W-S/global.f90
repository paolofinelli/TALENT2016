!     Global variables for the finite square well potential in main.f90
      module globals
      implicit none
      integer, parameter :: dm=kind(1.d0)
      real (kind=dm) ::h2m= 20.75, epsi=1e-6, V0=5.
      real (kind=dm) :: R_max=6., R_min=0., R_box=6.,h=0.1,Em, nmfactor, a=0.67
      integer  :: Nmesh
      real (kind=dm),allocatable :: rho(:) ,Psi(:)! psi(grid_index)
      logical :: comparison= .true., bisloop= .true.
      real (kind=dm) :: E_minus=0., E_plus=100., E_left, E_right
      integer(kind=dm) :: numnodes ! the number of excited state, that has to be the same as number of nodes in wavefunction
      integer(kind=dm) :: cnodes ! nodes of wavefuntion 
      integer(kind=dm) :: i
      real(kind=dm),allocatable :: k_sq(:)
      real(kind=dm) :: x  
      end module globals



