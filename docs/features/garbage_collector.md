# Garbage Collector

Typically, an integration test creates one or more containers. This can mean a lot of containers running by the time everything is done. We need to have a way to clean up after ourselves to keep our machines running smoothly.

Containers can be unused because:

1. The test is over and the container is not needed anymore.
2. The test failed, and we do not need that container anymore because the next build will create new ones.

## Cleanup patterns

### Using explicit terminate

The most common pattern for cleaning up containers is calling `terminate()` at the end of the test:

```perl
use Testcontainers qw( run );
use Testcontainers::Wait;

my $container = run('postgres:16',
    exposed_ports => ['5432/tcp'],
    env           => { POSTGRES_PASSWORD => 'password' },
    wait_for      => Testcontainers::Wait::for_log('database system is ready'),
);

# Test logic...

$container->terminate;
```

### Using END blocks

Use Perl's `END` block to ensure cleanup happens even if the test dies:

```perl
use Testcontainers qw( run );
use Testcontainers::Wait;

my $container;

$container = run('postgres:16',
    exposed_ports => ['5432/tcp'],
    env           => { POSTGRES_PASSWORD => 'password' },
    wait_for      => Testcontainers::Wait::for_log('database system is ready'),
);

# Test logic...

END { $container->terminate if $container }
```

!!! tip

    Use `if $container` to avoid errors when the container wasn't created successfully.

### Using eval for error handling

Use `eval` and check `$@` for robust cleanup on failures:

```perl
use Testcontainers qw( run );
use Testcontainers::Wait;

my $container;
eval {
    $container = run('postgres:16',
        exposed_ports => ['5432/tcp'],
        env           => { POSTGRES_PASSWORD => 'password' },
        wait_for      => Testcontainers::Wait::for_log('database system is ready'),
    );
    
    # Test logic that might fail...
};

my $error = $@;
$container->terminate if $container;
die $error if $error;
```

### Using Test::More subtests

Clean up containers within `subtest` blocks for isolation:

```perl
use Test::More;
use Testcontainers::Module::PostgreSQL qw( postgres_container );

subtest 'database test' => sub {
    my $pg = postgres_container(
        database => 'testdb',
        username => 'admin',
        password => 'secret',
    );
    
    # Test logic...
    ok(1, 'test passed');
    
    $pg->terminate;
};

done_testing;
```

### Using labels for CI cleanup

You can label containers and clean them up in CI scripts as a safety net:

```perl
my $container = run('postgres:16',
    exposed_ports => ['5432/tcp'],
    env           => { POSTGRES_PASSWORD => 'password' },
    labels        => {
        testcontainers         => 'true',
        'testcontainers.session' => $session_id,
    },
);
```

Then in your CI pipeline:

```bash
# Clean up any leftover test containers
docker rm -f $(docker ps -aq --filter "label=testcontainers=true") 2>/dev/null || true
```

## Resource Reaper (Ryuk)

!!! note "Not yet implemented"

    Automatic resource reaping (Ryuk) is not yet available in Testcontainers for Perl. This feature is planned for a future release.

In other Testcontainers implementations, a "resource reaper" called [Ryuk](https://github.com/testcontainers/moby-ryuk) runs as a sidecar container that automatically cleans up containers, networks, and volumes created during tests — even if the test process crashes or is killed.

When available, you will see an additional container called `ryuk` alongside all the containers that were specified in your test. It relies on container labels to determine which resources were created by the package to determine the entities that are safe to remove.

Until the resource reaper is implemented, ensure you clean up resources using one of the manual patterns described above.

!!! tip

    In CI environments, consider adding a post-build step to clean up any Docker containers with the `testcontainers` label as a safety net.
