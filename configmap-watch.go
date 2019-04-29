package main

import (
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"sync"
	"time"

	fsnotify "github.com/fsnotify/fsnotify"
)

var debug *bool
var wait *int
var volumeDirs volumeDirsFlag

type EventPasser struct {
	lock   sync.Mutex
	reload bool
}

func main() {
	debug = flag.Bool("debug", false, "print debug info")
	wait = flag.Int("wait", 120, "seconds during which reload flag remains true")

	flag.Var(&volumeDirs, "volume-dir", "the config map volume directory to watch for updates; may be used multiple times")
	flag.Parse()

	if len(volumeDirs) < 1 {
		log.Println("Missing volume-dir")
		log.Println()
		flag.Usage()
		os.Exit(1)
	}

	watcher, err := fsnotify.NewWatcher()
	if err != nil {
		log.Fatal(err)
	}
	defer watcher.Close()

	for _, d := range volumeDirs {
		log.Printf("Watching directory: %q", d)
		err = watcher.Add(d)
		if err != nil {
			log.Fatal(err)
		}
	}

	passer := &EventPasser{}

	go func() {
		for {
			select {
			case event := <-watcher.Events:
				if event.Op&fsnotify.Create == fsnotify.Create {
					if filepath.Base(event.Name) == "..data" {
						if *debug {
							log.Println(event, filepath.Base(event.Name))
						}
						log.Println("config map updated: set reload = true")
						passer.lock.Lock()
						passer.reload = true
						passer.lock.Unlock()
						time.Sleep(120 * time.Second)
						passer.lock.Lock()
						passer.reload = false
						passer.lock.Unlock()
						log.Println("set reload = false")
					}
				}
			case err := <-watcher.Errors:
				log.Println("error:", err)
			}
		}
	}()

	http.HandleFunc("/healthz", passer.httpHandler)
	http.ListenAndServe(":8080", nil)
}

func (p *EventPasser) httpHandler(w http.ResponseWriter, r *http.Request) {
	p.lock.Lock()
	defer p.lock.Unlock()
	if *debug {
		log.Printf("http handler: reload = %v\n", p.reload)
	}
	if p.reload {
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("configmap reload"))
	} else {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("ok"))
	}
}

type volumeDirsFlag []string

func (v *volumeDirsFlag) Set(value string) error {
	*v = append(*v, value)
	return nil
}

func (v *volumeDirsFlag) String() string {
	return fmt.Sprint(*v)
}
