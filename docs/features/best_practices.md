# Best practices

This page provides guidelines for writing reliable, maintainable tests with Testcontainers for Perl.

## Use random host ports

Avoid binding fixed host ports. Use `exposed_ports` to let Docker assign random available ports — this prevents port conflicts, especially in CI environments where tests may run in parallel.

```perl
# ✅ Good - Docker assigns a random host port
my $container = run('postgres:16',
    exposed_ports => ['5432/tcp'],
    env           => { POSTGRES_PASSWORD => 'password' },
);

my $port = $container->mapped_port('5432/tcp');
```

```perl
# ❌ Avoid - fixed host port can cause conflicts
# (not supported - use exposed_ports instead)
```

## Pin image versions

Always use a specific image tag. Never rely on `latest`, which can change unexpectedly and break your tests.

```perl
# ✅ Good
run('postgres:16.4', ...);

# ❌ Avoid
run('postgres:latest', ...);
```

## Use wait strategies

Configure a wait strategy so your test only proceeds after the service is fully ready. Without one, tests may fail intermittently due to race conditions.

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
```

See [Wait Strategies](wait/introduction.md) for all available strategies.

## Use pre-configured modules

When a pre-configured module exists (PostgreSQL, MySQL, Redis), prefer it over raw `run()`. Modules provide sensible defaults, correct wait strategies, and convenience methods like `connection_string()`.

```perl
use Testcontainers::Module::PostgreSQL qw( postgres_container );

# ✅ Good — uses the pre-configured module
my $pg = postgres_container(
    database => 'testdb',
    username => 'admin',
    password => 'secret',
);

my $connection_string = $pg->connection_string;
```

See [Modules](../modules/index.md) for all available modules.

## Clean up containers

Always clean up containers when tests complete. Use explicit `terminate()` or `END` blocks:

```perl
use Testcontainers qw( run );
use Testcontainers::Wait;

my $container = run('postgres:16',
    exposed_ports => ['5432/tcp'],
    env           => { POSTGRES_PASSWORD => 'password' },
    wait_for      => Testcontainers::Wait::for_log('database system is ready'),
);

# test logic...

$container->terminate;

# Or use END block for automatic cleanup:
END { $container->terminate if $container }
```

See [Garbage Collector](garbage_collector.md) for detailed cleanup patterns.

## Use eval for error handling

Use `eval` and check `$@` to ensure cleanup happens even when tests fail:

```perl
my $container;
eval {
    $container = run('postgres:16', ...);
    # test logic that might fail...
};
my $error = $@;
$container->terminate if $container;
die $error if $error;
```

## Configure logging for debugging

Use `Log::Any` to diagnose container issues:

```perl
use Log::Any::Adapter ('Stderr', log_level => 'debug');
```
