#generate wildcard TLS cert files

#usage:
# DOMAIN=infini.cloud ./generate.sh


[ -z "$DOMAIN" ] && echo  "usage: DOMAIN=infini.cloud ./generate.sh"  && exit


(cd /root && openssl rand -writerand .rnd)

cat /etc/ssl/openssl.cnf >  infini.ext
echo "[SAN]" >> infini.ext
echo "subjectAltName=DNS:$DOMAIN,DNS:*.$DOMAIN" >> infini.ext

# Root CA
openssl genrsa -out ca.key 2048
openssl req -new -x509 -subj "/CN=$DOMAIN"    \
               -days 3650 -sha256 -key ca.key -out ca.crt

# Node Cert
openssl genrsa -out node-key-temp.pem 2048
openssl pkcs8 -inform PEM -outform PEM -in node-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out instance.key
openssl req -new -key instance.key -out node.csr  -subj "/CN=$DOMAIN"  \
    -reqexts SAN \
    -extensions SAN \
    -config infini.ext

openssl x509 -req -in node.csr -CA ca.crt -CAkey ca.key -CAcreateserial -sha256 -out instance.crt   \
    -extensions SAN \
    -extfile  infini.ext

openssl x509 -noout -text -in instance.crt | grep DNS:

# Cleanup
rm node-key-temp.pem
rm node.csr
rm ca.srl
rm infini.ext

