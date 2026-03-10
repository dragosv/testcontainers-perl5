requires 'perl', '5.042';

# Core dependencies
requires 'Moo', '2.005';
requires 'namespace::clean', '0.27';
requires 'Log::Any', '1.710';
requires 'WWW::Docker', '0.100';
requires 'Time::HiRes';
requires 'IO::Socket::INET';
requires 'Carp';
requires 'Exporter';

# Optional but recommended
recommends 'HTTP::Tiny', '0.076';
recommends 'JSON::MaybeXS', '1.004';

# Test dependencies
on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Exception', '0.43';
};

# Development dependencies
on 'develop' => sub {
    requires 'Dist::Zilla';
    requires 'Dist::Zilla::Plugin::MetaProvides::Package';
};
