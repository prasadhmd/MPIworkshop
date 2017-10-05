!*********************************************************************
! Filename:      comm1.f90
! Author:        Prasad Maddumage <mhemantha@fsu.edu>
! Created at:    Sat Sep 30 09:01:15 2017
! Modified at:   Wed Oct  4 21:04:44 2017
! Modified by:   Prasad Maddumage <mhemantha@fsu.edu>
! Version:       $Id$
! Description:   
!*********************************************************************
program comm1

  use mpi

  implicit none

  integer, parameter :: SAME_TAG = 1
  integer            :: rank, size, ierr, one, two, buf1, buf2, sum1, sum2
  integer            :: comm_two, request(4), stati(MPI_STATUS_SIZE,4)
  
  call MPI_Init(ierr)
  call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr);
  call MPI_Comm_size(MPI_COMM_WORLD, size, ierr);

  call MPI_Comm_dup(MPI_COMM_WORLD, comm_two, ierr);

  one = rank + 1;
  two = (rank + 1) * 2;
!Two non-blocking receives of the same type from the same source with
! the same tag, but for two different contexts.
!Obtain single integer from their right-hand neighbors in a ring fashion
  call MPI_Irecv(buf1, 1, MPI_INT, merge(0, rank + 1, rank == (size - 1)), &
         SAME_TAG, MPI_COMM_WORLD, request(1), ierr)
  call MPI_Irecv(buf2, 1, MPI_INT, merge(0, rank + 1, rank == (size - 1)), &
         SAME_TAG, comm_two, request(2), ierr)
  call MPI_Isend(two, 1, MPI_INT, merge(size - 1, rank - 1, rank == 0), &
         SAME_TAG, comm_two, request(3), ierr)
  call MPI_Isend(one, 1, MPI_INT, merge(size - 1, rank - 1, rank == 0), &
         SAME_TAG, MPI_COMM_WORLD, request(4), ierr)

!Collective communication mixed with point-to-point communication.
! MPI guarantees that a single communicator can do safe point-to-point
! and collective communication.
  call MPI_Waitall(4, request, stati, ierr)
  call MPI_Allreduce(one, sum1, 1, MPI_INT, MPI_SUM, MPI_COMM_WORLD, ierr)
  call MPI_Allreduce(two, sum2, 1, MPI_INT, MPI_SUM, comm_two, ierr)

  print *, rank, " Received buf1= ", buf1, " and buf2= ", buf2, &
         " sum1= ", sum1, "and sum2= ", sum2

  call MPI_Comm_free(comm_two, ierr)
  call MPI_Finalize(ierr)

end program comm1
  
