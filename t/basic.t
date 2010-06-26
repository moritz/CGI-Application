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
    diag "Output: " ~ $output.perl;
    my ($h, $b) = $output.split("\r\n\r\n");
    ok ?($h ~~ $header), "$comment (header)";
    ok ?($b ~~ $body),   "$comment (body)";
}

{
    my $app = CGI::Application.new;
    isa_ok $app, CGI::Application;
    # TODO: make that CGI.new
    $app.query = {};
    response-like($app,
        rx{^ 'Content-Type: text/html'},
        rx{ 'Query Parameters:' },
        'base class response',
    );
}

done_testing;
