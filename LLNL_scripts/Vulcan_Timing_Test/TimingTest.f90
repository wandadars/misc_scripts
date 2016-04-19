PROGRAM TimingTest

! Purpose of this code is to examine the behavior of the intrinsic function
! SYSTEM_CLOCK() to learn how to properly use it.

        IMPLICIT NONE
        INCLUDE 'mpif.h'

        REAL :: TimeInit,ElapsedTime,MaxTime,SafeWriteBuffer
        INTEGER :: clock_rate, clock_max, i,dummy,Timer,safew
        INTEGER :: numtasks, rank, ierr
        
        !Initialize MPI Environment
        CALL MPI_INIT(ierr)
        CALL MPI_COMM_SIZE(MPI_COMM_WORLD,numtasks,ierr)
        CALL MPI_COMM_RANK(MPI_COMM_WORLD,rank,ierr)

        !Initialize the counter
        CALL SYSTEM_CLOCK(dummy,clock_rate,clock_max)
        TimeInit = dummy


        !Initialize Variables
        MaxTime = 43200 !12 Hours
        SafeWriteBuffer = 3600 !1 Hour before walltime
        safew = 0 !Initialize safe write variable

        IF(rank == 0) THEN

                !Open File For Output
                WRITE(*,*) 'Opening Ouput File'
                OPEN(UNIT = 15,file = 'timing_ouput.txt',status="REPLACE")

                WRITE(*,*) 'Beginning Ouput Timing Loop'

        END IF



        DO i = 1,20000
        
                CALL SLEEP(5)

                CALL SYSTEM_CLOCK(Timer,clock_rate,clock_max)
                ElapsedTime = REAL(Timer - TimeInit)/REAL(clock_rate)

                IF(rank == 0) THEN
                        
                        WRITE(*,*) 'Writing time to file.'
                        WRITE(15,*) 'Elapsed Time is: ',ElapsedTime

                        IF ( ( (MaxTime - ElapsedTime) .LE. SafeWriteBuffer  )) THEN
                                safew = 1
                        END IF


                END IF


                !Broadcast the data to all processors from the master processor
                CALL MPI_Bcast(safew, 1, MPI_INT, 0,MPI_COMM_WORLD,ierr)

                !All processors check the broadcasted variable that they recieved
                IF(safew == 1) THEN
                        EXIT
                END IF


        END DO


        !Close output file
        IF(rank == 0) THEN
                WRITE(*,*) 'Safe-Restart Completed. Quitting...'
                CLOSE(15)
        END IF

        CALL MPI_FINALIZE(ierr)

END PROGRAM TimingTest
