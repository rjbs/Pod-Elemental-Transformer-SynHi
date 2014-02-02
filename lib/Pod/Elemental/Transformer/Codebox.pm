use v5.10.0;
package Pod::Elemental::Transformer::Codebox;
# ABSTRACT: convert "=begin code" regions to SynHi boxes with no colorization

use Moose;
with 'Pod::Elemental::Transformer::SynHi';

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

=head1 SEE ALSO

=for :list
* L<Pod::Elemental::Transformer::SynHi>

=cut

use HTML::Entities ();

has '+format_name' => (default => 'code');

sub build_html {
  my ($self, $str, $param) = @_;

  return HTML::Entities::encode_entities($str);
}

1;
