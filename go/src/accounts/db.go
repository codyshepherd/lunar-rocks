package main

import (
	//"bytes"
	"database/sql"
	"errors"
	"fmt"
	"io/ioutil"
	"reflect"
	"regexp"

	uuid "github.com/google/uuid"
	log "github.com/sirupsen/logrus"

	_ "github.com/lib/pq"
	"golang.org/x/crypto/bcrypt"
)

type Database struct {
	Db *sql.DB
}

type acctRow struct {
	id       string
	username string
	email    string
	passhash []byte
	count    int
}

func dbInit(credsFile string, dbName string, tableNames []string) *Database {
	// open the creds file and read contents
	prefix := "^PSQLUSER=.*\n"
	prefixlen := 9
	pwprefix := "PSQLPW=.*"
	pwprefixlen := 7

	f, err := ioutil.ReadFile(credsFile)
	ErrorFail(err)
	fileStr := string(f)

	// use regex to find the username & pw
	re := regexp.MustCompile(prefix)
	str := re.FindString(fileStr)
	user := string(str[prefixlen:])

	re = regexp.MustCompile(pwprefix)
	str = re.FindString(fileStr)
	pw := string(str[pwprefixlen:])

	// connect to postgres
	connStr := fmt.Sprintf("host=localhost port=5433 dbname=%s user=%s password=%s sslmode=disable",
		dbName, user, pw)
	db, err := sql.Open("postgres", connStr) // This function does jack, so we need to Ping it
	err = db.Ping()
	ErrorFail(err)
	log.Debug("DB opened")

	// Check if our DB exists
	rows, err := db.Query(`
		SELECT EXISTS(
 			SELECT datname FROM pg_catalog.pg_database WHERE lower(datname) = lower($1)
		);`, dbName)
	ErrorFail(err)

	if rows == nil {
		log.Panic(fmt.Sprintf("Database %s not found!"))
	} else {
		log.Info("Found DB ", dbName)
	}

	// Check if our schema.tables exist
	for _, table := range tableNames {
		combined := fmt.Sprintf("%s.%s", schema, table)
		query := fmt.Sprintf("SELECT * FROM %s;", combined)
		log.Debug(query)
		rows, err = db.Query(query)
		ErrorFail(err)

		if rows == nil {
			log.Panic("'registered' table does not exist!")
		} else {
			log.Debug(fmt.Sprintf("Table %s found.", table))
		}
	}
	log.Info("Connect to postgres successful")

	d := Database{Db: nil}
	log.Debug(reflect.TypeOf(db))
	d.Db = db
	return &d
}

func (d *Database) Close() {
	d.Db.Close()
}

func (d *Database) DeleteByID(id string) error {
	var column string
	for table := range tableNames {
		if table == "tokens" {
			column = "userid"
		} else {
			column = "id"
		}
		delete_query := fmt.Sprintf(`
			DELETE FROM %s.%s where %s=$1`, schema, table, column)

		_, err := d.Db.Exec(delete_query, id)
		if err != nil {
			log.Error(fmt.Sprintf("Delete from %s failed", table))
			return err
		}
	}

	return nil
}

func (d *Database) GetIdByUsername(username string) (string, error) {
	retrieve_query := fmt.Sprintf(`
		SELECT id FROM %s.registered where username=$1`, schema)

	rows, err := d.Db.Query(retrieve_query, username)
	if err != nil {
		return "", err
	}

	var id string
	nextExists := rows.Next()

	log.Debug(fmt.Sprintf("Results of query to retrieve id of user %s:", username))
	if nextExists == true {
		rows.Scan(&id)
		log.Debug(fmt.Sprintf("id: %s", id))
		return id, nil
	} else {
		log.Error("No results")
		return "", errors.New("No id found for that username")
	}
}

func (d *Database) ComparePasswordHashByUsername(username string, attempt string) (bool, error) {
	// true for match, false for mismatch
	retrieve_query := fmt.Sprintf(`
	  SELECT passHash from %s.registered where username=$1`, schema)

	rows, err := d.Db.Query(retrieve_query, username)
	if err != nil {
		return false, err
	}

	var pw []byte
	nextExists := rows.Next()

	log.Debug(fmt.Sprintf("Results of query to retrieve pw hash for user %s:", username))
	if nextExists == true {
		rows.Scan(&pw)
		log.Debug(fmt.Sprintf("retrieved hash: %s", string(pw)))
		return bcrypt.CompareHashAndPassword(pw, []byte(attempt)) == nil, nil
	} else {
		log.Error("No results")
		return false, errors.New("No pw hash found for that username")
	}
}

func (d *Database) StoreNewTokenForUser(tok *Token) error {
	log.Debug("StoreNewTokenForUser")
	store_query := fmt.Sprintf(`
		INSERT INTO %s.tokens (token, type, valid, expires, userid)
		VALUES ($1, $2, $3, $4, $5)`, schema)

	if _, err := d.Db.Exec(store_query,
		tok.TokenString,
		tok.Type,
		tok.Valid,
		tok.Expires,
		tok.ForeignKeyID,
	); err != nil {
		log.Error("Error returned by token insert query")
		return err
	}

	log.Debug("StoreNewTokenForUser successful")
	return nil
}

func (d *Database) InsertNewUser(acct *Account, hash []byte) (string, error) {
	u := uuid.New()
	insertRow := acctRow{
		id:       u.String(),
		username: acct.User.Username,
		email:    acct.User.Email,
		passhash: hash,
	}

	// Check to see if username or uuid is already in DB
	var count int
	Check_query := fmt.Sprintf(`
  SELECT COUNT(id) FROM %s.registered where id=$1 OR username=$2`,
		schema)
	exists, err := d.Db.Query(Check_query, insertRow.id, insertRow.username)
	if err != nil {
		return insertRow.id, err
	}
	nextExists := exists.Next()

	log.Debug("Results of query to determine if user already exists:")
	if nextExists == true {
		exists.Scan(&count)
		log.Debug(fmt.Sprintf("count: %d", count))
	}

	if count > 0 {
		log.Error("User or UUID already exists")
		return insertRow.id, errors.New("User or UUID already exists")
	}

	// Insert new user into DB
	query := fmt.Sprintf(`
	INSERT INTO %s.registered (id, username, email, passhash)
	VALUES ($1, $2, $3, $4)`, schema)

	if _, err = d.Db.Exec(query,
		insertRow.id,
		insertRow.username,
		insertRow.email,
		insertRow.passhash,
	); err != nil {
		return insertRow.id, err
	}

	// Check that user was in fact added successfully
	Check_query = fmt.Sprintf(`
  SELECT COUNT(id) FROM %s.registered where id=$1 OR username=$2`,
		schema)

	exists, err = d.Db.Query(Check_query, insertRow.id, insertRow.username)
	if err != nil {
		return insertRow.id, err
	}

	nextExists = exists.Next()
	exists.Scan(&count)
	if count != 1 {
		log.Error("Could not find new user after adding to DB")
	} else {
		log.Debug("User added to DB successfully")
	}

	return insertRow.id, err
}
