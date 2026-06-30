## About ClamAV
- CClamAV is an open source (GPLv2) anti-virus toolkit, designed especially for e-mail scanning on mail gateways. It provides a number of utilities including a flexible and scalable multi-threaded daemon, a command line scanner and advanced tool for automatic database updates. The core of the package is an anti-virus engine available in a form of shared library.

## ClamAV Rest
- https://hub.docker.com/r/lokori/clamav-rest
- The server implementation and corresponding Dockerfile are on github: https://github.com/solita/clamav-rest This is a precompiled and packaged docker container running the server. You also need the ClamAV virus scanner for the REST endpoint.
- How to test ?
  ```
  # with malware testfile
  % curl -k -F "file=@eicar.com.txt" -F "name=eical.com.txt" https://clamav.app.pcai.sgctc.net/scan
  Everything ok : false
  
  # with normal file
  % curl -k -F "file=@test_file.txt" -F "name=test_file.txt" https://clamav.app.pcai.sgctc.net/scan
  Everything ok : true 
  ```
   
## Download Anti Malware Testfile
- https://www.eicar.org/download-anti-malware-testfile/#top
- The EICAR Anti-Virus Test File or EICAR test file is a computer file that was developed by the European Institute for Computer Antivirus Research (EICAR) and Computer Antivirus Research Organization (CARO), to test the response of computer antivirus programs.