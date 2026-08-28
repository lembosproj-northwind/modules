# Northwind Terraform Modules

The Terraform blueprints the Lembos sample organisation is built from, one per
`BlueprintProvisionerType.Terraform` entry the Orchestrator seeds:

| Module | Blueprint | Version | Type |
| --- | --- | --- | --- |
| `serverless-function` | `platform/serverless-function` | 2.1.0 | Component |
| `static-site` | `platform/static-site` | 1.5.0 | Component |
| `postgres-cluster` | `platform/postgres-cluster` | 3.3.0 | Resource |
| `redis-cache` | `platform/redis-cache` | 2.0.1 | Resource |
| `kafka-topic` | `platform/kafka-topic` | 1.4.0 | Resource |
| `object-store-bucket` | `platform/object-store-bucket` | 2.2.0 | Resource |
| `search-index` | `platform/search-index` | 1.1.0 | Resource |
| `eks-cluster` | `platform/eks-cluster` | 1.0.0 | Environment |
| `aws-landing-zone` | `platform/aws-landing-zone` | 1.0.0 | Environment |
| `kubernetes-namespace` | `platform/kubernetes-namespace` | 1.3.0 | Environment |

Module versions are git tags, in the form `{module}/v{version}` — so `postgres-cluster/v3.3.0` is the
coordinate the seeded BlueprintVersion pins.

## The stage vocabulary

Every module taking a `stage` takes `dev`, `test`, `staging` or `prod`. Those are `EnvironmentStage`'s own
values, not their display names: the platform resolves `context.environment.stage` to the canonical value,
so a module validating `Production` refuses every real run with a message about a vocabulary nobody sent.

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

## The three Environment modules, and the two levels they sit at

An Environment module produces **somewhere to run** rather than something that runs, so it takes an
environment, a stamp and a stage rather than the resource contract above. There are two levels of it, and
the difference is what is shared:

- **`aws-landing-zone`** is a destination's *foundation*: network, identity, cluster, ingress. It is shared
  by every stamp resolving to the same placement — two stamps differing only in country share one, two
  differing in region do not, because a VPC and a cluster are both regional. Its outputs are the
  `environment.outputs.*` vocabulary everything else reads.
- **`kubernetes-namespace`** is what one stamp *is* on top of that: a namespace with its own quota, its own
  network policy and its own service account. It is the level that is not shared, which is what makes a
  stamp a boundary rather than a naming convention.

`kubernetes-namespace` reads its cluster from the foundation — `cluster_name`, `cluster_endpoint`,
`cluster_ca` — rather than being configured with one. A stamp sits on the landing zone its environment
resolved to, and naming a second here is how the two come to disagree about which cluster the stamp is on.

It is also the one module that **configures a provider itself**, against the rule below. The reason is that
its `kubernetes` provider cannot be configured by a root module: what it points at is a cluster that does
not exist until the foundation has run, and arrives here as an input. The `aws` provider it also uses
follows the ordinary rule.

`eks-cluster` predates `aws-landing-zone` and builds a cluster without the network and ingress around it.
It is kept because a destination that already has a VPC is a real shape, and because the sample needs an
Environment blueprint that is not the whole estate.

## Running against Floci

Modules declare required providers but **do not configure them** — the root module does, which is what
lets the same module run against Floci locally and a real account elsewhere. See
[`examples/floci`](./examples/floci) for a root configuration with the endpoint overrides.
