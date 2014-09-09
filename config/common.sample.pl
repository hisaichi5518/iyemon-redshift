{
    'DBIx::Handler' => [
        'dbi:Pg:host=<host>;port=<port>;database=<database>',
        '<user>',
        '<password>',
    ],
    boostrap => {
        web => ['-p' => 50004],
    },
    time_zone => 'Asia/Tokyo',
}
