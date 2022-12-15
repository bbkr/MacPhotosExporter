use DBIish;

my $handle = DBIish.connect( 'SQLite', database => '/Pictures/Photos Library.photoslibrary/database/photos.db' );

class Picture {
    has $.id;
    has $.name;
    has $.path;

    method new ( :$id ) {

        state $query = $handle.prepare('
            SELECT modelId AS id, originalFileName AS name, imagePath AS path
            FROM RKMaster
            WHERE modelId = ?
        ');

        return self.bless( |$query.execute( $id ).allrows( :array-of-hash )[ 0 ] );
    }

}

class Album {
    has $.id;
    has $.name;

    method new ( :$id ) {

        state $query = $handle.prepare('
            SELECT modelId AS id, name
            FROM RKAlbum
            WHERE modelId = ?
        ');

        return self.bless( |$query.execute( $id ).allrows( :array-of-hash )[ 0 ] );
    }

    method pictures {

        state $query = $handle.prepare('
            SELECT RKVersion.masterId AS id
            FROM RKAlbumVersion, RKVersion
            WHERE RKAlbumVersion.versionId = RKVersion.modelId
                AND RKAlbumVersion.albumId = ?
        ');

        return $query.execute( $.id ).allrows( :array-of-hash ).map: { Picture.new( |$_ ) };
    }

}

class Folder {
    has $.uuid;
    has $.name;

    method new ( :$uuid ) {

        state $query = $handle.prepare('
            SELECT uuid, name
            FROM RKFolder
            WHERE uuid = ?
        ');

        return self.bless( |$query.execute( $uuid ).allrows( :array-of-hash )[ 0 ] );
    }

    method subfolders {

        state $query = $handle.prepare('
            SELECT uuid
            FROM RKFolder
            WHERE parentFolderUuid = ?
            ORDER BY name
        ');

        return $query.execute( $.uuid ).allrows( :array-of-hash ).map: { Folder.new( |$_ ) }
    }

    method albums {

        state $query = $handle.prepare('
            SELECT modelId AS id
            FROM RKAlbum
            WHERE folderUuid = ?
            ORDER BY name
        ');

        return $query.execute( $.uuid ).allrows( :array-of-hash ).map: { Album.new( |$_ ) };
    }

}

my $seen = 0;
sub traverse ( $current-folder, *@parent-folders ) {

    my $indent = '  ' x @parent-folders.elems;
    say $indent, '/' ,$current-folder.name;

    for $current-folder.albums.eager -> $album {
        say $indent, ' *' , $album.name;

        my $destination-path = IO::Path.new( '/Pictures/' );
        $destination-path .= add( .name ) for @parent-folders;
        $destination-path .= add( $current-folder.name );
        $destination-path .= add( $_ ) with $album.name;
        $destination-path.mkdir();

        for $album.pictures.eager -> $picture {
            say $indent, '  -' , $picture.name;

            my $source-file = IO::Path.new( '/Pictures/Photos Library.photoslibrary/Masters/' );
            $source-file .= add( $picture.path.lc );
            die $source-file unless $source-file.e;
            try {
                $source-file.copy( $destination-path.add( $source-file.basename ), :createonly );
            }
            $source-file.copy( $destination-path.add( $picture.id ~ '.' ~ $source-file.extension ), :createonly ) if $!;
            $seen++;
        }
    }

    for $current-folder.subfolders.eager -> $subfolder {
        samewith( $subfolder, @parent-folders, $current-folder );
    }
}

traverse( Folder.new( uuid => 'TopLevelAlbums' ) );

say $seen;
