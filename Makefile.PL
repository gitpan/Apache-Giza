use 5.008;
use ExtUtils::MakeMaker;

$GIZA_PREFIX = shift @ARGV;
$PACKAGE = 'Apache::Giza';
($PACKAGE_FILE = $PACKAGE) =~ s#::#/#g;

unless($GIZA_PREFIX) {
	print "
WARNING: Giza Prefix not set. You can set this by
         giving it as a command line parameter.  i.e:
           perl Makefile.PL /opt/giza2/include.	
         
         Reverting to the default: /opt/giza2/include

";
	$GIZA_PREFIX = '/opt/giza2/include';
}

set_prefix();

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME			=> $PACKAGE,
	VERSION_FROM	=> "lib/$PACKAGE_FILE.pm", # finds $VERSION
	PREREQ_PM		=> {
						'Cache::DB_File' => 0.1
	},
	ABSTRACT_FROM	=> "lib/$PACKAGE_FILE.pm",
	AUTHOR			=> 'Ask Solem Hoel <ask@unixmonks.net>',
	macro 			=> {
		GIZA_PREFIX => $GIZA_PREFIX
	},
	clean 			=> {
						FILES => 'lib/Apache/Giza.pm',
	},
	dist			=> {
						COMPRESS 	=> 'gzip -9',
						SUFFIX		=> '.gz',
						DIST_DEFAULT=> 'all tardist'
	}
);

sub set_prefix
{
	open(A, "<template/Apache-Giza.pm") or return;
	open(B, ">lib/Apache/Giza.pm") or return;
	while(<A>) {
		$f++ if(not $f && s/#\[\[PREFIX\]\]#/$GIZA_PREFIX/);
		$c.=$_;
	}
	print B $c;
	close(A), close(B);
}
