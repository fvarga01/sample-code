REM -------------------------------------------------------------
REM -------------------------------------------------------------
REM -------------------------------------------------------------
REM Seq write Command Line - 120 seconds,900GB file: 
diskspd.exe -o8 -t24 -b64K -c900G -d120 -h -L -si -w100 C:\ClusterStorage\vol1\diskspd_testfile.dat C:\ClusterStorage\vol3\diskspd_testfile.dat  C:\ClusterStorage\vol4\diskspd_testfile.dat >> diskspd_seqwr.out


REM Seq read Command Line - 120 seconds, 900GB file: 
diskspd.exe -o8 -t24 -b64K -c900G -d120 -h -L -si -w0 C:\ClusterStorage\vol1\diskspd_testfile.dat C:\ClusterStorage\vol3\diskspd_testfile.dat  C:\ClusterStorage\vol4\diskspd_testfile.dat >> diskspd_seqrd.out