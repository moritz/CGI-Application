class CGI::Application;

# XXX: should be dump-html
has %.run-modes   is rw = (start => 'dump');
has $.start-mode  is rw = 'start';

has $.header-type is rw = 'header';
has $.mode-param  is rw = 'rm';

has $.error-mode  is rw;

has $.current-runmode is rw;

# the CGI object or hash
has %.query is rw;

multi method run() {
    my $rm = $.__get_runmode($.mode-param);
    $.current-runmode = $rm;

    # undefine $.__PRERUN_MODE_LOCKED;
    # $.call-hook('prerun', $rm);
    # $.__PRERUN_MODE_LOCKED = 1
    # my $prerun-mode = $.prerun-mode;
    # if $prerun-mode {
    #    $rm = $prerun-mode;
    #    $.current-runmode = $rm;
    # }

    my $body = $.__get_body($rm);

    # $.call-hook('postrun', $body);

    my $headers = $._send_headers();

    my $output = $headers ~ $body;

    print $output unless $*CGI_APP_RETURN_ONLY || %*ENV<CGI_APP_RETURN_ONLY>;
    return $output;

}

multi method __get_runmode($rm-param) {
    my $rm = do given $rm-param {
        when Callable { .(self)     }
        when Hash     { .<run-mode> }
        default       { $.query{$_} }
    }
    $rm = $.start-mode unless defined($rm) && $rm.chars;
    return $rm;
}

multi method __get_runmeth($rm) {
    my $m = %.run-modes{$rm};
    # TODO: implement AUTOLOAD/CANDO mode
    die "No such run mode '$rm'\n" unless defined $m;
    return $m;
}

multi method __get_body($rm) {
    my $method-name = $.__get_runmeth($rm);
    my $body = try { self."$method-name"() };
    if $! {
        my $error = $!;
        $.call-hook('error', $error);
        if $.error-mode {
            $body = self."$.error-mode"();
        } else {
            die "Error executing run mode '$rm': $error";
        }
    }
    return $body;
}

multi method _send_headers() {
    "Content-Type: text/html\r\n\r\n";
}

multi method dump() {
    [~] gather {
        take "Runmode: '$.current-runmode'\n" if defined $.current-runmode;
        take "Query parameters: %.query.perl()\n";
        # TODO: dump %*ENV
    }

}

# vim: ft=perl6
