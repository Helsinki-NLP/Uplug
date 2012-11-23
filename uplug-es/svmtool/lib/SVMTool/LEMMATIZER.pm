package LEMMATIZER;

use Data::Dumper;

# ------------------------------------- SUBS ------------------------------------------

sub LT_load
{
    #description _ loads a dictionary
    #param1  _ dictionary filename
    #param2  _ verbose
    #@return _ dictionary hash ref

    my $dict = shift;
    my $verbose = shift;

    my $FDICT = new IO::File("< $dict") or die "Couldn't open dictionary file: $dict\n";

    my %DICT;
    my $iter;
    while (defined (my $line = <$FDICT>)) {
        #abandoned VBD abandon
        #print $line;
        chomp ($line);
        my @entry = split(" ", $line);
        $DICT{$entry[0]}->{$entry[1]} = $entry[2];
        $iter++;
        if ($verbose) {
           if (($iter%10000) == 0) { print STDERR "."; }
           if (($iter%100000) == 0) { print STDERR "$iter"; }
        }
    }

    $FDICT->close();

    if ($verbose) { print STDERR "...$iter forms [DONE]\n"; }
    
    return \%DICT;
}

sub LT_tag
{
   #description _ given a word/pos pair returns the lemma according to the given dictionary
   #param1 _ dictionary
   #param2 _ word
   #param3 _ pos

   my $dict = shift;
   my $word = shift;
   my $pos = shift;

   my $lemma = lc($word);

   if (exists($dict->{$word})) {
      if (exists($dict->{$word}->{$pos})) { $lemma = $dict->{$word}->{$pos}; }
      else {
         my %lemmas;
         foreach my $p (keys %{$dict->{$word}}) { $lemmas{$dict->{$word}->{$p}}++; }
         my @sorted_lemmas = sort {$lemmas{$b} <=> $lemmas{$a} || $a cmp $b} keys %lemmas;
         $lemma = $sorted_lemmas[0];
      }
   }
   elsif (exists($dict->{lc($word)})) {
      if (exists($dict->{lc($word)}->{$pos})) { $lemma = $dict->{lc($word)}->{$pos}; }
      else {
         my %lemmas;
         foreach my $p (keys %{$dict->{lc($word)}}) {$lemmas{$dict->{lc($word)}->{$p}}++; }
         my @sorted_lemmas = sort {$lemmas{$b} <=> $lemmas{$a} || $a cmp $b} keys %lemmas;
         $lemma = $sorted_lemmas[0];
      }
   }
   elsif ($pos =~ /^N.*/) { $lemma = $word; }
   #else { return lc($word); }

   return $lemma;
}

1;
