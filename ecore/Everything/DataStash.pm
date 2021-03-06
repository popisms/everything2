package Everything::DataStash;

use Moose;
use namespace::autoclean;
use utf8;
use JSON;

has 'CONF' => (isa => 'Everything::Configuration', is => 'ro', required => 1);
has 'DB' => (isa => 'Everything::NodeBase', is => 'ro', required => 1);
has 'APP' => (isa => 'Everything::Application', is => 'ro', required => 1);

has 'interval' => (isa => 'Int', is => 'ro', required => 1, default => 300);

sub generate
{
  my ($this, $data) = @_;

  return $this->DB->stashData($this->stash_name, $data);  
}

sub current_data
{
  my ($this) = @_;
  my $current_data = $this->DB->stashData($this->stash_name);
  return {} unless UNIVERSAL::isa($current_data, "HASH");
  return $current_data;
}

sub stash_name
{
  my ($this) = @_;
  my $name = $this->meta->name;
  $name =~ s/^Everything::DataStash:://g;
  return $name;
}

sub generate_if_needed
{
  my ($this, $force) = @_;
  if($force or time() - $this->stash_last_updated > $this->interval)
  {
    $this->generate();
    $this->stash_set_updated();
    return 1;
  }

  return;
}

sub stash_node
{
  my ($this) = @_;
  $this->DB->getNode($this->stash_name, "datastash");
}

sub stash_last_updated
{
  my ($this) = @_;
  return $this->DB->getNodeParam($this->stash_node,"last_update") || 0;
}

sub stash_set_updated
{
  my ($this, $time) = @_;
  $time ||= time();
  return $this->DB->setNodeParam($this->stash_node,"last_update",$time);
}

__PACKAGE__->meta->make_immutable;
1;
