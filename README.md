Luna HSM Client
====

This docker image contains a client for the Luna HSM and github.com/leifj/pyeleven for talking to it. By default
the image starts an instance of gunicorn on 0.0.0.0:8000 running pyeleven. You must provide PKCS11PIN via the 
environment to login to your partition. You should also mount /etc/luna/cert:/usr/safenet/lunaclient/cert to 
somewhere with "client" and "server" directories where luna client and server certs are found. The docker
image is designed to run with a hostname which is used to select the client certificate (generated unless it 
already exists).

Directory Layout
---

In the examples below, the /etc/luna/cert directory looks like this:

```bash
# tree /etc/luna/cert
/etc/luna/cert
├── client
│   ├── client.example.comKey.pem
│   └── client.example.com.pem
└── server
    ├── CAFile.pem
    └── hsm.example.comCert.pem
```

You must of course configure the HSM with a client matching the cert for client.example.com and assign
that client to at least one partition.

Examples
---

**Verify configuration**

```bash
# docker run -ti -h client.example.com -v /etc/luna/cert:/usr/safenet/lunaclient/cert docker.sunet.se/luna-client vtl verify


The following Luna SA Slots/Partitions were found: 

Slot    Serial #        Label
====    ========        =====
 1      999999999	example

```

**Start pyeleven**
```bash
# docker run -d client.example.com -p 8000:8000 -e PKCS11PIN=asecret -v /etc/luna/cert:/usr/safenet/lunaclient/cert docker.sunet.se/luna-client
[2015-12-12 00:01:29 +0000] [1] [INFO] Starting gunicorn 19.4.1
[2015-12-12 00:01:29 +0000] [1] [INFO] Listening at: http://0.0.0.0:8000 (1)
[2015-12-12 00:01:29 +0000] [1] [INFO] Using worker: sync
...

# wget -qO- http://localhost:8000/
{
  "slots": [
    1, 
    2, 
    3, 
    4
  ]
}

# wget -qO- http://localhost:8000/1
{
  "slot": {
    "firmwareVersion": "0.00", 
    "flags": [
      "CKF_TOKEN_PRESENT", 
      "CKF_REMOVABLE_DEVICE", 
      "CKF_HW_SLOT"
    ], 
    "hardwareVersion": "0.00", 
    "manufacturerID": "Unknown                         ", 
    "slotDescription": "LunaNet Slot                                                    "
  },
...
}
```

