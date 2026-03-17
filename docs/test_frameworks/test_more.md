# Test::More Integration

Testcontainers for Perl integrates with Perl's standard [Test::More](https://metacpan.org/pod/Test::More) framework. This page covers recommended patterns for managing container lifecycles in your tests.

## Per-test container with cleanup

The simplest pattern — start a container at the beginning of a test and clean up at the end:

```perl
use Test::More;
use Testcontainers qw( run );
use Testcontainers::Wait;
use Testcontainers::Module::Redis qw( redis_container );

subtest 'redis operations' => sub {
    my $redis = redis_container();

    my $redis_url = $redis->connection_string;
    like($redis_url, qr/^redis:\/\//, 'got valid Redis URL');

    # Clean up
    $redis->terminate;
};

done_testing;
```

This is ideal when a test needs its own isolated container.

## Per-test container with `setup` / `teardown`

Use `Test::More`'s subtest structure with setup and teardown for reusable container patterns:

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

subtest 'test insert' => sub {
    setup();
    my $conn = $pg->connection_string;
    like($conn, qr/^postgresql:\/\//, 'valid connection string');
    teardown();
};

subtest 'test select' => sub {
    setup();
    my $conn = $pg->connection_string;
    like($conn, qr/testdb/, 'contains database name');
    teardown();
};

done_testing;
```

Each subtest gets a fresh container, ensuring complete isolation.

## Shared container across a test file

To avoid the overhead of starting a new container for every test, share one container at the file level:

```perl
use Test::More;
use Testcontainers::Module::PostgreSQL qw( postgres_container );

my $pg;

# Setup once at the beginning
$pg = postgres_container(
    database => 'testdb',
    username => 'admin',
    password => 'secret',
);

subtest 'test insert' => sub {
    my $conn = $pg->connection_string;
    # Use shared container...
    ok(1, 'insert works');
};

subtest 'test select' => sub {
    my $conn = $pg->connection_string;
    # Use shared container...
    ok(1, 'select works');
};

# Cleanup at the end
END { $pg->terminate if $pg }

done_testing;
```

!!! warning

    When sharing containers, ensure tests don't leave state that interferes with other test methods. Consider resetting data between tests or using separate databases.

## Generic container test

Use `Testcontainers::run()` directly for images that don't have a pre-configured [module](../modules/index.md):

```perl
use Test::More;
use Testcontainers qw( run );
use Testcontainers::Wait;
use HTTP::Tiny;

subtest 'custom container' => sub {
    my $container = run('httpbin/httpbin:latest',
        exposed_ports => ['80/tcp'],
        wait_for      => Testcontainers::Wait::for_http('/uuid', port => '80/tcp'),
    );

    my $host = $container->host;
    my $port = $container->mapped_port('80/tcp');

    my $response = HTTP::Tiny->new->get("http://$host:$port/uuid");
    is($response->{status}, 200, 'HTTP 200 from httpbin');

    $container->terminate;
};

done_testing;
```

## Multiple container startup

Start multiple containers for tests that need several services:

```perl
use Test::More;
use Testcontainers::Module::PostgreSQL qw( postgres_container );
use Testcontainers::Module::Redis qw( redis_container );

subtest 'multiple services' => sub {
    my $pg = postgres_container(
        database => 'testdb',
        username => 'admin',
        password => 'secret',
    );

    my $redis = redis_container();

    like($pg->connection_string, qr/^postgresql:\/\//, 'PostgreSQL connection string valid');
    like($redis->connection_string, qr/^redis:\/\//, 'Redis connection string valid');

    $pg->terminate;
    $redis->terminate;
};

done_testing;
```

## Executing commands

Run commands inside a container and assert on the output:

```perl
use Test::More;
use Testcontainers qw( run );
use Testcontainers::Wait;

subtest 'exec command' => sub {
    my $container = run('alpine:latest',
        exposed_ports => [],
        cmd           => ['sleep', '30'],
        wait_for      => Testcontainers::Wait::for_log(''),
    );

    my $output = $container->exec(['echo', 'Hello from Alpine']);
    like($output, qr/Hello from Alpine/, 'exec output matches');

    $container->terminate;
};

done_testing;
```

## Checking container logs

Assert on log output from a container:

```perl
use Test::More;
use Testcontainers qw( run );
use Testcontainers::Wait;

subtest 'check logs' => sub {
    my $container = run('alpine:latest',
        exposed_ports => [],
        cmd           => ['sh', '-c', 'echo "Test output" && sleep 30'],
        wait_for      => Testcontainers::Wait::for_log('Test output'),
    );

    my $logs = $container->logs;
    like($logs, qr/Test output/, 'log contains expected output');

    $container->terminate;
};

done_testing;
```

## Best practices

| Practice | Recommendation |
|----------|---------------|
| **Cleanup** | Always call `$container->terminate` or use `END {}` blocks |
| **Isolation** | Prefer per-test containers unless startup cost is prohibitive |
| **Error handling** | Use `eval {}` and check `$@` for robust cleanup on failures |
| **Test::Exception** | Use `lives_ok` and `dies_ok` for testing container lifecycle |
