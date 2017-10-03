/*********************************************************************
 * Filename:      hello.c
 * Author:        Prasad Maddumage <mhemantha@fsu.edu>
 * Created at:    Wed Jul  9 23:32:29 2014
 * Modified at:   Mon Oct  2 12:17:26 2017
 * Modified by:   Prasad Maddumage <mhemantha@fsu.edu>
 * Version:       $Revision: 1.1 $
 * Description:   
 ********************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "mpi.h"

int main (int argc, char* argv[])
{

    const int master = 0;
    int n_procs, my_rank, source, tag = 0, ierr, namelen;
    char message[256];
    char processor_name[MPI_MAX_PROCESSOR_NAME];
    MPI_Status status;

    //Initializing MPI 
    ierr = MPI_Init(&argc, &argv);

    ierr = MPI_Comm_rank(MPI_COMM_WORLD, &my_rank);
    ierr = MPI_Comm_size(MPI_COMM_WORLD, &n_procs);
    MPI_Get_processor_name(processor_name, &namelen);

    if (my_rank != master) {
      //Slave nodes run the following part of the code
      // Creating the message to be sent
      sprintf(message, "Hello from %s. My rank is %i!", 
	      processor_name, my_rank);
      //Send the message to the master node
      ierr = MPI_Send(message, 256, MPI_CHAR,
                master, tag, MPI_COMM_WORLD);
    }
    else {
      //Following commands are run only by master node
      //Need to receive messages sent by 1, ..., n_procs-1 processes
      for (source = 1; source < n_procs; source++) {
	  ierr = MPI_Recv(message, 256, MPI_CHAR,
		    source, tag, MPI_COMM_WORLD, &status);
	  
	  printf("%s\n", message);

      }
    }
    
    //Shut down MPI
    ierr = MPI_Finalize();
    
}
