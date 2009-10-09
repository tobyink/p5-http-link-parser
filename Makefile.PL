use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'HTTP::Link::Parser',
    VERSION_FROM      => 'lib/HTTP/Link/Parser.pm', # finds $VERSION
    PREREQ_PM         => {
		 'URI'            => '1.37' ,
		 'URI::Escape'    => '3.29' ,
		 'HTTP::Response' => '5.824' ,
		 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/HTTP/Link/Parser.pm', # retrieve abstract from module
       AUTHOR         => 'Toby Inkster <mail@tobyinkster.co.uk>') : ()),
);
