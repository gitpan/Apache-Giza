package Apache::Giza;
use lib '#[[PREFIX]]#';
use strict; 
# ----------------- -  -         --     -        --- -   - -  #
# Apache+Giza - mod_perl handler
# ----------------------------------------------------------- #

use Apache::Constants qw(:common);
use Apache::Request ();
use Giza 			();
use Giza::Modules 	();
use Cache::DB_File 	();
our($giza, $user, $db, $template, $cache);
our $VERSION = 0.7;

sub handler
{ chdir $Giza::PREFIX;

	my($r) = @_;
	# If the request object starts with the /gfx path,
	# we don't want to handle it. Pass it to the next handler.
	return DECLINED if $r->uri =~ /^\/?gfx/o;

	# Create Giza session.
	($giza, $db, $user, $template)
		= Giza::Modules::giza_session(qw(db user template));
	my $apr = Apache::Request->new($r);
	$cache = Cache::DB_File->new(expire=>'1w', max_size=>500, filename=>'/tmp/blabla');

	# Setup environment.
	setupEnv($r);
	$r->content_type('text/html');

	# What does she want with the request?
	my $page	= $r->uri;
	my $loc		= quotemeta $r->location;
	my $parent	= $apr->param('parent') || Giza::G_CAT_TOP;
	$page =~ s/^$loc\/?//; # remove the location part of the page requested.
	$page ||= $giza->config->{template}{"index"};

	# ## configure the template object.
	$giza->apache($r);
	$template->apache($r);
	$template->parent($parent);
	$template->params($apr);
	$template->page($page);
	if($r->dir_config('GizaTemplate')) {
		$giza->config->{global}{template_dir} = $r->dir_config('GizaTemplate');
	}

	# if a object has a different template defined; ignore it.
	if($page ne $giza->config->{template}{"index"}) {
		$template->no_follow_obj_template(Giza::TRUE);
	}
	if($r->dir_config('NoFollowObjectTemplate')) {
		$template->no_follow_obj_template(Giza::TRUE);
	}

	# ## initalization complete, let's...
	
	  # ...establish a database connection.
	  $db->connect() or return FORBIDDEN;

      # create a unique key to use as cache identifier. 
	  my $tcachekey = undef;
	  if($apr->param) {
	    $tcachekey = $page.'?'. join("#!#",
	      map{"$_#:#".$apr->param($_)}
		    sort grep({!/(uname|pw)/} $apr->param)
		);
	  } else {
		$tcachekey = $page.'?parent#:#'.Giza::G_CAT_TOP;
	  }

	  my $in_cache = $cache->fetch($tcachekey);
	  if($in_cache)
	  { # ... if the request is in the cache, just use it...
	 	$r->print($in_cache);
	  } else
      { # ...if not, process the template and save the result.
		my $out = $template->do($page);
		$r->print($out);
		$cache->store($tcachekey, $out) if $out;
	  }

	$cache->close;
	$db->disconnect();
	return OK; # -- happy to serve you!
}

sub setupEnv
{
	my($r) = @_;

	if($r->dir_config('GizaDbName')) {
		$ENV{GIZA_DB_NAME} = $r->dir_config('GizaDbName');
	}
	if($r->dir_config('GizaDbUser')) {
		$ENV{GIZA_DB_USER} = $r->dir_config('GizaDbUser');
	}
	if($r->dir_config('GizaPrefix')) {
		$ENV{GIZA_PREFIX} = $r->dir_config('GizaPrefix');
	}
	if($r->dir_config('GizaLogQuery')) {
		$ENV{GIIZA_SHOW_QUERY} = $r->dir_config('GizaLogQuery');
	}
}
	

sub BEGIN
{
	print STDERR "giza2::mod_perl loading...\n";
}


1
__END__
=cut
=head1 NAME

Apache::Giza - Giza->mod_perl handler

=head1 SYNOPSIS

  <location /giza>
    SetHandler perl-script
    PerlModule Apache::DBI
    PerlHandler +Apache::Giza
    PerlSetVar GizaTemplate templates/admin
    PerlSetVar GizaDbName giza2
    PerlSetVar GizaDbUser giza
    PerlSetVar GizaPrefix /opt/giza2
    PerlSetVar NoFollowObjTemplate
  </location>

=head1 ABSTRACT

  This is the mod_perl handler for the Giza Web-content Management System.
  Using this instead of the CGI version will result in better performance.

=head1 DESCRIPTION

	The following options can be passed from the apache configuration
	via the PerlSetVar directive:

=head1 EXPORT

Apache::Giza has nothing to export.

=head1 SEE ALSO

The unixmonks website is at:
L<http://www.unixmonks.net>

L<perl>, L<Giza>, L<Giza::Modules>, L<mod_perl>

=head1 AUTHOR

Ask Solem Hoel E<lt>ask@unixmonks.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002 ABC Startsiden AS, Ask Solem Hoel

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
