#!/usr/bin/perl

use strict;
use lib qw(/usr/local/everything);
use Everything;
initEverything 'everything';
use Everything::HTML;
use Data::Dumper;

foreach my $current_type (qw(htmlcode superdoc container htmlpage)){

	my $nodetype = getNode($current_type,'nodetype');
	
	my $dbh = $DB->getDatabaseHandle();
	my $csr = $dbh->prepare('SELECT node_id FROM node where type_nodetype='.$nodetype->{node_id});
	$csr->execute();

	`mkdir -p lib/Everything/Compiled`;
my $handle;
open $handle, ">lib/Everything/Compiled/$current_type.pm";
print $handle <<"HEADING1";
#!/usr/bin/perl -w
use strict;
use Everything;
use Everything::HTML;
use Everything::Experience;
use Everything::MAIL;
use Everything::Search;
use Everything::Room;


package Everything::Compiled::$current_type;
# This file was automatically generated by e2compile.pl

HEADING1

if($current_type eq "htmlpage")
{
	print $handle "use Everything::Compiled::container;\n";
}

print $handle q|
BEGIN
{
	foreach my $sub qw(getRandomNode handle_errors query_vars_string tagApprove htmlScreen cleanupHTML tableWellFormed debugTag debugTable screenTable buildTable breakTags unMSify encodeHTML decodeHTML htmlFormatErr htmlErrorUsers htmlErrorGods jsWindow urlGen getCode getPages getPageForType getPage rewriteCleanEscape urlGenNoParams linkNode linkNodeTitle nodeName evalCode htmlcode embedCode parseCode stripCode listCode quote insertNodelet updateNodelet genContainer containHtml displayPage gotoNode confirmUser parseLinks urlDecode loginUser getCGI getTheme printHeader handleUserRequest cleanNodeName clearGlobals opNuke opLogin opLogout opNew getOpCode execOpCode isSuspended mod_perlInit mod_perlpsuedoInit escapeAngleBrackets isSpider findIsSpider showPartialDiff showCompleteDiff generate_test_cookie assign_test_condition check_test_substitutions recordUserAction processVarsSet)
	{
		eval("\$Everything::Compiled::|.$current_type.q|::{$sub} = *Everything::HTML::$sub;");
	}

|;

my $var_mapping = 
{
	'$NODE' => '::HTML::GNODE',
	'$dbh' => '::',
	'$USER' => '::HTML::',
	'$GNODE' => '::HTML::',
	'%HTMLVARS' => '::HTML::',
	'$DB' => '::',
	'$VARS' => '::HTML::',
	'$query' => '::HTML::',
	'$HTTP_ERROR_CODE' => '::HTML::',
	'$ERROR_HTML' => '::HTML::',
	'$SITE_UNAVAILABLE' => '::HTML::',
	'$IS_SPIDER' => '::HTML::',
	'$TEST' => '::HTML::',
	'$TEST_CONDITION' => '::HTML::',
	'$TEST_SESSION_ID' => '::HTML::',
	'$THEME' => '::HTML::',
	'$NODELET' => '::HTML::',
	'%HEADER_PARAMS' => '::HTML::',	
};

print $handle "use vars qw(".join(" ",keys %$var_mapping).");\n";

foreach my $var (keys %$var_mapping)
{
	my $rawname = $var;
	$rawname =~ s/^[\$\%]//g;
	my $mapping = $var_mapping->{$var};
	if($mapping =~ /::$/)
	{
		$mapping .= $rawname;
	}

	print $handle '*Everything::Compiled::'.$current_type.'::'.$rawname.' = *Everything'.$mapping.";\n";
}

print $handle q|foreach my $sub qw(getRef getId getTables getNode getNodeById getType getNodeWhere selectNodeWhere selectNode nukeNode insertNode updateNode updateLockedNode replaceNode transactionWrap initEverything removeFromNodegroup replaceNodegroup insertIntoNodegroup canCreateNode canDeleteNode canUpdateNode canReadNode updateLinks updateHits getVars setVars selectLinks isGroup isNodetype isGod lockNode unlockNode getCompiledCode clearCompiledCode dumpCallStack getCallStack printErr printLog)
	{
		eval("\$Everything::Compiled::|.$current_type.q|::{$sub} = *Everything::$sub;");
	}
}|;
	my $shortcuts;

	my $relevant_field = 
	{
		"superdoc" => "doctext",
		"htmlpage" => "page",
		"container" => "context",
	};

	while(my $row = $csr->fetchrow_hashref())
	{
		my $current_object = getNodeById($row->{'node_id'});
		next if $current_object->{node_id} == 401321 or $current_object->{node_id} == 1988386;
		
		my $title = $current_object->{title};
		my $escapedtitle = $current_object->{title};
		$escapedtitle =~ s/[^A-Za-z0-9]/_/g;
		$title = "__$current_type"."_$escapedtitle";
		print $handle "\n\n";
		print $handle "# ".$current_object->{title}." (node_id: ".$current_object->{node_id}.")\n";
		print $handle "sub ".$title."\n";
		print $handle "{\n";
		print $handle "\n\n";

		if($current_type eq "htmlcode")
		{
			print $handle " # Begin code from DB\n";
			print $handle $current_object->{code}."\n";
		}elsif($current_type eq "container")
		{
			$shortcuts->{"_id_".$current_object->{node_id}} = $escapedtitle;
			print $handle subifycode($current_object->{context}, $escapedtitle, $current_type, $current_object->{node_id});
		}elsif($current_type eq "htmlpage")
		{
			$shortcuts->{"_id_".$current_object->{node_id}} = $escapedtitle;
			#$prefix,$themer,$typeid,$thisdisplay
			$shortcuts->{join("_","",$current_object->{ownedby_theme},$current_object->{pagetype_nodetype},$current_object->{displaytype})} = $escapedtitle;
			print $handle subifycode($current_object->{$relevant_field->{$current_type}}, $escapedtitle, $current_type, $current_object->{parent_container});
			print $handle "}\n";
			print $handle "sub __htmlpage".join("_","",$current_object->{ownedby_theme},$current_object->{pagetype_nodetype},$current_object->{displaytype},"mimetype")."\n";
			print $handle "{ return '".$current_object->{mimetype}."'; "; #Bit of a hack, leave off the } and the above will pick it up

		}else{
			$shortcuts->{"_id_".$current_object->{node_id}} = $escapedtitle;
			print $handle subifycode($current_object->{$relevant_field->{$current_type}}, $escapedtitle, $current_type);
		}

		print $handle "}\n\n";
	}

	print $handle "\n\n";


	if($shortcuts)
	{
		print $handle "BEGIN {\n";
	
		foreach my $shortcutname (keys %$shortcuts)
		{
			# If all numeric, assume 
			my $shortcutval = $shortcuts->{$shortcutname};
			print $handle '$Everything::Compiled::'.$current_type."::{__$current_type"."$shortcutname} = *Everything::Compiled::".$current_type."::__$current_type"."_$shortcutval;\n";
		}
		print $handle "}";
	}

	print $handle "1;";

	close $handle;
}
my $contents;

