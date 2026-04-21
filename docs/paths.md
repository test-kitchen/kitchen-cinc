# Paths

kitchen-cinc derives several paths automatically. Override only when
your test environment deviates from the conventional layout.

## Sandbox paths (workstation side)

These options point at directories on the workstation that the
provisioner will look at when staging the sandbox. All of them
auto-resolve to subdirectories under `kitchen_root` if unset.

| Option                              | Default subpath                    |
|-------------------------------------|------------------------------------|
| `data_path`                         | `data/`                            |
| `data_bags_path`                    | `data_bags/`                       |
| `environments_path`                 | `environments/`                    |
| `nodes_path`                        | `nodes/`                           |
| `roles_path`                        | `roles/`                           |
| `clients_path`                      | `clients/`                         |
| `encrypted_data_bag_secret_key_path`| `encrypted_data_bag_secret_key`    |
| `apply_path` (`cinc_apply` only)    | `apply/`                           |

If a path is set explicitly, the provisioner expands it relative to
`kitchen_root`.

## On-instance binary paths

These options point at executables on the test instance. The defaults
derive from `cinc_omnibus_root` (set by the installer at runtime). On
Windows the `.bat` extension is appended automatically.

### `cinc_client_path` (`cinc_infra` / `cinc_zero` / `cinc_target`)

- **Type:** String
- **Default:** `<cinc_omnibus_root>/bin/cinc-client`
- Path to the `cinc-client` binary used during converge.

### `cinc_solo_path` (`cinc_solo`)

- **Type:** String
- **Default:** `<cinc_omnibus_root>/bin/cinc-solo`
- Path to the `cinc-solo` binary used during converge.

### `cinc_apply_path` (`cinc_apply`)

- **Type:** String
- **Default:** `<cinc_omnibus_root>/bin/cinc-apply`
- Path to the `cinc-apply` binary used during converge.

### `ruby_bindir`

- **Type:** String
- **Default:** `<cinc_omnibus_root>/embedded/bin`
- Directory containing the embedded Ruby interpreter shipped with the
  Cinc package.

## Notes

- The `<cinc_omnibus_root>` value is populated at install time by
  `Mixlib::Install`. For typical Linux installs it's `/opt/cinc`; for
  Windows it's under `C:\opscode\cinc`.
- Override the binary paths if you install Cinc into a non-default
  prefix (for example, when packaging a custom omnibus build).
- `kitchen_root` is provided by Test Kitchen itself and points at the
  top of the project being tested. It is not a kitchen-cinc option.
