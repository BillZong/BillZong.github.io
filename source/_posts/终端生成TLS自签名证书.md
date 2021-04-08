---
title: 终端生成TLS自签名证书
comments: true
abbrlink: e4cf1ff8
date: 2021-04-08 23:26:27
categories: 网络
tags: 网络
---

**Generating the private key:**

```
openssl genrsa -des3 -out server.key 1024
```

output:

```
Generating RSA private key, 1024 bit long modulus
.........................................................++++++
........++++++
e is 65537 (0x10001)
Enter PEM pass phrase:
Verifying password - Enter PEM pass phrase:
```

enter a passphrase for your private key.

**Generating the CSR (certificate signing request):**

```
openssl req -new -key server.key -out server.csr
```

it will request details like this:

```
Country Name (2 letter code) [GB]:
State or Province Name (full name) [Berkshire]:
Locality Name (eg, city) [Newbury]:
Organization Name (eg, company) [My Company Ltd]:
Organizational Unit Name (eg, section) []:
Common Name (eg, your name or your server's hostname) []:
Email Address []:
Please enter the following 'extra' attributes
to be sent with your certificate request
A challenge password []:
An optional company name []:
```

it's fairly straightforward, the common name is your server's hostname as it says in brackets.

**Generating the self signed certificate:**

```
openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt
```