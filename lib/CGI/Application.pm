class CGI::Application;

has %.run-modes is rw;
has $.start-mode is rw = 'start';
has %.mode-param is rw;

has %.query is rw;

multi method run() { "HEADER\r\n\r\nBODY" }

# vim: ft=perl6
