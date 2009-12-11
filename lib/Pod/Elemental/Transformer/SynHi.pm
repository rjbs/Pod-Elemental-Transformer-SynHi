package Pod::Elemental::Transformer::SynHi;
use Moose::Role;
with 'Pod::Elemental::Transformer';
# ABSTRACT: a role for transforming code into syntax highlighted HTML regions

=head1 DESCRIPTION

Pod::Elemental::Transformer::SynHi is a role to be included by transformers
that replace parts of the Pod document with C<html> regions, presumably to be
consumed by a downstream Pod-to-HTML transformer.

This role provides a C<transform_node> method.  It will call
C<synhi_params_for_para> for each paragraph under the node.  If that method
returns false, nothing happens.  If it returns a true value, that value will be
passed to the C<build_html> method, which should return HTML to be placed in an
C<html> region and used to replace the node that was found.

For example, you might provide these two methods and nothing else:

  sub synhi_params_for_para {
    my ($self, $para) = @_;

    return unless $para->isa('Pod::Elemental::Element::Pod5::Region')
           and    $para->format_name eq 'javascript' and ! $para->is_pod;

    return { content => $para->children->[0]->content };
  }

  sub build_html {
    my ($self, $arg) = @_;

    return Some::Syntax::Highlighter->javascript_to_html( $arg->{content} );
  }

Then, assuming that mythical module exists, C<=begin javascript> and C<=for
javascript> regions would be replaced with C<=begin html> regions for
downstream processing.

Some other methods exist and can be replaced.

=cut

requires 'synhi_params_for_para';
requires 'build_html';

=method build_html_para

This method sits between C<synhi_params_for_para> and C<build_html>.  It's
called with the synhi params, calls C<build_html>, and raps the resulting HTML
content in a Data paragraph in a non-pod C<html> region, which is returned.

=cut

sub build_html_para {
  my ($self, $arg) = @_;

  my $new = Pod::Elemental::Element::Pod5::Region->new({
    format_name => 'html',
    is_pod      => 0,
    content     => '',
    children    => [
      Pod::Elemental::Element::Pod5::Data->new({
        content => $self->build_html($arg),
      }),
    ],
  });

  return $new;
}

=method standard_code_block

  my $html = $xform->standard_code_block( $in_html );

Given a hunk of HTML representing the syntax highlighted code, this rips the
HTML apart and re-wraps it in a table with line numbers.  It assumes the code's
actual lines are broken by newlines or C<< <br> >> elements.

The standard code block emitted by this role is table with the class
C<code-listing>.  It will have one row with two cells; the first has class
C<line-numbers> and the second has class C<code>.  The table is used to make
it easy to copy only the code without the line numbers.

Some other minor changes are made, and these may change over time, to make the
code blocks "better" displayed.  If your needs are very specific, replace this
method.

=cut

sub standard_code_block {
  my ($self, $html) = @_;

  my @lines = split m{<br(?:\s*/)>|\n}, $html;

  # The leading nbsp below, in generating $code, is to try to get indentation
  # to appear in feed readers, which to not respect white-space:pre or the pre
  # element. The use of <br> instead of newlines is for the same reason.
  # -- rjbs, 2009-12-10
  my $nums  = join "<br />", map {; "$_:&nbsp;" } (1 .. @lines);
  my $code  = join "<br />",
              map {; s/^(\s+)/'&nbsp;' x length $1/me; $_ }
              @lines;

  # Another stupid hack: the <code> blocks below force monospace font.  It
  # can't wrap the whole table, though, because it would cause styling issues
  # in the rendered XHTML. -- rjbs, 2009-12-10
  $html = "<table class='code-listing'><tr>"
        . "<td class='line-numbers'><br /><code>$nums</code><br />&nbsp;</td>"
        . "<td class='code'><br /><code>$code</code><br />&nbsp;</td>"
        . "</table>";

  return $html;
}

sub transform_node {
  my ($self, $node) = @_;

  for my $i (0 .. (@{ $node->children } - 1)) {
    my $para = $node->children->[ $i ];

    next unless my $arg = $self->synhi_params_for_para($para);
    my $new = $self->build_html_para($arg);

    die "couldn't produce new html" unless $new;
    $node->children->[ $i ] = $new;
  }

  return $node;
}

1;
