package Everything::APIRouter;

use diagnostics;
use Moose;
use namespace::autoclean;
use JSON;
use Everything;
use Everything::Request;
use Data::Dumper;
use Everything::API;

has 'MODULE_TABLE' => (isa => "HashRef", is => "ro", builder => "build_module_table");

with 'Everything::HTTP';

sub build_module_table
{
  my $args = {"DB" => $Everything::DB, "APP" => $Everything::APP, "CONF" => $Everything::CONF};
  my $routes;
  foreach my $path (@INC)
  {
    if(-d "$path/Everything/API/")
    {
       my $dirhandle;
       opendir($dirhandle,"$path/Everything/API/");
       foreach my $module(readdir($dirhandle))
       {
         my $fullmodule = "$path/Everything/API/$module";
         next unless -e $fullmodule and -f $fullmodule;
         my ($apiname) = $module =~ /^([^\.]+)/;
         eval("use Everything::API::$apiname");
         $routes->{$apiname} = "Everything::API::$apiname"->new($args);
       }
       last;
    }
  }

  $routes->{catchall} = Everything::API->new($args);
  return $routes;
}


sub dispatcher
{
  my ($self) = @_;
  my $REQUEST = Everything::Request->new("DB" => $Everything::DB, "APP" => $Everything::APP, "CONF" => $Everything::CONF);
  my $urlform = $REQUEST->url(-absolute=>1);
  my $method = lc($REQUEST->request_method());

  if(!grep($method,"get","put","post","delete","patch"))
  {
    return $self->output($REQUEST, [$self->HTTP_METHOD_NOT_ALLOWED]); 
  }

  if(my ($endpoint, $extra) = $urlform =~ m|^/api/([^/]+)/?(.*)|)
  {
    if(exists $self->MODULE_TABLE->{$endpoint})
    {
      $self->output($REQUEST, $self->MODULE_TABLE->{$endpoint}->route($REQUEST, $extra));
    }else{
      $self->output($REQUEST, $self->MODULE_TABLE->{catchall}->$method($REQUEST));
    }
  }else{
    $self->output($REQUEST, [$self->HTTP_OK, [$urlform,$endpoint,$extra]]);
    #$self->MODULE_TABLE->{catchall}->$method($REQUEST));
  }
}

sub output
{
  my ($self, $REQUEST, $output) = @_;

  my $response_code = $output->[0];
  my $data = $output->[1];
  my $additional_headers = $output->[2];

  print $REQUEST->header(-status => $response_code);
  if($data)
  {
    print $REQUEST->header("application/json");
    print JSON::to_json($data); 
  }
}

__PACKAGE__->meta->make_immutable;
1;
