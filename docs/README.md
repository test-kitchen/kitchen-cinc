# kitchen-cinc Documentation

Reference documentation for every configuration option exposed by the
kitchen-cinc provisioners.

## Contents

- [Provisioners](provisioners.md) — overview of the available provisioner
  classes (`cinc_infra`, `cinc_zero`, `cinc_solo`, `cinc_apply`,
  `cinc_target`) and when to use each.
- [Installation options](installation.md) — controls how Cinc Client is
  downloaded and installed on the test instance (product, channel,
  version, download URL, omnibus options, proxies).
- [Converge options](converge.md) — controls how Cinc is invoked during
  the converge phase (run list, attributes, logging, multiple converges,
  idempotency, JSON attributes, Chef Zero host/port, etc.).
- [Cookbook resolution](cookbook-resolution.md) — Policyfile and
  Berkshelf integration, cookbook upload behavior.
- [Paths](paths.md) — sandbox layout, on-instance paths, and the path
  defaults for Cinc binaries (`cinc-client`, `cinc-solo`, `cinc-apply`).
- [Target mode](target-mode.md) — extra requirements and options for the
  `cinc_target` provisioner.

## Conventions

Every option below is documented with:

- **Type** — Ruby type accepted (`String`, `Integer`, `Boolean`,
  `Hash`, `Array`, `Symbol`).
- **Default** — value used when the option is not set in `kitchen.yml`.
  `auto` means the value is derived at runtime; `none` means `nil`.
- **Description** — what the option does and any relevant constraints.

Options marked **(advanced)** are rarely needed in normal use.
