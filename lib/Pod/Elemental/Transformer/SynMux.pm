package Pod::Elemental::Transformer::SynMux;
use Moose;
with 'Pod::Elemental::Transformer';
# ABSTRACT: apply multiple SynHi transformers to one document in one pass

use MooseX::Types;
use MooseX::Types::Moose qw(ArrayRef);

use namespace::autoclean;

has transformers => (
  is  => 'ro',
  isa => ArrayRef[ role_type('Pod::Elemental::Transformer::SynHi') ],
  required => 1,
);

sub transform_node {
  my ($self, $node) = @_;

  CHILD: for my $i (0 .. (@{ $node->children } - 1)) {
    my $para = $node->children->[ $i ];

    XFORM: for my $xform (@{ $self->transformers }) {
      next XFORM unless my $arg = $xform->synhi_params_for_para($para);
      my $new = $xform->build_html_para($arg);

      $node->children->[ $i ] = $new;
    }
  }

  return $node;
}

1;
