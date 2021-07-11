package main

import (
	"io/ioutil"
	"net/http"
	"time"
	"fmt"
	"github.com/algorand/go-algorand-sdk/client/algod"
	"github.com/algorand/go-algorand-sdk/client/kmd"
	emitter "github.com/emitter-io/go"

)
const algodAddress = "http://localhost:4001"
const kmdAddress = "http://localhost:4002"
const indexerAddress = "http://localhost:8980"
const algodToken = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
const kmdToken = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

func main() {
	client := connectToEmitter()
	updateLocation(client);
	algodClient, err := algod.MakeClient(algodAddress, algodToken)
	if err != nil {
		return
	}

	// Create a kmd client
	kmdClient, err := kmd.MakeClient(kmdAddress, kmdToken)
	if err != nil {
		return
	}

	fmt.Printf("algod: %T, kmd: %T\n", algodClient, kmdClient)
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
