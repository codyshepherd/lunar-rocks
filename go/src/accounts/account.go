package main

type Account struct {
	User PostAccount `json:"user"`
}

type PostAccount struct {
	Email    string `json:"email"`
	Username string `json:"username"`
	Password string `json:"password"`
}

type ResponseAccount struct {
	User ResponseUser `json:"user"`
}

type ResponseUser struct {
	Username string `json:"username"`
	Token    string `json:"token"`
}
