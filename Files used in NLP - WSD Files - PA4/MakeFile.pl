 # !usr/bin/perl

 use WWW::Wikipedia;
 my $wiki = WWW::Wikipedia->new();

  ## search for 'perl' 
  my $result = $wiki->search( 'perl' );

  ## if the entry has some text print it out
  if ( $result->text() ) { 
      print $result->text();
  }

  ## list any related items we can look up 
  print join( "\n", $result->related() );