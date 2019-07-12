<?php

class InArrayRecursive
{
    public function execute($needle, $haystack, $strict = true)
    {
        foreach ($haystack as $value) {
            if (($strict ? $value === $needle : $value == $needle) || (is_array($value) && $this->in_array_recursive($needle, $value, $strict))) {
                return true;
            }
        }
        return false;
    }
}
