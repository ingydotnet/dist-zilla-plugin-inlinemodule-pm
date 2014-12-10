package Dist::Zilla::Plugin::InlineModule;
our $VERSION = '0.01';

use Moose;
extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';
with 'Dist::Zilla::Role::AfterBuild';

has module => (
    isa => 'ArrayRef[Str]',
    traits => ['Array'],
    handles => { modules => 'elements' },
    required => 1,
);

# Lets us pass the 'module' option more than once:
sub mvp_multivalue_args { qw(module) }

# Add list of modules to the postamble arguments.
around _build_WriteMakefile_args => sub {
    my $orig = shift;
    my $self = shift;

    my $make_args = $self->$orig(@_);
    $make_args->{postamble}{inline}{module} = [ $self->modules ];

    return $make_args;
};

sub after_build {
    my ($self, $hash) = @_;
    my $build_dir = $hash->{build_root}->stringify;
    my @inline_modules = map "${_}::Inline", $self->modules;
    require Inline::Module;
    local @ARGV = (
        $build_dir,
        @inline_modules,
        '--',
        'Inline',
        'Inline::denter',
        'Inline::C',
        'Inline::C::Parser::RegExp',
        'Inline::Module',
        'Inline::Module::MakeMaker',
    );
    Inline::Module->handle_distdir;
}

1;
