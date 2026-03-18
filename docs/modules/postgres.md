# PostgreSQL

## Introduction

The Testcontainers module for PostgreSQL provides a pre-configured container for running a PostgreSQL database instance in your tests. It uses the official [`postgres`](https://hub.docker.com/_/postgres) Docker image.

## Adding the dependency

Add Testcontainers to your `cpanfile`:

```perl
requires 'Testcontainers';
```

Or install directly:

```bash
cpanm --installdeps .
perl Build.PL && ./Build && ./Build install
```

## Usage example

<!--codeinclude-->

```perl
use Testcontainers::Module::PostgreSQL qw( postgres_container );
use Test::More;

my $pg = postgres_container(
    database => 'testdb',
    username => 'admin',
    password => 'secret',
);

my $connection_string = $pg->connection_string;
# connection_string: "postgresql://admin:secret@localhost:XXXXX/testdb"

# Use connection_string with your PostgreSQL driver
# Or use the DBI DSN:
my $dsn = $pg->dsn;
# dsn: "dbi:Pg:dbname=testdb;host=localhost;port=XXXXX"

$pg->terminate;

done_testing;
```

<!--/codeinclude-->

## Module Reference

### `postgres_container`

The `postgres_container()` function creates and starts a PostgreSQL instance.

#### Function signature

```perl
my $pg = postgres_container(%opts);
```

Creates a new PostgreSQL container with the given options. The container is pre-configured with:

- **Image**: `postgres:16-alpine` (by default)
- **Port**: `5432/tcp` (mapped to a random host port)
- **Default credentials**: username `test`, password `test`, database `testdb`

#### Container Options

| Option           | Type     | Default            | Description                       |
|------------------|----------|:------------------:|-----------------------------------|
| `database`       | `String` | `"testdb"`         | Sets the `POSTGRES_DB` env var    |
| `username`       | `String` | `"test"`           | Sets the `POSTGRES_USER` env var  |
| `password`       | `String` | `"test"`           | Sets the `POSTGRES_PASSWORD` env var |
| `image`          | `String` | `"postgres:16-alpine"` | Docker image to use           |
| `port`           | `String` | `"5432/tcp"`       | Container port                    |
| `startup_timeout`| `Int`    | `60`               | Timeout in seconds                |
| `name`           | `String` | `undef`            | Container name                    |

#### Wait Strategy

The module uses a log-based wait strategy (applied automatically):

| Strategy | Configuration |
|----------|---------------|
| Log      | `"database system is ready to accept connections"` (2 occurrences) with 60 s timeout |

### Container Methods

The returned container object provides these methods:

| Method                | Return Type | Description                               |
|-----------------------|-------------|-------------------------------------------|
| `connection_string()` | `String`    | Returns a `postgresql://` connection URI  |
| `dsn()`               | `String`    | Returns a DBI-compatible DSN              |
| `host()`              | `String`    | Returns the container host                |
| `mapped_port($port)`  | `String`    | Returns the mapped host port              |
| `terminate()`         | `Void`      | Stops and removes the container           |

#### Connection string format

```
postgresql://<username>:<password>@<host>:<mapped-port>/<database>
```

#### DSN format

```
dbi:Pg:dbname=<database>;host=<host>;port=<mapped-port>
```

## Examples

### Default configuration

```perl
my $pg = postgres_container();
my $conn_str = $pg->connection_string;
# "postgresql://test:test@localhost:XXXXX/testdb"
```

### Pinned version

```perl
my $pg = postgres_container(
    image    => 'postgres:15-alpine',
    database => 'mydb',
    username => 'user1',
    password => 'pass1',
);
```

### Using with DBI

```perl
use DBI;
use Testcontainers::Module::PostgreSQL qw( postgres_container );

my $pg = postgres_container(
    database => 'testdb',
    username => 'admin',
    password => 'secret',
);

my $dbh = DBI->connect(
    $pg->dsn,
    $pg->username,
    $pg->password,
    { RaiseError => 1, AutoCommit => 1 }
);

# Use $dbh for database operations...

$dbh->disconnect;
$pg->terminate;
```

### Using a custom network

```perl
use WWW::Docker;
use Testcontainers qw( run );
use Testcontainers::Wait;

my $docker = WWW::Docker->new;
my $network = $docker->networks->create(name => 'pg-net');

my $container = run('postgres:16',
    exposed_ports => ['5432/tcp'],
    env           => { POSTGRES_PASSWORD => 'postgres' },
    networks      => ['pg-net'],
    wait_for      => Testcontainers::Wait::for_listening_port('5432/tcp'),
);

my $host = $container->host;
my $port = $container->mapped_port('5432/tcp');
my $conn_str = "postgresql://postgres:postgres\@$host:$port/postgres";

$container->terminate;
```
