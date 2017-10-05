/*********************************************************************
 * Filename:      mpi_fileW.c
 * Author:        Prasad Maddumage <mhemantha@fsu.edu>
 * Created at:    Sun Oct  1 23:52:52 2017
 * Modified at:   Wed Oct  4 16:41:03 2017
 * Modified by:   Prasad Maddumage <mhemantha@fsu.edu>
 * Version:       
 * Description:   MPI IO with explicit offsets  
 ********************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>

#define BLOCK_SIZE 1048576
#define MBYTE 1048576

int main(argc, argv)
     int argc;
     char *argv[];
{
  int my_rank, pool_size, number_of_blocks = 7, i, count;
  char *filename = "output1.bin";
  int *junk, *junk2;
  int number_of_integers, number_of_bytes;
  long long total_number_of_integers, total_number_of_bytes;
  MPI_Offset my_offset, my_current_offset;
  MPI_File fh;
  MPI_Status status;
  double start, finish, io_time, longest_io_time;
  FILE *ptr;

  MPI_Init(&argc, &argv);
  MPI_Comm_rank(MPI_COMM_WORLD, &my_rank);
  MPI_Comm_size(MPI_COMM_WORLD, &pool_size);

  number_of_integers = number_of_blocks * BLOCK_SIZE;
  number_of_bytes = sizeof(int) * number_of_integers;

  total_number_of_integers =
    (long long) pool_size * (long long) number_of_integers;
  total_number_of_bytes =
    (long long) pool_size * (long long) number_of_bytes;
  my_offset = (long long) my_rank * (long long) number_of_bytes;

  MPI_File_open(MPI_COMM_WORLD, filename, 
		MPI_MODE_CREATE | MPI_MODE_RDWR, MPI_INFO_NULL, &fh);
  MPI_File_seek(fh, my_offset, MPI_SEEK_SET);
  MPI_File_get_position(fh, &my_current_offset);

  /* generate random integers */

  junk = (int*) malloc(number_of_bytes);
  srand(28 + my_rank);
  for (i = 0; i < number_of_integers; i++) *(junk + i) = rand();
	   
      /* write the stuff out */

  start = MPI_Wtime();

  MPI_File_write(fh, junk, number_of_integers, MPI_INT, &status);

  finish = MPI_Wtime();
  io_time = finish - start;
  MPI_File_close(&fh);

  MPI_Allreduce(&io_time, &longest_io_time, 1, MPI_DOUBLE, MPI_MAX,
		MPI_COMM_WORLD);

  if (my_rank == 0) {
    printf("Parallel io_time       = %f seconds\n", longest_io_time);
    //printf("total_number_of_bytes = %lld\n", total_number_of_bytes);
    printf("transfer rate         = %f MB/s\n", 
    total_number_of_bytes / longest_io_time / MBYTE);

    ptr = fopen("master.bin","wb");  
    free(junk);
    number_of_integers = number_of_integers * pool_size;
    number_of_bytes = sizeof(int) * number_of_integers;
    junk = (int*) malloc(number_of_bytes);
    srand(28);
    for (i = 0; i < number_of_integers; i++) *(junk + i) = rand();
    start = MPI_Wtime();
    fwrite(junk, sizeof(int), number_of_integers, ptr);
    finish = MPI_Wtime();
    io_time = finish - start;
    printf("serial io_time       = %f seconds\n", io_time);
    //printf("total_number_of_bytes = %lld\n", number_of_bytes);
    printf("transfer rate         = %f MB/s\n",
    number_of_bytes / io_time / MBYTE);
    fclose(ptr);
  }
       
  MPI_Finalize();
  exit(0);
}
