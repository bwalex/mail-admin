package main

import (
	"os"
	"fmt"
	"path"
	"encoding/json"
	"net/http"
	"strconv"
)

var baseDir = ""

type CreateRequest struct {
	Uid int `json:"uid"`
	Gid int `json:"gid"`
}

func createHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		w.WriteHeader(http.StatusNotFound)
		return
	}

	var cr CreateRequest
	decoder := json.NewDecoder(r.Body)
	err := decoder.Decode(&cr)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte("request parsing failed!"))
		return
	}


	info, err := os.Stat(path.Join(baseDir, strconv.Itoa(cr.Gid)))
	if err != nil || !info.IsDir() {
		err = os.Mkdir(path.Join(baseDir, strconv.Itoa(cr.Gid)), 0750)
		if err != nil {
			w.WriteHeader(http.StatusBadRequest)
			w.Write([]byte("mkdir (gid) failed!"))
			return
		}

		err = os.Chown(path.Join(baseDir, strconv.Itoa(cr.Gid)), 0, cr.Gid)
		if err != nil {
			w.WriteHeader(http.StatusBadRequest)
			w.Write([]byte("chown (gid) failed!"))
			return
		}
	}

	err = os.Mkdir(path.Join(baseDir, strconv.Itoa(cr.Gid), strconv.Itoa(cr.Uid)), 0700)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte("mkdir (uid) failed!"))
		return
	}

	err = os.Chown(path.Join(baseDir, strconv.Itoa(cr.Gid), strconv.Itoa(cr.Uid)), cr.Uid, cr.Gid)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte("chown (uid) failed!"))
		return
	}

	w.WriteHeader(http.StatusCreated)
}

func main() {
	if len(os.Args) < 3 {
		fmt.Fprintf(os.Stderr, "usage: %s <port> <base_dir>\n", os.Args[0])
		os.Exit(1)
	}

	baseDir = os.Args[2]

	info, err := os.Stat(baseDir)
	if err != nil || !info.IsDir() {
		fmt.Fprintf(os.Stderr, "base_dir must point to an existing directory!")
		os.Exit(1)
	}

	http.HandleFunc("/create_account", createHandler)
	http.ListenAndServe(":"+os.Args[1], nil)
}
