# Running the modules against Floci

```shell
terraform init
terraform apply -var floci_endpoint=http://localhost:4566
```

`kafka-topic` is deliberately absent from this root. It speaks the Kafka protocol rather than the AWS
API, so it needs a reachable broker rather than an endpoint override — which makes it the one module
whose local story is not "point the provider somewhere else". Add it once a broker is in the app host.
