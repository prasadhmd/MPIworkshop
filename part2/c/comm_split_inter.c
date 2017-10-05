#include <stdio.h>

#include "mpi.h"


int main(int argc, char **argv)

{
  int rank[2], size[2], namelen, color;
  char processor_name[MPI_MAX_PROCESSOR_NAME];
  const char *cname[] = { "BLACK", "WHITE", "BLUE" };
  int i, buf, val;

  MPI_Comm comm_work, intercomm;
  MPI_Status status;

  MPI_Init(&argc, &argv);
  MPI_Comm_rank(MPI_COMM_WORLD, &rank[0]);
  MPI_Comm_size(MPI_COMM_WORLD, &size[0]);
  MPI_Get_processor_name(processor_name, &namelen);

  printf("Hello world! I’m  rank %d of %d on %s\n", rank[0],
	 size[0], processor_name);

  color = rank[0]%3;
  MPI_Comm_split(MPI_COMM_WORLD, color, rank[0], &comm_work);
  MPI_Comm_rank(comm_work, &rank[1]);
  MPI_Comm_size(comm_work, &size[1]);

  printf("%d: I’m  rank %d of %d in the %s context\n",
	 rank[0], rank[1], size[1], cname[color]);

  val = rank[1];
  if (rank[1] != 0) {
    /* Have every local worker send its value to its local leader */
    MPI_Send(&val, 1, MPI_INT, 0, 0, comm_work);
  }
  else {
    /* Every local leader receives values from its workers */
    for (i = 1; i < size[1]; i++) {
      MPI_Recv(&buf, 1, MPI_INT, i, 0, comm_work, &status);
      val += buf;
    }
    printf("%d: Local %s leader sum = %d\n", rank[0],
	   cname[color], val);
  }
  /* Establish an intercommunicator for message passing between the BLACK
     WHITE groups */
  if (color < 2) {
    if (color == 0) {
      /* BLACK Group: create intercommunicator and send to
       * corresponding member in WHITE group */
      MPI_Intercomm_create(comm_work, 0, MPI_COMM_WORLD, 1,
			   99, &intercomm);
      MPI_Send(&val, 1, MPI_INT, rank[1], 0, intercomm);
      printf("%d: %s member; sent value = %d\n", rank[0],
	     cname[color], val);
    }
    else {
      /* WHITE Group: create intercommunicator and receive
       * from corresponding member in BLACK group */
      MPI_Intercomm_create(comm_work, 0, MPI_COMM_WORLD, 0,
			   99, &intercomm);
      MPI_Recv(&buf, 1, MPI_INT, rank[1], 0, intercomm,
	       &status);
      printf("%d: %s member; received value = %d\n", rank[0],
	     cname[color], buf);
    }
    MPI_Comm_free(&intercomm);
  }

  MPI_Comm_free(&comm_work);
  MPI_Finalize();
}
