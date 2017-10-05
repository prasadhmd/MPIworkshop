!*********************************************************************
! Filename:      mpi_struct.f90
! Author:        Prasad Maddumage <mhemantha@fsu.edu>
! Created at:    Sun Oct  1 21:42:05 2017
! Modified at:   Wed Oct  4 21:44:37 2017
! Modified by:   Prasad Maddumage <mhemantha@fsu.edu>
! Version:       
! Description:   Custom data type for N-body problem
!*********************************************************************
program struct

  use mpi
  
  implicit none

  integer, parameter :: nelem = 5
  integer            :: my_rank, numtasks, source, dest, tag, ierr, i
  integer            :: stat(MPI_STATUS_SIZE)
  integer(KIND=MPI_ADDRESS_KIND) :: offsets(0:2)
  real               :: position(3)
  
  type :: particle
     real    :: pos(3), velocity(3)
     integer :: n
  end type particle

  type (particle) :: pcle, particles(nelem)

  integer :: particletype, oldtypes(0:2)
  integer :: blockcounts(0:2)

  tag = 1

  call MPI_INIT(ierr)
  call MPI_COMM_RANK(MPI_COMM_WORLD, my_rank, ierr)
  call MPI_COMM_SIZE(MPI_COMM_WORLD, numtasks, ierr)

  call MPI_GET_ADDRESS(pcle%pos, offsets(0), ierr)
  call MPI_GET_ADDRESS(pcle%velocity, offsets(1), ierr)
  call MPI_GET_ADDRESS(pcle%n, offsets(2), ierr)
  
  offsets(1:2) = offsets(1:2) - offsets(0)
  offsets(0) = 0
  oldtypes = (/MPI_REAL, MPI_REAL, MPI_INTEGER/)
  blockcounts = (/3, 3 ,1/)

  call MPI_TYPE_CREATE_STRUCT(3, blockcounts, offsets, oldtypes, &
         particletype, ierr)
  call MPI_TYPE_COMMIT(particletype, ierr)

! task 0 initializes the particle array and then sends it to each task
  if (my_rank .eq. 0) then
       do i = 1, nelem
           position = (/1.0*i, -1.0*i, 1.0*i/)
           particles(i)%pos = position
           particles(i)%velocity = (/0.25*i, -0.1*i, 0.9*i/)
           particles(i)%n = i
       end do
  endif

  call MPI_BCAST(particles, nelem, particletype, 0, MPI_COMM_WORLD, ierr)

  do i = 1, nelem
      print *, 'rank= ',my_rank,'velocity(1) of particle ', &
             i, ' = ', particles(i)%velocity(1)
  end do

! free datatype when done using it
  call MPI_TYPE_FREE(particletype, ierr)
  call MPI_FINALIZE(ierr)

end program struct
