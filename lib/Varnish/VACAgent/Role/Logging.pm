package Varnish::VACAgent::Role::Logging;

use Moose::Role;

requires '_config';

=head1 NAME

Varnish::VACAgent::Role::Logging

=head1 SYNOPSIS

with 'Varnish::VACAgent::Role::Logging';

...

$self->debug($message);
$self->info($message);
$self->warn($message);
$self->error($message);

=head1 DESCRIPTION

Provides Log4perl. Note that the importing class must have a _config
attribute. This means that the Configurable role must be imported
before this role.

=cut

use Log::Log4perl  qw( get_logger :easy );
use Cwd            qw( abs_path );
use File::Basename qw( fileparse );
use File::Path     qw( mkpath );
use FindBin        qw( $RealScript );
use POSIX          qw( strftime );



has _log => (
    is => 'ro',
    isa => 'Log::Log4perl::Logger',
    builder => '_build_log',
    handles => [
        "fatal",
        "error",
        "warn",
        "info",
        "debug",
        "trace",
    ],
    lazy => 1,
);



# Initialize Log::Log4perl. Check config to see if a log config file is
# specified in $config->{log_cfg_file} and use that if it exists.

sub _build_log {
    my $logger_name = 'VACAgent';
    
    my ($self) = @_;
    my $logger;
    my $log_cfg;

    # Init Log4Perl once
    if (Log::Log4perl->initialized) {
        return get_logger($logger_name); 
    }
    
    if ($ENV{HARNESS_VERSION}) {
        # Running as part of the test suite, shut up
        Log::Log4perl->easy_init($FATAL);
        $logger = get_logger($logger_name);
    } elsif (($log_cfg = $self->_config->log_config_file) && -r $log_cfg) {
        Log::Log4perl->init_and_watch($log_cfg, 3);
        $logger = get_logger($logger_name);
    } else {
        $logger = $self->_configure_logger($logger_name);
    }
    $logger->debug('Log4perl initialized');
    
    return $logger;
}



sub _configure_logger {
    my ($self, $logger_name) = @_;
    
    my $logger = get_logger($logger_name);
    
    my $layout = Log::Log4perl::Layout::PatternLayout->new(
        $self->_config->log_format);
    
    my $log_level = $self->_calculate_log_level;
    
    if ($self->_config->foreground) {
        $self->_configure_foreground_logging($logger, $layout, $log_level);
    }
    if (defined $self->_config->log_file) {
        $self->_configure_file_logging($logger, $layout, $log_level);
    }
    
    return $logger;
}



sub _configure_foreground_logging {
    my ($self, $logger, $layout, $log_level) = @_;
    
    my $stdout_appender =  Log::Log4perl::Appender->new(
        "Log::Log4perl::Appender::ScreenColoredLevels",
        name      => "screenlog",
        stderr    => 0,
    );
    $stdout_appender->layout($layout);
    $logger->add_appender($stdout_appender);
    $logger->level($log_level);
}



sub _configure_file_logging {
    my ($self, $logger, $layout, $log_level) = @_;
    
    my ($name, $path) = fileparse(strftime(
        $self->_config->log_file , localtime));
    unless (-d $path) {
        unless (mkpath($path)) {
            print $RealScript, ': ', $!, ": ", $path, "\n";
            exit 1;
        }
    }
    $self->_config->log_file(abs_path($path . $name));
    
    my $file_appender =  Log::Log4perl::Appender->new(
        "Log::Log4perl::Appender::File",
        name      => "filelog",
        filename  => $self->_config->log_file,
    );
    $file_appender->layout($layout);
    if ($self->_config->foreground) {
        $logger->info('Logging to: ', $self->_config->log_file);
    }
    $logger->add_appender($file_appender);
    $logger->level($log_level);
    Log::Log4perl->wrapper_register('Moose::Meta::Method::Delegation');
}



sub _calculate_log_level {
    my $self = shift;
    
    my $config = $self->_config;
    
    if ($config->log_level) {
        print "Configured log level: " . $config->log_level . "\n";
        return $TRACE   if $config->log_level eq "trace";
        return $DEBUG   if $config->log_level eq "debug";
        return $INFO    if $config->log_level eq "info";
        # return $NOTICE  if $config->log_level eq "notice";
        return $WARN    if $config->log_level eq "warning";
        return $WARN    if $config->log_level eq "warn";
        return $ERROR   if $config->log_level eq "error";
    }

    print "No log level configured, using info\n";
    return $INFO;
}



no Moose::Role;

1;

__END__



=head1 AUTHOR

Sigurd W. Larsen

=cut
