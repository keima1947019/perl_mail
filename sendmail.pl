#!/usr/bin/perl -w

use utf8;
use Encode;
use strict;
use warnings;
use Authen::SASL;
use MIME::Base64;
use Net::SMTP;
use Encode qw(decode encode);
use Unicode::Normalize;
use MIME::Entity;
#use open IO => ":utf8";
#use open IN => ":utf8";
#use open OUT => ":utf8";

sub sendmail {    
    my $atesaki_name = $_[0]; # destination username
    my $atesaki = $_[1]; # destination address
    my $message = $_[2]; # message
    my $SMTP_CONF = { # SMTP parameter. An anonymous hash is used as a reference.
         host => '<smtp server FQDN>',
         port => '<smtp tcp port number>', 
         from => '<sender mail address>',
         return_path => '<return mail address>',
         auth_uid => '<smtp auth username>',
         auth_pw => '<smtp auth password>'
    };
    my $subject = '<mail subject>';
    $subject = encode('MIME-Header-ISO_2022_JP',$subject); # Encode Japanese from internal string to external string
    my $message =<<"EOF";
Dear $atesaki_name,

$message

Sincerely,

EOF
    my $header = << "EOS";
From: $SMTP_CONF->{from}
Return-path: $SMTP_CONF->{return_path}
Reply-To: $SMTP_CONF->{return_path}
To: $atesaki
Subject: $subject
Mime-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
EOS
    $message = encode('utf-8',$message);
    my $smtp = Net::SMTP->new( # Net::SMTP instance creation
                              Host => $SMTP_CONF->{host},
                              Hello => $SMTP_CONF->{host},
                              Port => $SMTP_CONF->{port},
                              Timeout => 20,);
    unless($smtp){ # Failure log output
        my $msg = "can't connect smtp server: $!";
        die $msg;}
    $smtp->auth(
                $SMTP_CONF->{ auth_uid },
                $SMTP_CONF->{ auth_pw }
                ) or die "can't login smtp server";
    $smtp->mail( $SMTP_CONF->{ from } ); # real destination address
    $smtp->to( $atesaki );
    #$smtp->cc($atesaki);
    #$smtp->bcc($atesaki);
    $smtp->data();
    $smtp->datasend( "$header\n" );
    $smtp->datasend( "$message\n" );
    $smtp->dataend();
    $smtp->quit;
    1;}
open(DATAFILE, "<:utf8", "atesaki.csv") or die("Error, $!");
my $i = 0;
while(<DATAFILE>){
    if($i==0){$i++;next;}
        chomp($_);
        my @array = split(/,/,$_);
        $array[0] = encode('utf-8',$array[0]); # Encode to internal string just to print
        print "$i : $array[0]\n";
        $array[0] = decode('utf-8',$array[0]); # Decode and return
        &sendmail($array[0],$array[1],$array[2]); 
        $i++;
        next;
}
close(DATAFILE);
exit(0);