!*********************************************************************
! Filename:      mc_pi.f90
! Author:        Prasad Maddumage <mhemantha@fsu.edu>
! Created at:    Wed Jul 23 09:21:07 2014
! Modified at:   Thu Jul 24 09:37:12 2014
! Modified by:   Prasad Maddumage <mhemantha@fsu.edu>
! Version:       $Revision: 1.1 $
! Description:   Estimate value of PI using Monti Carlo method
!*********************************************************************
program mc_pi
  implicit none
  include 'mpif.h'

  integer, parameter :: count = 100000, master = 0
  integer :: my_rank, n_procs, ierr, seed(8)
  integer :: i, my_count, tot_count, my_circle, tot_circle
  real    :: harvest, x, x2, y, y2, r2, pi, pi_mc

  data seed/27499, 37813, 48611, 59359, 70657, 76207, 81799, 93179/
!Initializing MPI
  call MPI_INIT(ierr)
  call MPI_COMM_RANK(MPI_COMM_WORLD, my_rank, ierr)
  call MPI_COMM_SIZE(MPI_COMM_WORLD, n_procs, ierr)

!We take ceiling (round it up, not down) so that only one process
! waits for everyone else not everyone else wait for one process to finish
  my_count = ceiling(real(count) / real(n_procs))

!Finding a GOOD random number generator is very important for Monte Carlo
! methods. Here, we use the simple built in random_number()
!Each process needs a unique seed so that everyone have different random
! number sequences
  seed = seed + my_rank + 1
  call random_seed(put = seed)
  my_circle = 0
  do i = 1, my_count
!Randomly find a point (x,y) where -1<=x<1, -1<=y<1
      call random_number(harvest)
      x = 2.0 * harvest - 1.0
      x2 = x * x
      call random_number(harvest)
      y = 2.0 * harvest - 1.0
      y2 = y * y
!Calculate the distance to this point from origin (0,0)
      r2 = x2 + y2
!If r^2 <= 1, the point is inside the circle of radius 1
      if (r2 <= 1.0) my_circle = my_circle + 1
  end do

!Send partial results to master node
  call MPI_REDUCE(my_count, tot_count, 1, MPI_INTEGER, MPI_SUM, master, &
         MPI_COMM_WORLD, ierr)
  call MPI_REDUCE(my_circle, tot_circle, 1, MPI_INTEGER, MPI_SUM, master, &
         MPI_COMM_WORLD, ierr)

!Calculate the final result in the master node
  if (my_rank == master) then
       pi_mc = 4.0 * tot_circle / tot_count
!For comparison, we need the actual value of PI
       pi = 4.0 * atan(1.0)
       print *, "Estimated value of PI using Monte Carlo method: ", pi_mc
       print *, "Percentage Error: ", 100.0 * abs(pi - pi_mc)/pi, " %"
  endif

  call MPI_FINALIZE(ierr)
  
end program mc_pi
