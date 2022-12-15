# MacPhotosExporter

Exports folders and albums structure from macOS Photos app to directory tree.

# Instructions

Copy `migrate.raku` file to your `Pictures` directory.

Install [Docker](https://docs.docker.com/get-docker/).

Execute in terminal (replace `me` with your user name in path):

```
docker run --volume /Users/me/Pictures:/Pictures --interactive --tty alpine sh
```

It should log you to Alpine Linux console in Docker container. Type 4 commands there:

```
apk update
apk add rakudo zef sqlite-libs
zef install --/test DBIish
raku /Pictures/migrate.raku
```

It should print detected Folders, Albums and Photos and will create `TopLevelAlbums` directory containing them in exactly the same layout.

# Article

Migration code logic is explained [here](https://dev.to/bbkr/migrate-macos-photos-folders-and-albums-to-plain-tree-of-directories-2c1).
