!*********************************************************************
! Filename:      comm2.f90
! Author:        Prasad Maddumage <mhemantha@fsu.edu>
! Created at:    Sat Sep 30 11:00:46 2017
! Modified at:   Sat Sep 30 14:45:47 2017
! Modified by:   Prasad Maddumage <mhemantha@fsu.edu>
! Version:       
! Description:   
!*********************************************************************
program comm2

  use mpi

  implicit none

  integer            :: rank(2), size(2), ierr, mpi_group_world, &
         group_slaves, comm_slaves, namelen, send_val, recv_val, &
         send_val2, recv_val2, xranks(1)
  character*(MPI_MAX_PROCESSOR_NAME) :: processor_name

  xranks(1) = 0
  call MPI_Init(ierr)
  call MPI_Comm_rank(MPI_COMM_WORLD, rank(1), ierr)
  call MPI_Comm_size(MPI_COMM_WORLD, size(1), ierr)
  call MPI_Get_processor_name(processor_name, namelen, ierr)
  
  call MPI_Comm_group(MPI_COMM_WORLD, mpi_group_world, ierr)
  call MPI_Group_excl(mpi_group_world, 1, xranks, group_slaves, ierr)
  call MPI_Comm_create(MPI_COMM_WORLD, group_slaves, comm_slaves, ierr)

  print *, "Hello world! I’m rank ", rank(1), " of ", size(1), &
         " on ", processor_name(1:namelen)

  if (rank(1) /= 0) then
       call MPI_Comm_rank(comm_slaves, rank(2), ierr)
       call MPI_Comm_size(comm_slaves, size(2), ierr)

       print *, "In the slave universe I’m rank ", rank(2), &
              " of ", size(2), " on ", processor_name(1:namelen)
       send_val = size(2);
       call MPI_Reduce(send_val, recv_val, 1, MPI_INT, MPI_SUM, 0, comm_slaves, ierr)
       if (rank(2) == 0) then
            print *, "Slave leader received reduced value ", recv_val
       end if
  end if

  send_val2 = size(1)
  call MPI_Reduce(send_val2, recv_val2, 1, MPI_INT, MPI_SUM, 0, &
         MPI_COMM_WORLD, ierr)
  if (rank(1) == 0) then
       print *, "Master received reduced value ", recv_val2
  end if
  if (comm_slaves /= MPI_COMM_NULL) then
       call MPI_Comm_free(comm_slaves, ierr)
  end if

  call MPI_Group_free(group_slaves, ierr)
  call MPI_Group_free(mpi_group_world, ierr)
  call MPI_Finalize(ierr)
  
end program comm2


  
