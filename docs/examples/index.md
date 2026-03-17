# Examples

This page demonstrates common usage patterns for Testcontainers for Perl, from basic container management through to multi-container setups.

## Basic HTTP container

Start an NGINX container, wait for it to be ready, and make an HTTP request:

```perl
use Testcontainers qw( run );
use Testcontainers::Wait;
use HTTP::Tiny;

my $container = run('nginx:1.26-alpine',
    exposed_ports => ['80/tcp'],
    wait_for      => Testcontainers::Wait::for_http('/', port => '80/tcp'),
);

my $host = $container->host;
my $port = $container->mapped_port('80/tcp');

my $response = HTTP::Tiny->new->get("http://$host:$port/");
print "Status: $response->{status}\n";  # 200

$container->terminate;
```

## Database module

Use the pre-configured [PostgreSQL module](../modules/postgres.md) for zero-config database testing:

```perl
use Testcontainers::Module::PostgreSQL qw( postgres_container );

my $pg = postgres_container(
    database => 'myapp_test',
    username => 'admin',
    password => 'secret',
);

my $connection_string = $pg->connection_string;
# "postgresql://admin:secret@localhost:55432/myapp_test"

$pg->terminate;
```

## Combined wait strategies

Wait for multiple conditions before considering a container ready:

```perl
use Testcontainers qw( run );
use Testcontainers::Wait;

my $container = run('postgres:16',
    exposed_ports => ['5432/tcp'],
    env           => { POSTGRES_PASSWORD => 'password' },
    wait_for      => Testcontainers::Wait::for_all(
        Testcontainers::Wait::for_listening_port('5432/tcp'),
        Testcontainers::Wait::for_log('database system is ready to accept connections'),
    ),
);

# Container is guaranteed to have port 5432 listening
# AND the log message present

$container->terminate;
```

## Multi-container setup

Start multiple containers for integration testing:

```perl
use Testcontainers::Module::PostgreSQL qw( postgres_container );
use Testcontainers::Module::Redis qw( redis_container );

# Start services
my $pg = postgres_container(
    database => 'mydb',
    username => 'admin',
    password => 'secret',
);

my $redis = redis_container();

print "PostgreSQL: " . $pg->connection_string . "\n";
print "Redis: " . $redis->connection_string . "\n";

# Run your tests...

$pg->terminate;
$redis->terminate;
```

## Executing commands in a container

Run commands inside a running container:

```perl
use Testcontainers qw( run );

my $container = run('alpine:latest',
    cmd => ['sleep', '30'],
);

my $output = $container->exec(['echo', 'Hello from Alpine']);
print $output;  # "Hello from Alpine"

$container->terminate;
```

## Reading container logs

Access stdout/stderr from a running container:

```perl
use Testcontainers qw( run );

my $container = run('alpine:latest',
    cmd => ['sh', '-c', "echo 'Application started' && sleep 30"],
);

sleep 2;
my $logs = $container->logs;
print $logs;  # "Application started\n"

$container->terminate;
```

## Test::More integration

See the [Test::More Integration](../test_frameworks/test_more.md) page for complete testing patterns, including setup/teardown, shared containers, and subtest support.

```perl
use Test::More;
use Testcontainers::Module::PostgreSQL qw( postgres_container );

my $pg;

# Setup
$pg = postgres_container(
    database => 'testdb',
    username => 'admin',
    password => 'secret',
);

# Test
ok($pg->connection_string =~ /testdb/, 'connection string contains database name');

# Cleanup
$pg->terminate;

done_testing;
```
```
