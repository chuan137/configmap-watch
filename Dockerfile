FROM gcr.io/distroless/base

COPY out/configmap-watch /configmap-watch

ENTRYPOINT ["/configmap-watch"]
