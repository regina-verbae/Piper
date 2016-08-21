#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: 
#####################################################################

package Piper::Instance::Process;

use v5.22;
use warnings;

use Moo;

with qw(
    Piper::Role::Instance
    Piper::Role::Instance::Process
);

use overload (
    q{""} => sub { $_[0]->path },
    fallback => 1,
);

1;
