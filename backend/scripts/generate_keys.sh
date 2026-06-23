#!/bin/bash
# Generate RS256 key pair for JWT signing
openssl genrsa -out private.pem 2048
openssl rsa -in private.pem -pubout -out public.pem
echo "Keys generated: private.pem and public.pem"
