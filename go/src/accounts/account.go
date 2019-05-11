package main

type Account struct {
	User PostAccount `json:"user"`
}

type PostAccount struct {
	Email    string `json:"email"`
	Username string `json:"username"`
	Password string `json:"password"`
}
