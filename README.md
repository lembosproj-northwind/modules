# Northwind Terraform Modules

The Terraform blueprints the Lembos sample organisation is built from. Seven modules, matching the seven
`BlueprintProvisionerType.Terraform` entries the Orchestrator seeds:

| Module | Blueprint | Version | Type |
| --- | --- | --- | --- |
| `serverless-function` | `platform/serverless-function` | 2.1.0 | Component |
| `static-site` | `platform/static-site` | 1.5.0 | Component |
| `postgres-cluster` | `platform/postgres-cluster` | 3.3.0 | Resource |
| `redis-cache` | `platform/redis-cache` | 2.0.1 | Resource |
| `kafka-topic` | `platform/kafka-topic` | 1.4.0 | Resource |
| `object-store-bucket` | `platform/object-store-bucket` | 2.2.0 | Resource |
| `search-index` | `platform/search-index` | 1.1.0 | Resource |

Module versions are git tags, in the form `{module}/v{version}` — so `postgres-cluster/v3.3.0` is the
coordinate the seeded BlueprintVersion pins.

## The variable contract

Every **resource** module takes the same five inputs, because Lembos passes them without knowing which
module it is calling. A `ResourceNeed` declares a type and a size class; the EnvironmentProfile maps that
to one of these modules; the provisioning workflow supplies the rest from the environment and stamp.

| Variable | From |
| --- | --- |
| `name` | the Resource's qualified name, e.g. `ordering/orders-db` |
| `size_class` | `ResourceNeed.SizeClass` — `small` / `medium` / `large` |
| `environment` | the Environment's qualified name |
| `stamp` | the Stamp the instance occupies |
| `tags` | platform-supplied labels, merged into provider tags |

**What a size class means is decided per module, in its `locals`.** That is deliberate: `small` for
Postgres is a different decision from `small` for a search index, and the developer declaring the need
should not have to know either.

Every resource module returns the same four outputs:

| Output | Meaning |
| --- | --- |
| `resource_id` | the provider's identifier, recorded as provisioning output |
| `endpoint` | where the workload connects |
| `port` | the port, where the resource has one |
| `secret_ref` | **the vault path holding the credential — never the credential** |

`secret_ref` is the contract that keeps a secret out of Terraform state and out of the Orchestrator. It is
what a chart's `resourceBindings.<handle>.secretRef` is set from.

## Running against Floci

Modules declare required providers but **do not configure them** — the root module does, which is what
lets the same module run against Floci locally and a real account elsewhere. See
[`examples/floci`](./examples/floci) for a root configuration with the endpoint overrides.
