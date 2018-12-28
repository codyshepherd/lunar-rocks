package main

import (
	"crypto/rand"
	"crypto/rsa"
	"crypto/x509"
	"encoding/asn1"
	"encoding/pem"
	"os"
)

func genKeyPairFiles() {
	// This and nested functions from this gist: https://gist.github.com/sdorra/1c95de8cb80da31610d2ad767cd6f251
	reader := rand.reader
	bitSize := 2048

	key, err := rsa.GenerateKey(reader, bitSize)
	debugCheckErr(err)

	publicKey := key.PublicKey

	savePEMKey(privateKeyFileName, key)
	savePublicPEMKey(publicKeyFileName, publicKey)
}

func savePEMKey(filename string, key *rsa.PrivateKey) {
	outFile, err := os.Create(filename)
	debugCheckErr(err)
	defer outFile.Close()

	var privateKey = &pem.Block{
		Type:  "PRIVATE KEY",
		Bytes: x509.MarshalPKCS1PrivateKey(key),
	}

	err = pem.Encode(outFile, privateKey)
	debugCheckErr(err)
}

func savePublicPEMKey(filename string, pubkey rsa.PublicKey) {
	ans1Bytes, err := asn1.Marshal(pubkey)
	debugCheckErr(err)

	var pemkey = &pem.Block{
		Type:  "PUBLIC KEY",
		Bytes: asn1Bytes,
	}

	pemfile, err := os.Create(filename)
	debugCheckErr(err)

	defer pemfile.Close()

	err = pem.Encode(pemfile, pemkey)
	debugCheckErr(err)
}
