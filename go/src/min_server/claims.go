package main

import (
	jwt "github.com/dgrijalva/jwt-go"
)

type MyCustomClaims struct {
	Msg string `json:"msg"`
	jwt.StandardClaims
}
