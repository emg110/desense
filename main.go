package main

import (
	"io/ioutil"
	"net/http"
	"time"

	emitter "github.com/emitter-io/go"
)

func main() {
	client := connectToEmitter()
	updateLocation(client)
}

func updateLocation(e emitter.Emitter) {
	ticker := time.NewTicker(200 * time.Millisecond)
	defer ticker.Stop()
	for range ticker.C {
		location, err := getLocation()
		if err == nil {
			e.Publish("CHANNEL KEY", "desense-iss/", location)
		}
	}
}

func getLocation() ([]byte, error) {
	resp, err := http.Get("http://api.open-notify.org/iss-now.json")
	if err != nil {
		return nil, err
	}

	return ioutil.ReadAll(resp.Body)
}

func connectToEmitter() emitter.Emitter {
	client := emitter.NewClient(emitter.NewClientOptions())
	t := client.Connect()
	t.Wait()
	return client
}
