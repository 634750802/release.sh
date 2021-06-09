# release.sh

Manage mono-repo releases with git.

***WIP***

## Download

sh -c "$(curl https://raw.githubusercontent.com/634750802/release.sh/HEAD/download.sh)" -- <dir>

## Usages

### .release.sh

You should add a shell script to your mono-repo path, and provide several functions:

| Name                        | Params          | Details                                          |
| --------------------------- | --------------- | ------------------------------------------------ |
| verify-staging-sources      | current_version | lints or tests before staging build              |
| verify-release-sources      | current_version | lints or tests before release build              |
| build-staging-sources       | current_version | build staging outputs                            |
| build-release-sources       | current_version | build release outputs                            |
| distribute-staging-assets   | current_version | distribute releasing assets to wherever you want |
| distribute-releasing-assets | current_version | distribute releasing assets to wherever you want |
| set-releasing-version       | new_version     | update your codes to set new staging version     |
| set-staging-version         | current_version | update your codes to set release version         |

These are all commands that you need:
- `release.sh init <project-name> <initial-version>`
  initialize a staging branch
- `release.sh stage <project-name> <project-path>`
  verify build and distribute head codes, and move staging tag to head
- `release.sh release <project-name> <project-path>`
  verify build and distribute head codes, delete staging tag, add new staging version tag and add release tag
