!*********************************************************************
! Filename:      mpiIO.f90
! Author:        Prasad Maddumage <mhemantha@fsu.edu>
! Created at:    Wed Oct  4 22:48:02 2017
! Modified at:   Thu Oct  5 10:16:15 2017
! Modified by:   Prasad Maddumage <mhemantha@fsu.edu>
! Version:       
! Description:   ! example of parallel MPI write into a single file
!*********************************************************************

PROGRAM main

  use mpi

  implicit none
  
  integer            :: ierr, i, myrank, thefile, type_size
  integer, parameter :: BUFSIZE=100
  integer            :: buf(BUFSIZE)
  integer(kind=MPI_OFFSET_KIND) :: displacement
  
  call MPI_INIT(ierr)
  call MPI_COMM_RANK(MPI_COMM_WORLD, myrank, ierr)
! Find the size of MPI_INTEGER in bytes
  call MPI_TYPE_SIZE(MPI_INTEGER, type_size, ierr)

! Making some data
  do i = 0, BUFSIZE
      buf(i) = myrank * BUFSIZE + i
  enddo

! Each process opens the file together
  call MPI_FILE_OPEN(MPI_COMM_WORLD, 'testfile.bin', &
         MPI_MODE_WRONLY + MPI_MODE_CREATE, &
         MPI_INFO_NULL, thefile, ierr)
  
! displacement is the number of bytes to be skipped from the start of the file
  displacement = myrank * BUFSIZE * type_size
! Only a portion of the file is visible to a given process
! datarep = 'native': Data is stored exactly as it is in memory
  call MPI_FILE_SET_VIEW(thefile, displacement, MPI_INTEGER, &
         MPI_INTEGER, 'native', MPI_INFO_NULL, ierr)
  call MPI_FILE_WRITE(thefile, buf, BUFSIZE, MPI_INTEGER, &
         MPI_STATUS_IGNORE, ierr)
  call MPI_FILE_CLOSE(thefile, ierr)
  call MPI_FINALIZE(ierr)

END PROGRAM main

