#include <stdio.h>

#include "mpi.h"


#define SAME_TAG 1

int main(int argc, char **argv)

{
  int rank, size, namelen, one, two, buf1, buf2, sum1, sum2;
  char processor_name[MPI_MAX_PROCESSOR_NAME];

  MPI_Comm comm_two;
  MPI_Request request[4];
  MPI_Status stati[4];
  MPI_Init(&argc, &argv);
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  MPI_Comm_size(MPI_COMM_WORLD, &size);
  MPI_Get_processor_name(processor_name, &namelen);

  printf("Hello world! I’m rank %d of %d on %s\n", rank, size, processor_name);

  MPI_Comm_dup(MPI_COMM_WORLD, &comm_two);

  one = rank + 1;
  two = (rank + 1) * 2;
  /* Two non-blocking receives of the same type from the same source with
   * the same tag, but for two different contexts. */
  MPI_Irecv(&buf1, 1, MPI_INT, (rank == (size - 1) ? 0 : rank + 1), 
	    SAME_TAG, MPI_COMM_WORLD, &request[0]);
  MPI_Irecv(&buf2, 1, MPI_INT, (rank == (size - 1) ? 0 : rank + 1),
	    SAME_TAG, comm_two, &request[1]);
  MPI_Isend(&two, 1, MPI_INT, (rank == 0 ? (size - 1) : rank - 1),
	    SAME_TAG, comm_two, &request[2]);
  MPI_Isend(&one, 1, MPI_INT, (rank == 0 ? (size - 1) : rank - 1),
	    SAME_TAG, MPI_COMM_WORLD, &request[3]);

  /* Collective communication mixed with point-to-point communication.
   * MPI guarantees that a single communicator can do safe point-to-point
   * and collective communication. */
  MPI_Allreduce(&one, &sum1, 1, MPI_INT, MPI_SUM, MPI_COMM_WORLD);
  MPI_Allreduce(&two, &sum2, 1, MPI_INT, MPI_SUM, comm_two);
  MPI_Waitall(4, request, stati);

  printf("%d: Received buf1=%d and buf2=%d, sum1=%d and sum2=%d\n", rank,
	 buf1, buf2, sum1, sum2);

  MPI_Comm_free(&comm_two);
  MPI_Finalize();
}
