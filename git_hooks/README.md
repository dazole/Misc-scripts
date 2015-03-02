# post-receive:  

A git post-receive hook I use with gitlab to push my puppet code to multiple servers in multiple datacenters, with shared storage for the git repo.

```
PuppetMasters['DC1'] = ['server1',
                          'server2',
                       ]
PuppetMasters['DC2'] = ['server3',
                          'server4',
                      ]
RemoteDir = "/some/git/repo"
```
Should be self-explanetory.  Add another Datacenter, or more servers to the defined datacenters.  

The script should loop through each datacenter, testing each server to make sure $RemoteDir exists and it can read the 
README.md.

Since we have a shared filestore (nfs), we only need to be able to connect to one of the servers in the 'cluster'.  Once it has a good server, it pushes the code to that server in the datacenter.  Then checks the next datacenter and pushes there.

ToDo:

* Get rid of "$VERBOSE = nil", but I'm unsure how.



