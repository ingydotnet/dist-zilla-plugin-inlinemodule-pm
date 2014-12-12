package Dist::Zilla::Plugin::InlineModule;
our $VERSION = '0.01';

use XXX;

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
    isa => 'ArrayRef[Str]',
    traits => ['Array'],
    required => 0,
    default => sub { [] },
);

has ilsm => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    traits => ['Array'],
    required => 0,
    default => sub { ['Inline::C'] },
);

# Lets us pass the 'module' option more than once:
sub mvp_multivalue_args { qw(module stub ilsm) }

sub after_build {
    my ($self, $hash) = @_;
    require Inline::Module;

    my $inline_module = Inline::Module->new(
        ilsm => $self->ilsm,
    );
    my $build_dir = $hash->{build_root}->stringify;
    my @stub_modules = @{$self->stub}
    ? @{$self->stub}
    : map "${_}::Inline", @{$self->module};
    my @included_modules = $inline_module->included_modules;
    Inline::Module->handle_distdir(
        $build_dir,
        @stub_modules,
        '--',
        @included_modules,
    );
}

1;
