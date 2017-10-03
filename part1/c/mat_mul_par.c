/*********************************************************************
 * Filename:      mat_mul_par.c
 * Author:        Prasad Maddumage <mhemantha@fsu.edu>
 * Created at:    Tue Jul 15 13:06:17 2014
 * Modified at:   Tue Oct  3 00:25:30 2017
 * Modified by:   Prasad Maddumage <mhemantha@fsu.edu>
 * Version:       $Revision: 1.2 $
 * Description:   Parallel matrix multiplication
 ********************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "mpi.h"

//number of rows in A, B = nr_a, nr_b
//number of columns in A, B = nc_a, nc_b
const int master = 0, nc_a = 4, nr_a = 4, nr_b = 4, nc_b = 4;

int main (int argc, char* argv[])
{

    int n_procs, my_rank, source, tag = 0, ierr;
    int nr_local, n2, n_el, i, j, k;
    double t_start, t_finish;
    double a[nr_a][nc_a], b[nr_b][nc_b], c[nr_a][nc_b];
    double *a_local, *c_local;

    //Initializing MPI 
    ierr = MPI_Init(&argc, &argv);

    ierr = MPI_Comm_rank(MPI_COMM_WORLD, &my_rank);
    ierr = MPI_Comm_size(MPI_COMM_WORLD, &n_procs);

    //Initialize matrices A and B with some data (on MASTER node)
    if (my_rank == master) {
      for (i = 0; i < nr_a; i++) {
	for (j = 0; j < nc_a; j++) {
	  a[i][j] = (double)((1 + i) + (1 + j));
	}
      }
      for (i = 0; i < nr_b; i++) {
	for (j = 0; j < nc_b; j++) {
	  b[i][j] = (double)((1 + i) * (1 + j));
	}
      }
      //Start counting time
      t_start = MPI_Wtime();
    }

    //Load balancing: each process calculate same number of elements in matrix C
    //C is row major. So, let each process only calculate few rows of matrix C
    //Matrix multiplication: C(i,j) = {sum over all k} A(i,k) * B(k,j)
    //Each process needs only few rows of matrix A
    //nr_local = number of rows calculated by each process
    nr_local = ceil((double)nr_a / (double)n_procs);
    //nr_a >= n_procs must be true
    
    //A_local and C_local will hold the rows needed/calculated
    //by a SINGLE process
    a_local = (double *) calloc(nr_local * nc_a, sizeof(double));
    c_local = (double *) calloc(nr_local * nc_b, sizeof(double));
    for(i = 0; i < nr_local*nc_a; i++) {
      a_local[i] = 0.0;
    }
    for(i = 0; i < nr_local*nc_b; i++) {
      c_local[i] = 0.0;
    }

    //All processes need matrix B. Therefore, BCAST it
    n_el = nr_b * nc_b; //Total number of elements in matrix A
    ierr = MPI_Bcast(b, n_el, MPI_DOUBLE, master, MPI_COMM_WORLD);
    //Send n columns each from matrix B to ALL processes (including master)
    n2 = nr_local * nc_a; //# of elements in n number of columns
    ierr = MPI_Scatter(a, n2, MPI_DOUBLE, a_local, n2, MPI_DOUBLE, master, \
		       MPI_COMM_WORLD);
    
    for (j = 0; j < nc_b; j++) {
      for (i = 0; i < nr_local; i++) {
	for (k = 0; k < nc_a; k++) {
	  c_local[i*nr_local+j] = c_local[i*nr_local+j] + \
	    a_local[i*nr_local+k] * b[k][j];
	}
      }
    }

    //Collect the partial results to form the final matrix C on master
    ierr = MPI_Gather(c_local, n2, MPI_DOUBLE, c, n2, MPI_DOUBLE, master, \
		      MPI_COMM_WORLD);
    
    //Print the computing time and result as a matrix
    if (my_rank == master) {
      t_finish = MPI_Wtime();
      printf("Time elapsed for parallel computation (s) %f \n", \
	     t_finish - t_start);

      for(i = 0; i < nr_a; i++) {
	for(j = 0; j < nc_b; j++) {
	  printf("%i\t", c[i][j]);
	}
	printf("\n");
      }
    }

    ierr = MPI_Finalize();

}
