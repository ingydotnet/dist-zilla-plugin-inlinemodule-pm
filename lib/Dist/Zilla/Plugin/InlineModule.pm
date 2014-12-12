package Dist::Zilla::Plugin::InlineModule;
our $VERSION = '0.01';

use Moose;
extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';
with 'Dist::Zilla::Role::AfterBuild';

has module => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    traits => ['Array'],
    required => 1,
);

has stub => (
    is => 'ro',
    lazy => 1,
    builder => '_build_stub',
    isa => 'ArrayRef[Str]',
    traits => ['Array'],
    required => 0,
);

has ilsm => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    traits => ['Array'],
    required => 0,
    default => sub { ['Inline::C'] },
);

sub _build_stub {
    my ($self) = @_;
    return [ map "${_}::Inline", @{$self->module} ];
}

# Lets us pass the 'module' option more than once:
sub mvp_multivalue_args { qw(module stub ilsm) }

# Add list of modules to the postamble arguments.
around _build_WriteMakefile_args => sub {
    my $orig = shift;
    my $self = shift;

    my $make_args = $self->$orig(@_);
    $make_args->{postamble}{inline} = {
        module => $self->module,
        stub => $self->stub,
        ilsm => $self->ilsm,
    };

    return $make_args;
};

sub after_build {
    my ($self, $hash) = @_;
    require Inline::Module;

    Inline::Module->handle_distdir(
        $hash->{build_root}->stringify,
        @{$self->stub},
        '--',
        Inline::Module->new(ilsm => $self->ilsm)->included_modules,
    );
}

1;
