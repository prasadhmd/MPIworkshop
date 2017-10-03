//====================================================================
// Filename:      reduce.c
// Author:        Prasad Maddumage <mhemantha@fsu.edu>
// Created at:    Tue Jul  8 14:06:45 2014
// Modified at:   Wed Jul  9 09:38:00 2014
// Modified by:   Prasad Maddumage <mhemantha@fsu.edu>
// Version:       $Revision: 1.1 $
// Description:   Use MPI to do a parallel sum. Compile with -lm
//====================================================================
#include "mpi.h"
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

const int n = 100, seed = 323123, master = 0;

int main(int argc, char **argv)
{
  int my_rank, n_procs, ierr, i, ilow, ihigh, m;
  double my_sum, data_sum, data[n];

  //Initializing MPI
  MPI_Init(&argc, &argv);
  MPI_Comm_size(MPI_COMM_WORLD, &n_procs);
  MPI_Comm_rank(MPI_COMM_WORLD, &my_rank);

  //Generate some random data on master node
  if(my_rank == master) {
    srand(seed);
    for(i = 0; i < n; i++)
      {
	data[i] = (double)rand() / (double)RAND_MAX;
      }
  }
	
  //Send the data to all workers
  ierr = MPI_Bcast(data, n, MPI_DOUBLE, master, MPI_COMM_WORLD);

  //Load balancing: How many elements should one worker has to deal with?
  m = ceil((double)n / (double)n_procs);
  //What range of elements [ilow:ihigh] am I working on?
  ilow = my_rank * m;
  ihigh = (1 + my_rank) * m - 1;
  //Right hand boundary cannot exceed n-1
  if (ihigh >= n) ihigh = n - 1;

  //Do some work: Find the sum of YOUR portion of the data
  my_sum = 0.0;
  for (i = ilow; i <= ihigh; i++) my_sum += data[i];

  //Reduction among all workers and sending the result to master node
  ierr = MPI_Reduce(&my_sum, &data_sum, 1, MPI_DOUBLE, MPI_SUM, master, \
		    MPI_COMM_WORLD);
  
  //Printing parallel result and validation by master node
  if(my_rank == master) {
    my_sum = 0.0;
    for (i = 0; i < n; i++) my_sum += data[i];
    printf("Parallel result: %f, Sum of all data: %f \n", data_sum, my_sum);
  }

  ierr = MPI_Finalize();

}

