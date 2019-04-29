# Kubernetes ConfigMap Watch

*Inspired by [jimmidyson/configmap-reload](https://github.com/jimmidyson/configmap-reload), but combined with liveness probe*


**configmap-watch** is a simple http server that returns predefined status codes base on the states of the watched Kubernetes ConfigMaps. It can be run in a side car container along with the main container that sends liveness probe to it. The http server returns status code 200 until the watched configmap is updated. Then it returns 500 for 120 seconds, during when liveness probe signifies unhealthy. 

~~It is available as a Docker image at https://hub.docker.com/r/chuan137/configmap-watcher~~

### Usage

```
Usage of ./out/configmap-watch:
  -debug
    	print debug info
  -volume-dir value
    	the config map volume directory to watch for updates; may be used multiple times
  -wait int
    	seconds during which reload flag remains true (default 120)
```

### License

This project is [Apache Licensed](LICENSE.txt)

