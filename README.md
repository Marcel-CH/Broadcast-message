# Broadcast-message
How I chose to build a PowerShell based NETSend-replacement

As I am not skilled in PowerShell (or programming) the code will look crude to you guys. But it works. Basically it's copy&Pasted code Blocks but I thought it might be interesting for a beginner like me, to see that code can look ugly and still work and how the different pieces I did find on the web could come together.

We have different Locations and the fastets way to create an complete potential List of Computers I want to reach is by running an DNS Lookup through the different Segments and create a clean Host-only list. 

My goal was to send a Message to Computer in certain LAN Segments, use scriptblock to get it to run several Computers at a time so it is somewhat fast.

I use Batch to go collect the RAW Computer-Lists of the different LAN Segments. PSEXEC needs to be present. Once the script runs it asks for Admin Credentials that will be used to send ultimately the Message.
