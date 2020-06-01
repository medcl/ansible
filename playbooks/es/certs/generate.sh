#generate CA
openssl genrsa -out ca.key 2048
openssl req -new -x509 -subj '/CN=INFINI' -days 365 -key ca.key -out ca.crt
openssl req -x509 -nodes -subj '/CN=INFINI' -days 365 \
        -newkey rsa:4096 -sha256 -keyout instance.key -out instance.crt