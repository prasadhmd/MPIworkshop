!*********************************************************************
! Filename:      mat_mul_par.f90
! Author:        Prasad Maddumage <mhemantha@fsu.edu>
! Created at:    Mon Jul 14 08:49:19 2014
! Modified at:   Wed Jul 16 15:41:30 2014
! Modified by:   Prasad Maddumage <mhemantha@fsu.edu>
! Version:       $Revision: 1.3 $
! Description:   Parallel matrix multiplication
!*********************************************************************
program mat_mul_par

  implicit none

!Include the MPI header file
  include 'mpif.h'

!number of rows in A, B = nr_a, nr_b
!number of columns in A, B = nc_a, nc_b
  integer, parameter :: MASTER = 0, nc_a = 4, nr_a = 4, nr_b = 4, nc_b = 4
  integer            :: n_procs, my_rank, len, ierr
  integer            :: nc_local, n2, n_el, i, j, k
  real(kind = 8)     :: t_start, t_finish
  real               :: t1, t2, a(nr_a,nc_a), b(nr_b,nc_b), c(nr_a,nc_b)
  real, allocatable  :: b_local(:,:), c_local(:,:)

!Initializing MPI
  call MPI_INIT(ierr)
  call MPI_COMM_SIZE(MPI_COMM_WORLD, n_procs, ierr)
  call MPI_COMM_RANK(MPI_COMM_WORLD, my_rank, ierr)

!Initialize matrices A and B with some data (on MASTER node)
  if (my_rank == MASTER) then
       do i = 1, nr_a
           do j = 1, nc_a
               a(i,j) = real(i + j)
            end do
       end do
       
       do i = 1, nr_b
           do j = 1, nc_b
               b(i,j) = real(i * j)
           end do
       end do
!Start counting time
       t_start = MPI_Wtime()
  end if
  
!Load balancing: each process calculate same number of elements in matrix C
!Let each process only calculate few columns of C
!Matrix multiplication: C(i,j) = {sum over all k} A(i,k) * B(k,j)
!Therefore, each process needs only few columns of matrix B
!nc_local = number of columns calculated by each process
  nc_local = ceiling(real(nc_b) / n_procs)
!nc_b >= n_procs must be true

!B_local and C_local will hold the columns needed/calculated
!by a SINGLE process
  allocate(b_local(nr_b,nc_local), c_local(nr_a,nc_local))
  b_local = 0.0; c_local = 0.0

!All processes need matrix A. Therefore, BCAST it
  n_el = nr_a * nc_a !Total number of elements in matrix A
  call MPI_BCAST(a, n_el, MPI_REAL, MASTER, MPI_COMM_WORLD, ierr)
!Send n columns each from matrix B to ALL processes (including MASTER)
  n2 = nc_local * nr_b !# of elements in n number of columns
  call MPI_SCATTER(b, n2, MPI_REAL, b_local, n2, MPI_REAL, MASTER, &
         MPI_COMM_WORLD, ierr)

!Do the matrix multiplication to calculate n columns of C
!Notice all processes do the work including MASTER
  do j = 1, nc_local
      do i = 1, nr_a
          do k = 1, nc_a
              c_local(i,j) = c_local(i,j) + a(i,k) * b_local(k,j)
          end do
      end do
  end do

!Collect the partial results to form the final matrix C on MASTER
  call MPI_GATHER(c_local, n2, MPI_REAL, c, n2, MPI_REAL, MASTER, &
         MPI_COMM_WORLD, ierr)

!Print the result as a matrix
  if (my_rank == MASTER) then
       t_finish = MPI_Wtime()
       print *, "Time elapsed for parallel computation (s) ", t_finish - t_start
      
       do i = 1, nr_a
           print *, c(i,:)
       end do
  end if

  deallocate(b_local, c_local)
  call MPI_FINALIZE(ierr)

end program mat_mul_par
  
