# Release Process

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
