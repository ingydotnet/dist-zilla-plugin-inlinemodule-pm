package Dist::Zilla::Plugin::InlineModule;
our $VERSION = '0.01';

use Moose;
extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';
with qw(Dist::Zilla::Role::AfterBuild Dist::Zilla::Role::FileGatherer);

has module => (
    isa => 'ArrayRef[Str]',
    traits => ['Array'],
    handles => { modules => 'elements' },
    required => 1,
);

# Lets us pass the 'module' option more than once:
sub mvp_multivalue_args { qw(module) }

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

    # the following will make sure that Dist::Zilla know about the written
    # files so that it can add them to the tarball.
    my $old_write_module = \&Inline::Module::write_module;
    local *Inline::Module::write_module = sub {
        my $filepath = $old_write_module->(@_);

        # need to get the dist dir off the front for dzil
        my $dzil_filepath = $filepath;
        $dzil_filepath =~ s!^[^/]*/!!;

        my $file = Dist::Zilla::File::OnDisk->new(
            name => $dzil_filepath,
        );
        $self->add_file( $file );

        return $filepath;
    };
    Inline::Module->handle_distdir;
}

1;
