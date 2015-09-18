#!/usr/bin/perl

=pod

=encoding utf8

=head1 NAME

scrape.pl - Scrapes api.natmus.dk for asset metadata

=head1 SYNOPSIS

scrape.pl -o OUTPUT_FILE -c COLLECTION -n NUMBER_OF_RESULTS -t THROTTLE -l -v

=head1 DESCRIPTION

This script downloads asset metadata in JSON format from the National Museum of
Denmark API.

The following invocation of the script grabs all metadata from the DNT
collection in batches of 1000 assets and combines them in one JSON object which
is then stored in the file C<natmus.json>. The script waits for 1 second
between each request.

    scrape.pl -o ./natmus.json -c DNT -n 1000 -t 1

=head1 OPTIONS

=over

=item -c COLLECTION

The ID of the section to scrape (e.g. BA, DNT, DO, etc.).

=item -l

Only retrieve assets with an open license (currently all assets released under
the CC-BY-SA license).

=item -n NUMBER_OF_RESULTS

The number of results to fetch in each request. This should probably be less
than 1000.

=item -o OUTPUT_FILE

The final JSON object is written to this file.

=item -t SECONDS

Sleep for the given amount of seconds between each request. Defaults to 1.

=item -v

Be verbose. Prints status information to STDOUT.

=back

=cut

use Modern::Perl;

use Data::Dumper;
use Getopt::Std;
use HTTP::Request;
use JSON;
use LWP::UserAgent;
use Pod::Usage;
use POSIX;
use URI;

my $api_host  = 'testapi.natmus.dk';
my $api_path  = '/v1/Search/';
my $api_query = 'query=(type:asset)';

$|++;

# get command line options
my %opts = ();
getopts('lc:n:o:t:v', \%opts) or pod2usage(2);

# print usage instructions if required options are missing
if (!$opts{'o'}) {
  pod2usage(-verbose => 1);
}

# set default option values
if (!$opts{'n'}) {
  $opts{'n'} = 1000;
}
if (!$opts{'t'}) {
  $opts{'t'} = 1;
}

# add collection filter
if ($opts{'c'}) {
  $api_query .= " AND (collection:$opts{'c'})"
}

say "Scraping $api_host in batches of $opts{'n'} with a delay of $opts{'t'} second." if $opts{'v'};
say "Scraping limited to items having an open license." if ($opts{'v'} and $opts{'l'});

# figure out how many assets we have to get

my $steps = get_steps($opts{'n'});
say "We need to grab $steps pages from the API." if $opts{'v'};

# grab the assets and add them to one big array

my $output = [];
my $offset = 0;

for my $step (1..$steps) {
  # limit our request rate to avoid overloading the server
  if ($opts{'t'} > 0 and $step > 1) {
    sleep $opts{'t'};
  }

  # add paging parameters to query string
  my $query = $api_query . "&size=$opts{'n'}&offset=$offset";

  # get a set of results from the API and add them to the result array
  my $url = create_url($api_host, $api_path, $query);
  print "Downloading $url... " if $opts{'v'};
  my $json = get($url);

  foreach my $result (@{$json->{Results}}) {
    if ($opts{'l'}) {
      push $output, $result if $result->{license} eq 'CC-BY-SA';
    }
    else {
      push $output, $result;
    }
  }

  say "Done!" if $opts{'v'};

  # increment the offset by the step size 
  $offset += $opts{'n'};
}

# write the result to a JSON file
open my $out, '>', $opts{'o'} or die "Unable to open $opts{'o'} for writing: $!\n";
print $out encode_json($output);
close $out;

my $count = $#{$output} + 1;
say "Downloaded $count assets." if $opts{'v'};

sub create_url {
  my $host = shift;
  my $path = shift;
  my $query = shift;

  my $uri = URI->new();

  $uri->scheme('http');
  $uri->host($host);
  $uri->path($path);
  $uri->query($query);

  return $uri->as_string;
}

sub get {
  my $url = shift;

  # let other people know who we are
  my $ua = new LWP::UserAgent;
  $ua->agent('OutzeBot/1.0 (+http://www.information.dk/kontakt)');

  # perform the request
  my $req = new HTTP::Request(GET => $url);
  my $res = $ua->request($req);

  if ($res->is_success) {
    return decode_json($res->content);
  }
  else {
    say "HTTP ERROR: " . $res->status_line;
    say "URL: $url";
  }
}

sub get_steps {
  my $size = shift;

  my $url = create_url($api_host, $api_path, $api_query);
  my $json = get($url);

  my $total = $json->{NumberOfResultsTotal};

  my $steps = POSIX::ceil($total / $size);

  return $steps;
}

=pod

=head1 AUTHOR

Morten Wulff, <wulff@ratatosk.net>

=head1 COPYRIGHT

Copyright (c) 2015, Morten Wulff
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL MICHAEL BOSTOCK BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
