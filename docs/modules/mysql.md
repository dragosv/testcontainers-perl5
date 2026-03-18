# MySQL

## Introduction

The Testcontainers module for MySQL provides a pre-configured container for running a MySQL database instance in your tests. It uses the official [`mysql`](https://hub.docker.com/_/mysql) Docker image.

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
use Testcontainers::Module::MySQL qw( mysql_container );
use Test::More;

my $mysql = mysql_container(
    database => 'testdb',
    username => 'admin',
    password => 'secret',
);

my $connection_string = $mysql->connection_string;
# connection_string: "mysql://admin:secret@localhost:XXXXX/testdb"

# Or use the DBI DSN:
my $dsn = $mysql->dsn;
# dsn: "dbi:mysql:database=testdb;host=localhost;port=XXXXX"

$mysql->terminate;

done_testing;
```

<!--/codeinclude-->

## Module Reference

### `mysql_container`

The `mysql_container()` function creates and starts a MySQL instance.

#### Function signature

```perl
my $mysql = mysql_container(%opts);
```

Creates a new MySQL container with the given options. The container is pre-configured with:

- **Image**: `mysql:8.0` (by default)
- **Port**: `3306/tcp` (mapped to a random host port)
- **Default credentials**: username `test`, password `test`, database `testdb`
- **Environment**: `MYSQL_ROOT_PASSWORD` set to `"test"`

#### Container Options

| Option           | Type     | Default      | Description                           |
|------------------|----------|:------------:|---------------------------------------|
| `database`       | `String` | `"testdb"`   | Sets the `MYSQL_DATABASE` env var     |
| `username`       | `String` | `"test"`     | Sets the `MYSQL_USER` env var         |
| `password`       | `String` | `"test"`     | Sets `MYSQL_PASSWORD`                 |
| `root_password`  | `String` | `"test"`     | Sets `MYSQL_ROOT_PASSWORD`            |
| `image`          | `String` | `"mysql:8.0"`| Docker image to use                   |
| `port`           | `String` | `"3306/tcp"` | Container port                        |
| `startup_timeout`| `Int`    | `120`        | Timeout in seconds                    |
| `name`           | `String` | `undef`      | Container name                        |

#### Wait Strategy

The module uses a log-based wait strategy (applied automatically):

| Strategy | Configuration |
|----------|---------------|
| Log      | `"port: 3306  MySQL Community Server"` with 120 s timeout |

### Container Methods

The returned container object provides these methods:

| Method                | Return Type | Description                            |
|-----------------------|-------------|----------------------------------------|
| `connection_string()` | `String`    | Returns a `mysql://` connection URI    |
| `dsn()`               | `String`    | Returns a DBI-compatible DSN           |
| `host()`              | `String`    | Returns the container host             |
| `mapped_port($port)`  | `String`    | Returns the mapped host port           |
| `terminate()`         | `Void`      | Stops and removes the container        |

#### Connection string format

```
mysql://<username>:<password>@<host>:<mapped-port>/<database>
```

#### DSN format

```
dbi:mysql:database=<database>;host=<host>;port=<mapped-port>
```

## Examples

### Default configuration

```perl
my $mysql = mysql_container();
my $conn_str = $mysql->connection_string;
# "mysql://test:test@localhost:XXXXX/testdb"
```

### Pinned version

```perl
my $mysql = mysql_container(
    image    => 'mysql:8.4',
    database => 'mydb',
    username => 'user1',
    password => 'pass1',
);
```

### Using with DBI

```perl
use DBI;
use Testcontainers::Module::MySQL qw( mysql_container );

my $mysql = mysql_container(
    database => 'testdb',
    username => 'admin',
    password => 'secret',
);

my $dbh = DBI->connect(
    $mysql->dsn,
    $mysql->username,
    $mysql->password,
    { RaiseError => 1, AutoCommit => 1 }
);

# Use $dbh for database operations...

$dbh->disconnect;
$mysql->terminate;
```