sub subifycode
{
	my ($text, $title, $current_type, $nodeid) = @_;

	while($text=~s/(.*?)\[(\{.*?\}|".*?"|%.*?%)\]//s)
	{
		my ($before, $after) = ($1,$2);
		if(length($before) > 0)
		{
			process_text($before);
		}
		push @$contents, 'code';
		push @$contents, $after;
	}

	process_text($text);

	my $subroutines = "";
	my $returnstring = [];
	my $subnum = 0;

	while(@$contents)
	{
		my $type = shift @$contents;
		my $data = shift @$contents;

		if($type eq 'code')
		{
			if($data =~ s/^{(.*)}$//gs)
			{
				my $htmlcode = $1;
				my $data = [split(/\:/,$htmlcode,2)];
				push @$returnstring,"htmlcode(\"".quotemeta($data->[0])."\",\"".quotemeta($data->[1])."\")";
			}elsif($data =~ s/^\%(.*)\%$//gs){
				my $perlcode = $1;
			
				$subroutines .= "sub __$current_type"."_".$title."_embedded_sub$subnum { \n";
				$subroutines .= "$perlcode\n";
				$subroutines .= "}\n";
			
				push @$returnstring,"__$current_type"."_".$title."_embedded_sub$subnum()";
				$subnum++;
			}elsif($data =~ s/^\"(.*)\"$//gs){
				my $perlcode = $1;

				$subroutines .= "sub __$current_type"."_".$title."_embedded_sub$subnum { \n";
				$subroutines .= " return \"$perlcode\";\n";
				$subroutines .= "}\n";

				push @$returnstring,"__$current_type"."_".$title."_embedded_sub$subnum()";
				$subnum++;
			}else{
				print STDERR "Data error: $data";
			}
		}elsif($type eq 'txt')
		{
			push @$returnstring,'"'.quotemeta($data).'"';
		}elsif($type eq 'ret')
		{
			push @$returnstring,"\$__".$title."_CONTAINED_STUFF";
		}
	}

	my $return_str = "$subroutines\n";

	if($current_type eq "container")
	{
		my $currentnode = getNodeById($nodeid);
		$return_str = "my (\$__".$title."_CONTAINED_STUFF) = \@_;\n"."my \$CURRENTNODE = {'parent_container' => '$$currentnode{parent_container}'};\n".$return_str;	

		if($currentnode->{parent_container} != 0)
		{
			$return_str .= "no strict 'refs';\n";
			$return_str .= 'my $__return_sub = "__'.$current_type.'"."_id_$$CURRENTNODE{parent_container}";'."\n";
			$return_str .= "return &\$__return_sub(".join(".",@$returnstring).");\n";
		}else{
			$return_str .= "return ".join(".",@$returnstring).";\n";
		}
	}elsif($current_type eq "htmlpage" and $nodeid){
		my $parent_container = $nodeid;
		$return_str .= "return Everything::Compiled::container::__container_id_$nodeid(".join(".",@$returnstring).");\n";
	}else{
		$return_str .= "return ".join(".",@$returnstring).";\n";
	}

	return $return_str;
}

sub process_text
{
	my ($codetext) = @_;

	if(length($codetext) > 0)
	{
		if($codetext =~ /CONTAINED_STUFF/)
		{
			my $parts = [split(/CONTAINED_STUFF/,$codetext,2)];
			if(defined($parts->[0]) and length($parts->[0]) > 0)
			{
				push @$contents, 'txt';
				push @$contents, $parts->[0];
			}
			push @$contents, 'ret';
			push @$contents, '';
			
			if(defined($parts->[1]) and length($parts->[1]) > 0)
			{
				push @$contents, 'txt';
				push @$contents, $parts->[1];
			}
		}else{
			push @$contents, 'txt';
			push @$contents, $codetext;
		}	
	}	
}
