package Dist::Zilla::Plugin::InlineModule;
our $VERSION = '0.01';

use XXX;

use Moose;
extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';
with 'Dist::Zilla::Role::AfterBuild';

has module => (
    isa => 'ArrayRef[Str]',
    traits => ['Array'],
    handles => { modules => 'elements' },
    required => 1,
);

has stub => (
    isa => 'ArrayRef[Str]',
    traits => ['Array'],
    handles => { stubs => 'elements' },
    required => 0,
    default => sub { [] },
);

has ilsm => (
    isa => 'ArrayRef[Str]',
    traits => ['Array'],
    handles => { ilsms => 'elements' },
    required => 0,
    default => sub { ['Inline::C'] },
);

# Lets us pass the 'module' option more than once:
sub mvp_multivalue_args { qw(module stub ilsm) }

# Add our FixMakefile call to Makefile.PL, respecting any other footer lines
# that were provided in dist.ini:
around _build_footer => sub {
    my $orig = shift;
    my $self = shift;

    return join "\n",
        "use lib 'inc'; use Inline::Module::MakeMaker;",
        'Inline::Module::MakeMaker::FixMakefile(',
        (map { "  module => '" . $_ . "'," } $self->modules),
        ');',
        '',
        $self->$orig(@_);
};

use XXX;
sub after_build {
    my ($self, $hash) = @_;
    require Inline::Module;

    my $inline_module = Inline::Module->new(
        XXX ilsm => $self->ilsm,
    );
    my $build_dir = $hash->{build_root}->stringify;
    my @inline_modules = map "${_}::Inline", $self->modules;
    my @included_modules = $inline_module->included_modules;
    Inline::Module->handle_distdir(
        $build_dir,
        @inline_modules,
        '--',
        @included_modules,
    );
}

1;
