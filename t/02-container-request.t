use strict;
use warnings;
use Test::More;

use Testcontainers::ContainerRequest;

# Test container request creation
subtest 'basic request' => sub {
    my $req = Testcontainers::ContainerRequest->new(
        image         => 'nginx:alpine',
        exposed_ports => ['80/tcp'],
    );
    is($req->image, 'nginx:alpine', 'image set');
    is_deeply($req->exposed_ports, ['80/tcp'], 'exposed_ports set');
    is($req->startup_timeout, 60, 'default startup_timeout');
    is_deeply($req->env, {}, 'default empty env');
    is_deeply($req->cmd, [], 'default empty cmd');
};

subtest 'request with all options' => sub {
    my $req = Testcontainers::ContainerRequest->new(
        image           => 'postgres:16-alpine',
        exposed_ports   => ['5432/tcp'],
        env             => { POSTGRES_PASSWORD => 'test' },
        labels          => { app => 'mytest' },
        cmd             => ['-c', 'max_connections=100'],
        name            => 'test-pg',
        startup_timeout => 120,
        privileged      => 1,
        tmpfs           => { '/tmp' => 'rw' },
        network_mode    => 'bridge',
    );

    is($req->image, 'postgres:16-alpine', 'image');
    is_deeply($req->env, { POSTGRES_PASSWORD => 'test' }, 'env');
    is_deeply($req->labels, { app => 'mytest' }, 'labels');
    is($req->name, 'test-pg', 'name');
    is($req->startup_timeout, 120, 'startup_timeout');
    is($req->privileged, 1, 'privileged');
};

subtest 'to_docker_config' => sub {
    my $req = Testcontainers::ContainerRequest->new(
        image         => 'nginx:alpine',
        exposed_ports => ['80/tcp', '443/tcp'],
        env           => { FOO => 'bar', BAZ => 'qux' },
        labels        => { custom => 'label' },
        cmd           => ['nginx', '-g', 'daemon off;'],
    );

    my $config = $req->to_docker_config;

    is($config->{Image}, 'nginx:alpine', 'docker config image');
    ok(exists $config->{ExposedPorts}{'80/tcp'}, 'port 80 exposed');
    ok(exists $config->{ExposedPorts}{'443/tcp'}, 'port 443 exposed');

    # Env should be sorted key=value format
    is_deeply($config->{Env}, ['BAZ=qux', 'FOO=bar'], 'env in sorted key=value format');

    # Labels should include testcontainers labels
    is($config->{Labels}{custom}, 'label', 'custom label');
    is($config->{Labels}{'org.testcontainers'}, 'true', 'testcontainers label');
    is($config->{Labels}{'org.testcontainers.lang'}, 'perl', 'lang label');

    is_deeply($config->{Cmd}, ['nginx', '-g', 'daemon off;'], 'cmd');

    # HostConfig port bindings
    ok(exists $config->{HostConfig}{PortBindings}{'80/tcp'}, 'port binding 80');
    ok(exists $config->{HostConfig}{PortBindings}{'443/tcp'}, 'port binding 443');
};

subtest 'port normalization' => sub {
    my $req = Testcontainers::ContainerRequest->new(
        image         => 'nginx:alpine',
        exposed_ports => ['80'],  # without protocol
    );

    my $config = $req->to_docker_config;
    ok(exists $config->{ExposedPorts}{'80/tcp'}, 'bare port normalized to /tcp');
};

subtest 'tmpfs config' => sub {
    my $req = Testcontainers::ContainerRequest->new(
        image => 'nginx:alpine',
        tmpfs => { '/tmp' => 'rw', '/run' => 'rw,size=100m' },
    );

    my $config = $req->to_docker_config;
    is_deeply($config->{HostConfig}{Tmpfs}, { '/tmp' => 'rw', '/run' => 'rw,size=100m' }, 'tmpfs');
};

done_testing;
