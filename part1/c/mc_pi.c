/*********************************************************************
 * Filename:      mc_pi.c
 * Author:        Prasad Maddumage <mhemantha@fsu.edu>
 * Created at:    Thu Jul 24 09:32:34 2014
 * Modified at:   Thu Jul 24 09:37:25 2014
 * Modified by:   Prasad Maddumage <mhemantha@fsu.edu>
 * Version:       $Revision: 1.1 $
 * Description:   Estimate value of PI using Monti Carlo method
 ********************************************************************/
#include "mpi.h"
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

const int seed = 323123, count = 100000, master = 0;

int main(int argc, char **argv)
{
  int my_rank, n_procs, ierr, i, my_count, tot_count, my_circle, tot_circle;
  double harvest, x, x2, y, y2, r2, pi, pi_mc;
  //I need double NOT float. MPI_FLOAT in C is less "precise"!

  //Initializing MPI
  MPI_Init(&argc, &argv);
  MPI_Comm_size(MPI_COMM_WORLD, &n_procs);
  MPI_Comm_rank(MPI_COMM_WORLD, &my_rank);

  //We take ceiling (round it up, not down) so that only one process waits
  // for everyone else not everyone else wait for one process to finish
  my_count = ceil((double)(count) / (double)(n_procs));
  
  //Finding a GOOD random number generator is very important for Monte Carlo
  // methods. Here, we use the simple built in random_number()
  //Each process needs a unique seed so that everyone have different random
  // number sequences
  srand(seed + my_rank + 1);
  
  my_circle = 0;
  for (i = 0; i < my_count; i++) {
    //Randomly find a point (x,y) where -1<=x<1, -1<=y<1
    harvest = (double)rand() / (double)RAND_MAX;
    x = 2.0 * harvest - 1.0;
    x2 = x * x;
    harvest = (double)rand() / (double)RAND_MAX;
    y = 2.0 * harvest - 1.0;
    y2 = y * y;
    //Calculate the distance to this point from origin (0,0)
    r2 = x2 + y2;
    //If r^2 <= 1, the point is inside the circle of radius 1
    if (r2 <= 1.0) my_circle = my_circle + 1;
  }

  //Send partial results to master node
  ierr = MPI_Reduce(&my_count, &tot_count, 1, MPI_INT, MPI_SUM, master, \
		    MPI_COMM_WORLD);
  ierr = MPI_Reduce(&my_circle, &tot_circle, 1, MPI_INT, MPI_SUM, master, \
		    MPI_COMM_WORLD);
  
  //Calculate the final result in the master node
  if (my_rank == master) {
    pi_mc = 4.0 * tot_circle / tot_count;
    //For comparison, we need the actual value of PI
    pi = 4.0 * atan(1.0);
    printf("Estimated value of PI using Monte Carlo method: %f \n", pi_mc);
    printf("Percentage Error: %f %%", 100.0 * fabs(pi - pi_mc)/pi);
  }

  ierr = MPI_Finalize();

}
