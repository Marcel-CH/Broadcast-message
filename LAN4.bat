for /L %%N in (1,1,254) do @nslookup 172.16.4.%%N | Find "Name" >> C:\Temp\GetComputerList\PCnames4.txt
exit
