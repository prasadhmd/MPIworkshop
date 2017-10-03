!*********************************************************************
! Filename:      hello.f90
! Author:        Prasad Maddumage <mhemantha@fsu.edu>
! Created at:    Mon Jun 30 15:38:31 2014
! Modified at:   Mon Oct  2 11:59:09 2017
! Modified by:   Prasad Maddumage <mhemantha@fsu.edu>
! Version:       $Revision: 1.1 $
! Description:   
!*********************************************************************
program hello2
  implicit none
  include 'mpif.h'

  integer, parameter :: master = 0
  integer            :: my_rank, l, source, tag, n_procs, ierr
  character(len=256) :: message
  character(len=8)   :: rank_string
  integer            :: status(MPI_STATUS_SIZE)
  integer            :: string_len
  character*(MPI_MAX_PROCESSOR_NAME) :: my_proc_name

!Initializing MPI
  call MPI_Init(ierr)

  call MPI_Comm_rank(MPI_COMM_WORLD, my_rank, ierr)
  call MPI_Comm_size(MPI_COMM_WORLD, n_procs, ierr)
  call MPI_Get_processor_name(my_proc_name, l, ierr)

!Slave nodes run the following part of the code
  if (my_rank /= master) then
!Convert integer "my_rank" to a string
       write(rank_string, fmt = '(I2.2)') my_rank
!Creating the message to be sent
       message = 'Hello from '//trim(my_proc_name)//&
              '. My rank is '//trim(adjustl(rank_string))
!Create a tag for the message to be sent
       tag = 0
!Send the message to the master node
       call MPI_Send(message, len(message), MPI_CHARACTER, &
              master, tag, MPI_COMM_WORLD, ierr)
  else
!Following commands are run only by master node
!tag of the incoming messages are "0"
       tag = 0
!Need to receive messages sent by 1, ..., n_procs-1 processes
       do source = 1, n_procs - 1
           call MPI_Recv(message, len(message), MPI_CHARACTER, &
                  source, tag, MPI_COMM_WORLD, status, ierr)
!Printing messages as they are received
           print *, trim(message)
       end do
  end if

!Shut down MPI
  call MPI_Finalize(ierr)

end program hello2
