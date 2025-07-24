FROM spiceai/spiceai:latest-models AS spiceai

FROM debian:bookworm-slim

RUN apt update \
  && apt install --yes ca-certificates libssl3 curl --no-install-recommends

COPY --from=spiceai /usr/local/bin/spiced /usr/local/bin/spiced

# Create the Spicepod configuration file and copy data dependencies
COPY ../../test/spicepod.yaml /app/spicepod.yaml
COPY ../../test/data/*.parquet /app/data/

EXPOSE 8090
EXPOSE 9090
EXPOSE 50051

WORKDIR /app

# Start the Spice runtime with specified arguments
CMD ["/usr/local/bin/spiced", "--http", "0.0.0.0:8090", "--metrics", "0.0.0.0:9090", "--flight", "0.0.0.0:50051"]
