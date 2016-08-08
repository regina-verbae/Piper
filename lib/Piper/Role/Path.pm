#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: 
#####################################################################

package Piper::Role::Path;

use v5.22;
use warnings;

use Moo::Role;

requires 'parent';
requires 'sibling';
requires 'child';
requires 'stringify';

#children
#cwd
#rootdir
#absolute
#basename
#exists
#is_file/is_dir
#relative $rel = path("/tmp/foo/bar")->relative("/tmp"); # foo/bar
#subsumes path("foo/bar")->subsumes("foo/bar/baz"); # true
#resolve ./..?

sub exists_in {
    my ($path, $instance) = @_;
    return 0 unless $instance->can('directory');
    return exists $instance->directory->{$path} ? 1 : 0;
}

1;
