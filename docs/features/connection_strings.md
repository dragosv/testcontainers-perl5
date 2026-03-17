# Connection strings

Pre-configured container [modules](../modules/index.md) provide a `connection_string()` method (or equivalent) that returns a ready-to-use connection string. This eliminates the need to manually construct connection URLs from host, port, and credentials.

## How it works

After starting a module container, call `connection_string()` on the returned container object. The connection string includes the mapped host, the random port assigned by Docker, and any configured credentials.

```perl
use Testcontainers::Module::PostgreSQL qw( postgres_container );

my $pg = postgres_container(
    database => 'mydb',
    username => 'user',
    password => 'pass',
);

my $connection_string = $pg->connection_string;
# postgresql://user:pass@localhost:55432/mydb
```

## Available connection strings

### PostgreSQL

```perl
use Testcontainers::Module::PostgreSQL qw( postgres_container );

my $pg = postgres_container(
    database => 'testdb',
    username => 'admin',
    password => 'secret',
);

my $url = $pg->connection_string;
# Format: postgresql://<username>:<password>@<host>:<port>/<database>

# Or use DSN for DBI:
my $dsn = $pg->dsn;
# Format: dbi:Pg:dbname=<database>;host=<host>;port=<port>
```

### MySQL

```perl
use Testcontainers::Module::MySQL qw( mysql_container );

my $mysql = mysql_container(
    database => 'testdb',
    username => 'admin',
    password => 'secret',
);

my $url = $mysql->connection_string;
# Format: mysql://<username>:<password>@<host>:<port>/<database>

# Or use DSN for DBI:
my $dsn = $mysql->dsn;
# Format: dbi:mysql:database=<database>;host=<host>;port=<port>
```

### Redis

```perl
use Testcontainers::Module::Redis qw( redis_container );

my $redis = redis_container();

my $url = $redis->connection_string;
# Format: redis://<host>:<port>
```

## Using connection strings in tests

```perl
use Test::More;
use Testcontainers::Module::PostgreSQL qw( postgres_container );

my $pg;

sub setup {
    $pg = postgres_container(
        database => 'testdb',
        username => 'admin',
        password => 'secret',
    );
}

sub teardown {
    $pg->terminate if $pg;
}

subtest 'test connection' => sub {
    setup();
    my $connection_string = $pg->connection_string;
    like($connection_string, qr/^postgresql:\/\//, 'valid connection string');
    teardown();
};

done_testing;
```

!!! tip

    Connection strings automatically use the correct mapped host port, so you never need to worry about port conflicts.
