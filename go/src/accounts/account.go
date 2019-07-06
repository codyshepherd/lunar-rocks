package main

// This file defines struct objects to be used by the Accounts service in
// marshaling and unmarshaling json objects

// Account is used to unmarshal the json object sent by the client on Sign Up
type Account struct {
	User PostAccount `json:"user"`
}

type PostAccount struct {
	Email    string `json:"email"`
	Username string `json:"username"`
	Password string `json:"password"`
}

// Response Account represents the data returned to the client upon successful
// Sign Up or Sign In
type ResponseAccount struct {
	User ResponseUser `json:"user"`
}

type ResponseUser struct {
	Username string `json:"username"`
	Token    string `json:"token"`
}

// SignInAccount is used to unmarshal the json sent by the client during a
// Sign In attempt
type SignInAccount struct {
	User Login `json:"user"`
}

type Login struct {
	Password string `json:"password"`
	Username string `json:"username"`
}
