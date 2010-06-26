use v6;
use Test;

plan *;

#%*ENV<CGI_APP_RETURN_ONLY> = 1;

# RAKUDO workaround:
# setting ENV variables fails (WTF?), so let's use a dynamic variable instead
my $*CGI_APP_RETURN_ONLY = 1;

BEGIN { @*INC.push('t/lib', 'lib') };

use CGI::Application;


sub response-like($app, Mu $header, Mu $body, $comment, :$todo-header) {
    my $output = $app.run;
    my @hb = $output.split(rx{\r?\n\r?\n});
    todo($todo-header) if $todo-header;
    ok ?(@hb[0] ~~ $header), "$comment (header)" or diag "Got: @hb[0].perl()";
    ok ?(@hb[1] ~~ $body),   "$comment (body)"   or diag "Got: @hb[1].perl()";
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

use TestApp;
{
    my $app = TestApp.new();
    isa_ok $app, CGI::Application;

    response-like(
        $app,
        rx{^'Content-Type: text/html'},
        rx{'Hello World: basic_test'},
        'TestApp, blank query',
    );
}

{
    dies_ok { TestApp.new(query => [1, 2, 3]) },
            'query is restricted to Associative';
}

{
    my $app = TestApp.new(query => { test_rm => 'redirect_test' });
    response-like(
        $app,
        rx{^'Status: 302'},
        rx{^'Hello World: redirect_test'},
        'TestApp, redirect_test',
    );
}

{
    my $app = TestApp.new;
    $app.query = { test_rm => 'dump_txt' }
    response-like(
        $app,
        rx{^'Content-Type: text/html'},
        rx{'Query parameter'},
        'TestApp, dump_text',
    );
}

skip('Cookies') for ^3;
if 0 {
    my $app = TestApp.new(query => { test_rm => 'cookie_test' });

    response-like(
        $app,
        rx{ ^^'Set-Cookie: c_name=c_value' },
        rx{ 'Hello World: cookie_test' },
        'TestApp, cookie test',
    );
}

# TODO: template tests


{
    my $error_hook_called = 0;
    class TestAppWithError is CGI::Application {
        method BUILD { %.run-modes<throws_error> = 'throws_error' };
        method throws_error() {
            die "OH NOEZ";
        }
        method error(*@args) {
            $error_hook_called = 1;
        }
    }

    my $app = TestAppWithError.new(query => { rm => 'throws_error' });

    dies_ok { $app.run() },
        'when the run mode dies, the whole execution aborts';
    ok $error_hook_called, 'and the error hook was called';

}

done_testing;

# vim: ft=perl6
