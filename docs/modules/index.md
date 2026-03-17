# Testcontainers for Perl modules

In this section you'll find documentation for the pre-configured container modules available in Testcontainers for Perl. Each module provides sensible defaults for a specific technology — image, ports, environment variables, and wait strategies — so you can get started with minimal configuration.

## Available modules

| Module                              | Default Image         | Default Port | Connection Method       |
|-------------------------------------|-----------------------|:------------:|-------------------------|
| [PostgreSQL](postgres.md)           | `postgres:16-alpine`  | 5432/tcp     | `connection_string()`   |
| [MySQL](mysql.md)                   | `mysql:8.0`           | 3306/tcp     | `connection_string()`   |
| [Redis](redis.md)                   | `redis:7-alpine`      | 6379/tcp     | `connection_string()`   |

## Usage pattern

All modules follow a **factory function** pattern:

1. **Call** the factory function (e.g., `postgres_container()`) with configuration options.
2. **Use** the returned container object which provides connection methods and lifecycle control.

```perl
use Testcontainers::Module::PostgreSQL qw( postgres_container );

# Create and start
my $pg = postgres_container(
    database => 'testdb',
    username => 'admin',
    password => 'secret',
);

# Use the container
my $connection_string = $pg->connection_string;
my $dsn = $pg->dsn;

# Cleanup
$pg->terminate;
```

## Image versions

Each module uses a sensible default image tag. Pass the `image` option to use a different version:

```perl
my $pg = postgres_container(
    image    => 'postgres:15-alpine',
    database => 'testdb',
);
```

!!! tip

    Always pin image versions in CI to avoid flaky tests caused by image updates.

## Creating a new module

To add a new module, follow the existing pattern in `lib/Testcontainers/Module/`:

1. Create a factory function with sensible defaults (image, port, environment variables, wait strategy).
2. Use `Testcontainers::run()` with the appropriate configuration.
3. Create an inner container class (using Moo) that wraps the running container and exposes convenience methods like `connection_string()`.
4. The factory function should return the inner container object.

```perl
package Testcontainers::Module::MyService;

use strict;
use warnings;
use Testcontainers;
use Testcontainers::Wait;
use Exporter 'import';
our @EXPORT_OK = qw( myservice_container );

use constant {
    DEFAULT_IMAGE => 'myservice:latest',
    DEFAULT_PORT  => '1234/tcp',
};

sub myservice_container {
    my (%opts) = @_;

    my $image = $opts{image} // DEFAULT_IMAGE;
    my $port  = $opts{port}  // DEFAULT_PORT;

    my $container = Testcontainers::run($image,
        exposed_ports   => [$port],
        env             => { MY_SETTING => $opts{setting} // 'default' },
        _internal_labels => { 'org.testcontainers.module' => 'myservice' },
        wait_for        => Testcontainers::Wait::for_listening_port($port),
    );

    return Testcontainers::Module::MyService::Container->new(
        _inner  => $container,
        port    => $port,
        setting => $opts{setting},
    );
}


package Testcontainers::Module::MyService::Container;

use Moo;

has _inner  => (is => 'ro', required => 1, handles => [qw(
    id image host mapped_port terminate
)]);
has port    => (is => 'ro', required => 1);
has setting => (is => 'ro');

sub connection_string {
    my ($self) = @_;
    my $host = $self->host;
    my $mapped = $self->mapped_port($self->port);
    return "myservice://$host:$mapped";
}

1;
```

See [AGENTS.md](https://github.com/dragosv/testcontainers-perl5/blob/main/AGENTS.md) for the full contribution guidelines for adding modules.
