/*********************************************************************
 * Filename:      ring.c
 * Author:        Prasad Maddumage <mhemantha@fsu.edu>
 * Created at:    Wed Jul 16 22:48:34 2014
 * Modified at:   Mon Oct  2 23:55:25 2017
 * Modified by:   Prasad Maddumage <mhemantha@fsu.edu>
 * Version:       $Revision: 1.1 $
 * Description:   Exchange data between nearest neighbors
 *                Original code, "mpi_ringtopo.c" by Blaise Barney
 *https://computing.llnl.gov/tutorials/mpi/samples/C/mpi_ringtopo.c
 ********************************************************************/
#include "mpi.h"
#include <stdio.h>

main(int argc, char *argv[])  {
  int numtasks, rank, next, prev, buf[2], tag1=1, tag2=2;
  MPI_Request reqs[4];
  MPI_Status stats[4];
  
  //Initializing MPI
  MPI_Init(&argc,&argv);
  MPI_Comm_size(MPI_COMM_WORLD, &numtasks);
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  
  //Who are my neighbors (prev and next)?
  prev = rank - 1;
  next = rank + 1;
  //Rank 0's "previous" neighbor is n-1
  if (rank == 0)  prev = numtasks - 1;
  //Rank n-1's "next" neighbor is 0
  if (rank == (numtasks - 1))  next = 0;
  
  MPI_Irecv(&buf[0], 1, MPI_INT, prev, tag1, MPI_COMM_WORLD, &reqs[0]);
  MPI_Irecv(&buf[1], 1, MPI_INT, next, tag2, MPI_COMM_WORLD, &reqs[1]);
  
  MPI_Isend(&rank, 1, MPI_INT, prev, tag2, MPI_COMM_WORLD, &reqs[2]);
  MPI_Isend(&rank, 1, MPI_INT, next, tag1, MPI_COMM_WORLD, &reqs[3]);
  
  MPI_Waitall(4, reqs, stats);
  
  printf("Data in rank %i : %i and %i \n", rank, buf[0], buf[1]);

  MPI_Finalize();
}
