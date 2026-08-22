# Contributing to kitchen-cinc

Thanks for your interest in improving kitchen-cinc. Bug reports, feature requests, and pull requests are all welcome.

## Reporting issues

For bugs, please include:

- the version of kitchen-cinc and Test Kitchen you are using
- which provisioner you are using (`cinc_infra`, `cinc_solo`, `cinc_apply`,
  `cinc_target`, or one of the `chef_*` aliases)
- your `kitchen.yml`
- the output of the failing command, ideally with `-l debug`

## Development setup

```shell
bundle install
```

## Running tests

```shell
bundle exec rake          # Run all tests and linting
bundle exec rake spec     # Run unit tests only
bundle exec rake lint     # Run Cookstyle linting only
```

Many style offenses can be corrected automatically:

```shell
bundle exec cookstyle -a
```

## Integration tests

The integration suites converge real instances, so they need either Vagrant or
Docker available locally.

```shell
# Vagrant
KITCHEN_YAML=kitchen.yml bundle exec kitchen test

# Docker (Dokken)
KITCHEN_YAML=kitchen.dokken.yml bundle exec kitchen test
```

Changes that affect more than one provisioner are worth running against both,
since `cinc_target` in particular takes a very different path — it converges from
the workstation rather than on the instance.

## Documentation

Every configuration option is documented under [`docs/`](docs/README.md), split
by topic: provisioners, installation, converge, cookbook resolution, paths, and
target mode.

When you add or change an option, update the matching page and follow the
conventions in [`docs/README.md`](docs/README.md): each option is documented with
its **Type**, its **Default** (`auto` for values derived at runtime, `none` for
`nil`), and a **Description**. Options that are rarely needed are marked
**(advanced)**.

## Submitting changes

1. Fork the repository.
2. Create a feature branch off `main`.
3. Make your change, adding or updating tests to cover it.
4. Make sure `bundle exec rake` passes.
5. Push the branch to your fork and open a pull request.

Please keep pull requests focused on a single change — it makes review much
faster.

## Release process

This release process applies to all Cinc Project Test Kitchen plugins, but each project may have additional requirements.

1. Perform a diff between main and the last released version. Determine whether included MRs justify a patch, minor or major version release.
2. Check out the main branch of the project being prepared for release.
3. Branch into a release-branch of the form `150_release_prep`.
4. Modify the `cinc_version.rb` file to specify the version for releasing.
5. Run `rake changelog` to regenerate the changelog.
6. `git commit` the `cinc_version.rb` and `CHANGELOG.md` changes to the branch and setup an MR for them. Allow the MR to run any automated tests and review the CHANGELOG for accuracy.
7. Merge the MR to main after review.
8. Switch your local copy to the main branch and `git pull` to pull in the release preparation changes.
9. Run `rake release` on the main branch.
10. Modify the `cinc_version.rb` file and bump the patch or minor version, and commit/push.
