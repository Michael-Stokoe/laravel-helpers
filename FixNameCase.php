<?php

class FixNameCase
{
    /**
      * Normalize the given (partial) name of a person.
      *
      * - re-capitalize, take last name inserts into account
      * - remove excess white spaces
      *
      * Snippet from: https://timvisee.com/blog/snippet-correctly-capitalize-names-in-php
      *
      * @param string $name The input name.
      * @return string The normalized name.
      */
    public function execute($name)
    {
        // A list of properly cased parts
        $CASED = collect([
        "O'", "l'", "d'", 'St.', 'Mc', 'the', 'van', 'het', 'in', "'t", 'ten',
        'den', 'von', 'und', 'der', 'de', 'da', 'of', 'and', 'the', 'III', 'IV',
        'VI', 'VII', 'VIII', 'IX',
    ]);

        // Trim whitespace sequences to one space, append space to properly chunk
        $name = preg_replace('/\s+/', ' ', $name) . ' ';

        // Break name up into parts split by name separators
        $parts = preg_split('/( |-|O\'|l\'|d\'|St\\.|Mc)/i', $name, -1, PREG_SPLIT_DELIM_CAPTURE);

        // Chunk parts, use $CASED or uppercase first, remove unfinished chunks
        $name = collect($parts)
        ->chunk(2)
        ->filter(function ($part) {
            return $part->count() == 2;
        })
        ->mapSpread(function ($name, $separator = null) use ($CASED) {
            // Use specified case for separator if set
            $cased = $CASED->first(function ($i) use ($separator) {
                return strcasecmp($i, $separator) == 0;
            });
            $separator = $cased ?? $separator;

            // Choose specified part case, or uppercase first as default
            $cased = $CASED->first(function ($i) use ($name) {
                return strcasecmp($i, $name) == 0;
            });
            return [$cased ?? ucfirst(strtolower($name)), $separator];
        })
        ->map(function ($part) {
            return implode($part);
        })
        ->join('');

        // Trim and return normalized name
        return trim($name);
    }
}
