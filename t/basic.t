use v6;
use Test;

plan *;

#%*ENV<CGI_APP_RETURN_ONLY> = 1;

# RAKUDO workaround:
# setting ENV variables fails (WTF?), so let's use a dynamic variable instead
my $*CGI_APP_RETURN_ONLY = 1;

BEGIN { @*INC.push('t/lib', 'lib') };

use CGI::Application;


sub response-like($app, Mu $header, Mu $body, $comment) {
    my $output = $app.run;
    my @hb = $output.split(rx{\r?\n\r?\n});
#    diag "Header: @hb[0]";
#    diag "Body: @hb[1]";
    ok ?(@hb[0] ~~ $header), "$comment (header)";
    ok ?(@hb[1] ~~ $body),   "$comment (body)";
}

{
    my $app = CGI::Application.new;
    isa_ok $app, CGI::Application;
    # TODO: make that CGI.new
    $app.query = {};
    response-like($app,
        rx{^ 'Content-Type: text/html'},
        rx{ 'Query parameters:' },
        'base class response',
    );
}

done_testing;

# vim: ft=perl6
