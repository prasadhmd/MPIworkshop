!*********************************************************************
! Filename:      ring.f90
! Author:        Prasad Maddumage <mhemantha@fsu.edu>
! Created at:    Mon Jul  7 09:15:47 2014
! Modified at:   Thu Sep 18 10:46:40 2014
! Modified by:   Prasad Maddumage <mhemantha@fsu.edu>
! Version:       $Revision: 1.1 $
! Description:   Exchange data between nearest neighbors
!                Adapted from "mpi_ringtopo.f" by Blaise Barney
!https://computing.llnl.gov/tutorials/mpi/samples/Fortran/mpi_ringtopo.f
!*********************************************************************
program ring
  implicit none
  include 'mpif.h'

  integer :: n_procs, my_rank, next, prev, buf(2), ierr
  integer :: stats(MPI_STATUS_SIZE,4), reqs(4)

!Initializing MPI
  call MPI_INIT(ierr)
  call MPI_COMM_RANK(MPI_COMM_WORLD, my_rank, ierr)
  call MPI_COMM_SIZE(MPI_COMM_WORLD, n_procs, ierr)

!Who are my neighbors (prev and next)?
  prev = my_rank - 1
  next = my_rank + 1
!Rank 0's "previous" neighbor is n-1
  if (my_rank == 0)  prev = n_procs - 1
!Rank n_procs-1's "next" neighbor is 0
  if (my_rank == n_procs - 1) next = 0

  call MPI_IRECV(buf(1), 1, MPI_INTEGER, prev, 1, MPI_COMM_WORLD, reqs(1), ierr)
  call MPI_IRECV(buf(2), 1, MPI_INTEGER, next, 2, MPI_COMM_WORLD, reqs(2), ierr)

  call MPI_ISEND(my_rank, 1, MPI_INTEGER, prev, 2, MPI_COMM_WORLD, reqs(3), ierr)
  call MPI_ISEND(my_rank, 1, MPI_INTEGER, next, 1, MPI_COMM_WORLD, reqs(4), ierr)

  call MPI_WAITALL(4, reqs, stats, ierr)

  print *, 'Data in rank ', my_rank, ':', buf

  call MPI_FINALIZE(ierr)

end program ring
