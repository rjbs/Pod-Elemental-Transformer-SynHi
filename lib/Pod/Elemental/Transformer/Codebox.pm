package Pod::Elemental::Transformer::Codebox;
use Moose;
# ABSTRACT: convert "=begin code" regions to SynHi boxes with no colorization

=head1 DESCRIPTION

This transformer looks for regions like this:

  =begin code

    (map (stuff (lisp-has-lots-of '(,parens right))))

  =end code

...and translates them into code blocks using
L<Pod::Elemental::Transformer::SynHi>, but without actually considering the
syntax of the included code.  It just gets the code listing box treatment.

This form is also accepted, in a verbatim paragraph:

  #!code
  (map (stuff (lisp-has-lots-of '(,parens m-i-right))))

In the above example, the shebang-like line will be stripped.

B<Achtung!>  Two leading spaces are stripped from each line of the content to
be highlighted.  This behavior may change and become more configurable in the
future.

=cut

use HTML::Entities ();

has format_name => (is => 'ro', isa => 'Str', default => 'code');

sub build_html {
  my ($self, $arg) = @_;
  my $string = $arg->{content};
  my $syntax = $arg->{syntax};

  $string =~ s/^  //gms;

  return $self->standard_code_block(
    HTML::Entities::encode_entities($string)
  );
}

with 'Pod::Elemental::Transformer::SynHi';
1;
