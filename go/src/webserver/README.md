In case you ever need to generate self-signed certificates, this will do the
trick:

```
openssl genrsa -out server.key 2048
openssl req -new -x509 -sha256 -key server.key -out server.crt -days 3650
```

The certificate generation command (the second line) will require you to enter
various metadata about your identity.
