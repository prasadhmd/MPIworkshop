!*********************************************************************
! Filename:      reduce.f90
! Author:        Prasad Maddumage <mhemantha@fsu.edu>
! Created at:    Tue Jul  8 12:11:31 2014
! Modified at:   Wed Jul  9 15:40:10 2014
! Modified by:   Prasad Maddumage <mhemantha@fsu.edu>
! Version:       $Revision: 1.1 $
! Description:   Use MPI to do a parallel sum.
!*********************************************************************
program reduce
  implicit none
  include 'mpif.h'

  integer, parameter :: n = 100, seed = 323123, master = 0
  integer :: my_rank, n_procs, ierr
  integer :: i, i1, i2, m
  real    :: harvest, my_sum, data_sum, data(n)

!Initializing MPI
  call MPI_INIT(ierr)
  call MPI_COMM_RANK(MPI_COMM_WORLD, my_rank, ierr)
  call MPI_COMM_SIZE(MPI_COMM_WORLD, n_procs, ierr)

!Generate some random data (only master node)
  If (my_rank == master) then
       do i = 1, n
           call random_number(harvest)
           data(i) = harvest
       end do
  endif

!Send the data to all workers
  call MPI_BCAST(data, n, MPI_REAL, master, MPI_COMM_WORLD, ierr)

!Load balancing: How many elements should one worker has to deal with?
  m = ceiling(real(n) / n_procs)
!What range of elements [i1:i2] am I working on?
  i1 = my_rank * m + 1
  i2 = (1 + my_rank) * m
!Right hand boundary cannot exceed 100
  if (i2 > n) i2 = n

!Do some work: Find the sum of YOUR portion of the data
  my_sum = sum(data(i1:i2))

!Reduction among all workers and sending the result to master node
  call MPI_REDUCE(my_sum, data_sum, 1, MPI_REAL, MPI_SUM, master, &
         MPI_COMM_WORLD, ierr)

!Printing parallel result and validation by master node
  If (my_rank == master) print *,"Parallel result :", data_sum, &
         "Sum of all data :", sum(data)
  
  call MPI_FINALIZE(ierr)

end program reduce
